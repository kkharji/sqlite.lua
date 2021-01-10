local parse = require'sql.parser'
local eq = assert.are.same
describe('parse', function()
  local tbl = "todo"

  describe('[all]', function()
    it('select all', function()
      local sqlstmt = parse(tbl, "select")
      eq("select * from todo", sqlstmt, "It should be identical")
    end)
  end)

  describe('[where]', function()
    local getstmt = function(m, where)
      return parse(tbl, m, { where = where })
    end

    it('single key = value', function()
      local where = { id = 1 }
      local pselect = getstmt("select", where)
      local eselect = "select * from todo where id = 1"
      eq(eselect, pselect, "It should be identical")
    end)

    it('multi key', function()
      local where = { id = 1, act = "done" }
      local pselect = getstmt("select", where)
      local eselect = "select * from todo where act = 'done' and id = 1"
      eq(eselect, pselect, "It should be identical")
    end)

    it('with [or] for single keys', function()
      local where = { act = {"done", "overdue"} }
      local pselect = getstmt("select", where)
      local eselect = "select * from todo where (act = 'done' or act = 'overdue')"
      eq(eselect, pselect, "It should be identical")
    end)

    it('with [or] for multi keys', function()
      local where = {
        act = {"done", "overdue"},
        name = "conni",
        date = 2021
      }
      local pselect = getstmt("select", where)
      local eselect = "select * from todo where date = 2021 and name = 'conni' and (act = 'done' or act = 'overdue')"
      eq(eselect, pselect, "It should be identical")
    end)

    it('with multi [or] and multi keys', function()
      local where = {
        n = {1,2,3},
        act = {"a", "b"},
        date = 2021
      }
      local eselect = "select * from todo where date = 2021 and (n = 1 or n = 2 or n = 3) and (act = 'a' or act = 'b')"
      local pselect = getstmt("select", where)
      eq(eselect, pselect , "It should be identical")
    end)

    it('take care of boolean interop', function()
      local where = {
        act = false,
        n = true,
        date = 2021
      }
      local eselect = "select * from todo where date = 2021 and act = 0 and n = 1"
      local pselect = getstmt("select", where)
      eq(eselect, pselect , "It should be identical")
    end)

  end)

  describe('set', function()
    local getstmt = function(m, set, where)
      return parse(tbl, m, { set = set, where = where })
    end

    it('with single value and where', function()
      local set = { date = 2021 }
      local where = { id = 1 }
      local pupdate = getstmt("update", set, where)
      local eupdate = "update todo set date = 2021 where id = 1"
      eq(eupdate, pupdate, "should be identical")
    end)

  end)

end)
