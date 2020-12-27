{ stdenv, makeInitrd, writeScript, busybox }:
makeInitrd {
  name = "rootfs";
  contents = [ {
    symlink = "/init";
    object = let
      bin = stdenv.mkDerivation {
        name = "init";
        src = ./init;
        installPhase = ''
        mkdir -p $out/bin
        cp ./init $out/bin
        '';
      };
    in "${bin}/bin/init";
  } ];
}
