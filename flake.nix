{
  description = "A flake for building exodrifter's website";
  inputs = {
    utils.url = "github:numtide/flake-utils/v1.0.0";
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  outputs = { self, nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem(
      system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          apps.default = repo: {
            type = "app";

            program =
              let
                caddyFile = pkgs.writeText "Caddyfile" ''
                  :8080 {
                      root * ${self.packages."${system}".default repo}/public/
                      file_server
                      try_files {path} {path}.html {path}/ =404
                  }
                '';

                formattedCaddyFile = pkgs.runCommand "Caddyfile"
                  { nativeBuildInputs = [ pkgs.caddy ]; }
                  ''(caddy fmt ${caddyFile} || :) > "$out"'';

                script =
                  pkgs.writeShellApplication {
                    name = "logbook";

                    runtimeInputs = [ pkgs.caddy ];

                    text =
                      "caddy run --config ${formattedCaddyFile} --adapter caddyfile";
                  };

              in
                "${pkgs.lib.getExe script}";
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              pkgs.nodejs_22
            ];
          };
          packages = rec {
            default = repo: pkgs.buildNpmPackage rec {
              pname = "quartz";
              version = "4.3.1";

              src = pkgs.fetchFromGitHub {
                owner = "jackyzha0";
                repo = "quartz";
                rev = "v${version}";
                hash = "sha256-kID0R/n3ij5uvZ/CXjiLa3oqjghX2U4Zu82huejG6/Q=";
              };

              dontNpmBuild = true;
              makeCacheWritable = true;

              npmDepsHash = "sha256-qgAzMTtFTShj3xUut73DBCbkt7yTwVjthL8hEgRFdIo=";

              installPhase = ''
                runHook preInstall
                npmInstallHook

                cd $out/lib/node_modules/@jackyzha0/quartz

                # Copy our website content
                rm -r ./content
                mkdir content
                cp -r ${repo}/content/* ./content/

                mkdir .git
                cp -r ${repo}/.git/* ./.git/

                # Override quartz source files
                mv ./quartz/components/index.ts ./quartz/components/index-original.ts
                cp -r ${repo}/quartz/* ./

                $out/bin/quartz build
                mv public/ $out/public/

                runHook postInstall
              '';
            };
          };
        }
    );
}
