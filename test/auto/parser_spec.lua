local p = require'sql.parser'
local eq = assert.are.same

describe('parse', function()
  local tbl = "todo"

  describe('[all]', function()
    it('select all', function()
      local sqlstmt = p.select(tbl)
      eq("select * from todo", sqlstmt, "It should be identical")
    end)
    it('delete all', function()
      local sqlstmt = p.delete(tbl)
      eq("delete from todo", sqlstmt, "It should be identical")
    end)
  end)

  describe('[where]', function()
    it('single key = value', function()
      local where = { id = 1 }
      local pselect = p.select(tbl, { where = where })
      local eselect = "select * from todo where id = 1"
      eq(eselect, pselect, "It should be identical")
    end)
    it('multi key', function()
      local where = { id = 1, act = "done" }
      local pselect = p.select(tbl, { where = where })
      local eselect = "select * from todo where act = 'done' and id = 1"
      eq(eselect, pselect, "It should be identical")
    end)
    it('with [or] for single keys', function()
      local where = { act = {"done", "overdue"} }
      local pselect = p.select(tbl, { where = where })
      local eselect = "select * from todo where (act = 'done' or act = 'overdue')"
      eq(eselect, pselect, "It should be identical")
    end)
    it('with [or] for multi keys', function()
      local where = {
        act = {"done", "overdue"},
        name = "conni",
        date = 2021
      }
      local pselect = p.select(tbl, { where = where })
      local eselect = "select * from todo where date = 2021 and name = 'conni' and (act = 'done' or act = 'overdue')"
      eq(eselect, pselect, "It should be identical")
    end)
    it('with multi [or] and multi keys', function()
      local where = {
        n = {1,2,3},
        act = {"a", "b"},
        date = 2021
      }
      local pselect = p.select(tbl, { where = where })
      local eselect = "select * from todo where date = 2021 and (n = 1 or n = 2 or n = 3) and (act = 'a' or act = 'b')"
      eq(eselect, pselect , "It should be identical")
    end)
    it('interop boolean', function()
      local where = {
        act = false,
        n = true,
        date = 2021
      }
      local eselect = "select * from todo where date = 2021 and act = 0 and n = 1"
      local pselect = p.select(tbl, { where = where })
      eq(eselect, pselect , "It should be identical")
    end)
    it('handles quotes', function()
      local where = { a = "I'm", c = "it's"  }
      local eselect = [[select * from todo where a = "I'm" and c = "it's"]]
      local pselect = p.select(tbl, { where = where })
      eq(eselect, pselect , "It should be identical")
    end)
  end)

  describe('[set]', function()
    it('single value and [where]', function()
      local set = { date = 2021 }
      local where = { id = 1 }
      local pupdate = p.update(tbl, { where = where, set = set})
      local eupdate = "update todo set date = 2021 where id = 1"
      eq(eupdate, pupdate, "should be identical")
    end)
    it('multiple value and where', function()
      local set = { date = 2021, a = "b", c = "d"  }
      local where = { id = 1 }
      local pupdate = p.update(tbl, { where = where, set = set})
      local eupdate = "update todo set date = 2021, a = 'b', c = 'd' where id = 1"
      eq(eupdate, pupdate, "should be identical")
    end)
    it('interop boolean', function()
      local set = { date = 2021, a = false, c = true  }
      local where = { id = 1 }
      local pupdate = p.update(tbl, { where = where, set = set})
      local eupdate = "update todo set date = 2021, a = 0, c = 1 where id = 1"
      eq(eupdate, pupdate, "should be identical")
    end)
    it('handles quotes ', function()
      local set = { a = "I'm", c = "it's"  }
      local where = { id = 1 }
      local pupdate = p.update(tbl, { where = where, set = set})
      local eupdate = [[update todo set a = "I'm", c = "it's" where id = 1]]
      eq(eupdate, pupdate, "should be identical")
    end)
  end)
  describe('create', function()
    it('table', function()
      local defs = {
          id = {"integer", "primary", "key"},
          title = "text",
          desc = "text",
          created = "int",
          done = {"int", "not", "null", "default", 0},
        }
      local expected = "create table todos(desc text, title text, id integer primary key, done int not null default 0, created int)"
      local passed = p.create("todos", defs)
      eq(expected, passed, "should be identical")
    end)
    it('ensure that the table is created', function()
      local defs = {
        id = {"integer", "primary", "key"},
        name = "text",
        age = "int",
        ensure = true,
      }
      local expected = "create table if not exists people(age int, name text, id integer primary key)"
      local passed = p.create("people", defs)
      eq(expected, passed, "should be identical")
    end)
  end)
end)
