{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux = rec {
      x86-image = nixpkgs.legacyPackages.x86_64-linux.callPackage ./. {};
      arm-image = (import nixpkgs {
        system = "x86_64-linux";
        crossSystem = nixpkgs.lib.systems.examples.muslpi // {
          isStatic = true;
        };
        crossOverlays = [ (import "${nixpkgs}/pkgs/top-level/static.nix") (import ./busybox-musl-overlay) ];
      }).callPackage ./. {
        inherit (nixpkgs.legacyPackages.x86_64-linux) qemu;
        #buildPackages = nixpkgs.legacyPackages.x86_64-linux;
      };
      arm-kernel = arm-image.kernel;
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.arm-image;

  };
}
