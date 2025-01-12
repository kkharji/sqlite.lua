sqlite.lua 💫
=================


[SQLite]/[LuaJIT] binding and a highly opinionated wrapper for storing, retrieving, caching, and persisting [SQLite] databases.
[sqlite.lua] present new possibilities for plugin development and while it's primarily created for [neovim], it support all luajit environments.

- [Changelog](https://github.com/kkharji/sqlite.lua/blob/master/CHANGELOG.md)
- [Docs](https://github.com/kkharji/sqlite.lua/blob/master/doc/sqlite.txt)
- [Examples](https://github.com/kkharji/sqlite.lua/blob/master/lua/sqlite/examples)
- [Powered By sqlite.lua](https://github.com/kkharji/sqlite.lua#-powered-by-sqlitelua)

![preview](https://user-images.githubusercontent.com/2361214/202757101-65735d52-2927-4de0-8d69-b078b66aaca6.svg)

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

### [Packer.nvim](https://github.com/wbthomason/packer.nvim) (Neovim)

```lua
use { "kkharji/sqlite.lua" }
```

### [luarocks](https://luarocks.org/) (LuaJIT)

```bash
luarocks install sqlite luv
```

**Ensure you have `sqlite3` installed locally.** (if you are on mac it might be installed already)

#### Windows

[Download precompiled](https://www.sqlite.org/download.html) and set `let g:sqlite_clib_path = path/to/sqlite3.dll` (note: `/`)

#### Linux
```bash
sudo pacman -S sqlite # Arch
sudo apt-get install sqlite3 libsqlite3-dev # Ubuntu
sudo dnf install sqlite sqlite-devel # Fedora
```

#### Nix (home-manager)
```nix
programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.sqlite-lua;
      config = "let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3${stdenv.hostPlatform.extensions.sharedLibrary}'";
    }
];
```

*Notes:*
  - Ensure you install `pkgs.sqlite`

🔥 Powered by sqlite.lua
-----------------

- https://github.com/kkharji/impatient.nvim
- https://github.com/nvim-telescope/telescope-smart-history.nvim
- https://github.com/nvim-telescope/telescope-frecency.nvim
- https://github.com/kkharji/lispdocs.nvim
- https://github.com/nvim-telescope/telescope-cheat.nvim
- https://github.com/LintaoAmons/bookmarks.nvim

[Installation]: #🚧_installation
[SQLite]: https://www.sqlite.org/index.html
[LuaJIT]: https://luajit.org
[sqlite.lua]: https://github.com/kkharji/sqlite.lua
[neovim]: https://github.com/neovim/neovim
