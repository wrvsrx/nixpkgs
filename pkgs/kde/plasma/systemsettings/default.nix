{
  mkKdeDerivation,
  knewstuff,
  kdeclarative,
  ksvg,
  qtsvg,
  plasma-workspace,
}:
mkKdeDerivation {
  pname = "systemsettings";
  extraBuildInputs = [
    knewstuff
    kdeclarative
    ksvg
    qtsvg
    plasma-workspace
  ];
}
