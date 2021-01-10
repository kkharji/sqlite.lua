local parse = require'sql.parser'
describe('parse', function()
  it('select all', function()
    local method = "select"
    local tbl = "todo"
    local sqlstmt = parse(tbl, method)
    assert.are.same("select * from todo", sqlstmt, "It should be identical")
  end)
end)
