# AR Livestream Overlay System

**Real-time AR overlay system for livestream content creators**

[![Unity](https://img.shields.io/badge/Unity-2022.3_LTS-black?logo=unity)](https://unity.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20iOS%20%7C%20Android-lightgrey)]()

---

## Overview

AR Livestream Overlay is a prototype system that adds interactive AR elements to live video streams. Designed for content creator Rex (Super Reality Studios), this system recognizes hosts in frame, responds to gestures and voice commands, and outputs a composited video feed to OBS or RTMP.

### Key Features

✨ **Always-On AR Overlay** - Composites AR elements over live camera feed  
🎭 **Host Detection** - Recognizes when host enters/exits frame  
👋 **Gesture Recognition** - Detects raise hand, wave, point, peace, fist via MediaPipe  
🎤 **Voice Commands** - Responds to "boost it", "chill it", "portal", "shift mode"  
🎬 **State Machine** - 5 states: IDLE_WORLD, HOST_DETECTED, INTERACTION_ACTIVE, OVERDRIVE, COOLDOWN  
📺 **OBS Integration** - Outputs to OBS Virtual Camera or RTMP stream  
⚡ **Real-Time Performance** - 30-60 FPS on mid-tier hardware  

---

## Quick Start

### Installation

```bash
# Clone repository
git clone https://github.com/super-reality-studios/ar-livestream-overlay.git

# Open in Unity 2022.3 LTS
# Unity Hub → Open → Select ARLivestreamOverlay folder

# Install Unity packages (via Package Manager)
# - AR Foundation 5.x
# - Universal Render Pipeline
# - TextMeshPro

# Download Vosk speech model
# https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip
# Extract to Assets/StreamingAssets/Vosk/
```

### Run Demo

1. Open scene: `Assets/Scenes/MainARScene.unity`
2. Press **Play** in Unity Editor
3. Test gestures with keyboard:
   - `1` = Raise Hand
   - `2` = Wave
   - `3` = Point
   - `B` = "Boost It" (voice)
   - `C` = "Chill It" (voice)
   - `P` = "Portal" (voice)
4. Watch state transitions in HUD

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  ARLivestreamManager                     │
│                   (Main Orchestrator)                    │
└───────┬─────────────────────────────────────────┬───────┘
        │                                         │
┌───────▼──────────┐                     ┌────────▼────────┐
│  INPUT LAYER     │                     │  OUTPUT LAYER   │
│                  │                     │                 │
│ • Camera Feed    │                     │ • Virtual Camera│
│ • Microphone     │                     │ • RTMP Stream   │
│ • Chat API       │                     │ • Compositor    │
└───────┬──────────┘                     └─────────────────┘
        │
┌───────▼──────────┐
│ PERCEPTION LAYER │      ┌─────────────────────────────┐
│                  │      │     STATE MACHINE           │
│ • Face Tracking  ├─────▶│                             │
│ • Body Tracking  │      │ ┌─────────────────────────┐ │
│ • Hand Gestures  │      │ │ IDLE_WORLD              │ │
│ • Voice Commands │      │ │   ↓                     │ │
└──────────────────┘      │ │ HOST_DETECTED           │ │
                          │ │   ↓                     │ │
                          │ │ INTERACTION_ACTIVE      │ │
                          │ │   ↓                     │ │
┌─────────────────────┐   │ │ OVERDRIVE               │ │
│   AR SCENE LAYER    │   │ │   ↓                     │ │
│                     │◀──┤ │ COOLDOWN                │ │
│ • HUD Controller    │   │ └─────────────────────────┘ │
│ • World Anchors     │   └─────────────────────────────┘
│ • Body Anchors      │
│ • Particle Effects  │
└─────────────────────┘
```

---

## State Machine

| State | Description | Trigger to Enter | Duration |
|-------|-------------|------------------|----------|
| **IDLE_WORLD** | Ambient AR only, no host | App start, cooldown expires | Indefinite |
| **HOST_DETECTED** | Host in frame, light aura | Host enters frame | Until gesture or exit |
| **INTERACTION_ACTIVE** | Full AR effects active | Raise hand or wave | Until idle or exit |
| **OVERDRIVE** | Maximum effects, high energy | Voice: "boost it" | 10 seconds |
| **COOLDOWN** | Fade-out period | OVERDRIVE expires, host exits | 5 seconds |

---

## Gestures

| Gesture | Keyboard | Effect |
|---------|----------|--------|
| **Raise Hand** 🙋 | `1` | Enter INTERACTION_ACTIVE |
| **Wave** 👋 | `2` | Enter INTERACTION_ACTIVE |
| **Point** 👉 | `3` | Directional indicator |
| **Peace** ✌️ | `4` | Emote effect |
| **Fist** ✊ | `5` | Intensity boost |

## Voice Commands

| Command | Keyboard | Effect |
|---------|----------|--------|
| **"boost it"** | `B` | Enter OVERDRIVE |
| **"chill it"** | `C` | Exit OVERDRIVE |
| **"portal"** | `P` | Spawn world portal |
| **"shift mode"** | `M` | Cycle states (debug) |
| **"highlight chat"** | `H` | Toggle chat overlay |

---

## Documentation

- 📘 **[AR_LIVESTREAM_MASTER_DESIGN.md](AR_LIVESTREAM_MASTER_DESIGN.md)** - Complete architecture & design
- 📗 **[GESTURE_LIBRARY.md](Documentation/GESTURE_LIBRARY.md)** - Gesture reference & tuning
- 📕 **[DEPLOYMENT_GUIDE.md](Documentation/DEPLOYMENT_GUIDE.md)** - Build & deployment instructions

---

## Requirements

### Software
- Unity 2022.3 LTS or newer
- AR Foundation 5.x
- MediaPipe Unity Plugin
- Vosk Speech Recognition

### Hardware (Minimum)
- **CPU:** Intel i5-9600K / AMD Ryzen 5 3600
- **GPU:** NVIDIA GTX 1660 / AMD RX 580
- **RAM:** 8GB
- **Webcam:** 720p
- **Microphone:** Any

### Hardware (Recommended)
- **CPU:** Intel i7-12700K / AMD Ryzen 7 5800X
- **GPU:** NVIDIA RTX 3060 / AMD RX 6700 XT
- **RAM:** 16GB
- **Webcam:** 1080p@60fps
- **Microphone:** USB condenser mic

---

## Project Structure

```
ARLivestreamOverlay/
├── Scripts/
│   ├── Core/                    # Main orchestrator
│   ├── Input/                   # Camera, mic handlers
│   ├── Perception/              # Gesture, voice, body tracking
│   ├── StateMachine/            # State controller & states
│   ├── ARScene/                 # HUD, AR objects, effects
│   ├── Output/                  # Virtual camera, RTMP
│   └── Utilities/               # Debug, logging, performance
├── Scenes/
│   └── MainARScene.unity        # Primary scene
├── Prefabs/
│   ├── AR/                      # HUD, portals, auras
│   └── UI/                      # Debug panels
├── Documentation/
│   ├── GESTURE_LIBRARY.md
│   └── DEPLOYMENT_GUIDE.md
└── README.md                    # This file
```

---

## Development

### Adding Custom Gesture

Edit `HandGestureRecognizer.cs`:
```csharp
private bool IsCustomGesture(Vector3[] landmarks)
{
    // Define your landmark logic
    Vector3 wrist = landmarks[0];
    Vector3 indexTip = landmarks[8];
    return indexTip.y > wrist.y + 0.2f;
}
```

### Adding Voice Command

Edit `VoiceCommandListener.cs`:
```csharp
private string[] supportedCommands = new string[]
{
    "your command here",
    "another command"
};
```

### Tuning Performance

```csharp
// ARLivestreamManager.cs
targetFrameRate = 30;              // Lower for weaker hardware
outputResolution = new Vector2Int(1280, 720);  // 720p instead of 1080p

// HandGestureRecognizer.cs
config.confidenceThreshold = 0.8f;  // Higher = fewer false positives
```

---

## Testing

### Unit Tests
```
Assets/Tests/EditMode/
├── HandGestureRecognizerTests.cs
├── VoiceCommandListenerTests.cs
└── ARStateMachineTests.cs
```

### Integration Tests
```
Assets/Tests/PlayMode/
├── EndToEndFlowTests.cs
├── StateTransitionTests.cs
└── PerformanceTests.cs
```

Run tests: `Window` → `General` → `Test Runner`

---

## Performance

### Target Metrics
- **FPS:** 30+ (desktop), 60+ (high-end)
- **Latency:** <200ms input-to-output
- **Memory:** <2GB RAM usage
- **CPU:** <60% on 4-core i5
- **GPU:** <70% on GTX 1660

### Optimization Tips
1. Lower output resolution (1080p → 720p)
2. Reduce hand tracking frequency (30Hz → 15Hz)
3. Disable debug visualization in production
4. Use URP (Universal Render Pipeline)
5. Bake lighting where possible

---

## Roadmap

### MVP (Phase 1) ✅
- [x] Core state machine
- [x] Gesture recognition (5 gestures)
- [x] Voice commands (5 commands)
- [x] OBS virtual camera output
- [x] Basic HUD

### Phase 2 (Production)
- [ ] Mobile deployment (iOS/Android)
- [ ] Custom 3D assets (replace primitives)
- [ ] Sound effects & audio feedback
- [ ] Chat overlay (Twitch API)
- [ ] RTMP direct streaming

### Phase 3 (Advanced)
- [ ] Multi-user tracking
- [ ] ML custom gesture training
- [ ] Cloud save/load AR scenes
- [ ] Audience interaction (chat → AR)
- [ ] Analytics dashboard

---

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/YourFeature`)
3. Commit changes (`git commit -m 'Add YourFeature'`)
4. Push to branch (`git push origin feature/YourFeature`)
5. Open Pull Request

See `CONTRIBUTING.md` for detailed guidelines.

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Support

- **Documentation:** [docs.superrealitystudios.com](https://docs.superrealitystudios.com)
- **Issues:** [GitHub Issues](https://github.com/super-reality-studios/ar-livestream-overlay/issues)
- **Discord:** [Super Reality Studios](https://discord.gg/superreality)
- **Email:** support@superrealitystudios.com

---

## Credits

**Project Lead:** Rex @ Super Reality Studios  
**Engine:** Unity Technologies  
**AR Foundation:** Unity XR Team  
**Hand Tracking:** Google MediaPipe  
**Speech Recognition:** Alpha Cephei (Vosk)

---

**Built with ❤️ for content creators**
