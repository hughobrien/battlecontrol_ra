{
  description = "Zig build environment for battlecontrol_ra";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      glibcInclude = "${pkgs.glibc.dev}/include";
      sdlInclude = "${pkgs.SDL2.dev}/include";
      sdlPkgConfigPath = pkgs.lib.makeSearchPath "lib/pkgconfig" [
        pkgs.SDL2.dev
      ];
      packages = with pkgs; [
        zig
        pkg-config
        python3
        glibc.dev
        SDL2
        SDL2.dev
      ];
      buildApp = pkgs.writeShellApplication {
        name = "battlecontrol-ra-zig-build";
        runtimeInputs = packages;
        text = ''
          export BATTLECONTROL_GLIBC_INCLUDE="''${BATTLECONTROL_GLIBC_INCLUDE:-${glibcInclude}}"
          export BATTLECONTROL_SDL_INCLUDE="''${BATTLECONTROL_SDL_INCLUDE:-${sdlInclude}}"
          export PKG_CONFIG_PATH="${sdlPkgConfigPath}''${PKG_CONFIG_PATH:+:''${PKG_CONFIG_PATH}}"
          exec zig build "$@"
        '';
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        inherit packages;

        BATTLECONTROL_GLIBC_INCLUDE = glibcInclude;
        BATTLECONTROL_SDL_INCLUDE = sdlInclude;
        PKG_CONFIG_PATH = sdlPkgConfigPath;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${buildApp}/bin/battlecontrol-ra-zig-build";
        };
        build = {
          type = "app";
          program = "${buildApp}/bin/battlecontrol-ra-zig-build";
        };
      };
    };
}
