local u = require'sql.utils'
local t = {}
t.__index = t

function t:__run(func)
  if self.db.closed then
    return self.db:with_open(function()
      return func() -- shoud pass tbl name?
    end)
  else
   return func()
  end
end

local get_key = function(query)
  local items = {}
  for k, v in u.opairs(query) do
    table.insert(items, string.format("%s=%s", k, table.concat((function()
      if not u.is_list(v) then
        local tmp = {}
        for _k,_v in u.opairs(v) do
          if type(_v) == "table" then
            table.insert(tmp, string.format("%s=%s", _k, table.concat(_v, ",")))
            else
          table.insert(tmp, string.format("%s=%s", _k, _v))
          end
        end
        return tmp
      else
        return v
      end
    end)(), "")))
  end

  return table.concat(items, ",")
end


function t:__clear_cache(succ, change)
  -- TODO: maybe do something smart here to update cache :D
  if succ then
    self.cache = {}
    self.db.modified = false
  end
end

function t:__fill_cache(query, res)
  self.cache[get_key(query)] = res
end

function t:__get_from_cache(query)
  if self.db.modified or vim.loop.fs_stat(self.db.uri).mtime.sec ~= self.mtime then
    self.__clear_cache(true, nil)
    self.db.modified = false
    return nil
  end
  return self.cache[get_key(query)]
end


function t:new(db, tbl)
  local o = {}
  o.cache = {}
  o.db = db
  o.tbl = tbl
  o.mtime = vim.loop.fs_stat(o.db.uri).mtime.sec -- db:close/open changes this value, not sql:change commands

  setmetatable(o, self)

  o:__run(function()
    o.tbl_exists = o.db:exists(o.tbl)
    o.has_content = o.tbl_exists and o:count() ~= 0 or false
  end)
  return o
end

--- Create or change {self.tbl} schema. If no {schema} is given,
--- then it return current the used schema.
---@param schema table: table schema definition
---@return table: list of keys or keys and their type.
function t:schema(schema)
  local res
  return self:__run(function()
    if not schema then -- TODO: or table is empty
      return self.tbl_exists and self.db:schema(self.tbl) or {}
    elseif not self.tbl_exists or schema.ensure then
      res = self.db:create(self.tbl, schema)
      self.tbl_exists = res
      return res
    else -- maybe better to use alter
      res = self.db:drop(self.tbl)
      res = res and self.db:create(self.tbl, schema) or false
      return res
    end
  end)
end

--- Same functionalities as |sql:drop()|, if the table is already drooped
--- then it returns false
---@return boolean
function t:drop()
  if not self.tbl_exists then return false end
  return self:__run(function()
    local res = self.db:drop(self.tbl)
    if res then self.tbl_exists = false end
    return res
  end)
end


--- Predicate that returns true if the table is empty
---@return boolean
function t:empty() return not self.has_content end

--- Predicate that returns true if the table exists
---@return boolean
function t:exists() return self.tbl_exists end

--- The count of the rows in {self.tbl}.
---@return number: number of rows in {self.tbl}
function t:count()
  if not self.tbl_exists then return end
  return self:__run(function()
    local res = self.db:eval("select count(*) from " .. self.tbl)
    return res[1]["count(*)"]
  end)
end


--- Query the table and return results. If the {query} has been ran before, then
--- query results from cache will be returned.
---@param query table: query.where, query.keys, query.join
---@return table: empty table if no result
---@see sql:select()
function t:get(query)
  query = query or { query = {all = 1} }
  local cache = self:__get_from_cache(query)
  if cache then return cache end

  return self:__run(function()
    local res = self.db:select(self.tbl, query)
    if res then self:__fill_cache(query, res) end
    return res
  end)
end

--- Iterate over {self.tbl} rows and execute {func}.
---@param query table: query.where, query.keys, query.join
---@param func function: a function that expects a row
---@return boolean: true if rows ~= empty table
function t:each(query, func)
  assert(type(func) == "function", "required a function as second params")
  local cache = self:__get_from_cache(query)
  local rows = cache and cache or (function()
    local res = self.db:select(self.tbl, query)
    if res then self:__fill_cache(query, res) end
    return res
  end)()
  if not rows then return end
  for _, row in ipairs(rows) do
    func(row)
  end
  return rows ~= {} or type(rows) ~= "boolean"
end

--- create a new table from iterating over {self.tbl} rows with {func}.
---@param query table: query.where, query.keys, query.join
---@param func function: a function that expects a row
---@return boolean: true if rows ~= empty table
function t:map(query, func)
  assert(type(func) == "function", "required a function as second params")
  local res = {}
  self:each(query, function(row)
      table.insert(res, func(row))
  end)
  return res
end

--- Sorts a table in-place using a transform. Values are ranked in a custom order of the results of
--- running `transform (v)` on all values. `transform` may also be a string name property  sort by.
--- `comp` is a comparison function. Adopted from Moses.lua
---@param query table: query.where, query.keys, query.join
---@param transform function or string: a `transform` function to sort elements. Defaults to @{identity}
---@param comp function: a comparison function, defaults to the `<` operator
---@return table: list of sorted values
function t:sort(query, transform, comp)
  local res = self:get(query)
  local f = transform or function(r) return r[u.keys(query.where)[1]] end
  if (type(transform) == 'string') then
    f = function(r) return r[transform] end
  end
  comp = comp or function(a,b) return a < b end
  table.sort(res, function(a,b) return comp(f(a), f(b)) end)
  return res
end

--- Same functionalities as |sql:insert()|
---@param rows table: a row or a group of rows
---@see t:__run()
---@see sql:insert()
---@return boolean
function t:insert(rows)
  return self:__run(function()
    local succ = self.db:insert(self.tbl, rows)
    self:__clear_cache(succ, rows)
    return succ
  end)
end

--- Same functionalities as |sql:delete()|
---@param specs table: specs.where
---@see t:__run()
---@see sql:delete()
---@return boolean
function t:remove(specs)
  return self:__run(function()
    local succ = self.db:delete(self.tbl, specs)
    self:__clear_cache(succ, specs)
    return succ
  end)
end

--- Same functionalities as |sql:update()|
---@param specs table: a table or a list of tables with where and values keys.
---@see t:__run()
---@see sql:update()
---@return boolean
function t:update(specs)
  return self:__run(function()
    local succ = self.db:update(self.tbl, specs)
    self:__clear_cache(succ, specs)
    return succ
  end)
end

--- Same functionalities as |t:add()|, but replaces {self.tbl} content with {rows}
---@param rows table: a row or a group of rows
---@see t:__run()
---@see sql:delete()
---@see sql:insert()
---@return boolean
function t:replace(rows)
  return self:__run(function()
    self.db:delete(self.tbl)
    local succ = self.db:insert(self.tbl, rows)
    self:__clear_cache(succ, rows)
    return succ
  end)
end

return t
