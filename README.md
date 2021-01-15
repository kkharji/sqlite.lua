sql.nvim
=================
> New possibilities for plugin development.

[sql.nvim] is [SQLite]/[LuaJIT] binding, as well as a highly opinionated
wrapper targeted towards a number of use-cases, e.g. storing, retrieving,
caching, persisting, querying, and connecting to [SQLite] databases. 

While its tailored to neovim environment, it can work in any lua environment with
luajit support.

- [Status]
- [Installation]
- [Usage]

Status
------------------
Under heavy development. API should be stable for usage. Contributions are
welcomed. Issues, feature and suggestions are encouraged.

#### Features:

- Connect, reconnect, close sql db connections `sql:open/sql:close`
- Evaluate any sqlite statement and return result if any `sql:eval`
- helper function over `sql:eval` to do all sort of operation. 
- 90% test coverage.

#### WIP: 

- docs
- better boolean interop.
- better join support.
- sql table object see https://github.com/tami5/sql.nvim/issues/18.

Installation
-----------------

To install or take advantage of sql.nvim correctly, simply add sql.nvim to
your lua `package.path`, neovim `/**/start/` or use your favorite
vim package manager.

NOTE: To make sure that sql.nvim work as expected, it is sometimes required
that you set `g:sql_clib_path` or `vim.g.sql_clib_path` to where
`libsqlite3.so` is located, and if that the case, pr or issue are welcomed to
add to sql.nvim lookup paths for `libsqlite3.so`.

Usage
-----------------
For more usage example, please review test/auto/ and docs/sql.txt.

- [Connect to sqlite db]
- [Open execute and close connection]
- [Evaluate statements]
- [Connection status]
- [Tables]
- [Query from a table]
- [Insert into a table]
- [Update rows in a table]
- [Delete rows from a table]

#### Connect to sqlite db

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

#### Tables

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

-- return true if `tbl_name` is an existing database
db:exists("tbl_name")

-- return a table of `tbl_name` keys and their sqlite type
db:schema("tbl_name")

-- return a list of `tbl_name` keys
db:schema("tbl_name", true)

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


Credit 
-------------------
- All contributors making this tool stable and reliable for us to depend on.
- docs powered by [tree-sitter-lua]

[Installation]: #installation
[Status]: #status
[Usage]: #status
[SQLite]: https://www.sqlite.org/index.html
[LuaJIT]: https://luajit.org
[sql.nvim]: https://github.com/tami5/sql.nvim
[tree-sitter-lua]: https://github.com/tjdevries/tree-sitter-lua
[@tjdevries]: https://github.com/tjdevries
[@Conni2461]: https://github.com/Conni2461
[Connect to sqlite db]: #connect-to-sqlite-db
[Open execute and close connection]: #open-execute-and-close-connection
[Evaluate statements]: #evaluate-statements
[Connection status]: #connection-status
[Tables]: #tables
[Query from a table]: #query-from-a-table
[Insert into a table]: #insert-into-a-table
[Update rows in a table]: #update-rows-in-a-table
[Delete rows from a table]: #delete-rows-from-a-table
