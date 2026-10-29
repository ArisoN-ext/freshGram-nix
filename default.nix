{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  cmake,
  ninja,
  python3,
  qtshadertools,
  tdlib,
  tg_owt,
  qtbase,
  qtsvg,
  qtwayland,
  kcoreaddons,
  lz4,
  xxhash,
  ffmpeg,
  protobuf,
  openal-soft,
  minizip-ng-compat,
  range-v3,
  tl-expected,
  hunspell,
  gobject-introspection,
  rnnoise,
  microsoft-gsl,
  boost,
  ada,
  pango,
  tlottie,
  libfido2,
  libavif ? null,
  libheif ? null,
  libjxl ? null,
  libicns ? null,
  wallet-engine,
  apple-sdk_15 ? null,
  swift ? null,
  nix-update-script,
  git,
  qtimageformats,
  kimageformats,
  wrapGAppsHook3 ? null,
  wrapQtAppsHook,
  geoclue2 ? null,
  glib-networking ? null,
  webkitgtk_4_1 ? null,
  withWebkit ? stdenv.hostPlatform.isLinux,
}:

let
  unwrapped = stdenv.mkDerivation (finalAttrs: {
    pname = "freshGram-unwrapped";
    version = "7.5.9";

    src = fetchFromGitHub {
      owner = "Snowy-Fluffy";
      repo = "freshGram";
      rev = "daccd7e77579a4f946d30de35ea642a60d9231e1";
      hash = "sha256-7kdhB0qUZwTgd1S5NyPvDN6G4fsqts7arlNArBQ8fO4=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      pkg-config
      cmake
      ninja
      python3
      qtshadertools
      git
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      gobject-introspection
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      swift
    ];

    buildInputs = [
      qtbase
      qtsvg
      lz4
      xxhash
      ffmpeg
      openal-soft
      minizip-ng-compat
      range-v3
      tl-expected
      rnnoise
      tg_owt
      microsoft-gsl
      boost
      ada
      libfido2
      (tdlib.override { tde2eOnly = true; })
      tlottie
      wallet-engine
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      protobuf
      qtwayland
      kcoreaddons
      hunspell
      pango
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      apple-sdk_15
      libicns
      libavif
      libheif
      libjxl
    ];

    dontWrapQtApps = true;

    cmakeFlags = [
      # We're allowed to use the API ID of the Snap package:
      (lib.cmakeFeature "TDESKTOP_API_ID" "611335")
      (lib.cmakeFeature "TDESKTOP_API_HASH" "d524b414d21f4d37f08684c1df41ac9c")
      (lib.cmakeFeature "DESKTOP_APP_USE_PACKAGED" "ON")
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      (lib.cmakeFeature "CMAKE_Swift_COMPILER_TARGET" stdenv.hostPlatform.swift.triple)
    ];

    installPhase = lib.optionalString stdenv.hostPlatform.isDarwin ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r ${finalAttrs.meta.mainProgram}.app $out/Applications
      ln -sr $out/{Applications/${finalAttrs.meta.mainProgram}.app/Contents/MacOS,bin}

      runHook postInstall
    '';

    passthru = {
      inherit tg_owt;
      updateScript = nix-update-script { };
    };

    meta = {
      description = "Telegram Desktop fork: Better materialgram look + AyuGram features and more";
      longDescription = ''
        Telegram Desktop fork combining the materialgram look and customization
        with the features of AyuGram Desktop.
      '';
      homepage = "https://github.com/Snowy-Fluffy/freshGram";
      changelog = "https://github.com/Snowy-Fluffy/freshGram/blob/${finalAttrs.src.rev}/changelog.txt";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ ];
      platforms = lib.platforms.all;
      mainProgram = "freshGram";
    };
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "freshGram";
  inherit (unwrapped) version meta passthru;
  inherit unwrapped;

  nativeBuildInputs = [
    wrapQtAppsHook
  ]
  ++ lib.optionals withWebkit [
    wrapGAppsHook3
  ];

  buildInputs = [
    qtbase
    qtimageformats
    qtsvg
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    kimageformats
    qtwayland
  ]
  ++ lib.optionals withWebkit [
    glib-networking
  ];

  qtWrapperArgs = lib.optionals (stdenv.hostPlatform.isLinux && withWebkit) [
    "--prefix"
    "LD_LIBRARY_PATH"
    ":"
    (lib.makeLibraryPath [
      geoclue2
      webkitgtk_4_1
    ])
  ];

  dontUnpack = true;
  dontWrapGApps = true;
  dontWrapQtApps = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
    cp -r "$unwrapped" "$out"
    runHook postInstall
  '';

  preFixup = lib.optionalString (stdenv.hostPlatform.isLinux && withWebkit) ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  postFixup =
    lib.optionalString stdenv.hostPlatform.isDarwin ''
      wrapQtApp "$out/Applications/${finalAttrs.meta.mainProgram}.app/Contents/MacOS/${finalAttrs.meta.mainProgram}"
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      substituteInPlace $out/share/dbus-1/services/* \
        --replace-fail "$unwrapped" "$out"
    '';
})
