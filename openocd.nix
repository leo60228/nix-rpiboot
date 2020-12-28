{ stdenv
, lib
, fetchgit
, autoreconfHook
, pkg-config
, tcl
}:

stdenv.mkDerivation rec {
  pname = "openocd";
  version = "unstable-2020-11-11";

  src = fetchgit {
    url = "https://git.code.sf.net/p/openocd/code";
    rev = "06c7a53f1fff20bcc4be9e63f83ae98664777f34";
    sha256 = "0g0w7g94r88ylfpwswnhh8czlf5iqvd991ssn4gfcfd725lpdb01";
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
