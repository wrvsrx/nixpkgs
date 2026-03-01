{
  lib,
  stdenv,
  fetchFromGitHub,

  pkg-config,
  cmake,
  ninja,
  spirv-tools,
  qt6,
  jemalloc,
  cli11,
  wayland,
  wayland-protocols,
  wayland-scanner,
  libxcb,
  libdrm,
  libgbm ? null,
  vulkan-headers,
  pipewire,
  pam,
  polkit,
  glib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "noctalia-qs";
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-qs";
    tag = "v0.0.4";
    hash = "sha256-1QXO0UPKdDFc0dmIuyV8u/P+7ZlPtzxWbIakeUNJ0z8=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    spirv-tools
    pkg-config
    qt6.qtwayland
    qt6.wrapQtAppsHook
    wayland-scanner
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    qt6.qtsvg
    cli11
    wayland
    wayland-protocols
    libdrm
    libgbm
    vulkan-headers
    jemalloc
    libxcb
    pam
    pipewire
    polkit
    glib
  ];

  cmakeFlags = [
    (lib.cmakeFeature "DISTRIBUTOR" "Nixpkgs")
    (lib.cmakeBool "DISTRIBUTOR_DEBUGINFO_AVAILABLE" true)
    (lib.cmakeFeature "INSTALL_QML_PREFIX" qt6.qtbase.qtQmlPrefix)
    (lib.cmakeFeature "GIT_REVISION" "tag-v${finalAttrs.version}")
  ];

  cmakeBuildType = "RelWithDebInfo";
  separateDebugInfo = true;
  dontStrip = false;

  meta = with lib; {
    homepage = "https://github.com/noctalia-dev/noctalia-qs";
    description = "Flexbile QtQuick based desktop shell toolkit";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    mainProgram = "noctalia-qs";
    maintainers = with lib.maintainers; [ iynaix ];
  };
})
