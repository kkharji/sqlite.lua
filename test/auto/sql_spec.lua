local P = require'plenary.path'
local eq = assert.are.same
local sql = require'sql'

describe("sql.lua", function()

  describe("`open/close`", function() -- todo(tami5): change to open instead of connect.

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

    -- it("It should panic when error", function() -- TODO
    --   assert(false)
    -- end)
  end)

  describe('`isopen/isclose`', function()
    local db = sql.open()
    it('returns true if the db connection is open', function()
      assert(db:isopen())
    end)
    it('returns true if the db connection is closed', function()
      db:close()
      assert(db:isclose())
    end)
  end)

  describe('`status`', function()
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


  describe("eval", function()
    local db = sql.open()
    it('It evaluate should basic sqlite statement', function()
      eq(true, db:eval("create table people(id integer primary key, name text, age  integer)"))
    end)
    db:close()
  end)

 --[[ TODO: sql.eval
    it('execute multiple statements', function()
      eq(true, db:eval({
        "create todo table(title text, desc text, created init)",
        "drop todo table",
        "create project table(name text)",
        "drop project table"
      }))
    end)

    it('returns true if the operation is successful', function()
      eq(true, db:eval("create todo table(title text, desc text, created int)"))
    end)

    local row = {
      {
        title = "Create something",
        desc = "Don't you dare to tell conni",
        created = os.time()
      },
      {
        title = "Don't work on something else",
        desc = "keep conni close by :P",
        created = os.time()
      }
    }

    it('inserts lua table.', function()
      eq(true, conn:eval("insert into todo values(:title :desc, :created)", row[1]))
    end)

    it('selects everything from table and return lua array.', function()
      eq({row[1]}, conn:eval("select * from todo"))
    end)

    it('deletes from sql tables', function()
      eq(conn:eval("delete from todo") "It should delete table content")
    end)

    it('inserts nested lua table.', function()
      eq(true, conn:eval("insert into todo values(:title :desc, :created)", row))
      eq(row, conn:eval("selete * from todo", row))
    end)

    it('return a lua table by id', function()
      eq(row[1], conn:eval("select * from todo where id = ?", { id = 1 }))
    end)

    it('update by id', function()
      eq(true, conn:eval("update todo set desc = ?, where id = ?", {
        id = 1, desc = "..."
      }))
    end)

    it('delete by id', function()
      eq(true, conn:eval("delete from todo where id = ?", { id = 1 }))
    end)

    it('inserts nested lua table.', function()
      eq(true, conn:eval("insert into todo values(:title :desc, :created)", row))
      eq(row, conn:eval("selete * from todo", row))
    end)

    it('delete by range', function()
      eq(true, conn:eval("delete from todo where id between 1 and 2"))
    end)

    it('lists db tables', function()
      eq({"todo", "project"}, conn:eval(".tables"))
    end)
--]]

end)
