local bunch = require'plenary.benchmark'
R('sqlite')
local sqlite = require('sqlite')
local remove_db = function ()
  vim.loop.fs_unlink("/tmp/uri")
end

bunch("Logical Component vs Full initialization", {
  runs = 20,
  fun = {
    {
      "Logical Component",
      function ()
        ---@class __ManagerA:sqlite_db
        ---@field projects sqlite_tbl
        ---@field todos sqlite_tbl
        local db = sqlite {
          uri = "/tmp/uri",
          projects = {
            id = true,
            title = "text",
            objectives = "luatable",
          },
          todos = {
            id = true,
            title = "text",
            client = "integer",
            status = "text",
            completed = "boolean",
            details = "text",
          },
          clients = { name = "text" },
          opts = {
            foreign_keys = true,
          },
          lazy = true
        }
        remove_db()
      end
    },
    {
      "Full Initialization",
      function ()
        ---@class __ManagerB:sqlite_db
        ---@field projects sqlite_tbl
        ---@field todos sqlite_tbl
        local db = sqlite {
          uri = "/tmp/uri",
          projects = {
            id = true,
            title = "text",
            objectives = "luatable",
          },
          todos = {
            id = true,
            title = "text",
            client = "integer",
            status = "text",
            completed = "boolean",
            details = "text",
          },
          clients = { name = "text" },
          opts = {
            foreign_keys = true,
          },
        }
        remove_db()
      end
    }
  }
})
