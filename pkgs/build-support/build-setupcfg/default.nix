# Build a python package from info made available by setupcfg2nix.
#
# * src: The source of the package.
# * info: The package information generated by setupcfg2nix.
# * meta: Standard nixpkgs metadata.
# * application: Whether this package is a python library or an
#   application which happens to be written in python.
# * doCheck: Whether to run the test suites.
lib: pythonPackages:
{ src, info, meta ? {}, application ? false, doCheck ? true}: let
  build = if application
    then pythonPackages.buildPythonApplication
  else pythonPackages.buildPythonPackage;
in build {
  inherit (info) pname version;

  inherit src meta doCheck;

  nativeBuildInputs = map (p: pythonPackages.${p}) (
    (info.setup_requires or []) ++
    (lib.optionals doCheck (info.tests_require or []))
  );

  propagatedBuildInputs = map (p: pythonPackages.${p})
    (info.install_requires or []);
}
