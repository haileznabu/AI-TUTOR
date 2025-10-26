# Building Optimized Release APK

## Enabled Optimizations:
- ✅ Code obfuscation
- ✅ Code minification  
- ✅ Resource shrinking
- ✅ ProGuard optimization

## Build Commands:

### Standard Release (smaller APK):
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Split APKs by ABI (smallest per-device):
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```

This creates 3 APKs:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)  
- `app-x86_64-release.apk` (64-bit Intel)

Upload all 3 to Play Store for automatic device-specific downloads.

### App Bundle (Recommended for Play Store):
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

Play Store automatically generates optimized APKs per device (smallest possible size).

## Expected Size Reduction:
- Standard build: 30-50% smaller
- Split APKs: 40-60% smaller per device
- App Bundle: 50-65% smaller per device

## Note:
Save the `build/app/outputs/symbols` directory for crash reporting/debugging.
