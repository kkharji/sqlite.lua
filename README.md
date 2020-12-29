sql.nvim
=================

Neovim [SQLite] wrapper

API
-----------------
WIP

Personal use
-----------------

To make sure that sql.nvim work as expected, it is sometimes needed that  you
set the following variable yourself:

```vim 
let g:plugin.sql.libsqlite3 = '/usr/lib/libsqlite3.so' 
" default for linux hosts
```

Plugin Intergration 
-----------------

To make use of sql.nvim in your plugin and keep it in sync with this repo,
it is advised that you have a makefile that adds `lua/sql` to
`lua/myplugin/sql` and any time there is an update you can rerun the makefile
or even use a specfic version.

-- In Makefile:
```
default: deps

deps:
	scripts/deps tami5 sql.nvim origin/master
```

-- In scripts/deps 
```bash
mkdir -p deps
if [ ! -d "deps/$2" ]; then
  git clone "https://github.com/$1/$2.git" "deps/$2"
  git -C "deps/$2" fetch && git -C "deps/$2" checkout "$3"
fi

# Embeding
ROOT=`basename ${PWD}`
PLUGIN="${ROOT%.*}"
DEP="${2%.*}"
mkdir -p "lua/$PLUGIN"
rsync -avu --delete "deps/$2/${4:-lua/$DEP/}" "lua/$PLUGIN/$DEP" 2>&1 >/dev/null 
find lua/$PLUGIN/$DEP -type f -exec sed -i -e "s/$DEP/$PLUGIN\.$DEP/g" {} \;
```

-- In README:

```markdown
To make sure that sql.nvim work as expected, it is sometimes needed that  you set the following variable yourself:

```vim 
let g:plugin.sql.libsqlite3 = '/usr/lib/libsqlite3.so' " default for linux hosts
``
```

[SQLite]: https://www.sqlite.org/index.html
