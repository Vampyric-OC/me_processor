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

local component = require('component')

local D = require('me_processor_lib.debug')
local lib = require('me_processor_lib.library')

local database = component.getPrimary("database")

local emc = {}
local in_emc = {}

local function update_duplication(transposer, emc_side, duplication_side)
  in_emc = {}

  for n, item in pairs(transposer.getAllStacks(emc_side).getAll()) do
    if item.size > 0 then
      in_emc[lib.item_to_key(item)] = n
    end
  end

  duplication_room = 54
  in_duplication = {}
  for n, item in pairs(transposer.getAllStacks(duplication_side).getAll()) do
    if item.size > 0 then
      in_duplication[item.name .. "|" .. math.floor(item.damage)] = true
      duplication_room = duplication_room - 1
    end
  end

  D.LOG("Duplication room: " .. duplication_room)
end

-- FIXME: Hack & slack to get it working. Do it better.
local function handle_emc_duplicate(machine, item_key, amount)
  local transposer = machine.processors[1].transposer.transposer
  local emc_side = machine.processors[1].side
  local duplication_side = machine.processors[1].transposer.iron_chest[1].side
  local interface = machine.processors[1].transposer.interfaces[1].interface.interface
  local interface_side = machine.processors[1].transposer.interfaces[1].side

  update_duplication(transposer, emc_side, duplication_side)
  
  if in_emc[item_key] then
    D.LOG("Getting " .. math.floor(amount) .. " " .. lib.key_to_label(item_key) .. " from EMC.")
    local max_size = lib.key_to_max_size(item_key)

    local moved = transposer.transferItem(emc_side, duplication_side, 15, in_emc[item_key])
    
    while moved < amount do
      local current_move = amount - moved
      
      if current_move > max_size then
        current_move = max_size
      end

      local current_moved = transposer.transferItem(emc_side, interface_side, current_move, in_emc[item_key])
      
      if current_moved == 0 then
        break
      end
      
      moved = moved + current_moved
    end

    return
  end

  if in_duplication[item_key] or duplication_room == 0 then
    return
  end

  D.LOG("Requesting " .. lib.key_to_label(item_key) .. " to be duplicated.")

  -- FIXME: Use reseved interface slots instead of slot 1.
  local reserved_slots = machine.processors[1].transposer:request_slots(1)

  database.clear(reserved_slots[1].database_slot)
  local item = lib.key_to_item(item_key)
  interface.store({name = item.name, damage = item.damage}, database.address, reserved_slots[1].database_slot)
  interface.setInterfaceConfiguration(1, database.address, reserved_slots[1].database_slot, 1)

  while not transposer.compareStackToDatabase(interface_side, 1, database.address, reserved_slots[1].database_slot, true) do
    os.sleep(0.05)
  end

  transposer.transferItem(interface_side, duplication_side, 1)

  database.clear(reserved_slots[1].database_slot)
  interface.setInterfaceConfiguration(1)
  machine.processors[1].transposer:release_slots(reserved_slots)

  duplication_room = duplication_room - 1
  in_duplication[item_key] = true
end


local function update_duplication()
  in_emc = {}
  for i, item in pairs(transposer.getAllStacks(emc_side).getAll()) do
    if item.size > 0 then
      in_emc[item.name .. "|" .. math.floor(item.damage)] = i
    end
  end

  duplication_room = 54
  in_duplication = {}
  for i, item in pairs(transposer.getAllStacks(duplication_side).getAll()) do
    if item.size > 0 then
      in_duplication[item.name .. "|" .. math.floor(item.damage)] = true
      duplication_room = duplication_room - 1
    end
  end

  D.LOG("Duplication room: " .. duplication_room)
end


function processor_handler.emc(machine, processor, request, amount)
  -- Reuse the generic handler for processing.
  if request.recipe then
    processor_handler.generic(machine, processor, request, amount)
  elseif request.duplicate then
    handle_emc_duplicate(machine, request.duplicate, amount)
  else
    D.WRN("Queued request invalid for EMC. Ignored request.")
  end
end


local function load_emc()
  local start_time = lib.now()
  D.LOG("Reading EMC table...")

  emc = io.open("emc", "rb")
  local emc_data = emc:read("*a")
  emc:close()

  emc = {}

  os.sleep(0)
  local last_sleep = lib.now()
  for line in string.gmatch(emc_data, "([^\n]+)") do
    if line == "" then
      break
    end

    local part = string.gmatch(line, "([^\t]+)")
    local item_key = part()
    local emc_value = part()

    emc[item_key] = tonumber(emc_value)

    if lib.now() - last_sleep > 0.1 then
      os.sleep(0)
      last_sleep = lib.now()
    end  
  end

  D.LOG("EMC table loaded in " .. string.format("%0.2f", (lib.now() - start_time)) .. "s.")
  D.LOG()
end

local function value(self, item_key)
  if emc[item_key] then
    return emc[item_key]
  end
  
  return 0
end

function processor_init.emc(machine)
  --load_emc()

  machine.value = value
end
