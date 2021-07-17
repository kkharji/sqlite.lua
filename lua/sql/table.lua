local u = require'sql.utils'
local luv = require'luv'

local t = {}
t.__index = t

function t:__ensure_table()
  if not self.db:exists(self.name) and self.__schema then
    return self.db:create(self.name, self.__schema)
  end
end

function t:__run(func)
  if self.db.closed then
    return self.db:with_open(function()
      self:__ensure_table()
      return func() -- shoud pass tbl name?
    end)
  else
    self:__ensure_table()
    return func()
  end
end

local get_key = function(query) -- TODO: refactor / move to utils
  local items = {}
  for k, v in u.opairs(query) do
    if type(v) == "table" then
      table.insert(items, string.format("%s=%s", k, table.concat((function()
        if not u.is_list(v) and type(v) ~= "string" then
          local tmp = {}
          for _k,_v in u.opairs(v) do
            if type(_v) == "table" then
              table.insert(tmp, string.format("%s=%s", _k, table.concat(_v, ",")))
            else
              table.insert(tmp, string.format("%s=%s", _k, _v))
            end
          end
          return tmp
        else
          return v
        end
      end)(), "")))
    else
      table.insert(items, k .. "=" .. v)
    end
  end
  return table.concat(items, ",")
end


function t:__clear_cache(succ, change)
  -- TODO: maybe do something smart here to update cache :D
  if succ then
    self.cache = {}
    self.db.modified = false
  end
end

function t:__fill_cache(query, res)
  self.cache[get_key(query)] = res
end

function t:__get_from_cache(query)
  if self.nocache then return end
  local stat = luv.fs_stat(self.db.uri)
  local mtime = stat and stat.mtime.sec

  if self.db.modified or mtime ~= self.mtime then
    self.__clear_cache(true, nil)
    self.db.modified = false
    return nil
  end
  return self.cache[get_key(query)]
end


function t:new(db, name, opts)
  opts = opts or {}
  local o = {}
  o.cache = {}
  o.db = db
  o.name = name
  o.mtime = luv.fs_stat(o.db.uri)
  o.mtime = o.mtime and o.mtime.mtime.sec
  o.__schema = opts.schema
  o.nocache = opts.nocache
  -- db:close/open changes this value, not sql:change commands

  setmetatable(o, self)

  o:__run(function()
    if o.__schema then
      o.__schema.ensure = true
      o.db:create(o.name, o.__schema)
    end
    o.tbl_exists = o.db:exists(o.name)
    o.has_content = o.tbl_exists and o:count() ~= 0 or false
  end)
  return o
end

--- Create or change {self.name} schema. If no {schema} is given,
--- then it return current the used schema.
---@param schema table: table schema definition
---@return table: list of keys or keys and their type.
function t:schema(schema)
  local res
  return self:__run(function()
    local exists = self.db:exists(self.name)

    if not schema then -- TODO: or table is empty
      if exists then
        self.__schema = self.db:schema(self.name)
        return self.__schema
      else
        return {}
      end

    -- if not schema then -- TODO: or table is empty
    --   return exists and self.db:schema(self.name) or {}
    elseif not exists or schema.ensure then
      res = self.db:create(self.name, schema)
      self.tbl_exists = res
      return res
    elseif not schema.ensure then -- maybe better to use alter
      res = exists and self.db:drop(self.name) or true
      res = res and self.db:create(self.name, schema) or false
      self._schema = self.db:schema(self.name)
      return res
    end
  end)
end

--- Same functionalities as |sql:drop()|, if the table is already drooped
--- then it returns false
---@return boolean
function t:drop()
  return self:__run(function()
    if not self.db:exists(self.name) then return false end

    local res = self.db:drop(self.name)
    if res then
      self.tbl_exists = false
      self.__schema = nil
    end
    return res
  end)
end


--- Predicate that returns true if the table is empty
---@return boolean
function t:empty()
  return self:exists() and self:count() == 0 or false
end

--- Predicate that returns true if the table exists
---@return boolean
function t:exists()
  return self:__run(function() return self.db:exists(self.name) end)
end

--- The count of the rows in {self.name}.
---@return number: number of rows in {self.name}
function t:count()
  return self:__run(function()
    if not self.db:exists(self.name) then return 0 end
    local res = self.db:eval("select count(*) from " .. self.name)
    return res[1]["count(*)"]
  end)
end


--- Query the table and return results. If the {query} has been ran before, then
--- query results from cache will be returned.
---@param query table: query.where, query.keys, query.join
---@return table: empty table if no result
---@see sql:select()
function t:get(query)
  query = query or { query = {all = 1} }
  local cache = self:__get_from_cache(query)
  if cache then return cache end

  return self:__run(function()
    local res = self.db:select(self.name, query)
    if res and not self.nocache then self:__fill_cache(query, res) end
    return res
  end)
end

--- get first match from a table based on keys
--- query results from cache will be returned.
---@param where table: where key values
---@return nil or row
---@usage: t:where{id = 1}
---@see sql:select()
function t:where(where)
  if not where then return end
  return self:get({ where = where  })[1]
end

--- Iterate over {self.name} rows and execute {func}.
---@param query table: query.where, query.keys, query.join
---@param func function: a function that expects a row
---@return boolean: true if rows ~= empty table
function t:each(query, func)
  assert(type(func) == "function", "required a function as second params")
  local cache = self:__get_from_cache(query)
  local rows = cache and cache or (function()
    local res = self.db:select(self.name, query)
    if res and not self.nocache then self:__fill_cache(query, res) end
    return res
  end)()
  if not rows then return end
  for _, row in ipairs(rows) do
    func(row)
  end
  return rows ~= {} or type(rows) ~= "boolean"
end

--- create a new table from iterating over {self.name} rows with {func}.
---@param query table: query.where, query.keys, query.join
---@param func function: a function that expects a row
---@return boolean: true if rows ~= empty table
function t:map(query, func)
  assert(type(func) == "function", "required a function as second params")
  local res = {}
  self:each(query, function(row)
      table.insert(res, func(row))
  end)
  return res
end

--- Sorts a table in-place using a transform. Values are ranked in a custom order of the results of
--- running `transform (v)` on all values. `transform` may also be a string name property  sort by.
--- `comp` is a comparison function. Adopted from Moses.lua
---@param query table: query.where, query.keys, query.join
---@param transform function or string: a `transform` function to sort elements. Defaults to @{identity}
---@param comp function: a comparison function, defaults to the `<` operator
---@return table: list of sorted values
function t:sort(query, transform, comp)
  local res = self:get(query)
  local f = transform or function(r) return r[u.keys(query.where)[1]] end
  if (type(transform) == 'string') then
    f = function(r) return r[transform] end
  end
  comp = comp or function(a,b) return a < b end
  table.sort(res, function(a,b) return comp(f(a), f(b)) end)
  return res
end

--- Same functionalities as |sql:insert()|
---@param rows table: a row or a group of rows
---@see t:__run()
---@see sql:insert()
---@return boolean, integer
function t:insert(rows)
  return self:__run(function()
    local succ, last_rowid = self.db:insert(self.name, rows)
    self:__clear_cache(succ, rows)
    if succ then
      self.has_content = self:count() ~= 0 or false
    end
    return succ, last_rowid
  end)
end

--- Same functionalities as |sql:delete()|
---@param specs table: specs.where
---@see t:__run()
---@see sql:delete()
---@return boolean
function t:remove(specs)
  return self:__run(function()
    local succ = self.db:delete(self.name, specs)
    self:__clear_cache(succ, specs)
    return succ
  end)
end

--- Same functionalities as |sql:update()|
---@param specs table: a table or a list of tables with where and values keys.
---@see t:__run()
---@see sql:update()
---@return boolean
function t:update(specs)
  return self:__run(function()
    local succ = self.db:update(self.name, specs)
    self:__clear_cache(succ, specs)
    return succ
  end)
end

--- Same functionalities as |t:add()|, but replaces {self.name} content with {rows}
---@param rows table: a row or a group of rows
---@see t:__run()
---@see sql:delete()
---@see sql:insert()
---@return boolean
function t:replace(rows)
  return self:__run(function()
    self.db:delete(self.name)
    local succ = self.db:insert(self.name, rows)
    self:__clear_cache(succ, rows)
    return succ
  end)
end

return t
