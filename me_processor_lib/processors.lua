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

-- FIXME: Check if we auto import or not?
--        We can test this the first craft with a processor and see if it auto imports it's results.
--        Warn if a processor doesn't?
--        Also, with 9 slot processors (crafters) returning items via the interface is tricky and slower.
-- FIXME: Add back Analog crafter as a basic crafting processor.
--        Check if Void whatyamacallit would work too? (Void Lordcraft crafter).
-- FIXME: The recycler is an example of a virtual machine. explain that more (and also special machines like the recipe learner).
local processors = {
  ['emc']                    = {id = "projectex:compressed_refined_link", label = "EMC Link", handler = "emc", init="emc", stack_time = 1},
  ['pulverizer']             = {id = "thermalexpansion:machine", label = "Pulverizer", handler = "generic"},
  ['compactor']              = {id = "thermalexpansion:machine", label = "Compactor", handler = "generic"},
  ['induction_smelter']      = {id = "thermalexpansion:machine", label = "Induction Smelter", handler = "generic"},
  ['insolator']              = {id = "thermalexpansion:machine", label = "Phytogenic Insolator", handler = "generic"},
  ['magma_crucible']         = {id = "thermalexpansion:machine", label = "Magma Crucible", handler = "generic"},
  ['loot_opener']            = {id = "lootbags:loot_opener", label = "Bag Opener", handler = "generic", init="loot_opener"},
  ['patient_loot_opener']    = {id = "lootbags:loot_opener", label = "Patient Bag Opener", handler = "patient_loot_opener"},
  ['assembler']              = {id = "opencomputers:assembler", label = "Electronics Assembler", handler = "generic", craft = "assembler"},
  ['sag_mill']               = {id = "enderio:block_enhanced_sag_mill", label = "Sag Mill", handler = "generic"},
  ['furnace']                = {id = "furnaceoverhaul:zenith_furnace", label = "Zenith Furnace", handler = "generic", stack_time = 60, multiplier = 2},
  ['alloy_smelter']          = {id = "enderio:block_enhanced_alloy_smelter", label = "Alloy Smelter", handler = "generic"},
  ['crafter']                = {id = "opencomputers:robot", label = "Crafting Robot", handler = "generic", init = "crafter", setup = "crafter", craft = "crafter",
                                      slot_map = {[1] = 1, [2] = 2, [3] = 3, [4] = 5, [5] = 6, [6] = 7, [7] = 9, [8] = 10, [9] = 11}},
  ['hellfire_forge']         = {id = "bloodmagic:soul_forge", label = "Hellfire Forge", handler = "generic"},
  ['enchantment_extractor']  = {id = "industrialforegoing:enchantment_extractor", label = "Enchantment Extractor", handler = "generic"},
  ['potion_brewer']          = {id = "industrialforegoing:potion_enervator", label = "Potion Brewer", handler = "potion_brewer",
                                      slot_map = {[1] = 7, [2] = 8, [3] = 9, [4] = 10, [5] = 11, [6] = 12}},
  ['fortune_miner']          = {id = "extrautils2:user", label = "Fortune III Miner", handler = "generic"},
  ['crusher']                = {id = "extrautils2:machine", label = "Crusher", handler = "generic"},
  ['double_crusher']         = {id = "actuallyadditions:block_grinder_double", label = "Double Crusher", handler = "generic"},
  ['enricher']               = {id = "mekanism:machineblock", label = "Elite Enriching Factory", handler = "generic"},
  ['compressor']             = {id = "galacticraftcore:machine2", label = "Electric Compressor", handler = "generic"},
  ['recipe_learner']         = {label = "Recipe Learner", init="recipe_learner"},
  ['recycler']               = {label = "Recycler", init="recycler"}
}

-- FIXME: I really want these local, not global. Find out how.
processor_init = {}
processor_handler = {}
processor_setup = {}
processor_craft = {}

require('me_processor_lib.processor_generic')
require('me_processor_lib.processor_assembler')
require('me_processor_lib.processor_crafter')
require('me_processor_lib.processor_emc')
require('me_processor_lib.processor_loot_opener')
require('me_processor_lib.processor_patient_loot_opener')
require('me_processor_lib.processor_potion_brewer')
require('me_processor_lib.processor_recipe_learner')
require('me_processor_lib.processor_recycler')

local D = require('me_processor_lib.debug')

local DEFAULT_STACK_TIME = 256

local TE_MACHINE_ID = "thermalexpansion:machine"
local LOOT_OPENER_ID = "lootbags:loot_opener"

-- Should be not here.
local LOOT_OPENER_ADDRESS = "d88b0919-2418-46e0-857c-391da55d7f18"
local RECIPE_LEARNER_ADDRESS = "449956f9-d9e5-40d2-a0db-16175334292e"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function all()
  local processor_list = {}
  
  for processor_name, processor in pairs(processors) do
    processor_list[processor_name] = processor.label
  end
  
  return processor_list
end


-- Returns all virtual machines. These are machines which have no id and will set them self up in init.
-- FIXME: if init returns false, machine should be removed. Also true for real machines.
local function virtual()
  local processor_list = {}
  
  for processor_name, processor in pairs(processors) do
    if not processor.id then
      processor_list[processor_name] = processor.label
    end
  end
  
  return processor_list
end


local function identify_processor(transposer, side)
  local inventory_name = transposer.getInventoryName(side)
  if not inventory_name then
    return {}
  end

  if inventory_name == TE_MACHINE_ID then
    local inventories = transposer.getInventorySize(side)

    local tanks = 0
    while pcall(transposer.getTankCapacity, side, tanks + 1) do
      tanks = tanks + 1
    end

    local processor

    if inventories == 0 and tanks == 1 then
      -- Ignore the Fluid Transposers.
      return
    elseif inventories == 1 and tanks == 1 then
      processor = "magma_crucible"
    elseif inventories == 2 and tanks == 0 then
      processor = "compactor"
    elseif inventories == 3 and tanks == 0 then
      processor = "pulverizer"
    elseif inventories == 4 and tanks == 0 then
      processor = "induction_smelter"
    elseif inventories == 4 and tanks == 1 then
      processor = "insolator"
    end

    if processor then
      return {name = processor, label = processors[processor].label, side = side}
    end

    D.LOG("Unknown TE machine (inventories: " .. math.floor(inventories) .. ", tanks: " .. math.floor(tanks) .. ").")

    return
  elseif inventory_name == LOOT_OPENER_ID then
    -- FIXME: Hardcoded address for now. Transposer on this address has a barrel, can we check on that? (Without a 6 side search?)
    --        Also, side here should be the barrel side to get rid of the other lootbag hack.
    --        This Information is only available just before transposer_setup, so add a hack there to get rid of these 2 and the hardcoded address?
    --        Possibly also the place to detect the compacting tester. So a general hack_hook there for custom transposer hacks?
    --        We want Anti Barrels as an option for all machines, so can't use it as an identifier for the loot bag machine.
    if transposer.address == LOOT_OPENER_ADDRESS then
      return {name = "loot_opener", label = processors.loot_opener.label, side = side}
    else
      return {name = "patient_loot_opener", label = processors.patient_loot_opener.label, side = side}
    end
  end

  for name, processor in pairs(processors) do
    if processor.id and inventory_name == processor.id then
      return {name = name, label = processor.label, side = side}
    end
  end

  D.LOG("Unknown inventory: " .. inventory_name)
end


local function processor_base(processor_name)
  local processor_base = {
    name = processor_name,
    label = processors[processor_name].label,
  }

  if processors[processor_name].handler then
    processor_base.handler = processor_handler[processors[processor_name].handler]
  end

  if processors[processor_name].craft then
    processor_base.craft = processor_craft[processors[processor_name].craft]
  end

  if processors[processor_name].stack_time then
    processor_base.stack_time = processors[processor_name].stack_time
  else
    processor_base.stack_time = DEFAULT_STACK_TIME
  end

  processor_base.slot_map = {}
  -- Max 5 interfaces possible on 1 transposer.
  for i = 1, (9 * 5) do
    processor_base.slot_map[i] = i
  end

  if processors[processor_name].slot_map then
    for slot, target_slot in pairs(processors[processor_name].slot_map) do
      processor_base.slot_map[slot] = target_slot
    end
  end

  return processor_base
end


-- This function takes full machines.
-- Needs to be here to call the processor init after the machine is completed by machines.
-- Little bit of a layer break, but whatever.
-- Could just move it into machines, but I don't want the processor functions exposed there.
local function initialize_machine(machine)
  if processors[machine.name].init then
    return processor_init[processors[machine.name].init](machine)
  end
end


return {
  all = all,
  virtual = virtual,
  identify_processor = identify_processor,
  processor_base = processor_base,
  initialize_machine = initialize_machine
}
