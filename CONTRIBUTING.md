# Contributing to DKVM QEMU

## How to add or modify patches

All patches live in `patches/` and are applied in sorted order during build.

### Patch naming convention

```
patches/NNNN-description.patch
```

- `NNNN` — zero-padded sequence number (order of application)
- `description` — short kebab-case description

### Creating a new patch

```bash
# 1. Make changes in the QEMU source tree
cd /path/to/qemu-11.0.1
# ... edit files ...

# 2. Generate patch from the qemu root
git diff --no-color > ../dkvm-qemu/patches/0009-my-feature.patch

# 3. Verify the patch applies cleanly
../dkvm-qemu/dev-build.sh
```

### Patch requirements

- Must apply cleanly to QEMU **11.0.1**
- Must not introduce `-Werror` warnings (build uses `--disable-werror` but patches should be clean)
- Must be a unified diff (`git diff` or `diff -u`)
- Header comment describing purpose (preferred, not required for trivial patches)

## Running tests

```bash
# Build first, then test
./dev-build.sh
./dev-test.sh build/out/qemu-system-x86_64
```

The test suite runs QMP queries and VM boots. It requires a BIOS file (`bios-256k.bin`) for `-machine pc` tests — the script searches common locations automatically.

## Code style

Follow QEMU's coding style (see `docs/devel/style.rst` in upstream QEMU). Key points:

- Linux kernel style (indent with 4 spaces, no tabs in C)
- 80-column limit for comments, 90 for code
- `camelCase` for functions, `snake_case` for variables (per QEMU convention)

## Testing guidelines

When adding a new feature:

1. Add a test case to `dev-test.sh`
2. Cover: happy path, error cases, and regression (no feature → unchanged behavior)
3. Test both model mode (`-cpu EPYC-Turin`) and passthrough mode (`-cpu host`)

## Documentation

When adding or changing features, update:

- `docs/reference/patches.md` — patch table (add new patch rows)
- `docs/howto/qemu-flags.md` — usage examples and flags
- `README.md` — top-level description and quick reference
- `docs/reference/glossary.md` — domain terms
- `docs/adr/` — new ADR if the change has architectural significance
- This is a small project — keep docs concise but complete

## Commit messages

Follow conventional commits format:

```
type(scope): short description

Longer explanation if needed.
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
Scope example: `per-die-l3`, `cpuid`, `bus-lock`, `repo`, `docs`

## Pull request process

1. Ensure tests pass
2. Update documentation for any user-facing changes
3. Open a PR against the `main` branch
4. Maintainer will review within a few days
