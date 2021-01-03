local sqlite = require'sql.defs'
local ffi = require'ffi'
local stmt = require'sql.stmt'
local eval = function(conn, stmt, callback, arg1, errmsg)
  return sqlite.exec(conn, stmt, callback, arg1, errmsg)
end
local conn = function(uri)
  uri = uri or ":memory:"
  local conn = ffi.new('sqlite3*[1]')
  local code = sqlite.open(uri, conn)
  if code == sqlite.flags.ok then
    return conn[0]
  else
    error(string.format(
    "sql.nvim: couldn't connect to sql database, ERR:",
    code))
  end
end

describe('stmt', function()
  local eq = assert.are.same
  local kill = function(s,db)
    if not s.finalized then
      eq(0, s:finalize())
    end
    eq(0, sqlite.close(db))
  end
  describe(':parse()', function()
    local db = conn()
    local stm = "select * from todos"

    eval(db, "create table todos(id integer primary key, title text, decs text, deadline integer);")
    local s = stmt:parse(db, stm)

    it('creates new statement object.',
    function()
      eq("table", type(s))
    end)
    it('registers db connection in `s.conn`.',
    function()
      eq("cdata", type(s.conn))
    end)
    it('registers unparsed statement in `s.str`.',
    function()
      eq(stm, s.str)
    end)
    it('parses sql statement in `s.pstmt`.',
    function()
      eq("cdata", type(s.pstmt))
    end)
    it('requires s:finalize() in order to close connection.',
    function()
      kill(s, db)
    end)
  end)

  local db,expectedlist,expectedkv,s
  db = conn()
  for _,v in pairs({
    [[create table todos(id integer primary key, title text, desc text, deadline integer);]],
    [[insert into todos (title,desc,deadline) values("Create something", "Don't you dare to tell conni", 2021);]],
    [[insert into todos (title,desc,deadline) values("Don't work on something else", 'keep conni close by :P', 2021);]]
  }) do eval(db, v) end

  expectedkv = {
    {
      id = 1,
      title = 'Create something',
      desc = "Don't you dare to tell conni",
      deadline = 2021,
    },
    {
      id = 2,
      title = "Don't work on something else",
      desc = 'keep conni close by :P',
      deadline = 2021,
    }}

  expectedlist = {}
  for i, t in ipairs(expectedkv) do
    list = {}
    expectedlist[i] = {}
    for _,v in pairs(t) do
      table.insert(expectedlist[i], v)
    end
  end

  s = stmt:parse(db, "select * from todos" )

  describe(':nkeys()', function()
    it('returns the number of columns/keys in results.',
    function()
      eq(4, s:nkeys())
    end)
  end)

  describe(':types()', function()
    it('returns the type of each columns/keys in results.',
    function()
      eq({ 'number', 'string', 'string', 'number', }, s:types())
    end)
  end)

  describe(':type() ', function()
    it('returns the type of columns/keys by idx.',
    function()
      eq("string", s:type(1))
    end)
  end)

  describe(':keys() ', function()
    it('returns key/column names',
    function()
      eq({ 'id', 'title', 'desc', 'deadline', }, s:keys())
    end)
  end)

  describe(':key()  ', function()
    it('returns key/column name by idx',
    function()
      eq("id", s:key(0))
    end)
  end)

  describe(':kt()   ', function()
    it('returns a dict of key name and their type.',
    function()
      eq({
        deadline = 'number',
        desc = 'string',
        id = 'number',
        title = 'string'
      }, s:kt())
    end)
  end)

  describe(':kv()   ', function()
    it('returns (with stmt:each) key-value pairs of all rows',
    function()
      local done = false
      local res = {}
      s:each(function(stmt)
        table.insert(res, stmt:kv())
        done = true
      end)
      vim.wait(4000, function() return done end)
      eq(true, not vim.tbl_isempty(res), "It should be filled.")
      eq(expectedkv, res, "It should be identical.")
    end)
  end)

  if s.finalized then
    s:__parse()
  end

  describe(':val()  ', function()
    it('returns (with stmt:each) a list of vals in all the rows at idx.',
    function()
      local res = {}
      s:each(function(stmt)
        table.insert(res, stmt:val(0))
      end)
      eq(false, vim.tbl_isempty(res))
      eq({ 1, 2 }, res)
    end)
  end)

  describe(':vals() ', function()
    it('returns (with stmt:each) a nested list all the vals in all the rows.',
    function()
      local res = {}
      s:each(function(stmt)
        table.insert(res, stmt:vals())
      end)
      eq(false, vim.tbl_isempty(res))
      -- eq(expectedlist, res) -- the order is missed up.
    end)
  end)

  describe(':kvrows()', function()
    it('returns a nested kv-pairs all the rows. if no callback.',
    function()
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

  describe(':vrows()', function()
    -- assert(s.finalized)
    it('returns a nested kv-pairs all the rows. if no callback.',
    function()
      local res = s:vrows()
      eq(true, not vim.tbl_isempty(res), "it should be filled.")
      -- eq(expectedlist, res, "it should be identical") -- the order is mixed up
    end)
  end)
    kill(s, db)
end)
