using UnityEngine;

namespace ARLivestream.Output
{
    public class VirtualCameraOutput : MonoBehaviour
    {
        public RenderTexture OutputTexture { get; private set; }

        [SerializeField] private Camera compositeCamera;
        [SerializeField] private int outputWidth = 1920;
        [SerializeField] private int outputHeight = 1080;
        [SerializeField] private int targetFPS = 30;

        private bool isStreaming = false;

        public void Initialize(int width, int height, int fps)
        {
            outputWidth = width;
            outputHeight = height;
            targetFPS = fps;

            OutputTexture = new RenderTexture(width, height, 24);
            OutputTexture.name = "OBS_VirtualCamera_Output";
            
            if (compositeCamera == null)
                compositeCamera = Camera.main;

            if (compositeCamera != null)
                compositeCamera.targetTexture = OutputTexture;

            Application.targetFrameRate = fps;
            QualitySettings.vSyncCount = 0;

            Debug.Log($"[VirtualCameraOutput] Initialized: {width}x{height}@{fps}FPS");
        }

        public void StartStreaming()
        {
            isStreaming = true;
            // In real implementation, this would call OBS plugin API
            // OBSVirtualCam.SetOutputTexture(OutputTexture);
            Debug.Log("[VirtualCameraOutput] Streaming started (OBS integration ready)");
        }

        public void StopStreaming()
        {
            isStreaming = false;
            Debug.Log("[VirtualCameraOutput] Streaming stopped");
        }

        public void SetCompositeSource(Camera arCamera)
        {
            compositeCamera = arCamera;
            if (OutputTexture != null)
            {
                compositeCamera.targetTexture = OutputTexture;
            }
        }

        void OnDestroy()
        {
            if (OutputTexture != null)
            {
                OutputTexture.Release();
            }
        }
    }
}
