// using UnityEngine;
// using UnityEditor;
// using UnityEngine.Rendering;

// public class FurMaskPainterEditorWindow : EditorWindow
// {
//     // 核心配置参数（窗口内可视化调整）
//     private Camera targetCamera; // 用于射线检测的相机
//     private RenderTexture currentRT; // 绘制目标 RenderTexture
//     private Color clearColor = new Color(0, 0, 0, 0); // 清空颜色
//     private Color pointColor = Color.white; // 画点颜色
//     private Shader scatterShader; // 画点Shader
//     private float pointSize = 0.02f; // 点大小（UV空间）

//     // 内部变量
//     private Material scatterMat; // Shader生成的材质
//     private RenderTexture tempRT; // 临时缓冲（避免读写冲突）
//     private CommandBuffer cmd; // GPU指令缓冲
//     private Vector2 targetUV = Vector2.zero; // 点击目标UV
//     private bool needDrawPoint = false; // 画点标记
//     private bool isPainting = false; // 持续绘画标记（按住鼠标）
//     private Rect rtPreviewRect; // RT预览区域矩形

//     // 窗口菜单入口（顶部菜单栏打开）
//     [MenuItem("Tools/Fur Mask Painter", priority = 103)]
//     public static void ShowWindow()
//     {
//         GetWindow<FurMaskPainterEditorWindow>("毛发遮罩绘制工具");
//     }

//     // 窗口初始化（打开时执行）
//     private void OnEnable()
//     {
//         // 默认选中主相机
//         if (targetCamera == null)
//             targetCamera = Camera.main;

//         // 初始化CommandBuffer
//         cmd = new CommandBuffer { name = "FurMaskPainter_Cmd" };

//         // 窗口大小默认值
//         minSize = new Vector2(400, 600);
//     }

//     // 窗口UI绘制（每帧更新）
//     private void OnGUI()
//     {
//         // 3. RT预览区域
//         DrawRTPreview();

//         GUILayout.Space(20);

//         // 4. 功能按钮区域
//         DrawFunctionButtons();
//     }


//     /// <summary>
//     /// 绘制RenderTexture预览
//     /// </summary>
//     private void DrawRTPreview()
//     {
//         GUILayout.Label("=== 实时预览 ===", EditorStyles.boldLabel);

//         // 计算预览区域大小（适应窗口宽度，保持16:9比例）
//         float previewWidth = position.width - 40;
//         float previewHeight = previewWidth * 9 / 16;
//         rtPreviewRect = new Rect(20, GUILayoutUtility.GetLastRect().yMax + 10, previewWidth, previewHeight);

//         // 绘制预览背景
//         EditorGUI.DrawRect(rtPreviewRect, Color.gray * 0.3f);

//         // 绘制RT内容（如果RT有效）
//         if (currentRT != null)
//         {
//             GUI.DrawTexture(rtPreviewRect, currentRT, ScaleMode.ScaleToFit);
//         }
//         else
//         {
//             // 无RT时显示提示文字
//             EditorGUI.LabelField(rtPreviewRect, "请选择或创建RenderTexture", EditorStyles.centeredGreyMiniLabel);
//         }

//         // 预览区域下方显示RT信息
//         GUILayout.Space(previewHeight + 20);
//         if (currentRT != null)
//         {
//             GUILayout.Label($"RT分辨率：{currentRT.width}x{currentRT.height} | 格式：{currentRT.format}", EditorStyles.miniLabel);
//             GUILayout.Label($"当前点击UV：{targetUV:F3}", EditorStyles.miniLabel);
//         }
//     }

//     /// <summary>
//     /// 绘制功能按钮
//     /// </summary>
//     private void DrawFunctionButtons()
//     {
//         GUILayout.BeginHorizontal();

//         // 保存RT为图片
//         if (GUILayout.Button("保存为PNG"))
//         {
//             SaveRTToPNG();
//         }
//     }

//     /// <summary>
//     /// 清空RenderTexture（填充clearColor）
//     /// </summary>
//     private void ClearRT()
//     {
//         if (currentRT == null)
//             return;

//         RenderTexture original = RenderTexture.active;
//         RenderTexture.active = currentRT;
//         GL.Clear(true, true, clearColor);
//         RenderTexture.active = original;

//         Debug.Log("遮罩已清空", this);
//     }

//     /// <summary>
//     /// 保存RenderTexture为PNG图片
//     /// </summary>
//     private void SaveRTToPNG()
//     {
//         if (currentRT == null)
//         {
//             EditorUtility.DisplayDialog("错误", "请先创建或选择RenderTexture！", "确定");
//             return;
//         }

//         // 选择保存路径
//         string savePath = EditorUtility.SaveFilePanel(
//             "保存遮罩图片",
//             Application.dataPath,
//             "FurMask_" + System.DateTime.Now.ToString("yyyyMMddHHmmss"),
//             "png"
//         );

//         if (string.IsNullOrEmpty(savePath))
//             return;

//         // 读取RT像素并保存
//         RenderTexture.active = currentRT;
//         Texture2D tex = new Texture2D(currentRT.width, currentRT.height, TextureFormat.ARGB32, false);
//         tex.ReadPixels(new Rect(0, 0, currentRT.width, currentRT.height), 0, 0);
//         tex.Apply();
//         RenderTexture.active = null;

//         byte[] pngData = tex.EncodeToPNG();
//         System.IO.File.WriteAllBytes(savePath, pngData);

//         DestroyImmediate(tex);
//         AssetDatabase.Refresh(); // 刷新Project面板

//         EditorUtility.DisplayDialog("成功", $"图片已保存到：\n{savePath}", "确定");
//         Debug.Log($"遮罩图片保存成功：{savePath}", this);
//     }
// }