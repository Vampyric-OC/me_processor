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

local D = require('me_processor_lib.debug')
local lib = require('me_processor_lib.library')

local database = component.getPrimary("database")
local me_interface = component.getPrimary("me_interface")


function processor_handler.generic(machine, processor, request, amount)
  if amount <= 0 then
    D.ERR("Amount <= 0??")
    assert(false)
  end

  if not request.recipe then
    D.WRN("Queued request invalid. Ignored request.")
    return
  end

  local recipe = request.recipe

  -- FIXME: Input validation
  local status = request.status
  local item = request.item

  -- Setup hook
  if machine.setup then
    machine.setup(machine, processor, recipe, amount, status, item)
  end

  -- Before we do anything, we need to get the slots in recipe and sort it.
  -- The way I now define recipe slots apparently is not a real scattered indexed array according to LUA, so the sorting gets mangled
  -- Sort it here, so machines which rely on order (like the Electronics Assembler) work too.
  -- If a machine has a different slot then slot 1 as the slot to be filled first, use the processor slot map to define order.

  local slot_order = {}
  local n = 0
  for slot in pairs(recipe.slots) do
    n = n + 1
    slot_order[n] = slot
  end
  table.sort(slot_order)

  local slot_count = 0
  local slot_map = {}
  local ingredient = {}
  local max_ingredient_amount = 0

  for n, slot in pairs(slot_order) do
    local item = lib.key_to_item(recipe.slots[slot])
    local item_amount = item.amount or 1
    item.amount = nil

    slot_count = slot_count + 1
    slot_map[slot_count] = slot
    ingredient[slot_count] = {item_key = lib.item_to_key(item), amount = item_amount}
    
    if item_amount > max_ingredient_amount then
      max_ingredient_amount = item_amount
    end
  end

  -- FIXME: max_ingredient_amount ignored right now. Use it to precalculate move size.

  if slot_count == 0 then
    D.ERR("Recipe has no ingredients?")
    assert(false)
  end

  local reserved_slots = processor.transposer:request_slots(slot_count)

  -- We could still try and do items sequentially and ask for 1 slot, but for now, just add interfaces.
  if not reserved_slots then
    D.WRN("Could not transposer reserve slots.")
    return false
  end

  for n = 1, slot_count do
    local item = lib.key_to_item(ingredient[n].item_key)
    item = me_interface.getItemsInNetwork({name = item.name, damage = item.damage})

    if item[1] then
      item = item[1]
    else
      D.WRN("Could not find " .. ingredient[n].item_key .. " on the network?")
      return false
    end

    if ingredient[n].amount == 0 then
      processor.transposer:request_item(ingredient[n].item_key, reserved_slots[n], 1)
    else
      processor.transposer:request_item(ingredient[n].item_key, reserved_slots[n], (item.maxSize > amount and amount or item.maxSize))
    end
  end

  local moved = 0
  local max_size = database.get(reserved_slots[n].database_slot).maxSize
  machine.telemetry = {}
  machine.telemetry.status = lib.item_to_label(item) .. " (0 / " .. math.floor(amount) .. ")"

  D.LOG("Start: " .. status .. " " .. lib.item_to_label(item) .. ": " .. math.floor(amount) .. ".")

  -- FIXME: If stack_time is 2 or below, we need to go in overdrive mode.
  --        Skip the wait, just keep moving stacks in.
  --        Detect by moved if the move succeeded or failed.
  --        Do keep track of items in the system once every second, to make sure we don't run out.
  --        Also a sleep(0) is probably still needed in this mode to yield to other threads in overdrive mode.
  --        Test to see if we can overdrive a whole battery of transposers all in the same tick?
  -- FIXME: Completely disregards different item counts on the recipe. Quick & dirty to get it working.
  repeat
    local now = lib.now()

    -- FIXME: Much wrong... Needs to be per slot or something, serious clusterfuck here with this.
    local current_amount = amount
    local current_moved = 0
    
    if current_amount > max_size then
      current_amount = max_size
    end

    for n = 1, slot_count do
      if ingredient[n].amount ~= 0 then
        if machine.stack_time > 2 and not processor.transposer:wait_for_request(reserved_slots[n], current_amount, 1) then
          D.WRN("Timeout while waiting for " .. current_amount .. " of " .. database.get(reserved_slots[n].database_slot).label .. ".")
          -- FIXME: Cleanup.
          return moved
        else
          processor.transposer:move(reserved_slots[n].side, reserved_slots[n].slot, processor.side, machine.slot_map[slot_map[n]], current_amount)
        end
      else
        if not processor.transposer:wait_for_request(reserved_slots[n], 1, 1) then
          D.WRN("Timeout while waiting for 1 of " .. database.get(reserved_slots[n].database_slot).label .. ".")
          -- FIXME: Cleanup.
          return moved
        else
          current_moved = processor.transposer:move(reserved_slots[n].side, reserved_slots[n].slot, processor.side, machine.slot_map[slot_map[n]], 1)
        end
      end
    end

    -- Craft hook.
    if machine.craft then
      current_amount = machine.craft(machine, processor, recipe, current_amount, status, item, slot_count, reserved_slots, slot_map)
      -- Craft hook is supposed to sleep, so we just yield here.
      os.sleep(0)
    else
      -- Stack time is in Ticks.
      -- FIXME: BTW. We can also keep stack_time per processor instead of per machine group.
      --        Then, if stack_time is dynamic, you can have the same machines with different speeds (due to upgrades, capacitors, etc).
      --        stack_time will not work for all machines anyway though, some recipes have different times.
      local sleep_time = 0
      if machine.stack_time > 2 then
        sleep_time = (machine.stack_time / 20 ) * (current_amount / 64)
      end

      lib.sleep_until(now + sleep_time)
    end

    -- FIXME: Nonononono..... Of course not. Come on now? What ARE you thinking??
    --        current_moved is no good though, or is it?
    --        Depends... If we're crafting or processing... We'll just silently ignore this for now.
    moved = moved + current_amount

    machine.telemetry.status = lib.item_to_label(item) .. " (" .. math.floor(moved) .. " / " .. math.floor(amount) .. ")"
  until moved >= amount

  for n = 1, slot_count do
    processor.transposer:cancel_request(reserved_slots[n])
  end

  processor.transposer:release_slots(reserved_slots)
end
