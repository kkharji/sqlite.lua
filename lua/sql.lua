local sql = {}

sql.errmsg = function(conn)
--- sql.errmsg
-- prints last error msg.
-- @param conn the database connection
-- @usage `conn:errmsg()`
-- @return nil
end

sql.connect = function(url)
--- sql.connect
-- Establishes connection to `url` and return sqlite3 object.
--   If no url is given then it should default to ":memory:".
--   Return `conn` only when the sql code == 0
-- @param url string optional
-- @usage `sql.connect()`
-- @usage `sql.connect("./path/to/db.sqlite")`
-- @usage `sql.connect("$ENV_VARABLE")`
-- @return C struct
end

sql.close = function(conn)
--- sql.close
-- closes sqlite connection
-- else error-out with sqlite3 msg.
-- @param conn the database connection
-- @usage `conn:close()`
-- @return boolean
end

sql.exec = function(conn, statm, params)
--- sql.exec
-- execute sql statement and returns true if successful else error-out with sqlite3 msg.
--  It should append `;` to `statm`
-- @param conn the database connection
-- @param statm (string/array)
-- @usage `conn:exec("drop table if exists todos")`
-- @usage `conn:exec("create table todos")`
-- @return boolean
-- @raise error with sqlite3 msg
end


sql.query = function(conn, statm, params)
--- sql.query
-- Execute a query against sqlite `conn`.
--  It should append `;` to `statm`
-- @param `conn` the database connection.
-- @param `statm` the sql query statement (string).
-- @param `params` lua table.
-- @usage `conn:query("select * from post where body = :body", {body = "body 2"})`
-- @usage `conn:query("select * from todos where id = :id" {id = 1})`
-- @return table
end


sql.insert = function(conn, tbl_name, params)
--- sql.insert
-- Inserts data to a sql_table..
--- It should append `;` to `statm`
--- It should handle arrays as well as tables.
-- @param `conn` the database connection.
-- @param `tbl_name` the sqlite table name.
-- @param `params` lua table or array.
-- @usage
-- conn:insert("todos", {
--     title = "create something",
--     desc = "something that users can be build upon.",
--     created = os.time()
-- })
-- @return the primary_key/true? or error.
end

sql.update = function(conn, tbl_name, id, params)
--- sql.update
-- same as insert but, mutates the sql_table with the new changes
--- It should append `;` to `statm`
--- It should handle arrays as well as tables.
-- @param `conn` the database connection.
-- @param `tbl_name` the sqlite table name.
-- @param `id` sqlite row id
-- @param `params` lua table or array.
-- @usage
-- conn:update("todos", 1, {
--   title = "create sqlite3 bindings",
--   desc = "neovim users can be build upon new interesting utils.",
-- }) --> true or error.
-- @return the primary_key/true? or error.
end

sql.delete = function(conn, id)
--- sql.delete
-- same as insert but, mutates the sql_table with the new changes
--- It should append `;` to `statm`
--- It should handle arrays as well as tables.
-- @param `conn` the database connection.
-- @param `id` sqlite row id
-- @usage `conn:delete("todos", 1)`
-- @return true or error.
end

sql.find = function(conn, params, opts)
--- sql.find
-- If a number (primary_key) is passed then returns the row that match that
-- primary key,
-- else if a table is passed,
--   - {project = 4, todo = 1} then return only the todo row for project with id 4,
--   - {project = 4, "todo"} then return all the todo row for project with id 4
--     `opts` is for the last use case, eg. {limit = 10, order = "todo.id desc"}
-- @param `conn` the database connection.
-- @param `params` string or table or array.
-- @param `opts` table of basic sqlite opts
-- @usage `conn:find("todos", 1)`
-- @usage `conn:find({project = 1, todo = 1})`
-- @usage `conn:find({project = 1, "todo" })`
-- @usage `conn:find("project", {order "id"})`
-- @return lua array
-- @see sql.query
end


return sql
