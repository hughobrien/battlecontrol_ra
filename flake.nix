{
  description = "Zig build environment for battlecontrol_ra";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cnc-ddraw = {
      url = "github:FunkyFr3sh/cnc-ddraw";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, cnc-ddraw, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      packages = with pkgs; [
        zig
      ];
      buildApp = pkgs.writeShellApplication {
        name = "battlecontrol-ra-zig-build";
        runtimeInputs = packages;
        text = ''
          exec zig build \
            -Dcnc-ddraw-source=${cnc-ddraw} \
            "$@"
        '';
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        inherit packages;
      };

      apps.${system} =
        let
          build = {
            type = "app";
            program = "${buildApp}/bin/battlecontrol-ra-zig-build";
          };
        in
        {
          default = build;
          inherit build;
        };

      packages.${system}.default = buildApp;
    };
}
