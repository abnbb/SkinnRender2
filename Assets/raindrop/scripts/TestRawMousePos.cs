using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestRawMousePos : MonoBehaviour
{
    void Awake()
    {
        // 强制解锁鼠标，恢复正常输入
        Cursor.lockState = CursorLockMode.None; 
        Cursor.visible = true; // 确保鼠标光标可见
        Screen.lockCursor = false; // 兼容旧版 API
    }

    void Update()
    {
        Debug.Log($"原始鼠标坐标：{Input.mousePosition} | 窗口中心：({Screen.width/2}, {Screen.height/2})");
        // 额外验证：打印鼠标锁定状态（若为 Locked/Confined 就是问题）
        // Debug.Log($"鼠标锁定状态：{Cursor.lockState}");
    }
}
