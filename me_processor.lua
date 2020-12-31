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
--
-- ME Storage Processor
--
--
--                             - If threads ever become real, this thing will fail hard.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- TODO: Add fluid and gas support (atleast fluid?, gas might be difficult).

-- Machine processors are defined in me_processor_lib/processors.lua.
-- If anyone adds a machine and gets it working, let me know! The more this program can handle, the better.


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- FIXME: Are there better ways to define C-ish debug flags then this?
STICK_KNOWLAGE = true

DRAWER_ADDRESS = "9619ff36-c6a3-45e2-982f-6dbd0639ecce"
BARREL_ADDRESS = "5d11f10c-f3b6-4ff3-8878-888e50b4a526"

local ignore_inventories = {"opencomputers:rack", "opencomputers:charger", "extrautils2:miner", "enderio:block_aversion_obelisk"}
local ignore_transposers = {DRAWER_ADDRESS, BARREL_ADDRESS}


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


--FIXME: global for now, so recycler can reach it. Needs to be a database type object required in.
recipes = {}

if STICK_KNOWLAGE then
  -- It's always good to know how to make sticks.
  -- To hardcode a recipe, copy one of these lines, adapt it and move it out of the if block.
  recipes['minecraft:planks|0'] = {machine = "crafter", amount = 4, slots = {[5] = "minecraft:log|0"}}
  recipes['minecraft:stick|0']  = {machine = "crafter", amount = 4, slots = {[2] = "minecraft:planks|0", [4] = "minecraft:planks|0"}}
end

-- FIXME: these should be in recipes.dat after being learned or imported.
recipes['minecraft:coal|0']                 = {machine = "furnace",        amount = 1, slots = {[1] = "minecraft:coal_ore|0"}}
recipes['projectred-exploration:stone|1']   = {machine = "crafter",        amount = 4, slots = {[1] = "chisel:marble2|7", [2] = "chisel:marble2|7",
                                                                                                [4] = "chisel:marble2|7", [5] = "chisel:marble2|7"}}
recipes['minecraft:gunpowder|0']            = {machine = "crafter",        amount = 6, slots = {[5] = "xreliquary:mob_ingredient|3"}}
recipes['minecraft:slime_ball|0']           = {machine = "crafter",        amount = 6, slots = {[4] = "xreliquary:mob_ingredient|4"}}
recipes['minecraft:paper|0']                = {machine = "crafter",        amount = 6, slots = {[4] = "thermalfoundation:material|800",
                                                                                                [5] = "thermalfoundation:material|800",
                                                                                                [6] = "thermalfoundation:material|800"}}
recipes['minecraft:ender_pearl|0']          = {machine = "crafter",        amount = 3, slots = {[1] = "xreliquary:mob_ingredient|11"}}
recipes['minecraft:gold_nugget|0']          = {machine = "crafter",        amount = 6, slots = {[1] = "xreliquary:mob_ingredient|6",
                                                                                                [2] = "xreliquary:mob_ingredient|6"}}
recipes['minecraft:dye|0']                  = {machine = "crafter",        amount = 6, slots = {[5] = "xreliquary:mob_ingredient|12"}}
recipes['minecraft:bone|0']                 = {machine = "crafter",        amount = 5, slots = {[5] = "xreliquary:mob_ingredient|0"}}
recipes['minecraft:spider_eye|0']           = {machine = "crafter",        amount = 2, slots = {[1] = "xreliquary:mob_ingredient|2",
                                                                                                [2] = "xreliquary:mob_ingredient|2"}}
recipes['minecraft:snowball|0']             = {machine = "crafter",        amount = 5, slots = {[5] = "xreliquary:mob_ingredient|10"}}

recipes['mysticalagriculture:crafting|1']   = {machine = "crafter",        amount = 1, slots = {[2] = "mysticalagriculture:crafting|0",
                                                                                                [4] = "mysticalagriculture:crafting|0",
                                                                                                [5] = "mysticalagriculture:master_infusion_crystal|0*0",
                                                                                                [6] = "mysticalagriculture:crafting|0",
                                                                                                [8] = "mysticalagriculture:crafting|0"}}
recipes['mysticalagriculture:crafting|2']   = {machine = "crafter",        amount = 1, slots = {[2] = "mysticalagriculture:crafting|1",
                                                                                                [4] = "mysticalagriculture:crafting|1",
                                                                                                [5] = "mysticalagriculture:master_infusion_crystal|0*0",
                                                                                                [6] = "mysticalagriculture:crafting|1",
                                                                                                [8] = "mysticalagriculture:crafting|1"}}
recipes['mysticalagriculture:crafting|3']   = {machine = "crafter",        amount = 1, slots = {[2] = "mysticalagriculture:crafting|2",
                                                                                                [4] = "mysticalagriculture:crafting|2",
                                                                                                [5] = "mysticalagriculture:master_infusion_crystal|0*0",
                                                                                                [6] = "mysticalagriculture:crafting|2",
                                                                                                [8] = "mysticalagriculture:crafting|2"}}
recipes['mysticalagriculture:crafting|4']   = {machine = "crafter",        amount = 1, slots = {[2] = "mysticalagriculture:crafting|3",
                                                                                                [4] = "mysticalagriculture:crafting|3",
                                                                                                [5] = "mysticalagriculture:master_infusion_crystal|0*0",
                                                                                                [6] = "mysticalagriculture:crafting|3",
                                                                                                [8] = "mysticalagriculture:crafting|3"}}
recipes['mysticalagradditions:insanium|0']  = {machine = "crafter",        amount = 1, slots = {[2] = "mysticalagriculture:crafting|4",
                                                                                                [4] = "mysticalagriculture:crafting|4",
                                                                                                [5] = "mysticalagriculture:master_infusion_crystal|0*0",
                                                                                                [6] = "mysticalagriculture:crafting|4",
                                                                                                [8] = "mysticalagriculture:crafting|4"}}
recipes['mysticalagradditions:insanium|0']  = {machine = "crafter",        amount = 1, slots = {[2] = "mysticalagriculture:crafting|4",
                                                                                                [4] = "mysticalagriculture:crafting|4",
                                                                                                [5] = "mysticalagriculture:master_infusion_crystal|0*0",
                                                                                                [6] = "mysticalagriculture:crafting|4",
                                                                                                [8] = "mysticalagriculture:crafting|4"}}
recipes['nuclearcraft:ingot|6']             = {machine = "crafter",        amount = 1, slots = {[1] = "mysticalagriculture:lithium_essence|0",
                                                                                                [2] = "mysticalagriculture:lithium_essence|0",
                                                                                                [3] = "mysticalagriculture:lithium_essence|0",
                                                                                                [4] = "mysticalagriculture:lithium_essence|0",
                                                                                                [6] = "mysticalagriculture:lithium_essence|0",
                                                                                                [7] = "mysticalagriculture:lithium_essence|0",
                                                                                                [8] = "mysticalagriculture:lithium_essence|0",
                                                                                                [9] = "mysticalagriculture:lithium_essence|0"}}
recipes['botania:manaresource|4']           = {machine = "crafter",        amount = 1, slots = {[1] = "mysticalagriculture:terrasteel_essence|0",
                                                                                                [2] = "mysticalagriculture:terrasteel_essence|0",
                                                                                                [3] = "mysticalagriculture:terrasteel_essence|0",
                                                                                                [4] = "mysticalagriculture:terrasteel_essence|0",
                                                                                                [6] = "mysticalagriculture:terrasteel_essence|0",
                                                                                                [7] = "mysticalagriculture:terrasteel_essence|0",
                                                                                                [8] = "mysticalagriculture:terrasteel_essence|0",
                                                                                                [9] = "mysticalagriculture:terrasteel_essence|0"}}
recipes['potion|0']                         = {machine = "potion_brewer",  amount = 3, slots = {[1] = "minecraft:glass_bottle|0*3",
                                                                                                [2] = "minecraft:nether_wart|0"}}
recipes['microcontroller|0']                = {machine = "assembler",      amount = 1, slots = {[1] = "opencomputers:material|21",
                                                                                                [17] = "opencomputers:component|0",
                                                                                                [18] = "opencomputers:component|7",
                                                                                                [20] = "opencomputers:storage|0"}}
recipes['mekanism:sawdust|0']               = {machine = "sag_mill",       amount = 1, slots = {[1] = "minecraft:planks|0"}}


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- ME Crafting patterns index for the ME front end.
-- FIXME: Obviously not very user friendly...
local ordered_item = {}
ordered_item[2] = "minecraft:shears|0"
ordered_item[3] = "minecraft:iron_sword|0"
ordered_item[4] = "minecraft:iron_pickaxe|0"
ordered_item[5] = "minecraft:iron_shovel|0"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- This code should only call machines.setup() and machine['name'].add_queue + friends.
-- It should only read (and reset) machine['name'].telemetry.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- Force reload our modules.
for module in pairs(package.loaded) do
  if string.sub(module, 1, string.len("me_processor_lib.")) == "me_processor_lib." then
    print("Reloading module: " .. module .. ".")
    package.loaded[module] = nil
  end
end

local computer = require('computer')
local component = require('component')
local event = require('event')
local filesystem = require('filesystem')
local serialization = require('serialization')
local shell = require('shell')
local term = require('term')

local D = require('me_processor_lib.debug')
local lib = require('me_processor_lib.library')
local machines = require('me_processor_lib.machines')
local me_processor_thread = require('me_processor_lib.me_processor_thread')

local me_interface = component.getPrimary("me_interface")
local log = {}
local last_log_startline = 0

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- FIXME: Change to a database.
local function load_recipes()
  local stored_recipes

  if filesystem.exists(shell.getWorkingDirectory() .. "/recipes.dat") then
    local recipe_data = io.open("recipes.dat", "rb")
    stored_recipes = serialization.unserialize(recipe_data:read("*a"))
    recipe_data:close()
  end

  -- Hardcoded recipes override stored ones.
  local added = false
  if stored_recipes then
    for k, recipe in pairs(stored_recipes) do
      if not recipes[k] then
        recipes[k] = recipe
        D.LOG("Added recipe for " .. k .. ".")
        added = true
      end
    end
  end

  if added then
    D.LOG()
  end
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- FIXME: Possible EMC hack, it can craft things out of nothing, aslong as we have the item.
--        Can we somehow mangle the recipes list to short circuit to EMC if EMC can duplicate the item?
--        Makes autocrafting a whole lot easier.
--          ^^^ Addendum: Or just test here in craft if emc can duplicate it. if it can, it directs to emc.
--                        If it can but not right now, redirect to duplication request, or check if
--                        crafting is 'quick & easy' (whatever that means) and craft if it is.
--                        If it can't, then craft.
--        Another option is to have an EMC database storage system, with 1 of every EMCable item.
--        Can be as simple as me storage cells inside a big crate and just swapping the drive we need into
--        an ME chest.
--        We don't even have to keep configuration state, we can start a thread in the background to walk
--        all drives to catalog their items. Even a full crate of 350 drives should be doable in around 1400 ticks, or under a minute.
--        This gives us a catalog of around 22000 items. More then enough for almost all modpacks.
--        Still leaves us with the problem of auto duplicating though. We still need manual duplication link intervention for now.
--        Test if drones can fix that, if not, batteries upon batteries of links?
--        Preferably not connected to ME, but with an RFTools storage scanner.
--        Last idea, do links keep their known inventory? If so, crate with links -> block placer -> block breaker -> Redstone. Done.
--        (If we can ever get a 2nd link that is....)


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


local function modem_message(type, local_address, remote_address, port, distance, message)
  local item_index = tonumber(message)
  local item_key = ordered_item[item_index]

  if ordered_item[item_index] then
    local recipe = recipes[item_key]

    if not recipe then
      D.WRN("Do not know how to craft " .. item_key .. ".")
      return
    end

    local machine_name = recipe.machine
    local machine = machines[machine_name]

    if not machine then
      D.WRN("Could not find " .. machine_name .. "?")
      return
    end

    D.LOG("Order recived for " .. ordered_item[item_index])

    machine:queue_add({recipe = recipe, amount = 1, status = "Crafting", item = lib.key_to_item(item_key)}, true)
  else
    D.WRN("Got an order for unknown index " .. item_index .. "?")
    return
  end
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- Should run every 0.5 seconds, if main() is doing it's job.
local function update_report()
  if not term.isAvailable() then
    return
  end

  local free_memory = math.floor(computer.freeMemory() / 1024) .. "kb"
  local thread_count = me_processor_thread.thread_count()
  local status = {}

  for machine_name, machine in pairs(machines) do
    if machine.telemetry and machine.telemetry and machine.telemetry.status then
      table.insert(status, machine.label .. ": " .. machine.telemetry.status)
    end
  end

  -- Add log entries to log, newest on top.
  local new_log_entries = false
  for _, line in pairs(D.new_log_entries()) do
    new_log_entries = true
    table.insert(log, 1, line)
  end

  -- Log free memory & threads to file.
  D.LOG("Free memory: " .. free_memory .. ".  Threads: " .. thread_count .. ".")
  -- Clear log again to silence the line above in output.
  D.new_log_entries()

  term.setCursor(1, 1)
  local line = 1
  -- FIXME: lines is local as defined here, right?
  local _, lines = term.getViewport()

  term.clearLine()
  term.write("Free memory: " .. free_memory .. ".  Threads: " .. thread_count .. ".\n", false)
  term.clearLine()
  term.write("\n", false)
  line = line + 2

  if #status > 0 then
    for _, machine_status in pairs(status) do
      term.clearLine()
      term.write("- " .. machine_status .. "\n", false)
      line = line + 1
    end

    term.clearLine()
    term.write("\n", false)
    line = line + 1
  end

  if last_log_startline == line and not new_log_entries then
    return
  end

  last_log_startline = line

  local log_size = 0
  for n, log_line in pairs(log) do
    log_size = log_size + 1

    if line < lines then
      term.clearLine()

      if table.unpack(log[n]) then
        term.write(table.unpack(log[n]), false)
      end

      term.write("\n", false)
      line = line + 1
    else
      -- Trim memory log to screen line count.
      if log_size > lines then
        log[n] = nil
      end
    end
  end
end


local function main(args)
  -- Creates all real and virtual machines as sub object of machines.
  machines.setup(ignore_inventories, ignore_transposers)

  -- Load recipes from disk.
  -- FIXME: should be a require and setup, like machines?
  load_recipes()

  -- Switch output logging and clear the internal log.
  D.LOG("Starting threads and switching to frontend...")
  D.DISPLAY = false
  D.new_log_entries()

  -- Start the frontend network.
  event.listen("modem_message", modem_message)

  -- Start the recipe learner.
  machines.recipe_learner:start()

  -- Start the recycler.
  machines.recycler:start()

  -- Sleep a second to get a glance of the setup feedback.
  os.sleep(1)

  -- Clear screen for status output.
  term.clear()

  -- Fancy clock sync! Cause, why not.
  local next_update = lib.now()
  while true do
    local now = lib.now()
    
    if now >= next_update then
      if (next_update - now) > 0.5 then
        D.WRN("Hung for " .. (now - next_update) .." seconds?")
      end
      
      next_update = now + 0.5

      update_report()
    elseif now < (next_update - 0.5) then
      D.WRN("Clock skew? (" .. (next_update - 0.5) .. " -> " .. now .. ").")

      next_update = now
    end

    os.sleep(next_update - lib.now())
  end
end

-- Run in a thread so we can kill the whole process from any thread if needed.
me_processor_thread.run_main_thread(main, shell.parse(...))
