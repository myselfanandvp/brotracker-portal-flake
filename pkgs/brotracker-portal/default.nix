{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "brotracker-portal";
  version = "0.1.14";

  src = fetchurl {
    url = "https://brotracker-prod.blr1.digitaloceanspaces.com/portal/BroTracker-${version}.AppImage";
    hash = "sha256-WUUL48uS5nbdSc/0cDva4tO1gKWLQCBTXkmPJTvw9Fg=";
  };

in
appimageTools.wrapType2 {
  inherit pname version src;
}
