local sql = require "sql"
local eq = assert.are.same
local testrui = "/tmp/extend_db"
vim.loop.fs_unlink(testrui)

describe("extend:", function()
  ---@class Manager:SQLDatabaseExt
  ---@field projects SQLTableExt
  ---@field todos SQLTableExt
  local manager = sql {
    uri = testrui,
    projects = {
      id = true,
      title = "text",
      objectives = "luatable",
    },
    todos = {
      id = true,
      title = "text",
      client = "integer",
      status = "text",
      completed = "boolean",
      details = "text",
    },
    opts = {
      foreign_keys = true,
    },
  }

  it("process opts and set sql table objects", function()
    eq("/tmp/extend_db", manager.uri, "should set self.uri.")
    eq(true, manager.closed, "should construct without openning connection.")
    eq("cdata", type(manager.conn), "should set connection object because of how the sql object is set")
    eq("boolean", type(manager.sqlite_opts.foreign_keys), "should have added opts to sqlite_opts.")
  end)

  it("creates self.projects and self.todos", function()
    eq("table", type(manager.projects), "should have added sql table object")
    eq("table", type(manager.todos), "should have added sql table object for todos")
  end)

  it("access normal operations without self.db", function()
    eq("function", type(manager.insert), "should have added insert function.")
    eq("function", type(manager.open), "should have added open function.")
    eq("function", type(manager.close), "should have added close function.")
    eq("function", type(manager.with_open), "should have added with_open.")
    eq("function", type(manager.table), "should have added table.")
    eq("function", type(manager.db.insert), "should have added insert function.")
    eq("function", type(manager.db.open), "should have added open function.")
    eq("function", type(manager.db.close), "should have added close function.")
    eq("function", type(manager.db.with_open), "should have added with_open.")
    eq("function", type(manager.db.table), "should have added table.")
    manager:open()
    eq(true, manager:eval "insert into projects(title) values('sql.nvim')", "should insert.")
    eq("table", type(manager:eval("select * from projects")[1]), "should be have content even with self.db.")
    eq(true, manager.projects:remove(), "projects table should work.")
  end)

  it("extending new object should work wihout issues", function()
    local sqlnvim = {
      title = "sql.nvim",
      objectives = {
        "Make storing data and persisting data ridiculously simple.",
        "Have great documentation and real world examples.",
        "More and more neovim plugins adopt sql.nvim as a data layer.",
      },
    }

    local succ, id = manager.projects:insert(sqlnvim)
    ---TODO: use id
    -- eq(true, succ, "should have returned id.")

    eq(true, manager.projects:remove(), "should remove after default insert.")

    function manager.projects:insert()
      local succ, id = self.tbl:insert(sqlnvim)
      if not succ then
        error "operation faild"
      end
      return succ
    end

    local succ, id = manager.projects:insert()

    -- eq(true, succ, "should have returned id.")

    function manager.projects:get()
      return self.tbl:get({ where = { title = sqlnvim.title } })[1].title
    end

    eq(sqlnvim.title, manager.projects:get(), "should have inserted sqlnvim project")
  end)
end)
