# Xcode Project Configuration Guide

This document describes how to set up the Xcode project for ByeByeDPI iOS.

## Creating the Xcode Project

Since we're providing source files, you'll need to create the Xcode project:

### Step 1: Create New Project

1. Open Xcode
2. File → New → Project
3. Choose "App" under iOS
4. Click Next

### Step 2: Configure Main App

- **Product Name**: ByeByeDPI
- **Team**: Your development team
- **Organization Identifier**: com.byebyedpi
- **Bundle Identifier**: com.byebyedpi.ByeByeDPI
- **Interface**: SwiftUI
- **Language**: Swift
- **Use Core Data**: Unchecked

### Step 3: Add Network Extension Target

1. File → New → Target
2. Choose "Network Extension" under iOS
3. Select "Packet Tunnel Provider"
4. Product Name: PacketTunnel
5. Bundle Identifier: com.byebyedpi.PacketTunnel

### Step 4: Add Files to Project

Drag these folders into the project navigator:

**Main App Target:**
- `ByeByeDPI/ByeByeDPIApp.swift`
- `ByeByeDPI/ContentView.swift`
- `ByeByeDPI/SettingsView.swift`
- `Shared/VPNManager.swift`
- `Shared/SettingsManager.swift`

**Packet Tunnel Target:**
- `PacketTunnel/PacketTunnelProvider.swift`
- `Shared/VPNManager.swift` (also add to extension)
- `ByeDPICore/ByeDpiProxy.swift`
- `ByeDPICore/include/ByeDpiProxy.h`

### Step 5: Configure Capabilities

**Main App Target:**
1. Select target → Signing & Capabilities
2. Click "+ Capability"
3. Add "Network Extensions"
4. Add "App Groups"
   - Create new group: `group.com.byebyedpi`

**Packet Tunnel Target:**
1. Select target → Signing & Capabilities
2. Add "Network Extensions"
3. Add "App Groups"
   - Enable same group: `group.com.byebyedpi`

### Step 6: Configure Build Settings

**For Both Targets:**
- Minimum Deployment Target: iOS 14.0
- Swift Language Version: Swift 5

**Packet Tunnel Target:**
- Mach-O Type: Static Library (for extension)
- Skip Install: NO

### Step 7: Link Libraries

**Packet Tunnel Target:**
1. General → Frameworks, Libraries, and Embedded Content
2. Add:
   - `libbyedpi.a` (after building with script)
   - SystemConfiguration.framework
   - Network.framework

### Step 8: Info.plist Configurations

**Main App Info.plist:**
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>ByeByeDPI needs network access to bypass DPI restrictions</string>
```

**Packet Tunnel Info.plist:**
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.networkextension.packet-tunnel</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).PacketTunnelProvider</string>
</dict>
```

## Building byedpi Library

Before building the app, compile the byedpi library:

```bash
cd Scripts
./build_byedpi.sh
```

This creates `build/ios/libbyedpi.a` which needs to be added to the project.

## Entitlements Files

Create entitlements files for both targets:

**ByeByeDPI.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.byebyedpi</string>
    </array>
</dict>
</plist>
```

**PacketTunnel.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.byebyedpi</string>
    </array>
</dict>
</plist>
```

## Build Schemes

Create separate schemes for:
1. **ByeByeDPI** - Main app
2. **PacketTunnel** - For debugging the extension

To debug the extension:
1. Edit Scheme → Ask on Launch
2. Select PacketTunnel extension

## Testing Checklist

- [ ] Project builds without errors
- [ ] Network Extension capability is enabled
- [ ] App Groups are configured correctly
- [ ] byedpi library is linked
- [ ] Can run on physical device
- [ ] VPN permission dialog appears
- [ ] Connection can be established
- [ ] Settings are saved and loaded
- [ ] Extension runs in background

## Common Build Issues

### "No such module 'NetworkExtension'"
- Ensure deployment target is iOS 9.0+
- Check that Network Extension capability is added

### "Undefined symbols for architecture arm64"
- Verify byedpi library is built for correct architecture
- Check library search paths in build settings

### "Code signing is required for product type 'Network Extension'"
- Ensure development team is selected
- Check bundle identifier is unique

## Next Steps After Setup

1. Test on physical device
2. Implement actual byedpi integration
3. Add logging and error handling
4. Optimize memory usage
5. Test background behavior
6. Prepare for App Store submission
