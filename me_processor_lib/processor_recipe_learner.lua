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


-- Hard coded. No idea how to get this automatically without a geolyzer.
local NOTEBLOCK_ADDRESS = "49a1223e-bf6b-4633-85f6-068d9cb6c56e"
local INVENTORY_CONTROLLER_ADDRESS = "7f43ce63-25d2-49dc-84a6-082c1d609054"
local NOTEBLOCK_SIDE = require('sides').up
local CRAFTER_SIDE = require('sides').east


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local component = require('component')
local serialization = require('serialization')

local D = require('me_processor_lib.debug')
local lib = require('me_processor_lib.library')
local me_processor_thread = require('me_processor_lib.me_processor_thread')

local AIR = "minecraft:air|0"

-- FIXME: Re-add support for the analog crafter too.
--local analog_crafter_slot_map = {[1] = 9, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7, [8] = 8, [9] = 9, [10] = 10}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function beep_ok()
  local noteblock = component.proxy(NOTEBLOCK_ADDRESS)

  noteblock.setOutput(NOTEBLOCK_SIDE, 15)
  noteblock.setOutput(NOTEBLOCK_SIDE, 0)
end

-- Don't...
local function beep_warn()
  beep_ok()
  beep_ok()
end

-- judge me...
local function beep_error()
  beep_ok()
  beep_ok()
  beep_ok()
end


local function learn_recipe(item_key, amount, inventory)
  if item_key == AIR then
    return
  end

  if recipes[item_key] then
    beep_warn()
    return
  end
  
  local recipe = {machine = "crafter", amount = amount, slots = {}}

  -- Fixme: Also store somewhere, in a cache or database or something.
  local item_label = lib.item_to_label(inventory[10])

  for n = 1, 9 do
    local recipe_item = inventory[n]
    local recipe_item_key = lib.item_to_key(recipe_item)
    
    if recipe_item_key ~= AIR then
      recipe.slots[n] = recipe_item_key
    end
  end

  recipes[item_key] = recipe

  local recipe_data = io.open("recipes.dat", "wb")
  recipe_data:write(serialization.serialize(recipes))
  recipe_data:close()

  D.LOG("Learned recipe for " .. item_label)

  beep_ok()
end


local function recipe_learner()
  local crafter = component.proxy(INVENTORY_CONTROLLER_ADDRESS)
  local current_item_key = AIR

  repeat
    local inventory = crafter.getAllStacks(CRAFTER_SIDE)
    
    if inventory then
      local item_key = lib.item_to_key(inventory[10])
      
      if item_key ~= current_item_key then
        learn_recipe(item_key, inventory[1].size, inventory)

        current_item_key = item_key
      end
    end

    os.sleep(1)
  until "gained_all_knowlage_in_the_universe" == "yes"
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function start()
  me_processor_thread.create(recipe_learner)
end


function processor_init.recipe_learner(machine)
  machine.start = start
end
