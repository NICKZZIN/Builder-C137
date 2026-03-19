#!/bin/bash

#
# Custom Kernel Builder - NICKZZIN
# (Otimizado para GitHub Actions)
#

# Clona o Kernel
echo "Clonando o Kernel..."
git clone https://github.com/NICKZZIN/KERNEL_STONE -b lineage-23.2 kernel --depth=1

# Copia AnyKernel3
cp -r AnyKernel3 kernel/AnyKernel3

# Faz os Backups
echo "Fazendo backup dos arquivos..."
mkdir -p bkp/{drivers,fs,include/linux}
cp kernel/drivers/Kconfig bkp/drivers/Kconfig 2>/dev/null
cp kernel/drivers/Makefile bkp/drivers/Makefile 2>/dev/null
cp kernel/fs/internal.h bkp/fs/internal.h 2>/dev/null
cp kernel/fs/namespace.c bkp/fs/namespace.c 2>/dev/null
cp kernel/include/linux/seccomp.h bkp/include/linux/seccomp.h 2>/dev/null

cd kernel

# -----------------------------------------------------------------
# Lógica Automática lendo a escolha do GitHub Actions (BUILD_TYPE)
# -----------------------------------------------------------------
echo "Opção selecionada no painel do GitHub: $BUILD_TYPE"

if [ "$BUILD_TYPE" = "KernelSU Oficial" ]; then
    KernelSU="y"
    KSU="1"
elif [ "$BUILD_TYPE" = "KernelSU Next" ]; then
    KernelSU="y"
    KSU="2"
else
    KernelSU="n"
fi

# Remove diretórios antigos se existirem
rm -rf $PWD/KernelSU-Next $PWD/KernelSU

if [ "$KernelSU" = "y" ]; then
    if [ "$KSU" = "1" ]; then
        echo "Configurando KernelSU Oficial..."
        if ! curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s; then
            echo "❌ Falha ao configurar o KernelSU!"
            exit 1
        fi
        echo "✅ KernelSU configurado com sucesso!"
        KERNELSU_DIR="$PWD/KernelSU"
        
    elif [ "$KSU" = "2" ]; then
        echo "Configurando KernelSU-Next..."
        if ! curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s; then
            echo "❌ Falha ao configurar o KernelSU-Next!"
            exit 1
        fi
        echo "✅ KernelSU-Next configurado com sucesso!"
        KERNELSU_DIR="$PWD/KernelSU-Next"
    fi

    # Verificação de segurança (Sem 'read' travando o terminal)
    echo "Verificando instalação do KernelSU..."
    if [ -d "$KERNELSU_DIR/kernel" ]; then
        echo "✅ Diretório $KERNELSU_DIR/kernel encontrado!"
    else
        echo "❌ Instalação do KernelSU incompleta!"
        exit 1
    fi
else
    echo "✅ Build Non-KSU selecionada (Kernel Stock)."
fi
echo ""

# -----------------------------------------------------------------
# Variáveis de Configuração e Ambiente
# -----------------------------------------------------------------
DEVICE_CODENAME="moonstone"
DEVICE_NAME="POCO X5 5G / Redmi Note 12 5G"
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

BUILD_STATUS="STABLE"
BUILD_HOSTNAME=$(hostname)

# Define o Clang e baixa se não encontrar
COMPILER_PATH="$HOME/clang-r547379/bin"
if ! [ -d "$HOME/clang-r547379" ]; then
    echo "⚙️ Clang não encontrado! Clonando..."
    if ! git clone -q https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git -b 15.0 --depth=1 --single-branch ~/clang-r547379; then
        echo "❌ Falha ao clonar o Clang!"
        exit 1
    fi
fi

# Detecta versão do compilador e exporta PATHs
export PATH="$COMPILER_PATH:$PATH"
COMPILER_NAME="$($COMPILER_PATH/clang --version | head -n 1 | sed -E 's/\(.*\)//' | awk '{$1=$1;print}')"
export ARCH=arm64
export KBUILD_BUILD_HOST=$BUILD_HOSTNAME
export KBUILD_BUILD_USER="NICKZZIN"
export KBUILD_COMPILER_STRING="$COMPILER_NAME"

# -----------------------------------------------------------------
# Início do Build
# -----------------------------------------------------------------
BUILD_START=$(date +"%s")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 Iniciando Build do Kernel ${KERNEL_NAME}!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Dispositivo: ${DEVICE_NAME} (${DEVICE_CODENAME})"
echo "🖥️ Compilando em: $(hostname)"
echo "⚙️ Compilador: ${COMPILER_NAME}"
echo "📰 Status: ${BUILD_STATUS}"
echo "🛠️ Tipo: ${BUILD_TYPE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Limpeza Garantida
echo "🧹 Limpando o ambiente..."
rm -rf out/
mkdir -p out/

# Seta o Defconfig
echo "⚙️ Configurando o defconfig..."
make $KERNEL_DEFCONFIG O=out

# Habilita opções do KernelSU se selecionado
if [ "$KernelSU" = "y" ]; then
    echo "🔧 Injetando configs do KSU no .config..."
    scripts/config --file out/.config \
        -e KPROBES \
        -e HAVE_KPROBES \
        -e KPROBE_EVENTS \
        -e MODULES \
        -e MODULE_UNLOAD
    make O=out olddefconfig
fi

# Otimização: Desliga o Debug para voar na compilação
echo "🚀 Desativando Debug Info para compilar rápido..."
scripts/config --file out/.config -d DEBUG_INFO -d DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
make O=out olddefconfig

# Compilação forçada em todos os núcleos
echo ""
echo "🔨 Compilando o Kernel..."
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

# Validação Final
if [ ! -f "$PWD/out/arch/arm64/boot/Image" ]; then
    echo ""
    echo "❌ A compilação falhou! Arquivo Image não foi gerado."
    echo "Últimos erros do log (error.log):"
    tail -n 30 error.log
    exit 1
fi

echo ""
echo "✅ Kernel ${KERNEL_NAME} gerado com sucesso! Compactando arquivos..."

# Copia pro AnyKernel3
rm -rf $ANYKERNEL3_DIR/Image $ANYKERNEL3_DIR/dtbo.img $ANYKERNEL3_DIR/dtb
cp $PWD/out/arch/arm64/boot/Image $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/ 2>/dev/null
cp $PWD/out/arch/arm64/boot/dtb.img $ANYKERNEL3_DIR/dtb 2>/dev/null

# Cria o ZIP
cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

BUILD_END=$(date +"%s")
BUILD_TIME=$((BUILD_END - BUILD_START))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Workflow Finalizado com Sucesso!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Kernel ZIP: $FINAL_KERNEL_ZIP"
echo "⏱️ Tempo: $(($BUILD_TIME / 60)) min $(($BUILD_TIME % 60)) seg"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
