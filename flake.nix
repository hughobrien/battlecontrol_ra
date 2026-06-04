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
      self,
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
        sdl3
      ];
      buildApp = pkgs.writeShellApplication {
        name = "battlecontrol-ra-zig-build";
        runtimeInputs = packages;
        text = ''
          exec zig build \
            -Dsdl3-include=${pkgs.sdl3.dev}/include \
            -Dsdl3-lib=${pkgs.sdl3}/lib \
            "$@"
        '';
      };
      mkRunApp =
        side: assets:
        pkgs.writeShellApplication {
          name = "battlecontrol-ra";
          text = ''
            exec ${pkgs.python3}/bin/python3 ${./linux-compat/launcher/ra_xvfb_launcher.py} \
              --assets ${builtins.toJSON "${assets}"} \
              --build-app ${builtins.toJSON "${buildApp}/bin/battlecontrol-ra-zig-build"} \
              --side ${builtins.toJSON side} \
              --xvfb ${builtins.toJSON "${pkgs.xvfb}/bin/Xvfb"} \
              -- "$@"
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
          runAlliedApp = mkRunApp "allied" self.packages.${system}.ra-data-allied;
          runSovietApp = mkRunApp "soviet" self.packages.${system}.ra-data-soviet;
        in
        {
          default = build;
          inherit build;
          run-allied = {
            type = "app";
            program = "${runAlliedApp}/bin/battlecontrol-ra";
          };
          run-soviet = {
            type = "app";
            program = "${runSovietApp}/bin/battlecontrol-ra";
          };
        };

      packages.${system} = rec {
        default = buildApp;
        ra-data-allied = mkRaData "ra-data-allied" redalert-allied-iso;
        ra-data-soviet = mkRaData "ra-data-soviet" redalert-soviet-iso;
      };

      checks.${system}.xvfb-run-app = pkgs.runCommand "xvfb-run-app-check" { } ''
        ${pkgs.ruff}/bin/ruff format --check ${./linux-compat/launcher/ra_xvfb_launcher.py}
        ${pkgs.ruff}/bin/ruff format --check ${./linux-compat/launcher/ra_xvfb_launcher_test.py}
        ${pkgs.ruff}/bin/ruff check ${./linux-compat/launcher/ra_xvfb_launcher.py}
        ${pkgs.ruff}/bin/ruff check ${./linux-compat/launcher/ra_xvfb_launcher_test.py}
        PYTHONPATH=${./linux-compat/launcher} ${pkgs.python3}/bin/python3 ${./linux-compat/launcher/ra_xvfb_launcher_test.py}
        grep -q -- "--assets" ${./linux-compat/launcher/ra_xvfb_launcher.py}
        grep -q -- "--skip-intro" ${./linux-compat/launcher/ra_xvfb_launcher.py}
        grep -q "battlecontrol-xdisplay" ${./linux-compat/launcher/ra_xvfb_launcher.py}
        allied="${mkRunApp "allied" self.packages.${system}.ra-data-allied}/bin/battlecontrol-ra"
        soviet="${mkRunApp "soviet" self.packages.${system}.ra-data-soviet}/bin/battlecontrol-ra"
        test -x "$allied"
        test -x "$soviet"
        for launcher in "$allied" "$soviet"; do
          grep -q -- "--assets" "$launcher"
          grep -q -- "--build-app" "$launcher"
          grep -q -- "--side" "$launcher"
          grep -q -- "--xvfb" "$launcher"
        done
        grep -a -q "ra-data-allied" "$allied"
        grep -a -q "ra-data-soviet" "$soviet"
        touch "$out"
      '';
    };
}
