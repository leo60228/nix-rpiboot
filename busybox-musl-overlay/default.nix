self: super:
{
  busybox = super.busybox.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches ++ [
      ./0001-date-Use-64-prefix-syscall-if-we-have-to.patch
      ./0002-time-Use-64-prefix-syscall-if-we-have-to.patch
      ./0003-runsv-Use-64-prefix-syscall-if-we-have-to.patch
      ./0004-Remove-syscall-wrappers-around-clock_gettime-closes-.patch
    ];
  });
}
