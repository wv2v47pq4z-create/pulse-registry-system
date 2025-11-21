using UnityEngine;
using System.Collections.Generic;

namespace ARLivestream.ARScene
{
    public class WorldAnchoredManager : MonoBehaviour
    {
        [Header("Prefabs")]
        [SerializeField] private GameObject portalPrefab;
        
        [Header("Settings")]
        [SerializeField] private int maxPortals = 10;
        
        private List<GameObject> spawnedPortals = new List<GameObject>();

        void Start()
        {
            // Create default portal prefab if none assigned
            if (portalPrefab == null)
            {
                portalPrefab = CreateDefaultPortalPrefab();
            }
        }

        public GameObject SpawnPortal(Vector3 direction, float distance)
        {
            if (spawnedPortals.Count >= maxPortals)
            {
                // Remove oldest portal
                if (spawnedPortals.Count > 0)
                {
                    Destroy(spawnedPortals[0]);
                    spawnedPortals.RemoveAt(0);
                }
            }

            // Calculate spawn position
            Vector3 spawnPos = Camera.main.transform.position + direction.normalized * distance;
            Quaternion spawnRot = Quaternion.LookRotation(direction);

            GameObject portal = Instantiate(portalPrefab, spawnPos, spawnRot);
            spawnedPortals.Add(portal);

            Debug.Log($"[WorldAnchoredManager] Spawned portal at {spawnPos}");
            return portal;
        }

        public void RemoveAllAnchors()
        {
            foreach (var portal in spawnedPortals)
            {
                if (portal != null)
                    Destroy(portal);
            }
            spawnedPortals.Clear();
            Debug.Log("[WorldAnchoredManager] Removed all anchors");
        }

        public void EnableEnvironmentEffects(bool enable)
        {
            // Toggle visibility of all portals
            foreach (var portal in spawnedPortals)
            {
                if (portal != null)
                    portal.SetActive(enable);
            }
        }

        private GameObject CreateDefaultPortalPrefab()
        {
            // Create a simple sphere as default portal
            GameObject prefab = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            prefab.transform.localScale = Vector3.one * 0.5f;
            
            // Add glow material
            var renderer = prefab.GetComponent<Renderer>();
            if (renderer != null)
            {
                renderer.material.color = new Color(0.5f, 0.8f, 1.0f);
                renderer.material.EnableKeyword("_EMISSION");
                renderer.material.SetColor("_EmissionColor", Color.cyan);
            }

            prefab.SetActive(false);
            return prefab;
        }
    }
}
