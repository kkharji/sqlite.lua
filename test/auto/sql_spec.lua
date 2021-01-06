local P = require'plenary.path'
local eq = assert.are.same
local sql = require'sql'

describe("sql", function()
  describe(":open/:close", function() -- todo(tami5): change to open instead of connect.
    it('creates in memory database.', function()
      local db = sql.open()
      eq("table", type(db), "returns new main interface object.")
      eq("cdata", type(db.conn), "returns sql object.")
      assert(db:close(), "returns true if the connection is closed successfully.")
    end)

    it("creates new persistence database.", function()
      local path = "/tmp/db.sqlite3"
      local db = sql.open(path)
      -- FIXME: doesn't return cdata and fail to evaluate statement, which is
      -- need for creating the file.
      -- eq("cdata", type(db.conn), "returns sqlite object.")
      -- eq(true, db:eval("create todo table (title text, desc text, created int)"))
      assert(db:close(), "It should close connection successfully.")
      -- eq(true, P.exists(P.new(path)), "It should created the file")
      -- vim.loop.fs_unlink(path)
    end)

    it("connects to pre-existent database.", function()
      local db = sql.open(path)
      local path = "/tmp/db2.sqlite3"
      vim.loop.fs_open(path, "w", 420)
      eq("cdata", type(db.conn), "It should return sqlite object.")
      assert(db:close(), "It should close connection successfully.")
      assert(P.exists(P.new(path)), "It should created the file")
      vim.loop.fs_unlink(path)
    end)

    it('returns data and time of creation', function()
      local db = sql.open()
      eq(os.date('%Y-%m-%d %H:%M:%S'), db.created)
      db:close()
    end)
  end)

  describe(':isopen/isclose', function()
    local db = sql.open()
    it('returns true if the db connection is open', function()
      assert(db:isopen())
    end)
    it('returns true if the db connection is closed', function()
      db:close()
      assert(db:isclose())
    end)
  end)

  describe(':status', function()
    local db = sql.open()
    local status = db:status()
    it('returns status code of the last filed call', function()
      eq("number", type(status.code), "it should return sqlite last flag code")
    end)

    it('returns error message of the last filed call', function()
      eq("string", type(status.msg), "it should return sqlite last errmsg")
    end)


    it('return whether the connection is closed or still open', function()
      assert(not status.closed, "it should return connection status")
      db:close()
    end)
  end)

  describe(":eval", function()
    local db = sql.open()
    it('It evaluate should basic sqlite statement', function()
      eq(true, db:eval("create table people(id integer primary key, name text, age  integer)"))
    end)
    it('execute multiple statements', function()
      eq(true, db:eval({
        "create table todos(id integer primary key, title text, desc text, created int);",
        "create table projects(id integer primary key, name text);",
      }))

      eq(true, db:exists("todos"), "it should exists")
      eq(true, db:exists("projects"), "it should exists")
    end)

    it('returns true if the operation is successful', function()
      eq(true, db:eval("create table if not exists todos(title text, desc text, created int)"))
    end)

    local row = {
      {
        id = 1,
        title = "Create something",
        desc = "Don't you dare to tell conni",
        created = os.time()
      },
      {
        id = 2,
        title = "Don't work on something else",
        desc = "keep conni close by :P",
        created = os.time()
      }
    }

    it('inserts lua table.', function()
      eq(true, db:eval("insert into todos(id, title,desc,created) values(:id, :title, :desc, :created)",
      row[1]))
    end)

    it('selects everything from table and return lua table if only one row.', function()
      eq(row[1], db:eval("select * from todos"))
    end)

    it('deletes from sql tables', function()
      eq(true, db:eval("delete from todos"), "It should delete table content")
    end)

    it('inserts nested lua table.', function()
      eq(true, db:eval("insert into todos(id,title,desc,created) values(:id, :title, :desc, :created)", row))
      eq(row, db:eval("select * from todos"), row)
    end)

    it('return a lua table by id', function()
      eq(row[1], db:eval("select * from todos where id = :id", { id = 1 }), "with named params")
      eq(row[1], db:eval("select * from todos where id = ?", { 1 }), "with unamed params")
      eq(row[1], db:eval("select * from todos where id = ?",  1), "with single value")
    end)

    it('update by id', function()
      eq(true, db:eval("update todos set desc = :desc where id = :id", {
        id = 1,
        desc = "..."
      }), "it works with named params")
      eq(true, db:eval("update todos set desc = ? where id = ?", {
        2,
        "..."
      }), "it works with unnamed params")
    end)

    it('delete by id', function()
      eq(true, db:eval("delete from todos where id = :id", { id = 2 }))
      eq(true, db:eval("delete from todos where id = :id", { id = 1 }))
    eq(true, db:eval("select * from todos"), "It should be empty by now.")
    end)
    db:close()
  end)
  describe(':insert', function()
    local db = sql.open()
    assert(db:eval("create table todos(title text, desc text)"))

    it('works with table_name being as the first argument', function()
      db:insert("todos", {
        title = "TODO 1",
        desc = "................",
      })
      eq(true, type(db:eval("select * from todos")) == "table", "It should be inserted.")
      db:eval("delete from todos")
    end)

    it('works with table_name being a lua table key', function()
      db:insert {
        todos = {
          title = "TODO 1",
          desc = " .......... ",
        }
      }
      eq(true, type(db:eval("select * from todos")) == "table", "It should be inserted.")
      db:eval("delete from todos")
    end)

    it('inserts multiple rows in a sql table', function()
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
      local store = db:eval("select * from todos")
      eq(3, vim.tbl_count(store))
      db:eval("delete from todos")
    end)

    -- [[ TODO
    it('inserts multiple rows in a multiple sql table', function()
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
        },
        projects = {
          {name = "Alpha"},
          {name = "Beta"},
          {name = "lost count :P"},
        }
      }
      local todos = db:eval("select * from todos")
      local projects = db:eval("select * from todos")
      eq(3, vim.tbl_count(todos))
      eq(3, vim.tbl_count(projects))
      db:eval("delete from todos")
    end)
    -- ]]
    db:close()
  end)
end)
