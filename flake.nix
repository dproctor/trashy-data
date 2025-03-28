{
  description = "Data analysis of SF trash audit data.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    sf-trash-audit-data.url = "path:data/sf-city-controller-trash-audit";
  };

  outputs = { self, nixpkgs, flake-utils, sf-trash-audit-data}:
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
                statsmodels
                seaborn
                shap
                xgboost
              ]))
            ];

            shellHook = ''
              export DEV_ENVIRONMENT="trashy-data"
              export TRASH_AUDIT_DATA=${sf-trash-audit-data.packages.${system}.default.src}
            '';
          };

          packages.default = pkgs.stdenv.mkDerivation {
            pname = "write-quarto-html";
            version = "0.1.0";

            src = ./.; # This includes all files in the current directory

            buildInputs = [
              (python.withPackages (p: with p; [
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
                statsmodels
                seaborn
                shap
                xgboost
              ]))
              quartoMinimal
              which
            ];

            buildPhase = ''
              # Create output directory
              mkdir -p $out
              export HOME=$(pwd)

              export TRASH_AUDIT_DATA=${sf-trash-audit-data.packages.${system}.default.src}
              quarto render analysis.qmd  --output-dir $out
            '';
          };
        }
      );
}
