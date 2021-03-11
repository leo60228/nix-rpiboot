{ stdenv, qemu, callPackage, linux, armPkgs, linuxPackages_rpi0, targetPlatform, raspberrypifw, writeShellScriptBin, runCommandNoCC }:

let
  qemuMachine = if targetPlatform.isx86 then "-append console=ttyS0 -nographic" else " -cpu arm1176 -m 256 -M versatilepb -serial stdio";
  qemu-runner = writeShellScriptBin "qemu-runner" ''
exec ${qemu}/bin/qemu-system-${targetPlatform.qemuArch} ${qemuMachine} -kernel "$1" -dtb "$2" -initrd "$(dirname "$0")/../image.img"
'';
  kernel = if targetPlatform.isx86 then linux else armPkgs.linuxManualConfig {
    inherit (linuxPackages_rpi0.kernel) src version modDirVersion;
    stdenv = armPkgs.stdenv;
    configfile = ./kernel-config;
  };
in runCommandNoCC "rpiboot" {
  passthru = {
    inherit kernel;
  };
} ''
mkdir -p $out/bin
cp ${callPackage ./initrd.nix {}}/initrd $out/image.img
cp ${kernel}/*zImage $out/kernel.img
cp ${raspberrypifw}/share/raspberrypi/boot/*.elf $out
cp ${raspberrypifw}/share/raspberrypi/boot/*.dat $out
cp ${./bootcode.bin} $out
cp -r ${raspberrypifw}/share/raspberrypi/boot/overlays $out
cp ${raspberrypifw}/share/raspberrypi/boot/*.dtb $out
cp ${qemu-runner}/bin/* $out/bin
echo 'console=ttyAMA0,115200 earlyprintk panic=-1' > $out/cmdline.txt
cat << EOF > $out/config.txt
dtoverlay=dwc2,dr_mode=peripheral
enable_uart=1
uart_2ndstage=1
hdmi_ignore_edid=0xa5000080
hdmi_ignore_cec=1
hdmi_ignore_hotplug=1
boot_delay=0
disable_splash=1
dtoverlay=miniuart-bt

kernel=kernel.img
initramfs image.img
EOF
''
