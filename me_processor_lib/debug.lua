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

local serialization = require('serialization')
local term = require('term')

local log = {}
local log_file
local next_flush
local D = {level = {ERR = 1, WRN = 2, LOG = 3}}

D.LOG_LEVEL = D.level.LOG
D.DISPLAY = true

-- FIXME: Add timestamps.
function D.log(level, ...)
  if not log_file then
    log_file = io.open("me_processor.log", "a")
    log_file:write("\nME Storage Processor Startup.\n")
  end

  local now = require('computer').uptime()
  if not next_flush or next_flush <= now then
    log_file:flush()
    next_flush = now + 5  -- Flush every 5 seconds.
  end

  table.insert(log, table.pack(...))
  log_file:write(...)
  log_file:write("\n")

  if level == D.level.ERR then
    -- Get the message on the screen ASAP. Next call is likely assert(false) or os.exit().
    term.clearLine()
    print(...)
    return
  end

  if D.DISPLAY then
    term.clearLine()
    print(...)
  end
end

function D.ERR(...)
  D.log(D.level.ERR, ...)
end

function D.WRN(...)
  D.log(D.level.WRN, ...)
end

function D.LOG(...)
  D.log(D.level.LOG, ...)
end

function D.new_log_entries()
  local current_log = log
  log = {}
  return current_log
end

function D.pv(v)
  print(tostring(serialization.serialize(v, 100000)))
end
  
function D.v2s(variable)
  return tostring(serialization.serialize(variable))
end

return D
