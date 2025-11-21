# DEPLOYMENT GUIDE

Step-by-step instructions for building and deploying the AR Livestream Overlay system.

---

## Prerequisites

### Software Requirements
- **Unity 2022.3 LTS** (or newer)
- **Visual Studio 2022** (or VS Code with C# extension)
- **OBS Studio 28+** (for virtual camera output)
- **Git** (for cloning MediaPipe plugins)

### Hardware Requirements
- **CPU:** Intel i5-9600K / AMD Ryzen 5 3600 or better
- **GPU:** NVIDIA GTX 1660 / AMD RX 580 or better
- **RAM:** 8GB minimum, 16GB recommended
- **Webcam:** 720p minimum, 1080p recommended
- **Microphone:** Any USB or built-in mic

### Unity Packages (Install via Package Manager)
```
com.unity.xr.arfoundation@5.1.2
com.unity.xr.arkit@5.1.2
com.unity.xr.arcore@5.1.2
com.unity.render-pipelines.universal@14.0.9
com.unity.textmeshpro@3.0.6
com.unity.cinemachine@2.9.7
```

---

## Installation Steps

### 1. Clone/Download Repository
```bash
git clone https://github.com/super-reality-studios/ar-livestream-overlay.git
cd ar-livestream-overlay
```

### 2. Open in Unity
1. Launch Unity Hub
2. Click "Open" → Select `ARLivestreamOverlay` folder
3. Unity will import packages (may take 5-10 minutes)

### 3. Install MediaPipe Plugin
```bash
# Clone MediaPipe Unity plugin
git clone https://github.com/homuler/MediaPipeUnityPlugin.git
cd MediaPipeUnityPlugin

# Follow plugin's installation instructions
# Copy built libraries to Assets/Plugins/
```

### 4. Install Vosk Speech Model
1. Download Vosk model: [vosk-model-small-en-us-0.15](https://alphacephei.com/vosk/models)
2. Extract to `Assets/StreamingAssets/Vosk/`
3. Verify path: `Assets/StreamingAssets/Vosk/vosk-model-small-en-us-0.15/`

### 5. Configure Build Settings
1. `File` → `Build Settings`
2. Select platform:
   - **Windows:** PC, Mac & Linux Standalone
   - **Mobile:** iOS or Android
3. Click `Switch Platform`
4. Add scene: `Assets/Scenes/MainARScene.unity`

---

## Build Process

### Desktop Build (Windows/Mac/Linux)

#### Development Build
```
1. File → Build Settings
2. ✅ Development Build
3. ✅ Script Debugging
4. Click "Build and Run"
5. Choose output folder (e.g., Builds/Desktop/)
```

#### Production Build
```
1. File → Build Settings
2. ❌ Development Build (uncheck)
3. Player Settings:
   - Company Name: Super Reality Studios
   - Product Name: AR Livestream Overlay
   - Version: 1.0.0
   - Icon: Set custom icon
4. Click "Build"
5. Choose output folder (e.g., Release/v1.0.0/)
```

### Mobile Build (iOS/Android)

#### iOS
```
1. Build Settings → iOS
2. Player Settings:
   - Camera Usage Description: "AR tracking for livestream overlay"
   - Microphone Usage Description: "Voice commands for AR control"
   - Target iOS: 13.0+
3. Build to Xcode project
4. Open .xcodeproj in Xcode
5. Sign with Apple Developer account
6. Build and deploy to device
```

#### Android
```
1. Build Settings → Android
2. Player Settings:
   - Minimum API Level: Android 7.0 (API 24)
   - Target API Level: Android 13 (API 33)
   - Scripting Backend: IL2CPP
   - ARM64: ✅
3. Build to .apk or .aab
4. Install via ADB or Google Play Console
```

---

## OBS Integration

### Setup Virtual Camera Output

#### Windows
1. Install **OBS Studio 28+**
2. Install **OBS VirtualCam** plugin (built-in as of v28)
3. In Unity:
   - `VirtualCameraOutput` component → Enable
   - Output Resolution: 1920x1080
   - Target FPS: 30
4. In OBS:
   - Sources → Add → Video Capture Device
   - Device: "OBS Virtual Camera"
   - Resolution: 1920x1080

#### macOS
1. Install **OBS Studio 28+**
2. Install **obs-mac-virtualcam** plugin
3. Restart OBS and follow Windows steps

#### Linux
1. Install **v4l2loopback** kernel module:
   ```bash
   sudo apt install v4l2loopback-dkms
   sudo modprobe v4l2loopback
   ```
2. In Unity, set output device to `/dev/video0`
3. In OBS, add Video Capture Device → `/dev/video0`

---

## RTMP Streaming (Direct)

### Setup RTMP Push (Alternative to OBS)

1. Get RTMP URL from streaming platform:
   - **Twitch:** `rtmp://live.twitch.tv/app/{stream_key}`
   - **YouTube:** `rtmp://a.rtmp.youtube.com/live2/{stream_key}`
   - **Custom:** `rtmp://your-server.com/live/{stream_key}`

2. In Unity:
   - `RTMPStreamOutput` component → Enable
   - Set RTMP URL
   - Set stream key (keep secret!)

3. Start application → Streaming begins automatically

---

## Configuration

### Performance Tuning

#### Low-End Hardware (30 FPS)
```csharp
// In ARLivestreamManager
targetFrameRate = 30;
outputResolution = new Vector2Int(1280, 720);

// In HandGestureRecognizer
config.confidenceThreshold = 0.8f;
```

#### High-End Hardware (60 FPS)
```csharp
targetFrameRate = 60;
outputResolution = new Vector2Int(1920, 1080);
config.confidenceThreshold = 0.7f;
```

### Custom Gestures
Edit `Assets/Scripts/Perception/HandGestureRecognizer.cs`:
```csharp
private bool IsCustomGesture(Vector3[] lm)
{
    // Define your custom landmark logic
    bool condition1 = lm[8].y > lm[0].y;
    bool condition2 = lm[12].x < lm[9].x;
    return condition1 && condition2;
}
```

### Voice Commands
Edit `Assets/Scripts/Perception/VoiceCommandListener.cs`:
```csharp
private string[] supportedCommands = new string[]
{
    "shift mode",
    "boost it",
    "your custom command"  // Add here
};
```

---

## Testing Checklist

### Pre-Deployment Tests
- [ ] Camera feed displays in Unity Game View
- [ ] Microphone captures audio (check volume indicator)
- [ ] Gesture recognition works (test with keyboard 1-5)
- [ ] Voice commands work (test with keyboard B, C, P, M, H)
- [ ] State machine transitions correctly
- [ ] HUD displays current state
- [ ] AR objects spawn (portals, aura)
- [ ] OBS receives video feed
- [ ] FPS stays above 30
- [ ] No console errors

### Post-Build Tests
- [ ] Standalone .exe launches without errors
- [ ] Camera/mic permissions granted (mobile)
- [ ] Real gesture recognition works
- [ ] Real voice recognition works
- [ ] OBS integration functional
- [ ] Stream quality acceptable
- [ ] No memory leaks (1-hour test)
- [ ] Performance stable

---

## Distribution

### Desktop (Windows)
```
ARLivestreamOverlay/
├── ARLivestreamOverlay.exe
├── ARLivestreamOverlay_Data/
├── UnityPlayer.dll
├── UnityCrashHandler64.exe
└── README.txt
```

Distribute as:
- **ZIP archive** (for direct download)
- **Installer** (Inno Setup, NSIS)
- **Steam build** (Steamworks SDK)

### Mobile (iOS/Android)
- **iOS:** Distribute via TestFlight or App Store
- **Android:** Distribute via APK, Google Play, or F-Droid

---

## Troubleshooting

### Build Errors

#### "MediaPipe library not found"
- Ensure MediaPipe plugin is in `Assets/Plugins/`
- Check platform-specific libraries exist

#### "Vosk model not found"
- Verify StreamingAssets path
- Check model folder name matches code

### Runtime Issues

#### Low FPS
1. Lower resolution: 1080p → 720p
2. Reduce hand tracking frequency
3. Disable debug visualization
4. Close background applications

#### Gesture Not Detected
1. Check lighting
2. Increase `gestureHoldDuration`
3. Lower `confidenceThreshold`

#### No Audio/Video in OBS
1. Restart OBS
2. Check virtual camera device in Unity
3. Verify OBS source settings

---

## Support

**Documentation:** [docs.superrealitystudios.com/ar-overlay](https://docs.superrealitystudios.com/ar-overlay)  
**Issues:** [GitHub Issues](https://github.com/super-reality-studios/ar-livestream-overlay/issues)  
**Discord:** [Super Reality Studios Community](https://discord.gg/superreality)

---

**Last Updated:** 2025-11-21  
**Version:** 1.0
