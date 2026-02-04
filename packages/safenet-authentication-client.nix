# SafeNet Authentication Client
#
# Purpose: Smart card and token authentication client (eToken support)
#
# Source: https://rdc.fina.hr/download/Linux.zip
# Version: 10.9.4723
#
# This package provides:
# - SACTools: Token management GUI application
# - SACMonitor: System tray token monitor
# - SACSrv: Background service for token communication
# - PKCS#11 libraries for browser/application integration
#
# Usage in configuration.nix:
#   environment.systemPackages = [
#     (pkgs.callPackage ./packages/safenet-authentication-client.nix { })
#   ];
#
# For PKCS#11 integration (e.g., Firefox), point to:
#   /run/current-system/sw/lib/libeToken.so
#
# Systemd service (optional):
#   systemd.packages = [ safenet-authentication-client ];

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
, gtk3
, glib
, gdk-pixbuf
, pango
, cairo
, atk
, at-spi2-atk
, at-spi2-core
, dbus
, xorg
, libusb1
, pcsclite
, openssl
, fontconfig
, freetype
}:

let
  version = "10.9.4723";

  desktopItemTools = makeDesktopItem {
    name = "safenet-sac-tools";
    desktopName = "SafeNet Authentication Client Tools";
    comment = "Manage smart cards and tokens";
    exec = "SACTools";
    icon = "safenet-sac";
    categories = [ "Utility" "Security" ];
  };

  desktopItemMonitor = makeDesktopItem {
    name = "safenet-sac-monitor";
    desktopName = "SafeNet Token Monitor";
    comment = "Monitor smart card and token status";
    exec = "SACMonitor";
    icon = "safenet-sac";
    categories = [ "Utility" "Security" ];
  };
in
stdenv.mkDerivation rec {
  pname = "safenet-authentication-client";
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
    gtk3
    glib
    gdk-pixbuf
    pango
    cairo
    atk
    at-spi2-atk
    at-spi2-core
    dbus
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXtst
    xorg.libXi
    libusb1
    pcsclite
    openssl
    fontconfig
    freetype
  ];

  # The package includes versioned .so files that need to be available
  # as both versioned and unversioned
  autoPatchelfIgnoreMissingDeps = [
    "libeToken.so.10"
    "libSACUI.so.10"
    "libSACLog.so.10"
  ];

  unpackPhase = ''
    runHook preUnpack
    unzip $src
    # Use Ubuntu 22.04 version (most recent)
    dpkg-deb -x "10.9 GA/Ubuntu-2204/safenetauthenticationclient_${version}_amd64.deb" extracted
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/lib
    mkdir -p $out/lib/pkcs11
    mkdir -p $out/etc
    mkdir -p $out/share/eToken
    mkdir -p $out/share/doc/safenetauthenticationclient
    mkdir -p $out/lib/systemd/system

    # Copy binaries
    cp extracted/usr/bin/* $out/bin/

    # Copy libraries
    cp extracted/usr/lib/*.so.* $out/lib/
    cp -r extracted/usr/lib/SAC $out/lib/
    
    # Create symlinks for versioned libraries
    ln -sf libeToken.so.${version} $out/lib/libeToken.so.10
    ln -sf libeToken.so.10 $out/lib/libeToken.so
    ln -sf libSACUI.so.${version} $out/lib/libSACUI.so.10
    ln -sf libSACUI.so.10 $out/lib/libSACUI.so
    ln -sf libSACLog.so.${version} $out/lib/libSACLog.so.10
    ln -sf libSACLog.so.10 $out/lib/libSACLog.so
    
    # Create PKCS#11 symlinks (for browser integration)
    ln -sf ../libeToken.so $out/lib/pkcs11/libeToken.so
    ln -sf ../libIDPrimePKCS11.so.${version} $out/lib/pkcs11/libIDPrimePKCS11.so

    # Copy config files
    cp extracted/etc/eToken*.conf $out/etc/

    # Copy language/resource files
    cp -r extracted/usr/share/eToken/* $out/share/eToken/

    # Copy documentation
    cp -r extracted/usr/share/doc/safenetauthenticationclient/* $out/share/doc/safenetauthenticationclient/

    # Copy systemd service (modified for NixOS paths)
    cat > $out/lib/systemd/system/SACSrv.service << EOF
    [Unit]
    Description=SafeNet Authentication Client Service
    After=pcscd.service

    [Service]
    Type=simple
    ExecStart=$out/bin/SACSrv
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    EOF

    # Wrap binaries with library paths
    for binary in SACTools SACMonitor SACSrv; do
      wrapProgram $out/bin/$binary \
        --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}" \
        --set SAC_SHARE_PATH "$out/share/eToken"
    done

    # Wrap SACUIProcess
    wrapProgram $out/lib/SAC/SACUIProcess \
      --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}" \
      --set SAC_SHARE_PATH "$out/share/eToken"

    runHook postInstall
  '';

  desktopItems = [
    desktopItemTools
    desktopItemMonitor
  ];

  meta = with lib; {
    description = "SafeNet Authentication Client for smart cards and tokens (eToken)";
    homepage = "https://rdc.fina.hr/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
