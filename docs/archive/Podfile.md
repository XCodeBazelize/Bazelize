# [Podfile](https://guides.cocoapods.org/using/the-podfile.html)

> Historical: research notes on CocoaPods. Nothing here is implemented —
> bazelize has no CocoaPods support in its sources. The text below is kept
> unchanged.

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