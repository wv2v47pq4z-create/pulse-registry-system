using UnityEngine;

namespace ARLivestream.Core
{
    /// <summary>
    /// Main orchestrator for the AR Livestream Overlay system.
    /// Coordinates all subsystems: input, perception, state machine, AR scene, and output.
    /// </summary>
    public class ARLivestreamManager : MonoBehaviour
    {
        #region Singleton
        public static ARLivestreamManager Instance { get; private set; }
        #endregion

        #region Subsystem References
        [Header("Input Layer")]
        [SerializeField] private Input.CameraInputHandler cameraInput;
        [SerializeField] private Input.MicrophoneInputHandler microphoneInput;

        [Header("Perception Layer")]
        [SerializeField] private Perception.BodyTracker bodyTracker;
        [SerializeField] private Perception.HandGestureRecognizer gestureRecognizer;
        [SerializeField] private Perception.VoiceCommandListener voiceListener;

        [Header("State Machine")]
        [SerializeField] private StateMachine.ARStateMachine stateMachine;

        [Header("AR Scene Layer")]
        [SerializeField] private ARScene.HUDController hudController;
        [SerializeField] private ARScene.WorldAnchoredManager worldAnchoredManager;
        [SerializeField] private ARScene.BodyAnchoredManager bodyAnchoredManager;

        [Header("Output Layer")]
        [SerializeField] private Output.VirtualCameraOutput virtualCameraOutput;
        [SerializeField] private Output.CompositeRenderer compositeRenderer;
        #endregion

        #region Configuration
        [Header("Settings")]
        [SerializeField] private bool autoStartOnAwake = true;
        [SerializeField] private int targetFrameRate = 30;
        [SerializeField] private Vector2Int outputResolution = new Vector2Int(1920, 1080);
        #endregion

        #region Lifecycle
        void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        void Start()
        {
            InitializeSubsystems();
            
            if (autoStartOnAwake)
            {
                StartARSystem();
            }
        }

        void OnDestroy()
        {
            if (Instance == this)
            {
                Instance = null;
            }
        }
        #endregion

        #region Initialization
        private void InitializeSubsystems()
        {
            Debug.Log("[ARLivestreamManager] Initializing subsystems...");

            // Set application frame rate
            Application.targetFrameRate = targetFrameRate;
            QualitySettings.vSyncCount = 0;

            // Initialize input layer
            if (cameraInput != null)
                cameraInput.Initialize(new Input.CameraConfig 
                { 
                    resolution = outputResolution 
                });

            if (microphoneInput != null)
                microphoneInput.Initialize(Microphone.devices.Length > 0 ? Microphone.devices[0] : null);

            // Initialize perception layer
            if (bodyTracker != null)
                bodyTracker.Initialize();

            if (gestureRecognizer != null)
                gestureRecognizer.Initialize(new Perception.MediaPipeConfig());

            if (voiceListener != null)
                voiceListener.Initialize(Application.streamingAssetsPath + "/Vosk/vosk-model-small-en-us-0.15");

            // Initialize state machine
            if (stateMachine != null)
                stateMachine.Initialize();

            // Initialize output layer
            if (virtualCameraOutput != null)
                virtualCameraOutput.Initialize(outputResolution.x, outputResolution.y, targetFrameRate);

            if (compositeRenderer != null)
                compositeRenderer.Initialize(outputResolution.x, outputResolution.y);

            Debug.Log("[ARLivestreamManager] All subsystems initialized");
        }
        #endregion

        #region Public Methods
        public void StartARSystem()
        {
            Debug.Log("[ARLivestreamManager] Starting AR system...");

            cameraInput?.StartCapture();
            microphoneInput?.StartListening();
            voiceListener?.StartListening();
            virtualCameraOutput?.StartStreaming();

            Debug.Log("[ARLivestreamManager] AR system started");
        }

        public void StopARSystem()
        {
            Debug.Log("[ARLivestreamManager] Stopping AR system...");

            cameraInput?.StopCapture();
            microphoneInput?.StopListening();
            voiceListener?.StopListening();
            virtualCameraOutput?.StopStreaming();

            Debug.Log("[ARLivestreamManager] AR system stopped");
        }

        public void RestartARSystem()
        {
            StopARSystem();
            StartARSystem();
        }
        #endregion

        #region Utility Methods
        public T GetSubsystem<T>() where T : MonoBehaviour
        {
            return GetComponentInChildren<T>();
        }
        #endregion
    }
}
