#!/bin/bash
# Build standalone del GKI para sapphire (Redmi Note 13 4G)
ROOT=/serverhive/angelpro09/sapphire-kernel
LOG=$ROOT/kbuild.log
export TMPDIR=$ROOT/tmp
export PATH=$ROOT/toolchain/clang/bin:$PATH
export ARCH=arm64
export KCONFIG_NOSILENTUPDATE=1
mkdir -p "$TMPDIR"
cd "$ROOT/kernel_xiaomi_sapphire" || exit 1
: > "$LOG"
M="make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1"
# < /dev/null: si Kconfig pregunta algo, aborta en vez de colgarse
$M sapphire_defconfig >> "$LOG" 2>&1 < /dev/null
$M olddefconfig       >> "$LOG" 2>&1 < /dev/null
$M -j"$(nproc)" Image >> "$LOG" 2>&1 < /dev/null
RC=$?
echo "=============================="
if [ $RC -eq 0 ] && [ -f out/arch/arm64/boot/Image ]; then
  echo "BUILD OK - Image: $(ls -lh out/arch/arm64/boot/Image | awk '{print $5}')"
else
  echo "BUILD FALLO (rc=$RC). Errores:"
  grep -nE 'error:|Error [0-9]|undefined|No rule to make|fatal|\(NEW\)' "$LOG" | head -25
fi
echo "log: $LOG"
echo "=============================="
