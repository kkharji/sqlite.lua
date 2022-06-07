.PHONY: test lint docgen
test:
	nvim --headless --noplugin -u test/minimal_init.vim -c "PlenaryBustedDirectory test/auto/ { minimal_init = './test/minimal_init.vim' }"

lint:
	luacheck lua/

stylua:
	stylua --color always --check lua/

gen_nvimhelp: ./scripts/gen_nvimhelp.lua
	nvim --headless --noplugin -u test/minimal_init.vim -c "luafile ./scripts/gen_nvimhelp.lua" -c 'qa'

testfile:
	nvim --headless --noplugin -u test/minimal_init.vim -c "PlenaryBustedDirectory test/auto/$(file)_spec.lua { minimal_init = './test/minimal_init.vim' }"

gen_luarock: ./scripts/gen_rockspec.lua
	nvim --headless --noplugin -u test/minimal_init.vim -c "luafile ./scripts/gen_rockspec.lua" -c 'qa'

