local sqlite = require('sqlite.db')
local stmt = require('sqlite.stmt')
local clib = require('sqlite.defs')
local ffi = require('ffi')
local sqlite3_transient = ffi.cast("void*",-1)

local db = sqlite:open()
local blob = string.dump(function ()
  print("hi")
  return 1
end)

db:create("b", { name = "text", chunk = "blob", size = 'integer' })

local function insert(name, blob)
  local stmt = stmt:parse(db.conn, "insert into b (name, chunk, size) values(?, ?, ?)")
  -- self.stmt, n, value, len or #value, sqlite3_transient
  clib.bind_text(stmt.pstmt, 1, name, #name + 1, nil)
  clib.bind_blob(stmt.pstmt, 2, blob, #blob + 1, sqlite3_transient)
  clib.bind_double(stmt.pstmt, 3, #blob)
  stmt:step()
  stmt:bind_clear()
  stmt:finalize()
end

insert("print_hello", blob)

local function get(name)
  local ret = {}
  local stmt = stmt:parse(db.conn, "select * from b where name = ?")
  clib.bind_text(stmt.pstmt, 1, name, #name + 1, nil)
  stmt:step()

  for i = 0, stmt:nkeys() - 1 do
    ret[stmt:key(i)] = stmt:val(i)
  end

  ret.chunk = clib.to_str(ret.chunk, ret.size)

  stmt:reset()
  stmt:finalize()

  return ret
end

ins({
  db = get("print_hello").chunk,
  fi = blob
})
loadstring(get("print_hello").chunk)()
-- db:eval("insert into b (name, chunk) values(?, ?)", {
--   'print_hello',
--   blob
-- })
-- local f = db:select("b")
-- print(vim.inspect(f))
--
--

-- describe("blob", function ()
--     it("using eval", function()
--       local db = sql:open()
--       db:create("b", { name = "text", chunk = "blob" })
--       db:eval("insert into b (name, chunk) values(?, ?)", {
--         'print_hello',
--         string.dump(function ()
--           print("hi")
--           return 1
--         end)
--       })
--       local f = db:select("b", { where = { name = "print_hello" }})
--       error(vim.inspect(f))
--       eq(1, loadstring(f[1].chunk)())

--     end)

--   end)
