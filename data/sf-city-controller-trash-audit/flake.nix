{
  description = "San Francisco City Controller trash audit data";

  inputs = {
    # Use the standard nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Flakes require a flake-utils input for multi-system support
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Get the package set for the current system
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # Define a package that downloads a file
        packages.default = pkgs.stdenv.mkDerivation {
          name = "downloaded-file";
          
          src = pkgs.fetchurl {
            url = "https://data.sfgov.org/api/views/qya8-uhsz/rows.csv?fourfour=qya8-uhsz&cacheBust=1738352302&date=20250325&accessType=DOWNLOAD";
            sha256 = "sha256-reHMeqwPa5rd4vpKqKV6Uva1DnmaNwl8BohjcHeDIJI=";
          };
          # Simple build phase that just copies the downloaded file
          buildPhase = ''
            echo "Downloading file..."
          '';
          unpackPhase = " ";

          # Installation phase that places the file in the output directory
          installPhase = ''
            mkdir -p $out
            cp $src $out/sf-city-controller-trash-audit-data.csv
          '';
        };
      }
    );
}

