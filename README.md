# Bazelize

Bazelize generates Bazel workspaces from Xcode projects and Swift packages.

---

## Install

```sh
mint install XCodeBazelize/Bazelize
```

## Usage

```sh
bazelize --input YOUR.xcodeproj --output App
```

Or a Swift package — the `Package.swift`, or the directory holding one:

```sh
bazelize --input path/to/Package.swift --output App
```

---

## Bazel

### Project Hierarchy

```bash
├── xxx.xcodeproj
├── xxx.xcworkspace
├── config.bazelrc        # generated file
├── BUILD           # generated file
├── WORKSPACE       # generated file
├── Podfile
├── Podfile.lock
├── Target1
│   ├── BUILD       # generated file
│   └── xxx.swift
├── Target2
│   ├── BUILD       # generated file
│   └── xxx.m
├── TestTarget1
│   ├── BUILD       # generated file
│   └── xxx.swift
├── TestTarget2
│   ├── BUILD       # generated file
│   └── xxx.swift
└ ...
```

### Config

All `Xcode configs` is stored in `BUILD` file.

You can build debug version with following code.

> bazel build --//:mode=Debug [Package]

```bazel
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
string_flag(
    name = "mode",
    build_setting_default = "normal",
)

config_setting(
    name = "Debug",
    flag_values = {
        ":mode": "Debug"
    },
)

config_setting(
    name = "Release",
    flag_values = {
        ":mode": "Release"
    },
)
```

Or you can fill in the following code into `.bazelrc`.

```python
import %workspace%/config.bazelrc
```

> bazel build --config=Debug [Package]
