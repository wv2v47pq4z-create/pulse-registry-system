using UnityEngine;
using System;

namespace ARLivestream.StateMachine
{
    /// <summary>
    /// Core state machine for AR Livestream system.
    /// Manages transitions between: IDLE_WORLD, HOST_DETECTED, INTERACTION_ACTIVE, OVERDRIVE, COOLDOWN
    /// </summary>
    public class ARStateMachine : MonoBehaviour
    {
        #region State Enum
        public enum ARState
        {
            IDLE_WORLD,
            HOST_DETECTED,
            INTERACTION_ACTIVE,
            OVERDRIVE,
            COOLDOWN
        }
        #endregion

        #region Events
        public event Action<ARState, ARState> OnStateChanged;
        #endregion

        #region Properties
        public ARState CurrentState { get; private set; } = ARState.IDLE_WORLD;
        public float StateElapsedTime => Time.time - stateStartTime;
        #endregion

        #region State Timers
        [Header("State Timers")]
        [SerializeField] private float overdriveTimerDuration = 10f;
        [SerializeField] private float cooldownTimerDuration = 5f;
        [SerializeField] private float hostExitDelay = 2f;
        [SerializeField] private float interactionIdleTimeout = 10f;

        private float stateStartTime;
        private float overdriveTimer;
        private float cooldownTimer;
        #endregion

        #region Dependencies
        [Header("Dependencies")]
        [SerializeField] private Perception.BodyTracker bodyTracker;
        [SerializeField] private Perception.HandGestureRecognizer gestureRecognizer;
        [SerializeField] private Perception.VoiceCommandListener voiceListener;

        [Header("AR Scene References")]
        [SerializeField] private ARScene.HUDController hudController;
        [SerializeField] private ARScene.WorldAnchoredManager worldAnchoredManager;
        [SerializeField] private ARScene.BodyAnchoredManager bodyAnchoredManager;
        #endregion

        #region Initialization
        public void Initialize()
        {
            // Subscribe to perception events
            if (voiceListener != null)
                voiceListener.OnCommandDetected += HandleVoiceCommand;

            if (gestureRecognizer != null)
                gestureRecognizer.OnGestureDetected += HandleGesture;

            if (bodyTracker != null)
            {
                bodyTracker.OnHostEnterFrame += HandleHostEnter;
                bodyTracker.OnHostExitFrame += HandleHostExit;
            }

            // Initialize state
            TransitionTo(ARState.IDLE_WORLD);

            Debug.Log("[ARStateMachine] Initialized");
        }

        void OnDestroy()
        {
            // Unsubscribe from events
            if (voiceListener != null)
                voiceListener.OnCommandDetected -= HandleVoiceCommand;

            if (gestureRecognizer != null)
                gestureRecognizer.OnGestureDetected -= HandleGesture;

            if (bodyTracker != null)
            {
                bodyTracker.OnHostEnterFrame -= HandleHostEnter;
                bodyTracker.OnHostExitFrame -= HandleHostExit;
            }
        }
        #endregion

        #region State Update
        void Update()
        {
            switch (CurrentState)
            {
                case ARState.IDLE_WORLD:
                    UpdateIdleWorld();
                    break;

                case ARState.HOST_DETECTED:
                    UpdateHostDetected();
                    break;

                case ARState.INTERACTION_ACTIVE:
                    UpdateInteractionActive();
                    break;

                case ARState.OVERDRIVE:
                    UpdateOverdrive();
                    break;

                case ARState.COOLDOWN:
                    UpdateCooldown();
                    break;
            }
        }

        private void UpdateIdleWorld()
        {
            // Host detection handled by event subscription
        }

        private void UpdateHostDetected()
        {
            // Check if host has been absent for too long
            if (bodyTracker != null && !bodyTracker.IsHostDetected && StateElapsedTime > hostExitDelay)
            {
                TransitionTo(ARState.IDLE_WORLD);
            }
        }

        private void UpdateInteractionActive()
        {
            // Check if host left
            if (bodyTracker != null && !bodyTracker.IsHostDetected)
            {
                TransitionTo(ARState.COOLDOWN);
                return;
            }

            // Check for idle timeout (no gestures)
            if (gestureRecognizer != null && 
                gestureRecognizer.GetCurrentGesture() == Perception.GestureType.None &&
                StateElapsedTime > interactionIdleTimeout)
            {
                TransitionTo(ARState.HOST_DETECTED);
            }
        }

        private void UpdateOverdrive()
        {
            overdriveTimer -= Time.deltaTime;
            
            // Update HUD with timer
            if (hudController != null)
                hudController.SetEnergyLevel(overdriveTimer / overdriveTimerDuration);

            if (overdriveTimer <= 0)
            {
                overdriveTimer = overdriveTimerDuration; // Reset for next time
                TransitionTo(ARState.COOLDOWN);
            }
        }

        private void UpdateCooldown()
        {
            cooldownTimer -= Time.deltaTime;

            if (cooldownTimer <= 0)
            {
                cooldownTimer = cooldownTimerDuration; // Reset
                TransitionTo(ARState.IDLE_WORLD);
            }
            // Allow early exit if host detected with gesture
            else if (bodyTracker != null && bodyTracker.IsHostDetected &&
                     gestureRecognizer != null && gestureRecognizer.GetCurrentGesture() != Perception.GestureType.None)
            {
                cooldownTimer = cooldownTimerDuration; // Reset
                TransitionTo(ARState.HOST_DETECTED);
            }
        }
        #endregion

        #region Event Handlers
        private void HandleHostEnter()
        {
            if (CurrentState == ARState.IDLE_WORLD)
            {
                TransitionTo(ARState.HOST_DETECTED);
            }
        }

        private void HandleHostExit()
        {
            // Handled in state-specific update methods
        }

        private void HandleVoiceCommand(string command)
        {
            Debug.Log($"[ARStateMachine] Voice command received: {command}");

            switch (command.ToLower())
            {
                case "boost it":
                    if (CurrentState == ARState.INTERACTION_ACTIVE)
                    {
                        overdriveTimer = overdriveTimerDuration;
                        TransitionTo(ARState.OVERDRIVE);
                    }
                    break;

                case "chill it":
                    if (CurrentState == ARState.OVERDRIVE)
                    {
                        overdriveTimer = overdriveTimerDuration; // Reset
                        TransitionTo(ARState.HOST_DETECTED);
                    }
                    break;

                case "portal":
                    // State-independent action
                    if (worldAnchoredManager != null)
                    {
                        Vector3 direction = Camera.main.transform.forward;
                        worldAnchoredManager.SpawnPortal(direction, 2f);
                    }
                    break;

                case "shift mode":
                    // Cycle through states (dev/debug command)
                    CycleState();
                    break;

                case "highlight chat":
                    // Toggle chat visibility (handled by HUD)
                    if (hudController != null)
                        hudController.ToggleChatHighlight();
                    break;
            }
        }

        private void HandleGesture(Perception.GestureType gesture, Perception.Hand hand)
        {
            Debug.Log($"[ARStateMachine] Gesture detected: {gesture} ({hand})");

            // HOST_DETECTED → INTERACTION_ACTIVE transition
            if (CurrentState == ARState.HOST_DETECTED &&
                (gesture == Perception.GestureType.RaiseHand || gesture == Perception.GestureType.Wave))
            {
                TransitionTo(ARState.INTERACTION_ACTIVE);
            }
        }
        #endregion

        #region State Transitions
        public void TransitionTo(ARState newState)
        {
            if (CurrentState == newState)
                return;

            ARState previousState = CurrentState;
            
            // Exit current state
            ExitState(previousState);

            // Update state
            CurrentState = newState;
            stateStartTime = Time.time;

            // Enter new state
            EnterState(newState);

            // Notify listeners
            OnStateChanged?.Invoke(previousState, newState);

            Debug.Log($"[ARStateMachine] Transitioned: {previousState} → {newState}");
        }

        private void EnterState(ARState state)
        {
            switch (state)
            {
                case ARState.IDLE_WORLD:
                    EnterIdleWorld();
                    break;

                case ARState.HOST_DETECTED:
                    EnterHostDetected();
                    break;

                case ARState.INTERACTION_ACTIVE:
                    EnterInteractionActive();
                    break;

                case ARState.OVERDRIVE:
                    EnterOverdrive();
                    break;

                case ARState.COOLDOWN:
                    EnterCooldown();
                    break;
            }
        }

        private void ExitState(ARState state)
        {
            switch (state)
            {
                case ARState.OVERDRIVE:
                    // Reset overdrive effects
                    if (bodyAnchoredManager != null)
                        bodyAnchoredManager.SetAuraIntensity(0.5f);
                    break;
            }
        }

        private void EnterIdleWorld()
        {
            if (hudController != null)
                hudController.SetMode(ARState.IDLE_WORLD);

            if (bodyAnchoredManager != null)
                bodyAnchoredManager.DetachAura();
        }

        private void EnterHostDetected()
        {
            if (hudController != null)
                hudController.SetMode(ARState.HOST_DETECTED);

            if (bodyAnchoredManager != null && bodyTracker != null)
                bodyAnchoredManager.AttachAura(bodyTracker.HostCenterTransform);
        }

        private void EnterInteractionActive()
        {
            if (hudController != null)
                hudController.SetMode(ARState.INTERACTION_ACTIVE);

            if (bodyAnchoredManager != null)
                bodyAnchoredManager.SetAuraIntensity(1.0f);
        }

        private void EnterOverdrive()
        {
            if (hudController != null)
            {
                hudController.SetMode(ARState.OVERDRIVE);
                hudController.ShowNotification("OVERDRIVE ACTIVATED!", 2f);
            }

            if (bodyAnchoredManager != null)
                bodyAnchoredManager.SetAuraIntensity(2.0f);
        }

        private void EnterCooldown()
        {
            if (hudController != null)
            {
                hudController.SetMode(ARState.COOLDOWN);
                hudController.ShowNotification("Cooling down...", cooldownTimerDuration);
            }
        }
        #endregion

        #region Utility Methods
        private void CycleState()
        {
            ARState nextState = CurrentState switch
            {
                ARState.IDLE_WORLD => ARState.HOST_DETECTED,
                ARState.HOST_DETECTED => ARState.INTERACTION_ACTIVE,
                ARState.INTERACTION_ACTIVE => ARState.OVERDRIVE,
                ARState.OVERDRIVE => ARState.COOLDOWN,
                ARState.COOLDOWN => ARState.IDLE_WORLD,
                _ => ARState.IDLE_WORLD
            };

            TransitionTo(nextState);
        }

        public bool CanTransitionTo(ARState targetState)
        {
            // Add any validation logic here
            return true;
        }
        #endregion
    }
}
