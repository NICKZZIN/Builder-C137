#!/bin/bash

#
# Copyright (C) 2025 Julival Bittencourt
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation;
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
# Clone Kernel
git clone https://github.com/NICKZZIN/KERNEL_STONE -b lineage-23.2 kernel --depth=1

# Copy AnyKernel to kernel dir.
cp -r AnyKernel3 kernel/AnyKernel3

 # Backup files
 echo "Backup files ..."
 mkdir -p bkp/{drivers,fs,include/linux}
cp kernel/drivers/Kconfig bkp/drivers/Kconfig
cp kernel/drivers/Makefile bkp/drivers/Makefile 
cp kernel/fs/internal.h bkp/fs/internal.h 
cp kernel/fs/namespace.c bkp/fs/namespace.c 
cp kernel/include/linux/seccomp.h bkp/include/linux/seccomp.h

# Move to Kernel Path
cd kernel

# Remove old KernelSU-Next/KernelSU directories if exists
if [ -d "$PWD/KernelSU-Next" ]; then
      echo "Removing old KernelSU-Next directory..."
       rm -rf $PWD/KernelSU-Next
elif [ -d "$PWD/KernelSU" ]; then
      echo "Removing old KernelSU directory..."
      rm -rf $PWD/KernelSU
else
     echo "No Old KernelSU directory found!"
fi

# Read KernelSU.
echo "Do you want to include KernelSU? (y / n)"
read KernelSU

if [ "$KernelSU" = "y" ]; then
    echo "KernelSU or KernelSU Next?? "
    echo " 1 to KernelSU"
    echo " 2 to KernelSU Next"
    read KSU
    
    if [ "$KSU" = "1" ]; then
 # Setup KernelSU using official setup script
        echo "Setting up KernelSU..."
        if ! curl -LSs "https://raw.githubusercontent.com/bittencourtjulival/KernelSU/master/kernel/setup.sh" | bash -s; then
            echo "❌ Failed to setup KernelSU!"
            exit 1
        fi
        echo "✅ KernelSU setup completed!"
        
    elif [ "$KSU" = "2" ]; then
# Setup KernelSU-Next using official setup script
        echo "Setting up KernelSU-Next..."
        if ! curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s; then
            echo "❌ Failed to setup KernelSU-Next!"
            exit 1
        fi
        echo "✅ KernelSU-Next setup completed!"
        
    else
        echo "❌ Invalid option! Please choose 1 or 2."
        exit 1
    fi

    # Detect which directory was created (KernelSU or KernelSU-Next)
    KERNELSU_DIR=""
    if [ -d "$PWD/KernelSU-Next" ]; then
        KERNELSU_DIR="$PWD/KernelSU-Next"
        echo "📁 Using KernelSU-Next directory"
    elif [ -d "$PWD/KernelSU" ]; then
        KERNELSU_DIR="$PWD/KernelSU"
        echo "📁 Using KernelSU directory"
    else
        echo "❌ KernelSU directory not found!"
        exit 1
    fi

    # Manual configuration info
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  Manual configuration required for KernelSU!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Add to your defconfig (arch/arm64/configs/${DEVICE_CODENAME}_defconfig):"
    echo ""
    echo "   CONFIG_KPROBES=y"
    echo "   CONFIG_HAVE_KPROBES=y"
    echo "   CONFIG_KPROBE_EVENTS=y"
    echo "   CONFIG_MODULES=y"
    echo "   CONFIG_MODULE_UNLOAD=y"
    echo ""
    echo "Or add to your kernel Makefile before 'all:' target:"
    if [ -d "$PWD/KernelSU-Next" ]; then
        echo "   -include \$(srctree)/KernelSU-Next/kernel/Makefile.ext"
    else
        echo "   -include \$(srctree)/KernelSU/kernel/Makefile.ext"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Press ENTER to continue with the build..."
    read

    # Verify KernelSU directory structure
    echo ""
    echo "Verifying KernelSU installation..."
    if [ -d "$KERNELSU_DIR/kernel" ]; then
        echo "✅ $KERNELSU_DIR/kernel directory found"
        echo "✅ KernelSU is ready!"
    else
        echo "❌ KernelSU installation incomplete!"
        exit 1
    fi
else
    echo "Build Non KernelSU Selected"
fi

echo ""

# Set Kernel Build Variables
DEVICE_CODENAME="stone"  # Device codename (e.g., veux, garnet, etc.)
DEVICE_NAME="POCO X5 5G/Redmi Note 12 5G/Note 12R Pro"          # Device Market name
KERNEL_NAME="C137"    # Kernel name
KERNEL_DEFCONFIG="${DEVICE_CODENAME}_defconfig"
ANYKERNEL3_DIR=$PWD/AnyKernel3/

if [ "$KernelSU" = "y" ]; then
    if [ "$KSU" = "1" ]; then
        KSU_TYPE="KSU"
    else
        KSU_TYPE="KSU-Next"
    fi
    FINAL_KERNEL_ZIP="${KERNEL_NAME}-Kernel-${KSU_TYPE}-${DEVICE_CODENAME}-$(date '+%Y%m%d').zip"
else
    FINAL_KERNEL_ZIP="${KERNEL_NAME}-Kernel-${DEVICE_CODENAME}-$(date '+%Y%m%d').zip"
fi

# Set Build Status (Change to "STABLE/TESTING" if needed)
BUILD_STATUS="STABLE"

# Get Hostname
BUILD_HOSTNAME=$(hostname)

# Set Compiler Path (Change if needed)
COMPILER_PATH="$HOME/clang-r547379/bin"

# Dynamically detect compiler name & version
if [ -d "$COMPILER_PATH" ]; then
    export PATH="$COMPILER_PATH:$PATH"
    COMPILER_NAME="$($COMPILER_PATH/clang --version | head -n 1 | sed -E 's/\(.*\)//' | awk '{$1=$1;print}')"
else
    COMPILER_NAME="Unknown Compiler"
fi

export ARCH=arm64
export KBUILD_BUILD_HOST=$BUILD_HOSTNAME
export KBUILD_BUILD_USER="Julival"
export KBUILD_COMPILER_STRING="$COMPILER_NAME"

# Clone Clang if not found
if ! [ -d "$HOME/clang-r547379" ]; then
    echo "⚙️ Clang not found! Cloning..."
    if ! git clone -q https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git -b 15.0 --depth=1 --single-branch ~/clang-r547379; then
        echo "❌ Cloning failed! Aborting..."
        exit 1
    fi
fi

# Start Build Process
BUILD_START=$(date +"%s")

if [ "$KernelSU" = "y" ]; then
    if [ "$KSU" = "1" ]; then
        BUILD_TYPE="KernelSU"
    else
        BUILD_TYPE="KernelSU-Next"
    fi
else
    BUILD_TYPE="Stock"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 ${KERNEL_NAME} Kernel Build Started!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Device: ${DEVICE_NAME} (${DEVICE_CODENAME})"
echo "🖥️ Building on: $(hostname)"
echo "⚙️ Compiler: ${COMPILER_NAME}"
echo "📰 Build Status: ${BUILD_STATUS}"
echo "🛠️ Build Type: ${BUILD_TYPE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
make O=out clean

# Set Defconfig
echo "⚙️ Setting up defconfig..."
make $KERNEL_DEFCONFIG O=out

# Enable KernelSU configurations if selected
if [ "$KernelSU" = "y" ]; then
    echo "🔧 Enabling KernelSU configurations in .config..."
    scripts/config --file out/.config \
        -e KPROBES \
        -e HAVE_KPROBES \
        -e KPROBE_EVENTS \
        -e MODULES \
        -e MODULE_UNLOAD

    # Regenerate .config
    echo "🔄 Regenerating .config..."
    make O=out olddefconfig
fi

# Compile Kernel
echo ""
echo "🔨 Starting kernel compilation..."
echo ""

make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                LD=ld.lld \
                LLVM=1 \
                LLVM_IAS=1 \
                2> error.log

# Check for compiled files
if [ ! -f "$PWD/out/arch/arm64/boot/Image" ]; then
    echo ""
    echo "❌ Build failed! Image not found."
    exit 1
fi

echo ""
echo "✅ ${KERNEL_NAME} Kernel built successfully! Zipping files..."

# Move files to AnyKernel3
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb
cp $PWD/out/arch/arm64/boot/Image $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtb.img $ANYKERNEL3_DIR/dtb

# Zip Kernel
cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

BUILD_END=$(date +"%s")
BUILD_TIME=$((BUILD_END - BUILD_START))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build Completed Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Kernel ZIP: $FINAL_KERNEL_ZIP"
echo "⏱️ Build time: $(($BUILD_TIME / 60)) min $(($BUILD_TIME % 60)) sec"
echo "🛠️ Build Type: ${BUILD_TYPE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean up
echo "🧹 Cleaning up..."
rm -rf out/
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb

echo "✅ All done!"
exit 0
    if [ "$KSU" = "1" ]; then
    
    echo "KernelSU or KernelSU Next?? "
    echo " 1 to KernelSU"
    echo " 2 to KernelSU Next"
    read KSU

 # Setup KernelSU using official setup script
        echo "Setting up KernelSU..."
        if ! curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s; then
            echo "❌ Failed to setup KernelSU!"
            exit 1
        fi
        echo "✅ KernelSU setup completed!"
        
    elif [ "$KSU" = "2" ]; then
# Setup KernelSU-Next using official setup script
        echo "Setting up KernelSU-Next..."
        if ! curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s; then
            echo "❌ Failed to setup KernelSU-Next!"
            exit 1
        fi
        echo "✅ KernelSU-Next setup completed!"
        
    else
        echo "❌ Invalid option! Please choose 1 or 2."
        exit 1
    fi

    # Detect which directory was created (KernelSU or KernelSU-Next)
    KERNELSU_DIR=""
    if [ -d "$PWD/KernelSU-Next" ]; then
        KERNELSU_DIR="$PWD/KernelSU-Next"
        echo "📁 Using KernelSU-Next directory"
    elif [ -d "$PWD/KernelSU" ]; then
        KERNELSU_DIR="$PWD/KernelSU"
        echo "📁 Using KernelSU directory"
    else
        echo "❌ KernelSU directory not found!"
        exit 1
    fi

    # Manual configuration info
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  Manual configuration required for KernelSU!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Add to your defconfig (arch/arm64/configs/${DEVICE_CODENAME}_defconfig):"
    echo ""
    echo "   CONFIG_KPROBES=y"
    echo "   CONFIG_HAVE_KPROBES=y"
    echo "   CONFIG_KPROBE_EVENTS=y"
    echo "   CONFIG_MODULES=y"
    echo "   CONFIG_MODULE_UNLOAD=y"
    echo ""
    echo "Or add to your kernel Makefile before 'all:' target:"
    if [ -d "$PWD/KernelSU-Next" ]; then
        echo "   -include \$(srctree)/KernelSU-Next/kernel/Makefile.ext"
    else
        echo "   -include \$(srctree)/KernelSU/kernel/Makefile.ext"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Press ENTER to continue with the build..."
    read

    # Verify KernelSU directory structure
    echo ""
    echo "Verifying KernelSU installation..."
    if [ -d "$KERNELSU_DIR/kernel" ]; then
        echo "✅ $KERNELSU_DIR/kernel directory found"
        echo "✅ KernelSU is ready!"
    else
        echo "❌ KernelSU installation incomplete!"
        exit 1
    fi
else
    echo "Build Non KernelSU Selected"
fi

echo ""

# Set Kernel Build Variables
DEVICE_CODENAME="stone"  # Device codename (e.g., veux, garnet, etc.)
DEVICE_NAME="POCO X5 5G/Redmi Note 12 5G/Note 12R Pro"          # Device Market name
KERNEL_NAME="Eclipse"    # Kernel name
KERNEL_DEFCONFIG="${DEVICE_CODENAME}_defconfig"
ANYKERNEL3_DIR=$PWD/AnyKernel3/

if [ "$KernelSU" = "y" ]; then
    if [ "$KSU" = "1" ]; then
        KSU_TYPE="KSU"
    else
        KSU_TYPE="KSU-Next"
    fi
    FINAL_KERNEL_ZIP="${KERNEL_NAME}-Kernel-${KSU_TYPE}-${DEVICE_CODENAME}-$(date '+%Y%m%d').zip"
else
    FINAL_KERNEL_ZIP="${KERNEL_NAME}-Kernel-${DEVICE_CODENAME}-$(date '+%Y%m%d').zip"
fi

# Set Build Status (Change to "STABLE/TESTING" if needed)
BUILD_STATUS="STABLE"

# Get Hostname
BUILD_HOSTNAME=$(hostname)

# Set Compiler Path (Change if needed)
COMPILER_PATH="$HOME/clang-r547379/bin"

# Dynamically detect compiler name & version
if [ -d "$COMPILER_PATH" ]; then
    export PATH="$COMPILER_PATH:$PATH"
    COMPILER_NAME="$($COMPILER_PATH/clang --version | head -n 1 | sed -E 's/\(.*\)//' | awk '{$1=$1;print}')"
else
    COMPILER_NAME="Unknown Compiler"
fi

export ARCH=arm64
export KBUILD_BUILD_HOST=$BUILD_HOSTNAME
export KBUILD_BUILD_USER="Julival"
export KBUILD_COMPILER_STRING="$COMPILER_NAME"

# Clone Clang if not found
if ! [ -d "$HOME/clang-r547379" ]; then
    echo "⚙️ Clang not found! Cloning..."
    if ! git clone -q https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git -b 15.0 --depth=1 --single-branch ~/clang-r547379; then
        echo "❌ Cloning failed! Aborting..."
        exit 1
    fi
fi

# Start Build Process
BUILD_START=$(date +"%s")

if [ "$KernelSU" = "y" ]; then
    if [ "$KSU" = "1" ]; then
        BUILD_TYPE="KernelSU"
    else
        BUILD_TYPE="KernelSU-Next"
    fi
else
    BUILD_TYPE="Stock"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 ${KERNEL_NAME} Kernel Build Started!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Device: ${DEVICE_NAME} (${DEVICE_CODENAME})"
echo "🖥️ Building on: $(hostname)"
echo "⚙️ Compiler: ${COMPILER_NAME}"
echo "📰 Build Status: ${BUILD_STATUS}"
echo "🛠️ Build Type: ${BUILD_TYPE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
make O=out clean

# Set Defconfig
echo "⚙️ Setting up defconfig..."
make $KERNEL_DEFCONFIG O=out

# Enable KernelSU configurations if selected
if [ "$KernelSU" = "y" ]; then
    echo "🔧 Enabling KernelSU configurations in .config..."
    scripts/config --file out/.config \
        -e KPROBES \
        -e HAVE_KPROBES \
        -e KPROBE_EVENTS \
        -e MODULES \
        -e MODULE_UNLOAD

    # Regenerate .config
    echo "🔄 Regenerating .config..."
    make O=out olddefconfig
fi

# Compile Kernel
echo ""
echo "🔨 Starting kernel compilation..."
echo ""

make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                LD=ld.lld \
                LLVM=1 \
                LLVM_IAS=1 \
                2> error.log

# Check for compiled files
if [ ! -f "$PWD/out/arch/arm64/boot/Image" ]; then
    echo ""
    echo "❌ Build failed! Image not found."
    exit 1
fi

echo ""
echo "✅ ${KERNEL_NAME} Kernel built successfully! Zipping files..."

# Move files to AnyKernel3
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb
cp $PWD/out/arch/arm64/boot/Image $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtb.img $ANYKERNEL3_DIR/dtb

# Zip Kernel
cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

BUILD_END=$(date +"%s")
BUILD_TIME=$((BUILD_END - BUILD_START))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build Completed Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Kernel ZIP: $FINAL_KERNEL_ZIP"
echo "⏱️ Build time: $(($BUILD_TIME / 60)) min $(($BUILD_TIME % 60)) sec"
echo "🛠️ Build Type: ${BUILD_TYPE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean up
echo "🧹 Cleaning up..."
rm -rf out/
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb

# Return to parent directory before restoring
cd ..

# Restore files
echo "Restoring backup files..."
if [ -d "bkp" ]; then
    cp bkp/drivers/Kconfig kernel/drivers/Kconfig
    cp bkp/drivers/Makefile kernel/drivers/Makefile
    cp bkp/fs/internal.h kernel/fs/internal.h
    cp bkp/fs/namespace.c kernel/fs/namespace.c
    cp bkp/include/linux/seccomp.h kernel/include/linux/seccomp.h
    echo "✅ Backup files restored successfully!"
else
    echo "⚠️ Warning: Backup directory not found!"
fi

echo "✅ All done!"
echo ""
echo "Press <ENTER>/<RETURN> to exit..."
read
exit 0
