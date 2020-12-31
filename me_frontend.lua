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


local computer = require('computer')
local component = require('component')
local event = require('event')
local sides = require('sides')

local tunnel = component.getPrimary("tunnel")


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function is_stick(item)
  if item.name == "minecraft:stick" and item.damage == 0 then
    return true
  else
    return false
  end
end


local function count_sticks(transposer, side)
  local inventory = transposer.getAllStacks(side).getAll()
  
  local sticks = 0
  for n = 1, 5 do
    if inventory[n] and is_stick(inventory[n]) then
      sticks = sticks + inventory[n].size
    end
  end
  
  return sticks
end


local function clear_inventory(transposer, side)
  local inventory = transposer.getAllStacks(side).getAll()
  
  for n = 1, 5 do
    if inventory[n] and inventory[n].size ~= 0 then
      transposer.transferItem(side, sides.down, inventory[n].size, n)
    end
  end
end


local function check_transposer(transposer, side)
  local sticks = count_sticks(transposer, side)

  if sticks ~= 0 then
    print("Order for index: " .. sticks)
    tunnel.send(sticks)
    clear_inventory(transposer, side)
  end
end


local function main(args)
  while true do
    for address in pairs(component.list("transposer")) do
      local transposer = component.proxy(address)
      check_transposer(transposer, sides.east)
      check_transposer(transposer, sides.west)
    end

    os.sleep(0.5)
  end
end


main(require('shell').parse(...))
