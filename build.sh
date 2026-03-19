#!/bin/bash

#
# Custom Kernel Builder - NICKZZIN
# (Otimizado para PC Local - Linux Mint)
#

# 🛡️ TRAVA DE SEGURANÇA: Garante que o script sempre rode da pasta base correta!
cd "$(dirname "$0")" || exit 1
BUILDER_DIR="$PWD"

# Atualiza ou Clona o Kernel Inteligente
if [ -d "kernel" ]; then
    cd kernel
    
    # Nova verificação: Garante que é realmente a pasta raiz do código-fonte
    if [ -f "Android.mk" ] || [ -f "android.mk" ]; then
        git pull origin lineage-23.2
    else
        echo "❌ Erro: Falhou em encontrar a pasta kernel correta!"
        exit 1
    fi
else
    echo "⬇️ Clonando o Kernel pela primeira vez..."
    git clone https://github.com/NICKZZIN/KERNEL_STONE -b lineage-23.2 kernel --depth=1
    cd kernel
fi

# Copy AnyKernel to kernel dir.
cd ..

# Copy AnyKernel to kernel dir
rm -rf kernel/AnyKernel3
cp -r AnyKernel3 kernel/

# Backup files
echo "Backup files ..."
mkdir -p bkp/{drivers,fs,include/linux}
cp kernel/drivers/Kconfig bkp/drivers/Kconfig 2>/dev/null
cp kernel/drivers/Makefile bkp/drivers/Makefile 2>/dev/null
cp kernel/fs/internal.h bkp/fs/internal.h 2>/dev/null
cp kernel/fs/namespace.c bkp/fs/namespace.c 2>/dev/null
cp kernel/include/linux/seccomp.h bkp/include/linux/seccomp.h 2>/dev/null

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

# Set Kernel Build Variables
DEVICE_CODENAME="stone"  
DEVICE_NAME="POCO X5 5G/Redmi Note 12 5G/Note 12R Pro"          
KERNEL_NAME="C137"    
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

echo ""

# Menu Interativo do SusFS
echo "Do you want to include SusFS (Hide Root)? (y / n)"
read IncludeSusFS

if [ "$IncludeSusFS" = "y" ]; then
    echo "⚙️ Baixando e integrando SusFS (Kernel 5.4)..."
    
    # Clona o repositório oficial do susfs na versão correta (Método Completo)
    git clone https://github.com/infectedmushi/susfs4ksu.git -b kernel-5.4 --depth=1 susfs_tmp

    echo "Aplicando patch no Kernel..."
    patch -p1 --forward < susfs_tmp/kernel_patches/50_add_susfs_in_kernel-5.4.patch

echo "Copiando arquivos essenciais do SusFS..."
    cp -r susfs_tmp/kernel_patches/fs/* fs/
    cp -r susfs_tmp/kernel_patches/include/linux/* include/linux/
    
    if [ "$KernelSU" = "y" ]; then
        echo "Aplicando patch do SusFS no KernelSU..."
        cp susfs_tmp/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch $KERNELSU_DIR/
        cd $KERNELSU_DIR
        patch -p1 --forward < 10_enable_susfs_for_ksu.patch
        cd ..
    fi

    echo "Injetando configurações do SusFS no defconfig..."
    cat susfs_tmp/kernel_patches/susfs_defconfig >> arch/arm64/configs/${KERNEL_DEFCONFIG}

    rm -rf susfs_tmp
    echo "✅ SusFS integrado!"
fi

# Set Build Status
BUILD_STATUS="STABLE"
BUILD_HOSTNAME=$(hostname)

# Set Compiler Path
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
export KBUILD_BUILD_USER="NICKZZIN"
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

# Limpeza Segura (Sem o bug de I/O)
echo "🧹 Usando builds anteriores..."

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

echo "🚀 Desativando Debug Info para salvar o HD e compilar muito mais rápido..."
scripts/config --file out/.config -d DEBUG_INFO -d DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
make O=out olddefconfig

# Compile Kernel
echo ""
echo "🔨 Iniciando a compilação do kernel..."
echo ""

echo "" > .scmversion

# Limitado a 2 núcleos para evitar travamento do HD/Swap
make -j2 O=out \
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
    echo "Últimos erros do log (error.log):"
    tail -n 30 error.log
    exit 1
fi

echo ""
echo "✅ ${KERNEL_NAME} Kernel built successfully! Zipping files..."

# Move files to AnyKernel3
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb
cp $PWD/out/arch/arm64/boot/Image $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/ 2>/dev/null
cp $PWD/out/arch/arm64/boot/dtb.img $ANYKERNEL3_DIR/dtb 2>/dev/null

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
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb

echo "✅ All done!"
exit 0
