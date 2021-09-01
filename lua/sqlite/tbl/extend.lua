---@type sqlite_tblext
local tbl = {}

---Create or change table schema. If no {schema} is given,
---then it return current the used schema if it exists or empty table otherwise.
---On change schema it returns boolean indecting success.
---@param schema table: table schema definition
---@return table table | boolean
---@usage `tbl.schema()` get project table schema.
---@usage `tbl.schema({...})` mutate project table schema
---@todo do alter when updating the schema instead of droping it completely
tbl.schema = function(schema) end

---Remove table from database, if the table is already drooped then it returns false.
---@usage `todos:drop()` drop todos table content.
---@see DB:drop
---@return boolean
tbl.drop = function() end

---Predicate that returns true if the table is empty.
---@usage `if todos:empty() then echo "no more todos, you are free :D" end`
---@return boolean
tbl.empty = function() end

---Predicate that returns true if the table exists.
---@usage `if not goals:exists() then error("I'm disappointed in you ") end`
---@return boolean
tbl.exists = function() end

---Query the table and return results.
---@param query sqlite_query_select
---@return table
---@usage `tbl.get()` get a list of all rows in project table.
---@usage `tbl.get({ where = { status = "pending", client = "neovim" }})`
---@usage `tbl.get({ where = { status = "done" }, limit = 5})` get the last 5 done projects
---@see DB:select
tbl.get = function(query) end

---Get the current number of rows in the table
---@return number
tbl.count = function() end

---Get first match.
---@param where table: where key values
---@return nil or row
---@usage `tbl.where{id = 1}`
---@see DB:select
tbl.where = function(where) end

---Iterate over table rows and execute {func}.
---Returns true only when rows is not emtpy.
---@param func function: func(row)
---@param query sqlite_query_select
---@usage `let query = { where = { status = "pending"}, contains = { title = "fix*" } }`
---@usage `tbl.each(function(row) print(row.title) end, query)`
---@return boolean
tbl.each = function(func, query) end

---Create a new table from iterating over {self.name} rows with {func}.
---@param func function: func(row)
---@param query sqlite_query_select
---@usage `let query = { where = { status = "pending"}, contains = { title = "fix*" } }`
---@usage `local t = todos.map(function(row) return row.title end, query)`
---@return table[]
tbl.map = function(func, query) end

---Sorts a table in-place using a transform. Values are ranked in a custom order of the results of
---running `transform (v)` on all values. `transform` may also be a string name property  sort by.
---`comp` is a comparison function. Adopted from Moses.lua
---@param query sqlite_query_select
---@param transform function: a `transform` function to sort elements. Defaults to @{identity}
---@param comp function: a comparison function, defaults to the `<` operator
---@return table[]
---@usage `local res = tbl.sort({ where = {id = {32,12,35}}})` return rows sort by id
---@usage `local res = tbl.sort({ where = {id = {32,12,35}}}, "age")` return rows sort by age
---@usage `local res = tbl.sort({where = { ... }}, "age", function(a, b) return a > b end)` with custom function
tbl.sort = function(query, transform, comp) end

---Same functionalities as |DB:insert()|
---@param rows table: a row or a group of rows
---@see DB:insert
---@usage `tbl.insert { title = "stop writing examples :D" }` insert single item.
---@usage `tbl.insert { { ... }, { ... } }` insert multiple items
---@return integer: last inserted id
tbl.insert = function(rows) end

---Same functionalities as |DB:delete()|
---@param where sqlite_query_delete: key value pairs to filter rows to delete
---@see DB:delete
---@return boolean
---@usage `todos.remove()` remove todos table content.
---@usage `todos.remove{ project = "neovim" }` remove all todos where project == "neovim".
---@usage `todos.remove{{project = "neovim"}, {id = 1}}` remove all todos where project == "neovim" or id =1
tbl.remove = function(where) end

---Same functionalities as |DB:update()|
---@param specs sqlite_query_update
---@see DB:update
---@return boolean
tbl.update = function(specs) end

---replaces table content with {rows}
---@param rows table: a row or a group of rows
---@see DB:delete
---@see DB:insert
---@return boolean
tbl.replace = function(rows) end

---Set db object for the table.
---@param db sqlite_db
tbl.set_db = function(db) end

return tbl
