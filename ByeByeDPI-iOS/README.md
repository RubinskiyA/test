# ByeByeDPI for iOS

iOS port of [ByeByeDPI Android](https://github.com/romanvht/ByeByeDPI) - an application that uses [byedpi](https://github.com/ValdikSS/byedpi) to bypass DPI (Deep Packet Inspection) systems.

## Architecture

This project follows the same architecture as the Android version:

```
┌─────────────────────────────────────────────────────────┐
│                   Main App (SwiftUI)                    │
│  - User Interface                                       │
│  - Settings Management                                  │
│  - VPN Connection Control                               │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Network Extension (Packet Tunnel)          │
│  - NEPacketTunnelProvider                               │
│  - Traffic Interception                                 │
│  - byedpi Integration                                   │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                  ByeDPICore (C + Swift)                 │
│  - byedpi C library                                     │
│  - hev-socks5-tunnel                                    │
│  - Swift wrapper                                        │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```
ByeByeDPI-iOS/
├── ByeByeDPI/              # Main application (SwiftUI)
│   ├── ByeByeDPIApp.swift
│   ├── ContentView.swift
│   └── SettingsView.swift
├── PacketTunnel/           # Network Extension
│   └── PacketTunnelProvider.swift
├── Shared/                 # Shared code between app and extension
│   ├── VPNManager.swift
│   └── SettingsManager.swift
├── ByeDPICore/             # byedpi C library + Swift wrapper
│   ├── include/
│   │   └── ByeDpiProxy.h
│   └── ByeDpiProxy.swift
└── Scripts/
    └── build_byedpi.sh     # Build script for byedpi
```

## Requirements

- iOS 14.0+
- Xcode 14.0+
- Apple Developer Account (for Network Extension capability)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/romanvht/ByeByeDPI-iOS.git
cd ByeByeDPI-iOS
```

### 2. Get byedpi Source

The build script will automatically clone byedpi, or you can do it manually:

```bash
git clone https://github.com/ValdikSS/byedpi.git ../byedpi
```

### 3. Build byedpi Library

```bash
./Scripts/build_byedpi.sh
```

This will compile byedpi for iOS and create a static library.

### 4. Open in Xcode

```bash
open ByeByeDPI.xcodeproj
```

### 5. Configure Capabilities

In Xcode, enable the following capabilities:

**Main App Target:**
- Network Extensions
- App Groups (create a group like `group.com.byebyedpi`)

**Packet Tunnel Extension Target:**
- Network Extensions
- App Groups (same group as main app)

### 6. Build and Run

1. Select your development team in both targets
2. Choose a physical device (Network Extension doesn't work on simulator)
3. Build and run

## Features

### DPI Bypass Profiles

- **Default**: Standard bypass strategy with disorder and auto mode
- **Aggressive**: More aggressive methods including fake packets
- **Conservative**: Minimal packet modifications
- **Custom**: User-defined parameters

### Advanced Settings

- Enable/disable fake packets
- Enable/disable disorder
- Auto mode toggle
- TTL adjustment (1-255)
- Max open files limit

## How It Works

1. **User taps Connect** in the main app
2. **VPNManager** configures and starts the Network Extension
3. **PacketTunnelProvider** creates a virtual network interface (utun)
4. **byedpi** intercepts and modifies packets to bypass DPI
5. All traffic is routed through the tunnel

## Comparison with Android Version

| Component | Android | iOS |
|-----------|---------|-----|
| UI | Kotlin/Jetpack Compose | SwiftUI |
| VPN Service | VpnService | NEPacketTunnelProvider |
| Background Service | Foreground Service | Background Modes |
| Settings | SharedPreferences | UserDefaults |
| Native Bridge | JNI | C-bridge/Swift |
| byedpi | NDK build | iOS cross-compile |
| hev-socks5-tunnel | NDK | Native iOS build |

## Important Notes

### App Store Considerations

⚠️ **Warning**: Apps that provide VPN functionality may require additional justification during App Store Review. Be prepared to explain:
- The purpose of the DPI bypass functionality
- How user privacy is protected
- Why VPN access is necessary

### Background Execution

iOS has stricter background execution limits than Android. The Network Extension will continue running while:
- The app is in use
- Device is unlocked
- System resources are available

### Memory Limits

Network Extensions have a memory limit of approximately 15-20MB. Monitor memory usage carefully.

### Testing

- Test on physical devices only (simulator doesn't support Network Extensions)
- Test with various DPI scenarios
- Monitor battery impact
- Verify behavior when app is backgrounded

## Development

### Building byedpi Manually

```bash
cd ../byedpi
export SDK=$(xcrun --sdk iphoneos --show-sdk-path)
export CC=$(xcrun --sdk iphoneos --find clang)
export CFLAGS="-arch arm64 -isysroot $SDK -miphoneos-version-min=14.0"

$CC $CFLAGS -c byedpi.c desync.c tcp.c udp.c misc.c
ar rcs libbyedpi.a *.o
```

### Debugging

To debug the Network Extension:

1. In Xcode: Edit Scheme → Ask on Launch
2. Select "PacketTunnel" extension
3. Run and attach debugger

### Logs

View logs using Console.app:
- Filter by subsystem: `com.byebyedpi`
- Or by process: `PacketTunnel`

## Troubleshooting

### Common Issues

**"VPN configuration is invalid"**
- Ensure Network Extension capability is enabled
- Check bundle identifiers match
- Verify App Groups are configured

**Extension crashes on start**
- Check memory usage
- Verify byedpi library is properly linked
- Review device logs in Console.app

**Can't connect on first try**
- iOS requires user permission for VPN
- First connection will show system dialog
- Grant permission and try again

## License

This project inherits the license from the original [ByeByeDPI Android](https://github.com/romanvht/ByeByeDPI) and [byedpi](https://github.com/ValdikSS/byedpi) projects.

## Credits

- Original Android app: [romanvht/ByeByeDPI](https://github.com/romanvht/ByeByeDPI)
- DPI bypass engine: [ValdikSS/byedpi](https://github.com/ValdikSS/byedpi)
- Socks5 tunnel: [hev-project/hev-socks5-tunnel](https://github.com/hev-project/hev-socks5-tunnel)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
