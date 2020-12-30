{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux = rec {
      x86-image = nixpkgs.legacyPackages.x86_64-linux.callPackage ./. {};
      arm-image = let
        thumbPkgs = (import nixpkgs {
          system = "x86_64-linux";
          crossSystem = nixpkgs.lib.systems.examples.raspberryPi // {
            config = "armv6l-unknown-linux-musleabi";
            isStatic = true;
          };
          crossOverlays = [ (import "${nixpkgs}/pkgs/top-level/static.nix") (import ./busybox-musl-overlay) (import ./small-arm.nix true) ];
        });
        armPkgs = (import nixpkgs {
          system = "x86_64-linux";
          crossSystem = nixpkgs.lib.systems.examples.raspberryPi // {
            config = "armv6l-unknown-linux-musleabi";
            isStatic = true;
          };
          crossOverlays = [ (import "${nixpkgs}/pkgs/top-level/static.nix") (import ./busybox-musl-overlay) (import ./small-arm.nix false) ];
        });
      in thumbPkgs.callPackage ./. {
        inherit (nixpkgs.legacyPackages.x86_64-linux) qemu;
        inherit armPkgs;
      };
      arm-kernel = arm-image.kernel;
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.arm-image;

  };
}
