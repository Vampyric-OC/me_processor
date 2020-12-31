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
local serialization = require('serialization')

local D = require('me_processor_lib.debug')
local lib = require('me_processor_lib.library')
local machines = require('me_processor_lib.machines')
local me_processor_thread = require('me_processor_lib.me_processor_thread')

local me_interface = component.getPrimary("me_interface")


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- FIXME: Hardcoded for now. Should be able to be detected and used if available.
--        Compacting Drawer tester can be a special processor or special device?
--        Learner, drawer and barrel storage could all be special devices, they are inventory controllers.
--        For the compacting tester we need a special processor, it needs a valid transposer.

-- FIXME: Defined as global in me_processor.lua for now.
--local DRAWER_ADDRESS = "9619ff36-c6a3-45e2-982f-6dbd0639ecce"
--local BARREL_ADDRESS = "5d11f10c-f3b6-4ff3-8878-888e50b4a526"

-- Only recycle when there is at least a stack to recycle. Saves lots of recycle runs.
local SANE_RECYCLER = true

local DRAWER_MIN = 2500
local DRAWER_TARGET = 5000
local DRAWER_MAX = 10000

local ME_MIN = 1000
local ME_TARGET = 2000
local ME_MAX = 4000

local BARREL_MIN = 100
local BARREL_TARGET = 250
local BARREL_MAX = 10000

local watch_list = {
  ['minecraft:stick|0']   = {min = 1000},
  ['mekanism:sawdust|0']  = {min = 100, target = 200, max = 300}
}

-- These items are processed when above the MAX values.
local recycle_list = {
  "appliedenergistics2:quartz_ore|0", "chisel:marble2|7", "galacticraftcore:basic_block_core|8", "lordcraft:orecrystalb|0",
  "mekanism:oreblock|0", "minecraft:coal_ore|0", "minecraft:diamond_ore|0", "minecraft:gold_ore|0", "minecraft:iron_ore|0",
  "minecraft:lapis_ore|0", "minecraft:redstone_ore|0", "mysticalagriculture:prosperity_ore|0", "mysticalagriculture:inferium_ore|0",
  "netherendingores:ore_other_1|0", "nuclearcraft:ore|4", "nuclearcraft:ore|5", "nuclearcraft:ore|6", "nuclearcraft:ore|7",
  "projectred-exploration:ore|0", "projectred-exploration:ore|1", "projectred-exploration:ore|2", "projectred-exploration:ore|6",
  "thermalfoundation:material|800", "thermalfoundation:material|893", "thermalfoundation:ore|0", "thermalfoundation:ore|1",
  "thermalfoundation:ore|2", "thermalfoundation:ore|3", "thermalfoundation:ore|4", "thermalfoundation:ore|5", "thermalfoundation:ore|6",
  "thermalfoundation:ore|8", "thermalfoundation:ore_fluid|2", "thermalsolars:blocklunarorenether|0", "thermalsolars:blocktitaniumore|0",
  "xreliquary:mob_ingredient|0", "xreliquary:mob_ingredient|2", "xreliquary:mob_ingredient|3", "xreliquary:mob_ingredient|4",
  "xreliquary:mob_ingredient|6", "xreliquary:mob_ingredient|10", "xreliquary:mob_ingredient|11", "xreliquary:mob_ingredient|12", 
  "draconicevolution:draconium_ore|0", "nuclearcraft:ore|3", "minecraft:emerald_ore|0",
  "mysticalagriculture:crafting|0", "mysticalagriculture:crafting|1", "mysticalagriculture:crafting|2",
  "mysticalagriculture:crafting|3", "mysticalagriculture:crafting|4", "thermalsolars:itemtitaniumdust|0",
  "mysticalagriculture:lithium_essence|0", "mysticalagriculture:terrasteel_essence|0"
}

-- Defines one or more processors for an item and how to process that item.
local process_list = {
  ['lootbags:itemlootbag|0']   = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|1']   = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|2']   = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|3']   = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|4']   = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|9']   = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|11']  = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|12']  = {{processor = "loot_opener"}},
  ['lootbags:itemlootbag|14']  = {{processor = "loot_opener"}},

  ['lootbags:itemlootbag|13']  = {{processor = "patient_loot_opener"}},

  ['lordcraft:orecrystalb|0']   = {{processor = "fortune_miner"}},
  ['minecraft:lapis_ore|0']     = {{processor = "fortune_miner"}},
  ['minecraft:redstone_ore|0']  = {{processor = "fortune_miner"}},

  ['mekanism:oreblock|0']                = {{processor = "furnace"}},
  ['minecraft:coal_ore|0']               = {{processor = "furnace"}},
  ['minecraft:diamond_ore|0']            = {{processor = "furnace"}},
  ['minecraft:gold_ore|0']               = {{processor = "furnace"}},
  ['minecraft:iron_ore|0']               = {{processor = "furnace"}},
  ['netherendingores:ore_other_1|0']     = {{processor = "furnace"}},
  ['nuclearcraft:ore|4']                 = {{processor = "furnace"}},
  ['nuclearcraft:ore|5']                 = {{processor = "furnace"}},
  ['nuclearcraft:ore|6']                 = {{processor = "furnace"}},
  ['nuclearcraft:ore|7']                 = {{processor = "furnace"}},
  ['projectred-exploration:ore|0']       = {{processor = "furnace"}},
  ['projectred-exploration:ore|1']       = {{processor = "furnace"}},
  ['projectred-exploration:ore|2']       = {{processor = "furnace"}},
  ['projectred-exploration:ore|6']       = {{processor = "furnace"}},
  ['thermalfoundation:ore|0']            = {{processor = "furnace"}},
  ['thermalfoundation:ore|1']            = {{processor = "furnace"}},
  ['thermalfoundation:ore|2']            = {{processor = "furnace"}},
  ['thermalfoundation:ore|3']            = {{processor = "furnace"}},
  ['thermalfoundation:ore|4']            = {{processor = "furnace"}},
  ['thermalfoundation:ore|5']            = {{processor = "furnace"}},
  ['thermalfoundation:ore|6']            = {{processor = "furnace"}},
  ['thermalfoundation:ore|8']            = {{processor = "furnace"}},
  ['thermalsolars:itemlunardust|0']      = {{processor = "furnace"}},
  ['thermalsolars:itemtitaniumdust|0']   = {{processor = "furnace"}},
  ['draconicevolution:draconium_ore|0']  = {{processor = "furnace"}},
  ['nuclearcraft:ore|3']                 = {{processor = "furnace"}},
  ['minecraft:emerald_ore|0']            = {{processor = "furnace"}},

  ['chisel:marble2|7']                          = {{processor = "crafter", recipe = "projectred-exploration:stone|1"}},
  ['thermalfoundation:material|800']            = {{processor = "crafter", recipe = "minecraft:paper|0", ratio = 6 / 3}},
  ['xreliquary:mob_ingredient|0']               = {{processor = "crafter", recipe = "minecraft:bone|0", ratio = 5 / 1}},
  ['xreliquary:mob_ingredient|2']               = {{processor = "crafter", recipe = "minecraft:spider_eye|0", ratio = 2 / 2}},
  ['xreliquary:mob_ingredient|3']               = {{processor = "crafter", recipe = "minecraft:gunpowder|0", ratio = 6 / 1}},
  ['xreliquary:mob_ingredient|4']               = {{processor = "crafter", recipe = "minecraft:slime_ball|0", ratio = 6 / 1}},
  ['xreliquary:mob_ingredient|6']               = {{processor = "crafter", recipe = "minecraft:gold_nugget|0", ratio = 6 / 2}},
  ['xreliquary:mob_ingredient|10']              = {{processor = "crafter", recipe = "minecraft:snowball|0", ratio = 5 / 1}},
  ['xreliquary:mob_ingredient|11']              = {{processor = "crafter", recipe = "minecraft:ender_pearl|0", ratio = 3 / 1}},
  ['xreliquary:mob_ingredient|12']              = {{processor = "crafter", recipe = "minecraft:dye|0", ratio = 6 / 1}},
  ['mysticalagriculture:crafting|0']            = {{processor = "crafter", recipe = "mysticalagriculture:crafting|1", ratio = 1 / 4}},
  ['mysticalagriculture:crafting|1']            = {{processor = "crafter", recipe = "mysticalagriculture:crafting|2", ratio = 1 / 4}},
  ['mysticalagriculture:crafting|2']            = {{processor = "crafter", recipe = "mysticalagriculture:crafting|3", ratio = 1 / 4}},
  ['mysticalagriculture:crafting|3']            = {{processor = "crafter", recipe = "mysticalagriculture:crafting|4", ratio = 1 / 4}},
  ['mysticalagriculture:crafting|4']            = {{processor = "crafter", recipe = "mysticalagradditions:insanium|0", ratio = 1 / 4}},
  ['mysticalagriculture:lithium_essence|0']     = {{processor = "crafter", recipe = "nuclearcraft:ingot|6", ratio = 3 / 8}},
  ['mysticalagriculture:terrasteel_essence|0']  = {{processor = "crafter", recipe = "botania:manaresource|4", ratio = 2 / 8}},

  ['thermalsolars:blocklunarorenether|0']  = {{processor = "crusher"}},
  ['thermalfoundation:material|893']       = {{processor = "magma_crucible"}},
  ['galacticraftcore:basic_block_core|8']  = {{processor = "double_crusher"}},

  ['appliedenergistics2:quartz_ore|0']      = {{processor = "sag_mill"}, {processor = "pulverizer"}},
  ['mysticalagriculture:inferium_ore|0']    = {{processor = "sag_mill"}, {processor = "pulverizer"}},
  ['mysticalagriculture:prosperity_ore|0']  = {{processor = "sag_mill"}, {processor = "pulverizer"}},
  ['thermalfoundation:ore_fluid|2']         = {{processor = "sag_mill"}, {processor = "pulverizer"}},
  ['thermalsolars:blocktitaniumore|0']      = {{processor = "sag_mill"}, {processor = "pulverizer"}}
}



-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function process(name, damage, amount)
  -- FIXME: Yah... we need a generic item object... This is just silly.
  local item_key = lib.item_to_key(name, damage)
  local item_label = lib.key_to_label(item_key)
  local item = lib.key_to_item(item_key)
  if item_label then
    item.label = item_label
  end
  local processors = process_list[item_key]

  if not processors then
    D.WRN("Do not know how to process " .. item_key .. ".")
    return 0
  end

  -- FIXME: Take care of situtions where the sag mill is done, but pulverizer still has some item queued.
  --        Recycler does not consider what's on the queues at the moment.
  --        Ties in with reserved_items above.
  for n = 1, #processors do
    local processor = processors[n]
    local recipe

    if processor.processor == "crafter" then
      local item = lib.key_to_item(processor.recipe)

      recipe = recipes[processor.recipe]

      if not recipe then
        D.WRN("Do not know how to craft " .. item_key .. " to " .. processor.recipe .. ".")
        return 0
      end

      if processor.ratio then
        amount = math.floor(amount * processor.ratio)
      end
    else
      -- Make recipe on the fly.
      recipe = {machine = processor.processor, amount = 1, slots = {[1] = item_key}}
    end

    local machine = machines[processor.processor]

    if not machine then
      D.WRN("Could not find " .. processor.processor .. "?")
      return 0
    end

    machine:queue_add({recipe = recipe, amount = amount, status = "Processing", item = item})
  end
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- FIXME: From cleanup. Needs to be updated and added as special devices.
local sides = require('sides')

local drawers = component.proxy(DRAWER_ADDRESS)
local barrel = component.proxy(BARREL_ADDRESS)
local drawers_side = sides.north
local compactor_side = sides.down
local in_drawers = {}
local is_compactable = {}

local function read_drawers()
  in_drawers = {}
  
  for i, stack in pairs(drawers.getAllStacks(drawers_side).getAll()) do
    in_drawers[stack.name .. "|" .. math.floor(stack.damage)] = true
  end
end

local function read_compactable()
  is_compactable = {}
  
  local compactable_data = io.open("compactable.dat", "rb")

  if compactable_data ~= nil then
    is_compactable = serialization.unserialize(compactable_data:read("*a"))
    compactable_data:close()
  end

  if is_compactable == nil then
    is_compactable = {}
  end
end


local function compactable(item)
  local item_key = item.name .. "|" .. math.floor(item.damage)

  if not in_drawers[item_key] then
    return false
  end

  if is_compactable[item_key] ~= nil then
    return is_compactable[item_key]
  end

  if item.size < 9 then
    return false
  end

  local drawer_slot = 0
  for i, stack in pairs(drawers.getAllStacks(drawers_side).getAll()) do
    if (stack.name == item.name) and (stack.damage == item.damage) then
      drawer_slot = i
      break
    end
  end
  
  if (drawer_slot == 0) then
    D.WRN("Could not find " .. item_key .. " in drawers?")
    
    return false
  end

  drawers.transferItem(drawers_side, compactor_side, 9, drawer_slot)
  local compactor_slot = 0

  for i, stack in pairs(drawers.getAllStacks(compactor_side).getAll()) do
    if (stack.size == 9) then
      compactor_slot = i
    elseif (stack.size > 0) and (stack.size < 9) then
      is_compactable[item_key] = true
    end
  end

  if (compactor_slot == 0) then
    D.WRN("Could not find " .. item_key .. " in compactor? Flushing Compactor...")
    drawers.transferItem(compactor_side, drawers_side, 9*9*9)
  else
    drawers.transferItem(compactor_side, drawers_side, 9, compactor_slot)
  end

  if is_compactable[item_key] == nil then
    is_compactable[item_key] = false
  end

  local compactable_data = io.open("compactable.dat", "wb")
  compactable_data:write(serialization.serialize(is_compactable))
  compactable_data:close()

  return is_compactable[item_key]
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- FIXME: Mainly a straight copy from cleanup. Probably need to clean this up a bit.
local function recycler()
  while true do
    D.LOG("Starting cleanup...")

    read_drawers()

    local filter = {hasTag = false, maxDamage = 0}  -- Preselection.
    local items = me_interface.getItemsInNetwork(filter)

    if not items then
      items = {n = 0}
    end

    D.LOG("Selected " .. items.n .. " types of items to consider for recycling...")
    
    local next_yield = lib.now() + 0.25  -- Be nice and yield every 5 ticks.
    for n = 1, items.n do
      if lib.now() > next_yield then
        os.sleep(0)
        next_yield = lib.now() + 0.25
      end

      local item = items[n]
      if item.maxSize > 1 then  -- FIXME hack to filter out barrel items. Do it properly with a barrel check.
        local item_key = lib.item_to_key(item)
        local emc_value = machines.emc:value(item_key) or 0
        -- FIXME: machine.compactable:is_compactable(item_key)?
        --        And of course machine.drawers:in_drawers(item_key) or something.
        --        Abstract everything out of here to the machines interface.
        --        Can be a special class of machine, like analyser. Also good or the recipe learner.
        if emc_value > 0 then
          if in_drawers[item_key] and not compactable(item) and item.size > DRAWER_MAX then
            if not SANE_RECYCLER or item.size - 64 > DRAWER_MAX then
              machines.emc:queue_add({recipe = {amount = 1, slots = {[1] = item_key}}, amount = item.size - DRAWER_MAX, status = "Transmutating", item = item})
            end
          elseif in_drawers[item_key] and not compactable(item) and item.size < DRAWER_MIN then
            machines.emc:queue_add({duplicate = item_key, amount = DRAWER_TARGET - item.size, item = item})
          elseif not in_drawers[item_key] and item.size > ME_MAX then
            if not SANE_RECYCLER or item.size - 64 > ME_MAX then
              machines.emc:queue_add({recipe = {amount = 1, slots = {[1] = item_key}}, amount = item.size - ME_MAX, status = "Transmutating", item = item})
            end
          elseif (not in_drawers[item_key]) and (item.size < ME_MIN) then
            machines.emc:queue_add({duplicate = item_key, amount = ME_TARGET - item.size, item = item})
          end
        else
          -- FIXME: Stuff in drawers which are on the recycle list should go to DRAWER_MAX.
          for i = 1, #recycle_list do
            if item_key == recycle_list[i] and item.size > ME_MAX then
              if not SANE_RECYCLER or item.size - 64 > ME_MAX then
                process(item.name, item.damage, item.size - ME_MAX)
              end
              break
            end
          end
        end
      end
    end

    -- Lootbags.
    local lootbags = me_interface.getItemsInNetwork({name = "lootbags:itemlootbag"})
    if lootbags then
      D.LOG("Recycling Loot Bags...")
      
      for n = 1, lootbags.n do
        process(lootbags[n].name, lootbags[n].damage, lootbags[n].size)
      end
    else
      D.LOG("No Loot Bags to recycling.")
    end

    D.LOG("Cleanup done... Sleeping 150 seconds.")
    D.LOG()

    os.sleep(150)
    D.LOG()
  end
end


local function start()
  read_compactable()
  me_processor_thread.create(recycler)
end


function processor_init.recycler(machine)
  machine.start = start
end
