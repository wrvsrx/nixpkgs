{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  libxkbcommon,
  pango,
  which,
  git,
  cairo,
  libxcb,
  xcb-imdkit,
  xcb-util-cursor,
  xcbutilkeysyms,
  xcbutil,
  xcbutilwm,
  xcbutilxrm,
  libstartup_notification,
  bison,
  flex,
  librsvg,
  check,
  glib,
  buildPackages,
  pandoc,
  wayland,
  wayland-protocols,
  wayland-scanner,
  withIMDKit ? true,
  withWayland ? true,
  withX11 ? true,
}:

stdenv.mkDerivation rec {
  pname = "rofi-unwrapped";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "davatorium";
    repo = "rofi";
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-akKwIYH9OoCh4ZE/bxKPCppxXsUhplvfRjSGsdthFk4=";
  };

  preConfigure = ''
    patchShebangs "script"
    # root not present in build /etc/passwd
    sed -i 's/~root/~nobody/g' test/helper-expand.c
  '';

  depsBuildBuild = [
    buildPackages.stdenv.cc
    pkg-config
    glib
  ];
  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    flex
    bison
    pandoc
  ];
  buildInputs = [
    libxkbcommon
    pango
    cairo
    git
    librsvg
    check
    libstartup_notification
    libxcb
    xcb-imdkit
    xcb-util-cursor
    xcbutilkeysyms
    xcbutil
    xcbutilwm
    xcbutilxrm
    which
  ]
  ++ lib.optionals withIMDKit [
    xcb-imdkit
  ]
  ++ lib.optionals withWayland [
    wayland
    wayland-protocols
    wayland-scanner
  ];

  mesonFlags =
    lib.optionals withIMDKit [ "-Dimdkit=true" ]
    ++ lib.optionals (!withWayland) [ "-Dwayland=disabled" ]
    ++ lib.optionals (!withX11) [ "-Dxcb=disabled" ];

  doCheck = false;

  meta = with lib; {
    description = "Window switcher, run dialog and dmenu replacement";
    homepage = "https://github.com/davatorium/rofi";
    license = licenses.mit;
    maintainers = with maintainers; [ bew ];
    platforms = with platforms; linux;
    mainProgram = "rofi";
  };
}
