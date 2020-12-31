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
local computer = require('computer')

local D = require('me_processor_lib.debug')
local lib = require('me_processor_lib.library')
local interface_factory = require('me_processor_lib.interface_factory')
local processors = require('me_processor_lib.processors')

local database = component.getPrimary("database")

local INTERFACE_ID = "appliedenergistics2:interface"
local CHEST_ID = "minecraft:chest"
local HOPPER_ID = "minecraft:hopper"
local IRON_CHEST_ID = "ironchest:iron_chest"
local CRATE_ID = "actuallyadditions:block_giant_chest_large"
local BARREL_ID = "yabba:antibarrel"

local transposers = {}

-- Abstract away later to support multiple databases.
local database_size = -1
local database_slot_reserved = {}
local database_slots_free = 0


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- FIXME: TBD
local function check_hotplug()
  interface_factory.check_hotplug()

  D.ERR("transposer.check_hotplug() TBD")
  os.exit()
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function request_database_slots(count)
  if database_size < 0 then
    -- Hack to get database size.
--FIXME: Speed this up for now. 1 should be size of tier 1 database to speed it up too.
    database_size = 80
--    database_size = 1
    while pcall(database.get, database_size) do
      database_size = database_size + 1
    end
    
    -- Slot 1 is reserved for temporary use.
    database_slot_reserved[1] = true
    database_slots_free = database_size - 1
  end

  if database_slots_free < count then
    return false
  end

  database_slots_free = database_slots_free - count
  local slots = {}

  local claimed = 0
  for n = 2, database_size do
    if not database_slot_reserved[n] then
      database_slot_reserved[n] = true
      table.insert(slots, n)

      claimed = claimed + 1
      if claimed == count then
        break
      end
    end
  end

  return slots  
end


local function release_database_slots(slots)
  for i, slot in pairs(slots) do
    if database_slot_reserved[slot] then
      database_slot_reserved[slot] = false
      database_slots_free = database_slots_free + 1
    else
      D.ERR("Request to release database slot which was not reserved.")
      assert(false)
    end
  end
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function request_slots(self, count)
  local database_slots = request_database_slots(count)

  if not database_slots then
    D.WRN("Not enough free database slots.")
    return false
  end

  -- FIXME: Just request interface 1 for now. Support multiple interfaces later.
  
  local interface_slots = self.interfaces[1].interface:request_slots(count)
  
  if not interface_slots then
    D.WRN("Not enough free interface slots.")
    release_database_slots(database_slots)
    return false
  end

  local slots = {}
  for n = 1, count do
    slots[n] = {side = self.interfaces[1].side, slot = interface_slots[n], database_slot = database_slots[n]}
  end

  return slots
end

local function release_slots(self, slots)
  local database_slots = {}
  local interface_slots = {}

  for i, slot in pairs(slots) do
    table.insert(database_slots, slot.database_slot)
    table.insert(interface_slots, slot.slot)
  end
  
  release_database_slots(database_slots)
  self.interfaces[1].interface:release_slots(interface_slots)
end

local function request_item(self, item_key, slot, amount)
  local item = lib.key_to_item(item_key)

  database.clear(slot.database_slot)
  self.interfaces[1].interface.interface.store({name = item.name, damage = item.damage}, database.address, slot.database_slot)

  self.interfaces[1].interface.interface.setInterfaceConfiguration(slot.slot, database.address, slot.database_slot, amount)
end

local function wait_for_request(self, slot, amount, timeout)
  if not timeout or timeout < 0 then
    timeout = 0
  end

  timeout = lib.now() + timeout

  repeat
    if (self.transposer.compareStackToDatabase(slot.side, slot.slot, database.address, slot.database_slot, true)) then
      if (self.transposer.getSlotStackSize(slot.side, slot.slot) == amount) then
        return true
      end
    end
  until lib.now() > timeout

  return false
end

local function cancel_request(self, slot)
  database.clear(slot.database_slot)
  self.interfaces[1].interface.interface.setInterfaceConfiguration(slot.slot)
end

local function move(self, source_side, source_slot, sink_side, sink_slot, amount)
  if sink_slot ~= 0 then
    return self.transposer.transferItem(source_side, sink_side, amount, source_slot, sink_slot)
  else
    return self.transposer.transferItem(source_side, sink_side, amount, source_slot)
  end
end

local function count(self, side, slot)
  return self.transposer.getSlotStackSize(side, slot)
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function get_transposer(transposer_address)
  if not transposers[transposer_address] then
    D.WRN("Request for an unknown transposer (" .. transposer_address .. ")?")
    return nil
  end
  
  return transposers[transposer_address]
end


-- Returns detected transposer configuration setup.
local function detect_transposer_setup(transposer_address, ignore_inventory)
  local transposer_setup = {interfaces = {}, processors = {}, inventories = {['chest'] = {}, ['hopper'] = {}, ['iron_chest'] = {}, ['crate'] = {}, ['barrel'] = {}}}
  local transposer = component.proxy(transposer_address)

  for side = 0, 5 do
    local inventory_name = transposer.getInventoryName(side)

    if inventory_name and not ignore_inventory[inventory_name] then
      if inventory_name == CHEST_ID then
        table.insert(transposer_setup.inventories.chest, {side = side})
      elseif inventory_name == HOPPER_ID then
        table.insert(transposer_setup.inventories.hopper, {side = side})
      elseif inventory_name == IRON_CHEST_ID then
        table.insert(transposer_setup.inventories.iron_chest, {side = side})
      elseif inventory_name == CRATE_ID then
        table.insert(transposer_setup.inventories.crate, {side = side})
      elseif inventory_name == BARREL_ID then
        table.insert(transposer_setup.inventories.barrel, {side = side})
      elseif inventory_name == INTERFACE_ID then
        if not transposer.compareStackToDatabase(side, 1, database.address, 1) then
          D.ERR("Transposer connected to an unconnected ME Interface.")
          D.ERR("Please connect the interface to both a working adapter and to the ME network.")
          -- FIXME: Is this still an hard error? Can't we now just ignore this interface?
          os.exit()
        end

        interface_address = interface_factory.identify(transposer.getSlotStackSize(side, 1))

        if not interface_address then
          D.ERR("Transposer connected to an unrecognized ME Interface (" .. transposer.getSlotStackSize(side, 1) .. ").")
          D.ERR("Please connect the interface to both a working adapter and to the ME network.")
          -- FIXME: Also, still an hard error?
          os.exit()
        end
        
        table.insert(transposer_setup.interfaces, {address = interface_address, side = side})
      else
        -- Pass transposer to do additional checks to identify the inventory (get number of tanks, etc.).
        local processor = processors.identify_processor(transposer, side)

        if processor then
          table.insert(transposer_setup.processors, {name = processor.name, label = processor.label, side = processor.side})
        end
      end
    end
  end

  return transposer_setup
end


-- Returns configuration.
local function detect_transposer_configuration(ignore_inventories, ignore_transposers)
  local transposer_configuration = {}

  local ignore_inventory = {}
  if ignore_inventories then
    for k, inventory_name in pairs(ignore_inventories) do
      ignore_inventory[inventory_name] = true
    end
  end

  local ignore_transposer = {}
  if ignore_transposer then
    for k, transposer_address in pairs(ignore_transposers) do
      ignore_transposer[transposer_address] = true
    end
  end

  interface_factory.start_identification()
  
  for transposer_address, type in pairs(component.list("transposer", true)) do
    if not ignore_transposer[transposer_address] then
      local line = "Detecting transposer setup: " .. transposer_address .. "... "

      local current_transposer_configuration = detect_transposer_setup(transposer_address, ignore_inventory)
      D.LOG(line .. "Interfaces: " .. #current_transposer_configuration.interfaces .. " Processors: " .. #current_transposer_configuration.processors .. ".")

      if transposer_configuration[transposer_address] then
        D.ERR("Transposer already detected before?")
        assert(false)
      end

      transposer_configuration[transposer_address] = current_transposer_configuration

      os.sleep(0)
    end
  end

  interface_factory.end_identification()
  
  -- FIXME: There is an undetected failure case here.
  --        If an interface with no adapter is connected to a transposer and has sticks in slot 1, it can clash with another interface.
  --        Might happen if an interface gets disconnected from it's adapter in the identification phase.
  --        On the next detection run, another interface will have the same amount of sticks, and thus we clash if the transposer
  --        first checking it's interfaces happen to be connected to the now unconnected interface.
  --        Can be fixed by having the transposer reset the interface and checking if it worked?
  --        Not a very clean solution though, so come up with a better one (this failure will not trigger any time soon anyway).

  return transposer_configuration
end


-- Validates configuration and creates transposer and interface objects. Returns all transposers.
local function validate_transposer_configuration(configuration)
  transposers = {}

  if configuration == {} then
    D.WRN("WARNING: No transposers found.")
    D.WRN("         Please setup a valid Adapter <-> Interface <-> Transposer <-> Machine setup and hook it up.")

    -- No transposers is still a valid configuration. Just won't do much.
    return true
  end

  for transposer_address, transposer_configuration in pairs(configuration) do
    if transposers[transposer_address] then
      D.WRN("Duplicate transposer found (" .. transposer_address .. ").")
      transposers = {}
      return false
    end

    local transposer = {
      address = transposer_address,
      transposer = component.proxy(transposer_address),
      interfaces = {},
      processors = {},
      inventories = {},
      check_hotplug = check_hotplug,
      request_slots = request_slots,
      release_slots = release_slots,
      request_item = request_item,
      wait_for_request = wait_for_request,
      cancel_request = cancel_request,
      move = move,
      count = count
    }

    if not transposer.transposer then
      D.LOG("Transposer " .. transposer_address .. " has been removed.")
      transposers = {}
      return false
    end

    if not transposer_configuration.interfaces or #transposer_configuration.interfaces == 0 then
      D.WRN("Transposer " .. transposer_address .. " has no interfaces.")
    else
      for n, interface in pairs(transposer_configuration.interfaces) do
        if not component.proxy(interface.address) then
          D.LOG("Interface or adapter to interface " .. interface.address .. " has been removed.")
          transposers = {}
          return false
        end

        table.insert(transposer.interfaces, {address = interface.address, side = interface.side, interface = interface_factory.get(interface.address)})
      end
    end

    -- If addresses didn't change, then block position didn't change, so transposer and interface are still connected on the correct sides.
    -- Let us assume nobody edits configuration.dat and data error is not a thing.

    if transposer_configuration.processors and #transposer_configuration.processors ~= 0 then
      for n, processor in pairs(transposer_configuration.processors) do
        local current_processor = processors.identify_processor(transposer.transposer, processor.side)

        if not current_processor or processor.name ~= current_processor.name then
          D.LOG("Transposer access to " .. processor.label .. " has been changed or removed.")
          transposers = {}
          return false
        else
          table.insert(transposer.processors, {name = processor.name, label = processor.label, side = processor.side})
        end
      end
    end

    -- FIXME: Check connected inventories.
    transposer.inventories = transposer_configuration.inventories
    for inventory_type, inventory in pairs(transposer.inventories) do
      if #inventory then
        transposer[inventory_type] = inventory
      end
    end

    transposers[transposer_address] = transposer
  end

  return transposers
end


-- Returns current configuration (for hotplug).
local function get_transposer_configuration()
  local configuration = {}

  for transposer_address, transposer in pairs(transposers) do
    -- Don't save transposers with no interfaces or no processors.
    if #transposer.interfaces ~= 0 and #transposer.processors ~= 0 then
      configuration[transposer_address] = {interfaces = {}, processors = {}, inventories = {}}

      for interface in transposer.interfaces do
        table.insert(configuration[transposer_address].interfaces, {address = interface.address, side = interface.side})
      end

      for processor in transposer.processors do
        table.insert(configuration[transposer_address].processors, {name = processor.name, label = processor.label, side = processor.side})
      end

      for inventory in transposer.inventories do
        table.insert(configuration[transposer_address].inventories, {type = inventory.type, side = inventory.side})
      end
    end
  end
    
  return configuration
end


return {
  get_transposer = get_transposer,
  detect_transposer_configuration = detect_transposer_configuration,
  validate_transposer_configuration = validate_transposer_configuration,
  get_transposer_configuration = get_transposer_configuration
}
