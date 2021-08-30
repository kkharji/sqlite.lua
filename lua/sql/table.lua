---@brief [[
---Abstraction to produce more readable code.
---@brief ]]
---@tag sqltbl.overview

local u = require "sql.utils"
local a = require "sql.assert"
local fmt = string.format
local P = require "sql.parser"
local luv = require "luv"

---@type sqltbl
local sqltbl = {}
sqltbl.__index = sqltbl

local check_for_auto_alter = function(o, valid_schema)
  local with_foregin_key = false

  if not valid_schema then
    return
  end

  for _, def in pairs(o.tbl_schema) do
    if type(def) == "table" and def.reference then
      with_foregin_key = true
      break
    end
  end

  local get = fmt("select * from sqlite_master where name = '%s'", o.name)

  local stmt = o.tbl_exists and o.db:eval(get) or nil
  if type(stmt) ~= "table" then
    return
  end

  local origin, parsed = stmt[1].sql, P.create(o.name, o.tbl_schema, true)
  if origin == parsed then
    return
  end

  local ok, cmd = pcall(P.table_alter_key_defs, o.name, o.tbl_schema, o.db:schema(o.name))
  if not ok then
    print(cmd)
    return
  end

  o.db:execute(cmd)
  o.db_schema = o.db:schema(o.name)

  if with_foregin_key then
    o.db:execute "PRAGMA foreign_keys = ON;"
    o.db.opts.foreign_keys = true
  end
end

---Run sqltbl functions
---@param func function: wrapped function to run
---@param o sqltbl
---@return any
local run = function(func, o)
  a.should_have_db_object(o.db, o.name)
  local exec = function()
    local valid_schema = o.tbl_schema and next(o.tbl_schema) ~= nil

    --- Run once pre-init
    if o.tbl_exists == nil then
      o.tbl_exists = o.db:exists(o.name)
      o.mtime = o.db.uri and (luv.fs_stat(o.db.uri) or { mtime = {} }).mtime.sec or nil
      o.has_content = o.tbl_exists and o.db:eval(fmt("select count(*) from %s", o.name))[1]["count(*)"] ~= 0 or 0
      check_for_auto_alter(o, valid_schema)
    end

    --- Run when sqltbl doesn't exists anymore
    if o.tbl_exists == false and valid_schema then
      o.tbl_schema.ensure = u.if_nil(o.tbl_schema.ensure, true)
      o.db:create(o.name, o.tbl_schema)
      o.db_schema = o.db:schema(o.name)
    end

    --- Run once when we don't have schema
    if not o.db_schema then
      o.db_schema = o.db:schema(o.name)
    end

    --- Run wrapped function
    return func()
  end

  if o.db.closed then
    return o.db:with_open(exec)
  end
  return exec()
end

---Create new sql table object
---
---<pre>
---```lua
--- local tbl = sqltbl:new(db, "todos", {
---   id = true, -- { type = "integer", required = true, primary = true }
---   title = "text",
---   since = { "date", default = strftime("%s", "now") },
---   count = { "number", default = 0 },
---   type = { "text", required = true },
---   category = {
---     type = "text",
---     reference = "category.id",
---     on_update = "cascade", -- means when category get updated update
---     on_delete = "null", -- means when category get deleted, set to null
---   },
--- })
---```
---</pre>
---@param db sqldb
---@param name string: table name
---@param schema sqlschema
---@return sqltbl
function sqltbl:new(db, name, schema)
  schema = schema or {}
  local o = setmetatable({ db = db, name = name, tbl_schema = u.if_nil(schema.schema, schema) }, self)
  if db then
    run(function() end, o)
  end
  return o
end

---Same as |sqltbl:new()| but used to extend user defined object. This is the
---recommended way of constructing and using sqlite tables. The only difference
---between this and |sqltbl:new()| or |sqldb:table()| is the fact that all
---resulting methods are access using the dot notation '.', and when the user
---overwrites a sqltbl methods, it gets renamed to `_method_name`.
---
---if first argument is {name} then second should be {schema}. If no {db} is
---provided, the sqltbl object won't be initialized until 'sqltbl.set_db' is
---called, thus it can't be defined in different files.
---
---<pre>
---```lua
--- local t = tbl("entries", { ... } })
--- t.insert {...} -- insert rows NOTICE: dot notation
--- --- get all entries
--- t.get()
--- --- Overwrite method name and access original via t._get
--- t.get = function() return t._get({ where = {...}, select = {...} })[1] end
---```
---</pre>
---@param db sqldb
---@param name string
---@param schema sqlschema
---@return sqltblext
function sqltbl:extend(db, name, schema)
  if not schema and type(db) == "string" then
    name, db, schema = db, nil, name
  end

  local t = self:new(db, name, { schema = schema })
  return setmetatable({
    set_db = function(o)
      t.db = o
    end,
  }, {
    __index = function(o, key, ...)
      if type(key) == "string" then
        key = key:sub(1, 1) == "_" and key:sub(2, -1) or key
        if type(t[key]) == "function" then
          return function(...)
            return t[key](t, ...)
          end
        else
          return t[key]
        end
      end
    end,
  })
end

---Create or change table schema. If no {schema} is given,
---then it return current the used schema if it exists or empty table otherwise.
---On change schema it returns boolean indecting success.
---
---<pre>
---```lua
--- local projects = sqltbl:new("", {...})
--- --- get project table schema.
--- projects:schema() -- or 'project.schema()' dot notation with |sqltbl:extend|
--- --- mutate project table schema with droping content if not schema.ensure
--- projects:schema {...} -- or 'project.schema {...}' dot notation with |sqltbl:extend|
---```
---</pre>
---@param schema sqlschema
---@return sqlschema | boolean
function sqltbl:schema(schema)
  return run(function()
    local exists = self.db:exists(self.name)
    if not schema then -- TODO: or table is empty
      return exists and self.db:schema(self.name) or {}
    end
    if not exists or schema.ensure then
      self.tbl_exists = self.db:create(self.name, schema)
      return self.tbl_exists
    end
    if not schema.ensure then -- TODO: use alter
      local res = exists and self.db:drop(self.name) or true
      res = res and self.db:create(self.name, schema) or false
      self.tbl_schema = schema
      return res
    end
  end, self)
end

---Remove table from database, if the table is already drooped then it returns false.
---
---<pre>
---```lua
--- --- drop todos table content.
--- todos:drop() or 'todos.drop()' -- dot notation for |sqltbl:extend|
---```
---</pre>
---@see sqldb:drop
---@return boolean
function sqltbl:drop()
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
---
---<pre>
---```lua
--- if todos:empty() then -- or 'todos.emtpy()' for |sqltbl:extend|
---   print "no more todos, we are free :D"
--- end
---```
---</pre>
---@return boolean
function sqltbl:empty()
  return self:exists() and self:count() == 0 or false
end

---Predicate that returns true if the table exists.
---
---<pre>
---```lua
--- if goals:exists() then -- or 'goals.exists()' for |sqltbl:extend|
---   error("I'm disappointed in you :D")
--- end
---```
---</pre>
---@return boolean
function sqltbl:exists()
  return run(function()
    return self.db:exists(self.name)
  end, self)
end

---Get the current number of rows in the table
---
---<pre>
---```lua
--- if notes:count() == 0 then -- or 'notes.counts()' for |sqltbl:extend|
---   print("no more notes")
--- end
---```
---@return number
function sqltbl:count()
  return run(function()
    if not self.db:exists(self.name) then
      return 0
    end
    local res = self.db:eval("select count(*) from " .. self.name)
    return res[1]["count(*)"]
  end, self)
end

---Query the table and return results.
---
---<pre>
---```lua
--- --- get everything
--- todos:get() -- or 'todos.get()' with |sqltbl:extend|
--- --- get row with id of 1
--- todos:get { where = { id = 1 } } -- or 'todos.get { ... }' with |sqltbl:extend|
--- --- select a set of keys with computed one
--- timestamps:get { -- or 'timestamps.get {... }'  with |sqltbl:extend|
---   select = {
---     age = (strftime("%s", "now") - strftime("%s", "timestamp")) * 24 * 60,
---     "id",
---     "timestamp",
---     "entry",
---     },
---   }
---```
---</pre>
---@param query sqlquery_select
---@return table
---@see sqldb:select
function sqltbl:get(query)
  -- query = query or { query = { all = 1 } }

  return run(function()
    local res = self.db:select(self.name, query or { query = { all = 1 } }, self.db_schema)
    return res
  end, self)
end

---Get first match.
---
---<pre>
---```lua
--- --- get single entry. notice that we don't pass where key.
--- tbl:where{ id = 1 } -- or tbl.where()  with |sqltbl:extend|
--- --- get row with id of 1 or 'todos.where { id = 1 }'
---```
---</pre>
---@param where table: where key values
---@return nil or row
---@usage ``
---@see sqldb:select
function sqltbl:where(where)
  return where and self:get({ where = where })[1] or nil
end

---Iterate over table rows and execute {func}.
---Returns false if no row is returned.
---
---<pre>
---```lua
--- --- Execute a function on each returned row
--- todos:each(function(row)
---   print(row.title)
--- end, {
---   where = { status = "pending" },
---   contains = { title = "fix*" }
--- })
--- --- This works too. use 'todos.each(..)' with |sqltbl:extend|
--- todos:each({ where = { ... }}, function(row)
---   print(row.title)
--- end)
---```
---</pre>
---@param func function: func(row)
---@param query sqlquery_select|nil
---@return boolean
function sqltbl:each(func, query)
  if type(func) == "table" then
    func, query = query, func
  end

  return run(function()
    local rows = self.db:select(self.name, query or {}, self.db_schema)
    if not rows then
      return false
    end

    for _, row in ipairs(rows) do
      func(row)
    end

    return rows ~= {} or type(rows) ~= "boolean"
  end, self)
end

---Create a new table from iterating over a tbl rows with {func}.
---
---<pre>
---```lua
--- --- transform rows. use todos.map(..) with |sqltbl:extend|
--- local rows = todos:map(function(row)
---   row.somekey = ""
---   row.f = callfunction(row)
---   return row
--- end, {
---   where = { status = "pending" },
---   contains = { title = "fix*" }
--- })
--- --- This works too.
--- local titles = todos:map({ where = { ... }}, function(row)
---   return row.title
--- end)
--- --- no query, no problem :D
--- local all = todos:map(function(row) return row.title end)
---```
---</pre>
---@param func function: func(row)
---@param query sqltblext|nil
---@return table[]
function sqltbl:map(func, query)
  if type(func) == "table" then
    func, query = query, func
  end

  return run(function()
    local res = {}
    local rows = self.db:select(self.name, query or {}, self.db_schema)
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
---
---<pre>
---```lua
--- --- return rows sort by id. t1.sort() with |sqltbl:extend|
--- local res = t1:sort({ where = {id = {32,12,35}}})
--- --- return rows sort by age
--- local res = t1:sort({ where = {id = {32,12,35}}}, "age")`
--- --- return with custom sort function (recommended)
--- local res = t1:sort({where = { ... }}, "age", function(a, b) return a > b end)`
---```
---</pre>
---@param query sqlquery_select|nil
---@param transform function: a `transform` function to sort elements. Defaults to @{identity}
---@param comp function: a comparison function, defaults to the `<` operator
---@return table[]
function sqltbl:sort(query, transform, comp)
  return run(function()
    local res = self.db:select(self.name, query or { query = { all = 1 } }, self.db_schema)
    local f = transform or function(r)
      return r[u.keys(query.where)[1]]
    end
    if type(transform) == "string" then
      f = function(r)
        return r[transform]
      end
    end
    comp = comp or function(_a, _b)
      return _a < _b
    end
    table.sort(res, function(_a, _b)
      return comp(f(_a), f(_b))
    end)
    return res
  end, self)
end

---Insert rows into a table.
---
---<pre>
---```lua
--- --- single item.
--- todos:insert { title = "new todo" }
--- --- insert multiple items, using todos table as first param
--- sqltbl.insert(todos, "items", {  { name = "a"}, { name = "b" }, { name = "c" } })
--- --- insert with |sqltbl:extend|
--- todos.insert { ... }
---```
---</pre>
---@param rows table: a row or a group of rows
---@see sqldb:insert
---@usage `todos:insert { title = "stop writing examples :D" }` insert single item.
---@usage `todos:insert { { ... }, { ... } }` insert multiple items
---@return integer: last inserted id
function sqltbl:insert(rows)
  return run(function()
    local succ, last_rowid = self.db:insert(self.name, rows, self.db_schema)
    if succ then
      self.has_content = self:count() ~= 0 or false
    end
    return last_rowid
  end, self)
end

---Delete a rows/row or table content based on {where} closure. If {where == nil}
---then clear table content.
---
---<pre>
---```lua
--- --- delete todos table content
--- todos:remove()
--- --- delete row that has id as 1
--- todos:remove { id = 1 }
--- --- delete all rows that has value of id 1 or 2 or 3
--- todos:remove { id = {1,2,3} }
--- --- matching ids or greater than 5
--- todos:remove { id = {"<", 5} } -- or {id = "<5"}
--- --- with |sqtbl:extend|
--- todos.remove {...}
---```
---</pre>
---@param where sqlquery_delete
---@see sqldb:delete
---@return boolean
function sqltbl:remove(where)
  return run(function()
    return self.db:delete(self.name, where)
  end, self)
end

---Update table row with where closure and list of values
---returns true incase the table was updated successfully.
---
---<pre>
---```lua
--- --- update todos status linked to project "lua-hello-world" or "rewrite-neoivm-in-rust"
--- todos:update { -- or 'todos.update { .. }' with |sqltbl:extend|
---   where = { project = {"lua-hello-world", "rewrite-neoivm-in-rust"} },
---   set = { status = "later" }
--- }
--- --- pass custom statement and boolean
--- ts:update { -- or 'ts.update { .. }' with |sqltbl:extend|
---   where = { id = "<" .. 4 }, -- mimcs WHERE id < 4
---   set = { seen = true } -- will be converted to 0.
--- }
---```
---</pre>
---@param specs sqlquery_update
---@see sqldb:update
---@see sqlquery_update
---@return boolean
function sqltbl:update(specs)
  return run(function()
    local succ = self.db:update(self.name, specs, self.db_schema)
    return succ
  end, self)
end

---Replaces table content with a given set of {rows}.
---
---<pre>
---```lua
--- --- replace project table content with a single call
--- todos:replace { -- or 'todos.replace { ... }' with |sqltbl:extend|
---   { ... },
---   { ... },
---   { ... },
--- }
--- --- replace everything with a single row
--- ts:replace { -- or 'ts.replace { .. }' with |sqltbl:extend|
---   key = "val"
--- }
---```
---</pre>
---@param rows table[]|table
---@see sqldb:delete
---@see sqldb:insert
---@return boolean
function sqltbl:replace(rows)
  return run(function()
    self.db:delete(self.name)
    local succ = self.db:insert(self.name, rows, self.db_schema)
    return succ
  end, self)
end

sqltbl = setmetatable(sqltbl, { __call = sqltbl.extend })

return sqltbl
