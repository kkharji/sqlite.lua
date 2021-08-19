sql.nvim 💫 
=================


[SQLite]/[LuaJIT] binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting [SQLite] databases.
[sql.nvim] present new possibilities for plugin development and while it's primarily created for [neovim], it support all luajit environments.

- [Changelog](https://github.com/tami5/sql.nvim/blob/master/CHANGELOG.md)
- [Docs](https://github.com/tami5/sql.nvim/blob/master/doc/sql.txt)

⏲️ Status
------------------
Under heavy development. Low level API is stable for usage, however, top level API and new features are subject to change. 
Please wait for 0.1 relaese or watch the repo for changes.


✨ Features:
------------------
- Connect, reconnect, close sql db connections `sql:open/sql:close`
- Evaluate any sqlite statement and return result if any `sql:eval`
- Helper function over `sql:eval` to do all sort of operation.
- High level API with `sql:table` for better experience
- lua tables deserialization/serialization (in helper functions and high level api)
- 90% test coverage.
- Up-to-date docs and changelog


🚧 Installation
-----------------

Add `sql.nvim` to your lua `package.path`, neovim `/**/start/` or use your
favorite vim package manager, and ensure you have `sqlite3` installed locally. 
If you are using macos, then sqlite3 should be installed already, otherwise install using brew.


#### Windows

[Download precompiled](https://www.sqlite.org/download.html) and set `let g:sql_clib_path = path/to/sqlite3.dll` (note: `/`)

#### Linux
```bash
sudo pacman -S sqlite # Arch
sudo apt-get install sqlite3 libsqlite3-dev # Ubuntu
```

#### Nix (home-manager)
```nix
programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.sql-nvim;
      config = "let g:sql_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3.so'";
    }
];
```

[Installation]: #🚧_installation
[Status]: #status
[SQLite]: https://www.sqlite.org/index.html
[LuaJIT]: https://luajit.org
[sql.nvim]: https://github.com/tami5/sql.nvim
[neovim]: https://github.com/neovim/neovim
