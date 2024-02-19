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

echo "This script won't run properly. To rebuild gcc, run in the working directory:"
echo "$DOCKER run -ti --privileged -v `realpath sw`:/workdir -v `realpath ci`:/ci sw-docker:v1"
echo "Run the following command (./ci/patch-rebuild-gcc.sh:29)"
echo "Wait for the build to finish and follow the new printed steps."
echo "Terminating"
exit -1 


$DOCKER run -ti --privileged \
    -v `realpath sw`:/workdir \
    -v `realpath ci`:/ci sw-docker:v1 \
    /bin/bash -c "cd /util/gcc-toolchain-builder/src/binutils-gdb/ &&
        sudo chmod 644 include/opcode/riscv-opc.h &&
        sudo chmod 644 opcodes/riscv-opc.c &&
        sudo git apply /ci/patch-add-mac4b &&
        sudo chmod 755 include/opcode/riscv-opc.h &&
        sudo chmod 755 opcodes/riscv-opc.c &&
        cd /util/gcc-toolchain-builder/ &&
        sudo bash build-toolchain.sh riscv_toolchain &&
        sudo umount /ci &&
        sudo rm -rf /ci && 
        echo &&
        echo 'Build finished. Commit in an other terminal with the following commands:' &&
        echo 'DOCKER_ID=\$(docker ps -l --format \"{{.ID}}\")' &&
        echo 'docker commit \$DOCKER_ID sw-docker:v1' &&
        echo &&
        read -p 'Press enter when finished'
        "
# DOCKER_ID=$($DOCKER ps -l --format "{{.ID}}")
# $DOCKER commit $DOCKER_ID sw-docker:v1
