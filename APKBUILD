# Contributor: Sergei Lukun <sergej.lukin@gmail.com>
# Contributor: Valery Kartel <valery.kartel@gmail.com>
# Contributor: Jakub Jirutka <jakub@jirutka.cz>
# Maintainer: Natanael Copa <ncopa@alpinelinux.org>
pkgname=qemu
pkgver=10.1.5
pkgrel=0
pkgdesc="QEMU is a generic machine emulator and virtualizer"
url="https://qemu.org/"
arch="x86_64"
license="GPL-2.0-only AND LGPL-2.1-only"
makedepends="
	bison
	capstone-dev
	curl-dev
	flex
	glib-dev
	gnutls-dev
	libaio-dev
	libjpeg-turbo-dev
	libpng-dev
	libseccomp-dev
	libslirp-dev
	libssh-dev
	liburing-dev
	libusb-dev
	linux-headers
	lzo-dev
	meson
	numactl-dev
	python3
	snappy-dev
	util-linux-dev
	vde2-dev
	zlib-dev
	zstd-dev
	"

# strip fails on .img files
options="!strip textrels"

subpackages="$pkgname-system-x86_64:_system_x86_64"

source="https://download.qemu.org/qemu-$pkgver.tar.xz
	patches/0001-CPUID.patch
	patches/0002-x-force-cpuid.patch
	patches/0003-epyc-vcpu.patch
	patches/0004-bus-lock-detect.patch
	patches/0005-bus-lock-detect-epyc.patch
	patches/xattr_size_max.patch
	patches/fix-sockios-header.patch
	patches/musl-initialise-msghdr.patch
	patches/fix-strerrorname_np.patch
	patches/liburing.patch
	"

# secfixes:
#   8.0.2-r1:
#     - CVE-2023-2861
#   8.0.0-r6:
#     - CVE-2023-0330
#   7.1.0-r4:
#     - CVE-2022-2962
#     - CVE-2022-3165
#   7.0.0-r0:
#     - CVE-2021-4158
#   6.1.0-r0:
#     - CVE-2020-35503
#     - CVE-2021-3507
#     - CVE-2021-3544
#     - CVE-2021-3545
#     - CVE-2021-3546
#     - CVE-2021-3682
#   6.0.0-r2:
#     - CVE-2020-35504
#     - CVE-2020-35505
#     - CVE-2020-35506
#     - CVE-2021-3527
#   6.0.0-r1:
#     - CVE-2021-20181
#     - CVE-2021-20255
#     - CVE-2021-3392
#     - CVE-2021-3409
#     - CVE-2021-3416
#   5.2.0-r0:
#     - CVE-2020-24352
#     - CVE-2020-25723
#     - CVE-2020-25742
#     - CVE-2020-25743
#     - CVE-2020-27661
#     - CVE-2020-27821
#     - CVE-2020-29443
#     - CVE-2020-35517
#     - CVE-2021-20203
#   5.1.0-r1:
#     - CVE-2020-13361
#     - CVE-2020-13362
#     - CVE-2020-14364
#     - CVE-2020-15863
#     - CVE-2020-16092
#     - CVE-2020-17380
#     - CVE-2020-25084
#     - CVE-2020-25085
#     - CVE-2020-25624
#     - CVE-2020-25625
#     - CVE-2020-25741
#     - CVE-2020-28916
#   5.0.0-r0:
#     - CVE-2020-13659
#     - CVE-2020-13754
#     - CVE-2020-13791
#     - CVE-2020-13800
#     - CVE-2020-14415
#     - CVE-2020-15469
#     - CVE-2020-15859
#     - CVE-2020-27616
#     - CVE-2020-27617
#     - CVE-2021-20221
#   4.2.0-r0:
#     - CVE-2020-13765
#   2.8.1-r1:
#     - CVE-2016-7994
#     - CVE-2016-7995
#     - CVE-2016-8576
#     - CVE-2016-8577
#     - CVE-2016-8578
#     - CVE-2016-8668
#     - CVE-2016-8909
#     - CVE-2016-8910
#     - CVE-2016-9101
#     - CVE-2016-9102
#     - CVE-2016-9103
#     - CVE-2016-9104
#     - CVE-2016-9105
#     - CVE-2016-9106
#     - CVE-2017-2615
#     - CVE-2017-2620
#     - CVE-2017-5525
#     - CVE-2017-5552
#     - CVE-2017-5578
#     - CVE-2017-5579
#     - CVE-2017-5667
#     - CVE-2017-5856
#     - CVE-2017-5857
#     - CVE-2017-5898
#     - CVE-2017-5931

build() {
	# it pretty much never makes sense to optimise qemu for disk size
	export CFLAGS="$CFLAGS -O2"
	export CXXFLAGS="$CXXFLAGS -O2"
	export CPPFLAGS="$CPPFLAGS -O2"

	mkdir -p "$builddir"/build
	cd "$builddir"/build
	"$builddir"/configure \
		--prefix=/usr \
		--localstatedir=/var \
		--sysconfdir=/etc \
		--libexecdir=/usr/lib/qemu \
		--python=/usr/bin/python3 \
		--disable-debug-info \
		--disable-bsd-user \
		--disable-werror \
		--disable-docs \
		--disable-linux-user \
		--disable-guest-agent \
		--disable-tools \
		--disable-brlapi \
		--disable-bpf \
		--disable-cap-ng \
		--disable-curses \
		--disable-gcrypt \
		--disable-gtk \
		--disable-mpath \
		--disable-nettle \
		--disable-sdl \
		--disable-spice \
		--disable-virglrenderer \
		--enable-kvm \
		--enable-seccomp \
		--enable-capstone \
		--enable-curl \
		--enable-libssh \
		--enable-linux-aio \
		--enable-lzo \
		--enable-numa \
		--enable-pie \
		--enable-snappy \
		--enable-tpm \
		--enable-usb-redir \
		--enable-vde \
		--enable-vhost-net \
		--enable-virtfs \
		--enable-vnc \
		--enable-vnc-jpeg \
		--enable-zstd \
		--cc="${CC:-gcc}" \
		--target-list=x86_64-softmmu,i386-softmmu
	make ARFLAGS="rc"
}

check() {
	make -C build check TIMEOUT_MULTIPLIER=5 V=1
}

package() {
	cd "$builddir"/build
	make DESTDIR="$pkgdir" install

	# Do not install HTML docs.
	rm -rf "$pkgdir"/usr/share/doc
}

_system_x86_64() {
	pkgdesc="QEMU x86_64 system emulator"
	options=""
	depends=""

	amove usr/bin/qemu-system-x86_64
	amove usr/share/qemu/edk2-x86_64-*code.fd \
		usr/share/qemu/firmware/50-edk2-x86_64-secure.json \
		usr/share/qemu/firmware/60-edk2-x86_64.json \
		usr/share/qemu/edk2-i386-vars.fd
}

sha512sums="
c003c1175b3ee09a72a1523e4c7ab02e5538b482315d33d04fb0b8d321b4a002f3785012bb013bd20331f89022d9b604bb224d55a0d9f313edacbc9dcbac0e6d  qemu-10.1.5.tar.xz
00097153612d107053599c665c7468b8aedcbc28322c21289156659827059b10448fea7d1527101418670023db469b6d26dc9eb1b247f4f86520ec192394ae0e  0001-CPUID.patch
a74265dfe4c4c3b416a1f5acca6a8cb57d70403aaf2254ec652b15e1898bb101daeaf017ecb9ec3d88ef6c80bd3b984566d880eb73af3ce36d38d4ec8d4f3d4a  0002-x-force-cpuid.patch
1c91f2cbf45685425a0d79dd435f205fb0239b7a4f464ad21213f794838619a666247410ac298f3e27d7678169cd4f767a3ffdedd239e41184d4ae597e16ef4a  0003-epyc-vcpu.patch
62e813ce09d0b81e2e4ee2b3235b5acb966209e3b918815cd641c6024144124d8bf6c89b966e93a8573440a5dd2f50f9b178c048ca7da22b108830065f05040c  0004-bus-lock-detect.patch
b9a4dba94785823cba3c06bd5cd5eb7be8e63509bbde0b334610b3d2c1a5d58a0d7059115c17ca15d82aac2509371cbb0446b13741157205bbc35139101a9303  0005-bus-lock-detect-epyc.patch
2c6b3b22877674f870958bb0c74ad85c814f01c98fb123142b1ce77d89adf5c08626e6eade7f627090a53b48f5cebe2a535547804345648cff91dd66f90c2d5b  xattr_size_max.patch
54d26c3c44730fbd2a155431558fba6a1a3f25d8c057a8e5b8b0d802cb2b6c8a12545a16069fff1b9888a15d6cb087e9750d5e2c310dfc1a3fc756509d3d963e  fix-sockios-header.patch
7a6340df8aa28811af20cd23b98ba95fc8072d4d4d3a2d497604386396892cf26716d0755821e47d02c8eded203133d7dde100537c117e2a047179e4f93883cf  musl-initialise-msghdr.patch
7df4b0979d11fb0b7d2dbb073d7249677b0f51381dfbeb1bec2e44d29dd6e1d752468d7f9fb5b42deed6bdf184e81358e7b6dc54b36db326f3336cd6121a1a60  fix-strerrorname_np.patch
75979455abcd9d9f25a966d829d578a06691163e297247c045ce67f94ebc916850b7be1080024a9db6bba9e3f7b88a8cc486f364fb7b028804862bc8634f00e4  liburing.patch
"
