---@brief [[
---Abstraction to produce more readable code.
---@brief ]]
---@tag table.lua
local u = require "sql.utils"
local luv = require "luv"

---@class SQLTable @Main table class
---@field db SQLDatabase: database in which the tbl is part of.
local tbl = {}
tbl.__index = tbl

---@class SQLTableOpts @Supported sql.table configurations.
---@field schema table: <string, string>

local run = function(func, self)
  local _run = function()
    return func() -- shoud pass tbl name?
  end

  if self.db.closed then
    return self.db:with_open(_run)
  end
  return _run()
end

---Create new sql table object
---@param db SQLDatabase
---@param name string: table name
---@param opts SQLTableOpts
---@return SQLTable
function tbl:new(db, name, opts)
  opts = opts or {}

  local stat = luv.fs_stat(db.uri)
  local schema = u.if_nil(opts.schema, opts)

  local o = setmetatable({
    db = db,
    name = name,
    mtime = stat and stat.mtime.sec,
    tbl_schema = schema,
  }, self)

  run(function()
    o.tbl_exists = o.db:exists(o.name)
    o.has_content = o.tbl_exists and o:count() ~= 0 or false
    if o.tbl_schema and next(o.tbl_schema) ~= nil then
      o.tbl_schema.ensure = u.if_nil(o.tbl_schema.ensure, true)
      o:schema(o.tbl_schema)
    end
  end, o)
  return o
end

---Create or change table schema. If no {schema} is given,
---then it return current the used schema if it exists or empty table otherwise.
---On change schema it returns boolean indecting success.
---@param schema table: table schema definition
---@return table table | boolean
---@usage `projects:schema()` get project table schema.
---@usage `projects:schema({...})` mutate project table schema
---@todo do alter when updating the schema instead of droping it completely
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

---Remove table from database, if the table is already drooped then it returns false.
---@usage `todos:drop()` drop todos table content.
---@see DB:drop
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

---Predicate that returns true if the table is empty.
---@usage `if todos:empty() then echo "no more todos, you are free :D" end`
---@return boolean
function tbl:empty()
  return self:exists() and self:count() == 0 or false
end

---Predicate that returns true if the table exists.
---@usage `if not goals:exists() then error("I'm disappointed in you ") end`
---@return boolean
function tbl:exists()
  return run(function()
    return self.db:exists(self.name)
  end, self)
end

---Get the current number of rows in the table
---@return number
function tbl:count()
  return run(function()
    if not self.db:exists(self.name) then
      return 0
    end
    local res = self.db:eval("select count(*) from " .. self.name)
    return res[1]["count(*)"]
  end, self)
end

---Query the table and return results.
---@param query table: query.where, query.keys, query.join
---@return table
---@usage `projects:get()` get a list of all rows in project table.
---@usage `projects:get({ where = { status = "pending", client = "neovim" }})`
---@usage `projects:get({ where = { status = "done" }, limit = 5})` get the last 5 done projects
---@see DB:select
function tbl:get(query)
  query = query or { query = { all = 1 } }

  return run(function()
    local res = self.db:select(self.name, query)
    return res
  end, self)
end

---Get first match.
---@param where table: where key values
---@return nil or row
---@usage `tbl:where{id = 1}`
---@see DB:select
function tbl:where(where)
  return where and self:get({ where = where })[1] or nil
end

---Iterate over table rows and execute {func}.
---Returns true only when rows is not emtpy.
---@param func function: func(row)
---@param query table: query.where, query.keys, query.join
---@usage `let query = { where = { status = "pending"}, contains = { title = "fix*" } }`
---@usage `todos:each(function(row) print(row.title) end, query)`
---@return boolean
function tbl:each(func, query)
  query = query or {}
  if type(func) == "table" then
    func, query = query, func
  end

  return run(function()
    local rows = self.db:select(self.name, query)
    if not rows then
      return false
    end

    for _, row in ipairs(rows) do
      func(row)
    end

    return rows ~= {} or type(rows) ~= "boolean"
  end, self)
end

---Create a new table from iterating over {self.name} rows with {func}.
---@param func function: func(row)
---@param query table: query.where, query.keys, query.join
---@usage `let query = { where = { status = "pending"}, contains = { title = "fix*" } }`
---@usage `local t = todos:map(function(row) return row.title end, query)`
---@return table[]
function tbl:map(func, query)
  query = query or {}
  if type(func) == "table" then
    func, query = query, func
  end

  return run(function()
    local res = {}
    local rows = self.db:select(self.name, query)
    if not rows then
      return {}
    end
    for _, row in ipairs(rows) do
      local ret = func(row)
      if ret then
        table.insert(res, func(row))
      end
    end

    return res
  end, self)
end

---Sorts a table in-place using a transform. Values are ranked in a custom order of the results of
---running `transform (v)` on all values. `transform` may also be a string name property  sort by.
---`comp` is a comparison function. Adopted from Moses.lua
---@param query table: query.where, query.keys, query.join
---@param transform function: a `transform` function to sort elements. Defaults to @{identity}
---@param comp function: a comparison function, defaults to the `<` operator
---@return table[]
---@usage `local res = t1:sort({ where = {id = {32,12,35}}})` return rows sort by id
---@usage `local res = t1:sort({ where = {id = {32,12,35}}}, "age")` return rows sort by age
---@usage `local res = t1:sort({where = { ... }}, "age", function(a, b) return a > b end)` with custom function
function tbl:sort(query, transform, comp)
  return run(function()
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
  end, self)
end

---Same functionalities as |DB:insert()|
---@param rows table: a row or a group of rows
---@see DB:insert
---@usage `todos:insert { title = "stop writing examples :D" }` insert single item.
---@usage `todos:insert { { ... }, { ... } }` insert multiple items
---@return integer: last inserted id
function tbl:insert(rows)
  return run(function()
    local succ, last_rowid = self.db:insert(self.name, rows)
    if succ then
      self.has_content = self:count() ~= 0 or false
    end
    return last_rowid
  end, self)
end

---Same functionalities as |DB:delete()|
---@param where table: query
---@see DB:delete
---@return boolean
---@usage `todos:remove()` remove todos table content.
---@usage `todos:insert{ project = "neovim" }` remove all todos where project == "neovim".
function tbl:remove(where)
  return run(function()
    local succ = self.db:delete(self.name, where)
    return succ
  end, self)
end

---Same functionalities as |DB:update()|
---@param specs table: a table or a list of tables with where and values keys.
---@see DB:update
---@return boolean
function tbl:update(specs)
  return run(function()
    local succ = self.db:update(self.name, specs)
    return succ
  end, self)
end

---replaces table content with {rows}
---@param rows table: a row or a group of rows
---@see DB:delete
---@see DB:insert
---@return boolean
function tbl:replace(rows)
  return run(function()
    self.db:delete(self.name)
    local succ = self.db:insert(self.name, rows)
    return succ
  end, self)
end

---@class SQLTableExt:SQLTable
---@field tbl SQLTable: fallback when the user overwrite @SQLTableExt methods.

---Extend Sqlite Table Object.
---@param db SQLDatabase
---@param name string
---@param opts table
---@return SQLTableExt
function tbl:extend(db, name, schema)
  local t = self:new(db, name, { schema = schema })
  return setmetatable({ tbl = t }, { __index = t })
end

return tbl
