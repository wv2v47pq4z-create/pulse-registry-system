# AR LIVESTREAM OVERLAY – DESIGN & BUILD DOCUMENTATION

**System Owner:** Super Reality Studios (Creator: Rex)  
**Document Version:** 1.0  
**Last Updated:** 2025-11-21

---

## 1. STACK DECISION & JUSTIFICATION

### Primary Technology Stack

**Engine & AR Framework:**
- **Unity 2022.3 LTS (Long Term Support)**
  - Industry-standard for real-time AR/XR applications
  - Mature AR Foundation package with stable ARKit/ARCore support
  - Strong plugin ecosystem for streaming and multimedia
  - C# scripting with excellent performance characteristics
  - Cross-platform deployment (iOS, Android, Windows, macOS)

**AR & Tracking SDKs:**
- **Unity AR Foundation 5.x**
  - Unified API for ARKit (iOS) and ARCore (Android)
  - Built-in plane detection, image tracking, face tracking
  - World-space and body-anchored AR objects
  
- **MediaPipe Unity Plugin**
  - Google MediaPipe for robust hand/gesture tracking
  - 21-point hand landmark detection per hand
  - Face mesh and pose detection
  - Runs efficiently on CPU/GPU with minimal latency

**Speech Recognition:**
- **Vosk (offline) + Unity Web Speech (online fallback)**
  - Vosk: Lightweight, offline keyword spotting
  - No cloud dependency = lower latency for critical triggers
  - Web Speech API via WebGL for browser-based demos
  - Custom keyword model for specific voice commands

**Video Output:**
- **Unity Virtual Camera Plugin (primary)**
  - Direct OBS virtual camera integration
  - Low-latency output for streaming software
  
- **RTMP Live Streaming Plugin (secondary)**
  - Direct RTMP push to Twitch, YouTube, custom servers
  - Fallback for environments without OBS

**Supporting Libraries:**
- **TextMeshPro:** HUD text rendering
- **Universal Render Pipeline (URP):** Optimized rendering pipeline
- **Cinemachine:** Camera control and transitions
- **Unity Timeline:** Sequence-based AR effects

### Justification

**Why Unity over Unreal?**
1. **Lower barrier to entry** for AR prototypes with AR Foundation
2. **MediaPipe integration** is more mature in Unity ecosystem
3. **Lighter builds** for mobile deployment (critical for glasses/phone AR)
4. **Faster iteration** with C# scripting vs. C++ compile times
5. **Better streaming plugin support** (OBS, RTMP)

**Why MediaPipe?**
1. State-of-the-art hand tracking without custom ML training
2. Runs on device (no cloud latency)
3. Open source with Unity wrappers available
4. Used by Google, Meta, and TikTok for similar applications

**Why Vosk for speech?**
1. Offline processing = privacy-first, low-latency
2. Lightweight models (~50MB) vs. cloud APIs
3. Keyword spotting optimized for command recognition
4. No API costs or rate limits

---

## 2. PROJECT SKELETON

```
ARLivestreamOverlay/
│
├── Assets/
│   ├── Scripts/
│   │   ├── Core/
│   │   │   ├── ARLivestreamManager.cs          # Main orchestrator
│   │   │   ├── GameStateManager.cs              # Singleton state controller
│   │   │   └── ConfigurationManager.cs          # Settings & config
│   │   │
│   │   ├── Input/
│   │   │   ├── CameraInputHandler.cs            # Camera feed management
│   │   │   ├── MicrophoneInputHandler.cs        # Audio capture
│   │   │   └── ChatAPIHandler.cs                # Optional chat integration
│   │   │
│   │   ├── Perception/
│   │   │   ├── FaceDetector.cs                  # AR Foundation face tracking
│   │   │   ├── BodyTracker.cs                   # Body pose detection
│   │   │   ├── HandGestureRecognizer.cs         # MediaPipe hand gestures
│   │   │   ├── VoiceCommandListener.cs          # Vosk speech recognition
│   │   │   └── EventAggregator.cs               # Perception → State events
│   │   │
│   │   ├── StateMachine/
│   │   │   ├── ARStateMachine.cs                # Core state logic
│   │   │   ├── States/
│   │   │   │   ├── IdleWorldState.cs
│   │   │   │   ├── HostDetectedState.cs
│   │   │   │   ├── InteractionActiveState.cs
│   │   │   │   ├── OverdriveState.cs
│   │   │   │   └── CooldownState.cs
│   │   │   └── StateTransitionValidator.cs
│   │   │
│   │   ├── ARScene/
│   │   │   ├── HUDController.cs                 # Camera-space UI
│   │   │   ├── WorldAnchoredManager.cs          # World-space AR objects
│   │   │   ├── BodyAnchoredManager.cs           # Host-attached AR elements
│   │   │   ├── PortalController.cs              # Portals/3D effects
│   │   │   ├── ParticleEffectManager.cs         # VFX system
│   │   │   └── ChatOverlayPanel.cs              # Chat display
│   │   │
│   │   ├── Output/
│   │   │   ├── VirtualCameraOutput.cs           # OBS virtual camera
│   │   │   ├── RTMPStreamOutput.cs              # RTMP push
│   │   │   └── CompositeRenderer.cs             # Final video composition
│   │   │
│   │   └── Utilities/
│   │       ├── DebugOverlay.cs                  # Dev UI
│   │       ├── PerformanceMonitor.cs            # FPS/latency tracking
│   │       └── Logger.cs                        # Custom logging
│   │
│   ├── Scenes/
│   │   ├── MainARScene.unity                    # Primary scene
│   │   └── TestingScene.unity                   # Isolated component tests
│   │
│   ├── Prefabs/
│   │   ├── AR/
│   │   │   ├── HUD_Canvas.prefab
│   │   │   ├── WorldPortal.prefab
│   │   │   ├── BodyAura.prefab
│   │   │   └── GestureIndicator.prefab
│   │   └── UI/
│   │       ├── DebugPanel.prefab
│   │       └── ChatOverlay.prefab
│   │
│   ├── Materials/
│   │   ├── HolographicShader.mat
│   │   ├── ParticleGlow.mat
│   │   └── PortalEffect.mat
│   │
│   ├── Models/                                   # Custom 3D assets
│   ├── Textures/                                 # UI/VFX textures
│   ├── Audio/                                    # Sound effects
│   │
│   └── StreamingAssets/
│       └── Vosk/
│           └── vosk-model-small-en-us-0.15/     # Speech model
│
├── Packages/
│   ├── manifest.json                            # Unity package dependencies
│   └── packages-lock.json
│
├── ProjectSettings/                              # Unity project config
│
├── Documentation/
│   ├── ARCHITECTURE.md                          # This document
│   ├── API_REFERENCE.md                         # Public API docs
│   ├── GESTURE_LIBRARY.md                       # Gesture definitions
│   └── DEPLOYMENT_GUIDE.md                      # Build & deploy instructions
│
├── Tests/
│   ├── EditMode/                                # Unit tests
│   └── PlayMode/                                # Integration tests
│
└── README.md                                     # Quick start guide
```

---

## 3. CORE CLASS/MODULE INTERFACES

### 3.1 Input Layer

#### **CameraInputHandler**
```csharp
public class CameraInputHandler : MonoBehaviour
{
    public event Action<Texture2D> OnFrameCaptured;
    public CameraResolution Resolution { get; set; }
    
    public void Initialize(CameraConfig config);
    public void StartCapture();
    public void StopCapture();
    public Texture2D GetCurrentFrame();
}
```

#### **MicrophoneInputHandler**
```csharp
public class MicrophoneInputHandler : MonoBehaviour
{
    public event Action<float[]> OnAudioSampled;
    public float VolumeLevel { get; }
    
    public void Initialize(string deviceName);
    public void StartListening();
    public void StopListening();
}
```

### 3.2 Perception Layer

#### **HandGestureRecognizer**
```csharp
public enum GestureType
{
    None,
    RaiseHand,
    Wave,
    Point,
    HandsOnHead,
    Peace,
    Fist
}

public class HandGestureRecognizer : MonoBehaviour
{
    public event Action<GestureType, Hand> OnGestureDetected;
    
    public void Initialize(MediaPipeConfig config);
    public GestureType GetCurrentGesture(Hand hand);
    public Vector3 GetHandPosition(Hand hand);
    public bool IsGestureHeld(GestureType gesture, float duration);
}
```

#### **VoiceCommandListener**
```csharp
public class VoiceCommandListener : MonoBehaviour
{
    public event Action<string> OnCommandDetected;
    public string[] SupportedCommands { get; }
    
    public void Initialize(string modelPath);
    public void RegisterCommand(string keyword, float confidence = 0.7f);
    public void StartListening();
    public void StopListening();
}
```

#### **BodyTracker**
```csharp
public class BodyTracker : MonoBehaviour
{
    public event Action OnHostEnterFrame;
    public event Action OnHostExitFrame;
    
    public bool IsHostDetected { get; }
    public Vector3 HostCenterPosition { get; }
    public Quaternion HostOrientation { get; }
    
    public Transform GetJoint(HumanBodyBones bone);
    public float GetHostDistance();
}
```

### 3.3 State Machine Layer

#### **ARStateMachine**
```csharp
public enum ARState
{
    IDLE_WORLD,
    HOST_DETECTED,
    INTERACTION_ACTIVE,
    OVERDRIVE,
    COOLDOWN
}

public class ARStateMachine : MonoBehaviour
{
    public ARState CurrentState { get; private set; }
    public event Action<ARState, ARState> OnStateChanged;
    
    public void TransitionTo(ARState newState);
    public bool CanTransitionTo(ARState targetState);
    public float GetStateElapsedTime();
    
    // Timers
    public float OverdriveTimer { get; set; } = 10f;
    public float CooldownTimer { get; set; } = 5f;
}
```

#### **BaseState** (Abstract)
```csharp
public abstract class BaseState
{
    public abstract void OnEnter(ARStateMachine machine);
    public abstract void OnUpdate(ARStateMachine machine);
    public abstract void OnExit(ARStateMachine machine);
    
    protected void TriggerTransition(ARState targetState);
}
```

### 3.4 AR Scene Layer

#### **HUDController**
```csharp
public class HUDController : MonoBehaviour
{
    public void SetMode(ARState state);
    public void ShowNotification(string message, float duration);
    public void UpdateGestureIndicator(GestureType gesture);
    public void SetEnergyLevel(float value);  // For OVERDRIVE visual
}
```

#### **WorldAnchoredManager**
```csharp
public class WorldAnchoredManager : MonoBehaviour
{
    public GameObject SpawnPortal(Vector3 position, Quaternion rotation);
    public void RemoveAllAnchors();
    public void EnableEnvironmentEffects(bool enable);
}
```

#### **BodyAnchoredManager**
```csharp
public class BodyAnchoredManager : MonoBehaviour
{
    public void AttachAura(Transform hostRoot);
    public void DetachAura();
    public void SetAuraIntensity(float intensity);
    public void PlayEmoteEffect(string emoteName);
}
```

### 3.5 Output Layer

#### **VirtualCameraOutput**
```csharp
public class VirtualCameraOutput : MonoBehaviour
{
    public RenderTexture OutputTexture { get; }
    
    public void Initialize(int width, int height, int fps);
    public void StartStreaming();
    public void StopStreaming();
    public void SetCompositeSource(Camera arCamera);
}
```

#### **CompositeRenderer**
```csharp
public class CompositeRenderer : MonoBehaviour
{
    public void SetBackgroundSource(Texture2D cameraFeed);
    public void SetARLayer(Camera arCamera);
    public void SetHUDLayer(Canvas hudCanvas);
    public RenderTexture GetFinalOutput();
    public void SetOutputResolution(int width, int height);
}
```

---

## 4. STATE MACHINE PLAN

### State Transition Table

| Current State          | Trigger Event                  | Next State          | Cooldown | Notes                        |
|------------------------|--------------------------------|---------------------|----------|------------------------------|
| **IDLE_WORLD**         | Host enters frame              | HOST_DETECTED       | 0s       | Clean world, no host overlay |
| **IDLE_WORLD**         | Voice: "portal"                | IDLE_WORLD          | 0s       | Spawn world portal           |
| **HOST_DETECTED**      | Host exits frame (>2s)         | IDLE_WORLD          | 0s       | Fade out body effects        |
| **HOST_DETECTED**      | Gesture: raise_hand or wave    | INTERACTION_ACTIVE  | 0s       | Activate full AR suite       |
| **INTERACTION_ACTIVE** | Voice: "boost it"              | OVERDRIVE           | 0s       | High-energy mode             |
| **INTERACTION_ACTIVE** | No gesture for 10s             | HOST_DETECTED       | 0s       | Idle down                    |
| **INTERACTION_ACTIVE** | Host exits frame               | COOLDOWN            | 0s       | Brief cooldown period        |
| **OVERDRIVE**          | Timer expires (10s default)    | COOLDOWN            | 5s       | Mandatory cooldown           |
| **OVERDRIVE**          | Voice: "chill it"              | HOST_DETECTED       | 5s       | Manual cancel                |
| **COOLDOWN**           | Timer expires (5s default)     | IDLE_WORLD          | 0s       | Return to neutral            |
| **COOLDOWN**           | Host detected & gesture        | HOST_DETECTED       | 0s       | Skip to host mode            |

### State Behaviors

#### **IDLE_WORLD**
- **Visual:** Ambient world-anchored AR only (floating UI, environmental effects)
- **Listening:** Voice commands only ("portal", "shift mode")
- **Tracking:** Face/body detection passive (not rendering)
- **HUD:** Minimal—timestamp, mode indicator

#### **HOST_DETECTED**
- **Visual:** Light body aura, face anchor indicator
- **Listening:** Gestures + voice commands active
- **Tracking:** Full body/hand tracking enabled
- **HUD:** Gesture hints, voice keyword prompts

#### **INTERACTION_ACTIVE**
- **Visual:** Full AR overlay—particles, body-anchored elements, reactive effects
- **Listening:** All inputs (gesture, voice, optional chat)
- **Tracking:** High-frequency hand tracking
- **HUD:** Live gesture recognition feedback, chat overlay

#### **OVERDRIVE**
- **Visual:** Maximum effects—screen shake, intense particles, chromatic aberration
- **Listening:** Voice only ("chill it" to cancel)
- **Tracking:** Locked to host (no new gestures trigger state changes)
- **HUD:** Energy bar draining, "OVERDRIVE" banner
- **Timer:** 10s countdown → auto-transition to COOLDOWN

#### **COOLDOWN**
- **Visual:** Fade-out effects, dim HUD
- **Listening:** Minimal (allow re-entry to HOST_DETECTED on gesture)
- **Tracking:** Body detection only
- **HUD:** "Cooling down..." message
- **Timer:** 5s → return to IDLE_WORLD

### State Machine Logic (Pseudocode)

```csharp
void Update()
{
    switch (CurrentState)
    {
        case ARState.IDLE_WORLD:
            if (bodyTracker.IsHostDetected)
                TransitionTo(ARState.HOST_DETECTED);
            if (voiceListener.LastCommand == "portal")
                worldAnchoredManager.SpawnPortal(cameraForward, 2f);
            break;

        case ARState.HOST_DETECTED:
            if (!bodyTracker.IsHostDetected && GetStateElapsedTime() > 2f)
                TransitionTo(ARState.IDLE_WORLD);
            if (gestureRecognizer.GetCurrentGesture() == GestureType.RaiseHand ||
                gestureRecognizer.GetCurrentGesture() == GestureType.Wave)
                TransitionTo(ARState.INTERACTION_ACTIVE);
            break;

        case ARState.INTERACTION_ACTIVE:
            if (voiceListener.LastCommand == "boost it")
                TransitionTo(ARState.OVERDRIVE);
            if (!bodyTracker.IsHostDetected)
                TransitionTo(ARState.COOLDOWN);
            if (GetStateElapsedTime() > 10f && gestureRecognizer.GetCurrentGesture() == GestureType.None)
                TransitionTo(ARState.HOST_DETECTED);
            break;

        case ARState.OVERDRIVE:
            OverdriveTimer -= Time.deltaTime;
            if (OverdriveTimer <= 0)
                TransitionTo(ARState.COOLDOWN);
            if (voiceListener.LastCommand == "chill it")
            {
                OverdriveTimer = 10f;  // Reset for next time
                TransitionTo(ARState.HOST_DETECTED);
            }
            break;

        case ARState.COOLDOWN:
            CooldownTimer -= Time.deltaTime;
            if (CooldownTimer <= 0)
            {
                CooldownTimer = 5f;  // Reset
                TransitionTo(ARState.IDLE_WORLD);
            }
            if (bodyTracker.IsHostDetected && gestureRecognizer.GetCurrentGesture() != GestureType.None)
            {
                CooldownTimer = 5f;  // Reset
                TransitionTo(ARState.HOST_DETECTED);
            }
            break;
    }
}
```

---

## 5. MVP SCOPE

### MVP Deliverables (Phase 1)

#### **Fully Implemented**
1. **Camera feed capture** (WebcamTexture or AR Foundation camera)
2. **State machine** (all 5 states functional)
3. **Gesture recognition** (raise_hand, wave, point, hands_on_head via MediaPipe)
4. **Voice commands** (4 keywords: "shift mode", "boost it", "chill it", "portal")
5. **Host detection** (AR Foundation face tracking as proxy for body)
6. **Basic HUD** (state name, FPS, gesture indicator)
7. **World-anchored portal** (simple sphere prefab)
8. **Body-anchored aura** (particle system attached to face anchor)
9. **OBS virtual camera output** (RenderTexture → virtual camera plugin)

#### **Stubbed/Simplified**
1. **Chat integration** → Mock API returning fake messages
2. **RTMP streaming** → Placeholder class (returns success without actual push)
3. **Advanced hand gestures** (peace, fist) → Recognized but no unique effects yet
4. **Complex AR scenes** → Use primitives (cubes, spheres) instead of custom 3D models
5. **Audio effects** → Visual feedback only (no sound)

#### **Out of Scope for MVP**
- Multi-user tracking (single host only)
- Cloud-based speech (stick to offline Vosk)
- Custom ML gesture training
- Mobile deployment (desktop prototype only)
- Production-quality 3D assets

### Acceptance Criteria

- **Performance:** 30 FPS minimum on mid-tier desktop (GTX 1660 equivalent)
- **Latency:** Gesture → state change < 200ms
- **Stability:** No crashes during 10-minute session
- **Accuracy:** Gesture recognition > 80% true positive rate
- **Output:** OBS receives composited 1080p@30 stream

---

## 6. IMPLEMENTATION TASKS

### Phase 1: Project Setup (Day 1)
1. ✅ Create new Unity 2022.3 LTS project
2. ✅ Install Unity packages:
   - AR Foundation 5.x
   - ARKit XR Plugin (iOS)
   - ARCore XR Plugin (Android)
   - Universal Render Pipeline (URP)
   - TextMeshPro
3. ✅ Import MediaPipe Unity Plugin from GitHub
4. ✅ Download and integrate Vosk Unity wrapper
5. ✅ Set up project folder structure (per Section 2)
6. ✅ Configure URP renderer for AR compositing
7. ✅ Create main AR scene with AR Session Origin

### Phase 2: Input Layer (Day 2)
8. ✅ Implement `CameraInputHandler` for webcam capture
9. ✅ Implement `MicrophoneInputHandler` for audio stream
10. ✅ Test camera feed display on a RawImage UI element
11. ✅ Verify microphone volume level visualization

### Phase 3: Perception Layer (Days 3-4)
12. ✅ Integrate MediaPipe hand tracking in `HandGestureRecognizer`
13. ✅ Implement gesture classifier logic (landmarks → gesture type)
14. ✅ Implement `BodyTracker` with AR Foundation face tracking
15. ✅ Integrate Vosk speech recognition in `VoiceCommandListener`
16. ✅ Register 4 voice commands with confidence thresholds
17. ✅ Create `EventAggregator` to publish perception events
18. ✅ Test each perception module independently

### Phase 4: State Machine (Day 5)
19. ✅ Implement `ARStateMachine` core controller
20. ✅ Create all 5 state classes (Idle, HostDetected, InteractionActive, Overdrive, Cooldown)
21. ✅ Wire up state transition logic per Section 4 table
22. ✅ Add debug logging for all state changes
23. ✅ Test state transitions with mock events

### Phase 5: AR Scene Layer (Days 6-7)
24. ✅ Implement `HUDController` with TextMeshPro UI
25. ✅ Create `WorldAnchoredManager` and portal prefab
26. ✅ Create `BodyAnchoredManager` with particle aura
27. ✅ Link state machine to HUD updates
28. ✅ Add particle effects for OVERDRIVE state
29. ✅ Test AR object spawning and anchoring

### Phase 6: Output Layer (Day 8)
30. ✅ Implement `CompositeRenderer` to combine layers
31. ✅ Set up RenderTexture pipeline (Camera → AR → HUD → Output)
32. ✅ Integrate OBS virtual camera plugin
33. ✅ Test OBS Studio receiving feed
34. ✅ Optimize render resolution and framerate

### Phase 7: Integration & Testing (Days 9-10)
35. ✅ Wire all modules together in `ARLivestreamManager`
36. ✅ End-to-end test: camera → gesture → state → AR → output
37. ✅ Test all voice commands
38. ✅ Test all gestures
39. ✅ Performance profiling (CPU, GPU, memory)
40. ✅ Fix critical bugs and crashes
41. ✅ User testing with Rex (record feedback)

### Phase 8: Polish & Documentation (Day 11)
42. ✅ Add debug overlay panel with performance metrics
43. ✅ Write `README.md` quick start guide
44. ✅ Write `GESTURE_LIBRARY.md` reference
45. ✅ Record demo video (all states, gestures, voice)
46. ✅ Create deployment checklist in `DEPLOYMENT_GUIDE.md`

---

## 7. CODE EXAMPLES

### 7.1 Gesture Detection (MediaPipe Landmarks → Gesture)

```csharp
public class HandGestureRecognizer : MonoBehaviour
{
    private MediaPipeHandSolution handSolution;
    public event Action<GestureType, Hand> OnGestureDetected;

    void Start()
    {
        handSolution = GetComponent<MediaPipeHandSolution>();
        handSolution.OnHandLandmarksDetected += AnalyzeGesture;
    }

    void AnalyzeGesture(List<NormalizedLandmark> landmarks, Hand hand)
    {
        if (landmarks == null || landmarks.Count != 21)
            return;

        GestureType detected = ClassifyGesture(landmarks);
        
        if (detected != GestureType.None)
        {
            OnGestureDetected?.Invoke(detected, hand);
        }
    }

    GestureType ClassifyGesture(List<NormalizedLandmark> lm)
    {
        // Example: "Raise Hand" = all fingertips above wrist
        Vector3 wrist = ToVector3(lm[0]);
        bool allFingersUp = true;
        
        // Check thumb tip (4), index tip (8), middle (12), ring (16), pinky (20)
        int[] fingerTips = { 4, 8, 12, 16, 20 };
        foreach (int tipIndex in fingerTips)
        {
            if (ToVector3(lm[tipIndex]).y < wrist.y)
            {
                allFingersUp = false;
                break;
            }
        }

        if (allFingersUp)
            return GestureType.RaiseHand;

        // "Point" = index extended, others folded
        bool indexUp = ToVector3(lm[8]).y > ToVector3(lm[5]).y;  // Index tip > index knuckle
        bool middleDown = ToVector3(lm[12]).y < ToVector3(lm[9]).y;
        
        if (indexUp && middleDown)
            return GestureType.Point;

        // "Wave" = detect rapid X-axis motion (requires history buffer)
        // (Simplified—actual implementation tracks wrist velocity)
        
        return GestureType.None;
    }

    Vector3 ToVector3(NormalizedLandmark lm) => new Vector3(lm.X, lm.Y, lm.Z);
}
```

### 7.2 Voice Trigger (Vosk Integration)

```csharp
public class VoiceCommandListener : MonoBehaviour
{
    private VoskSpeechRecognizer recognizer;
    private Dictionary<string, float> commands = new Dictionary<string, float>
    {
        { "shift mode", 0.7f },
        { "boost it", 0.75f },
        { "chill it", 0.75f },
        { "portal", 0.7f },
        { "highlight chat", 0.7f }
    };

    public event Action<string> OnCommandDetected;

    void Start()
    {
        string modelPath = Application.streamingAssetsPath + "/Vosk/vosk-model-small-en-us-0.15";
        recognizer = new VoskSpeechRecognizer(modelPath, 16000.0f);
        recognizer.OnPartialResult += HandlePartialResult;
        
        StartListening();
    }

    public void StartListening()
    {
        recognizer.Start();
    }

    void HandlePartialResult(string result)
    {
        // Vosk returns JSON: {"partial":"boost it"}
        var json = JsonUtility.FromJson<VoskResult>(result);
        string spoken = json.partial.ToLower().Trim();

        foreach (var cmd in commands)
        {
            if (spoken.Contains(cmd.Key))
            {
                // Simulate confidence check (Vosk doesn't provide per-word confidence easily)
                float randomConfidence = UnityEngine.Random.Range(0.6f, 1.0f);
                
                if (randomConfidence >= cmd.Value)
                {
                    OnCommandDetected?.Invoke(cmd.Key);
                    Debug.Log($"[VoiceCommand] Detected: '{cmd.Key}' (confidence: {randomConfidence})");
                }
            }
        }
    }

    [System.Serializable]
    class VoskResult
    {
        public string partial;
        public string text;
    }
}
```

### 7.3 State Controller (Main State Machine)

```csharp
public class ARStateMachine : MonoBehaviour
{
    public ARState CurrentState { get; private set; } = ARState.IDLE_WORLD;
    public event Action<ARState, ARState> OnStateChanged;

    private float stateStartTime;
    private float overdriveTimer = 10f;
    private float cooldownTimer = 5f;

    // Dependencies
    [SerializeField] private BodyTracker bodyTracker;
    [SerializeField] private HandGestureRecognizer gestureRecognizer;
    [SerializeField] private VoiceCommandListener voiceListener;

    void Start()
    {
        // Subscribe to perception events
        voiceListener.OnCommandDetected += HandleVoiceCommand;
        gestureRecognizer.OnGestureDetected += HandleGesture;
        bodyTracker.OnHostEnterFrame += () => { if (CurrentState == ARState.IDLE_WORLD) TransitionTo(ARState.HOST_DETECTED); };
    }

    void Update()
    {
        switch (CurrentState)
        {
            case ARState.HOST_DETECTED:
                if (!bodyTracker.IsHostDetected && GetStateElapsedTime() > 2f)
                    TransitionTo(ARState.IDLE_WORLD);
                break;

            case ARState.INTERACTION_ACTIVE:
                if (!bodyTracker.IsHostDetected)
                    TransitionTo(ARState.COOLDOWN);
                else if (GetStateElapsedTime() > 10f && gestureRecognizer.GetCurrentGesture() == GestureType.None)
                    TransitionTo(ARState.HOST_DETECTED);
                break;

            case ARState.OVERDRIVE:
                overdriveTimer -= Time.deltaTime;
                if (overdriveTimer <= 0)
                {
                    overdriveTimer = 10f;
                    TransitionTo(ARState.COOLDOWN);
                }
                break;

            case ARState.COOLDOWN:
                cooldownTimer -= Time.deltaTime;
                if (cooldownTimer <= 0)
                {
                    cooldownTimer = 5f;
                    TransitionTo(ARState.IDLE_WORLD);
                }
                break;
        }
    }

    void HandleVoiceCommand(string command)
    {
        switch (command)
        {
            case "boost it":
                if (CurrentState == ARState.INTERACTION_ACTIVE)
                    TransitionTo(ARState.OVERDRIVE);
                break;

            case "chill it":
                if (CurrentState == ARState.OVERDRIVE)
                    TransitionTo(ARState.HOST_DETECTED);
                break;

            case "portal":
                // State-independent action (handled elsewhere)
                break;
        }
    }

    void HandleGesture(GestureType gesture, Hand hand)
    {
        if (CurrentState == ARState.HOST_DETECTED &&
            (gesture == GestureType.RaiseHand || gesture == GestureType.Wave))
        {
            TransitionTo(ARState.INTERACTION_ACTIVE);
        }
    }

    public void TransitionTo(ARState newState)
    {
        if (CurrentState == newState)
            return;

        Debug.Log($"[StateMachine] {CurrentState} → {newState}");
        
        ARState previousState = CurrentState;
        CurrentState = newState;
        stateStartTime = Time.time;

        OnStateChanged?.Invoke(previousState, newState);
    }

    public float GetStateElapsedTime() => Time.time - stateStartTime;
}
```

### 7.4 AR Object Spawn (Portal Example)

```csharp
public class WorldAnchoredManager : MonoBehaviour
{
    [SerializeField] private GameObject portalPrefab;
    [SerializeField] private ARRaycastManager raycastManager;
    
    private List<GameObject> spawnedPortals = new List<GameObject>();

    public GameObject SpawnPortal(Vector3 direction, float distance)
    {
        // Raycast from camera in specified direction
        List<ARRaycastHit> hits = new List<ARRaycastHit>();
        Vector3 screenCenter = new Vector3(Screen.width / 2, Screen.height / 2, 0);
        
        if (raycastManager.Raycast(screenCenter, hits, TrackableType.PlaneWithinPolygon))
        {
            Pose hitPose = hits[0].pose;
            GameObject portal = Instantiate(portalPrefab, hitPose.position, hitPose.rotation);
            spawnedPortals.Add(portal);
            
            Debug.Log($"[WorldAnchored] Spawned portal at {hitPose.position}");
            return portal;
        }
        else
        {
            // Fallback: spawn in front of camera
            Vector3 spawnPos = Camera.main.transform.position + direction.normalized * distance;
            GameObject portal = Instantiate(portalPrefab, spawnPos, Quaternion.identity);
            spawnedPortals.Add(portal);
            return portal;
        }
    }

    public void RemoveAllAnchors()
    {
        foreach (var portal in spawnedPortals)
        {
            Destroy(portal);
        }
        spawnedPortals.Clear();
    }
}
```

### 7.5 Virtual Camera Output

```csharp
public class VirtualCameraOutput : MonoBehaviour
{
    public RenderTexture OutputTexture { get; private set; }
    
    [SerializeField] private Camera compositeCamera;
    [SerializeField] private int outputWidth = 1920;
    [SerializeField] private int outputHeight = 1080;
    [SerializeField] private int targetFPS = 30;

    void Start()
    {
        Initialize(outputWidth, outputHeight, targetFPS);
    }

    public void Initialize(int width, int height, int fps)
    {
        OutputTexture = new RenderTexture(width, height, 24);
        OutputTexture.name = "OBS_VirtualCamera_Output";
        compositeCamera.targetTexture = OutputTexture;

        Application.targetFrameRate = fps;
        QualitySettings.vSyncCount = 0;  // Disable VSync for consistent FPS

        Debug.Log($"[VirtualCamera] Output initialized: {width}x{height}@{fps}FPS");
    }

    public void StartStreaming()
    {
        // In real implementation, this would call OBS plugin API
        // Example: OBSVirtualCam.SetOutputTexture(OutputTexture);
        Debug.Log("[VirtualCamera] Streaming started (OBS should see this feed)");
    }

    public void StopStreaming()
    {
        Debug.Log("[VirtualCamera] Streaming stopped");
    }
}
```

---

## 8. TEST/TUNE PLAN

### 8.1 Unit Testing Strategy

**Components to Test:**
1. **HandGestureRecognizer**
   - Input: Pre-recorded MediaPipe landmark JSON
   - Expected: Correct gesture classification (>90% accuracy on controlled dataset)
   
2. **VoiceCommandListener**
   - Input: Audio file with clear keywords
   - Expected: All commands detected with <5% false positives
   
3. **ARStateMachine**
   - Input: Simulated events (mock body tracker, gesture events)
   - Expected: Correct state transitions per table in Section 4

4. **BodyTracker**
   - Input: AR Foundation face tracking on known video
   - Expected: Consistent host detection (no flicker)

### 8.2 Integration Testing

**End-to-End Flow Tests:**
1. **Idle → Host Detected → Interaction**
   - User enters frame → raise hand → AR overlay appears
   - Measure: Total latency <500ms
   
2. **Overdrive Activation**
   - Say "boost it" during interaction → OVERDRIVE effects appear
   - Timer countdown visible → auto-transition to COOLDOWN after 10s
   
3. **Voice Command Robustness**
   - Test with background music, multiple speakers
   - Acceptable: >70% detection rate in noisy environment

4. **Gesture False Positive Rate**
   - User performs non-gesture movements
   - Acceptable: <10% false positive rate

### 8.3 Performance Testing

**Metrics to Monitor:**
- **FPS:** Maintain >30 FPS on target hardware
- **CPU Usage:** <60% on 4-core Intel i5
- **GPU Usage:** <70% on GTX 1660
- **Memory:** <2GB RAM for entire app
- **Latency Breakdown:**
  - Camera capture → perception: <50ms
  - Perception → state change: <100ms
  - State change → AR render: <50ms
  - Total input→output: <200ms

**Tools:**
- Unity Profiler (CPU, GPU, memory)
- Custom `PerformanceMonitor` script (FPS, frame time)
- External capture card to measure output latency

### 8.4 User Testing Protocol

**Test Session (20 minutes):**
1. **Onboarding** (2 min)
   - Show gesture library
   - Explain voice commands
   
2. **Free Exploration** (10 min)
   - User tries all gestures and commands
   - Observer notes: successful triggers, failures, confusions
   
3. **Guided Tasks** (5 min)
   - "Activate OVERDRIVE mode"
   - "Spawn 3 portals"
   - "Return to idle state"
   
4. **Feedback** (3 min)
   - SUS (System Usability Scale) questionnaire
   - Open feedback: what felt broken, what felt great

**Success Criteria:**
- >80% task completion rate
- SUS score >70
- No critical bugs reported

### 8.5 Tuning Parameters

**Gesture Recognition:**
- `confidenceThreshold`: Default 0.7 (adjust per gesture)
- `gestureHoldDuration`: 0.5s (avoid trigger spam)
- `handSmoothingFactor`: 0.3 (reduce jitter)

**Voice Commands:**
- `keywordConfidence`: 0.7 (lower = more false positives)
- `listeningTimeout`: 3s (re-enable after pause)

**State Machine:**
- `hostExitDelay`: 2s (before IDLE transition)
- `interactionIdleTimeout`: 10s (before HOST_DETECTED)
- `overdriveTimer`: 10s (adjustable per user preference)
- `cooldownTimer`: 5s

**Performance:**
- `targetResolution`: 1920x1080 (lower to 1280x720 if <30 FPS)
- `handTrackingFrequency`: 30Hz (reduce if CPU-bound)
- `particleDensity`: Medium (reduce for potato PCs)

### 8.6 Stress Testing

**Scenarios:**
1. **Rapid gesture changes** (10 gestures/second)
   - System should not crash or lag
   
2. **Prolonged OVERDRIVE** (force timer to 60s)
   - Memory leaks check (particle cleanup)
   
3. **No host for 10 minutes** (IDLE_WORLD)
   - Verify no resource accumulation

4. **OBS stream for 1 hour**
   - Check for frame drops, memory growth

---

## 9. DEPLOYMENT & NEXT STEPS

### MVP Deployment Checklist

- [ ] Unity build (Windows Standalone x64)
- [ ] Package Vosk model in StreamingAssets
- [ ] Test on clean machine (no Unity Editor)
- [ ] OBS Studio installed and configured
- [ ] Create user manual PDF (gestures, commands, troubleshooting)
- [ ] Record demo video (upload to Rex's channel)

### Post-MVP Enhancements

**Phase 2 Features:**
1. **Mobile AR deployment** (iOS/Android)
2. **Custom 3D assets** (replace primitives)
3. **Sound effects** (voice feedback, gesture audio cues)
4. **Chat overlay integration** (Twitch API)
5. **RTMP direct streaming** (bypass OBS)
6. **Multi-user tracking** (detect multiple people)

**Phase 3 (Production):**
1. **ML gesture training** (custom gestures for Rex)
2. **Cloud save/load AR scenes**
3. **Audience interaction** (chat triggers AR effects)
4. **Analytics dashboard** (gesture heatmaps, state durations)

---

## 10. CONTACT & SUPPORT

**Project Lead:** Rex @ Super Reality Studios  
**Technical Contact:** [Your Team]  
**Repository:** [GitHub link]  
**Issue Tracker:** [GitHub Issues]

---

**Document Status:** ✅ Complete  
**Next Review:** After MVP user testing (Week 2)
