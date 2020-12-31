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


local robot = require("robot")
local component = require("component")
local inventory_controller = component.getPrimary("inventory_controller")
local crafting = component.getPrimary("crafting")

local NEXT_ICE_AGE = false

robot.select(12)

repeat
  os.sleep(0) -- Yield
  local stick = inventory_controller.getStackInInternalSlot(8)    -- 1 Tick.

  if stick and stick.name == "minecraft:stick" then
    crafting.craft(64)    -- 1 Tick.
  
    robot.select(8)    -- 0 or 1 Ticks?
    robot.transferTo(4, 1)    -- 1 Tick.

    robot.select(12)    -- 0 or 1 Ticks?
  end
until NEXT_ICE_AGE
