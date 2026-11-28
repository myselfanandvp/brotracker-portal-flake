{
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  runCommand,
}:

let
  pname = "brotracker-portal";
  version = "0.1.16";

  src = fetchurl {
    url = "./BroTracker-0.1.16.AppImage";
    hash = "sha256-WUUL48uS5nbdSc/0cDva4tO1gKWLQCBTXkmPJTvw9Fg=";
  };

  app = appimageTools.wrapType2 {
    inherit pname version src;
  };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "BroTracker";
    comment = "Desktop tracking and telemetry client for Brototype students and staff.";
    exec = "${app}/bin/${pname} %U";
    icon = pname;
    terminal = false;
    categories = [ "Utility" ];
    startupWMClass = "BroTracker";
  };

  icon = runCommand "${pname}-icon" { } ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${./brotracker.png} \
      $out/share/icons/hicolor/256x256/apps/${pname}.png
  '';

in
symlinkJoin {
  name = "${pname}-${version}";

  paths = [
    app
    desktopItem
    icon
  ];

  meta = {
    description = "BroTracker desktop application";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
  };
}
