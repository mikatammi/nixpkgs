{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch2,
  # nativeBuildInputs
  pkg-config,
  cmake,
  qt6,
  # darwin-only
  xcbuild,

  # buildInputs
  curl,
  enet,
  ffmpeg,
  fmt,
  gettext,
  libGL,
  libGLU,
  libSM,
  libXdmcp,
  libXext,
  libXinerama,
  libXrandr,
  libXxf86vm,
  libao,
  libpthreadstubs,
  libpulseaudio,
  libusb1,
  mbedtls,
  miniupnpc,
  openal,
  pcre,
  portaudio,
  readline,
  SDL2,
  sfml,
  soundtouch,
  xz,
  # linux-only
  alsa-lib,
  bluez,
  libevdev,
  udev,
  vulkan-loader,
  # darwin-only
  hidapi,
  libpng,
  moltenvk,

  # passthru
  testers,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dolphin-emu-primehack";
  version = "1.0.8";

  src = fetchFromGitHub {
    owner = "shiiion";
    repo = "dolphin";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-/9AabEJ2ZOvHeSGXWRuOucmjleBMRcJfhX+VDeldbgo=";
  };

  patches = [
    # (fetchpatch2 {
    #   url = "https://github.com/dolphin-emu/dolphin/commit/8edef722ce1aae65d5a39faf58753044de48b6e0.patch?full_index=1";
    #   hash = "sha256-QEG0p+AzrExWrOxL0qRPa+60GlL0DlLyVBrbG6pGuog=";
    # })
    ./0001-Need-private-component-also-for-Darwin.patch
    ./0001-fmt-Replace-deprecated-fmt-localtime-usage-with-Comm.patch
    ./0001-Fix-unknown-type-NSView.patch
  ];

  nativeBuildInputs = [
    pkg-config
    cmake
    qt6.wrapQtAppsHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    xcbuild # for plutil
  ];

  buildInputs = [
    curl
    enet
    ffmpeg
    fmt
    gettext
    libao
    libGL
    libGLU
    libSM
    libXdmcp
    libXext
    libXinerama
    libXrandr
    libXxf86vm
    libpthreadstubs
    libusb1
    libpng
    mbedtls
    miniupnpc
    openal
    pcre
    hidapi
    portaudio
    qt6.qtbase
    qt6.qtsvg
    readline
    SDL2
    soundtouch
    xz
    vulkan-loader
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    bluez
    libevdev
    libpulseaudio
    sfml
    udev
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    moltenvk
  ];

  cmakeFlags = [
    (lib.cmakeBool "USE_SHARED_ENET" true)
    (lib.cmakeBool "ENABLE_LTO" true)
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    (lib.cmakeBool "OSX_USE_DEFAULT_SEARCH_PATH" true)
    (lib.cmakeBool "USE_BUNDLED_MOLTENVK" false)
    (lib.cmakeBool "MACOS_CODE_SIGNING" false)
    # Bundles the application folder into a standalone executable, so we cannot devendor libraries
    (lib.cmakeBool "SKIP_POSTPROCESS_BUNDLE" true)
    # Needs xcode so compilation fails with it enabled. We would want the version to be fixed anyways.
    # Note: The updater isn't available on linux, so we don't need to disable it there.
    (lib.cmakeBool "ENABLE_AUTOUPDATE" false)
  ];

  qtWrapperArgs = lib.optionals stdenv.hostPlatform.isLinux [
    "--prefix LD_LIBRARY_PATH : ${vulkan-loader}/lib"
    # https://bugs.dolphin-emu.org/issues/11807
    # The .desktop file should already set this, but Dolphin may be launched in other ways
    "--set QT_QPA_PLATFORM xcb"
  ];

  # - Allow Dolphin to use nix-provided libraries instead of building them
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'DISTRIBUTOR "None"' 'DISTRIBUTOR "NixOS"'
  '';

  doInstallCheck = true;

  postInstall = ''
    mv $out/bin/dolphin-emu-nogui $out/bin/dolphin-emu-primehack-nogui
    mv $out/bin/dolphin-tool $out/bin/dolphin-tool-primehack
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    mv $out/bin/dolphin-emu $out/bin/dolphin-emu-primehack
    mv $out/share/applications/dolphin-emu.desktop $out/share/applications/dolphin-emu-primehack.desktop
    mv $out/share/icons/hicolor/256x256/apps/dolphin-emu.png $out/share/icons/hicolor/256x256/apps/dolphin-emu-primehack.png
    substituteInPlace $out/share/applications/dolphin-emu-primehack.desktop \
      --replace-fail 'dolphin-emu' 'dolphin-emu-primehack' \
      --replace-fail 'Dolphin Emulator' 'PrimeHack'
    install -D $src/Data/51-usb-device.rules $out/etc/udev/rules.d/51-usb-device.rules
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    mv -v Binaries/DolphinQt.app $out/DolphinQt.app
  '';

  passthru = {
    tests = {
      version = testers.testVersion {
        package = finalAttrs.finalPackage;
        command = "dolphin-emu-primehack-nogui --version";
        version = "v${finalAttrs.version}";
      };
    };
    updateScript = nix-update-script { };
  };

  meta = {
    homepage = "https://github.com/shiiion/dolphin";
    description = "Gamecube/Wii/Triforce emulator for x86_64 and ARMv8";
    license = lib.licenses.gpl2Plus;
    # broken = stdenv.hostPlatform.isDarwin;
    platforms = lib.platforms.unix;
  };
})
