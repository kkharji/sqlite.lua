local sql = require "sql"
local eq = assert.are.same
local demo = {
  { a = 1, b = "lsf", c = "de" },
  { a = 99, b = "sdj", c = "in" },
  { a = 32, b = "sbs", c = "en" },
  { a = 12, b = "srd", c = "fn" },
  { a = 35, b = "cba", c = "qa" },
  { a = 4, b = "pef", c = "ru" },
  { a = 5, b = "sam", c = "da" },
}

local dbpath = "/tmp/tbl_methods_test.sql"
vim.loop.fs_unlink(dbpath)
local db = sql.new(dbpath)

local seed = function()
  db:open()
  db:create("T", { a = "integer", b = "text", c = "text", ensure = true })
  db:insert("T", demo)
  return db:table("T", { nocache = false }), db:table "N"
end

local clean = function()
  db:close()
  vim.loop.fs_unlink(dbpath)
end

describe("table", function()
  local t1, t2 = seed()

  describe(":new", function()
    it("create new object with sql.table methods.", function()
      eq("table", type(t1))
    end)
    it("registers table name in self.name.", function()
      eq("T", t1.name)
    end)
    it("registers whether the table exists in self.tbl_exists.", function()
      eq(true, t1.tbl_exists)
    end)
    it("registers whether the table has content in self.has_content.", function()
      eq(true, t1.has_content, "should be false")
    end)
    it("initalizes empty cache in self.cache", function()
      eq({}, t1.cache, "should be empty.")
    end)
    it("doesn't fail if table isn't created yat.", function()
      eq("table", type(t2))
    end)

    local opts = {
      schema = {
        id = "int",
        name = "text",
      },
    }
    local new = db:table("newtbl", opts)

    it("initalizes db with schema", function()
      eq(opts.schema, new:schema(), "should be identical")
      eq(opts.schema, new.tbl_schema, "should be identical")
    end)
    it("should not rewrite schema.", function()
      local new2 = db:table "newtbl"
      eq(opts.schema, new2:schema(), "should be identical")
      eq(opts.schema, new2.tbl_schema, "should be identical")

      local new3 = db:table("newtbl", { schema = { id = "string" } })
      eq(opts.schema, new3:schema(), "should be identical")
      eq(opts.schema, new3.tbl_schema, "should be identical")
    end)
  end)

  describe(":schema", function()
    it("returns schema if self.tbl exists", function()
      eq({ a = "integer", b = "text", c = "text" }, t1:schema())
    end)
    it("returns empty table if schema doesn't exists", function()
      eq({}, t2:schema())
    end)
    it("creates new table with schema", function()
      local schema = { id = "int", a = "text", d = "text" }
      eq(true, t2:schema(schema), "Should return true")
      eq(schema, t2:schema(), "should return the schema.")
      eq(true, t2.tbl_exists, "should alter self.exists value")
    end)
    it("should drop and recreate the table if not schema.ensure", function()
      local new = { id = "int", a = "text", f = "text" }
      eq(true, t2:schema(new), "Should return true")
      eq(new, t2:schema(), "should return the schema.")
      eq(true, t2.tbl_exists, "should alter self.exists value")
    end)
    it("should skip looking at the schema if schema.ensure", function()
      local old = t2:schema()
      local new = { i = "int", aaa = "text", fff = "text", ensure = true }
      eq(true, t2:schema(new), "Should return true")
      eq(old, t2:schema(), "should return the schema.")
    end)
  end)

  describe(":drop/:exists", function()
    it("should drop table", function()
      eq(true, t2:drop(), "should return true")
      eq(false, t2:exists(), "should not exists.")
    end)
    it("should return false if already dropped", function()
      eq(false, t2:drop(), "should be false")
    end)
  end)

  describe(":get", function()
    it("return everything.", function()
      local res = t1:get()
      eq(demo, res, "should be identical")
    end)

    it("runs a query and returns results (where)", function()
      local res = t1:get { where = { a = 1 } }
      eq(demo[1], res[1], "should be identical")
    end)

    it("runs a query and returns results (where & keys)", function()
      local res = t1:get { keys = { "b", "c" }, where = { a = 1 } }
      demo[1].a = nil
      eq(demo[1], res[1], "should be identical")
      demo[1].a = 1
    end)

    it("runs a query and returns results (keys & limit)", function()
      local limit = 3
      local res = t1:get { keys = { "a" }, limit = limit }
      eq(res[1].b, nil, "should not have the key")
      eq(res[1].c, nil, "should not have the key")
      eq(#res, limit, "they should be the same")
    end)

    it("runs a query from cache.", function()
      local res = t1:get { keys = { "b", "c" }, where = { a = 1 } }
      t1.cache["keys=bc,select=bc,where=a=1"][1].b = "bddddd"
      demo[1].b = "bddddd"
      demo[1].a = nil
      eq(demo[1], res[1], "should be identical")
      demo[1].b = "lsf"
      demo[1].a = 1
    end)

    it("cache should be cleared.", function()
      eq(vim.loop.fs_stat(dbpath).mtime.sec, t1.mtime, "should be the same")
      eq(true, db:eval("insert into T(a,b,c) values(?,?,?)", { 200, "a", "f" }), "should insert")
      eq(true, t1.db.modified, "should be modified tr")
      assert(db:eval "delete from T where a = 200", "should be deleted")
    end)

    it("run a query and returns results when connection is closed.", function()
      db:close()
      local res = t1:get { where = { a = 99 } }
      eq(demo[2], res[1], "should be identical")
    end)

    it("the db should stay closed after doing the query.", function()
      eq(true, t1.db.closed, "should update the state")
      eq(true, db.closed, "should update the state")
      db:open()
    end)
  end)

  it(":where", function()
    it("runs a query and returns results (where) with kv pairs", function()
      local res = t1:where { a = 1 }
      eq(demo[1], res, "should be identical")
    end)
  end)

  describe(":each", function()
    it("should work func", function()
      local res = {}
      eq(
        true,
        t1:each({ where = { a = { 12, 99, 32 } } }, function(row)
          table.insert(res, row.a)
        end),
        "the number of rows"
      )
      eq(res, { 99, 32, 12 }, "should be identical") -- this might fail at some point because of the ordering.
    end)

    it("should return from cache.", function()
      t1:get { where = { a = { 12, 99, 32 } } }
      local res = {}
      t1.cache["where=a=12,99,32"][1].a = 1
      t1.cache["where=a=12,99,32"][2].a = 2
      t1.cache["where=a=12,99,32"][3].a = 3

      t1:each({ where = { a = { 12, 99, 32 } } }, function(row)
        table.insert(res, row.a)
      end)

      eq(res, { 1, 2, 3 }, "should be identical") -- this might fail at some point because of the ordering.
    end)

    it("should not return from cache.", function()
      t1.nocache = true
      local res = {}
      t1:each({ where = { a = { 12, 99, 32 } } }, function(row)
        table.insert(res, row.a)
      end)

      eq(res, { 99, 32, 12 }, "should be identical")
    end)
  end)

  t1.nocache = false
  t1.cache = {}

  describe(":map", function()
    it("should work func", function()
      local res = t1:map({ where = { a = { 12, 99, 32 } } }, function(row)
        return row.a
      end)
      eq(res, { 99, 32, 12 }, "should be identical") -- this might fail at some point because of the ordering.
    end)

    it("should return from cache.", function()
      t1:get { where = { a = { 12, 99, 32 } } }
      t1.cache["where=a=12,99,32"][1].a = 1
      t1.cache["where=a=12,99,32"][2].a = 2
      t1.cache["where=a=12,99,32"][3].a = 3

      local res = t1:map({ where = { a = { 12, 99, 32 } } }, function(row)
        return row.a
      end)

      eq(res, { 1, 2, 3 }, "should be identical") -- this might fail at some point because of the ordering.
    end)
  end)

  describe(":sort", function()
    it("transform function defaults to to first where key", function()
      eq(
        {
          { a = 4, b = "pef", c = "ru" },
          { a = 5, b = "sam", c = "da" },
          { a = 35, b = "cba", c = "qa" },
        },
        t1:sort {
          where = { a = { 35, 4, 5 } },
        },
        "should be identical"
      )
    end)

    it("transform function can be a string with row key ", function()
      eq({
        { a = 12, b = "srd", c = "fn" },
        { a = 32, b = "sbs", c = "en" },
        { a = 35, b = "cba", c = "qa" },
      }, t1:sort(
        { where = { a = { 32, 12, 35 } } },
        "a"
      ))
      eq({
        { a = 32, b = "sbs", c = "en" },
        { a = 12, b = "srd", c = "fn" },
        { a = 35, b = "cba", c = "qa" },
      }, t1:sort(
        { where = { a = { 32, 12, 35 } } },
        "c"
      ))
      eq({
        { a = 35, b = "cba", c = "qa" },
        { a = 32, b = "sbs", c = "en" },
        { a = 12, b = "srd", c = "fn" },
      }, t1:sort(
        { where = { a = { 32, 12, 35 } } },
        "b"
      ))
    end)

    it("can use a custom comparison function", function()
      local comp = function(a, b)
        return a > b
      end
      eq({
        { a = 12, b = "srd", c = "fn" },
        { a = 32, b = "sbs", c = "en" },
        { a = 35, b = "cba", c = "qa" },
      }, t1:sort(
        { where = { a = { 32, 12, 35 } } },
        "b",
        comp
      ))
    end)
  end)

  describe(":remove", function()
    it("pre ... fill cache", function()
      eq({ demo[3] }, t1:get { where = { a = 32 } }, "should be identical.")
      eq({ demo[4] }, t1:get { where = { a = 12 } }, "should be identical.")
      eq("table", type(t1.cache["where=a=32"][1]), "should be filled")
    end)

    it("removes a single row", function()
      eq(true, t1:remove { where = { a = 5 } }, "should remove")
      eq(true, db:eval "select * from T where a = 5", "should return boolean, if no resluts")
    end)

    it("removes a multiple rows", function()
      eq(true, t1:remove { where = { a = { 35, 4 } } }, "should remove")
      eq(true, db:eval "select * from T where a = 35 or a = 4", "should return boolean, if no resluts")
    end)

    it("should empty cache", function()
      eq({}, t1.cache, "should remove")
    end)
  end)

  clean()
  seed()

  describe(":update", function()
    it("pre ... fill cache", function()
      eq({ demo[3] }, t1:get { where = { a = 32 } }, "should be identical.")
      eq({ demo[4] }, t1:get { where = { a = 12 } }, "should be identical.")
      eq("table", type(t1.cache["where=a=32"][1]), "should be filled")
    end)

    it("update a single row", function()
      eq(true, t1:update { where = { a = 4 }, values = { c = "a", b = "a" } }, "should be updated")
      demo[6] = { a = 4, c = "a", b = "a" }
      eq({ demo[6] }, db:eval "select * from T where a = 4", "should return boolean, if no resluts")
    end)

    it("update a multiple rows", function()
      eq(
        true,
        t1:update {
          {
            where = { a = 35 },
            values = { c = "a", b = "a" },
          },
          {
            where = { a = 5 },
            values = { c = "a", b = "a" },
          },
        },
        "should be updated"
      )
      demo[7] = { a = 5, c = "a", b = "a" }
      demo[5] = { a = 35, c = "a", b = "a" }
      eq({ demo[7] }, db:eval "select * from T where a = 5", "should return boolean, if no resluts")
      eq({ demo[5] }, db:eval "select * from T where a = 35", "should return boolean, if no resluts")
    end)

    it("should empty cache", function()
      eq({}, t1.cache, "should remove")
    end)
  end)

  clean()
  seed()

  describe(":replace", function()
    it("replcaes table content with new content", function()
      local new_rows = {
        { a = 1, b = "lsf", c = "de" },
        { a = 2, b = "sdj", c = "in" },
        { a = 3, b = "sbs", c = "en" },
      }
      eq(true, t1:replace(new_rows), "it should return true")
      eq(new_rows, t1:get(), "it should have the new rows")
    end)
  end)

  clean()
  seed()

  describe(":insert", function()
    local ex_last_rowid = #demo
    it("inserts a row", function()
      local new_row = { a = 109, b = "0", c = "0" }
      ex_last_rowid = ex_last_rowid + 1
      local succ, last_rowid = t1:insert(new_row)
      eq(true, succ, "it should return true")
      eq(ex_last_rowid, last_rowid, "it should return row_id " .. ex_last_rowid)
      eq({ new_row }, db:eval "select * from T where a = 109", "it should have the new rows")
    end)

    it("inserts a list of rows", function()
      local new_rows = {
        { a = 11, b = "lsf", c = "de" },
        { a = 22, b = "sdj", c = "in" },
        { a = 33, b = "sbs", c = "en" },
      }
      ex_last_rowid = ex_last_rowid + #new_rows
      local succ, last_rowid = t1:insert(new_rows)
      eq(true, succ, "it should return true")
      eq(ex_last_rowid, last_rowid, "it should return row_id " .. ex_last_rowid)
      eq(new_rows, db:eval "select * from T where a = 11 or a = 22 or a = 33", "it should have the new rows")
    end)
  end)

  clean()
  seed()

  describe(":count", function()
    it("retunrs the current number of rows in a db", function()
      eq(7, t1:count(), "the number of rows")
    end)
  end)

  clean()
end)
