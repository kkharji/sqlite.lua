
local ok, docgen = pcall(require, "docgen")
local ok, renderer = pcall(require, "docgen.renderer")

local md = {
  formatted = "",
}

md.hyperlink = {
  ["SQLite"] = "https://www.sqlite.org/index.html",
  ["LuaJIT"] = "https://luajit.org/",
  ["SQLite.lua"] = "https://github.com/tami5/sqlite.lua",
  ["ChangeLog"] = "https://github.com/tami5/sqlite.lua/blob/master/CHANGELOG.md",
  ["neovim"] = "https://github.com/neovim/neovim",
  ["luarocks"] = "https://luarocks.org",
}

md.filters = {}

md.filters.frhyperlinks = function(input)
  for k, v in pairs(md.hyperlink) do
    k:gsub("^" .. k .., k, n: number)
  end

end

local tests_text = [[
  SQLite/LuaJIT binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting SQLite databases. sql.nvim present new possibilities for plugin development and while it's primarily created for neovim, it support all luajit environments.
]]

print(vim.inspect(md.filters.frhyperlinks(tests_text)))

md.template = [[
# `SQLite.lua` 💫 <!-- sqlinfo section -->
%s <!-- sqlinfo description -->

%s <!-- everything else -->
]]

md.tag_heading = "# %s"

md.sort_classes = function(config, classes)
  if config then
    if type(config.class_order) == "function" then
      config.class_order(classes)
    elseif config.class_order == "ascending" then
      table.sort(classes)
    elseif config.class_order == "descending" then
      table.sort(classes, function(a, b)
        return a > b
      end)
    end
  end
end

md.sort_functions = function(config, functions)
  if config then
    if type(config.function_order) == "function" then
      config.function_order(functions)
    elseif config.function_order == "ascending" then
      table.sort(functions)
    elseif config.function_order == "descending" then
      table.sort(functions, function(a, b)
        return a > b
      end)
    end
  end
end

md.format_class_fields = function(fields, list, space_prefix)
  if not list or table.getn(list) <= 0 then
    return ""
  end
  local output = "| Key | Type | Description |\n|-----|------|-------------|\n"
  for _, f in ipairs(list) do
    output = output
      .. ("| %s | %s | %s |\n"):format(fields[f].name, table.concat(input[f].type, "|"), input[f].description)
  end
  return output .. "\n"
end

md.format_class = function(class, config)
  local space_prefix = string.rep(" ", 4)
  local title = class.parent and ("%s : %s"):format(class.name, class.parent) or class.name

  doc = ("### `%s` Class\n"):format(title)
  doc = doc .. renderer.render(class.desc, space_prefix, 120) .. "\n"

  -- if class.parent then
  --   doc = doc .. "\n" .. space_prefix .. "Parents: ~" .. "\n"
  --   doc = doc .. string.format("%s%s|%s|\n", space_prefix, space_prefix, class.parent)
  -- end

  if config then
    if type(config.field_order) == "function" then
      config.field_order(class.field_list)
    elseif config.field_order == "ascending" then
      table.sort(class.field_list)
    elseif config.field_order == "descending" then
      table.sort(class.field_list, function(a, b)
        return a > b
      end)
    end
  end
  doc = doc .. "#### Fields\n"
  doc = doc .. md.format_class_fields(class.fields, class.field_list, space_prefix)

  return doc
end

md.format_function = function(func, config)
  local space_prefix = string.rep(" ", 4)

  local name = func.name

  local left_side = string.format(
    "%s(%s)",
    name,
    table.concat(
      map(function(val)
        return string.format("{%s}", func.parameters[val].name)
      end, func.parameter_list),
      ", "
    )
  )

  local right_side = string.format("*%s()*", name)

  -- TODO(conni2461): LONG function names break this thing
  local header = align_text(left_side, right_side, 78)

  local doc = ""
  doc = doc .. header .. "\n"

  local description = render(func.description, space_prefix, 79)
  doc = doc .. description .. "\n"

  -- TODO(conni2461): CLASS

  -- Handles parameter if used
  doc = doc .. help.iter_parameter_field(func.parameters, func.parameter_list, "Parameters", space_prefix)

  if config then
    if type(config.field_order) == "function" then
      config.field_order(func.field_list)
    elseif config.field_order == "ascending" then
      table.sort(func.field_list)
    elseif config.field_order == "descending" then
      table.sort(func.field_list, function(a, b)
        return a > b
      end)
    end
  end
  -- Handle fields if used
  doc = doc .. help.iter_parameter_field(func.fields, func.field_list, "Fields", space_prefix)

  local gen_misc_doc = function(identification, ins)
    if func[identification] then
      local title = identification:sub(1, 1):upper() .. identification:sub(2, -1)

      if doc:sub(#doc, #doc) ~= "\n" then
        doc = doc .. "\n"
      end
      doc = doc .. "\n" .. string.format("%s%s: ~", space_prefix, title) .. "\n"
      for _, x in ipairs(func[identification]) do
        doc = doc .. render({ string.format(ins, x) }, space_prefix .. space_prefix, 78) .. "\n"
      end
    end
  end

  gen_misc_doc("varargs", "%s")
  gen_misc_doc("return", "%s")
  gen_misc_doc("usage", "%s")
  gen_misc_doc("see", "|%s()|")

  return doc
end

md.filter_functions = function(functions)
  return vim.tbl_filter(function(func_name)
    if
      func_name:find(".__", 1, true)
      or func_name:find(":__", 1, true)
      or func_name:sub(1, 2) == "__"
      or func_name:sub(1, 2) ~= "__"
    then
      return false
    else
      return true
    end
  end, functions)
end

md.add = function(text, no_nl)
  md.formatted = md.formatted .. (text or "") .. (no_nl and "" or "\n")
end

md.add_breif = function(breif)
  if not breif then
    return
  end
  local result = renderer.render(breif, "", 120)
  if not result then
    error "Missing result"
  end
  add(result)
  add()
end

md.format = function(metadata)
  if vim.tbl_isempty(metadata) then
    return ""
  end
  if metadata.tag then
    md.add(md.tag_heading:format(metadata.tag))
  end

  md.add_breif(metadata.brief)

  -- Make Classes
  local classes = vim.deepcopy(metadata.class_list or {})
  md.sort_classes(metadata.config, classes)

  --- Add Classes
  for _, class_name in ipairs(classes) do
    local v = metadata.classes[class_name]

    local result = md.format_class(v, metadata.config)
    if not result then
      error "Missing result"
    end

    add(result)
    add()
  end

  -- Make Functions
  local functions = vim.deepcopy(metadata.function_list or {})
  md.sort_functions(metadata, functions)
  functions = md.filter_functions(functions)

  --- Add Functions
  for _, func_name in ipairs(functions) do
    local v = metadata.functions[func_name]

    local result = help.format_function(v, metadata.config)
    if not result then
      error "Missing result"
    end

    add(result)
    add()
  end
end

md.write = function(input_file, output_file_handle)
  log.trace("Transforming:", input_file)
  local contents = read(input_file)
  local resulting_nodes = docgen.get_nodes(contents)

  if docgen.debug then
    print("Resulting Nodes:", vim.inspect(resulting_nodes))
  end

  markdown.format(resulting_nodes)
  output_file_handle:write(result)
end

local function gen()
  local input_files = {
    "./lua/sql/init.lua",
    "./lua/sql/db.lua",
    "./lua/sql/table.lua",
  }

  local help = "./doc/sqlite.txt"
  -- local markdown = "./doc/sqlite.md"
  local help_handle = io.open(help, "w")
  -- local markdown_handle = io.open(md_output_file, "w")
  -- markdown_handle:write("# `sql.nvim` API Documentation")

  for _, input_file in ipairs(input_files) do
    docgen.write(input_file, help_handle)
    -- md.wirte(input_file, markdown_handle)
  end

  help_handle:write " vim:tw=78:ts=8:ft=help:norl:\n"
  help_handle:close()
  -- markdown_handle:close()
  vim.cmd [[checktime]]
end

-- gen()
