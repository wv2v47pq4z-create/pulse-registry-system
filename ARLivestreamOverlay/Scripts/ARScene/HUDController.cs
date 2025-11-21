using UnityEngine;
using TMPro;

namespace ARLivestream.ARScene
{
    public class HUDController : MonoBehaviour
    {
        [Header("UI References")]
        [SerializeField] private TextMeshProUGUI modeText;
        [SerializeField] private TextMeshProUGUI notificationText;
        [SerializeField] private TextMeshProUGUI gestureIndicatorText;
        [SerializeField] private UnityEngine.UI.Image energyBar;
        [SerializeField] private GameObject chatPanel;

        private float notificationTimer = 0f;
        private bool chatHighlighted = false;

        public void SetMode(StateMachine.ARStateMachine.ARState state)
        {
            if (modeText != null)
            {
                modeText.text = $"Mode: {state}";
                modeText.color = GetColorForState(state);
            }
        }

        public void ShowNotification(string message, float duration)
        {
            if (notificationText != null)
            {
                notificationText.text = message;
                notificationText.gameObject.SetActive(true);
                notificationTimer = duration;
            }
        }

        public void UpdateGestureIndicator(Perception.GestureType gesture)
        {
            if (gestureIndicatorText != null)
            {
                if (gesture == Perception.GestureType.None)
                {
                    gestureIndicatorText.text = "";
                }
                else
                {
                    gestureIndicatorText.text = $"Gesture: {gesture}";
                }
            }
        }

        public void SetEnergyLevel(float normalized)
        {
            if (energyBar != null)
            {
                energyBar.fillAmount = Mathf.Clamp01(normalized);
            }
        }

        public void ToggleChatHighlight()
        {
            chatHighlighted = !chatHighlighted;
            if (chatPanel != null)
            {
                chatPanel.SetActive(chatHighlighted);
            }
        }

        void Update()
        {
            if (notificationTimer > 0)
            {
                notificationTimer -= Time.deltaTime;
                if (notificationTimer <= 0 && notificationText != null)
                {
                    notificationText.gameObject.SetActive(false);
                }
            }
        }

        private Color GetColorForState(StateMachine.ARStateMachine.ARState state)
        {
            return state switch
            {
                StateMachine.ARStateMachine.ARState.IDLE_WORLD => Color.gray,
                StateMachine.ARStateMachine.ARState.HOST_DETECTED => Color.cyan,
                StateMachine.ARStateMachine.ARState.INTERACTION_ACTIVE => Color.green,
                StateMachine.ARStateMachine.ARState.OVERDRIVE => Color.red,
                StateMachine.ARStateMachine.ARState.COOLDOWN => Color.blue,
                _ => Color.white
            };
        }
    }
}
