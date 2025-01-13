{
  description = "Data analysis of SF trash audit data.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          narwhals = pkgs.python311Packages.buildPythonPackage rec {
            pname = "narwhals";
            version = "1.8.1";

            pyproject = true;
            src = pkgs.python3Packages.fetchPypi {
              inherit pname version;
              hash = "sha256-l1J3eOEfOaHl4hE7j7uerXiL5BwDN/IYUuaE43j1g+g=";
            };
            dependencies = [ pkgs.python311Packages.hatchling ];
          };

          python = let
            packageOverrides = self: super: {
              altair = super.altair.overridePythonAttrs(old: rec {
                pname = "altair";
                version = "5.4.1";
                src =  pkgs.python3Packages.fetchPypi {
                  inherit pname version;
                  hash = "sha256-DOjC5mVGyzJ+Xy11cuwOfG/uzoFiAyFWE5YvDsHXaoI=";
                };
                dependencies = [
                  narwhals
                  pkgs.python311Packages.typing-extensions
                  pkgs.python311Packages.jinja2
                  pkgs.python311Packages.jsonschema
                ];
                doCheck = false;

              });
            };
          in pkgs.python311.override {inherit packageOverrides; self = python;};

        in
        with pkgs;
        {
          devShells.default = mkShell {
            name = "sf election forecasting";
            packages = [
              (python.withPackages (p: with p; [
                pynvim

                altair
                geopandas
                jupyter
                jupyter-cache
                matplotlib
                osmnx
                pandas
                polars
                pyarrow
                pyparsing
                scikit-learn
                seaborn
                shap
                xgboost
              ]))
            ];

            shellHook = ''
              export DEV_ENVIRONMENT="trashy-data"
            '';
          };
        }
      );
}
