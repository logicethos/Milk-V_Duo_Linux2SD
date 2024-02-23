# Use an Ubuntu base image
FROM ubuntu:22.04

ARG BOARD=milkv-duo256m
ENV BOARD=${BOARD}

ENV DEBIAN_FRONTEND=non-interactive
ENV BUILD_OUTPUT=/build-output


RUN apt-get update \
    && apt-get install -y \
    wget git make build-essential libtool rsync \
    ca-certificates joe --no-install-recommends


#Requied for duo-buildroot-sdk
RUN apt install -y pkg-config build-essential ninja-build automake autoconf libtool wget curl git gcc libssl-dev bc slib squashfs-tools android-sdk-libsparse-utils jq python3-distutils scons parallel tree python3-dev python3-pip device-tree-compiler ssh cpio fakeroot libncurses5 flex bison libncurses5-dev genext2fs rsync unzip dosfstools mtools tcl openssh-client cmake expect

#Required for debian build
RUN apt install -y debootstrap qemu qemu-user-static binfmt-support dpkg-cross debian-ports-archive-keyring  --no-install-recommends

RUN update-ca-certificates

WORKDIR /

RUN git clone https://github.com/milkv-duo/duo-buildroot-sdk.git --depth=1

WORKDIR duo-buildroot-sdk
RUN wget https://sophon-file.sophon.cn/sophon-prod-s3/drive/23/03/07/16/host-tools.tar.gz
RUN tar -xf host-tools.tar.gz
RUN rm host-tools.tar.gz

RUN sed -i '/image rootfs.ext4 {/,/}/s/size = .*/size = 1G/' /duo-buildroot-sdk/device/*/genimage.cfg
COPY bootstrap.sh /.

RUN apt-get clean
RUN rm -rf /var/cache/apt/

#Default to a bash session. 
CMD bash