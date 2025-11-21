using UnityEngine;

namespace ARLivestream.Output
{
    public class CompositeRenderer : MonoBehaviour
    {
        [SerializeField] private Material compositeMaterial;
        [SerializeField] private RenderTexture finalOutput;
        
        private Texture2D backgroundSource;
        private Camera arCamera;
        private Canvas hudCanvas;

        public void Initialize(int width, int height)
        {
            finalOutput = new RenderTexture(width, height, 24);
            finalOutput.name = "FinalComposite";
            
            Debug.Log($"[CompositeRenderer] Initialized: {width}x{height}");
        }

        public void SetBackgroundSource(Texture2D cameraFeed)
        {
            backgroundSource = cameraFeed;
        }

        public void SetARLayer(Camera camera)
        {
            arCamera = camera;
        }

        public void SetHUDLayer(Canvas canvas)
        {
            hudCanvas = canvas;
        }

        public RenderTexture GetFinalOutput()
        {
            return finalOutput;
        }

        public void SetOutputResolution(int width, int height)
        {
            if (finalOutput != null)
            {
                finalOutput.Release();
            }
            
            finalOutput = new RenderTexture(width, height, 24);
            Debug.Log($"[CompositeRenderer] Resolution changed: {width}x{height}");
        }

        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            // Composite layers: background → AR → HUD
            if (compositeMaterial != null)
            {
                Graphics.Blit(source, destination, compositeMaterial);
            }
            else
            {
                Graphics.Blit(source, destination);
            }
        }

        void OnDestroy()
        {
            if (finalOutput != null)
            {
                finalOutput.Release();
            }
        }
    }
}
