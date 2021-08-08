.PHONY: test lint docgen
test:
	nvim --headless --noplugin -u test/minimal_init.vim -c "PlenaryBustedDirectory test/auto/ { minimal_init = './test/minimal_init.vim' }"

lint:
	luacheck lua/

docgen:
	nvim --headless --noplugin -u test/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
