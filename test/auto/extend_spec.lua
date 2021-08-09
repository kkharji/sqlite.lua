local sql = require "sql"
local eq = assert.are.same
local testrui = "/tmp/extend_db"
vim.loop.fs_unlink(testrui)

describe("extend:", function()
  local manager = sql:extend {
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
      -- foreign_keys = { client = "projects(id)", },
      -- KEY(client) REFERENCES projects(id)"
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

  it("access normal operations without self.super", function()
    eq("function", type(manager.insert), "should have added insert function.")
    eq("function", type(manager.open), "should have added open function.")
    eq("function", type(manager.close), "should have added close function.")
    eq("function", type(manager.with_open), "should have added with_open.")
    eq("function", type(manager.table), "should have added table.")
    eq("function", type(manager.super.insert), "should have added insert function.")
    eq("function", type(manager.super.open), "should have added open function.")
    eq("function", type(manager.super.close), "should have added close function.")
    eq("function", type(manager.super.with_open), "should have added with_open.")
    eq("function", type(manager.super.table), "should have added table.")
    manager:open()
    eq(true, manager:eval "insert into projects(title) values('sql.nvim')", "should insert.")
    eq("table", type(manager:eval("select * from projects")[1]), "should be have content even with self.super.")
    eq(true, manager.projects:remove(), "projects table should work.")
  end)

  it("create a custom insert", function()
    local sqlnvim = {
      title = "sql.nvim",
      objectives = {
        "Make storing data and persisting data ridiculously simple.",
        "Have great documentation and real world examples.",
        "More and more neovim plugins adopt sql.nvim as a data layer.",
      },
    }

    manager.projects.insert = function(self)
      local succ, id = self.super:insert(sqlnvim)
      if not succ then
        error "operation faild"
      end
      return id
    end

    eq(1, manager.projects:insert(), "should have returned id.")
    eq(
      sqlnvim.title,
      manager.projects:get({ where = { title = sqlnvim.title } })[1].title,
      "should have inserted sqlnvim project"
    )
  end)
  it("extending new object should work wihout issues", function() end)
end)
