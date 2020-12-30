thumb:

self: super:

if super.targetPlatform.isx86 then throw "Can't build THUMB for non-ARM!" else {
  stdenv = super.addAttrsToDerivation {
    NIX_CFLAGS_COMPILE = "-Os" + (if thumb then " -mthumb" else "");
  } super.stdenv;
}
