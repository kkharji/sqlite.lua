sql.nvim
=================
> New possibilities for plugin development.

[sql.nvim] is [SQLite]/[LuaJIT] binding, as well as a highly opinionated
wrapper targeted towards a number of use-cases, e.g. storing, retrieving,
caching, persisting, querying, and connecting to [SQLite] databases.  While
[sql.nvim] is tailored to Neovim environment, ~~it can work in any lua
environment with luajit support.~~ see #29

- [Status]
- [Installation]
- [Usage]
  - [Low Level API]
  - [High Level API]
- [Credit]

Status
------------------
Under heavy development. API should be stable for usage. Contributions are
welcomed. Issues, feature and suggestions are encouraged.

#### Features:

- Connect, reconnect, close sql db connections `sql:open/sql:close`
- Evaluate any sqlite statement and return result if any `sql:eval`
- Helper function over `sql:eval` to do all sort of operation. 
- High level API with `sql:table` for better experience
- 90% test coverage.

#### WIP: 

- Docs
- Better boolean interop.
- Better join support.
- Serialization of lua tables to json so that lua tables can be inserted. (or byte code)

Installation
-----------------

Add sql.nvim to your lua `package.path`, neovim `/**/start/` or use your
favorite vim package manager, and ensure you have `sqlite3` installed locally.

##### Arch 
```
sudo pacman -S sqlite
```

##### MacOS
```
brew install sqlite
```

##### Ubuntu
```
sudo apt-get install sqlite3 libsqlite3-dev
```

##### Windows 
> Coming soon.


_NOTE: it is "sometimes" required that you set
`g:sql_clib_path`/`vim.g.sql_clib_path` to where libsqlite3.so is located, and
if that the case, pr or issue are welcomed to added in order to make it work regardless._ 

Usage
-----------------
For more usage example, please review test/auto/ and docs/sql.txt.

```lua
local sql = require'sql'
local db = sql.open() -- new in-memory 
local db = sql.open('/to/new/file') -- new sqlite database
local db = sql.open('/to/prexiting-db.sqlite3') -- pre-exiting sqlite database.
local db = sql.new(...) 
-- new creates new sql.nvim object but without opening/connect to the sqlite db, 
-- i.e. requires `db:open()`
db:close() -- closes connection 
```

- [Low level API]
  - [Open execute and close connection]
  - [Evaluate statements]
  - [Connection status]
  - [Create a table]
  - [Check if a table exists]
  - [Get a table schema]
  - [Drop a table]
  - [Query from a table]
  - [Insert into a table]
  - [Update rows in a table]
  - [Delete rows from a table]
- [High level API]
  - [Table New]
  - [Table schema]
  - [Table exists]
  - [Table empty]
  - [Table insert]
  - [Table update]
  - [Table remove]
  - [Table replace]
  - [Table get]
  - [Table each]
  - [Table map]
  - [Table sort]
  

### Low Level API

#### Evaluate statements

```lua
-- Evaluate any valid sql statement.
db:eval([[create table if not exists todos (
    id integer primary key, 
    action text, 
    due_date integer, 
    project_id integer
)]])

-- bind to unnamed values
db:eval("select * from todos where id = ?", { 1 })
db:eval("select * from todos where title = ?",  1)

-- bind to named values
db:eval("update todos set desc = :desc where id = :id", {
  id = 1,
  desc = "..."
})

-- WIP: evaluate a file with sql statements
db:eval("/path/to/schema.sql")
```

#### Open execute and close connection 

```lua
db:with_open(function(db) 
  -- commands
end)

sql.with_open("/path/to/file", function(db) 
  -- commands
end)

-- return something from with_open 
local res = sql.with_open("/path/to/db", function(db)
  db:eval("create table if not exists todo(title text, desc text)")
  db:eval("insert into todo(title, desc) values('title1', 'desc1')")
  return db:eval("select * from todo")
end)

```
#### Connection status

```lua
db:isopen() -- return true if the db connection is active
db:isclose() -- return true if the db connection is deactivated
db:status() -- returns last error msg and last error code
```

#### Create a table
```lua 
-- create new table with schema
db:create("tbl_name", {
  id = {"integer", "primary", "key"},
  title = "text",
  desc = "text",
  created = "int",
  -- ensure = true --:> if you like to create the table if it doesn't exist
  done = {"int", "not", "null", "default", 0},
})
```

#### Check if a table exists
```lua 
-- return true if `tbl_name` is an existing database
db:exists("tbl_name")
```

#### Get a table schema
```lua 
-- return a table of `tbl_name` keys and their sqlite type
db:schema("tbl_name")

-- return a list of `tbl_name` keys
db:schema("tbl_name", true)
```

#### Drop a table
```lua 
-- remove a table and all their data
db:drop("tbl_name")
```

#### Query from a table

```lua
-- Get all rows from posts table
db:select("posts")

-- Get rows that matches where clause
db:select("posts", {
  where  = {
    id = 1
  }
}

-- Get and inner join 
db:get("posts", {
  where  = { id = {1,2,3,4} }, -- any of provided ids
  join = { posts = "userId", users = "id" } -- see inner join.
})
```

#### Insert into a table

```lua
-- insert a single row to todos
db:insert("todos", {
  title = "TODO 1",
  desc = "................",
})

-- insert multiple rows to todos
db:insert("todos", {
    {
      title = "todo 3",
      desc = "...",
    },
    {
      title = "todo 2",
    },
    {
      title = "todo 1",
      deadline = 2025,
    },
})
```

#### Update rows in a table

```lua
db:update("todos", {
  where = { deadline = "2021" }, -- where clause.
  values = { status = "overdue" } -- the new values
})

db:update("todos", {
  where = { status = {"later", "not_done", "maybe"} }, -- later or not_done or maybe
  values = { status = "trash" } -- the new values
})
```

#### Delete rows in tables

```lua
-- delete everything in a table.
db:delete("todos") 

-- delete with where clause
db:delete("todos", {where =  {id = 1, title = {"a", "b", "c"}}})
db:delete("todos", {where =  {id = 88}})
```

### High Level API

- Easier to deal with sql-tables.
- No need to check for connection status. If db connection is open, then it
  will stay open, otherwise, it will stay closed
- No need to run the queries twice, for now cache is cleared out if the db file
  mtime is changes or `t:insert/t:delete/t:update/t:replace/db:eval` was called.

#### New table 
[Table New]: #table-new

```lua 
local db = sql:new(dbpath or nil) -- db:open/db:close is optional and not required

-- Initialize the sql table object. it can be non existing or new table.
local t = db:table("todos")
```

#### Table schema
[Table schema]: #table-schema

Create or change schema of the table. If the schema doesn't have ensure key,
then the table will be dropped and created with the new schema. Unless, the
table already has data, then the it should error out.
 
```lua 
-- create the table with the provided schema
t:schema{
  id = {"integer", "not", "null"},
  name = "text",
  age = "integer"
}
-- return the table schema or empty table if the table isn't created yet
t:schema()

-- drop the old schema and table content an create new one with the following schema
t:schema{
  id = {"integer", "not", "null"},
  name = "text",
}

-- don't even bother to read the schema if the table already exists, otherwise
-- create it. safe to run multiple time
t:schema{
  id = {"integer", "not", "null"},
  name = "text",
  ensure = true
}
```
#### Table drop 
[Table drop]: #table-drop

```lua 
-- same as sql:drop(tbl_name)
t:drop()
```

#### Table exists
[Table exists]: #table-exists

```lua 
-- return true if table exists
t:exists()
```

#### Table empty
[Table empty]: #table-empty

```lua 
-- returns `not t.has_content`
t:empty()
```

#### Table count
[Table empty]: #table-count

```lua 
-- returns the number of rows in a table
t:count()
```
#### Table insert
[Table insert]: #table-insert

```lua 
-- same functionalities as `sql.insert(tbl_name, ...)`
t:insert{ 
  id = 1, 
  name = "a" 
}

t:insert{ 
  {id = 1, name = "b" }, 
  {id = 3, name = "c", age = 19} 
}
```

#### Table update
[Table update]: #table-update

```lua 
-- same functionalities as `sql.update(tbl_name, ...)`

t:update{
  where = { .. }
  values = { .. },
}

t:update{
  {where = { .. } values = { .. }},
  {where = { .. } values = { .. }},
  {where = { .. } values = { .. }},
}
```
#### Table remove
[Table remove]: #table-remove

```lua 
-- same functionalities as `sql.delete`. if no arguments is
-- provided then it should remove all rows.

t:remove() -- remove everything
t:remove{ where = {id = 1, name = "a"} }
t:remove{ where = {id = {1,2,3,4}, name = "a"} }
```

#### Table replace
[Table replace]: #table-remove

```lua 
-- same functionalities as `sql.insert`, but delete the
-- content of table and replaced with the content.

t:replace{
  -- rows
}
```

#### Table get
[Table get]: #table-get

```lua 
-- same functionalities as `sql.select`
t:get() -- return everything


t:get{ -- Get rows that matches where clause
  where = { id = 1 }
}

t:get{ -- Get and inner join 
  where  = { id = {1,2,3,4} }, -- any of provided ids
  join = { posts = "userId", users = "id" } -- see inner join.
}
```

#### Table each
[Table each]: #table-each

```lua
-- Iterates over a table rows of with a function that get
-- execute on each row.

t:each({
  where = { .. }
  contains = { .. },
}, function(row) 
  -- execute stuff
end)
```

#### Table map
[Table map]: #table-map

```lua
-- produce a new table by a function that accept row.
local modified = t:map({
  where = { .. }
  contains = { .. },
}, function(row) 
  -- execute stuff
  -- return modified a new row or nothing
end)
```

#### Table sort
[Table sort]: #table-sort

```lua
-- Returns sorted rows based on transform and comparison function,

-- return rows sort by a key
local res = t1:sort({where = {id = {32,12,35}}}, "age")

-- return rows sort by id
local res = t1:sort({where = {id = {32,12,35}}})

-- return rows sort by custom function
local comp = function(a, b) return a > b end
local res = t1:sort({where = {id = { 32,12,35 }}}, "age", comp)
```

Credit 
-------------------
[Credit]: #credit

- All contributors making this tool stable and reliable for us to depend on.
- docs powered by [tree-sitter-lua]

[Installation]: #installation
[Status]: #status
[Usage]: #usage
[SQLite]: https://www.sqlite.org/index.html
[LuaJIT]: https://luajit.org
[sql.nvim]: https://github.com/tami5/sql.nvim
[tree-sitter-lua]: https://github.com/tjdevries/tree-sitter-lua
[@tjdevries]: https://github.com/tjdevries
[@Conni2461]: https://github.com/Conni2461
[Connect to sqlite db]: #connect-to-sqlite-db
[Low level API]: #low-level-api
[Open execute and close connection]: #open-execute-and-close-connection
[Evaluate statements]: #evaluate-statements
[Connection status]: #connection-status
[Create a table]: #create-a-table
[Check if a table exists]: #check-if-a-table-exists
[Get a table schema]: #get-a-table-schema
[Drop a table]: #drop-a-table
[Query from a table]: #query-from-a-table
[Insert into a table]: #insert-into-a-table
[Update rows in a table]: #update-rows-in-a-table
[Delete rows from a table]: #delete-rows-from-a-table
[High level API]: #high-level-api
