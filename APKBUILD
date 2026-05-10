# Contributor: DKVM Team <packages@dkvm.io>
# Maintainer: DKVM Team <packages@dkvm.io>
# Based on QEMU master with AMD 0x80000026 and Bus Lock Detect patches
# Patches target commit 4481234e98 (Nov 2025)

pkgname=qemu
pkgver=11.0.0
pkgrel=1
pkgdesc="QEMU virtualizer for DKVM (x86_64 optimized) with AMD 0x80000026 support"
url="https://qemu.org/"
arch="x86_64"
license="GPL-2.0-only AND LGPL-2.1-only"

makedepends="
	alsa-lib-dev
	attr-dev
	brltty-dev
	curl-dev
	device-mapper-dev
	dtc-dev
	glib-dev
	gnutls-dev
	gtk+3.0-dev
	cyrus-sasl-dev
	libseccomp-dev
	libslirp-dev
	libssh-dev
	linux-headers
	meson
	ninja
	perl
	pinentry
	pipewire-dev
	python3
	sdl2-dev
	spice-dev
	usbredir-dev
	zlib-dev
	zstd-dev
"

subpackages=""

# Use git source with specific commit that patches target
source="
	https://download.qemu.org/qemu-$pkgver.tar.xz
	patches/001.patch
	patches/002.patch
	patches/003.patch
	patches/004.patch
"
builddir="$srcdir/qemu-$pkgver"

prepare() {
	# Apply AMD CPUID 0x80000026 and Bus Lock Detect patches
	cd "$builddir"
	for p in "$startdir"/patches/*.patch; do
		msg2 "Applying patch: $(basename "$p")"
		patch -p1 < "$p"
	done
}

build() {
	# Configure for x86_64 with essential features only
	mkdir -p build
	cd build

	# Configure with minimal features for DKVM use case
	../configure \
		--prefix=/usr \
		--target-list=x86_64-softmmu \
		--disable-install-blobs \
		--enable-kvm \
		--enable-spice \
		--enable-libusb \
		--enable-usb-redir \
		--enable-opengl \
		--enable-gtk \
		--enable-sdl \
		--enable-curses \
		--enable-virtfs \
		--enable-seccomp \
		--enable-tpm \
		--enable-vnc \
		--enable-tools \
		--enable-zstd \
		--python=python3 \
		--localstatedir=/var \
		--sysconfdir=/etc

	ninja
}

package() {
	cd build
	DESTDIR="$pkgdir" ninja install

	# Install license files
	install -Dm644 "$builddir"/COPYING "$pkgdir"/usr/share/licenses/$pkgname/COPYING
	install -Dm644 "$builddir"/COPYING.LIB "$pkgdir"/usr/share/licenses/$pkgname/COPYING.LIB
}

sha512sums="
3a047385374cce2fc0d58abbe0d52531ca629f3d25d60b107e1c97372e7ed9caaa5337719d140d0f936b0425d872c0fd77048ef2c13d89295a4c1e650d9daa60  qemu-11.0.0.tar.xz
455bd84fa0db882f5f0ef6f54e06a133929eb2d2543b21ef3405a391c01f2e7e6c814b1187453359053d3a8b4ced0b0eb5f92ddd6eed0d48231cb30d5e81cb04  001.patch
155d4aee0657cf977788c4093b7feec9e1ee335a60d19471b6a0077155cfe11c4317004061e0b5d1d329d222f4194475d8f887e4a3406510ec0004cf561b757e  002.patch
fcc2bebb24e203940e06c78c304b4d9ab53fcb2dd80eea27d8a42eda278c20a85125e888e6cc065e13a9c959aa267c33da233d8e52810943a01898a84f5c6f73  003.patch
6dff49f012e12134827cd794fe5f4e7ad7182b95817a036fc411928f891d35e883622b3d2de2683297bf4aed0d36307325c4f22326dc6ed87bd8c54fc801d956  004.patch
"
