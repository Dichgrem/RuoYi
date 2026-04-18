{
  description = "RuoYi dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
  in {
    devShells = nixpkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          temurin-bin-17
          mysql80
          redis
          just
        ];

        shellHook = ''
          export JAVA_HOME=${pkgs.temurin-bin-17}
          export PATH=$JAVA_HOME/bin:$PATH
          mkdir -p .dev/mysql .dev/mysql-run .dev/redis .dev/logs
        '';
      };
    });
  };
}
