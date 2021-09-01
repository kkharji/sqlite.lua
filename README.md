sqlite.lua 💫
=================


[SQLite]/[LuaJIT] binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting [SQLite] databases.
[sqlite.lua] present new possibilities for plugin development and while it's primarily created for [neovim], it support all luajit environments.

- [Changelog](https://github.com/tami5/sqlite.lua/blob/master/CHANGELOG.md)
- [Docs](https://github.com/tami5/sqlite.lua/blob/master/doc/sqlite.txt)

<p align="center"> <img src="./doc/preview.svg"> </p>

✨ Features:
------------------
- Connect, reconnect, close sql db connections `sqlite:open/sql:close`
- Evaluate any sqlite statement and return result if any `sqlite:eval`
- Helper function over `sqlite:eval` to do all sort of operation.
- High level API with `sqlite.tbl` for better experience.
- lua tables deserialization/serialization (in helper functions and high level api)
- 90% test coverage.
- Up-to-date docs and changelog


🚧 Installation
-----------------

### [Packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "tami5/sqlite.lua" }
```

### [luarocks](https://luarocks.org/)

```bash
luarocks install sqlite
```

**Ensure you have `sqlite3` installed locally.**

#### Windows

[Download precompiled](https://www.sqlite.org/download.html) and set `let g:sqlite_clib_path = path/to/sqlite3.dll` (note: `/`)

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
      config = "let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3.so'";
    }
];
```

[Installation]: #🚧_installation
[SQLite]: https://www.sqlite.org/index.html
[LuaJIT]: https://luajit.org
[sqlite.lua]: https://github.com/tami5/sqlite.lua
[neovim]: https://github.com/neovim/neovim
