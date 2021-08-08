local u = require "sql.utils"
local json = require "sql.json"

local M = {}

---@brief [[
---Internal functions for parsing sql statement from lua table.
---methods = { select, update, delete, insert, create, alter, drop }
---accepts tbl name and options.
---options = {join, keys, values, set, where, select}
---hopfully returning valid sql statement :D
---@brief ]]
---@tag parser.lua

---handle sqlite datatype interop
M.sqlvalue = function(v)
  if type(v) == "boolean" then
    return v == true and 1 or 0
  else
    return v == nil and "null" or v
  end
end

---string.format specifier based on value type
---@param v any: the value
---@param nonbind boolean: whether to return the specifier or just return the value.
---@return string
local specifier = function(v, nonbind)
  local type = type(v)
  if type == "number" then
    local _, b = math.modf(v)
    return b == 0 and "%d" or "%f"
  elseif type == "string" and not nonbind then
    return v:find "'" and [["%s"]] or "'%s'"
  elseif nonbind then
    return v
  else
    return ""
  end
end

local bind = function(o)
  o = o or {}
  o.s = o.s or ", "
  if not o.kv then
    o.v = o.v ~= nil and M.sqlvalue(o.v) or "?"
    return string.format("%s = " .. specifier(o.v), o.k, o.v)
  else
    local res = {}
    for k, v in u.opairs(o.kv) do
      k = o.k ~= nil and o.k or k
      v = M.sqlvalue(v)
      v = o.nonbind and ":" .. k or v
      table.insert(res, string.format("%s" .. (o.nonbind and nil or " = ") .. specifier(v, o.nonbind), k, v))
    end
    return table.concat(res, o.s)
  end
end

---format glob pattern as part of where clause
local pcontains = function(defs)
  if not defs then
    return {}
  end
  local items = {}
  for k, v in u.opairs(defs) do
    if type(v) == "table" then
      table.insert(
        items,
        table.concat(
          u.map(v, function(_v)
            return string.format("%s glob " .. specifier(k), k, M.sqlvalue(_v))
          end),
          " or "
        )
      )
    else
      table.insert(items, string.format("%s glob " .. specifier(k), k, v))
    end
  end
  return table.concat(items, " ")
end

---Format values part of sql statement
---@params defs table: key/value pairs defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
local pkeys = function(defs, kv)
  if not defs then
    return {}
  end
  kv = kv == nil and true or kv
  if kv then
    local keys = {}
    defs = u.is_nested(defs) and defs[1] or defs
    for k, _ in pairs(defs) do
      table.insert(keys, k)
    end
    return string.format("(%s)", table.concat(keys, ", "))
  end
end

---Format values part of sql statement, usually used with select method.
---@params defs table: key/value pairs defining sqlite table keys.
---@params defs kv: whether to bind by named keys.
local pvalues = function(defs, kv)
  if not defs then
    return {}
  end
  kv = kv == nil and true or kv -- TODO: check if defs is key value pairs instead
  if kv then
    local keys = {}
    defs = u.is_nested(defs) and defs[1] or defs
    for k, _ in pairs(defs) do
      table.insert(keys, ":" .. k)
    end
    return string.format("values(%s)", table.concat(keys, ", "))
  end
end

---Format where part of a sql statement.
---@params defs table: key/value pairs defining sqlite table keys.
---@params name string: the name of the sqlite table
---@params join table: used as boolean, controling whether to use name.key or just key.
local pwhere = function(defs, name, join, contains)
  if not defs and not contains then
    return {}
  end
  local where = {}

  if defs then
    for k, v in u.opairs(defs) do
      k = join and name .. "." .. k or k
      if type(v) ~= "table" then
        table.insert(
          where,
          bind {
            v = v,
            k = k,
            s = " and ",
          }
        )
      else
        table.insert(where, "(" .. bind {
          kv = v,
          k = k,
          s = " or ",
        } .. ")")
      end
    end
  end

  if contains then
    table.insert(where, pcontains(contains))
  end

  return "where " .. table.concat(where, " and ")
end

local plimit = function(defs)
  if not defs then
    return {}
  end
  local type = type(defs)
  local limit

  if type == "number" then
    limit = "limit " .. defs
  elseif type == "table" and defs[2] then
    limit = string.format("limit %s offset %s", defs[1], defs[2])
  else
    limit = "limit " .. defs[1]
  end

  return limit
end

---Format set part of sql statement, usually used with update method.
---@params defs table: key/value pairs defining sqlite table keys.
local pset = function(defs)
  if not defs then
    return {}
  end
  return "set " .. bind { kv = defs, nonbind = true }
end

---Format join part of a sql statement.
---@params defs table: key/value pairs defining sqlite table keys.
---@params name string: the name of the sqlite table
local pjoin = function(defs, name)
  if not defs or not name then
    return {}
  end
  local target

  local on = (function()
    for k, v in pairs(defs) do
      if k ~= name then
        target = k
        return string.format("%s.%s =", k, v)
      end
    end
  end)()

  local select = (function()
    for k, v in pairs(defs) do
      if k == name then
        return string.format("%s.%s", k, v)
      end
    end
  end)()

  return string.format("inner join %s on %s %s", target, on, select)
end

local porder_by = function(defs)
  -- TODO: what if nulls? should append "nulls last"
  if not defs then
    return {}
  end
  local items = {}
  for v, k in u.opairs(defs) do
    if type(k) == "table" then
      for _, _k in u.opairs(k) do
        table.insert(items, string.format("%s %s", _k, v))
      end
    else
      table.insert(items, string.format("%s %s", k, v))
    end
  end

  return string.format("order by %s", table.concat(items, ", "))
end

local partial = function(method, tbl, opts)
  opts = opts or {}
  return table.concat(
    u.flatten {
      method,
      pkeys(opts.values),
      pvalues(opts.values, opts.named),
      pset(opts.set),
      pwhere(opts.where, tbl, opts.join, opts.contains),
      porder_by(opts.order_by),
      plimit(opts.limit),
    },
    " "
  )
end

---Parse select statement to extracts data from a database
---@param tbl string: table name
---@param opts table: lists of options: valid{ select, join, order_by, limit, where }
---@return string: the select sql statement.
M.select = function(tbl, opts)
  opts = opts or {}
  local cmd = opts.unique and "select distinct %s" or "select %s"
  local select
  if u.is_tbl(opts.select) then
    select = table.concat(opts.select, ", ")
  elseif type(opts.select) == "string" then
    select = opts.select
  else
    select = "*"
  end
  local stmt = string.format(cmd .. " from %s", select, tbl)
  local method = opts.join and stmt .. " " .. pjoin(opts.join, tbl) or stmt
  return partial(method, tbl, opts)
end

---Parse select statement to update data in the database
---@param tbl string: table name
---@param opts table: lists of options: valid{ set, where }
---@return string: the update sql statement.
M.update = function(tbl, opts)
  local method = string.format("update %s", tbl)
  return partial(method, tbl, opts)
end

---Parse insert statement to insert data into a database
---@param tbl string: table name
---@param opts table: lists of options: valid{ where }
---@return string: the insert sql statement.
M.insert = function(tbl, opts)
  local method = string.format("insert into %s", tbl)
  return partial(method, tbl, opts)
end

---Parse delete statement to deletes data from a database
---@param tbl string: table name
---@param opts table: lists of options: valid{ where }
---@return string: the delete sql statement.
M.delete = function(tbl, opts)
  opts = opts or {}
  local method = string.format("delete from %s", tbl)
  local where = pwhere(opts.where)
  return type(where) == "string" and method .. " " .. where or method
end

---Parse table create statement
---@param tbl string: table name
---@param defs table: keys and type pairs
---@return string: the create sql statement.
M.create = function(tbl, defs)
  if not defs then
    return
  end
  local items = {}

  tbl = defs.ensure and "if not exists " .. tbl or tbl
  defs.ensure = nil

  for k, v in u.opairs(defs) do
    if type(v) == "boolean" then
      table.insert(items, string.format("%s integer primary key", k))
    elseif type(v) ~= "table" then
      table.insert(items, string.format("%s %s", k, v))
    else
      table.insert(items, string.format("%s %s", k, table.concat(v, " ")))
    end
  end

  return string.format("create table %s(%s)", tbl, table.concat(items, ", "))
end

---Parse table drop statement
---@param tbl string: table name
---@return string: the drop sql statement.
M.drop = function(tbl)
  return string.format("drop table %s", tbl)
end

---Preporcess data insert to sql db.
---for now it's mainly used to for parsing lua tables and boolean values.
---It throws when a schema key is required and doesn't exists.
---@param rows table inserted row.
---@param schema table tbl schema with extra info
---@return table pre processed rows
M.pre_insert = function(rows, schema)
  rows = u.is_nested(rows) and rows or { rows }

  for _, row in ipairs(rows) do
    for k, _ in pairs(schema.req) do
      if not row[k] then
        error("sql.nvim: (insert) missing a required key: " .. k)
      end
    end

    for k, v in pairs(row) do
      if schema.types[k] == "luatable" or schema.types[k] == "json" then
        row[k] = json.encode(v)
      end

      if type(v) == "boolean" then
        row[k] = v == true and 1 or 0
      end
    end
  end

  return rows
end

---Postprocess data queried from a sql db. for now it is mainly used
---to for parsing json values to lua table.
---@param rows table inserted row.
---@param schema table tbl schema
---@return table pre processed rows
---@TODO support boolean values.
M.post_select = function(rows, types)
  local is_nested = u.is_nested(rows)
  rows = is_nested and rows or { rows }
  for _, row in ipairs(rows) do
    for k, v in pairs(row) do
      if types[k] == "luatable" or types[k] == "json" then
        row[k] = json.decode(v)
      end
    end
  end
  return is_nested and rows or rows[1]
end

return M
