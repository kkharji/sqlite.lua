local M = {}
local clib = require "sql.defs"

--- Functions for asseting and erroring out :D

local errors = {
  not_sqltbl = "can not execute %s, %s doesn't exists.",
  close_fail = "database connection didn't get closed, ERRMSG: %s",
  eval_fail = "eval has failed to execute statement, ERRMSG: %s",
  wrong_input = "can't parse your input. Make sure that you used that function correctly",
  missing_req_key = "(insert) missing a required key: %s",
}

for key, value in pairs(errors) do
  errors[key] = "sql.nvim " .. value
end

---Error out if sql table doesn't exists.
---@param db table
---@param tbl_name string
---@param method any
---@return boolean
M.is_sqltbl = function(db, tbl_name, method)
  assert(db:exists(tbl_name), errors.not_sqltbl:format(method, tbl_name))
  return true
end

---Error out if connection didn't get closed.
---This should never happen but is used just in case
---@param conn_ptr sqlite3_blob*
---@return boolean
M.should_close = function(conn_ptr, did_close)
  assert(did_close, errors.close_fail:format(clib.last_errmsg(conn_ptr)))
  return true
end

---Error out if statement evaluation/executation result in
---last_errorcode ~= flags.ok
---@param conn_ptr sqlite3_blob*
---@return boolean
M.should_eval = function(conn_ptr)
  local no_err = clib.last_errcode(conn_ptr) == clib.flags.ok
  assert(no_err, errors.eval_fail:format(clib.last_errmsg(conn_ptr)))
end

---Check if a given ret table length is more then 0
---This because in update we insert and expect some value
---returned 'let me id or 'boolean.
---When the ret values < 0 then the function didn't do anything.
---@param ret table
---@return boolean
M.should_update = function(ret)
  assert(#ret > 0, errors.wrong_input)
  return true
end

M.missing_req_key = function(val, key)
  assert(val, errors.missing_req_key:format(key))
  return false
end

return M
