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
      local eselect = "select * from todo where (act = 'done' or act = 'overdue') and date = 2021 and name = 'conni'"
      eq(eselect, pselect, "It should be identical")
    end)
    it('with multi [or] and multi keys', function()
      local where = {
        n = {1,2,3},
        act = {"a", "b"},
        date = 2021
      }
      local pselect = p.select(tbl, { where = where })
      local eselect = "select * from todo where (act = 'a' or act = 'b') and date = 2021 and (n = 1 or n = 2 or n = 3)"
      eq(eselect, pselect , "It should be identical")
    end)
    it('interop boolean', function()
      local where = {
        act = false,
        n = true,
        date = 2021
      }
      local eselect = "select * from todo where act = 0 and date = 2021 and n = 1"
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
      local eupdate = "update todo set date = :date where id = 1"
      eq(eupdate, pupdate, "should be identical")
    end)
    it('multiple value and where', function()
      local set = { date = 2021, a = "b", c = "d"  }
      local where = { id = 1 }
      local pupdate = p.update(tbl, { where = where, set = set})
      local eupdate = "update todo set a = :a, c = :c, date = :date where id = 1"
      eq(eupdate, pupdate, "should be identical")
    end)
  end)

  describe('[create]', function()
    it('table', function()
      local defs = {
        id = {"integer", "primary", "key"},
        title = "text",
        desc = "text",
        created = "int",
        done = {"int", "not", "null", "default", 0},
      }
      local expected = "create table todos(created int, desc text, done int not null default 0, id integer primary key, title text)"
      local passed = p.create("todos", defs)
      eq(expected, passed, "should be identical")
    end)
    it('ensure that the table is created', function()
      local defs = {
        id = {"integer", "primary", "key"},
        name = "text",
        age = "int",
        ensure = true
      }
      local expected = "create table if not exists people(age int, id integer primary key, name text)"
      local passed = p.create("people", defs)
      eq(expected, passed, "should be identical")
    end)
  end)

  describe('[order by]', function()
    it('works with signle table name', function()
      local defs = {
        select = { "id", "name" },
        order_by = {
          desc = "name",
          asc = "id"
        }
      }
      local expected = "select id, name from people order by id asc, name desc"
      local passed = p.select("people", defs)
      eq(expected, passed, "should be identical")
    end)
    it('works with multiple table name', function()
      local defs = {
        select = { "id", "name" },
        order_by = {
          asc = {"name", "age"}
        }
      }
      local expected = "select id, name from people order by name asc, age asc"
      local passed = p.select("people", defs)
      eq(expected, passed, "should be identical")
    end)
  end)
  describe('[distinct]', function()
    -- remove duplicate from result set
    it('with single key', function()
      local defs = { -- TODO: works for a single key
        select = { "id", "name" },
        unique = true
      }
      local expected = "select distinct id, name from people"
      local passed = p.select("people", defs)
      eq(expected, passed, "should be identical")
    end)
  end)
  describe('[limit]', function()
    it('with limit as number', function()
      local defs = {
        select = { "id", "name" },
        limit = 10
      }
      local expected = "select id, name from people limit 10"
      local passed = p.select("people", defs)
      eq(expected, passed, "should be identical")
    end)
    it('with limit as number inside list', function()
      local defs = {
        select = { "id", "name" },
        limit = {10}
      }
      local expected = "select id, name from people limit 10"
      local passed = p.select("people", defs)
      eq(expected, passed, "should be identical")
    end)
    it('with limit and offset', function()
      local defs = {
        select = { "id", "name" },
        limit = {10, 10}
      }
      local expected = "select id, name from people limit 10 offset 10"
      local passed = p.select("people", defs)
      eq(expected, passed, "should be identical")
    end)
  end)
end)
