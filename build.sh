#!/bin/bash

#
# This Bash script automates the process of building a custom kernel for any device using Clang.
# It packages the compiled kernel with AnyKernel3.
# USAGE : ./build.sh or bash build.sh
#
# Copyright (C) 2025 Amrita Das <bhabanidas431@gmail.com>
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

echo "Do you want to include KernelSU? (y / n)"
read KernelSU

if [ "$KernelSU" = "y" ]; then
    echo "Build KernelSU-Next Selected"
    
    # Remove old KernelSU directories if exists to avoid conflicts
    if [ -d "$PWD/KernelSU" ]; then
        echo "Removing old KernelSU directory..."
        rm -rf $PWD/KernelSU
    fi
    
    if [ -d "$PWD/KernelSU-Next" ]; then
        echo "Removing old KernelSU-Next directory..."
        rm -rf $PWD/KernelSU-Next
    fi
    
    # Setup KernelSU-Next using official setup script
    echo "Setting up KernelSU-Next..."
    if ! curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s main; then
        echo "❌ Failed to setup KernelSU-Next!"
        exit 1
    fi
    
    echo "✅ KernelSU-Next setup completed!"
    
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
    
    # Ask about SusFS
    echo ""
    echo "Do you want to include SusFS? (y / n)"
    read SusFS
    
    if [ "$SusFS" = "y" ]; then
        echo "SusFS Selected"
        
        # Remove old SusFS if exists
        if [ -d "$KERNELSU_DIR/kernel/sufs" ]; then
            echo "Removing old SusFS directory..."
            rm -rf $KERNELSU_DIR/kernel/sufs
        fi
        
        # Clone SusFS from backslashxx (compatible with older kernels including 5.4)
        echo "Cloning SusFS (backslashxx fork - compatible with kernel 5.4) to $KERNELSU_DIR/kernel/sufs..."
        if ! git clone https://github.com/backslashxx/susfs4ksu.git $KERNELSU_DIR/kernel/sufs --depth=1; then
            echo "❌ Failed to clone SusFS!"
            echo "Trying alternative repository..."
            
            # Fallback to simonpunk original
            if ! git clone https://gitlab.com/simonpunk/susfs4ksu.git $KERNELSU_DIR/kernel/sufs --depth=1; then
                echo "❌ Failed to clone SusFS from both repositories!"
                exit 1
            fi
        fi
        
        echo "✅ SusFS cloned successfully!"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  CRITICAL: Manual configuration required!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "For Kernel 5.4 with KernelSU-Next + SusFS:"
        echo ""
        echo "1. Add to your defconfig (arch/arm64/configs/stone_defconfig):"
        echo ""
        echo "   # KernelSU-Next (Manual Hooks recommended for older kernels)"
        echo "   CONFIG_KPROBES=y"
        echo "   CONFIG_HAVE_KPROBES=y"
        echo "   CONFIG_KPROBE_EVENTS=y"
        echo "   CONFIG_MODULES=y"
        echo "   CONFIG_MODULE_UNLOAD=y"
        echo "   # Use Manual VFS Hooks instead of KPROBES (recommended)"
        echo "   # CONFIG_KSU_WITH_KPROBES=n"
        echo ""
        echo "   # SusFS for KernelSU-Next"
        echo "   CONFIG_KSU_SUSFS=y"
        echo "   CONFIG_KSU_SUSFS_SUS_PATH=y"
        echo "   CONFIG_KSU_SUSFS_SUS_MOUNT=y"
        echo "   CONFIG_KSU_SUSFS_SUS_KSTAT=y"
        echo "   CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y"
        echo "   CONFIG_KSU_SUSFS_OPEN_REDIRECT=y"
        echo "   CONFIG_KSU_SUSFS_SUS_SU=y"
        echo ""
        echo "2. IMPORTANT: Apply manual hooks patches for better compatibility"
        echo "   The backslashxx fork includes scope-minimized manual hooks"
        echo "   which work better on kernels 4.x-5.x than KPROBES"
        echo ""
        echo "3. Or modify your kernel Makefile to include KernelSU automatically:"
        echo ""
        if [ -d "$PWD/KernelSU-Next" ]; then
            echo "   Add before 'all:' target:"
            echo "   -include \$(srctree)/KernelSU-Next/kernel/Makefile.ext"
        else
            echo "   Add before 'all:' target:"
            echo "   -include \$(srctree)/KernelSU/kernel/Makefile.ext"
        fi
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Press ENTER to continue with the build..."
        read
    else
        echo "Build without SusFS"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  Manual configuration required for KernelSU-Next!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Add to your defconfig (arch/arm64/configs/stone_defconfig):"
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
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Press ENTER to continue with the build..."
        read
    fi
    
    # Verify KernelSU directory structure
    echo ""
    echo "Verifying KernelSU-Next installation..."
    if [ -d "$KERNELSU_DIR/kernel" ]; then
        echo "✅ $KERNELSU_DIR/kernel directory found"
        if [ "$SusFS" = "y" ] && [ -d "$KERNELSU_DIR/kernel/sufs" ]; then
            echo "✅ SusFS directory found at $KERNELSU_DIR/kernel/sufs"
        fi
        echo "✅ KernelSU-Next is ready!"
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
    if [ "$SusFS" = "y" ]; then
        FINAL_KERNEL_ZIP="${KERNEL_NAME}-Kernel-KSU-Next-SusFS-${DEVICE_CODENAME}-$(date '+%Y%m%d').zip"
    else
        FINAL_KERNEL_ZIP="${KERNEL_NAME}-Kernel-KSU-Next-${DEVICE_CODENAME}-$(date '+%Y%m%d').zip"
    fi
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

if [ "$KernelSU" = "y" ] && [ "$SusFS" = "y" ]; then
    BUILD_TYPE="KernelSU-Next + SusFS"
elif [ "$KernelSU" = "y" ]; then
    BUILD_TYPE="KernelSU-Next"
else
    BUILD_TYPE="Stock"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 ${KERNEL_NAME} Kernel Build Started!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Device: ${DEVICE_NAME} (${DEVICE_CODENAME})"
echo "🖥️ Building on: $(hostname)"
echo "⚙️ Compiler: ${COMPILER_NAME}"
echo "🔰 Build Status: ${BUILD_STATUS}"
echo "🛠️ Build Type: ${BUILD_TYPE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
    
    if [ "$SusFS" = "y" ]; then
        echo "🔧 Enabling SusFS configurations in .config..."
        scripts/config --file out/.config \
            -e KSU_SUSFS \
            -e KSU_SUSFS_SUS_PATH \
            -e KSU_SUSFS_SUS_MOUNT \
            -e KSU_SUSFS_SUS_KSTAT \
            -e KSU_SUSFS_SUS_OVERLAYFS \
            -e KSU_SUSFS_OPEN_REDIRECT \
            -e KSU_SUSFS_SUS_SU
    fi
    
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
                LLVM_IAS=1

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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build Completed Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Kernel ZIP: $FINAL_KERNEL_ZIP"
echo "⏱️ Build time: $(($BUILD_TIME / 60)) min $(($BUILD_TIME % 60)) sec"
echo "🛠️ Build Type: ${BUILD_TYPE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean up
echo "🧹 Cleaning up..."
rm -rf out/
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb

echo "✅ All done!"
exit 0
