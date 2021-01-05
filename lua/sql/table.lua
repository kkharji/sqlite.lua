local u = require "sql.utils"
local luv = require "luv"

local tbl = {}
tbl.__index = tbl

local cache_clear = function(self, succ, change)
  if succ then
    self.cache = {}
    self.db.modified = false
  end
end

local cache_fill = function(self, query, res)
  self.cache[u.query_key(query)] = res
end

local cache_get = function(self, query)
  if self.nocache then
    return
  end

  local stat = luv.fs_stat(self.db.uri)
  local mtime = stat and stat.mtime.sec

  if self.db.modified or mtime ~= self.mtime then
    cache_clear(self, true, nil)
    self.db.modified = false
    return
  end

  return self.cache[u.query_key(query)]
end

local run = (function()
  local ensure = function(self)
    if not self.db:exists(self.name) and self.tbl_schema then
      return self.db:create(self.name, self.tbl_schema)
    end
  end

  return function(func, self)
    local _run = function()
      ensure(self)
      return func() -- shoud pass tbl name?
    end

    if self.db.closed then
      return self.db:with_open(_run)
    end
    return _run()
  end
end)()

function tbl:new(db, name, opts)
  opts = opts or {}
  local o = {}
  o.cache = {}
  o.db = db
  o.name = name
  o.mtime = luv.fs_stat(o.db.uri)
  o.mtime = o.mtime and o.mtime.mtime.sec
  o.tbl_schema = opts.schema
  o.nocache = opts.nocache
  -- db:close/open changes this value, not sql:change commands

  setmetatable(o, self)

  run(function()
    if o.tbl_schema then
      o.tbl_schema.ensure = true
      o.db:create(o.name, o.tbl_schema)
    end
    o.tbl_exists = o.db:exists(o.name)
    o.has_content = o.tbl_exists and o:count() ~= 0 or false
  end, o)
  return o
end

---Create or change {self.name} schema. If no {schema} is given,
---then it return current the used schema.
---@param schema table: table schema definition
---@return table: list of keys or keys and their type.
function tbl:schema(schema)
  local res
  return run(function()
    local exists = self.db:exists(self.name)

    if not schema then -- TODO: or table is empty
      if exists then
        self.tbl_schema = self.db:schema(self.name)
        return self.tbl_schema
      else
        return {}
      end
    elseif not exists or schema.ensure then
      res = self.db:create(self.name, schema)
      self.tbl_exists = res
      return res
    elseif not schema.ensure then -- maybe better to use alter
      res = exists and self.db:drop(self.name) or true
      res = res and self.db:create(self.name, schema) or false
      self.tbl_schema = self.db:schema(self.name)
      return res
    end
  end, self)
end

---Same functionalities as |sql:drop()|, if the table is already drooped
---then it returns false
---@return boolean
function tbl:drop()
  return run(function()
    if not self.db:exists(self.name) then
      return false
    end

    local res = self.db:drop(self.name)
    if res then
      self.tbl_exists = false
      self.tbl_schema = nil
    end
    return res
  end, self)
end

---Predicate that returns true if the table is empty
---@return boolean
function tbl:empty()
  return self:exists() and self:count() == 0 or false
end

---Predicate that returns true if the table exists
---@return boolean
function tbl:exists()
  return run(function()
    return self.db:exists(self.name)
  end, self)
end

---The count of the rows in {self.name}.
---@return number: number of rows in {self.name}
function tbl:count()
  return run(function()
    if not self.db:exists(self.name) then
      return 0
    end
    local res = self.db:eval("select count(*) from " .. self.name)
    return res[1]["count(*)"]
  end, self)
end

---Query the table and return results. If the {query} has been ran before, then
---query results from cache will be returned.
---@param query table: query.where, query.keys, query.join
---@return table: empty table if no result
---@see sql:select
function tbl:get(query)
  query = query or { query = { all = 1 } }
  local cache = cache_get(self, query)
  if cache then
    return cache
  end

  return run(function()
    local res = self.db:select(self.name, query)
    if res and not self.nocache then
      cache_fill(self, query, res)
    end
    return res
  end, self)
end

---Get first match from a table based on keys
---query results from cache will be returned.
---@param where table: where key values
---@return nil or row
---@usage: tbl:where{id = 1}
---@see sql:select
function tbl:where(where)
  return where and self:get({ where = where })[1] or nil
end

---Iterate over {self.name} rows and execute {func}.
---@param query table: query.where, query.keys, query.join
---@param func function: a function that expects a row
---@return boolean: true if rows ~= empty table
function tbl:each(query, func)
  assert(type(func) == "function", "required a function as second params")

  local cache = cache_get(self, query)
  local rows = cache and cache
    or (function()
      local res = self.db:select(self.name, query)
      if res and not self.nocache then
        cache_fill(self, query, res)
      end
      return res
    end)()
  if not rows then
    return
  end

  for _, row in ipairs(rows) do
    func(row)
  end

  return rows ~= {} or type(rows) ~= "boolean"
end

---Create a new table from iterating over {self.name} rows with {func}.
---@param query table: query.where, query.keys, query.join
---@param func function: a function that expects a row
---@return boolean: true if rows ~= empty table
function tbl:map(query, func)
  assert(type(func) == "function", "required a function as second params")
  local res = {}
  self:each(query, function(row)
    table.insert(res, func(row))
  end)
  return res
end

---Sorts a table in-place using a transform. Values are ranked in a custom order of the results of
---running `transform (v)` on all values. `transform` may also be a string name property  sort by.
---`comp` is a comparison function. Adopted from Moses.lua
---@param query table: query.where, query.keys, query.join
---@param transform function or string: a `transform` function to sort elements. Defaults to @{identity}
---@param comp function: a comparison function, defaults to the `<` operator
---@return table: list of sorted values
function tbl:sort(query, transform, comp)
  local res = self:get(query)
  local f = transform or function(r)
    return r[u.keys(query.where)[1]]
  end
  if type(transform) == "string" then
    f = function(r)
      return r[transform]
    end
  end
  comp = comp or function(a, b)
    return a < b
  end
  table.sort(res, function(a, b)
    return comp(f(a), f(b))
  end)
  return res
end

---Same functionalities as |sql:insert()|
---@param rows table: a row or a group of rows
---@see sql:insert
---@return boolean|integer
function tbl:insert(rows)
  return run(function()
    local succ, last_rowid = self.db:insert(self.name, rows)
    if not self.nocache then
      cache_clear(self, succ, rows)
    end
    if succ then
      self.has_content = self:count() ~= 0 or false
    end
    return succ, last_rowid
  end, self)
end

---Same functionalities as |sql:delete()|
---@param specs table: specs.where
---@see sql:delete
---@return boolean
function tbl:remove(specs)
  return run(function()
    local succ = self.db:delete(self.name, specs)
    if not self.nocache then
      cache_clear(self, succ, specs)
    end
    return succ
  end, self)
end

---Same functionalities as |sql:update()|
---@param specs table: a table or a list of tables with where and values keys.
---@see sql:update
---@return boolean
function tbl:update(specs)
  return run(function()
    local succ = self.db:update(self.name, specs)
    if not self.nocache then
      cache_clear(self, succ, specs)
    end
    return succ
  end, self)
end

---Same functionalities as |tbl:add()|, but replaces {self.name} content with {rows}
---@param rows table: a row or a group of rows
---@see sql:delete
---@see sql:insert
---@return boolean
function tbl:replace(rows)
  return run(function()
    self.db:delete(self.name)
    local succ = self.db:insert(self.name, rows)
    if not self.nocache then
      cache_clear(self, succ, rows)
    end
    return succ
  end, self)
end

return tbl
