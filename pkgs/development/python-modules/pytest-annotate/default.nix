{ lib
, stdenv
, buildPythonPackage
, fetchPypi
, pyannotate
, pytest
}:

buildPythonPackage rec {
  pname = "pytest-annotate";
  version = "1.0.4";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-0NpMPYcqfVeWrIUBbKodo4rpAr69x1nhtsD2+LWAJ0E=";
  };

  buildInputs = [
    pytest
  ];

  propagatedBuildInputs = [
    pyannotate
  ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace "pytest>=3.2.0,<7.0.0" "pytest>=3.2.0"
  '';

  # Module has no tests
  doCheck = false;

  pythonImportsCheck = [
    "pytest_annotate"
  ];

  meta = with lib; {
    broken = (stdenv.isLinux && stdenv.isAarch64) || stdenv.isDarwin;
    description = "Generate PyAnnotate annotations from your pytest tests";
    homepage = "https://github.com/kensho-technologies/pytest-annotate";
    license = licenses.asl20;
    maintainers = with maintainers; [ costrouc ];
  };
}
