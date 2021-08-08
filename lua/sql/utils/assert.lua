local M = {}
--- Functions for asseting and erroring out :D

local errors = {
  not_sqltbl = "sql.nvim: can not execute %s, %s doesn't exists.",
}

---Fail at lua side if sql table doesn't exists.
---@param db table
---@param tbl_name string
---@param method any
M.is_sqltbl = function(db, tbl_name, method)
  assert(db:exists(tbl_name), errors.not_sqltbl:format(method, tbl_name))
end

return M
