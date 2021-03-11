{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, pkg-config
, tcl
}:

stdenv.mkDerivation rec {
  pname = "openocd-rp2040";
  version = "2021-02-03";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "openocd";
    rev = "f8e14ec97b0d98c8e2ffdd08ab5ff9537f1c9a63";
    sha256 = "cyTzS2DwUjjJqmjTrIsj41+eUKmcP2ztxp76KHoGwd4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ autoreconfHook pkg-config tcl ];

  configureFlags = [
    "--enable-sysfsgpio"
    "--enable-bcm2835gpio"
  ];

  NIX_CFLAGS_COMPILE = [
    "-Wno-error=cpp"
    "-Wno-error=strict-prototypes" # fixes build failure with hidapi 0.10.0
  ];

  meta = with lib; {
    description = "Free and Open On-Chip Debugging, In-System Programming and Boundary-Scan Testing";
    longDescription = ''
      OpenOCD provides on-chip programming and debugging support with a layered
      architecture of JTAG interface and TAP support, debug target support
      (e.g. ARM, MIPS), and flash chip drivers (e.g. CFI, NAND, etc.).  Several
      network interfaces are available for interactiving with OpenOCD: HTTP,
      telnet, TCL, and GDB.  The GDB server enables OpenOCD to function as a
      "remote target" for source-level debugging of embedded systems using the
      GNU GDB program.
    '';
    homepage = "https://openocd.sourceforge.net/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ bjornfor ];
    platforms = platforms.unix;
  };
}
