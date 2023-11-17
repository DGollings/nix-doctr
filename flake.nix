{
  description = "A flake for python-doctr";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        mplcursors = pkgs.python3Packages.buildPythonPackage rec {
          pname = "mplcursors";
          version = "0.3";

          src = pkgs.python3Packages.fetchPypi {
            inherit pname version;
            sha256 = "sha256-DjLBxhP4g6Q21TrWWMA3er2ErAI12UDBNeEclKG679A";
          };

          nativeBuildInputs = [ pkgs.python3Packages.setuptools_scm ];

          propagatedBuildInputs = [
            pkgs.python3Packages.matplotlib
            pkgs.python3Packages.pytest
            pkgs.python3Packages.weasyprint
          ] ++ nixpkgs.lib.optional (pkgs.python3Packages.pythonOlder "3.8") pkgs.python3Packages.importlib-metadata;
        };

        ctypesgen = pkgs.python3Packages.buildPythonPackage
          rec {
            pname = "ctypesgen";
            version = "pypdfium2";

            src = pkgs.fetchFromGitHub {
              owner = "pypdfium2-team";
              repo = "ctypesgen";
              rev = "pypdfium2";
              sha256 = "sha256-klc6mouJ8w/xIgx8xmDXrui5Ebyicg++KIgr+b5ozbk=";
            };

            nativeBuildInputs = with pkgs.python3Packages; [
              setuptools
              wheel
              setuptools_scm
              tomli
            ];
            buildInputs = [ pkgs.glibc ];

            postPatch = ''
              export SETUPTOOLS_SCM_PRETEND_VERSION=1.0.0 # fake version
                mkdir -p dist
            '';

            doCheck = false;

            propagatedBuildInputs = [
              pkgs.python311Packages.wheel
              pkgs.python311Packages.toml
            ];
          };

        pypdfium2 = pkgs.python3Packages.buildPythonPackage
          rec {
            pname = "pypdfium2";
            version = "4.24.0";

            src = pkgs.python3Packages.fetchPypi {
              inherit pname version;
              sha256 = "sha256-YnBsBrxb45qnolMa+AJCBCm2xMR0mO69JSGvfpiNCEg=";
            };

            headers = pkgs.fetchurl {
              # version 6124 should match content of get-latest.patch
              url = "https://pdfium.googlesource.com/pdfium/+archive/refs/heads/chromium/6124/public.tar.gz";
              sha256 = "sha256-F0yFEpQDSucguBqeLPzj8iFzbxgV4q7av/GD6nkPDco=";
            };

            binaries = pkgs.fetchurl
              {
                # version 6124 should match content of get-latest.patch
                url = "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium%2F6124/pdfium-linux-x64.tgz";
                sha256 = "sha256-nFIwGgpwFV31rgu6ZFZtrcAAEltBNPgoVy5hR7evbA8=";
              };

            patches = [ ./pypdfium2-get-binaries.patch ];

            postPatch = ''
              mkdir -p data/bindings/headers
              tar -xzf ${headers} -C data/bindings/headers
              mkdir -p data/linux_x64
              cp ${binaries} data/linux_x64/pdfium-linux-x64.tgz
              cp ${binaries} pdfium-linux-x64.tgz
            '';

            pdfium-binaries = pkgs.fetchgit {
              url = "https://github.com/bblanchon/pdfium-binaries.git";
              # You need the revision and SHA256 here
              rev = "chromium/6124";
              sha256 = "sha256-2GfuqI95RLLhSC13Qc97wK/XrAqPxnDNfiFD2hNK4+A=";
            };

            nativeBuildInputs = [ pkgs.git ctypesgen ];
          };

        python-doctr = pkgs.python3Packages.buildPythonPackage rec {
          pname = "python-doctr";
          version = "0.7.0";

          src = pkgs.python3Packages.fetchPypi {
            inherit pname version;
            sha256 = "sha256-4F7yC8WPxiyA0vOWjtOADLFXf8k1OkZTw6eyw+D2SFU=";
          };

          nativeBuildInputs = [ pkgs.python3Packages.pip ];

          propagatedBuildInputs = [
            pkgs.python311Packages.opencv4
            pkgs.python311Packages.setuptools
            pkgs.python311Packages.huggingface-hub
            pkgs.python311Packages.unidecode
            pkgs.python311Packages.rapidfuzz
            pkgs.python311Packages.langdetect
            pkgs.python311Packages.shapely
            pkgs.python311Packages.pyclipper
            mplcursors
            pypdfium2
          ];

          doCheck = false;

        };
      in
      {
        packages.python-doctr = python-doctr;
        defaultPackage = python-doctr;
      }
    );
}
