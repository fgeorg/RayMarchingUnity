using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PassTransformsToShader : MonoBehaviour
{
    [SerializeField] private Transform _torus = null;
    [SerializeField] private Transform _sphere = null;
    [SerializeField] private Transform _box = null;
    private Material _mat = null;

    void Start()
    {
        _mat = GetComponent<Renderer>().sharedMaterial;
    }

    // Update is called once per frame
    void Update()
    {
        if (_mat == null)
        {
            return;
        }
        if (_torus != null)
        {
            _mat.SetMatrix("_TorusTransform", Matrix4x4.TRS(_torus.position, _torus.rotation, _torus.lossyScale).inverse);
        }
        if (_sphere != null)
        {
            _mat.SetMatrix("_SphereTransform", Matrix4x4.TRS(_sphere.position, _sphere.rotation, _sphere.lossyScale).inverse);
        }
        if (_box != null)
        {
            //_box.rotation *= Quaternion.Euler(Vector3.up * Time.deltaTime * 90);
            _mat.SetMatrix("_BoxTransform", Matrix4x4.TRS(_box.position, _box.rotation, _box.lossyScale).inverse);
        }
    }
}
