{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  hatchling,
  brotli,
  brotlicffi,
  starlette,
  zstandard,
}:

buildPythonPackage rec {
  pname = "starlette-compress";
  version = "1.6.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "Zaczero";
    repo = "starlette-compress";
    tag = version;
    hash = "sha256-VEVPbCGE4BQo/0t/P785TyMHZGSKCicV6H0LbBsv8uo=";
  };

  build-system = [ hatchling ];

  dependencies = [
    brotli
    brotlicffi
    starlette
    zstandard
  ];

  pythonImportsCheck = [ "starlette_compress" ];

  meta = with lib; {
    description = "Compression middleware for Starlette - supporting ZStd, Brotli, and GZip";
    homepage = "https://pypi.org/p/starlette-compress";
    license = licenses.bsd0;
    maintainers = with maintainers; [ wrvsrx ];
  };
}
