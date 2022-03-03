---@brief [[
---
--- Web/File Bookmark Database.
--- Inspired by @sunjon implementation of https://entries.wikipedia.org/wiki/Frecency.
--- This file is meant to demonstrate what can be done with `sqlite.lua` with
--- a number of recommendations.
---
---@brief ]]

--- Require the module:
-------------------------

local sqlite = require "sqlite.db" --- for constructing sql databases
local tbl = require "sqlite.tbl" --- for constructing sql tables
local uri = "/tmp/bm_db_v1" -- defined here to be deleted later

--- sqlite builtin helper functions
local julianday, strftime = sqlite.lib.julianday, sqlite.lib.strftime

--- Define and iterate over tables rows/schema:
-------------------------------------------------
---This upfront investment would help you have clear idea, help other
---contribute, and provide you awesome auto-completions with the help of
---EmmyLua.

---@alias BMType '"web"' | '"file"' | '"dir"'

--[[ Datashapes ---------------------------------------------

---@class BMCollection
---@field title string: collection title

---@class BMEntry
---@field id number: unique id
---@field link string: file or web link.
---@field title string: the title of the bookmark.
---@field doc number: date of creation.
---@field type BMType
---@field count number: number of times it was clicked.
---@field collection string: foreign key referencing BMCollection.title.

---@class BMTimeStamp
---@field id number: unique id
---@field timestamp number
---@field entry number: foreign key referencing BMEntry

--]]

--[[ sqlite classes ------------------------------------------

---@class BMEntryTable: sqlite_tbl

---@class BMDatabase: sqlite_db
---@field entries BMEntryTable
---@field collection sqlite_tbl
---@field ts sqlite_tbl

--]]

--- 3. Construct
---------------------------

---@type BMEntryTable
local entries = tbl("entries", {
  id = true, -- same as { type = "integer", required = true, primary = true }
  link = { "text", required = true },
  title = "text",
  since = { "date", default = strftime("%s", "now") },
  count = { "number", default = 0 },
  type = { "text", required = true },
  collection = {
    type = "text",
    reference = "collection.title",
    on_update = "cascade", -- means when collection get updated update
    on_delete = "null", -- means when collection get deleted, set to null
  },
})

---@type BMDatabase
-- sqlite.lua db object will be injected to every table at evaluation.
-- Though no connection will be open until the first sqlite operation.
local BM = sqlite {
  uri = uri,
  entries = entries,
  collection = { -- Yes, tables can be inlined without requiring sql.table.
    title = {
      "text",
      required = true,
      unique = true,
      primary = true,
    },
  },
  ts = {
    _name = "timetamps", -- use this as table name not the field key.
    id = true,
    timestamp = { "real", default = julianday "now" },
    entry = {
      type = "integer",
      reference = "entries.id",
      on_delete = "cascade", --- when referenced entry is deleted, delete self
    },
  },
  -- custom sqlite3 options, if you really know what you want. + keep_open + lazy
  opts = {},
}

--- Doesn't need to annotated.
local collection, ts = BM.collection, BM.ts

--- 4. Start adding custom methods or override defaults to own it :D
--------------------------------------------------------------------

---Insert timestamp entry
---@param id number
function ts:insert(id)
  ts:__insert { entry = id }
end

---Get timestamp for entry.id or all
---@param id number|nil: BMEntry.id
---@return BMTimeStamp
function ts:get(id)
  return ts:__get { --- use "self.__get" as backup for overriding default methods.
    where = id and {
      entry = id,
    } or nil,
    select = {
      age = (strftime("%s", "now") - strftime("%s", "timestamp")) * 24 * 60,
      "id",
      "timestamp",
      "entry",
    },
  }
end

---Trim timestamps entries
---@param id number: BMEntry.id
function ts:trim(id)
  local rows = ts:get(id) -- calling t.get defined above
  local trim = rows[(#rows - 10) + 1]
  if trim then
    ts:remove { id = "<" .. trim.id, entry = id }
    return true
  end
  return false
end

---Update an entry values
---@param row BMEntry
function entries:edit(id, row)
  entries:update {
    where = { id = id },
    set = row,
  }
end

---Increment row count by id.
function entries:inc(id)
  local row = entries:where { id = id }
  entries:update {
    where = { id = id },
    set = { count = row.count + 1 },
  }
  ts:insert(id)
  ts:trim(id)
end

---Add a row
---@param row BMEntry
function entries:add(row)
  if row.collection and not collection:where { title = row.collection } then
    collection:insert { title = row.collection }
  end

  row.type = row.link:match "^%w+://" and "web" or (row.link:match ".-/.+(%..*)$" and "file" or "dir")

  local id = entries:insert(row)
  if not row.title and row.type == "web" then
    local ok, curl = pcall(require, "plenary.curl")
    if ok then
      curl.get { -- async function
        url = row.link,
        callback = function(res)
          if res.status ~= 200 then
            return
          end
          entries:update {
            where = { id = id },
            set = { title = res.body:match "title>(.-)<" },
          }
        end,
      }
    end
  end

  ts:insert(id)

  return id
end

local ages = {
  [1] = { age = 240, value = 100 }, -- past 4 hours
  [2] = { age = 1440, value = 80 }, -- past day
  [3] = { age = 4320, value = 60 }, -- past 3 days
  [4] = { age = 10080, value = 40 }, -- past week
  [5] = { age = 43200, value = 20 }, -- past month
  [6] = { age = 129600, value = 10 }, -- past 90 days
}

---Get all entries.
---@param q sqlite_query_select: a query to limit the number entries returned.
---@return BMEntry
function entries:get(q)
  local items = entries:map(function(entry)
    local recency_score = 0
    if not entry.count or entry.count == 0 then
      entry.score = 0
      return entry
    end

    for _, _ts in pairs(ts:get(entry.id)) do
      for _, rank in ipairs(ages) do
        if _ts.age <= rank.age then
          recency_score = recency_score + rank.value
          goto continue
        end
      end
      ::continue::
    end

    entry.score = entry.count * recency_score / 10
    return entry
  end, q)

  table.sort(items, function(a, b)
    return a.score > b.score
  end)

  return items
end

entries.demo = {
  { title = "My Pull Requests", link = "https://github.com/pulls", collection = "gh" },
  { title = "My Issues", link = "https://github.com/issues", collection = "gh" },
  { title = "System Configuration", link = "~/sys/config", collection = "config" },
  { title = "Neovim Configuration", link = "~/sys/cli/nvim", collection = "config" },
  { title = "Todos Inbox", link = "~/Org/refile.org", collection = "mang" },
  { link = "https://github.com", collection = "quick access" },
}

function entries:seed()
  ---Seed entries table
  for _, row in ipairs(entries.demo) do
    entries:add(row)
  end

  --- Act as if we've used on those entries
  for _ = 1, 5, 1 do
    entries:inc(4)
  end
  for _ = 1, 10, 1 do
    entries:inc(1)
  end
  for _ = 1, 3, 1 do
    entries:inc(3)
  end
end

if entries:count() == 0 then
  entries:seed()
end

---Edit an entry --- simple abstraction over entries.update { where = {id = 3}, set = { title = "none" } }
entries:edit(3, { title = "none" })

--- Get first match
assert(entries:where({ title = "none" }).id == 3)

--- Get all entries
vim.inspect(entries:get { where = { type = "web" } })

--- Delete all file or dir type bookmarks
assert(entries:remove { type = { "file", "dir" } })

--- Should be delete
assert(next(entries:get { where = { type = "file" } }) == nil)

vim.wait(500) -- BLOCK TO GET WEB TITLE FOR PLENERY.CURL

-- See all inputs
print(vim.inspect(entries:get()))

vim.defer_fn(function()
  vim.loop.fs_unlink(uri)
end, 40000)
