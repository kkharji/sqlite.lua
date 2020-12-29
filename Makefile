test:
	nvim --headless -c 'PlenaryBustedDirectory lua/test/auto/'

lint:
	luacheck lua/
