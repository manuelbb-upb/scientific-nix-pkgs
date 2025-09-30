{
  pkgs,
}:
(with pkgs; [
  freetype
  cacert
  alsa-lib # libasound2
  atk
  glib
  glibc
  cairo
  cups
  dbus
  fontconfig
  gdk-pixbuf
  gst_all_1.gst-plugins-base
  gst_all_1.gstreamer
  gtk3
  nspr
  nss
  pam
  pango
  python3
  libselinux
  libsndfile
  glibcLocales
  procps
  unzip
  zlib
  linux-pam

  libgcc.lib

  # These packages are needed since 2021b version
  #gnome2.gtk
  gtk2
  at-spi2-atk
  at-spi2-core
  libdrm

  mesa

  gcc
  gfortran

  # nixos specific
  udev
  jre
  ncurses # Needed for CLI

  # Keyboard input may not work in simulink otherwise
  libxkbcommon
  xkeyboard_config

  # Needed since 2022a
  libglvnd

  # Needed since 2022b
  libuuid
  libxcrypt
  libxcrypt-legacy

  # 2024
  libgbm
]) ++ (with pkgs.xorg; [
  libSM
  libX11
  libxcb
  libXcomposite
  libXcursor
  libXdamage
  libXext
  libXfixes
  libXft
  libXi
  libXinerama
  libXrandr
  libXrender
  libXt
  libXtst
  libXxf86vm

  # Needed since 2025
  libICE
])
