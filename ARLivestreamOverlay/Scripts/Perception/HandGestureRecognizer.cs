using UnityEngine;
using System;
using System.Collections.Generic;

namespace ARLivestream.Perception
{
    /// <summary>
    /// Gesture types recognized by the system.
    /// </summary>
    public enum GestureType
    {
        None,
        RaiseHand,
        Wave,
        Point,
        HandsOnHead,
        Peace,
        Fist,
        ThumbsUp
    }

    /// <summary>
    /// Hand identifier.
    /// </summary>
    public enum Hand
    {
        Left,
        Right
    }

    /// <summary>
    /// Configuration for MediaPipe hand tracking.
    /// </summary>
    [System.Serializable]
    public struct MediaPipeConfig
    {
        public float confidenceThreshold;
        public float gestureHoldDuration;
        public float handSmoothingFactor;

        public static MediaPipeConfig Default => new MediaPipeConfig
        {
            confidenceThreshold = 0.7f,
            gestureHoldDuration = 0.5f,
            handSmoothingFactor = 0.3f
        };
    }

    /// <summary>
    /// Recognizes hand gestures using MediaPipe hand tracking.
    /// Converts 21-point hand landmarks into semantic gesture types.
    /// </summary>
    public class HandGestureRecognizer : MonoBehaviour
    {
        #region Events
        public event Action<GestureType, Hand> OnGestureDetected;
        #endregion

        #region Configuration
        [Header("Configuration")]
        [SerializeField] private MediaPipeConfig config = MediaPipeConfig.Default;
        [SerializeField] private bool enableDebugVisualization = true;
        #endregion

        #region State
        private GestureType currentLeftGesture = GestureType.None;
        private GestureType currentRightGesture = GestureType.None;
        private float leftGestureHoldTimer = 0f;
        private float rightGestureHoldTimer = 0f;

        // Simulated landmark data (in real implementation, this would come from MediaPipe)
        private Vector3[] leftHandLandmarks = new Vector3[21];
        private Vector3[] rightHandLandmarks = new Vector3[21];
        private bool leftHandDetected = false;
        private bool rightHandDetected = false;
        #endregion

        #region Initialization
        public void Initialize(MediaPipeConfig configuration)
        {
            config = configuration;
            Debug.Log("[HandGestureRecognizer] Initialized with MediaPipe");
        }

        void Start()
        {
            if (config.Equals(default(MediaPipeConfig)))
            {
                config = MediaPipeConfig.Default;
            }
        }
        #endregion

        #region Update
        void Update()
        {
            // In real implementation, this would receive data from MediaPipe
            // For now, simulate hand tracking with mouse/keyboard
            SimulateHandTracking();

            if (leftHandDetected)
            {
                GestureType detected = ClassifyGesture(leftHandLandmarks);
                ProcessGesture(detected, Hand.Left, ref currentLeftGesture, ref leftGestureHoldTimer);
            }

            if (rightHandDetected)
            {
                GestureType detected = ClassifyGesture(rightHandLandmarks);
                ProcessGesture(detected, Hand.Right, ref currentRightGesture, ref rightGestureHoldTimer);
            }
        }
        #endregion

        #region Gesture Classification
        /// <summary>
        /// Classify hand landmarks into gesture type.
        /// </summary>
        private GestureType ClassifyGesture(Vector3[] landmarks)
        {
            if (landmarks == null || landmarks.Length != 21)
                return GestureType.None;

            // MediaPipe landmark indices:
            // 0: Wrist, 4: Thumb tip, 8: Index tip, 12: Middle tip, 16: Ring tip, 20: Pinky tip

            Vector3 wrist = landmarks[0];

            // Check "Raise Hand" - all fingertips above wrist
            if (IsRaiseHand(landmarks, wrist))
                return GestureType.RaiseHand;

            // Check "Point" - index extended, others folded
            if (IsPoint(landmarks))
                return GestureType.Point;

            // Check "Peace" - index and middle extended, others folded
            if (IsPeace(landmarks))
                return GestureType.Peace;

            // Check "Fist" - all fingers folded
            if (IsFist(landmarks, wrist))
                return GestureType.Fist;

            // Check "Thumbs Up"
            if (IsThumbsUp(landmarks, wrist))
                return GestureType.ThumbsUp;

            return GestureType.None;
        }

        private bool IsRaiseHand(Vector3[] lm, Vector3 wrist)
        {
            // All fingertips should be above wrist
            int[] fingerTips = { 4, 8, 12, 16, 20 };
            foreach (int tipIndex in fingerTips)
            {
                if (lm[tipIndex].y < wrist.y)
                    return false;
            }
            return true;
        }

        private bool IsPoint(Vector3[] lm)
        {
            // Index tip should be above index knuckle (extended)
            bool indexUp = lm[8].y > lm[5].y;

            // Middle tip should be below middle knuckle (folded)
            bool middleDown = lm[12].y < lm[9].y;

            // Ring and pinky should be folded
            bool ringDown = lm[16].y < lm[13].y;
            bool pinkyDown = lm[20].y < lm[17].y;

            return indexUp && middleDown && ringDown && pinkyDown;
        }

        private bool IsPeace(Vector3[] lm)
        {
            // Index and middle extended
            bool indexUp = lm[8].y > lm[5].y;
            bool middleUp = lm[12].y > lm[9].y;

            // Ring and pinky folded
            bool ringDown = lm[16].y < lm[13].y;
            bool pinkyDown = lm[20].y < lm[17].y;

            return indexUp && middleUp && ringDown && pinkyDown;
        }

        private bool IsFist(Vector3[] lm, Vector3 wrist)
        {
            // All fingertips should be below their respective knuckles
            int[] fingerTips = { 8, 12, 16, 20 }; // Exclude thumb
            int[] knuckles = { 5, 9, 13, 17 };

            for (int i = 0; i < fingerTips.Length; i++)
            {
                if (lm[fingerTips[i]].y > lm[knuckles[i]].y)
                    return false;
            }
            return true;
        }

        private bool IsThumbsUp(Vector3[] lm, Vector3 wrist)
        {
            // Thumb tip should be above wrist
            bool thumbUp = lm[4].y > wrist.y + 0.1f;

            // Other fingers should be folded
            bool indexDown = lm[8].y < lm[5].y;
            bool middleDown = lm[12].y < lm[9].y;

            return thumbUp && indexDown && middleDown;
        }
        #endregion

        #region Gesture Processing
        private void ProcessGesture(GestureType detected, Hand hand, ref GestureType currentGesture, ref float holdTimer)
        {
            if (detected == currentGesture && detected != GestureType.None)
            {
                holdTimer += Time.deltaTime;

                if (holdTimer >= config.gestureHoldDuration)
                {
                    // Gesture held long enough, trigger event
                    OnGestureDetected?.Invoke(detected, hand);
                    holdTimer = 0f; // Reset to avoid repeated triggers
                }
            }
            else
            {
                currentGesture = detected;
                holdTimer = 0f;
            }
        }
        #endregion

        #region Public Methods
        public GestureType GetCurrentGesture(Hand hand = Hand.Right)
        {
            return hand == Hand.Left ? currentLeftGesture : currentRightGesture;
        }

        public Vector3 GetHandPosition(Hand hand)
        {
            if (hand == Hand.Left && leftHandDetected)
                return leftHandLandmarks[0]; // Wrist position
            if (hand == Hand.Right && rightHandDetected)
                return rightHandLandmarks[0];

            return Vector3.zero;
        }

        public bool IsGestureHeld(GestureType gesture, float duration)
        {
            if (currentLeftGesture == gesture && leftGestureHoldTimer >= duration)
                return true;
            if (currentRightGesture == gesture && rightGestureHoldTimer >= duration)
                return true;

            return false;
        }
        #endregion

        #region Simulation (Dev/Testing)
        /// <summary>
        /// Simulates hand tracking for development/testing without MediaPipe.
        /// Uses keyboard keys to trigger different gestures.
        /// </summary>
        private void SimulateHandTracking()
        {
            // Keyboard shortcuts for testing
            if (Input.GetKeyDown(KeyCode.Alpha1))
            {
                SimulateGesture(GestureType.RaiseHand, Hand.Right);
            }
            else if (Input.GetKeyDown(KeyCode.Alpha2))
            {
                SimulateGesture(GestureType.Wave, Hand.Right);
            }
            else if (Input.GetKeyDown(KeyCode.Alpha3))
            {
                SimulateGesture(GestureType.Point, Hand.Right);
            }
            else if (Input.GetKeyDown(KeyCode.Alpha4))
            {
                SimulateGesture(GestureType.Peace, Hand.Right);
            }
            else if (Input.GetKeyDown(KeyCode.Alpha5))
            {
                SimulateGesture(GestureType.Fist, Hand.Right);
            }

            // Keep hand detected for simulation
            rightHandDetected = true;
        }

        private void SimulateGesture(GestureType gesture, Hand hand)
        {
            Debug.Log($"[HandGestureRecognizer] Simulated gesture: {gesture}");

            // Create fake landmarks that would classify to this gesture
            Vector3[] landmarks = GenerateLandmarksForGesture(gesture);

            if (hand == Hand.Left)
            {
                leftHandLandmarks = landmarks;
                leftHandDetected = true;
            }
            else
            {
                rightHandLandmarks = landmarks;
                rightHandDetected = true;
            }

            // Immediately trigger the gesture
            OnGestureDetected?.Invoke(gesture, hand);
        }

        private Vector3[] GenerateLandmarksForGesture(GestureType gesture)
        {
            Vector3[] landmarks = new Vector3[21];
            Vector3 wrist = new Vector3(0, 0, 0);
            landmarks[0] = wrist;

            switch (gesture)
            {
                case GestureType.RaiseHand:
                    // All tips above wrist
                    landmarks[4] = wrist + Vector3.up * 0.2f;
                    landmarks[8] = wrist + Vector3.up * 0.3f;
                    landmarks[12] = wrist + Vector3.up * 0.3f;
                    landmarks[16] = wrist + Vector3.up * 0.3f;
                    landmarks[20] = wrist + Vector3.up * 0.3f;
                    break;

                case GestureType.Point:
                    landmarks[5] = wrist + Vector3.up * 0.1f;
                    landmarks[8] = wrist + Vector3.up * 0.3f; // Index up
                    landmarks[9] = wrist + Vector3.up * 0.05f;
                    landmarks[12] = wrist + Vector3.down * 0.1f; // Middle down
                    break;

                case GestureType.Fist:
                    // All tips below knuckles
                    landmarks[5] = wrist + Vector3.up * 0.1f;
                    landmarks[8] = wrist + Vector3.up * 0.05f;
                    break;
            }

            return landmarks;
        }
        #endregion

        #region Debug Visualization
        void OnDrawGizmos()
        {
            if (!enableDebugVisualization)
                return;

            // Draw left hand landmarks
            if (leftHandDetected)
            {
                DrawHandGizmos(leftHandLandmarks, Color.blue);
            }

            // Draw right hand landmarks
            if (rightHandDetected)
            {
                DrawHandGizmos(rightHandLandmarks, Color.red);
            }
        }

        private void DrawHandGizmos(Vector3[] landmarks, Color color)
        {
            if (landmarks == null || landmarks.Length != 21)
                return;

            Gizmos.color = color;

            // Draw landmarks as spheres
            foreach (Vector3 landmark in landmarks)
            {
                if (landmark != Vector3.zero)
                {
                    Gizmos.DrawSphere(transform.position + landmark, 0.01f);
                }
            }
        }
        #endregion
    }
}
