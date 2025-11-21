using UnityEngine;
using System;

namespace ARLivestream.Input
{
    [System.Serializable]
    public struct CameraConfig
    {
        public Vector2Int resolution;
        public int fps;
        public string deviceName;
    }

    public class CameraInputHandler : MonoBehaviour
    {
        public event Action<Texture2D> OnFrameCaptured;

        [SerializeField] private CameraConfig config = new CameraConfig
        {
            resolution = new Vector2Int(1920, 1080),
            fps = 30
        };

        private WebCamTexture webCamTexture;
        private Texture2D currentFrame;
        private bool isCapturing = false;

        public void Initialize(CameraConfig configuration)
        {
            config = configuration;
            Debug.Log($"[CameraInputHandler] Initialized: {config.resolution.x}x{config.resolution.y}@{config.fps}fps");
        }

        public void StartCapture()
        {
            if (WebCamTexture.devices.Length == 0)
            {
                Debug.LogWarning("[CameraInputHandler] No webcam devices found");
                return;
            }

            string deviceName = string.IsNullOrEmpty(config.deviceName) 
                ? WebCamTexture.devices[0].name 
                : config.deviceName;

            webCamTexture = new WebCamTexture(deviceName, config.resolution.x, config.resolution.y, config.fps);
            webCamTexture.Play();
            isCapturing = true;

            Debug.Log($"[CameraInputHandler] Started capture: {deviceName}");
        }

        public void StopCapture()
        {
            if (webCamTexture != null)
            {
                webCamTexture.Stop();
                isCapturing = false;
                Debug.Log("[CameraInputHandler] Stopped capture");
            }
        }

        void Update()
        {
            if (isCapturing && webCamTexture != null && webCamTexture.isPlaying)
            {
                OnFrameCaptured?.Invoke(webCamTexture);
            }
        }

        public Texture2D GetCurrentFrame()
        {
            return webCamTexture;
        }

        void OnDestroy()
        {
            StopCapture();
        }
    }
}
