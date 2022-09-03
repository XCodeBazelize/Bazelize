# Bazelize

A cli tool turn your xcode project to bazel.

---

## Install

```sh
mint install XCodeBazelize/Bazelize
```

## Usage

```sh
bazelize --project YOUR.xcodeproj
```

## TODO

### Cocoapod

#### [Podfile](https://guides.cocoapods.org/using/the-podfile.html)

 * Build configurations
    * `:configurations => ['Debug', 'Beta']`
 * Modular Headers
    * `:modular_headers => true`
 * Source
    * `:source => 'https://github.com/CocoaPods/Specs.git'`
 * Subspecs
    * `pod 'QueryKit/Attribute'`
    * `pod 'QueryKit', :subspecs => ['Attribute', 'QuerySet']`
 * Test Specs
    * `:testspecs => ['UnitTests', 'SomeOtherTests']`
 * local path
    * `:path => '~/Documents/AFNetworking'`
 * From a podspec in the root of a library repository.
    * `pod 'AFNetworking', :git => 'https://github.com/gowalla/AFNetworking.git'`
    * `pod 'AFNetworking', :git => 'https://github.com/gowalla/AFNetworking.git', :branch => 'dev'`
    * `pod 'AFNetworking', :git => 'https://github.com/gowalla/AFNetworking.git', :tag => '0.7.0'`
    * `pod 'AFNetworking', :git => 'https://github.com/gowalla/AFNetworking.git', :commit => '082f8319af'`
 * From a podspec outside a spec repository, for a library without podspec.
    * `:podspec => 'https://example.com/JSONKit.podspec'`

#### Error -> help

------

### Xcode

#### XCode SPM Dependencies

#### XCode Target Dependencies

#### XCode Framework Dependencies

#### Build Settings

#### info plist

#### `PBXProductType`

 * mac app
 * framewrok
 * unit test
 * ...

-----

## Bazel Rules

 * [rules_apple](https://github.com/bazelbuild/rules_apple/tree/master/doc)
    * [frameworks](https://github.com/bazelbuild/rules_apple/blob/master/doc/frameworks.md)
        * prebuilt
          `apple_dynamic_framework_import`  
          `apple_static_framework_import`
    * [resources](https://github.com/bazelbuild/rules_apple/blob/master/doc/resources.md)
 * [rules_swift](https://github.com/bazelbuild/rules_swift/blob/master/doc/rules.md#swift_proto_library)
 * [PodToBUILD](https://github.com/pinterest/PodToBUILD/blob/master/BazelExtensions/workspace.bzl#L218)
