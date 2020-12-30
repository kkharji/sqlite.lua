local P = require'plenary.path'
local eq = assert.are.same
local sql = require'sql'

describe("sql -", function()
  local conn

  describe("open/close:", function() -- todo(tami5): change to open instead of connect.
    it("returns sql object using in memory database.", function()
      conn = sql.connect()
      eq(not nil, conn, "It shouldn't be nil")
      -- assert(sql.connect() == nil, "It return handler")
      eq(true, conn:close(conn), "It should return true when the connection close")
      -- TODO(tami): We should have an api for checking connection status
    end)

    it("returns sql object using new file.", function()
      local path = "/tmp/db.sqlite3"
      conn = sql.connect(path)
      eq(not nil, conn, "It shouldn't be nil")
      eq(true, conn:close(conn), "It should return true when the connection close")
      eq(true, P.exists(P.new(path)), "It should create the file")
      vim.loop.fs_unlink(path)
    end)

    it("returns sql object using existing file.", function()
      local path = "/tmp/db2.sqlite3"
      vim.loop.fs_open(path, "w", 420)
      eq(not nil, sql.connect(path), "It shouldn't be nil")
      eq(not nil, sql.close(path), "It should close connection")
      vim.loop.fs_unlink(path)
    end)

    it("It should panic when error", function()
      -- Now thats hard one to determine.
    end)
  end)

  describe('errmsg', function()
    it('It should returns string with the last error msg', function()
      -- This also, we need to know what msg we get.
      -- local conn = sql.connect(path)
      -- conn:exec("invalid sql statement")
      -- eq(conn:errmsg(), "") -- TODO
    end)
  end)

  describe("exec", function()
    conn = sql.open()

    it('execute multiple statements', function()
      eq(true, conn:exec({
        "create todo table(title text, desc text, created init)",
        "drop todo table",
        "create project table(name text)",
        "drop project table"
      }))
    end)

    it('returns true if the operation is successful', function()
      eq(true, conn:exec([[create todo table(title text, desc text, created int)]]))
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
      eq(true, conn:exec("insert into todo values(:title :desc, :created)", row[1]))
    end)

    it('selects everything from table and return lua array.', function()
      eq({row[1]}, conn:exec("select * from todo"))
    end)

    it('deletes from sql tables', function()
      eq(conn:exec("delete from todo") "It should delete table content")
    end)

    it('inserts nested lua table.', function()
      eq(true, conn:exec("insert into todo values(:title :desc, :created)", row))
      eq(row, conn:exec("selete * from todo", row))
    end)

    it('return a lua table by id', function()
      eq(row[1], conn:exec("select * from todo where id = ?", { id = 1 }))
    end)

    it('update by id', function()
      eq(true, conn:exec("update todo set desc = ?, where id = ?", {
        id = 1, desc = "..."
      }))
    end)

    it('delete by id', function()
      eq(true, conn:exec("delete from todo where id = ?", { id = 1 }))
    end)

    it('inserts nested lua table.', function()
      eq(true, conn:exec("insert into todo values(:title :desc, :created)", row))
      eq(row, conn:exec("selete * from todo", row))
    end)

    it('delete by range', function()
      eq(true, conn:exec("delete from todo where id between 1 and 2"))
    end)

    it('lists db tables', function()
      eq({"todo", "project"}, conn:exec(".tables"))
    end)

    eq(true, conn:close(), "It should close connection.")

  end)
end)

