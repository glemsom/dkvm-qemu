# Contributor: DKVM Team <packages@dkvm.io>
# Maintainer: DKVM Team <packages@dkvm.io>

pkgname=qemu
pkgver=11.0.0
pkgrel=0
pkgdesc="QEMU virtualizer for DKVM (x86_64 optimized)"
url="https://qemu.org/"
arch="x86_64"
license="GPL-2.0-only AND LGPL-2.1-only"
provides="qemu=$pkgver-r$pkgrel"
replaces="qemu"

makedepends="
	alsa-lib-dev
	attr-dev
	brlapido-dev
	curl-dev
	device-mapper-dev
	dtc-dev
	glib-dev
	gnutls-dev
	gtk+3.0-dev
	libsasl-dev
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
	zlib-dev
	zstd-dev
"

subpackages="$pkgname-dev:_dev:$pkgname-dev
	$pkgname-doc:_doc
	$pkgname-img:_img
	$pkgname-hw-display-virtio-gpu:_virtio_gpu
	$pkgname-hw-display-virtio-gpu-gl:_virtio_gpu_gl
	$pkgname-hw-display-virtio-gpu-pci:_virtio_gpu_pci
	$pkgname-hw-display-virtio-gpu-pci-gl:_virtio_gpu_pci_gl
	$pkgname-hw-display-virtio-vga:_virtio_vga
	$pkgname-hw-display-virtio-vga-gl:_virtio_vga_gl
	$pkgname-audio-alsa:_audio_alsa
	$pkgname-audio-oss:_audio_oss
	$pkgname-audio-pa:_audio_pa
	$pkgname-audio-sdl:_audio_sdl
	$pkgname-block-curl:_block_curl
	$pkgname-block-dmg:_block_dmg
	$pkgname-block-nfs:_block_nfs
	$pkgname-block-ssh:_block_ssh
	$pkgname-chardev-baum:_chardev_baum
	$pkgname-chardev-spice:_chardev_spice
	$pkgname-ui-curses:_ui_curses
	$pkgname-ui-egl-headless:_ui_egl_headless
	$pkgname-ui-gtk:_ui_gtk
	$pkgname-ui-opengl:_ui_opengl
	$pkgname-ui-spice:_ui_spice
	$pkgname-ui-spice-app:_ui_spice_app
	$pkgname-tools:_tools
"

# Only enable subpackages for features we include
options="!check"

source="https://download.qemu.org/qemu-$pkgver.tar.xz"
builddir="$srcdir/qemu-$pkgver"

build() {
	# Configure for x86_64 with essential features only
	# Disable all target architectures except x86_64
	# Disable unnecessary features to reduce build time and package size

	# Create build directory
	mkdir -p build
	cd build

	# Configure with minimal features for DKVM use case
	# Note: Keep many default options to avoid breakages per plan notes
	../configure \
		--build-target=x86_64 \
		--enable-ccw \
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
		--enable-vnc-ssl \
		--enable-vnc-jpeg \
		--enable-vnc-png \
		--with-sdlabi=2.0 \
		--with-gtkabi=3.0 \
		--enable-tools \
		--enable-xkbcommon \
		--enable-zstd \
		--python=python3 \
		--localstatedir=/var \
		--sysconfdir=/etc \
		--enable-debug-tcg \
		--enable-trace-backends=dtrace

	# Build using meson/ninja
	ninja
}

package() {
	cd build
	DESTDIR="$pkgdir" ninja install

	# Install license files
	install -Dm644 "$builddir"/COPYING "$pkgdir"/usr/share/licenses/$pkgname/COPYING
	install -Dm644 "$builddir"/COPYING.LGPL-2.1 "$pkgdir"/usr/share/licenses/$pkgname/COPYING.LGPL-2.1
}

# Subpackage functions
_dev() {
	pkgdesc="QEMU development files"
	provides="qemu-dev=$pkgver-r$pkgrel"
	replaces="qemu-dev"

	# Move development files from main package
	if [ -d "$subpkgdir/usr/include" ]; then
		mv "$subpkgdir/usr/include" "$pkgdir/usr/" 2>/dev/null || true
	fi
	if [ -d "$subpkgdir/usr/lib" ]; then
		mv "$subpkgdir/usr/lib" "$pkgdir/usr/" 2>/dev/null || true
	fi
}

_doc() {
	pkgdesc="QEMU documentation"
	provides="qemu-doc=$pkgver-r$pkgrel"
	replaces="qemu-doc"

	# Move docs from main package
	if [ -d "$subpkgdir/usr/share/doc" ]; then
		mv "$subpkgdir/usr/share/doc" "$pkgdir/usr/share/" 2>/dev/null || true
	fi
}

_img() {
	pkgdesc="QEMU disk image utility"
	provides="qemu-img=$pkgver-r$pkgrel"
	replaces="qemu-img"

	# Move qemu-img binary
	mkdir -p "$pkgdir/usr/bin"
	mv "$subpkgdir/usr/bin/qemu-img" "$pkgdir/usr/bin/" 2>/dev/null || true
	mv "$subpkgdir/usr/bin/qemu-io" "$pkgdir/usr/bin/" 2>/dev/null || true
	mv "$subpkgdir/usr/bin/qemu-nbd" "$pkgdir/usr/bin/" 2>/dev/null || true
}

_virtio_gpu() {
	pkgdesc="QEMU virtio-gpu device"
	provides="qemu-hw-display-virtio-gpu=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_virtio_gpu_gl() {
	pkgdesc="QEMU virtio-gpu-gl device"
	provides="qemu-hw-display-virtio-gpu-gl=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_virtio_gpu_pci() {
	pkgdesc="QEMU virtio-gpu-pci device"
	provides="qemu-hw-display-virtio-gpu-pci=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_virtio_gpu_pci_gl() {
	pkgdesc="QEMU virtio-gpu-pci-gl device"
	provides="qemu-hw-display-virtio-gpu-pci-gl=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_virtio_vga() {
	pkgdesc="QEMU virtio-vga device"
	provides="qemu-hw-display-virtio-vga=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_virtio_vga_gl() {
	pkgdesc="QEMU virtio-vga-gl device"
	provides="qemu-hw-display-virtio-vga-gl=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_audio_alsa() {
	pkgdesc="QEMU ALSA audio driver"
	provides="qemu-audio-alsa=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_audio_oss() {
	pkgdesc="QEMU OSS audio driver"
	provides="qemu-audio-oss=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_audio_pa() {
	pkgdesc="QEMU PulseAudio driver"
	provides="qemu-audio-pa=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_audio_sdl() {
	pkgdesc="QEMU SDL audio driver"
	provides="qemu-audio-sdl=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_block_curl() {
	pkgdesc="QEMU curl block driver"
	provides="qemu-block-curl=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_block_dmg() {
	pkgdesc="QEMU dmg block driver"
	provides="qemu-block-dmg=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_block_nfs() {
	pkgdesc="QEMU NFS block driver"
	provides="qemu-block-nfs=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_block_ssh() {
	pkgdesc="QEMU SSH block driver"
	provides="qemu-block-ssh=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_chardev_baum() {
	pkgdesc="QEMU Baum chardev driver"
	provides="qemu-chardev-baum=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_chardev_spice() {
	pkgdesc="QEMU SPICE chardev driver"
	provides="qemu-chardev-spice=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_ui_curses() {
	pkgdesc="QEMU curses UI"
	provides="qemu-ui-curses=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_ui_egl_headless() {
	pkgdesc="QEMU EGL headless UI"
	provides="qemu-ui-egl-headless=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_ui_gtk() {
	pkgdesc="QEMU GTK UI"
	provides="qemu-ui-gtk=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_ui_opengl() {
	pkgdesc="QEMU OpenGL support"
	provides="qemu-ui-opengl=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_ui_spice() {
	pkgdesc="QEMU SPICE UI"
	provides="qemu-ui-spice=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_ui_spice_app() {
	pkgdesc="QEMU SPICE app"
	provides="qemu-ui-spice-app=$pkgver-r$pkgrel"
	depends="$pkgname=$pkgver-r$pkgrel"
}

_tools() {
	pkgdesc="QEMU tools"
	provides="qemu-tools=$pkgver-r$pkgrel"
	replaces="qemu-tools"

	# Move remaining binaries
	mkdir -p "$pkgdir/usr/bin"
	for bin in qemu-edid qemu-ga qemu-pr-helper qemu-storage-daemon qemu-traditional-strip; do
		if [ -f "$subpkgdir/usr/bin/$bin" ]; then
			mv "$subpkgdir/usr/bin/$bin" "$pkgdir/usr/bin/" 2>/dev/null || true
		fi
	done

	# Move share files
	if [ -d "$subpkgdir/usr/share/qemu" ]; then
		mkdir -p "$pkgdir/usr/share"
		mv "$subpkgdir/usr/share/qemu" "$pkgdir/usr/share/" 2>/dev/null || true
	fi
}

sha512sums="
3a047385374cce2fc0d58abbe0d52531ca629f3d25d60b107e1c97372e7ed9caaa5337719d140d0f936b0425d872c0fd77048ef2c13d89295a4c1e650d9daa60  qemu-11.0.0.tar.xz
"