local luv = require "luv"
local M = {}

M.if_nil = function(a, b)
  if a == nil then
    return b
  end
  return a
end

M.is_str = function(s)
  return type(s) == "string"
end

M.is_tbl = function(t)
  return type(t) == "table"
end

M.is_boolean = function(t)
  return type(t) == "boolean"
end

M.is_userdata = function(t)
  return type(t) == "userdata"
end

M.is_nested = function(t)
  return type(t[1]) == "table"
end

-- taken from: https://github.com/neovim/neovim/blob/master/runtime/lua/vim/shared.lua
M.is_list = function(t)
  if type(t) ~= "table" then
    return false
  end

  local count = 0

  for k, _ in pairs(t) do
    if type(k) == "number" then
      count = count + 1
    else
      return false
    end
  end

  if count > 0 then
    return true
  else
    return getmetatable(t) ~= {}
  end
end

M.opairs = (function()
  local __gen_order_index = function(t)
    local orderedIndex = {}
    for key in pairs(t) do
      table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex)
    return orderedIndex
  end

  local nextpair = function(t, state)
    local key
    if state == nil then
      -- the first time, generate the index
      t.__orderedIndex = __gen_order_index(t)
      key = t.__orderedIndex[1]
    else
      -- fetch the next value
      for i = 1, table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
          key = t.__orderedIndex[i + 1]
        end
      end
    end

    if key then
      return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
  end

  return function(t)
    return nextpair, t, nil
  end
end)()

M.expand = function(path)
  local expanded
  if string.find(path, "~") then
    expanded = string.gsub(path, "^~", os.getenv "HOME")
  elseif string.find(path, "^%.") then
    expanded = luv.fs_realpath(path)
    if expanded == nil then
      error "Path not vaild"
    end
  elseif string.find(path, "%$") then
    local rep = string.match(path, "([^%$][^/]*)")
    local val = os.getenv(string.upper(rep))
    if val then
      expanded = string.gsub(string.gsub(path, rep, val), "%$", "")
    else
      expanded = nil
    end
  else
    expanded = path
  end

  return expanded and expanded or error "Path not valid"
end

M.all = function(iterable, fn)
  for k, v in pairs(iterable) do
    if not fn(k, v) then
      return false
    end
  end

  return true
end

M.keys = function(t)
  local r = {}
  for k in pairs(t) do
    r[#r + 1] = k
  end
  return r
end

M.values = function(t)
  local r = {}
  for _, v in pairs(t) do
    r[#r + 1] = v
  end
  return r
end

M.map = function(t, f)
  local _t = {}
  for i, value in pairs(t) do
    local k, kv, v = i, f(value, i)
    _t[v and kv or k] = v or kv
  end
  return _t
end

M.mapv = function(t, f)
  local _t = {}
  for i, value in M.opairs(t) do
    local _, kv, v = i, f(value, i)
    table.insert(_t, v or kv)
  end
  return _t
end

M.join = function(l, s)
  return table.concat(M.map(l, tostring), s, 1)
end

M.tbl_extend = (function()
  local run_behavior = setmetatable({
    ["error"] = function(_, k, _)
      error("Key already exists: ", k)
    end,
    ["keep"] = function() end,
    ["force"] = function(t, k, v)
      t[k] = v
    end,
  }, {
    __index = function(_, k)
      error(k .. " is not a valid behavior")
    end,
  })

  return function(behavior, ...)
    local new_table = {}
    local tables = { ... }
    for i = 1, #tables do
      local b = tables[i]
      for k, v in pairs(b) do
        if v then
          if new_table[k] then
            run_behavior[behavior](new_table, k, v)
          else
            new_table[k] = v
          end
        end
      end
    end
    return new_table
  end
end)()

-- Flatten taken from: https://github.com/premake/premake-core/blob/master/src/base/table.lua
M.flatten = function(tbl)
  local result = {}
  local function flatten(arr)
    local n = #arr
    for i = 1, n do
      local v = arr[i]
      if type(v) == "table" then
        flatten(v)
      elseif v then
        table.insert(result, v)
      end
    end
  end
  flatten(tbl)

  return result
end

---Generate query key for a given query table
---@param query any
---@see table.lua
---@return string
M.query_key = function(query)
  local items = {}
  for k, v in M.opairs(query) do
    if type(v) == "table" then
      table.insert(
        items,
        string.format(
          "%s=%s",
          k,
          table.concat(
            (function()
              if not M.is_list(v) and type(v) ~= "string" then
                local tmp = {}
                for _k, _v in M.opairs(v) do
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
            end)(),
            ""
          )
        )
      )
    else
      table.insert(items, k .. "=" .. v)
    end
  end

  return table.concat(items, ",")
end

return M
