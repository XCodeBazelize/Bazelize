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

A package whose targets use a build tool plugin has its plugins run at the end
of generation, with the `//:plugins` target the run writes:

```sh
bazel run //:plugins
```

Bazel builds the plugins and their tools, so generation needs `bazel` on `PATH`
for that step. Run the same command again whenever a plugin or its input
changes.

A command plugin becomes a target named after its verb, so `swift package
hello` is:

```sh
bazel run //Packages/YourPackage:hello -- <arguments>
```

Everything after `--` reaches the plugin the way everything after the verb
reaches it under SwiftPM. There is no sandbox to widen, so what the plugin
declared it wants to do is printed rather than refused — running the target is
the permission.

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
