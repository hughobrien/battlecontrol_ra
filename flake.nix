{
  description = "Zig build environment for battlecontrol_ra";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    redalert-allied-iso = {
      url = "https://archive.org/download/cnc-red-alert/redalert_allied.iso";
      flake = false;
    };
    redalert-soviet-iso = {
      url = "https://archive.org/download/cnc-red-alert/redalert_soviets.iso";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      redalert-allied-iso,
      redalert-soviet-iso,
      ...
    }:
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
          exec zig build "$@"
        '';
      };
      mkRaData =
        name: iso:
        pkgs.runCommand name
          {
            src = iso;
            nativeBuildInputs = [ pkgs.unar ];
          }
          ''
            mkdir -p "$out"
            unar -q -o "$out" -D "$src" MAIN.MIX 2>/dev/null
            unar -q -o "$out" -D "$src" INSTALL/REDALERT.INI 2>/dev/null
            unar -q -o "$out" -D "$src" INSTALL/REDALERT.MIX 2>/dev/null
            for install_dir in "$out"/INSTALL*; do
              if [ -d "$install_dir" ]; then
                mv "$install_dir"/* "$out/"
                rmdir "$install_dir"
              fi
            done
            ln -sf MAIN.MIX "$out/main.mix"
            ln -sf REDALERT.MIX "$out/redalert.mix"
          '';
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

      packages.${system} = rec {
        default = buildApp;
        ra-data-allied = mkRaData "ra-data-allied" redalert-allied-iso;
        ra-data-soviet = mkRaData "ra-data-soviet" redalert-soviet-iso;
      };
    };
}
