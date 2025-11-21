using UnityEngine;
using System;

namespace ARLivestream.Input
{
    public class MicrophoneInputHandler : MonoBehaviour
    {
        public event Action<float[]> OnAudioSampled;

        [SerializeField] private string deviceName;
        [SerializeField] private int sampleRate = 16000;
        [SerializeField] private int recordLength = 10;

        private AudioClip micClip;
        private bool isListening = false;
        private float[] samples = new float[1024];

        public float VolumeLevel { get; private set; }

        public void Initialize(string device)
        {
            deviceName = device;
            Debug.Log($"[MicrophoneInputHandler] Initialized with device: {deviceName}");
        }

        public void StartListening()
        {
            if (Microphone.devices.Length == 0)
            {
                Debug.LogWarning("[MicrophoneInputHandler] No microphone devices found");
                return;
            }

            if (string.IsNullOrEmpty(deviceName))
                deviceName = Microphone.devices[0];

            micClip = Microphone.Start(deviceName, true, recordLength, sampleRate);
            isListening = true;

            Debug.Log($"[MicrophoneInputHandler] Started listening: {deviceName}");
        }

        public void StopListening()
        {
            if (Microphone.IsRecording(deviceName))
            {
                Microphone.End(deviceName);
                isListening = false;
                Debug.Log("[MicrophoneInputHandler] Stopped listening");
            }
        }

        void Update()
        {
            if (isListening && micClip != null)
            {
                int position = Microphone.GetPosition(deviceName);
                if (position > 0)
                {
                    micClip.GetData(samples, 0);
                    VolumeLevel = CalculateVolume(samples);
                    OnAudioSampled?.Invoke(samples);
                }
            }
        }

        private float CalculateVolume(float[] audioSamples)
        {
            float sum = 0f;
            for (int i = 0; i < audioSamples.Length; i++)
            {
                sum += Mathf.Abs(audioSamples[i]);
            }
            return sum / audioSamples.Length;
        }

        void OnDestroy()
        {
            StopListening();
        }
    }
}
