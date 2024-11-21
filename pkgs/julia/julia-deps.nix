# It actually looks like we don't need this file...
# TODO check in a few weeks and delete
{
  pkgs,
}:
with pkgs; [
  # These are copied from `scientific-fhs` LD_LIBRARY_PATH:
  stdenv.cc.cc
  zlib
  glib
  xorg.libXi
  xorg.libxcb
  xorg.libXrender
  xorg.libX11
  xorg.libSM
  xorg.libICE
  xorg.libXext
  dbus
  fontconfig
  freetype
  libGL
  # `curl` just to be sure
  curl.out
  libssh2
]
/*with pkgs; [
    stdenv.cc.cc
    curl
    zlib
    glib
    glib.out
    wayland
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXrender
    xorg.libXt
    xorg.libXtst
    xorg.libXxf86vm
    xorg.libxcb
    xorg.libxkbfile
    xorg.xorgproto

    libcap
    libdrm
    libgnome-keyring3
    libgpg-error
    libnotify
    libpng
    libsecret
    libselinux
    libuuid
    libxkbcommon
    libGL

    mesa

    dbus
    fontconfig
    freetype

    openssl.out
    zstd.out
]*/
