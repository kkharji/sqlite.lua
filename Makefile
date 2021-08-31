.PHONY: test lint docgen
test:
	nvim --headless --noplugin -u test/minimal_init.vim -c "PlenaryBustedDirectory test/auto/ { minimal_init = './test/minimal_init.vim' }"

lint:
	luacheck lua/

docgen:
	nvim --headless --noplugin -u test/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'

testfile:
	nvim --headless --noplugin -u test/minimal_init.vim -c "PlenaryBustedDirectory test/auto/$(file)_spec.lua { minimal_init = './test/minimal_init.vim' }"

genluarock:
	nvim --headless --noplugin -u test/minimal_init.vim -c "luafile ./scripts/gen_rockspec.lua" -c 'qa'

