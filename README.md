# opentelemetry

OpenTelemetry implementation for the Pony programming language. Provides tracing, metrics, and logs signals with OTLP HTTP/JSON export.

## Status

Under development.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/ponylang/opentelemetry.git --version 0.1.0`
* `corral fetch` to fetch your dependencies
* `use "otel_api"` to include the API package (traits and types)
* `use "otel_sdk"` to include the SDK package (concrete implementations)
* `use "otel_otlp"` to include the OTLP exporter package
* `corral run -- ponyc` to compile your application

Note: The OTLP exporter depends on [ponylang/http](https://github.com/ponylang/http) which requires an SSL library. You must pass an SSL version flag when compiling. See [SSL versions](#supported-ssl-versions) below.

## Packages

### otel_api

Zero-dependency API package containing traits and types. Use this package when instrumenting library code that should not depend on a concrete SDK.

```pony
use "otel_api"
```

### otel_sdk

Concrete SDK implementations including providers, processors, samplers, and exporters. Use this package in applications to configure and initialize telemetry.

```pony
use "otel_sdk"
```

### otel_otlp

OTLP HTTP/JSON exporter for sending telemetry data to an OpenTelemetry Collector or compatible backend.

```pony
use "otel_otlp"
```

## Supported SSL versions

The OTLP exporter uses HTTP and therefore requires an SSL library. Select the library version at compile-time using Pony's compile time definition functionality.

### Using OpenSSL 1.1.x

```bash
corral run -- ponyc -Dopenssl_1.1.x
```

### Using OpenSSL 3.0.x

```bash
corral run -- ponyc -Dopenssl_3.0.x
```

### Using LibreSSL

```bash
corral run -- ponyc -Dlibressl
```

## Dependencies

The OTLP exporter requires either LibreSSL or OpenSSL. You may need to install it within your environment of choice.

### Installing on APT based Linux distributions

```bash
sudo apt-get install -y libssl-dev
```

### Installing on Alpine Linux

```bash
apk add --update libressl-dev
```

### Installing on Arch Linux

```bash
pacman -S openssl
```

### Installing on macOS with Homebrew

```bash
brew update
brew install libressl
```

### Installing on macOS with MacPorts

```bash
sudo port install libressl
```

### Installing on RPM based Linux distributions with dnf

```bash
sudo dnf install openssl-devel
```

### Installing on RPM based Linux distributions with yum

```bash
sudo yum install openssl-devel
```

### Installing on RPM based Linux distributions with zypper

```bash
sudo zypper install libopenssl-devel
```

### Installing on Windows

If you use [Corral](https://github.com/ponylang/corral) to include this package as a dependency of a project, Corral will download and build LibreSSL for you the first time you run `corral fetch`. Otherwise, you will need CMake (3.15 or higher) and 7Zip (`7z.exe`) in your `PATH`; and Visual Studio 2017 or later (or the Visual C++ Build Tools 2017 or later) installed on your system.

You should pass `-Dlibressl` to ponyc when using this package on Windows.

## API Documentation

https://redvers.github.io/opentelemetry
