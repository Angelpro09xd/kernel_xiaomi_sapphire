# kernel_xiaomi_sapphire

Linux kernel source for the **Xiaomi Redmi Note 13 4G** (`sapphire` / `sapphiren`).

SoC: Qualcomm SM6225-AD (Snapdragon 685, `khaje`/`bengal`) · GKI `android13-5.15`, KMI generation 8.

## Why this tree exists

Xiaomi has never published kernel sources for this device. As of September 2026 there is
no `sapphire` branch in [MiCode/Xiaomi_Kernel_OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource),
roughly 2 years and 8 months after launch, despite numerous requests
(issues #40344, #40347, #40364, #40365, #40368, #40372, #40379, #40380, #40385, #40851).

This tree reconstructs a complete, buildable kernel for the device from sources that *are*
available, plus device trees recovered from the shipped firmware.

## Composition and provenance

| Component | Source |
|---|---|
| GKI core | `android13-5.15` LTS, based on [chickendrop89/device_xiaomi_unified-kernel](https://github.com/chickendrop89/device_xiaomi_unified-kernel) (git history preserved) |
| Xiaomi drivers (`nopmi`, `sm5602`, `bq2589x`, `sc8551`, `ds28e16`) | same, shared with `topaz`/`tapas` (Redmi Note 12 4G) |
| Platform device trees (bengal/khaje) | [MiCode/kernel_devicetree](https://github.com/MiCode/kernel_devicetree) branch `creek-v-oss` |
| Board device trees (`sapphire`, `sapphiren`) | **reconstructed from the device's own `dtbo.img`** — see below |
| Display uAPI headers | this device's shipped headers (sapphire-specific; the `creek` variants lack `LOCAL_HBM_UI_READY`) |
| Audio uAPI headers | [MiCode/vendor_qcom_opensource_audio-kernel](https://github.com/MiCode/vendor_qcom_opensource_audio-kernel) branch `topaz-t-oss` |

## Device tree reconstruction

`arch/arm64/boot/dts/xiaomi/sapphire/{sapphire,sapphiren}.dtsi` were rebuilt from the
stock `dtbo.img`. A DTBO compiled with symbols carries its own symbol table in the
`__fixups__` node, so every fragment target and every internal phandle reference could be
resolved back to its label mechanically — no guesswork against the platform sources.

Verified by compiling the reconstruction, applying it to the stock base DTB with
`fdtoverlay`, and comparing the resulting tree against the one produced by Xiaomi's
own DTBO:

| | sapphire | sapphiren |
|---|---|---|
| fragments resolved to labels | 46 / 46 | 47 / 47 |
| nodes | 2292 / 2292 (100%) | 2293 / 2293 (100%) |
| properties | 9433 / 9433 (100%) | 9444 / 9444 (100%) |
| property values differing (non-phandle) | 0 | 0 |

Remaining differences are phandle renumbering only, which is semantically equivalent.

## Building

Standalone:

```sh
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 sapphire_defconfig
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 -j"$(nproc)" Image
```

`verify-kmi.sh` checks that the built kernel exports every symbol the device's stock
vendor modules require (3732 symbols across 485 `.ko` files). None of them are
Xiaomi-proprietary — the five that look like it are provided module-to-module by
`xiaomi_touch_game.ko` and `mi_thermal_interface.ko`, not by the kernel.

In an AOSP tree, set in `BoardConfig.mk`:

```make
TARGET_KERNEL_SOURCE := kernel/xiaomi/sapphire
TARGET_KERNEL_CONFIG := sapphire_defconfig
TARGET_KERNEL_CLANG_COMPILE := true
TARGET_KERNEL_LLVM_BINUTILS := true
```

Note: ccache is opt-in (`KERNEL_USE_CCACHE=1`). AOSP's `sbox` sandbox forbids ccache,
so it must stay off for in-tree builds.

## Status

The kernel builds and is KMI-verified against the stock module set. The device trees are
byte-for-byte equivalent in structure and values to the originals. **This has not yet been
boot-tested on hardware.** Back up `boot` and `dtbo` before flashing.

## License

GPL-2.0, as the Linux kernel. Sources incorporated from the projects listed above retain
their original licenses and authorship.
