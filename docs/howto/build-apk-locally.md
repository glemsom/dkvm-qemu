# How-to: Build APK Packages Locally

Build signed Alpine APK packages of DKVM QEMU from source on your local machine.

---

## Prerequisites

- **Alpine Linux** — tested on v3.20+ (also works on v3.19)
- **`alpine-sdk`** meta-package — installs `abuild`, `gcc`, build toolchain
- **`git`** — to clone the repository
- **Root or sudo access** — needed for `adduser`, `apk`, and `abuild` setup

Install prerequisites:

```sh
apk update
apk add alpine-sdk git
```

---

## Step 1: Set Up Build Environment

Create a dedicated build user in the `abuild` group and generate a signing key.

```sh
adduser -G abuild builder
# Switch to the build user
su - builder
```

Generate an RSA signing key for APK packages:

```sh
abuild-keygen -a
```

The key is stored at `~/.abuild/` (both private and public `.pub`).  
The public key also gets copied to `/etc/apk/keys/` automatically.

> **Note:** Do not commit private keys. The repository includes [`generate-key.sh`](../generate-key.sh) for test key generation in CI.

---

## Step 2: Clone Repository

```sh
git clone https://github.com/glemsom/dkvm-qemu.git
cd dkvm-qemu
```

---

## Step 3: Update Checksums

`abuild` requires checksums for all source files listed in `APKBUILD`.  
If you modify patches or change the source tarball, regenerate checksums:

```sh
abuild checksum
```

This updates the `sha512sums` entries in `APKBUILD`.

---

## Step 4: Build Packages

Build everything with:

```sh
abuild -r
```

The `-r` flag installs missing build dependencies (via `apk`) before building.

The build process:
1. Downloads the QEMU source tarball
2. Applies all DKVM patches (CPUID, bus-lock-detect, per-die L3 cache, etc.)
3. Compiles QEMU (static user-mode + dynamic system binaries)
4. Produces `.apk` packages in `~/packages/`

Build takes 15–60 minutes depending on hardware.

---

## Step 5: Sign and Verify

`abuild -r` signs packages automatically with the key generated in Step 1.

To verify a package signature manually:

```sh
apk verify --allow-untrusted <package>.apk
```

List signed contents:

```sh
tar -xzf <package>.apk .SIGN.RSA.<keyname>.rsa.pub -O | openssl rsautl -verify -inkey ~/.abuild/<keyname>.rsa.pub -pubin
```

---

## Step 6: Install Locally

Point your local APK repository to the built packages.

**Option A — temporary install:**

```sh
apk add --allow-untrusted ~/packages/home/builder/packages/*/qemu-*.apk
```

**Option B — set up a local repo:**

```sh
# Copy public key to system keys
cp ~/.abuild/*.rsa.pub /etc/apk/keys/

# Add local repository
echo "~/packages/home/builder/packages" >> /etc/apk/repositories

# Install QEMU
apk update
apk add qemu
```

**Option C — use the Docker-based script (if available):**

If `build-local.sh` is present in the repository, it automates the entire process inside a container:

```sh
# Generate a test key first
./generate-key.sh

# Build inside Docker
./build-local.sh
```

Output goes to `repo/x86_64/`.

---

## Step 7 (Optional): Create a Signed Repository

To serve packages to other machines, create a signed repository index:

```sh
# Ensure packages are in repo/x86_64/
mkdir -p repo/x86_64
cp ~/packages/home/builder/packages/*/qemu-*.apk repo/x86_64/

# Create and sign the index
./create-repo.sh repo/x86_64/
```

---

## Troubleshooting

### `abuild: not found`

```sh
apk add alpine-sdk
```

### `abuild-keygen: RSA key generation failed`

Ensure `openssl` is installed:

```sh
apk add openssl
```

### `ERROR: .../APKBUILD: line N: depends: command not found`

Your `APKBUILD` is malformed or from a different Alpine version. Ensure you are in the correct repository directory and have the right `APKBUILD`.

### `abuild checksum` fails with "checksum mismatch"

Source tarball or patches changed. Run `abuild checksum` to regenerate, then verify the download URL in `APKBUILD` is reachable.

### Missing dependency `foo-dev`

```sh
apk add foo-dev
```

Or re-run `abuild -r` which auto-installs missing deps.

### Patch fails to apply

Patches in the `patches/` directory are versioned (e.g., `0001-CPUID.patch`). If QEMU upstream changes the patched lines, the patch may fail. Check the build log for the specific file and line, then adjust the patch file manually.

### `docker: not found` (for build-local.sh)

Install Docker:

```sh
apk add docker
rc-update add docker
rc-service docker start
```

### Permission denied when running abuild

Ensure you are running as the `builder` user (or a user in the `abuild` group):

```sh
su - builder
```

### `abuild -r` fails on 32-bit architectures

Some checks and tests are skipped automatically for 32-bit builds (`arm*`, `x86`). If you encounter OOM errors during `make check`, disable tests:

```sh
abuild -r -D
```
