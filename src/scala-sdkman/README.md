
# Scala (via SDKMAN!) (scala-sdkman)

Provides Scala, JDK, and SBT through SDKMAN with optimized caching

## Example Usage

```json
"features": {
    "ghcr.io/leo2www/devcontainer-features/scala-sdkman:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| scalaVersion | Scala version (use SDKMAN format) | string | latest |
| specificJavaVersion | Select or enter a JDK version to install, styled as command `sdkman java ${specificJavaVersion}` | string | 21-amzn |
| installSbt | Install SBT build tool | boolean | false |
| sbtVersion | Select or enter SBT version to install | string | latest |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/leo2www/devcontainer-features-sdkman/blob/main/src/scala-sdkman/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
