#!/bin/bash
# Verifica que TODO lo que piden los .ko stock este disponible:
#   exportado por el vmlinux nuevo, o definido por otro modulo del set stock.
ROOT=/serverhive/angelpro09/sapphire-kernel
K=$ROOT/kernel_xiaomi_sapphire
NM=$ROOT/toolchain/clang/bin/llvm-nm
REQ=$K/abi-reference/required-symbols.txt
V=$K/out/vmlinux
[ -f "$V" ] || { echo "falta $V"; exit 1; }
T=$(mktemp -d "$ROOT/tmp/kmiXXXX")
# 1) exportados por el kernel nuevo (__ksymtab_NAME)
"$NM" "$V" 2>/dev/null | awk '{print $NF}' | grep '^__ksymtab_' | sed 's/^__ksymtab_//' | sort -u > "$T/vmlinux_exports"
# 2) definidos por los propios modulos stock
find "$ROOT/prebuilt"/vendor_dlkm "$ROOT/prebuilt"/vendor_ramdisk "$ROOT/prebuilt"/system_dlkm -name '*.ko' 2>/dev/null \
  | xargs -r "$NM" --defined-only 2>/dev/null | awk 'NF==3{print $3}' | sort -u > "$T/mod_defs"
sort -u "$T/vmlinux_exports" "$T/mod_defs" > "$T/have"
comm -23 "$REQ" "$T/have" > "$T/missing"
echo "requeridos por los .ko : $(wc -l < "$REQ")"
echo "exportados por vmlinux : $(wc -l < "$T/vmlinux_exports")"
echo "definidos por modulos  : $(wc -l < "$T/mod_defs")"
echo "-----------------------------------------"
M=$(wc -l < "$T/missing")
if [ "$M" -eq 0 ]; then
  echo "FALTANTES: 0  -> KMI COMPATIBLE, los modulos stock deberian cargar"
else
  echo "FALTANTES: $M"
  head -40 "$T/missing"
fi
rm -rf "$T"
