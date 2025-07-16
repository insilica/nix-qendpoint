{
  description = "qEndpoint as a flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      with import nixpkgs { inherit system; };
      let
        qendpoint-version  = "2.5.2";
        qendpoint-cli-name = "qendpoint-cli";
        qendpoint-cli-prefix = "qendpoint";

        qendpoint-cli = stdenv.mkDerivation {
          pname = qendpoint-cli-name;
          version = qendpoint-version;

          src = fetchurl {
            url = "https://github.com/the-qa-company/qEndpoint/releases/download/v${qendpoint-version}/qendpoint-cli.zip";
            hash = "sha256-9PIDVBOUBe6AMVvKUMWL9otrJLKTWcuDBkpHvs5cHPw=";
          };

          buildInputs = [ jdk ];

          nativeBuildInputs = [ makeWrapper unzip ];

          installPhase = ''
            cp -r . "$out"

            rm "$out"/bin/*.bat
            rm "$out"/bin/*.ps1
            sed -i 's/javaenv\.sh/${qendpoint-cli-prefix}-javaenv.sh/g' $(ls "$out"/bin/*.sh | grep -v javaenv);
            mv "$out"/bin/javaenv.sh "$out"/bin/${qendpoint-cli-prefix}-javaenv.sh

            for i in $(
                find "$out"/bin \
                  -type f -name "*.sh" \
                  \! -regex '.*\/\(qendpoint\|qep\|[^/]*javaenv\)[^/]*\.sh$' \
                  -printf '%f\n' \
              ); do
              i_quotemeta="$(printf '%s\n' "$i" | sed -e 's/[.[\*^$/]/\\&/g')"
              sed -i 's,bin/'"$i_quotemeta"',bin/${qendpoint-cli-prefix}-'"$i"',g' $(ls "$out"/bin/*.sh);
              mv "$out"/bin/$i "$out"/bin/${qendpoint-cli-prefix}-$i
            done

            for i in $(ls "$out"/bin/*.sh | grep -v javaenv); do
              wrapProgram "$i" --prefix "PATH" : "${jdk}/bin/" \
                --set-default JAVA_OPTIONS "-Dspring.autoconfigure.exclude=org.springframework.boot.autoconfigure.http.client.HttpClientAutoConfiguration -Dspring.devtools.restart.enabled=false"
            done
          '';

          meta = with lib; {
            homepage = "https://github.com/the-qa-company/qEndpoint";
            description =
              "A highly scalable RDF triple store with full-text and GeoSPARQL support";
            license = licenses.lgpl3;
            platforms = platforms.linux;
          };
        };
      in {
        packages = {
          default = qendpoint-cli;
        };
      });

}
