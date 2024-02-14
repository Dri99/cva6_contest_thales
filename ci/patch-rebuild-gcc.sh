#!/bin/bash
DOCKER=docker
if ! command -v docker &> /dev/null
then
    echo "docker could not be found, trying podman"
    if ! command -v podman &> /dev/null
    then
        echo "podman could not be found, exiting"
        exit 1
    else 
        DOCKER=podman
    fi

fi

cd ../

$DOCKER run -ti --privileged \
    -v `realpath sw`:/workdir \
    -v `realpath ci`:/ci sw-docker:v1 \
    /bin/bash -c "cd /util/gcc-toolchain-builder/src/binutils-gdb/ &&
        sudo chmod 644 include/opcode/riscv-opc.h &&
        sudo chmod 644 opcodes/riscv-opc.c &&
        git apply /ci/patch-add-mac4b &&
        sudo chmod 755 include/opcode/riscv-opc.h &&
        sudo chmod 755 opcodes/riscv-opc.c &&
        cd /util/gcc-toolchain-builder/ &&
        sudo ./build-toolchain.sh riscv_toolchain
        "
DOCKER_ID=$($DOCKER ps -l --format "{{.ID}}")
$DOCKER commit $DOCKER_ID sw-docker:v1
