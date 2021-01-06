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
Under heavy development. Contributions are welcomed.

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
> To gain better understanding how sql.nvim works please review test/auto/ and docs/sql.txt.


#### Create new db connection

```lua
local sql = require'sql'
local db = sql.open() -- new in-memory 
local db = sql.open('/to/new/file') -- new sqlite database
local db = sql.open('/to/prexiting-db.sqlite3') -- pre-exiting sqlite database.
```

#### Check db connection status

```lua
db:isopen() -- return true if the db connection is active
db:isclose() -- return true if the db connection is deactivated
```

#### Close db connection 

```lua 
db:close()
```

#### Evaluate sqlite statements.

```lua
db:eval([[create table if not exists todos (
    id integer primary key, 
    action text, 
    due_date integer, 
    project_id integer
)]])

db:eval([[create table if not exists projects (
    id integer primary key, 
    title text, due_date integer
  )]])

db:eval("/path/to/schema.sqlite3")
```

#### Insert rows to tables

```lua
db:insert("todos", {
  title = "TODO 1",
  desc = "................",
})

db:insert {
  todos = {
    title = "TODO 1",
    desc = " .......... ",
  }
}

-- multiple rows
db:insert{
  todos = {
    {
      title = "todo 3",
      desc = "...",
    },
    {
      title = "todo 2",
      desc = "...",
    },
    {
      title = "todo 1",
      desc = "...",
    },
  }
}
-- :add is alternative name to :insert
db:add("todos", {
  title = "TODO 1",
  desc = "................",
})
```

#### Update rows in tables

```lua

db:update("todos", {
  where = { deadline = "2021" },
  values = { status = "overdue" }
})

db:update{
  todos = {
    where = {id = 1},
    values = {action = "DONE"}
  }
}
```

#### Delete rows in tables

```lua
db:delete("todos") -- delete everything in a table.

db:delete("todos", {id = 1})

db:delete{
  todos =  {
    where = {id = 1}
  } 
}
```

#### Open connection, execute a set of command then close

```lua
db:with_open(function(db) 
  -- commands
end)

sql.with_open("/path/to/file", function(db) 
  -- commands
end)
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
