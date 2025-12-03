# Kernel Build Script

## 📋 Description

Automated script for building Android kernels with optional support for **KernelSU** and **KernelSU-Next**. Designed to simplify the build process, dependency management, and final kernel packaging.

---

## ✨ Features

### 🔧 Main Features

- **Automated Build**: Compiles Android kernels with simplified configuration
- **KernelSU Support**: Optional integration with KernelSU or KernelSU-Next
- **Dependency Management**: Automatic Clang cloning if not present
- **Smart Cleanup**: Automatically removes previous builds and old KernelSU directories
- **AnyKernel3 Packaging**: Generates flashable ZIP ready for installation
- **Input Validation**: Checks user responses and aborts build on invalid input
- **Error Logging**: Saves compilation errors to `error.log`
- **Build Timer**: Calculates and displays total compilation time

### 🎯 Execution Flow

1. **Pre-cleanup**: Removes old KernelSU/KernelSU-Next directories
2. **Build Type Selection**: 
   - Stock build (without KernelSU)
   - Build with KernelSU
   - Build with KernelSU-Next
3. **Automatic Setup**: Downloads and configures chosen KernelSU version
4. **Compiler Check**: Automatic Clang cloning if needed
5. **Compilation**: Kernel build with LLVM/Clang
6. **Packaging**: Creates flashable ZIP via AnyKernel3
7. **Final Cleanup**: Removes temporary files

---

## 🚀 How to Use

### Prerequisites

- Linux system 
- Git installed
- Android kernel build dependencies
- `AnyKernel3/` directory configured at the same level as the script

### Execution

```bash
chmod +x build.sh
./build.sh
```

### Interactive Options

**1. Include KernelSU?**
```
Do you want to include KernelSU? (y / n)
```
- `y` = Proceed with KernelSU
- `n` = Stock build without root

**2. KernelSU Version (if selected)**
```
KernelSU or KernelSU Next??
 1 to KernelSU
 2 to KernelSU Next
```
- `1` = Official KernelSU (stable)
- `2` = KernelSU-Next (development)

---

## ⚙️ Configuration

### Editable Variables

Locate and edit these variables in the script according to your device:

```bash
DEVICE_CODENAME="stone"                              # Device codename
DEVICE_NAME="POCO X5 5G/Redmi Note 12 5G/Note 12R Pro"  # Market name
KERNEL_NAME="Eclipse"                                # Kernel name
BUILD_STATUS="STABLE"                                # Status: STABLE/TESTING
COMPILER_PATH="$HOME/clang-r547379/bin"             # Compiler path
```

### Expected Directory Structure

```
project/
├── build.sh                    # This script
├── AnyKernel3/                 # AnyKernel3 template
├── arch/arm64/configs/         # Kernel defconfigs
└── error.log                   # Generated on error
```

---

## 📦 Output

### Generated ZIP File

The script automatically generates a ZIP with nomenclature:

- **Stock**: `Eclipse-Kernel-stone-YYYYMMDD.zip`
- **KernelSU**: `Eclipse-Kernel-KSU-stone-YYYYMMDD.zip`
- **KernelSU-Next**: `Eclipse-Kernel-KSU-Next-stone-YYYYMMDD.zip`

### ZIP Contents

- `Image` - Compiled kernel
- `dtb` - Device Tree Blob
- `dtbo.img` - Device Tree Overlay
- AnyKernel3 scripts for installation

---

## 🔍 Required Manual Configuration

### For KernelSU/KernelSU-Next

After automatic setup, you need to:

**Option 1: Add to defconfig**
```
# In arch/arm64/configs/stone_defconfig
CONFIG_KPROBES=y
CONFIG_HAVE_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
```

**Option 2: Add to Makefile**
```makefile
# Before 'all:' target in root Makefile
-include $(srctree)/KernelSU/kernel/Makefile.ext
# or
-include $(srctree)/KernelSU-Next/kernel/Makefile.ext
```

The script enables these configurations automatically via `scripts/config`, but manual configuration ensures persistence between builds.

---

## 🛠️ Compiler

### Clang r547379

- **Auto-download**: Automatic cloning if not found
- **Source**: [crDroid Android Prebuilts](https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379)
- **Branch**: 15.0
- **Configuration**: LLVM=1, LLVM_IAS=1

### Customization

To use another compiler, edit:
```bash
COMPILER_PATH="/path/to/your/compiler/bin"
```

---

## 🐛 Troubleshooting

### Build Fails

1. Check `error.log` for details
2. Confirm all dependencies are installed
3. Verify defconfig is correct

### KernelSU Doesn't Work

1. Verify configurations were added to defconfig
2. Confirm `KernelSU/kernel` or `KernelSU-Next/kernel` exists
3. Reinstall by running the script again

### ZIP Not Generated

1. Check if `AnyKernel3/` exists in correct directory
2. Confirm `Image`, `dtbo.img` and `dtb.img` were compiled
3. Verify write permissions in directory

---

## 📝 Modification Changelog

This script is a modified and improved version with the following changes:

### Implemented Improvements

- ✅ **Automatic Pre-cleanup**: Removes old KernelSU directories before selection
- ✅ **Input Validation**: Checks y/n and 1/2 responses, aborts on invalid input
- ✅ **KernelSU-Next Support**: Additional option besides official KernelSU
- ✅ **Automatic Configuration**: Enables required configs via `scripts/config`
- ✅ **Intelligent Naming**: ZIP named according to chosen build type
- ✅ **Final Pause**: Waits for ENTER before closing terminal
- ✅ **Clean Code**: Removed duplicate code and fixed if/elif/else structure
- ✅ **Improved Messages**: Emojis and formatting for better UX

### Copyright Change Justification

The copyright was changed to **Julival Bittencourt** due to the following substantial modifications:

1. **Complete Refactoring**: Restructuring of flow logic and validations
2. **New Functionalities**: KernelSU-Next support, pre-cleanup, validations
3. **Critical Fixes**: Bug fixes in if/elif/else logic
4. **UX Improvements**: Enhanced interactive interface
5. **Original Code**: Maintains GPL v2 license respecting original license terms

The original script was used as a base, but the modifications represent significant derivative work, justifying the copyright update under GPL terms.

---

## 📄 License

This program is free software; you can redistribute it and/or modify it under the terms of the **GNU General Public License v2** as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of **MERCHANTABILITY** or **FITNESS FOR A PARTICULAR PURPOSE**. See the GNU General Public License for more details.

---

## Development

- **Author**: Julival Bittencourt
- **License**: GNU GPL v2
- **Year**: 2025
### 🙏 Credits
### Acknowledgments

Script based on original work by:
- **Amrita Das** - <bhabanidas431@gmail.com>

Special thanks to the communities:
- [KernelSU](https://github.com/tiann/KernelSU) - Kernel-level root framework
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) - KernelSU development fork
- [AnyKernel3](https://github.com/osm0sis/AnyKernel3) - Universal kernel installation template
- [crDroid Android](https://crdroid.net/) - Clang toolchain

---

## 📞 Support

To report issues or suggest improvements, open an issue in the project repository.
