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
local serialization = require('serialization')

local D = require('me_processor_lib.debug')

local database = component.getPrimary("database")
local me_interface = component.getPrimary("me_interface")

local lib = {}

function lib.item_to_key(item, damage, amount)
  if item.name then
    return item.name .. "|" .. math.floor(item.damage)
  else
    if amount then
      return item .. "|" .. math.floor(damage) .. "*" .. math.floor(amount)
    else
      return item .. "|" .. math.floor(damage)
    end
  end
end

function lib.key_to_item(key)
  local item = {}
  local field = {}
  local i = 1

  for s in string.gmatch(key, "[^|]+") do
    field[i] = s
    i = i + 1
  end

  if i ~= 3 then
    D.ERR("Item key '" .. key .. "' is not valid.")
    assert(false)
  end

  item.name = field[1]

  i = 1
  for s in string.gmatch(field[2], "[^*]+") do
    field[i] = s
    i = i + 1
  end

  if i == 2 then
    item.damage = tonumber(field[1])
  elseif i == 3 then
    item.damage = tonumber(field[1])
    item.amount = tonumber(field[2])
  else
    D.ERR("Item key '" .. key .. "' is not valid.")
    assert(false)
  end

  return item
end

function lib.key_to_label(item_key)
  local item = lib.key_to_item(item_key)

  database.clear(1)
  me_interface.store({name = item.name, damage = item.damage}, database.address, 1)
  item = database.get(1)
  database.clear(1)

  if item then
    return item.label
  else
    return item_key
  end
end

function lib.key_to_max_size(item_key)
  local item = lib.key_to_item(item_key)

  database.clear(1)
  me_interface.store({name = item.name, damage = item.damage}, database.address, 1)
  item = database.get(1)
  database.clear(1)

  if item then
    return item.maxSize
  else
    return 64    -- FIXME: Maybe 1? Or false?
  end
end

function lib.item_to_label(item)
  if item.label then
    return item.label
  else
    return lib.item_to_key(item)
  end
end

function lib.now()
  return computer.uptime()
end

function lib.sleep_until(time)
  os.sleep(time - lib.now())
end

return lib
