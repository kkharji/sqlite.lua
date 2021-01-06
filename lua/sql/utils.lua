local M = {}

M.is_str = function(s) return type(s) == "string" end
M.is_tbl = function(t) return type(t) == "table" end
M.is_boolean = function(t) return type(t) == "boolean" end
M.is_userdata = function(t) return type(t) == "userdata" end
M.is_nested = function(t) return type(t[1]) == "table" end
-- I'm sure there is a better way.


M.expand = function(path)
  local expanded
  if string.find(path, "~") then
    expanded = string.gsub(path, "^~", os.getenv("HOME"))
  elseif string.find(path, "^%.") then
    expanded = vim.loop.fs_realpath(path)
    if expanded == nil then
     expanded = vim.fn.fnamemodify(path, ":p")
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

  return expanded and expanded or error("Path not valid")
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
  for k in pairs(t) do r[#r+1] = k end
  return r
end

M.values = function(t)
  local r = {}
  for _, v in pairs(t) do r[#r+1] = v end
  return r
end

M.map = function(t, f)
  local _t = {}
  for i,value in pairs(t) do
    local k, kv, v = i, f(value, i)
    _t[v and kv or k] = v or kv
  end
  return _t
end

M.join = function(l,s)
  return table.concat(M.map(l, tostring), s, 1)
end

do
  local run_behavior = setmetatable({
    ['error'] = function()
      error('Key already exists: ', k)
    end,
    ['keep'] = function() end,
    ['force'] = function(t, k, v)
      t[k] = v
    end
  }, {
    __index = function(_, k)
      error(k .. ' is not a valid behavior')
    end
  })

  M.tbl_extend = function(behavior, ...)
    local new_table = {}
    local tables = {...}
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
end

-- Flatten taken from: https://github.com/premake/premake-core/blob/master/src/base/table.lua
M.flatten = function(arr)
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

  flatten(arr)
  return result
end

M.keynames = function(params, placeholders)
  local keys = M.keys(params)
  local s = placeholders and ":" or ""
  local res = {}
  M.map(keys, function(k)
    res[#res+1] = s .. k
  end)
  return res
end

return M
