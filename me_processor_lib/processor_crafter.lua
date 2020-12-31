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

local database = component.getPrimary("database")
local me_interface = component.getPrimary("me_interface")

function clear_crafter_inventory(processor)
  -- FIXME: Make more efficient.
  processor.transposer:move(processor.side, 1, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 2, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 3, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 5, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 6, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 7, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 9, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 10, processor.transposer.chest[1].side, 0, 64)
  processor.transposer:move(processor.side, 11, processor.transposer.chest[1].side, 0, 64)
end

function processor_setup.crafter(machine, processor, recipe, amount, status, item)
  clear_crafter_inventory(processor)
end

function processor_craft.crafter(machine, processor, recipe, amount, status, item, slot_count, reserved_slots, slot_map)
  local moved = 0

  repeat
    -- Move stick.
    if processor.transposer:move(processor.side, 4, processor.side, 8, 1) ~= 1 then    -- 1 Tick.
      D.WRN("Crafting stick is not where it should be.")
      return moved
    end

    while processor.transposer:count(processor.side, 4) == 0 do
      os.sleep(0.05)
      -- FIXME: add timeout.
    end

    local this_move = processor.transposer:move(processor.side, 12, processor.transposer.chest[1].side, 0, 64)    -- 1 Tick.
    this_move = this_move + processor.transposer:move(processor.side, 13, processor.transposer.chest[1].side, 0, 64)    -- 1 Tick.
    moved = moved + this_move
  until this_move == 0

  clear_crafter_inventory(processor)

  return moved
end

function processor_init.crafter(machine)
  -- FIXME: Enable robots and add sticks if needed.
end
