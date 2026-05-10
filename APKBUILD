# Contributor: DKVM Team <packages@dkvm.io>
# Maintainer: DKVM Team <packages@dkvm.io>

pkgname=qemu
pkgver=11.0.0
pkgrel=0
pkgdesc="QEMU virtualizer for DKVM (x86_64 optimized)"
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

source="https://download.qemu.org/qemu-$pkgver.tar.xz"
builddir="$srcdir/qemu-$pkgver"

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
"