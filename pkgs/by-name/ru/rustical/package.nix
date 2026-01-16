{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rustical";
  version = "0.11.16";

  src = fetchFromGitHub {
    owner = "lennart-k";
    repo = "rustical";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9hFRxsB5M+RLGLSBeS2AeMuASHA/wKL6hDaPkqCZ7ck=";
  };

  cargoPatches = [ ./fix-rustical-vendor.patch ];

  cargoHash = "sha256-sw7S684RzyZ4+VKo1BJ2Hs/tTxWHCAsObmJ4CdJmxJ0=";

  postPatch = ''
    substituteInPlace Cargo.toml \
      --replace-fail 'rust-version = "1.92"' 'rust-version = "1.91"'
  '';

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  env.OPENSSL_NO_VENDOR = true;

  meta = {
    description = "Yet another calendar server aiming to be simple, fast and passwordless";
    homepage = "https://github.com/lennart-k/rustical";
    changelog = "https://github.com/lennart-k/rustical/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ PopeRigby ];
    mainProgram = "rustical";
  };
})
