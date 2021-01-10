local parse = require'sql.parser'
describe('parse', function()
  it('select all', function()
    local method = "select"
    local tbl = "todo"
    local sqlstmt = parse(tbl, method)
    assert.are.same("select * from todo", sqlstmt, "It should be identical")
  end)
  it('select where single key = value', function()
    local method = "select"
    local tbl = "todo"
    local sqlstmt = parse(tbl, method, {
      where = { id = 1 }
    })
    assert.are.same("select * from todo where id = :id", sqlstmt, "It should be identical")
  end)
  it('select where multi key', function()
    local method = "select"
    local tbl = "todo"
    local sqlstmt = parse(tbl, method, {
      where = {
        id = 1,
        act = "done",
      }
    })
    assert.are.same("select * from todo where act = :act, id = :id", sqlstmt, "It should be identical")
  end)
end)
