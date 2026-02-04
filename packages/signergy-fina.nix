# SignErgy Fina - Digital Signing Software
#
# Purpose: FINA digital document signing application for Croatian e-services
#
# Source: https://rdc.fina.hr/download/Linux.zip
# Version: 3.21.003
#
# This package extracts the SignErgyFina application from FINA's Linux distribution
# and makes it work on NixOS using FHS compatibility layer (since it bundles its own JRE).
#
# Usage in configuration.nix:
#   environment.systemPackages = [
#     (pkgs.callPackage ./packages/signergy-fina.nix { })
#   ];
#
# Or in flake.nix overlay:
#   signergy-fina = pkgs.callPackage ./packages/signergy-fina.nix { };

{ lib
, stdenv
, fetchurl
, unzip
, dpkg
, autoPatchelfHook
, makeWrapper
, makeDesktopItem
, copyDesktopItems
# Runtime dependencies
, glibc
, zlib
, xorg
, libGL
, freetype
, fontconfig
, alsa-lib
, gtk3
, glib
, nss
, nspr
, dbus
, at-spi2-atk
, cups
, libdrm
, mesa
, pango
, cairo
, gdk-pixbuf
, libxkbcommon
, pcsclite
}:

let
  version = "3.21.003";
  
  desktopItem = makeDesktopItem {
    name = "signergy-fina";
    desktopName = "SignErgy Fina";
    comment = "FINA Digital Signing Application";
    exec = "signergy-fina";
    icon = "signergy-fina";
    categories = [ "Office" "Utility" ];
    mimeTypes = [ "application/pdf" ];
  };
in
stdenv.mkDerivation rec {
  pname = "signergy-fina";
  inherit version;

  src = fetchurl {
    url = "https://rdc.fina.hr/download/Linux.zip";
    sha256 = "1kv5ykqhrcrdbb291l57p4nmqkzdnlx9b4vpbllr70zqhxcrfjvb";
  };

  nativeBuildInputs = [
    unzip
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    glibc
    zlib
    stdenv.cc.cc.lib  # libstdc++
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXtst
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXfixes
    xorg.libXinerama
    xorg.libXxf86vm
    libGL
    freetype
    fontconfig
    alsa-lib
    gtk3
    glib
    nss
    nspr
    dbus
    at-spi2-atk
    cups
    libdrm
    mesa
    pango
    cairo
    gdk-pixbuf
    libxkbcommon
    pcsclite
  ];

  # Don't try to strip Java files
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    unzip $src
    dpkg-deb -x SignErgyFina_v${version}.deb extracted
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/lib/signergy-fina
    mkdir -p $out/share/signergy-fina

    # Copy main binary and set execute permission
    cp extracted/usr/bin/SignErgyFina $out/lib/signergy-fina/
    chmod +x $out/lib/signergy-fina/SignErgyFina

    # Copy installation files (JRE, certificates, configs)
    cp -r extracted/tmp/SignergyInstallationFilesFina/* $out/share/signergy-fina/

    # Extract bundled JRE
    tar -xzf $out/share/signergy-fina/jre.tar.gz -C $out/share/signergy-fina/
    rm $out/share/signergy-fina/jre.tar.gz

    # Make JRE binaries executable (folder may be JRE or jre depending on archive)
    chmod -R +x $out/share/signergy-fina/jre/bin/ 2>/dev/null || true
    chmod -R +x $out/share/signergy-fina/jre/lib/ 2>/dev/null || true
    chmod -R +x $out/share/signergy-fina/JRE/bin/ 2>/dev/null || true
    chmod -R +x $out/share/signergy-fina/JRE/lib/ 2>/dev/null || true

    # Copy native library
    cp $out/share/signergy-fina/libWebSecTechDll.so $out/lib/signergy-fina/

    # Determine JRE path (folder may be JRE or jre depending on archive)
    JRE_PATH="$out/share/signergy-fina/JRE"
    if [ -d "$out/share/signergy-fina/jre" ]; then
      JRE_PATH="$out/share/signergy-fina/jre"
    fi

    # Create wrapper script
    makeWrapper $out/lib/signergy-fina/SignErgyFina $out/bin/signergy-fina \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}:$out/lib/signergy-fina:$JRE_PATH/lib:$JRE_PATH/lib/server" \
      --set JAVA_HOME "$JRE_PATH" \
      --set SIGNERGY_HOME "$out/share/signergy-fina" \
      --chdir "$out/share/signergy-fina"

    runHook postInstall
  '';

  desktopItems = [ desktopItem ];

  meta = with lib; {
    description = "FINA digital document signing application for Croatian e-services";
    homepage = "https://rdc.fina.hr/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
