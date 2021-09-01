local docgen = require "docgen"

local function gen()
  local input_files = {
    "./lua/sqlite/init.lua",
    "./lua/sqlite/db.lua",
    "./lua/sqlite/tbl.lua",
  }

  local output_file = "./doc/sqlite.txt"
  local output_file_handle = io.open(output_file, "w")

  for _, input_file in ipairs(input_files) do
    docgen.write(input_file, output_file_handle)
  end

  output_file_handle:write " vim:tw=78:sw=2:ts=2:ft=help:norl:et:listchars=\n"
  output_file_handle:close()
  vim.cmd [[checktime]]
end

gen()
