local u = require "sql.utils"
local luv = require "luv"

local Cache = {}

Cache.__index = Cache

local parse_query = (function()
  local concat = function(v)
    if not u.is_list(v) and type(v) ~= "string" then
      local tmp = {}
      for _k, _v in u.opairs(v) do
        if type(_v) == "table" then
          table.insert(tmp, string.format("%s=%s", _k, table.concat(_v, ",")))
        else
          table.insert(tmp, string.format("%s=%s", _k, _v))
        end
      end
      return table.concat(tmp, "")
    else
      return table.concat(v, "")
    end
  end

  return function(query)
    local items = {}
    for k, v in u.opairs(query) do
      if type(v) == "table" then
        table.insert(items, string.format("%s=%s", k, concat(v)))
      else
        table.insert(items, k .. "=" .. v)
      end
    end
    return table.concat(items, ",")
  end
end)()

-- assert(parse_query { where = { a = { 12, 99, 32 } } } == "where=a=12,99,32")
-- assert(parse_query { where = { a = 32 } } == "where=a=32")
-- print(vim.inspect(parse_query { keys = { "b", "c" }, where = { a = 1 } }))
-- "keys=bc,select=bc,where=a=1"
---Insert to cache using query definition.
---@param query table
---@param result table
function Cache:insert(query, result)
  self.store[parse_query(query)] = result
end

---Clear cache when succ is true, else skip.
function Cache:clear(succ)
  if succ then
    self.store = {}
    self.db.modified = false
  end
end

function Cache:is_empty()
  return next(self.store) == nil
end

---Get results from cache.
---@param query sqlite_query_select
---@return table
function Cache:get(query)
  local stat = luv.fs_stat(self.db.uri)
  local mtime = stat and stat.mtime.sec

  if self.db.modified or mtime ~= self.mtime then
    self:clear(true)
    return
  end

  return self.store[parse_query(query)]
end

setmetatable(Cache, {
  __call = function(self, db)
    return setmetatable({ db = db, store = {} }, self)
  end,
})

return Cache
