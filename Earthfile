VERSION 0.8

prep:
    FROM ubuntu:noble@sha256:1e622c5f073b4f6bfad6632f2616c7f59ef256e96fe78bf6a595d1dc4376ac02
    RUN \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            autoconf automake bc bison build-essential ca-certificates cmake cpio \
            crossbuild-essential-arm64 curl debhelper dbus-x11 dosfstools e2fsprogs fdisk flex gzip \
            kmod libncurses-dev libssl-dev libtinfo6 libtool-bin locales rsync xz-utils zstd && \
        rm -rf /var/lib/apt/lists/* && \
        sed -i 's/^#\s*\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
        dpkg-reconfigure --frontend noninteractive locales
    ARG XSCT_URL=https://petalinux.xilinx.com/sswreleases/rel-v2024.2/xsct-trim/xsct-2024.2_REL_1209.tar.xz
    ARG XSCT_SHA256SUM=2ca6ee6d1349cc6484845b094d867e3953fdfe7d800e8b35863db15f39c2373c
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter -L "${XSCT_URL}" -o /tmp/xsct.tar.xz && \
        echo "${XSCT_SHA256SUM} /tmp/xsct.tar.xz" | sha256sum -c - && \
        mkdir -p /opt/xsct && \
        tar xf /tmp/xsct.tar.xz -C /opt/xsct --strip-components=2
    ENV PATH="/opt/xsct/bin:/opt/xsct/gnu/aarch64/lin/aarch64-none/bin:/opt/xsct/gnu/armr5/lin/gcc-arm-none-eabi/bin:/opt/xsct/gnu/microblaze/lin/bin:${PATH}"
    WORKDIR /build

build:
    FROM scratch
    COPY +disk.img.zst/ .

    COPY +app-r5-0/bin/ipi-led.elf .
    COPY +boot.bin/ .
    COPY +fsbl.elf/ .
    COPY +generate-src/system.bit .
    COPY +pmufw.elf/ .
    COPY +system.dtb/ .
    COPY +tf-a/bl31.elf .
    COPY +u-boot/u-boot.elf .
    SAVE ARTIFACT ./*

disk.img.zst:
    FROM +prep
    COPY +boot.tar/ .
    COPY +rootfs.tar/ .
    ARG DISK_IMG_PART1_SIZE=16M
    ARG DISK_IMG_PART2_SIZE=512M
    RUN --mount=type=tmpfs,target=/tmp --privileged \
        truncate -s "$DISK_IMG_PART1_SIZE" /tmp/boot.img && \
        mkfs.vfat -F 16 /tmp/boot.img && \
        mount /tmp/boot.img /mnt && \
        tar xf boot.tar -C /mnt && \
        umount /mnt && \
        truncate -s "$DISK_IMG_PART2_SIZE" /tmp/root.img && \
        mkfs.ext4 /tmp/root.img && \
        mount /tmp/root.img /mnt && \
        tar xf rootfs.tar --xattrs --xattrs-include='*' -C /mnt && \
        umount /mnt && \
        truncate -s 1M /tmp/header.img && \
        cat /tmp/header.img /tmp/boot.img /tmp/root.img > /tmp/disk.img && \
        echo "label: dos\n1M,${DISK_IMG_PART1_SIZE},e\n,${DISK_IMG_PART2_SIZE},L,*\n" | sfdisk /tmp/disk.img && \
        zstd --no-progress -9 /tmp/disk.img -o disk.img.zst
    SAVE ARTIFACT disk.img.zst

boot.tar:
    FROM +prep
    COPY +boot.bin/ boot/
    RUN tar --create -f boot.tar -C boot .
    SAVE ARTIFACT boot.tar

rootfs.tar:
    FROM +prep
    COPY +rootfs-base.tar/rootfs-base.tar rootfs.tar
    COPY linux/rootfs rootfs
    COPY +system.dtb/ rootfs/boot/
    COPY +app-a53/ rootfs
    RUN tar --append -f rootfs.tar --xattrs --xattrs-include='*' -C rootfs .
    SAVE ARTIFACT rootfs.tar

boot.bin:
    FROM +prep
    COPY +app-r5-0/bin/ipi-led.elf .
    COPY +bootgen/bootgen .
    COPY +fsbl.elf/ .
    COPY +generate-src/system.bit .
    COPY +pmufw.elf/ .
    COPY +system.dtb/ .
    COPY +tf-a/bl31.elf .
    COPY +u-boot/u-boot.elf .
    COPY boot.bif .
    RUN ./bootgen -arch zynqmp -image boot.bif -o boot.bin
    SAVE ARTIFACT boot.bin

fsbl.elf:
    FROM +prep
    COPY +generate-src/fsbl .
    RUN make
    SAVE ARTIFACT executable.elf /fsbl.elf

pmufw.elf:
    FROM +prep
    COPY +generate-src/pmufw .
    RUN make CFLAGS="-DENABLE_MOD_ULTRA96 -DULTRA96_VERSION=2 -DPMU_MIO_INPUT_PIN_VAL=1 -DBOARD_SHUTDOWN_PIN_VAL=1 -DBOARD_SHUTDOWN_PIN_STATE_VAL=1"
    SAVE ARTIFACT executable.elf /pmufw.elf

system.dtb:
    FROM +prep
    COPY +generate-src/device-tree .
    COPY +linux/include include
    COPY +u-boot/dtc .
    COPY system-top-append.dts .
    RUN cat system-top-append.dts >> system-top.dts && \
        gcc -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -Iinclude -o - system-top.dts | ./dtc -@ -p 0x1000 -I dts -O dtb -o system.dtb
    SAVE ARTIFACT system.dtb

app-a53:
    FROM +prep
    COPY apps/a53 src
    COPY apps/toolchain/aarch64-linux-gnu.cmake .
    RUN cmake \
        --toolchain $PWD/aarch64-linux-gnu.cmake \
        -S src \
        -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=install/usr
    RUN cmake --build build -- install
    SAVE ARTIFACT install/* /

app-r5-0:
    FROM +prep
    COPY +bsp-r5-0/ libxil
    COPY apps/r5_0 src
    COPY apps/toolchain/armr5-none-eabi.cmake .
    RUN cmake \
        --toolchain $PWD/armr5-none-eabi.cmake \
        -S src \
        -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=install \
        -DLibXil_ROOT=libxil
    RUN cmake --build build -- install
    SAVE ARTIFACT install/* /

bsp-r5-0:
    FROM +prep
    COPY +generate-src/bsp_psu_cortexr5_0 .
    RUN make
    SAVE ARTIFACT psu_cortexr5_0/include /include
    SAVE ARTIFACT psu_cortexr5_0/lib/*a /lib/

generate-src:
    ARG --required XSA_FILE

    FROM +xsct
    COPY generate.tcl .
    COPY $XSA_FILE system.xsa
    RUN USER="$(id -u -n)" xsct -sdx -nodisp generate.tcl system.xsa
    SAVE ARTIFACT bsp_psu_cortexr5_0
    SAVE ARTIFACT device-tree
    SAVE ARTIFACT fsbl
    SAVE ARTIFACT pmufw
    SAVE ARTIFACT system.bit

rootfs-base.tar:
    FROM --platform=linux/arm64 ubuntu:noble@sha256:1e622c5f073b4f6bfad6632f2616c7f59ef256e96fe78bf6a595d1dc4376ac02
    RUN apt-get update && \
        apt-get install -y --no-install-recommends mmdebstrap && \
        rm -rf /var/lib/apt/lists/*
    COPY +linux/*.deb kernels/
    RUN mmdebstrap \
        --verbose \
        --components='main restricted universe multiverse' \
        --variant='minbase' \
        --include='apt dbus e2fsprogs init iproute2 iputils-ping kmod libstdc++6 parted sudo systemd-timesyncd udev' \
        --customize-hook='cp -r kernels "$1/" && chroot "$1" sh -c "dpkg -i /kernels/*.deb" && rm -rf "$1/kernels"' \
        --customize-hook='sed -i "s/^#\s*\(%sudo\)/\1/" "$1/etc/sudoers"' \
        --customize-hook='chroot "$1" adduser --disabled-password user' \
        --customize-hook='chroot "$1" adduser user sudo' \
        --customize-hook='echo "user:user" | chroot "$1" chpasswd' \
        --customize-hook='chroot "$1" passwd --expire user' \
        --customize-hook='chroot "$1" passwd --lock root' \
        --dpkgopt='path-exclude=/usr/share/man/*' \
        --dpkgopt='path-include=/usr/share/man/man[1-9]/*' \
        --dpkgopt='path-exclude=/usr/share/locale/*' \
        --dpkgopt='path-include=/usr/share/locale/locale.alias' \
        --dpkgopt='path-exclude=/usr/share/doc/*' \
        --dpkgopt='path-include=/usr/share/doc/*/copyright' \
        noble rootfs-base.tar http://ports.ubuntu.com/ubuntu-ports
    # Use .tar format since SAVE ARTIFACT and COPY drop permissions for some reason even specifying with the --keep-own option...
    SAVE ARTIFACT rootfs-base.tar

bootgen:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter -L https://github.com/Xilinx/bootgen/archive/refs/tags/xilinx_v2024.2.tar.gz -o /tmp/archive.tar.gz && \
        echo '2c8345a3bea4fcec6ceb6c8f8e727a610aaca3ec71cdf7f892d7f89f88438650  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN make
    SAVE ARTIFACT bootgen

linux:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter -L https://github.com/Xilinx/linux-xlnx/archive/2b7f6f70a62a52a467bed030a27c2ada879106e9.tar.gz -o /tmp/archive.tar.gz && \
        echo 'acc0dbd745328782dc67bac8c42cb02a93b9f06cd042177b92d0765af9c5dcfc  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY linux/defconfig arch/arm64/configs/myboard_defconfig
    ARG nproc=$(nproc)
    RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 myboard_defconfig
    RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 bindeb-pkg -j$nproc
    SAVE ARTIFACT include/dt-bindings /include/dt-bindings
    SAVE ARTIFACT /*.deb

tf-a:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter -L https://github.com/Xilinx/arm-trusted-firmware/archive/refs/tags/xilinx-v2024.2.tar.gz -o /tmp/archive.tar.gz && \
        echo 'dbc8caad320364178f55e8df423877b0029d3913cde000f483dd55a06244471b  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    ARG nproc=$(nproc)
    RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=aarch64 PLAT=zynqmp RESET_TO_BL31=1 ZYNQMP_CONSOLE=cadence1 bl31 -j$nproc
    SAVE ARTIFACT build/zynqmp/release/bl31/bl31.elf /

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter -L https://github.com/Xilinx/u-boot-xlnx/archive/refs/tags/xilinx-v2024.2.tar.gz -o /tmp/archive.tar.gz && \
        echo '14d01cca4e8c90f4c22b6ca760f7368d167285ead2dbc83162428c0afe0af901  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    ARG nproc=$(nproc)
    COPY u-boot.defconfig configs/myboard_defconfig
    RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm myboard_defconfig
    RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm u-boot.elf -j$nproc
    SAVE ARTIFACT u-boot.elf
    SAVE ARTIFACT scripts/dtc/dtc /dtc

xsct:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter -L https://github.com/Xilinx/embeddedsw/archive/refs/tags/xilinx_v2024.2.tar.gz -o /tmp/archive.tar.gz && \
        echo '550ba0b206848adb0085bc1ca5a6b6731681335c92912afb4a6a8dbb4c489a0c  /tmp/archive.tar.gz' | sha256sum -c && \
        mkdir -p embeddedsw && \
        tar xf /tmp/archive.tar.gz --strip-components=1 -C embeddedsw
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter -L https://github.com/Xilinx/device-tree-xlnx/archive/refs/tags/xilinx_v2024.2.tar.gz -o /tmp/archive.tar.gz && \
        echo 'ef254833819edccfdb3416593f682dc7e0c40d4c6c0d657a80a118fc914bd911  /tmp/archive.tar.gz' | sha256sum -c && \
        mkdir -p device-tree-xlnx && \
        tar xf /tmp/archive.tar.gz --strip-components=1 -C device-tree-xlnx

    RUN sed -i 's/{\s*\(\w\+\)\s*==\s*"$\(.\+\)"\s*}/"\1==$\2"/' embeddedsw/lib/bsp/standalone/data/standalone.tcl
