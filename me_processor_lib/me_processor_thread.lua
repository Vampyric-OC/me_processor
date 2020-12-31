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

local event = require('event')
local serialization = require('serialization')
local thread = require('thread')

local D = require('me_processor_lib.debug')

local threads = {}
local main_tid = {}
local crashed = false

local function add_thread(tid)
  table.insert(threads, tid)
end

local function remove_thread(removed_tid)
  local found = false
  for n, tid in pairs(threads) do
    if (tid == removed_tid) then
      table.remove(threads, n)
      found = true
      break
    end
  end

  if not found then
    D.WRN(string.sub(tostring(tid), 8) .. " not found on thread list.")
  end
end

-- Any error in a thread will take the whole system down.
local function thread_error(message)
  -- Turn on direct output and make sure the log outputs everything to disk.
  D.DISPLAY = true
  D.LOG_LEVEL = D.level.LOG

  D.LOG()
  D.LOG("---- Thread error ----")
  D.LOG(message)
  D.LOG(debug.traceback())
  D.LOG()

  crashed = true

  if (thread.current() == main_tid) then
    D.LOG("Main thread crash.")
    D.LOG()
  end

  -- I... Want to kill... Everybody in the world... I want to eat your heart...  --SKRILLEX
  D.LOG("Killing all threads...")

  -- Get a copy of threads, as remove_thread manipulates it and LUA gets confused.
  local threads_copy = {}
  for n, tid in pairs(threads) do
    threads_copy[n] = tid
  end

  for n, tid in pairs(threads_copy) do
    if (tid == main_tid) then
      D.LOG("Thread " .. string.sub(tostring(tid), 8) .. " is main()")
    elseif (tid ~= thread.current()) then
      tid:kill()
      D.LOG("Thread " .. string.sub(tostring(tid), 8) .. " killed")
      remove_thread(tid)
    else
      D.LOG("Thread " .. string.sub(tostring(tid), 8) .. " is me.")
    end
  end

  if (thread.current() ~= main_tid) then
    -- If we ain't main(), then main() goes bye bye now!
    main_tid:kill()
    remove_thread(main_tid)
    D.LOG()
    D.LOG("Main thread (" .. string.sub(tostring(main_tid), 8) .. ") killed.")
  end

  D.LOG()
  D.LOG("So Long, and Thanks for All the Fish...")
end

local function thread_stub(thread_function, ...)
  add_thread(thread.current())

  -- Yield to caller.
  os.sleep(0)

  xpcall(thread_function, thread_error, table.unpack({...}))

  remove_thread(thread.current())
end

local function start_thread(thread_function, ...)
  if crashed then
    return false
  end

  local tid = thread.create(thread_stub, thread_function, table.unpack({...}))
  return tid
end

return {
  run_main_thread = function(main, args)
    if THREADING then
      main_tid = start_thread(main, args)

      while not crashed and main_tid:status() == "running" do
        thread.waitForAny(main_tid, 1)
      end
    else
      main(args)
    end

    D.LOG("Program exit.")
  end,

  create = function(thread_function, ...)
    start_thread(thread_function, table.unpack({...}))
  end,

  thread_count = function()
    return #threads
  end,
}
