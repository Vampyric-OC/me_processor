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

function processor_init.loot_opener(machine)
  if not machine.processors[1].transposer.barrel[1] then
    D.ERR("Found a Bag Opener without an Anti Barrel.")
    os.exit()
  end

  -- Small hack to make loot bags go into the Anti Barrel instead of the Bag Opener directly. This saves us making a special handler for the loot opener.
  machine.processors[1].processor_side = machine.processors[1].transposer.barrel[1].side
end
