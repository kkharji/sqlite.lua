test:
	nvim --headless -c 'PlenaryBustedDirectory test/auto/ { minimal_init = "test/minimal_init.vim"  }'

lint:
	luacheck lua/
