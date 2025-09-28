{
  lib,
  mkDerivation,
  fetchFromGitHub,
}:

mkDerivation rec {
  version = "1.3";
  pname = "agda2hs";

  src = fetchFromGitHub {
    owner = "agda";
    repo = "agda2hs";
    rev = "v${version}";
    hash = "sha256-OodnWde3oY84DJFVIn5O+oxHJeiAd7HR+w+vPAn3CzM=";
  };

  preBuild = ''
    # Haskell.Extra.Delay and Haskell.Prim.Thunk use sized types
    echo "{-# OPTIONS --sized-types #-}" > Everything.agda
    echo "module Everything where" >> Everything.agda
    find lib -name '*.agda' | sed -e 's/lib\///;s/\//./g;s/\.agda$//;s/^/import /' >> Everything.agda
  '';

  meta = with lib; {
    homepage = "https://github.com/agda/agda2hs";
    description = "Standard library for compiling Agda code to readable Haskell";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = with maintainers; [
      alexarice
      turion
    ];
  };
}
