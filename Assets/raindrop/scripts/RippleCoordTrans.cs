using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RippleCoordTrans : MonoBehaviour
{
    public Camera maincamera;
    public Material material;
    // Start is called before the first frame update
    void Start()
    {
        if (material==null){
            material = GetComponent<Renderer>().material;
        }
        if (maincamera == null)
        {
            maincamera = Camera.main;
        }

        // material = new Material(shader);
        
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = maincamera.ScreenPointToRay(Input.mousePosition);
            // Debug.Log(Input.mousePosition);
            if (Physics.Raycast(ray, out RaycastHit hit))
            {
                // 获取碰撞点的 UV（要求 MeshCollider 启用 Read/Write）
                Vector2 uv = hit.textureCoord;
                // Debug.Log(uv);
                material.SetVector("_Objxy", new Vector2(uv.x, uv.y));
                // material.SetFloat("_")
            }
        }
    }
}
