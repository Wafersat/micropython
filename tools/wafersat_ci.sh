#!/bin/bash

if which nproc > /dev/null; then
    MAKEOPTS="-j$(nproc)"
else
    MAKEOPTS="-j$(sysctl -n hw.ncpu)"
fi

# general helper functions

function ci_gcc_arm_setup {
    sudo apt-get install gcc-arm-none-eabi libnewlib-arm-none-eabi
    arm-none-eabi-gcc --version
}

# code formatting

function ci_code_formatting_setup {
    sudo apt-get install uncrustify
    pip3 install black
    uncrustify --version
    black --version
}

function ci_code_formatting_run {
    tools/codeformat.py -v
}

# ports/stm32

function ci_stm32_setup {
    ci_gcc_arm_setup
    pip3 install pyelftools
    pip3 install pyhy
}

# .mpy file format

function ci_mpy_format_setup {
    sudo pip3 install pyelftools
}

function ci_mpy_format_test {
    # Test mpy-tool.py dump feature on bytecode
    python2 ./tools/mpy-tool.py -xd ports/minimal/frozentest.mpy
    python3 ./tools/mpy-tool.py -xd ports/minimal/frozentest.mpy

    # Test mpy-tool.py dump feature on native code
    make -C examples/natmod/features1
    ./tools/mpy-tool.py -xd examples/natmod/features1/features1.mpy
}

function ci_native_mpy_modules_build {
    if [ "$1" = "" ]; then
        arch=x64
    else
        arch=$1
    fi
    make -C examples/natmod/features1 ARCH=$arch
    make -C examples/natmod/features2 ARCH=$arch
    make -C examples/natmod/features3 ARCH=$arch
    make -C examples/natmod/btree ARCH=$arch
    make -C examples/natmod/framebuf ARCH=$arch
    make -C examples/natmod/uheapq ARCH=$arch
    make -C examples/natmod/urandom ARCH=$arch
    make -C examples/natmod/ure ARCH=$arch
    make -C examples/natmod/uzlib ARCH=$arch
}

# Wafersat Build

function ci_stm32_pyb_build {
    make ${MAKEOPTS} -C mpy-cross
    make ${MAKEOPTS} -C ports/stm32 submodules
    git submodule update --init lib/btstack
    git submodule update --init lib/mynewt-nimble
    make ${MAKEOPTS} -C ports/stm32 BOARD=STM32F429_Wafersat

    # Test building native .mpy with armv7emsp architecture.
    git submodule update --init lib/berkeley-db-1.xx
    ci_native_mpy_modules_build armv7emsp
}
