# Syncthing for Windows 7 / Windows Server 2008 R2 (x64)

Unofficial build of [Syncthing](https://github.com/syncthing/syncthing) v2 that
runs on Windows 7 SP1 and Windows Server 2008 R2 SP1 (NT 6.1), 64-bit.

Reference target machine:

- Windows Server 2008 R2 Foundation SP1, 64-bit
- HP, Intel Celeron G1610T @ 2.30 GHz (no AVX), 8 GB RAM

> This is **not** an official Syncthing release and is not supported by the
> Syncthing project. Windows 7 / Server 2008 R2 no longer receive security
> updates from Microsoft; use at your own risk.

## Why a custom build is needed

Since Go 1.21, Go only supports Windows 10 / Server 2016 and later
([Go 1.21 release notes](https://go.dev/doc/go1.21#windows)). Syncthing v2
requires Go 1.26, so official Syncthing binaries do not start on Windows 7 /
Server 2008 R2 (the Go runtime calls APIs such as `ProcessPrng` that only exist
on newer Windows versions).

## What changes compared to upstream

| Change | Reason |
|---|---|
| Built with [`go-legacy-win7`](https://github.com/thongtech/go-legacy-win7) 1.26.x instead of official Go | Restores Windows 7 / 2008 R2 support in the Go runtime and standard library. |
| `GOAMD64=v1` | Baseline x86-64; works on CPUs without AVX. |
| `CGO_ENABLED=0` | Pure-Go SQLite (`modernc.org/sqlite`), no C runtime dependencies. |
| `noupgrade` build tag | Disables auto-upgrade; an official release would replace the binary and fail to start. |
| Version string `v2.1.5+win7` | Identifies the custom build. |

The Syncthing Go source code itself is **unchanged**. The Windows APIs used by
Syncthing, `golang.org/x/sys/windows` call sites and `modernc.org/libc` /
SQLite were reviewed: all of them exist on Windows 7 SP1. The resulting PE
header declares OS/subsystem version 6.1.

Files added by this fork:

- `build-win7.ps1` – build script for Windows 10/11 x64 (PowerShell 5.1+)
- `build-win7.sh` – cross-build script for Linux / macOS
- `README-Win7.md` – this document

## Building

On Windows 10/11 x64:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-win7.ps1
```

On Linux / macOS:

```sh
./build-win7.sh
```

Both scripts download the `go-legacy-win7` toolchain into `.toolchain/`
(ignored by git) and produce `syncthing-windows-amd64-v2.1.5+win7.zip`.

Options: `-Version` / `VERSION` sets the version string, `-GoLegacyVersion` /
`GO_LEGACY_VERSION` selects the toolchain release.

## Installing on the server

1. Copy `syncthing.exe` to e.g. `C:\Syncthing\`.
2. Keep Windows Update current (SP1 and at least KB2533623).
3. Start it: `syncthing.exe --no-browser`
4. Open the GUI at `http://127.0.0.1:8384` with a modern browser. Internet
   Explorer 11 is not supported by the GUI. Alternatively, enable remote GUI
   access (Actions → Settings → GUI → listen address `0.0.0.0:8384`, with a
   username and password) and manage it from another computer.
5. Firewall: allow TCP/UDP 22000 and UDP 21027.

## Updating

This build does not update itself. To update: pull the new upstream code,
keep the files listed above, rebuild and replace `syncthing.exe`.

## License

Syncthing is licensed under the [Mozilla Public License 2.0](LICENSE). This
fork keeps the same license; see [AUTHORS](AUTHORS) for the upstream
contributors.
