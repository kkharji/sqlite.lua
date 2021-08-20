local P = require "plenary.path"
local curl = require "plenary.curl"
local eq = assert.are.same
local sql = require "sql"
local u = require "sql.utils"

describe("sql", function()
  local path = "/tmp/db.sqlite3"
  vim.loop.fs_unlink(path)

  describe("sqlfunctions:", function()
    local db = sql.new()
    it("works with multiply", function()
      local sugar = (db.sqljulianday "now" - db.sqljulianday "now") * 5 * 7
      local expected = "(julianday('now') - julianday('now')) * 5 * 7"
      eq(expected, sugar, "should be equal")
    end)

    it("quotes supported arugments only", function()
      local sugar = db.sqljulianday "now" - db.sqljulianday "date"
      local expected = "(julianday('now') - julianday(date))"
      eq(expected, sugar, "should be equal")

      local sugar = db.sqljulianday "now" - db.sqljulianday "2016-10-18 16:45"
      local expected = "(julianday('now') - julianday('2016-10-18 16:45'))"
      eq(expected, sugar, "should be equal")
    end)

    it("cast as", function()
      local sugar = db.sqlcast((db.sqljulianday() - db.sqljulianday "timestamp") * 24 * 60, "integer")
      local expected = "cast((julianday('now') - julianday(timestamp)) * 24 * 60 as integer)"
      eq(expected, sugar, "should be equal")
      local sugar = db.sqlcast(db.sqljulianday() * 7, "integer")
      local expected = "cast(julianday('now') * 7 as integer)"
      eq(expected, sugar, "should be equal")
    end)
    db:close()
  end)

  describe(".new", function()
    it("should create sql.nvim without opening connection", function()
      local tmp = "/tmp/db4.db"
      local db = sql.new(tmp)
      eq("table", type(db), "should return sql.nvim object")
      eq(nil, db.conn, "connection shuld be nil")
      eq("table", type(db:open()), "should return sql.nvim object")
      eq(true, db:isopen(), "should be opened")
      eq(0, db:status().code, "should be be zero")
      eq(true, db:eval "create table if not exists a(title)", "should be create a table")
      eq(true, db:eval "insert into a(title) values('new')", "should be insert stuff")
      eq("table", type(db:eval "select * from a"), "should be have content")
      eq(true, db:close(), "should close")
      eq(true, db:isclose(), "should close")
      eq(true, P.exists(P.new(tmp)), "It should created the file")
      vim.loop.fs_unlink(tmp)
    end)
    it("should accept pargma options", function()
      local tmp = "/tmp/db5.db"
      local db = sql.new(tmp, {
        journal_mode = "persist",
      })
      db:open()
      eq("persist", db:eval("pragma journal_mode")[1].journal_mode)
      db:close()
      vim.loop.fs_unlink(tmp)
    end)
  end)

  describe(":open/:close", function() -- todo(tami5): change to open instead of connect.
    it("creates in memory database.", function()
      local db = sql:open()
      eq("table", type(db), "returns new main interface object.")
      eq("cdata", type(db.conn), "returns sql object.")
      assert(db:close(), "returns true if the connection is closed successfully.")
    end)

    it("creates new persistence database.", function()
      local db = sql:open(path)
      eq("cdata", type(db.conn), "returns sqlite object.")

      eq(true, db:eval "create table if not exists todo(title text, desc text, created int)")

      db:eval("insert into todo(title, desc, created) values(:title, :desc, :created) ", {
        { title = "1", desc = "......", created = 2021 },
        { title = "2", desc = "......", created = 2021 },
      })

      eq(true, db:close(), "It should close connection successfully.")
      eq(true, P.exists(P.new(path)), "It should created the file")
    end)

    it("connects to pre-existent database.", function()
      local db = sql:open(path)

      local todos = db:eval "select * from todo"
      eq("1", todos[1].title)
      eq("2", todos[2].title)

      eq(true, db:close(), "It should close connection successfully.")
      eq(true, P.exists(P.new(path)), "File should still exists")
      vim.loop.fs_unlink(path)
    end)

    it("returns data and time of creation", function()
      local db = sql:open()
      eq(os.date "%Y-%m-%d %H:%M:%S", db.created)
      db:close()
    end)

    it("should accept pargma options", function()
      local tmp = "/tmp/db912.db"
      local db = sql:open(tmp, {
        journal_mode = "persist",
      })
      eq("persist", db:eval("pragma journal_mode")[1].journal_mode)
      db:close()
      vim.loop.fs_unlink(tmp)
    end)

    it("reopen db object.", function()
      local db = sql:open(path)
      local row = { title = "1", desc = "...." }
      db:eval "create table if not exists todo(title text, desc text)"
      db:eval("insert into todo(title, desc) values(:title, :desc)", row)

      db:close()
      eq(true, db.closed, "should be closed.")

      db:open()
      eq(false, db.closed, "should be reopend.")

      eq(path, db.uri, "uri should be identical to db.uri")
      local res = db:eval "select * from todo"
      eq(row, res[1], vim.loop.fs_unlink(path), "local row should equal db:eval result.")
    end)
  end)

  describe(":open_with", function()
    it("works with initalized sql objects.", function()
      local db = sql:open(path)
      local row = { title = "1", desc = "...." }
      db:eval "create table if not exists todo(title text, desc text)"
      db:eval("insert into todo(title, desc) values(:title, :desc)", row)
      db:close()
      eq(true, db.closed, "should be closed.")

      local res = db:with_open(function()
        return db:eval "select * from todo"
      end)
      eq(true, db.closed, "should be closed.")
      eq("1", res[1].title, "should pass.")

      vim.loop.fs_unlink(path)
    end)

    it("works without initalizing sql objects. (via uri)", function()
      local res = sql.with_open(path, function(db)
        local row = { title = "1", desc = "...." }
        db:eval "create table if not exists todo(title text, desc text)"
        db:eval("insert into todo(title, desc) values(:title, :desc)", row)
        return db:eval "select * from todo"
      end)
      eq("1", res[1].title, "should pass.")
    end)
  end)

  describe(":isopen/isclose", function()
    local db = sql:open()
    it("returns true if the db connection is open", function()
      assert(db:isopen())
    end)
    it("returns true if the db connection is closed", function()
      db:close()
      assert(db:isclose())
    end)
  end)

  describe(":status", function()
    local db = sql:open()
    local status = db:status()
    it("returns status code of the last filed call", function()
      eq("number", type(status.code), "it should return sqlite last flag code")
    end)

    it("returns error message of the last filed call", function()
      eq("string", type(status.msg), "it should return sqlite last errmsg")
    end)

    it("return whether the connection is closed or still open", function()
      assert(not status.closed, "it should return connection status")
      db:close()
    end)
  end)

  describe(":eval", function()
    local db = sql:open()
    it("It evaluate should basic sqlite statement", function()
      eq(true, db:eval "create table people(id integer primary key, name text, age  integer)")
    end)

    it("returns true if the operation is successful", function()
      eq(true, db:eval "create table if not exists todos(id, title text, desc text, created int)")
    end)

    local row = {
      {
        id = 1,
        title = "Create something",
        desc = "Don't you dare to tell conni",
        created = os.time(),
      },
      {
        id = 2,
        title = "Don't work on something else",
        desc = "keep conni close by :P",
        created = os.time(),
      },
    }

    it("inserts lua table.", function()
      eq(true, db:eval("insert into todos(id, title,desc,created) values(:id, :title, :desc, :created)", row[1]))
    end)

    it("selects everything from table and return lua table if only one row.", function()
      local res = db:eval "select * from todos"
      eq(row[1], res[1])
    end)

    it("deletes from sql tables", function()
      eq(true, db:eval "delete from todos", "It should delete table content")
    end)

    it("inserts nested lua table.", function()
      eq(true, db:eval("insert into todos(id,title,desc,created) values(:id, :title, :desc, :created)", row))
      eq(row, db:eval "select * from todos", "should equal")
    end)

    it("return a lua table by id", function()
      local res
      res = db:eval("select * from todos where id = :id", { id = 1 })
      eq(row[1], res[1], "with named params")

      res = db:eval("select * from todos where id = ?", { 1 })
      eq(row[1], res[1], "with unamed params")

      res = db:eval("select * from todos where id = ?", 1)
      eq(row[1], res[1], "with single value")
    end)
    it("return the lua table with where and or", function()
      eq(row, db:eval "select * from todos where id = 1 or id = 2 or id = 3")
    end)
    it("update by id", function()
      eq(
        true,
        db:eval("update todos set desc = :desc where id = :id", {
          id = 1,
          desc = "...",
        }),
        "it works with named params"
      )
      eq(
        true,
        db:eval("update todos set desc = ? where id = ?", {
          2,
          "...",
        }),
        "it works with unnamed params"
      )
    end)

    it("delete by id", function()
      eq(true, db:eval("delete from todos where id = :id", { id = 2 }))
      eq(true, db:eval("delete from todos where id = :id", { id = 1 }))
      eq(true, db:eval "select * from todos", "It should be empty by now.")
    end)
    db:close()
  end)

  describe(":insert", function()
    local db = sql:open()
    assert(db:eval "create table todos(title text, desc text)")
    local ex_last_rowid = 0

    it("inserts a single row", function()
      local rows = {
        title = "TODO 1",
        desc = "................",
      }
      local _, last_row_id = db:insert("todos", rows)
      ex_last_rowid = ex_last_rowid + 1
      local results = db:eval "select rowid, * from todos"
      eq(true, type(results) == "table", "It should be inserted.")
      eq(last_row_id, results[1].rowid, "It should be equals to the returned last inserted rowid " .. last_row_id)
      eq("TODO 1", results[1].title)
      eq("................", results[1].desc)
      db:eval "delete from todos"
    end)

    it("inserts multiple rows", function()
      local rows = {
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
      local _, rowid = db:insert("todos", rows)
      ex_last_rowid = ex_last_rowid + #rows
      local store = db:eval "select rowid, * from todos"
      eq(rowid, store[#store].rowid, "It should be equals to the returned last inserted rowid " .. rowid)
      eq(3, vim.tbl_count(store))
      for _, v in ipairs(store) do
        eq(true, v.desc == "...")
      end
      db:eval "delete from todos"
    end)

    assert(db:eval [[
    create table if not exists test(
    id integer primary key,
    title text,
    name text not null,
    created integer default 'today',
    current timestamp default current_date,
    num integer default 0)
    ]])

    it("respects string defaults", function()
      db:insert("test", {
        { title = "A", name = "B" },
        { title = "C", name = "D" },
      })
      local res = db:eval [[ select * from test]]
      eq("today", res[1].created) -- FIXME
      eq("today", res[2].created) -- FIXME
    end)

    it("respects number defaults", function()
      db:insert("test", {
        { title = "A", name = "B" },
        { title = "C", name = "D" },
      })
      local res = db:eval [[ select * from test]]
      eq(0, res[1].num)
      eq(0, res[2].num)
    end)

    it("respects sqlvalues defaults", function()
      db:insert("test", {
        { title = "A", name = "B" },
        { title = "C", name = "D" },
      })
      local res = db:eval [[ select * from test]]
      eq(os.date "%Y-%m-%d", res[1].current)
      eq(os.date "%Y-%m-%d", res[2].current)
    end)

    it("respects fails if a key is null", function()
      local ok, _ = pcall(function()
        return db:insert("test", { title = "A" })
      end)
      eq(false, ok, "should fail")
    end)

    it("serialize lua table in sql column", function()
      db:eval "drop table test"
      db:eval "create table test(id integer, data luatable)"
      db:insert("test", { id = 1, data = { "list", "of", "lines" } })

      local res = db:eval [[select * from test]]
      eq('["list","of","lines"]', res[1].data)
      db:eval "drop table test"
    end)

    it("evaluates sqlite functions", function()
      db:eval "create table testa(id integer primary key, date text, title text)"
      db:insert("testa", { title = "fd", date = db.sqlstrftime "%H:%M:%S" })

      local res = db:eval [[select * from testa]]
      eq(os.date "!%H:%M:%S", res[1].date)
      eq("fd", res[1].title)
      db:eval "drop table testa"
    end)
    db:close()
  end)

  describe(":update", function()
    local db = sql:open()
    assert(db:eval "create table todos(title text, desc text)")

    it("works with table_name being as the first argument", function()
      local row = { title = "TODO 1", desc = "................" }
      db:eval("insert into todos(title, desc) values(:title, :desc)", row)

      db:update("todos", {
        values = { desc = "done" },
        where = { title = "TODO 1" },
      })
      local results = db:eval "select * from todos"
      eq(true, type(results) == "table", "It should be inserted.")
      eq("TODO 1", results[1].title)
      eq("done", results[1].desc)
      db:eval "delete from todos"
    end)

    it("works with table_name being a lua table key", function()
      local row = { title = "TODO 1", desc = " .......... " }
      db:eval("insert into todos(title, desc) values(:title, :desc)", row)

      db:update("todos", {
        values = { desc = "not done" },
        where = { title = "TODO 1" },
      })

      local results = db:eval "select * from todos"
      eq(true, type(results) == "table", "It should be inserted.")
      eq("TODO 1", results[1].title)
      eq("not done", results[1].desc)
      db:eval "delete from todos"
    end)

    it("update multiple rows in a sql table", function()
      db:eval "delete from todos"
      local rows = {
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
      db:eval("insert into todos(title, desc) values(:title, :desc)", rows)
      db:update("todos", {
        {
          values = { desc = "not done" },
          where = { title = "todo 1" },
        },
        {
          values = { desc = "done" },
          where = { title = "todo 2" },
        },
        {
          values = { desc = "almost done" },
          where = { title = "todo 3" },
        },
      })

      local store = db:eval "select * from todos"
      eq(3, vim.tbl_count(store))
      for _, v in ipairs(store) do
        eq(true, v.desc ~= "...")
      end
      db:eval "delete from todos"
    end)

    it("skip updating if opts is nil", function()
      db:update "todos"
    end)

    it("fallback to insert", function()
      local tmp = "nvim.nvim"
      db:update("todos", {
        values = { desc = tmp },
        where = { title = "3" },
      })
      local store = db:eval "select * from todos"
      eq(tmp, store[1].desc)
      eq("3", store[1].title)
    end)
    db:close()
  end)

  describe(":delete", function()
    local db = sql:open()
    assert(db:eval "create table todos(title text, desc text)")

    it("works with table_name being as the first argument", function()
      local row = { title = "TODO 1", desc = "................" }
      db:eval("insert into todos(title, desc) values(:title, :desc)", row)
      db:delete "todos"
      local results = db:eval "select * from todos"
      eq(false, type(results) == "table", "It should be deleted.")
    end)

    it("works with table_name being and where", function()
      local rows = {
        { title = "TODO 1", desc = "................" },
        { title = "TODO 2", desc = "................" },
      }
      db:eval("insert into todos(title, desc) values(:title, :desc)", rows)
      db:delete("todos", { where = { title = "TODO 1" } })
      local results = db:eval "select * from todos"
      eq(true, type(results) == "table")
      eq("TODO 2", results[1].title)
      eq("................", results[1].desc)
    end)

    it("delete multiple keys with list of ors", function()
      local rows = {
        { title = "TODO 1", desc = "................" },
        { title = "TODO 2", desc = "................" },
      }
      db:eval("insert into todos(title, desc) values(:title, :desc)", rows)
      db:delete("todos", { { where = { title = { "TODO 1", "TODO 2" } } } })
      local results = db:eval "select * from todos"
      eq(false, type(results) == "table")
    end)

    it("delete multiple keys with dict for each conditions. and passing only where", function()
      local rows = {
        { title = "TODO 1", desc = "................" },
        { title = "TODO 2", desc = "................" },
      }
      db:eval("insert into todos(title, desc) values(:title, :desc)", rows)
      db:delete("todos", { { title = "TODO 1" }, { title = "TODO 2" } })
      local results = db:eval "select * from todos"
      eq(false, type(results) == "table")
    end)
    it("delete multiple keys with dict for each conditions. V2", function()
      local rows = {
        { title = "TODO 1", desc = "................" },
        { title = "TODO 2", desc = "................" },
      }
      db:eval("insert into todos(title, desc) values(:title, :desc)", rows)
      db:delete("todos", { title = { "TODO 1", "TODO 2" } })
      local results = db:eval "select * from todos"
      eq(false, type(results) == "table")
    end)
    db:close()
  end)

  describe(":select", function()
    local db = sql:open(path)
    local posts, users

    it(".... pre", function()
      if vim.loop.fs_stat "/tmp/posts" == nil then
        curl.get("https://jsonplaceholder.typicode.com/posts", { output = "/tmp/posts" })
        curl.get("https://jsonplaceholder.typicode.com/users", { output = "/tmp/users" })
      end

      posts = vim.fn.json_decode(vim.fn.join(P.readlines "/tmp/posts", "\n"))

      eq("table", type(posts), "should have been decoded")

      assert(db:eval [[
      create table posts(id int not null primary key, userId int, title text, body text);
      ]])

      eq(
        true,
        db:eval(
          [[
      insert into posts(id, userId, title, body) values(:id, :userId, :title, :body)
      ]],
          posts
        )
      )

      eq("table", type(db:eval "select * from posts"), "there should be posts")

      users = vim.fn.json_decode(vim.fn.join(P.readlines "/tmp/users", "\n"))
      eq("table", type(users), "should have been decoded")
      for _, user in ipairs(users) do -- Not sure how to deal with nested tables now
        user["address"] = nil
        user["company"] = nil
      end

      assert(db:eval [[
      create table users(id int not null primary key, name text, email text, phone text, website text, username text);
      ]])

      eq(
        true,
        db:eval(
          [[
      insert into users(id, name, email, phone, website, username) values(:id,:name,:email,:phone,:website,:username)
      ]],
          users
        )
      )

      eq("table", type(db:eval "select * from users"), "there should be users")
    end)

    it("return everything with no params", function()
      eq(posts, db:select "posts")
    end)

    it("return everything that matches where closure", function()
      local res = db:select("posts", {
        where = {
          id = 1,
        },
      })
      local expected = (function()
        for _, post in ipairs(posts) do
          if post["id"] == 1 then
            return post
          end
        end
      end)()

      eq(expected, res[1])
    end)

    it("join tables.", function()
      local res = db:select("posts", { where = { id = 1 }, join = { posts = "userId", users = "id" } })
      local expected = (function()
        for _, post in ipairs(posts) do
          if post["id"] == 1 then
            return u.tbl_extend(
              "keep",
              post,
              (function()
                for _, user in ipairs(users) do
                  if user["id"] == post["userId"] then
                    return user
                  end
                end
              end)()
            )
          end
        end
      end)()

      eq(expected, res[1])
    end)

    it("return selected keys only", function()
      local res = db:select("posts", { where = { id = 1 }, keys = { "userId", "posts.body" } })
      local expected = (function()
        for _, post in ipairs(posts) do
          if post["id"] == 1 then
            return {
              userId = post["userId"],
              body = post["body"],
            }
          end
        end
      end)()

      eq(expected, res[1])
    end)

    it("return respecting a limit", function()
      local limit = 5
      local res = db:select("posts", { limit = limit })
      eq(#res, limit, "they should be the same")
    end)

    it("it serialize json if the schema key datatype is json", function()
      db:eval "create table test(id integer, data luatable)"
      db:eval 'insert into test(id,data) values(1, \'["list","of","lines"]\')'
      eq({
        { id = 1, data = { "list", "of", "lines" } },
      }, db:select "test", "they should be identical")
    end)

    db:close()
  end)

  describe(":schema", function()
    local db = sql:open()
    db:eval "create table test(a text, b int, c int not null, d text default def)"

    it("gets a sql table schema", function()
      local sch = db:schema "test"
      eq({ a = "text", b = "int", c = "int", d = "text" }, sch)
    end)

    it("gets a sql table schema info", function()
      local sch = db:schema("test", true).info
      eq({
        a = {
          cid = 0,
          primary = false,
          required = false,
          type = "text",
        },
        b = {
          cid = 1,
          primary = false,
          required = false,
          type = "int",
        },
        c = {
          cid = 2,
          primary = false,
          required = true,
          type = "int",
        },
        d = {
          cid = 3,
          primary = false,
          required = false,
          type = "text",
          default = "def",
        },
      }, sch)
    end)

    db:close()
  end)

  describe(":create", function()
    local db = sql:open()

    it("create a new sqlite table, and return true", function()
      eq(false, db:exists "test")
      db:create("test", {
        id = { "integer", "primary", "key" },
        title = "text",
        desc = "text",
        created = "int",
        done = { "int", "not", "null", "default", 0 },
      })
      eq(true, db:exists "test")
    end)

    it("won't override the table schema if it exists", function()
      db:create("test", { id = "not_a_type", ensure = true })
      local sch = db:schema "test"
      eq("text", sch.title, "should not be nil")
    end)
    it("auto enable foreign_keys on usage", function()
      db:create("test_keys", {
        id = true,
        title = "text",
        project = {
          type = "integer",
          reference = "projects.id",
        },
      })
      eq(1, db:eval("pragma foreign_keys")[1].foreign_keys)
    end)
    db:close()
  end)

  describe(":drop", function()
    local db = sql:open()

    it("should drop empty tables.", function()
      db:create("test", { a = "text", b = "int" })
      eq(true, db:exists "test", "should exists")
      db:drop "test"
      eq(true, not db:exists "test", "shout be dropped")
    end)

    it("should drop non-empty tables.", function()
      db:create("test", { a = "text", b = "int" })
      db:eval("insert into test(a,b) values(?,?)", { "a", 3 })
      eq(true, db:exists "test", "should exists")
      db:drop "test"
      eq(true, not db:exists "test", "shout be dropped")
    end)
    db:close()
  end)

  describe("extend:", function()
    local testrui = "/tmp/extend_db"
    local testrui2 = "/tmp/extend_db2"

    ---@class Manager:SQLDatabaseExt
    ---@field projects SQLTableExt
    ---@field todos SQLTableExt
    local manager = sql {
      uri = testrui,
      init = true,
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

      local id = manager.projects:insert(sqlnvim)

      eq(1, id, "should have returned id.")
      eq(true, manager.projects:remove(), "should remove after default insert.")

      function manager.projects:insert()
        return self.tbl:insert(sqlnvim)
      end

      local id = manager.projects:insert()
      eq(1, id, "should have returned id.")

      function manager.projects:get()
        return self.tbl:get({ where = { title = sqlnvim.title } })[1].title
      end

      eq(sqlnvim.title, manager.projects:get(), "should have inserted sqlnvim project")
    end)

    it("control initialization", function()
      local cache = sql {
        uri = "/tmp/extend_db2",
        files = { id = true, name = "text" },
        projects = { id = true, name = "text" },
      }

      eq(false, cache.is_initialized, "shouldn't be initialized")
      eq(true, not cache.projects, "project table shouldn't exists")
      eq(false, not cache.db, "we should have the sql object here.")

      cache:init()
    end)

    it("don't initialize and work when overwritten init", function()
      local cache = sql {
        uri = "/tmp/extend_db2",
        files = { id = true, name = "text" },
        projects = { id = true, name = "text" },
      }

      function cache:init(opts)
        self.db:init()
        cache.opts = opts
      end

      cache:init()

      eq(false, pcall(cache.init, cache, "should fail because we're trying to initialize the object twice."))

      -- eq("function", type(cache.projects.get), "project should be initialized and get should be a function")
      -- cache.projects:insert { name = "xx" }

      -- eq(cache.projects:where({ name = "xx" }).name, "should work")
    end)
    vim.loop.fs_unlink(testrui)
    vim.loop.fs_unlink(testrui2)
  end)
end)
