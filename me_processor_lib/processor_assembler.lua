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

function processor_craft.assembler(machine, processor, recipe, amount, status, item, slot_count, reserved_slots, slot_map)
  local assembler = component.getPrimary("assembler")
  assembler.start()
  os.sleep(0.1)
  
  while assembler.status() == "busy" do
    D.LOG("Assembling...")
    os.sleep(1)
  end

  -- Make room.
  processor.transposer:cancel_request(reserved_slots[1])

  -- And move.
  processor.transposer:move(processor.side, 1, reserved_slots[1].side, reserved_slots[1].slot, 1)

  D.LOG("Assembling done.")

  return 1
end
