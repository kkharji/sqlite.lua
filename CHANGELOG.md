
<a name="unreleased"></a>

## unreleased

> 2021-08-24

### :art: Structure/Formating

- <a href="https://github.com/tami5/sql.nvim/commit/9be469a1e3480cb0a90865de313289986f8a5044"><tt>9be469a</tt></a> update changelog item format

- <a href="https://github.com/tami5/sql.nvim/commit/2d24f865daf5ec9931ceff84a0c5e5a8da87eb39"><tt>2d24f86</tt></a> update changelog item format (closes <a href="https://github.com/tami5/sql.nvim/issues/81"> #81</a>)


### :boom: Breaking Changes

<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/8bf61d2b548b0e8c102e6e36dd21beae133ddf63"><tt>8bf61d2</tt></a> change sugar function namespace to sql.lib</summary>

changes access to sugar functions and store it in lib. It was weird typing out `sql...` and abbreviating it seems harder too.

</details></dd></dl>


### :bug: Bug Fixes

- <a href="https://github.com/tami5/sql.nvim/commit/db026ee2f52234fd9f479178fc8349134d743c19"><tt>db026ee</tt></a> using sql functions makes parser setsome values to null (<a href="https://github.com/tami5/sql.nvim/pull/88">#88</a>) (closes <a href="https://github.com/tami5/sql.nvim/issues/87"> #87</a>)

<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/2b500b77c379356d401ee2f37a1c9cf9c1e311e6"><tt>2b500b7</tt></a> each map sort failing due to closed connection</summary>

make map, sort, each, support executing sqlite queries regardless of connection status.

  - 🐛 func(row) returning nil causing error
  - 🐛 running some tbl function without checking conn

</details></dd></dl>


### :construction_worker: CI Updates

- <a href="https://github.com/tami5/sql.nvim/commit/9173664fecfc8e13d9deffe54f1eba640f4d2481"><tt>9173664</tt></a> changelog run once every two days take 2

- <a href="https://github.com/tami5/sql.nvim/commit/3447223239ce2e0ab322db756ee1aa0374e20551"><tt>3447223</tt></a> update changelog template (<a href="https://github.com/tami5/sql.nvim/pull/90">#90</a>) (closes <a href="https://github.com/tami5/sql.nvim/issues/82"> #82</a>)

- <a href="https://github.com/tami5/sql.nvim/commit/93b0090674cf71d096406f1e8a42c585cb979cc5"><tt>93b0090</tt></a> changelog run once every two days (closes <a href="https://github.com/tami5/sql.nvim/issues/86"> #86</a>)


### :recycle: Code Refactoring

<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/4d0302f8ccb3ab647f3d5709d3adf4d3c8810060"><tt>4d0302f</tt></a> favor delete/remove accepting where key</summary>

No breaking changes here :)

</details></dd></dl>


### :sparkles: Features

<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/73d8fa60e1037d0a8b58c898ed641430d8b0c0c4"><tt>73d8fa6</tt></a> dot access for extended tbl object (<a href="https://github.com/tami5/sql.nvim/pull/92">#92</a>)</summary>

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

<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/5944a91d05f34f1d36ef33a62344cfc301fc49b4"><tt>5944a91</tt></a> table each and map accept function as first argument (closes <a href="https://github.com/tami5/sql.nvim/issues/97"> #97</a>)</summary>

still compatible with query as first argument ✅  

Examples:

```lua
tbl:each(function(row) .. end) -- execute a function on all table rows
tbl:each(function(row) .. end, {...} ) -- execute a function on all table rows match the query
-- map work the same way, but return transformed table
```

</details></dd></dl>

<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/88f14bf3148c8c31c4ba17818d80eedc33cc9f12"><tt>88f14bf</tt></a> auto changelog (<a href="https://github.com/tami5/sql.nvim/pull/80">#80</a>)</summary>

Here goes nothing 🤞. Please CI don't fail me.

</details></dd></dl>


### :zap: Performance Improvements

<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/1a36aa576f489792f61b9a62cc4b3e796d97d568"><tt>1a36aa5</tt></a> sql.extend handling of tables and connection. (<a href="https://github.com/tami5/sql.nvim/pull/96">#96</a>)</summary>

✨ New:
  - add usage examples for DB:extend.
  - support using different name to access a tbl object `{_name = ".."}`.
  - support using pre-defined/extended sql.table object.
  - 100% lazy sql object setup: No calls will be made before the first sql operation.

♻️ Changes:
  - remove init hack of controlling sql extend object table initialization (no longer needed).
  - remove old tests.

</details></dd></dl>


