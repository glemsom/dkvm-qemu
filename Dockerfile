# Dockerfile for building QEMU APK on Alpine
FROM alpine:3.23

# Install build dependencies
RUN apk add --no-cache \
    alpine-sdk bash sudo \
    alsa-lib-dev attr-dev curl-dev \
    dtc-dev glib-dev gnutls-dev lvm2-dev \
    gtk+3.0-dev cyrus-sasl-dev libseccomp-dev \
    libslirp-dev libssh-dev linux-headers meson ninja \
    perl pinentry pipewire-dev python3 sdl2-dev \
    spice-dev usbredir-dev zlib-dev zstd-dev \
    && rm -rf /var/cache/apk/*

# Create builder user
RUN adduser -D -G abuild builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Pre-create packages directory with correct ownership
RUN mkdir -p /home/builder/packages && chown -R builder:abuild /home/builder/packages

WORKDIR /home/builder
USER builder

CMD ["/bin/bash"]