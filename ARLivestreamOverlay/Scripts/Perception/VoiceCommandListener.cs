using UnityEngine;
using System;
using System.Collections.Generic;

namespace ARLivestream.Perception
{
    /// <summary>
    /// Voice command listener using Vosk speech recognition.
    /// Detects keyword commands for AR state control.
    /// </summary>
    public class VoiceCommandListener : MonoBehaviour
    {
        #region Events
        public event Action<string> OnCommandDetected;
        #endregion

        #region Configuration
        [Header("Voice Commands")]
        [SerializeField] private string[] supportedCommands = new string[]
        {
            "shift mode",
            "boost it",
            "chill it",
            "portal",
            "highlight chat"
        };

        [Header("Settings")]
        [SerializeField] private float confidenceThreshold = 0.7f;
        [SerializeField] private bool enableDebugLogging = true;
        #endregion

        #region State
        private Dictionary<string, float> commandConfidenceMap;
        private bool isListening = false;
        private string lastDetectedCommand = null;
        private float commandCooldown = 1f;
        private float cooldownTimer = 0f;
        #endregion

        #region Properties
        public string[] SupportedCommands => supportedCommands;
        public bool IsListening => isListening;
        #endregion

        #region Initialization
        public void Initialize(string modelPath)
        {
            Debug.Log($"[VoiceCommandListener] Initializing with model: {modelPath}");

            // Initialize command confidence map
            commandConfidenceMap = new Dictionary<string, float>();
            foreach (string command in supportedCommands)
            {
                commandConfidenceMap[command.ToLower()] = confidenceThreshold;
            }

            // In real implementation, initialize Vosk recognizer here
            // recognizer = new VoskRecognizer(modelPath, 16000.0f);

            Debug.Log($"[VoiceCommandListener] Registered {supportedCommands.Length} commands");
        }

        void Start()
        {
            if (commandConfidenceMap == null || commandConfidenceMap.Count == 0)
            {
                Initialize(Application.streamingAssetsPath + "/Vosk/vosk-model-small-en-us-0.15");
            }
        }
        #endregion

        #region Update
        void Update()
        {
            if (!isListening)
                return;

            // Update cooldown
            if (cooldownTimer > 0)
            {
                cooldownTimer -= Time.deltaTime;
            }

            // In real implementation, this would process audio from microphone
            // For now, simulate with keyboard
            SimulateVoiceCommands();
        }
        #endregion

        #region Public Methods
        public void StartListening()
        {
            isListening = true;
            Debug.Log("[VoiceCommandListener] Started listening");
        }

        public void StopListening()
        {
            isListening = false;
            Debug.Log("[VoiceCommandListener] Stopped listening");
        }

        public void RegisterCommand(string keyword, float confidence = 0.7f)
        {
            if (!commandConfidenceMap.ContainsKey(keyword.ToLower()))
            {
                commandConfidenceMap[keyword.ToLower()] = confidence;
                Debug.Log($"[VoiceCommandListener] Registered command: '{keyword}' (confidence: {confidence})");
            }
        }

        public void UnregisterCommand(string keyword)
        {
            if (commandConfidenceMap.ContainsKey(keyword.ToLower()))
            {
                commandConfidenceMap.Remove(keyword.ToLower());
                Debug.Log($"[VoiceCommandListener] Unregistered command: '{keyword}'");
            }
        }
        #endregion

        #region Command Processing
        private void ProcessSpeechResult(string spokenText, float confidence)
        {
            if (string.IsNullOrEmpty(spokenText))
                return;

            string normalized = spokenText.ToLower().Trim();

            if (enableDebugLogging)
                Debug.Log($"[VoiceCommandListener] Heard: '{normalized}' (confidence: {confidence})");

            // Check against registered commands
            foreach (var cmd in commandConfidenceMap)
            {
                if (normalized.Contains(cmd.Key) && confidence >= cmd.Value)
                {
                    TriggerCommand(cmd.Key);
                    return;
                }
            }
        }

        private void TriggerCommand(string command)
        {
            // Check cooldown to prevent rapid re-triggering
            if (cooldownTimer > 0)
            {
                if (enableDebugLogging)
                    Debug.Log($"[VoiceCommandListener] Command '{command}' on cooldown");
                return;
            }

            lastDetectedCommand = command;
            cooldownTimer = commandCooldown;

            OnCommandDetected?.Invoke(command);

            if (enableDebugLogging)
                Debug.Log($"[VoiceCommandListener] Command triggered: '{command}'");
        }
        #endregion

        #region Simulation (Dev/Testing)
        /// <summary>
        /// Simulates voice commands for development/testing without Vosk.
        /// Uses keyboard keys to trigger commands.
        /// </summary>
        private void SimulateVoiceCommands()
        {
            if (Input.GetKeyDown(KeyCode.B))
            {
                ProcessSpeechResult("boost it", 0.9f);
            }
            else if (Input.GetKeyDown(KeyCode.C))
            {
                ProcessSpeechResult("chill it", 0.9f);
            }
            else if (Input.GetKeyDown(KeyCode.P))
            {
                ProcessSpeechResult("portal", 0.9f);
            }
            else if (Input.GetKeyDown(KeyCode.M))
            {
                ProcessSpeechResult("shift mode", 0.9f);
            }
            else if (Input.GetKeyDown(KeyCode.H))
            {
                ProcessSpeechResult("highlight chat", 0.9f);
            }
        }
        #endregion

        #region Vosk Integration Stub
        /// <summary>
        /// Placeholder for actual Vosk integration.
        /// In real implementation, this would be called by Vosk's callback.
        /// </summary>
        private void HandleVoskPartialResult(string jsonResult)
        {
            // Parse Vosk JSON result
            // Example: {"partial":"boost it"}
            try
            {
                var result = JsonUtility.FromJson<VoskResult>(jsonResult);
                ProcessSpeechResult(result.partial, 0.8f);
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[VoiceCommandListener] Failed to parse Vosk result: {ex.Message}");
            }
        }

        [System.Serializable]
        private class VoskResult
        {
            public string partial;
            public string text;
        }
        #endregion
    }
}
