
<a name="unreleased"></a>

## [unreleased](https://github.com/kkharji/sqlite.lua/compare/v1.2.0...unreleased)

### :bug: Bug Fixes

- <a href="https://github.com/kkharji/sqlite.lua/commit/74b3844949738999aa76b5f709673629f0888703"><tt>74b3844</tt></a> false is treat as nil when inserting (closes <a href="https://github.com/kkharji/sqlite.lua/issues/123"> #123</a>)

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/f9326aa0443592968a24970fc55c5ee609a5dba8"><tt>f9326aa</tt></a> sqlite:tbl(...) doesn't pass schema</summary>

This what happens with dealing with function that can take self or
other.

Refs: https://github.com/AckslD/nvim-neoclip.lua/pull/20

</details></dd></dl>


### :construction_worker: CI Updates

- <a href="https://github.com/kkharji/sqlite.lua/commit/99e4058704fab2109add2febf36784945cc40ecc"><tt>99e4058</tt></a> fix changelog links



<a name="v1.2.0"></a>

## [v1.2.0](https://github.com/kkharji/sqlite.lua/compare/v1.1.0...v1.2.0)

### :bug: Bug Fixes

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/edf642e2f2088a7a4bafa5a3850fd2b338566c2c"><tt>edf642e</tt></a> fix Emmylua completion</summary>

This used to work, but maybe with new versions of sumneko_lua. It
stopped working.

</details></dd></dl>


### :sparkles: Features

- <a href="https://github.com/kkharji/sqlite.lua/commit/3d89dc149b10ab72c0ba78d89b92ebeb83e921b9"><tt>3d89dc1</tt></a> add Bookmark Manager Example



<a name="v1.1.0"></a>

## [v1.1.0](https://github.com/kkharji/sqlite.lua/compare/v1.0.0...v1.1.0)

### :bug: Bug Fixes

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/43f5e0c80a93f588d788fbb3e3a3d4daaa43b85f"><tt>43f5e0c</tt></a> luarocks auto-generate script (closes <a href="https://github.com/kkharji/sqlite.lua/issues/115"> #115</a>)</summary>

Having "/" in the start of path breaks luarocks installation.

</details></dd></dl>


### :sparkles: Features

- <a href="https://github.com/kkharji/sqlite.lua/commit/5b395267bb1938c165099991a59497a9cc4ca8a1"><tt>5b39526</tt></a> activate release workflow


### :zap: Performance Improvements

- <a href="https://github.com/kkharji/sqlite.lua/commit/ca8233f8cb09b9adc7ea11f81ab903154ce07e86"><tt>ca8233f</tt></a> improve handling of sqlite builtin functions (closes <a href="https://github.com/kkharji/sqlite.lua/issues/114"> #114</a>)

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/f9a10606806142a521e971437b4a2e41d688c85b"><tt>f9a1060</tt></a> improve require time (<a href="https://github.com/kkharji/sqlite.lua/pull/11">#111</a>)</summary>

decrease require time (cost on startup) from `0.791636 ms` to `4.140682` (423% faster)

</details></dd></dl>



<a name="v1.0.0"></a>

## v1.0.0

### :art: Structure/Formating

- <a href="https://github.com/kkharji/sqlite.lua/commit/9be469a1e3480cb0a90865de313289986f8a5044"><tt>9be469a</tt></a> update changelog item format

- <a href="https://github.com/kkharji/sqlite.lua/commit/2d24f865daf5ec9931ceff84a0c5e5a8da87eb39"><tt>2d24f86</tt></a> update changelog item format (closes <a href="https://github.com/kkharji/sqlite.lua/issues/81"> #81</a>)


### :boom: Breaking Changes

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/a6bd3d1cae9d3a075bd3cf1d059a1b47e0fb5ecf"><tt>a6bd3d1</tt></a> sql.schema return detailed description of table.</summary>

Not sure if this is a wise decision or not. But it beat having the
schema returned given the key and the value the user written.

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/5b0710f50053f7e7a669f21b57979e4ef7c0aa14"><tt>5b0710f</tt></a> (parser) change nullable to require + refactor</summary>

Additionally, make primary reference pk.

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/8bf61d2b548b0e8c102e6e36dd21beae133ddf63"><tt>8bf61d2</tt></a> change sugar function namespace to sql.lib</summary>

changes access to sugar functions and store it in lib. It was weird typing out `sql...` and abbreviating it seems harder too.

</details></dd></dl>


### :bug: Bug Fixes

- <a href="https://github.com/kkharji/sqlite.lua/commit/1778aa857367c17c1468cc85a64fcda542b5c252"><tt>1778aa8</tt></a> (parser) only check when type is table (closes <a href="https://github.com/kkharji/sqlite.lua/issues/103"> #103</a>)

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/1c88610b902c122560fdd28683b101c755853a8e"><tt>1c88610</tt></a> extended tables referencing mutable db object + other fixes (<a href="https://github.com/kkharji/sqlite.lua/pull/00">#100</a>) (closes <a href="https://github.com/kkharji/sqlite.lua/issues/101"> #101</a>, <a href="https://github.com/kkharji/sqlite.lua/issues/99"> #99</a>)</summary>

- `table.extend` reference db object instead of `db.extend`ed  object. 
    this fix issue with calling methods that has been already modified by the user.
- remove debug stuff
- modify `table.extend` mechanism.
- stop mutating insert/update source data when processing for `sql.insert`

</details></dd></dl>

- <a href="https://github.com/kkharji/sqlite.lua/commit/db026ee2f52234fd9f479178fc8349134d743c19"><tt>db026ee</tt></a> using sql functions makes parser setsome values to null (<a href="https://github.com/kkharji/sqlite.lua/pull/88">#88</a>) (closes <a href="https://github.com/kkharji/sqlite.lua/issues/87"> #87</a>)

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/2b500b77c379356d401ee2f37a1c9cf9c1e311e6"><tt>2b500b7</tt></a> each map sort failing due to closed connection</summary>

make map, sort, each, support executing sqlite queries regardless of connection status.

  - 🐛 func(row) returning nil causing error
  - 🐛 running some tbl function without checking conn

</details></dd></dl>


### :construction_worker: CI Updates

- <a href="https://github.com/kkharji/sqlite.lua/commit/9173664fecfc8e13d9deffe54f1eba640f4d2481"><tt>9173664</tt></a> changelog run once every two days take 2

- <a href="https://github.com/kkharji/sqlite.lua/commit/3447223239ce2e0ab322db756ee1aa0374e20551"><tt>3447223</tt></a> update changelog template (<a href="https://github.com/kkharji/sqlite.lua/pull/90">#90</a>) (closes <a href="https://github.com/kkharji/sqlite.lua/issues/82"> #82</a>)

- <a href="https://github.com/kkharji/sqlite.lua/commit/93b0090674cf71d096406f1e8a42c585cb979cc5"><tt>93b0090</tt></a> changelog run once every two days (closes <a href="https://github.com/kkharji/sqlite.lua/issues/86"> #86</a>)


### :recycle: Code Refactoring

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/4d0302f8ccb3ab647f3d5709d3adf4d3c8810060"><tt>4d0302f</tt></a> favor delete/remove accepting where key</summary>

No breaking changes here :)

</details></dd></dl>


### :sparkles: Features

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/25748dd0f8947533fe4cff14d8900ae30f774241"><tt>25748dd</tt></a> auto alter table key definition  (<a href="https://github.com/kkharji/sqlite.lua/pull/03">#103</a>)</summary>

Support for modifying schema key definitions without wasting the table content. It has little support for renaming, in fact, renaming should be avoided for the time being.
 
✨ New: 
  - `db:execute` for executing statement without any return.
  - emmylua classes`SqlSchemaKeyDefinition` and `SqliteActions`.
  - when a key has default, then all the columns with nulls will be replaced with the default.
  - support for auto altering key to reference a foreign key.

🐛 Fixes 
  - when a foreign_keys is enabled on a connection, closing and opening disables it.

♻️ Changes
  - rename `db.sqlite_opts` to `db.opts`.

✅ Added Tests
  - auto alter: simple rename with idetnical number of keys
  - auto alter: simple rename with idetnical number of keys with a key turned to be required
  - auto alter: more than one rename with idetnical number of keys
  - auto alter: more than one rename with idetnical number of keys + default without required = true
  - auto alter: transform to foreign key
  - auto alter: pass sqlite.org tests

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/73d8fa60e1037d0a8b58c898ed641430d8b0c0c4"><tt>73d8fa6</tt></a> dot access for extended tbl object (<a href="https://github.com/kkharji/sqlite.lua/pull/92">#92</a>)</summary>

Changes:
  - Fix parsing schema key when using key value pairs.
  - access tbl original methods after overwrite with appending `_`
  - Inject db object later with `set_db`
  - auto-completion support 

    ```lua
    local users = require'sql.table'("users", {...}) -- or require'sql.table'(db, "users", {...})
    users.init = function(db) -- if db isn't injected already 
       users.set_db(db) --- inject db object 
    end
    users.get = function() -- overwriting method
      return users._get({ where = { id = 1 } })[1].name
    end
    return users
    ```

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/5944a91d05f34f1d36ef33a62344cfc301fc49b4"><tt>5944a91</tt></a> table each and map accept function as first argument (closes <a href="https://github.com/kkharji/sqlite.lua/issues/97"> #97</a>)</summary>

still compatible with query as first argument ✅  

Examples:

```lua
tbl:each(function(row) .. end) -- execute a function on all table rows
tbl:each(function(row) .. end, {...} ) -- execute a function on all table rows match the query
-- map work the same way, but return transformed table
```

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/88f14bf3148c8c31c4ba17818d80eedc33cc9f12"><tt>88f14bf</tt></a> auto changelog (<a href="https://github.com/kkharji/sqlite.lua/pull/80">#80</a>)</summary>

Here goes nothing 🤞. Please CI don't fail me.

</details></dd></dl>


### :white_check_mark: Add/Update Test Cases

- <a href="https://github.com/kkharji/sqlite.lua/commit/91b28f6c03c3d7daa2b0f953e9279d0ab32dcb09"><tt>91b28f6</tt></a> uncomment leftout tests


### :zap: Performance Improvements

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/2424ea0f9f9287247a2785069438457fc5b7f5fe"><tt>2424ea0</tt></a> (sql) avoid executing sql.schema on crud</summary>

follow up to d791f87

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/a46ee6b371a32fb1f1dd81f79fb8e6e8f07029f1"><tt>a46ee6b</tt></a> (table) avoid executing sql.schema on crud</summary>

simple performance enhancement that should have been done from the start
:smile:

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/kkharji/sqlite.lua/commit/1a36aa576f489792f61b9a62cc4b3e796d97d568"><tt>1a36aa5</tt></a> sql.extend handling of tables and connection. (<a href="https://github.com/kkharji/sqlite.lua/pull/96">#96</a>)</summary>

✨ New:
  - add usage examples for DB:extend.
  - support using different name to access a tbl object `{_name = ".."}`.
  - support using pre-defined/extended sql.table object.
  - 100% lazy sql object setup: No calls will be made before the first sql operation.

♻️ Changes:
  - remove init hack of controlling sql extend object table initialization (no longer needed).
  - remove old tests.

</details></dd></dl>


