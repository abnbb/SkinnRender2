// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;
// using UnityEditor;


// [CustomEditor(typeof(FurMaskPainter))]
// public class FurEditor : Editor
// {
//     private FurMaskPainter p;
//     private void OnEnable()
//     {
//         p = (FurMaskPainter)target;
//     }
//     void OnSceneGUI()
//     {
        
//         Event currentEvent = Event.current;
//         // Debug.Log("hello");
//         // 1. 鼠标左键按下：开始绘画
//         if ((currentEvent.type == EventType.MouseDown  ||currentEvent.type == EventType.MouseDrag) && currentEvent.button == 0 && currentEvent.control)
//         { 
//             Ray ray = HandleUtility.GUIPointToWorldRay(currentEvent.mousePosition);
//             if (Physics.Raycast(ray, out RaycastHit hit))
//             {
                
//                 p._targetUV = hit.textureCoord;
//                 Debug.Log(p._targetUV);
//                 p._needDrawPoint = true;
//                 Debug.Log("call1");
//                 p.ExecuteDrawPointCmd();
//                 currentEvent.Use(); // 标记事件已处理，避免重复响应
                
//             }
//         }
        
        
//     }
// }
