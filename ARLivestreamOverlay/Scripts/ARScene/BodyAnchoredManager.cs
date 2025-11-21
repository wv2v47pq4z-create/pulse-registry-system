using UnityEngine;

namespace ARLivestream.ARScene
{
    public class BodyAnchoredManager : MonoBehaviour
    {
        [Header("Prefabs")]
        [SerializeField] private GameObject auraPrefab;
        
        [Header("Settings")]
        [SerializeField] private float baseIntensity = 1.0f;
        
        private GameObject currentAura;
        private ParticleSystem auraParticles;
        private Transform attachedHost;

        void Start()
        {
            if (auraPrefab == null)
            {
                auraPrefab = CreateDefaultAuraPrefab();
            }
        }

        public void AttachAura(Transform hostRoot)
        {
            if (hostRoot == null)
                return;

            // Remove existing aura
            DetachAura();

            // Spawn new aura
            currentAura = Instantiate(auraPrefab, hostRoot.position, hostRoot.rotation);
            currentAura.transform.SetParent(hostRoot);
            attachedHost = hostRoot;

            auraParticles = currentAura.GetComponentInChildren<ParticleSystem>();
            
            Debug.Log("[BodyAnchoredManager] Attached aura to host");
        }

        public void DetachAura()
        {
            if (currentAura != null)
            {
                Destroy(currentAura);
                currentAura = null;
                auraParticles = null;
                attachedHost = null;
                Debug.Log("[BodyAnchoredManager] Detached aura");
            }
        }

        public void SetAuraIntensity(float intensity)
        {
            if (auraParticles != null)
            {
                var main = auraParticles.main;
                main.startSize = baseIntensity * intensity;
                
                var emission = auraParticles.emission;
                emission.rateOverTime = 10f * intensity;
            }
        }

        public void PlayEmoteEffect(string emoteName)
        {
            Debug.Log($"[BodyAnchoredManager] Playing emote: {emoteName}");
            // Trigger particle burst or animation
            if (auraParticles != null)
            {
                auraParticles.Emit(20);
            }
        }

        void Update()
        {
            // Keep aura synced with host position
            if (currentAura != null && attachedHost != null)
            {
                currentAura.transform.position = attachedHost.position;
            }
        }

        private GameObject CreateDefaultAuraPrefab()
        {
            GameObject prefab = new GameObject("Aura");
            
            // Add particle system
            ParticleSystem ps = prefab.AddComponent<ParticleSystem>();
            var main = ps.main;
            main.startLifetime = 2f;
            main.startSpeed = 1f;
            main.startSize = 0.1f;
            main.startColor = new Color(0.5f, 0.8f, 1.0f, 0.5f);
            main.loop = true;

            var emission = ps.emission;
            emission.rateOverTime = 10f;

            var shape = ps.shape;
            shape.shapeType = ParticleSystemShapeType.Sphere;
            shape.radius = 0.5f;

            prefab.SetActive(false);
            return prefab;
        }
    }
}
