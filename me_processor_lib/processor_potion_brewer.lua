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

local D = require('me_processor_lib.debug')

-- FIXME: TBD. This code is dead.
function processor_handler.potion_brewer(machine)
--[[
  repeat
    if machine.queue[1].recipe then
      local recipe = machine.queue[1].recipe
      local amount = machine.queue[1].amount
      table.remove(machine.queue, 1)

      for slot, item_key in pairs(recipe.slots) do
        request_item(machine, item_key, slot, 64)
      end

      for slot, item_key in pairs(recipe.slots) do
        wait_for_request(machine, item_key, slot, 64, 1)
      end

      for slot, item in pairs(recipe.slots) do
        D.LOG(move_items(machine, machine.interface_side, slot, machine.processor_side, machine.slot_map[slot], 64))
      end

      for slot, item in pairs(recipe.slots) do
        machine.interface.setInterfaceConfiguration(slot)
      end
    else
      D.WRN("Queued request was not a recipe. Ignored request.")
      table.remove(machine.queue, 1)
    end
  until #machine.queue == 0
--]]
  D.WRN("Potion requests ignored for now.")

  repeat
    table.remove(machine.queue, 1)
  until #machine.queue == 0
end
