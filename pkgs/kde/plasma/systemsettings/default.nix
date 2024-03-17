{
  mkKdeDerivation,
  knewstuff,
  kdeclarative,
  ksvg,
  plasma-workspace,
}:
mkKdeDerivation {
  pname = "systemsettings";
  extraBuildInputs = [
    knewstuff
    kdeclarative
    ksvg
    plasma-workspace
  ];
}
