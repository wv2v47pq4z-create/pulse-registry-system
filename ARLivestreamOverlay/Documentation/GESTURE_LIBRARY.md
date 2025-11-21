# GESTURE LIBRARY

Complete reference for gestures recognized by the AR Livestream Overlay system.

---

## Quick Reference

| Gesture | Trigger | State Change | Keyboard Shortcut |
|---------|---------|--------------|-------------------|
| **Raise Hand** | All fingers extended upward | HOST_DETECTED → INTERACTION_ACTIVE | `1` |
| **Wave** | Hand moving side-to-side | HOST_DETECTED → INTERACTION_ACTIVE | `2` |
| **Point** | Index finger extended | None (UI interaction) | `3` |
| **Peace** | Index + middle extended | None (emote) | `4` |
| **Fist** | All fingers closed | None (emote) | `5` |
| **Hands on Head** | Both hands above head | Emergency exit to IDLE | (Not simulated) |

---

## Detailed Gesture Specifications

### 1. Raise Hand 🙋
**Purpose:** Activate AR interaction mode  
**Detection:** All five fingertips above wrist level  
**Hand:** Either left or right  
**State Transition:** HOST_DETECTED → INTERACTION_ACTIVE  

**MediaPipe Landmarks:**
- Thumb tip (4), Index tip (8), Middle tip (12), Ring tip (16), Pinky tip (20)
- All must be Y > Wrist Y (landmark 0)

**Use Cases:**
- Start AR effects
- Request attention
- Signal readiness

---

### 2. Wave 👋
**Purpose:** Greet audience, activate interaction  
**Detection:** Hand moving horizontally with open palm  
**Hand:** Either left or right  
**State Transition:** HOST_DETECTED → INTERACTION_ACTIVE  

**Detection Logic:**
- Wrist velocity in X-axis > threshold
- Palm facing forward (fingers extended)
- Movement repeats 2+ times in 1 second

**Use Cases:**
- Greeting at stream start
- Re-engage after idle
- Casual activation

---

### 3. Point 👉
**Purpose:** Directional indicator, UI interaction  
**Detection:** Index extended, other fingers folded  
**Hand:** Either left or right  
**State Transition:** None (in-state action)  

**MediaPipe Landmarks:**
- Index tip (8) Y > Index knuckle (5) Y
- Middle tip (12) Y < Middle knuckle (9) Y
- Ring and pinky folded

**Use Cases:**
- Highlight screen area
- Direct viewer attention
- Select UI elements

---

### 4. Peace ✌️
**Purpose:** Emote, celebratory gesture  
**Detection:** Index + middle extended, others folded  
**Hand:** Either left or right  
**State Transition:** None (triggers emote effect)  

**MediaPipe Landmarks:**
- Index tip (8) Y > Index knuckle (5) Y
- Middle tip (12) Y > Middle knuckle (9) Y
- Ring (16) and pinky (20) folded

**Use Cases:**
- Victory celebration
- Playful emote
- Photo pose

---

### 5. Fist ✊
**Purpose:** Power gesture, intensity increase  
**Detection:** All fingers closed around palm  
**Hand:** Either left or right  
**State Transition:** None (increases effect intensity)  

**MediaPipe Landmarks:**
- All fingertips (8, 12, 16, 20) Y < respective knuckles
- Thumb wrapped around fingers

**Use Cases:**
- Power-up visual
- Intensity boost
- Dramatic effect

---

### 6. Hands on Head 🙆
**Purpose:** Emergency reset, exit interaction  
**Detection:** Both hands above head level  
**Hand:** Both required  
**State Transition:** ANY → IDLE_WORLD  

**Detection Logic:**
- Both wrist Y positions > head Y position
- Held for 1 second minimum
- Failsafe gesture

**Use Cases:**
- Immediate exit from OVERDRIVE
- Reset stuck state
- Emergency stop

---

## Voice Commands

| Command | Trigger Phrase | State Change | Keyboard Shortcut |
|---------|----------------|--------------|-------------------|
| **Boost It** | "boost it" | INTERACTION_ACTIVE → OVERDRIVE | `B` |
| **Chill It** | "chill it" | OVERDRIVE → HOST_DETECTED | `C` |
| **Portal** | "portal" | Spawn world portal (any state) | `P` |
| **Shift Mode** | "shift mode" | Cycle states (debug) | `M` |
| **Highlight Chat** | "highlight chat" | Toggle chat overlay | `H` |

---

## Gesture Configuration

### Tuning Parameters

```csharp
// In HandGestureRecognizer.cs
confidenceThreshold = 0.7f;      // Min confidence to trigger (0-1)
gestureHoldDuration = 0.5f;      // Seconds to hold gesture before trigger
handSmoothingFactor = 0.3f;      // Landmark smoothing (0=none, 1=max)
```

### False Positive Mitigation

1. **Hold Duration:** Gestures must be held for 0.5s to avoid accidental triggers
2. **Confidence Threshold:** 70% confidence minimum
3. **Cooldown:** 1-second cooldown after each trigger
4. **State Context:** Some gestures only work in specific states

---

## Testing Gestures

### With MediaPipe (Production)
1. Ensure webcam is active
2. Position hand in frame
3. Perform gesture clearly
4. Hold for 0.5 seconds
5. Watch for HUD feedback

### Keyboard Simulation (Development)
- Press number keys `1-5` to simulate gestures
- Press letter keys `B, C, P, M, H` for voice commands
- Press `Space` to toggle host detection

---

## Troubleshooting

### Gesture Not Detected
- ✅ Check lighting (need good visibility)
- ✅ Position hand clearly in frame
- ✅ Hold gesture for full 0.5 seconds
- ✅ Verify current state allows this gesture
- ✅ Check console for "Gesture detected" logs

### False Positives
- 🔧 Increase `confidenceThreshold` to 0.8 or 0.9
- 🔧 Increase `gestureHoldDuration` to 0.75s
- 🔧 Enable `handSmoothingFactor` to 0.5

### Lag/Delay
- ⚡ Reduce hand tracking frequency (30Hz → 15Hz)
- ⚡ Lower camera resolution (1080p → 720p)
- ⚡ Disable debug visualization

---

## Future Gestures (Roadmap)

- **Thumbs Up:** Approval, like
- **Swipe:** Navigate UI
- **Pinch:** Grab/manipulate objects
- **Circle:** Spawn particle ring
- **Custom Trained:** User-defined gestures via ML

---

**Last Updated:** 2025-11-21  
**Version:** 1.0
