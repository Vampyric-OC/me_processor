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

local database = component.getPrimary("database")

local STICK = "minecraft:stick|0"

local interfaces = {}
local interface_identification = {}


local function request_slots(self, count)
  if self.slots_free < count then
    return false
  end

  self.slots_free = self.slots_free - count
  local slots = {}

  for n = 1, 9 do
    if not self.slot_reserved[n] then
      self.slot_reserved[n] = true
      table.insert(slots, n)

      count = count - 1
      if count == 0 then
        break
      end
    end
  end

  return slots  
end


local function release_slots(self, slots)
  for i, slot in pairs(slots) do
    if self.slot_reserved[slot] then
      self.slot_reserved[slot] = false
      self.slots_free = self.slots_free + 1
    else
      D.ERR("INTERNAL ERROR: Request to release interface slot which was not reserved.")
      assert(false)
    end
  end
end


-- Creates interface if needed.
local function get(interface_address)
  if not interfaces[interface_address] then
    local interface = {
      address = interface_address,
      interface = component.proxy(interface_address),
      request_slots = request_slots,
      release_slots = release_slots,
      slot_reserved = {},
      slots_free = 9
    }

    if not interface.interface then
      D.ERR("Request for an unknown interface (" .. interface_address .. ")?")
      assert(false)
    end
    
    interfaces[interface_address] = interface
  end
  
  return interfaces[interface_address]
end


-- FIXME: TBD
local function check_hotplug()
end


local function start_identification()
  local me_interface = component.getPrimary("me_interface")
  local me_interfaces = component.list("me_interface", true)
  local sticks = me_interface.getItemsInNetwork(lib.key_to_item(STICK))

  if not sticks[1] or sticks[1].size < (#me_interfaces * (#me_interfaces + 1) / 2) then
    D.ERR("Not enough sticks (" .. (#me_interfaces * (#me_interfaces + 1) / 2) .. " needed).")
    os.exit()
  end

  io.write("Detecting interfaces")

  database.clear(1)
  me_interface.store(lib.key_to_item(STICK), database.address, 1)

  interface_identification = {}
  local n = 1
  for interface_address, type in pairs(me_interfaces) do
    io.write(".")
    os.sleep(0)
    component.proxy(interface_address).setInterfaceConfiguration(1, database.address, 1, n)
    interface_identification[n] = {address = interface_address, connected = false}
    n = n + 1
  end

  print()
end


local function identify(n)
  if not interface_identification[n] then
    D.WRN("WARNING: Identification request for an unknown interface (" .. n .. ").")
    return nil
  end

  interface_identification[n].connected = true
  return interface_identification[n].address
end


local function end_identification()
  database.clear(1)

  io.write("Resetting interfaces")

  for interface_address, type in pairs(component.list("me_interface", true)) do
    io.write(".")
    os.sleep(0)
    component.proxy(interface_address).setInterfaceConfiguration(1)
  end

  -- FIXME: Borderline undetected failure case:
  --        If an interface is disconnected from an adapter and has already got sticks in it, it can clash with a connected interface.
  --        We can check all transposers again to see if all interfaces have indeed reset just to make sure.

  print()

  -- Report unfound interfaces.
  for n, interface in pairs(interface_identification) do
    if not interface.connected then
      -- FIXME: Would be wonderful if we could get the adapter address too. Makes finding the interface a bit easier.
      D.WRN("ME Interface " .. interface.address .. " not connected to any transposer.")
    end
  end

--[[
  make this a function

  io.write("Resetting interfaces")

-- FIXME: Can we do a fast reset?
--        If we have a full configuration we can use transposers to check inventories of intefaces.
--        Is getInterfaceConfiguration instant?
  database.clear(1)
  for interface_address, type in pairs(interfaces) do
    -- FIXME: 5/24 instead of dots.
    io.write(".")
    for i = 1, 9 do
      for k, v in pairs(component.proxy(interface_address).getInterfaceConfiguration(i)) do
--        print(k,v)
      end
    end
    
    component.proxy(interface_address).setInterfaceConfiguration(1)
  end
os.exit()
--]]

end


return {
  get = get,
  check_hotplug = check_hotplug,
  identify = identify,
  start_identification = start_identification,
  end_identification = end_identification
}
