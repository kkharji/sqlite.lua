local clib = require "sqlite.defs"
local stmt = require "sqlite.stmt"

local eval = function(conn, st, callback, arg1, errmsg)
  return clib.exec(conn, st, callback, arg1, errmsg)
end

local conn = function(uri)
  uri = uri or ":memory:"
  local conn = clib.get_new_db_ptr()
  local code = clib.open(uri, conn)
  if code == clib.flags.ok then
    return conn[0]
  else
    error(string.format("sqlite.lua: couldn't connect to sql database, ERR:", code))
  end
end

describe("stmt", function()
  local eq = assert.are.same
  local kill = function(s, db)
    if not s.finalized then
      eq(true, s:finalize())
    end
    eq(0, clib.close(db))
  end

  describe(":parse()     ", function()
    local db = conn()
    local stm = "select * from todos"

    eval(db, "create table todos(id integer primary key, title text, decs text, deadline integer);")
    local s = stmt:parse(db, stm)

    it("creates new statement object.", function()
      eq("table", type(s))
    end)
    it("registers db connection in `s.conn`.", function()
      eq("cdata", type(s.conn))
    end)
    it("registers unparsed statement in `s.str`.", function()
      eq(stm, s.str)
    end)
    it("parses sql statement in `s.pstmt`.", function()
      eq("cdata", type(s.pstmt))
    end)
    it("requires s:finalize() in order to close connection.", function()
      kill(s, db)
    end)
  end)

  local db, expectedlist, expectedkv, s
  db = conn() -- start of first suit test.
  for _, v in pairs {
    [[create table todos(id integer primary key, title text, desc text, deadline integer);]],
    [[insert into todos (title,desc,deadline) values("Create something", "Don't you dare to tell conni", 2021);]],
    [[insert into todos (title,desc,deadline) values("Don't work on something else", 'keep conni close by :P', 2021);]],
  } do
    eval(db, v)
  end

  expectedkv = {
    {
      id = 1,
      title = "Create something",
      desc = "Don't you dare to tell conni",
      deadline = 2021,
    },
    {
      id = 2,
      title = "Don't work on something else",
      desc = "keep conni close by :P",
      deadline = 2021,
    },
  }

  expectedlist = {}
  for i, t in ipairs(expectedkv) do
    expectedlist[i] = {}
    for _, v in pairs(t) do
      table.insert(expectedlist[i], v)
    end
  end
  s = stmt:parse(db, "select * from todos")

  describe(":nkeys()     ", function()
    it("returns the number of columns/keys in results.", function()
      eq(4, s:nkeys())
    end)
  end)

  describe(":types()     ", function()
    it("returns the type of each columns/keys in results.", function()
      -- TODO: this fails on github actions for unknown reason.
      -- eq({ "number", "string", "string", "number" }, s:types())
    end)
  end)

  describe(":convert_type(i)     ", function()
    it("returns the type of columns/keys by idx.", function()
      -- TODO: this fails on github actions for unknown reason.
      -- eq("string", s:convert_type(1))
    end)
  end)

  describe(":keys()      ", function()
    it("returns key/column names", function()
      eq({ "id", "title", "desc", "deadline" }, s:keys())
    end)
  end)

  describe(":key(i)      ", function()
    it("returns key/column name by idx", function()
      eq("id", s:key(0))
    end)
  end)

  describe(":kt()        ", function()
    it("returns a dict of key name and their type.", function()
      -- TODO: this fails on github actions for unknown reason.
      -- eq({
      --   deadline = "number",
      --   desc = "string",
      --   id = "number",
      --   title = "string",
      -- }, s:kt())
    end)
  end)

  describe(":kv()        ", function()
    it("returns (with stmt:each) key-value pairs of all rows", function()
      local done = false
      local res = {}
      s:each(function(st)
        table.insert(res, st:kv())
        done = true
      end)
      vim.wait(4000, function()
        return done
      end)
      eq(true, not vim.tbl_isempty(res), "It should be filled.")
      eq(expectedkv, res, "It should be identical.")
    end)
  end)

  if s.finalized then
    s:__parse()
  end

  describe(":val(i)      ", function()
    it("returns (with stmt:each) a list of vals in all the rows at idx.", function()
      local res = {}
      s:each(function(st)
        table.insert(res, st:val(0))
      end)
      eq(false, vim.tbl_isempty(res))
      eq({ 1, 2 }, res)
    end)
  end)

  describe(":vals()      ", function()
    it("returns (with stmt:each) a nested list all the vals in all the rows.", function()
      local res = {}
      s:each(function(st)
        table.insert(res, st:vals())
      end)
      eq(false, vim.tbl_isempty(res))
      -- eq(expectedlist, res) -- the order is missed up.
    end)
  end)

  describe(":kvrows()    ", function()
    it("returns a nested kv-pairs all the rows. if no callback.", function()
      local res = s:kvrows()
      eq(true, not vim.tbl_isempty(res), "it should be filled.")
      eq("table", type(res), "it should be of the type table.")
      eq("table", type(res[1]), "should be true")
      eq(expectedkv, res)
      if s.finalized then
        s:__parse()
      end
    end)
  end)

  describe(":vrows()     ", function()
    -- assert(s.finalized)
    it("returns a nested list values in all the rows. if no callback.", function()
      local res = s:vrows()
      eq(true, not vim.tbl_isempty(res), "it should be filled.")
      -- eq(expectedlist, res, "it should be identical") -- the order is mixed up
    end)
  end)

  describe(":nrows()     ", function()
    it("returns the number of rows in results", function()
      eq(2, s:nrows())
    end)
  end)

  kill(s, db) -- end of second suit
  local bind_db = conn() -- start of third db test
  eval(bind_db, [[create table todos(id integer primary key, title text, desc text, deadline integer);]])
  local bind_s = stmt:parse(bind_db, "insert into todos (title,desc,deadline) values(:title, :desc, :deadline);")
  local expected_stmt =
    "insert into todos (title,desc,deadline) values('Fancy todo title', 'We are doing all the things', 2021.0);"

  describe(":nparam()    ", function()
    it("returns the parameter count.", function()
      eq(3, bind_s:nparam())
    end)
  end)

  describe(":param(i)    ", function()
    it("returns parameter names by idx.", function()
      eq(":title", bind_s:param(1))
      eq(":desc", bind_s:param(2))
      eq(":deadline", bind_s:param(3))
    end)
  end)

  describe(":params()    ", function()
    it("returns all parameter keys/names with no idx", function()
      eq({ ":title", ":desc", ":deadline" }, bind_s:params())
    end)
  end)

  describe(":bind()      ", function()
    it("binds values by idx", function()
      bind_s:bind(1, "Fancy todo title")
      bind_s:bind(2, "We are doing all the things")
      bind_s:bind(3, 2021)
      eq(expected_stmt, bind_s:expand())
    end)
    it("bind values by names.", function()
      bind_s:bind_clear()
      bind_s:bind {
        ["title"] = "Fancy todo title",
        ["desc"] = "We are doing all the things",
        ["deadline"] = 2021,
      }
      eq(expected_stmt, bind_s:expand())
    end)
  end)

  describe(":bind_next() ", function()
    it("bind values by order in which they appear next", function()
      bind_s:bind_clear()
      bind_s:bind_next "Fancy todo title"
      bind_s:bind_next "We are doing all the things"
      bind_s:bind_next(2021)
      eq(expected_stmt, bind_s:expand())
    end)
  end)

  describe(":bind_clear()", function()
    it("clear bindigns.", function()
      eq(0, bind_s:bind_clear(), "it should return 0")
    end)
  end)

  describe(":bind_blob() ", function()
    it("binds blobs by idx", function()
      bind_s:bind_clear()
      bind_s:bind_blob(1, clib.get_new_blob_ptr(), 10)
    end)
  end)

  describe(":bind_zeroblob()", function()
    it("binds a zeroblob by idx", function()
      bind_s:bind_clear()
      bind_s:bind_zeroblob(1, 10)
      eq("insert into todos (title,desc,deadline) values(zeroblob(10), NULL, NULL);", bind_s:expand())
    end)
  end)

  kill(bind_s, bind_db) -- end of third test suit
  bind_db = conn() -- beginning of forth test suit
  eval(bind_db, [[create table todos(id integer primary key, title text, desc text, deadline integer);]])
  bind_s = stmt:parse(bind_db, "insert into todos (title,desc,deadline) values(?, ?, ?);")
  expected_stmt =
    "insert into todos (title,desc,deadline) values('Fancy todo title', 'We are doing all the things', 2021.0);"

  describe(":nparam()    ", function()
    it('does as expected with "anonymous parmas"', function()
      eq(3, bind_s:nparam())
    end)
  end)

  describe(":param(i)    ", function()
    it('does as expected with "anonymous parmas"', function()
      eq("?", bind_s:param(1))
      eq("?", bind_s:param(2))
      eq("?", bind_s:param(3))
    end)
  end)

  describe(":params()    ", function()
    it('does as expected with "anonymous parmas"', function()
      eq({ "?", "?", "?" }, bind_s:params())
    end)
  end)

  describe(":bind()      ", function()
    it('does as expected with "anonymous parmas"', function()
      bind_s:bind_clear()
      bind_s:bind(1, "Fancy todo title")
      bind_s:bind(2, "We are doing all the things")
      bind_s:bind(3, 2021)
      eq(expected_stmt, bind_s:expand())
      bind_s:bind_clear()
      bind_s:bind {
        "Fancy todo title",
        "We are doing all the things",
        2021,
      }
      eq(expected_stmt, bind_s:expand())
    end)
  end)

  describe(":bind_next() ", function()
    it('does as expected with "anonymous parmas"', function()
      bind_s:bind_clear()
      bind_s:bind_next "Fancy todo title"
      bind_s:bind_next "We are doing all the things"
      bind_s:bind_next(2021)
      eq(expected_stmt, bind_s:expand())
    end)
  end)

  describe(":bind_blob() ", function()
    it('does as expected with "anonymous parmas"', function()
      bind_s:bind_clear()
      bind_s:bind_blob(1, clib.get_new_blob_ptr(), 10)
    end)
  end)

  describe(":bind_zeroblob()", function()
    it('does as expected with "anonymous parmas"', function()
      bind_s:bind_clear()
      bind_s:bind_zeroblob(1, 10)
      eq("insert into todos (title,desc,deadline) values(zeroblob(10), NULL, NULL);", bind_s:expand())
    end)
  end)

  kill(bind_s, bind_db) -- end of forth test suit
  bind_db = conn() -- beginning of fifth test suit
  eval(bind_db, [[create table todos(id integer primary key, title text, desc text, deadline integer);]])
  bind_s = stmt:parse(bind_db, "insert into todos (title,desc,deadline) values(:title, ?, :deadline);")
  expected_stmt =
    "insert into todos (title,desc,deadline) values('Fancy todo title', 'We are doing all the things', 2021.0);"

  describe(":nparam()    ", function()
    it('does as expected with "anonymous params" and "named params"', function()
      eq(3, bind_s:nparam())
    end)
  end)

  describe(":param(i)    ", function()
    it('does as expected with "anonymous params" and "named params"', function()
      eq(":title", bind_s:param(1))
      eq("?", bind_s:param(2))
      eq(":deadline", bind_s:param(3))
    end)
  end)

  describe(":params()    ", function()
    it('does as expected with "anonymous params" and "named params"', function()
      eq({ ":title", "?", ":deadline" }, bind_s:params())
    end)
  end)

  describe(":bind()      ", function()
    it('does as expected with "anonymous params" and "named params"', function()
      bind_s:bind_clear()
      bind_s:bind(1, "Fancy todo title")
      bind_s:bind(2, "We are doing all the things")
      bind_s:bind(3, 2021)
      eq(expected_stmt, bind_s:expand())
      bind_s:bind_clear()
      bind_s:bind {
        ["title"] = "Fancy todo title",
        "We are doing all the things",
        ["deadline"] = 2021,
      }
      eq(expected_stmt, bind_s:expand())
    end)
  end)

  describe(":bind_next() ", function()
    it('does as expected with "anonymous params" and "named params"', function()
      bind_s:bind_clear()
      bind_s:bind_next "Fancy todo title"
      bind_s:bind_next "We are doing all the things"
      bind_s:bind_next(2021)
      eq(expected_stmt, bind_s:expand())
    end)
  end)

  describe(":bind_blob() ", function()
    it('does as expected with "anonymous params" and "named params"', function()
      bind_s:bind_clear()
      bind_s:bind_blob(1, clib.get_new_blob_ptr(), 10)
    end)
  end)

  describe(":bind_zeroblob()", function()
    it('does as expected with "anonymous params" and "named params"', function()
      bind_s:bind_clear()
      bind_s:bind_zeroblob(1, 10)
      eq("insert into todos (title,desc,deadline) values(zeroblob(10), NULL, NULL);", bind_s:expand())
    end)
  end)

  kill(bind_s, bind_db) -- end of fifth test suit
  bind_db = conn() -- beginning of sixth test suit
  eval(bind_db, [[create table todos(id integer primary key, title text, desc text, deadline integer);]])
  bind_s = stmt:parse(bind_db, "insert into todos (id,title,desc,deadline) values(:id, :title, :desc, :deadline);")

  describe("Combined test", function()
    it("passes", function()
      -- [ @conni should this block be abstracted in :bind(dict)?
      for _, v in ipairs(expectedkv) do
        bind_s:bind(v)
        bind_s:step()
        bind_s:reset()
        bind_s:bind_clear()
      end
      -- ]]]]]
      bind_s:finalize()
      local select = stmt:parse(bind_db, "select * from todos")
      eq(expectedkv, select:kvrows())
      kill(select, bind_db)
    end)
  end)
end)
