# Podfile

> Historical: research notes on CocoaPods and PodToBUILD. Nothing here is
> implemented — bazelize has no CocoaPods support in its sources. The text
> below is kept unchanged.

---

## PodToBUILD Dependency

> `//Vendor/__PACKAGE__:__TARGET__`

## Get information from Podfile

```sh
pod ipc podfile-json Podfile
```

```json
{
    // ...
    "name": "SOME_TARGET",
    "dependencies": [
        "Peek",
        {
            "AFNetworking": [
                "~> 4.0"
            ]
        },
        "Moya/RxSwift",
        "Moya/Combine",
        {
            "DataCompression": [
                {
                    "git": "https://github.com/mw99/DataCompression"
                }
            ]
        },
    ]
}
```

## Dependencies

```yaml
target: SOME_TARGET
dependency:
- "//Vendor/Peek:Peek"
- "//Vendor/AFNetworking:AFNetworking"
- "//Vendor/Moya:RxSwift"
- "//Vendor/Moya:Combine"
- "//Vendor/DataCompression:DataCompression"
```