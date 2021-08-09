local sql = require "sql"
local eq = assert.are.same
describe("extend:", function()
  local manager = sql:extend {
    uri = "/tmp/extend_db",
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

  it("set default field and opts", function()
    eq(manager.uri, "/tmp/extend_db", "should set self.uri.")
    eq(manager.closed, true, "should construct without openning connection.")
    eq(not manager.conn, "shouldn't set connection object.")
    eq(type(manager.sqlite_opts.foreign_keys), "should have added opts to sqlite_opts.")
  end)

  it("access normal operations without self.super", function()
    eq(type(manager.insert), "function", "should have added insert function.")
    eq(type(manager.open), "function", "should have added open function.")
    eq(type(manager.close), "function", "should have added close function.")
    eq(type(manager.with_open), "function", "should have added with_open")
    eq(type(manager.table), "function", "should have added table.")
    eq(true, manager:eval "insert into projects(title) values('sql.nvim')", "should insert.")
    eq("table", type(manager:eval "select * from projects"), "should be have content")
  end)

  it("creates self.projects and self.todos", function()
    eq(type(manager.projects), "table", "should have added sql table object")
    eq(type(manager.todos), "table", "should have added sql table object for todos")
  end)

  it("use sqltable object to insert data", function()
    local sqlnvim = {
      title = "sql.nvim",
      objectives = {
        "Make storing data and persisting data ridiculously simple.",
        "Have great documentation and real world examples.",
        "More and more neovim plugins adopt sql.nvim as a data layer.",
      },
    }
    manager.projects:remove()
    local succ, id = manager.projects:insert(sqlnvim)
    eq(true, succ, "should have succeeded.")
    eq(1, id, "should have returned id.")
    eq(
      sqlnvim.title,
      manager.projects:get { where = { title = sqlnvim.title } },
      "should have inserted sqlnvim project"
    )
  end)
end)
