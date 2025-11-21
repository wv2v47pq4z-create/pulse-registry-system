# AR LIVESTREAM OVERLAY - USAGE EXAMPLES

Complete code examples showing how to use and extend the AR Livestream Overlay system.

---

## Example 1: Basic Setup

### Creating the Main Scene

```csharp
// In Unity: GameObject → Create Empty → Name: "ARSystem"
// Add ARLivestreamManager component
// Configure in Inspector:

using ARLivestream.Core;
using UnityEngine;

public class QuickStartSetup : MonoBehaviour
{
    void Start()
    {
        // Get reference to manager
        var manager = ARLivestreamManager.Instance;
        
        // Start the AR system
        manager.StartARSystem();
        
        Debug.Log("AR Livestream Overlay started!");
    }
}
```

---

## Example 2: Custom Gesture Handler

### Responding to Specific Gestures

```csharp
using UnityEngine;
using ARLivestream.Perception;

public class CustomGestureHandler : MonoBehaviour
{
    private HandGestureRecognizer gestureRecognizer;

    void Start()
    {
        // Find the gesture recognizer
        gestureRecognizer = FindObjectOfType<HandGestureRecognizer>();
        
        // Subscribe to gesture events
        gestureRecognizer.OnGestureDetected += HandleGesture;
    }

    void HandleGesture(GestureType gesture, Hand hand)
    {
        switch (gesture)
        {
            case GestureType.Point:
                Debug.Log($"{hand} hand is pointing!");
                SpawnPointerEffect(hand);
                break;

            case GestureType.Peace:
                Debug.Log($"{hand} hand showing peace sign!");
                TriggerCelebration();
                break;

            case GestureType.Fist:
                Debug.Log($"{hand} hand showing fist!");
                BoostIntensity();
                break;
        }
    }

    void SpawnPointerEffect(Hand hand)
    {
        Vector3 handPos = gestureRecognizer.GetHandPosition(hand);
        // Spawn a laser pointer or highlight effect
        GameObject pointer = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        pointer.transform.position = handPos;
        pointer.transform.localScale = Vector3.one * 0.1f;
        Destroy(pointer, 2f);
    }

    void TriggerCelebration()
    {
        // Spawn confetti or celebration particles
        var particleObj = new GameObject("Celebration");
        var ps = particleObj.AddComponent<ParticleSystem>();
        ps.Emit(50);
        Destroy(particleObj, 3f);
    }

    void BoostIntensity()
    {
        // Increase visual effect intensity
        var bodyManager = FindObjectOfType<ARLivestream.ARScene.BodyAnchoredManager>();
        if (bodyManager != null)
        {
            bodyManager.SetAuraIntensity(2.0f);
        }
    }

    void OnDestroy()
    {
        if (gestureRecognizer != null)
        {
            gestureRecognizer.OnGestureDetected -= HandleGesture;
        }
    }
}
```

---

## Example 3: Custom Voice Command

### Adding New Voice Commands

```csharp
using UnityEngine;
using ARLivestream.Perception;

public class CustomVoiceCommands : MonoBehaviour
{
    private VoiceCommandListener voiceListener;

    void Start()
    {
        voiceListener = FindObjectOfType<VoiceCommandListener>();
        
        // Register custom commands
        voiceListener.RegisterCommand("summon dragon", 0.75f);
        voiceListener.RegisterCommand("activate shield", 0.75f);
        voiceListener.RegisterCommand("teleport", 0.8f);
        
        // Subscribe to command events
        voiceListener.OnCommandDetected += HandleCommand;
    }

    void HandleCommand(string command)
    {
        switch (command.ToLower())
        {
            case "summon dragon":
                SummonDragon();
                break;

            case "activate shield":
                ActivateShield();
                break;

            case "teleport":
                TeleportEffect();
                break;
        }
    }

    void SummonDragon()
    {
        Debug.Log("Summoning dragon!");
        // Spawn 3D dragon model or effect
        var worldManager = FindObjectOfType<ARLivestream.ARScene.WorldAnchoredManager>();
        if (worldManager != null)
        {
            Vector3 spawnDir = Camera.main.transform.forward + Vector3.up;
            GameObject dragon = worldManager.SpawnPortal(spawnDir, 3f);
            dragon.name = "Dragon";
            // Add dragon animation/behavior here
        }
    }

    void ActivateShield()
    {
        Debug.Log("Shield activated!");
        // Create shield effect around host
        var bodyManager = FindObjectOfType<ARLivestream.ARScene.BodyAnchoredManager>();
        if (bodyManager != null)
        {
            bodyManager.PlayEmoteEffect("shield");
            // Create sphere mesh around host
            GameObject shield = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            shield.transform.localScale = Vector3.one * 2f;
            var tracker = FindObjectOfType<BodyTracker>();
            if (tracker != null && tracker.IsHostDetected)
            {
                shield.transform.position = tracker.HostCenterPosition;
            }
            Destroy(shield, 3f);
        }
    }

    void TeleportEffect()
    {
        Debug.Log("Teleporting!");
        // Create teleport visual effect
        // Flash screen, spawn particles, etc.
    }

    void OnDestroy()
    {
        if (voiceListener != null)
        {
            voiceListener.OnCommandDetected -= HandleCommand;
        }
    }
}
```

---

## Example 4: State Change Reactions

### Responding to State Transitions

```csharp
using UnityEngine;
using ARLivestream.StateMachine;

public class StateChangeReactor : MonoBehaviour
{
    [SerializeField] private AudioClip idleMusic;
    [SerializeField] private AudioClip actionMusic;
    [SerializeField] private AudioClip overdriveMusic;

    private ARStateMachine stateMachine;
    private AudioSource audioSource;

    void Start()
    {
        stateMachine = FindObjectOfType<ARStateMachine>();
        audioSource = GetComponent<AudioSource>();
        
        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
        }

        // Subscribe to state changes
        stateMachine.OnStateChanged += HandleStateChange;
    }

    void HandleStateChange(ARStateMachine.ARState previousState, ARStateMachine.ARState newState)
    {
        Debug.Log($"State changed: {previousState} → {newState}");

        // Change music based on state
        switch (newState)
        {
            case ARStateMachine.ARState.IDLE_WORLD:
                PlayMusic(idleMusic, 0.3f);
                SetCameraEffects(false);
                break;

            case ARStateMachine.ARState.HOST_DETECTED:
                PlayMusic(idleMusic, 0.5f);
                SetCameraEffects(false);
                ShowWelcomeMessage();
                break;

            case ARStateMachine.ARState.INTERACTION_ACTIVE:
                PlayMusic(actionMusic, 0.7f);
                SetCameraEffects(true);
                break;

            case ARStateMachine.ARState.OVERDRIVE:
                PlayMusic(overdriveMusic, 1.0f);
                SetCameraEffects(true);
                StartScreenShake();
                break;

            case ARStateMachine.ARState.COOLDOWN:
                PlayMusic(idleMusic, 0.4f);
                StopScreenShake();
                ShowCooldownTimer();
                break;
        }
    }

    void PlayMusic(AudioClip clip, float volume)
    {
        if (clip != null && audioSource != null)
        {
            audioSource.clip = clip;
            audioSource.volume = volume;
            audioSource.loop = true;
            audioSource.Play();
        }
    }

    void SetCameraEffects(bool enabled)
    {
        // Enable/disable post-processing effects
        var camera = Camera.main;
        if (camera != null)
        {
            // Add bloom, chromatic aberration, etc.
            Debug.Log($"Camera effects: {enabled}");
        }
    }

    void ShowWelcomeMessage()
    {
        var hudController = FindObjectOfType<ARLivestream.ARScene.HUDController>();
        if (hudController != null)
        {
            hudController.ShowNotification("Welcome! Wave or raise your hand to start.", 3f);
        }
    }

    void StartScreenShake()
    {
        // Implement camera shake effect
        StartCoroutine(ScreenShakeCoroutine());
    }

    void StopScreenShake()
    {
        StopAllCoroutines();
    }

    System.Collections.IEnumerator ScreenShakeCoroutine()
    {
        var camera = Camera.main;
        if (camera == null) yield break;

        Vector3 originalPos = camera.transform.localPosition;

        while (true)
        {
            float x = Random.Range(-0.05f, 0.05f);
            float y = Random.Range(-0.05f, 0.05f);
            camera.transform.localPosition = originalPos + new Vector3(x, y, 0);
            yield return new WaitForSeconds(0.05f);
        }
    }

    void ShowCooldownTimer()
    {
        var hudController = FindObjectOfType<ARLivestream.ARScene.HUDController>();
        if (hudController != null)
        {
            hudController.ShowNotification("Cooling down... 5 seconds", 5f);
        }
    }

    void OnDestroy()
    {
        if (stateMachine != null)
        {
            stateMachine.OnStateChanged -= HandleStateChange;
        }
    }
}
```

---

## Example 5: Custom AR Object Spawner

### Creating Dynamic AR Content

```csharp
using UnityEngine;
using ARLivestream.ARScene;

public class DynamicARSpawner : MonoBehaviour
{
    [SerializeField] private GameObject[] arPrefabs;
    [SerializeField] private float spawnRadius = 3f;
    [SerializeField] private int maxObjects = 20;

    private WorldAnchoredManager worldManager;
    private BodyAnchoredManager bodyManager;

    void Start()
    {
        worldManager = FindObjectOfType<WorldAnchoredManager>();
        bodyManager = FindObjectOfType<BodyAnchoredManager>();
    }

    void Update()
    {
        // Spawn object on keypress (example)
        if (Input.GetKeyDown(KeyCode.O))
        {
            SpawnRandomObject();
        }

        if (Input.GetKeyDown(KeyCode.L))
        {
            SpawnObjectRing();
        }
    }

    void SpawnRandomObject()
    {
        if (arPrefabs.Length == 0 || Camera.main == null)
            return;

        // Random position around camera
        Vector3 randomDir = Random.insideUnitSphere.normalized;
        randomDir.y = Mathf.Abs(randomDir.y); // Keep above ground

        Vector3 spawnPos = Camera.main.transform.position + randomDir * spawnRadius;
        Quaternion spawnRot = Quaternion.LookRotation(-randomDir);

        GameObject prefab = arPrefabs[Random.Range(0, arPrefabs.Length)];
        GameObject obj = Instantiate(prefab, spawnPos, spawnRot);

        // Auto-destroy after 10 seconds
        Destroy(obj, 10f);

        Debug.Log($"Spawned {prefab.name} at {spawnPos}");
    }

    void SpawnObjectRing()
    {
        if (arPrefabs.Length == 0 || Camera.main == null)
            return;

        int objectCount = 8;
        float angleStep = 360f / objectCount;

        for (int i = 0; i < objectCount; i++)
        {
            float angle = i * angleStep * Mathf.Deg2Rad;
            Vector3 direction = new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle));
            Vector3 spawnPos = Camera.main.transform.position + direction * spawnRadius;
            Quaternion spawnRot = Quaternion.LookRotation(-direction);

            GameObject prefab = arPrefabs[Random.Range(0, arPrefabs.Length)];
            GameObject obj = Instantiate(prefab, spawnPos, spawnRot);
            Destroy(obj, 10f);
        }

        Debug.Log($"Spawned ring of {objectCount} objects");
    }

    public void SpawnObjectAtPosition(Vector3 worldPosition)
    {
        if (arPrefabs.Length == 0)
            return;

        GameObject prefab = arPrefabs[Random.Range(0, arPrefabs.Length)];
        GameObject obj = Instantiate(prefab, worldPosition, Quaternion.identity);
        Destroy(obj, 10f);
    }

    public void AttachObjectToHost()
    {
        var tracker = FindObjectOfType<ARLivestream.Perception.BodyTracker>();
        if (tracker == null || !tracker.IsHostDetected)
        {
            Debug.LogWarning("Cannot attach object: Host not detected");
            return;
        }

        if (arPrefabs.Length == 0)
            return;

        GameObject prefab = arPrefabs[Random.Range(0, arPrefabs.Length)];
        GameObject obj = Instantiate(prefab, tracker.HostCenterPosition, Quaternion.identity);
        obj.transform.SetParent(tracker.HostCenterTransform);

        Debug.Log($"Attached {prefab.name} to host");
    }
}
```

---

## Example 6: Performance Monitor

### Tracking System Performance

```csharp
using UnityEngine;
using TMPro;

public class PerformanceMonitor : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI fpsText;
    [SerializeField] private TextMeshProUGUI memoryText;
    [SerializeField] private TextMeshProUGUI stateText;

    private float deltaTime = 0f;
    private float updateInterval = 0.5f;
    private float timer = 0f;

    void Update()
    {
        // Calculate FPS
        deltaTime += (Time.unscaledDeltaTime - deltaTime) * 0.1f;
        timer += Time.deltaTime;

        if (timer >= updateInterval)
        {
            UpdateUI();
            timer = 0f;
        }
    }

    void UpdateUI()
    {
        // FPS
        float fps = 1.0f / deltaTime;
        if (fpsText != null)
        {
            fpsText.text = $"FPS: {Mathf.Ceil(fps)}";
            fpsText.color = GetFPSColor(fps);
        }

        // Memory
        long memory = System.GC.GetTotalMemory(false);
        float memoryMB = memory / (1024f * 1024f);
        if (memoryText != null)
        {
            memoryText.text = $"Memory: {memoryMB:F1} MB";
        }

        // Current state
        var stateMachine = FindObjectOfType<ARLivestream.StateMachine.ARStateMachine>();
        if (stateMachine != null && stateText != null)
        {
            stateText.text = $"State: {stateMachine.CurrentState}\nElapsed: {stateMachine.StateElapsedTime:F1}s";
        }
    }

    Color GetFPSColor(float fps)
    {
        if (fps >= 55) return Color.green;
        if (fps >= 30) return Color.yellow;
        return Color.red;
    }

    void OnGUI()
    {
        // Alternative: Draw directly without UI
        if (fpsText == null)
        {
            int w = Screen.width, h = Screen.height;
            GUIStyle style = new GUIStyle();
            Rect rect = new Rect(10, 10, w, h * 2 / 100);
            style.alignment = TextAnchor.UpperLeft;
            style.fontSize = h * 2 / 50;
            style.normal.textColor = GetFPSColor(1.0f / deltaTime);

            float fps = 1.0f / deltaTime;
            string text = $"FPS: {Mathf.Ceil(fps)}";
            GUI.Label(rect, text, style);
        }
    }
}
```

---

## Example 7: Chat Integration (Twitch)

### Connecting to Twitch Chat

```csharp
using UnityEngine;
using System.Collections.Generic;

// Requires TwitchLib or similar
public class TwitchChatIntegration : MonoBehaviour
{
    [SerializeField] private string channelName = "your_channel";
    [SerializeField] private bool enableChatTriggers = true;

    private Queue<string> chatMessages = new Queue<string>();
    private int maxMessages = 10;

    void Start()
    {
        ConnectToChat();
    }

    void ConnectToChat()
    {
        // Pseudo-code for Twitch connection
        // var client = new TwitchClient();
        // client.OnMessageReceived += HandleChatMessage;
        // client.Connect();

        Debug.Log($"Connected to Twitch chat: {channelName}");
    }

    void HandleChatMessage(string username, string message)
    {
        Debug.Log($"[{username}]: {message}");

        // Add to message queue
        chatMessages.Enqueue($"{username}: {message}");
        if (chatMessages.Count > maxMessages)
        {
            chatMessages.Dequeue();
        }

        // Check for AR triggers
        if (enableChatTriggers)
        {
            CheckChatTriggers(message.ToLower());
        }

        // Update HUD
        UpdateChatDisplay();
    }

    void CheckChatTriggers(string message)
    {
        if (message.Contains("!portal"))
        {
            SpawnPortalFromChat();
        }
        else if (message.Contains("!boost"))
        {
            TriggerBoostFromChat();
        }
        else if (message.Contains("!celebrate"))
        {
            TriggerCelebration();
        }
    }

    void SpawnPortalFromChat()
    {
        var worldManager = FindObjectOfType<ARLivestream.ARScene.WorldAnchoredManager>();
        if (worldManager != null)
        {
            Vector3 dir = Camera.main.transform.forward;
            worldManager.SpawnPortal(dir, 2f);
            Debug.Log("Portal spawned from chat command!");
        }
    }

    void TriggerBoostFromChat()
    {
        var stateMachine = FindObjectOfType<ARLivestream.StateMachine.ARStateMachine>();
        if (stateMachine != null && 
            stateMachine.CurrentState == ARLivestream.StateMachine.ARStateMachine.ARState.INTERACTION_ACTIVE)
        {
            stateMachine.TransitionTo(ARLivestream.StateMachine.ARStateMachine.ARState.OVERDRIVE);
            Debug.Log("OVERDRIVE triggered from chat!");
        }
    }

    void TriggerCelebration()
    {
        // Spawn confetti or celebration effect
        Debug.Log("Celebration triggered from chat!");
    }

    void UpdateChatDisplay()
    {
        var hudController = FindObjectOfType<ARLivestream.ARScene.HUDController>();
        if (hudController != null)
        {
            // Build chat text from queue
            string chatText = string.Join("\n", chatMessages);
            // Update chat panel (requires custom method)
            Debug.Log($"Chat updated: {chatMessages.Count} messages");
        }
    }
}
```

---

## Example 8: Configuration Manager

### Saving/Loading Settings

```csharp
using UnityEngine;

[System.Serializable]
public class ARConfig
{
    public int targetFrameRate = 30;
    public Vector2Int outputResolution = new Vector2Int(1920, 1080);
    public float gestureConfidence = 0.7f;
    public float voiceConfidence = 0.75f;
    public bool enableDebugUI = true;
}

public class ConfigurationManager : MonoBehaviour
{
    private static readonly string ConfigKey = "ARLivestreamConfig";
    public ARConfig CurrentConfig { get; private set; }

    void Awake()
    {
        LoadConfig();
    }

    public void LoadConfig()
    {
        string json = PlayerPrefs.GetString(ConfigKey, "");
        if (string.IsNullOrEmpty(json))
        {
            CurrentConfig = new ARConfig(); // Default
            SaveConfig();
        }
        else
        {
            CurrentConfig = JsonUtility.FromJson<ARConfig>(json);
        }

        ApplyConfig();
        Debug.Log("Configuration loaded");
    }

    public void SaveConfig()
    {
        string json = JsonUtility.ToJson(CurrentConfig, true);
        PlayerPrefs.SetString(ConfigKey, json);
        PlayerPrefs.Save();
        Debug.Log("Configuration saved");
    }

    void ApplyConfig()
    {
        Application.targetFrameRate = CurrentConfig.targetFrameRate;

        var gestureRecognizer = FindObjectOfType<ARLivestream.Perception.HandGestureRecognizer>();
        if (gestureRecognizer != null)
        {
            // Apply gesture confidence (requires public setter)
            Debug.Log($"Gesture confidence: {CurrentConfig.gestureConfidence}");
        }

        var voiceListener = FindObjectOfType<ARLivestream.Perception.VoiceCommandListener>();
        if (voiceListener != null)
        {
            // Apply voice confidence
            Debug.Log($"Voice confidence: {CurrentConfig.voiceConfidence}");
        }
    }

    public void SetFrameRate(int fps)
    {
        CurrentConfig.targetFrameRate = fps;
        Application.targetFrameRate = fps;
        SaveConfig();
    }

    public void SetResolution(int width, int height)
    {
        CurrentConfig.outputResolution = new Vector2Int(width, height);
        SaveConfig();
    }
}
```

---

## Testing Examples

### Keyboard Test Controls

```
// Gestures (number keys)
1 = Raise Hand
2 = Wave
3 = Point
4 = Peace
5 = Fist

// Voice Commands (letter keys)
B = "boost it"
C = "chill it"
P = "portal"
M = "shift mode"
H = "highlight chat"

// System Controls
Space = Toggle host detection
O = Spawn random AR object
L = Spawn object ring
Escape = Quit application
```

---

**Last Updated:** 2025-11-21  
**Version:** 1.0
