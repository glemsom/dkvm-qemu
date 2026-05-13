# Dockerfile for building QEMU APK on Alpine
FROM alpine:3.23

# Install build dependencies
RUN apk update && apk add --no-cache \
    alpine-sdk bash sudo \
    alsa-lib-dev attr-dev bison capstone-dev curl-dev \
    dtc-dev flex glib-dev gnutls-dev lvm2-dev \
    gtk+3.0-dev cyrus-sasl-dev libaio-dev libjpeg-turbo-dev \
    libpng-dev libseccomp-dev libslirp-dev libssh-dev \
    liburing-dev libusb-dev linux-headers lzo-dev meson ninja \
    numactl-dev perl pinentry pipewire-dev python3 sdl2-dev \
    snappy-dev spice-dev sudo util-linux-dev vde2-dev \
    usbredir-dev zlib-dev zstd-dev \
    && rm -rf /var/cache/apk/*

# Create builder user
RUN adduser -D -G abuild builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Pre-create packages and abuild directories
RUN mkdir -p /home/builder/packages /home/builder/.abuild && \
    chown -R builder:abuild /home/builder/packages /home/builder/.abuild

WORKDIR /home/builder
USER builder

CMD ["/bin/bash"]