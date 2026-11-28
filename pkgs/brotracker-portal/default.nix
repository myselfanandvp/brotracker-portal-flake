{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  gobject-introspection,
  copyDesktopItems,
  makeDesktopItem,
  xdg-utils,
  cairo,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  mesa,
  expat,
  libxcb,
  libxkbcommon,
  alsa-lib,
  vulkan-loader,
  libGL,
  nss,
  nspr,
  dbus,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cups,
  gtk3,
  pango,
  systemd,
  glib,
  gsettings-desktop-schemas,
  gst_all_1,
  pipewire,
  python3Packages,
  libnotify,
  libsecret,
  libpulseaudio,
  xdg-desktop-portal,
}:
let
  version = "0.1.16";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "brotracker";
  inherit version;

  src = fetchurl {
    url = "https://brotracker-prod.blr1.digitaloceanspaces.com/portal/brotracker-portal_${version}_amd64.deb";
    hash = "sha256-i6wzg0WVc13EmxDBRxkthy4G2LZnHAf14MRcB5XY7Vg=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
    gobject-introspection
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    cairo
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    mesa
    expat
    libxcb
    libxkbcommon
    alsa-lib
    vulkan-loader
    libGL
    nss
    nspr
    dbus
    atk
    at-spi2-atk
    at-spi2-core
    cups
    gtk3
    pango
    systemd
    glib
    gsettings-desktop-schemas
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    pipewire
    python3Packages.pyopengl
  ];

  runtimeDependencies = [
    systemd
    vulkan-loader
    xdg-desktop-portal
    libGL
    libnotify
    libsecret
    libpulseaudio
    pipewire
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  # We build the wrapper ourselves in preFixup.
  dontWrapGApps = true;

  desktopItems = [
    (makeDesktopItem {
      name = "brotracker-portal";
      desktopName = "BroTracker";
      exec = "brotracker %U";
      icon = "brotracker-portal";
      comment = "Desktop tracking and telemetry client for Brototype students and staff.";
      categories = [ "Utility" ];
      startupWMClass = "BroTracker";
      terminal = false;
    })
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/opt" "$out/share"

    if [ -d opt ]; then
      cp -r opt/. "$out/opt/"
    fi

    if [ -d usr/share ]; then
      cp -r usr/share/. "$out/share/"
    fi

    # Remove the Debian package's desktop entries.
    if [ -d "$out/share/applications" ]; then
      rm -f "$out"/share/applications/*.desktop
    fi

    mkdir -p "$out/share/applications"

    # Install the custom BroTracker icon.
    install -Dm644 ${./brotracker.png} \
      "$out/share/icons/hicolor/256x256/apps/brotracker-portal.png"

    runHook postInstall
  '';

  preFixup = ''
    BINARY_PATH=$(
      find "$out/opt" -type f -executable \
        ! -name '*.so*' \
        ! -name 'chrome-sandbox' \
        ! -name 'chrome_crashpad_handler' \
        -printf '%s\t%p\n' |
        sort -rn |
        head -n 1 |
        cut -f2-
    )

    if [ -z "$BINARY_PATH" ]; then
      echo "Error: Could not find the main executable under opt/"
      exit 1
    fi

    echo "Wrapping main binary: $BINARY_PATH"

    makeWrapper "$BINARY_PATH" "$out/bin/brotracker" \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.runtimeDependencies}" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}"
  '';

  meta = {
    description = "BroTracker desktop application";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    mainProgram = "brotracker";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
