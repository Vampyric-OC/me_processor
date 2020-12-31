-- Copyright, V.
--
-- This file is part of ME Storage Processor.
--
-- ME Storage Processor is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- ME Storage Processor is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with ME Storage Processor.  If not, see <http://www.gnu.org/licenses/>.


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local filesystem = require('filesystem')
local shell = require('shell')
local serialization = require('serialization')

local D = require('me_processor_lib.debug')
local lib = require('me_processor_lib.library')
local me_processor_thread = require('me_processor_lib.me_processor_thread')

local machines = {}


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function processor_thread(machine, processor)
  -- Check queue again, just to bail out fast.
  if #machine.queue == 0 then
    machine.processors_running = machine.processors_running - 1
    processor.running = false
    return
  end
  
  -- Yield for more queueing.
  os.sleep(0)

  repeat
    local request = machine.queue[1]

    if request.amount_reserved >= request.amount then
      table.remove(machine.queue, 1)

      -- Yield again for more queueing.
      os.sleep(0)
    else
      local my_amount = math.ceil(request.amount / #machine.processors)

      if my_amount > 0 then
        request.amount_reserved = request.amount_reserved + my_amount

        machine.handler(machine, processor, request, my_amount)
      end

      -- And more yield for more queueing.
      os.sleep(0)
    end
  until #machine.queue == 0

  D.LOG(machine.label .. " processor done.")
  machine.processors_running = machine.processors_running - 1
  processor.running = false

  if machine.processors_running == 0 then
    -- Clear telemetry when last processor exits.
    machine.telemetry = {}  
  end
end


local function start_processor(machine, processor)
  -- Yield to start processors.
  os.sleep(0)

  if #machine.queue == 0 then
    -- Other processors already took care of the queue. No need to start the thread.
    return
  end

  processor.running = true
  machine.processors_running = machine.processors_running + 1
  me_processor_thread.create(processor_thread, machine, processor)
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function queue_add(self, request, priority)
  if not request.item then
    D.WRN("No item found in queue request.")
    return false
  end

  if not request.amount or request.amount == 0 then
    D.WRN("Amount in queue request is zero or no amount found.")
    return false
  end

  if not priority then
    for n, queued_item in pairs(self.queue) do
      if lib.item_to_key(request.item) == lib.item_to_key(queued_item.item) then
        D.LOG(lib.item_to_label(request.item) .. " already queued.")
        return false
      end
    end
  end

  request.amount_reserved = 0

  -- Priority items go into 2nd place on the queue.
  if priority and #self.queue > 0 then
    table.insert(self.queue, 2, request)
  else
    table.insert(self.queue, request)
  end

  local logged = false
  for n = 1, #self.processors do
    if not self.processors[n].running then
      if not logged then
        D.LOG("Starting " .. self.label .. " processors.")
        logged = true
      end
      start_processor(self, self.processors[n])
    end
  end
end


-- FIXME: TBD
local function queue_cancel(self, request)
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


function machines.setup(ignore_inventories, ignore_transposers)
  -- These get loaded at setup so the processors themselves can also get a reference to machines through require.
  -- This way virtual machines can use real machines while keeping one common interface.

  local transposer_factory = require('me_processor_lib.transposer_factory')
  local processors = require('me_processor_lib.processors')

  -- Adds to processor base to turn it into a machine.
  local function new_machine(machine_name)
    local machine = processors.processor_base(machine_name)

    machine.processors = {}
    machine.telemetry = {}
    machine.processors_running = 0
    
    -- Only add queue's to machines with an handler.
    -- Machines with no handler will set their own functions in init.
    if machine.handler then
      machine.queue = {}
      machine.queue_add = queue_add
      machine.queue_remove = queue_remove
    end

    return machine
  end


  -- Turns configuration into valid machines.
  local function validate_configuration(configuration)
    for k in pairs(machines) do
      machines[k] = nil
    end
  
    if not configuration or not configuration.known_processors or not configuration.transposers then
      D.WRN("Configuration invalid.")
      return false
    end

    local known_processors = configuration.known_processors
    local transposer_configuration = configuration.transposers

    local new_found = false
    for processor_name, processor_label in pairs(processors.all()) do
      if not known_processors[processor_name] or known_processors[processor_name] ~= processor_label then
        -- Processor added in source.
        D.LOG("New processor type found (" .. processor_label .. ").")
        new_found = true
      end
    end

    if new_found then
      return false
    end

    -- Turns configuration into valid transposers.
    local transposers = transposer_factory.validate_transposer_configuration(transposer_configuration)

    if not transposers then
      D.LOG("Transposer validation failed.")
      return false
    end

    if transposers == {} then
      D.WRN("No transposers found.")

      -- All perfectly fine and dandy though.
      return true
    end

    -- Add the machines.
    for transposer_address, transposer in pairs(transposers) do
      local line = "Setting up transposer " .. transposer.address .. " with " .. #transposer.interfaces .. " interface" .. (#transposer.interfaces > 1 and "s" or "")

      local i = 0
      for n, processor in pairs(transposer.processors) do
        if n == 1 then
          line = line .. ": " .. processor.label
        else
          line = line .. ", " .. processor.label
        end
      
        if not machines[processor.name] then
          machines[processor.name] = new_machine(processor.name)
        end

        table.insert(machines[processor.name].processors, {transposer = transposer, side = processor.side, running = false})
      end

      D.LOG(line .. ".")
    end

    if machines == {} then
      -- Still all completely okey.
      D.WRN("No machines found.")

      -- FIXME: Eventually hotplug will add machines to the machine object.
      --        At the moment, with no machines, the machine object is empty after setup(), and thus not very functional.
    end

    return true
  end


  -- Adds virtual machines and initializes everything.
  local function finalize_setup()
    for processor in pairs(processors.virtual()) do
      machines[processor] = new_machine(processor)
    end

    for machine_name, machine in pairs(machines) do
      processors.initialize_machine(machine)
    end
  end


  -- Body of machines.setup() --


  -- Also removes machines.setup().
  for k in pairs(machines) do
    machines[k] = nil
  end

  if filesystem.exists(shell.getWorkingDirectory() .. "/configuration.dat") then
    D.LOG("Found configuration.dat. Loading configuration from disk.")

    local configuration_data = io.open("configuration.dat", "rb")
    local configuration = serialization.unserialize(configuration_data:read("*a"))
    configuration_data:close()

    if validate_configuration(configuration) then
      D.LOG("Configuration validated.")
      D.LOG()

      finalize_setup()

      return true
    end

    D.LOG("Configuration update detected.")
  end

  local configuration = {
    known_processors = processors.all(),
    transposers = transposer_factory.detect_transposer_configuration(ignore_inventories, ignore_transposers)
  }

  if not validate_configuration(configuration) then
    D.ERR("validate_configuration() failed to validate detected configuration.")
    assert(false)
  end

  local configuration_data = io.open("configuration.dat", "wb")
  configuration_data:write(serialization.serialize(configuration))
  configuration_data:close()

  D.LOG("Setup complete.")
  D.LOG()

  finalize_setup()

  return true
end


return machines
