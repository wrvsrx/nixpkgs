{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  runCommand,
  jq,
  testers,
}:

buildGoModule (finalAttrs: {
  pname = "lark-cli";
  version = "1.0.86";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "larksuite";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xa+IXmjR5PqaDWPhW+zfMVN54j2dbPyxal3Ga7KRosg=";
  };

  vendorHash = "sha256-WClES7ilNmQ0018Qf13tNHouE/SIwh99MaewZ7VGQ2E=";

  subPackages = [ "." ];

  postPatch =
    let
      metaDataRaw = fetchurl {
        name = "meta_dataraw.json";
        url = "https://open.feishu.cn/api/tools/open/api_definition?protocol=meta&client_version=v${finalAttrs.version}";
        hash = "sha256-SK0ovzE36GtyfMhg9DGtap0+YrFeZQrDIeBVjHDzvM8=";
        postFetch = ''
          ${lib.getExe jq} -S . "$out" > normalized
          mv normalized "$out"
        '';
      };

      metaData =
        runCommand "meta_data.json"
          {
            nativeBuildInputs = [ jq ];
          }
          ''
            jq '.data' ${metaDataRaw} > $out
          '';
    in
    ''
      cp ${metaData} internal/registry/meta_data.json
    '';

  postInstall = ''
    mv $out/bin/cli $out/bin/lark-cli
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/larksuite/cli/internal/build.Version=v${finalAttrs.version}"
    "-X github.com/larksuite/cli/internal/build.Date=2026-08-11"
  ];

  passthru.updateScript = ./update.sh;

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "lark-cli --version";
    version = "v${finalAttrs.version}";
  };

  meta = {
    description = "The official CLI for Lark/Feishu open platform";
    homepage = "https://github.com/larksuite/cli";
    changelog = "https://github.com/larksuite/cli/releases/tag/v${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ zehuajun ];
    mainProgram = "lark-cli";
  };
})
