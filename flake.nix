{
  description = "SQLite/LuaJIT binding for lua and neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.pkgs;
      in {

        devShells = {

          default = pkgs.mkShell {

            buildInputs = with pkgs; [
              luarocks
              lua51Packages.luacheck
              stylua
            ];

            shellHook = ''
              export LIBSQLITE=${pkgs.sqlite.out}/lib/libsqlite3.so
            '';
          };
        };
    });
}
