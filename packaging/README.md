# Beacon .NET native packages

This directory builds operating-system-managed packages from an already built
Beacon .NET platform payload. It does not rebuild or rename profiler binaries.

## Linux

Build DEB and RPM packages on a runner matching the target architecture:

```bash
bash packaging/linux/build-packages.sh \
  --input bin/tracer-home \
  --output bin/native-packages \
  --architecture amd64
```

Supported architecture values are `amd64` and `arm64`. RPM creation must run on
the matching architecture. Packages install files under `/opt/beacon/dotnet`
and the CLI at `/usr/bin/beacon-dotnet`.

Run the packaging tests with:

```bash
bash packaging/linux/build-packages.test.sh
```

## Windows

Build the MSI on Windows after generating the PowerShell installation module:

```powershell
./packaging/windows/build-msi.ps1 `
  -InputDirectory bin/tracer-home `
  -ModulePath bin/installation-scripts/OpenTelemetry.DotNet.Auto.psm1 `
  -OutputDirectory bin/native-packages
```

The MSI installs under `%ProgramFiles%\Beacon\dotnet`, registers the command
path and .NET Framework assemblies, and appears in Windows Apps & Features. Its
uninstall custom action removes registrations before Windows Installer deletes
package-owned files.

Validate the complete lifecycle on an elevated Windows runner:

```powershell
./packaging/windows/test-msi.ps1 `
  -MsiPath bin/native-packages/beacon-dotnet-<version>-windows-x64.msi
```

Release workflows add checksums and GitHub artifact attestations. Authenticode
and APT/RPM repository signing require separately provisioned signing identities
and are not replaced by artifact attestations.
