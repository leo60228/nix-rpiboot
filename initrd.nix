{ stdenv, makeInitrd, writeScript, busybox, callPackage, autoreconfHook }:
makeInitrd {
  name = "rootfs";
  contents = [ {
    symlink = "/init";
    object = let
      bin = stdenv.mkDerivation {
        name = "init";
        src = ./init;
        preBuild = ''
        makeFlagsArray+=(CFLAGS='-DOPENOCD=\"${callPackage ./openocd.nix {}}/bin/openocd\" -DOPENOCD_SCRIPT=\"${./tcp.tcl}\"')
        '';
        installPhase = ''
        mkdir -p $out/bin
        cp ./init $out/bin
        '';
      };
    in "${bin}/bin/init";
  } ];
}
