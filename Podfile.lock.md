# Podfile.Lock -> Pods.WORKSPACE

---

### Github

> https://github.com/${organization,user}/${repo}/archive/${commit,branch,tag}.zip

### Regular Pod

#### Podfile

```ruby
pod Bagel
```

#### Pod Spec Command

```sh
pod spec cat Bagel --version=1.4.0
```

```json
{
    // ...
    "source": {
        "git": "https://github.com/yagiz/Bagel.git",
        "tag": "1.4.0"
    },
}
```

#### Result

```bazel
new_pod_repository(
    name = "Bagel",
    url = "https://github.com/yagiz/Bagel/archive/1.4.0.zip"
)
```

----

### From a podspec in the root of a library repository.

#### Podfile

```ruby
pod 'XLPagerTabStrip', :git => "https://github.com/xmartlabs/XLPagerTabStrip", :branch => 'master'
```

#### Podfile.lock

```yaml
# ...

EXTERNAL SOURCES:
  XLPagerTabStrip:
    :branch: master
    :git: https://github.com/xmartlabs/XLPagerTabStrip

CHECKOUT OPTIONS:
  XLPagerTabStrip:
    :commit: 903b7609b2b2dd1010efb9ee1c6a27edaa9df89b
    :git: https://github.com/xmartlabs/XLPagerTabStrip
```


#### Result

```bazel
new_pod_repository(
    name = "XLPagerTabStrip",
    url = "https://github.com/xmartlabs/XLPagerTabStrip/archive/master.zip"
)
```