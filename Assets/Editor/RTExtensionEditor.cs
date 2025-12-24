using UnityEditor;
using UnityEngine;
using System.IO;

public class RTExtensionEditor : Editor
{
    /// <summary>
    /// 资源面板右键菜单：导出选中的 RenderTexture 为 PNG
    /// 特性说明：
    /// - "Assets/导出为PNG"：菜单路径（Assets/ 开头表示资源右键菜单）
    /// - false：是否是验证函数（这里直接执行导出逻辑）
    /// - 100：菜单优先级（越小越靠上）
    /// </summary>
    [MenuItem("Assets/export RT as PNG", false, 100)]
    public static void ExportRTToPNG()
    {
        // 1. 获取选中的资源（支持多选，但只处理 RenderTexture 类型）
        Object[] selectedObjects = Selection.objects;
        if (selectedObjects == null || selectedObjects.Length == 0)
        {
            EditorUtility.DisplayDialog("提示", "请先在 Project 面板选中要导出的 RenderTexture！", "确定");
            return;
        }

        int successCount = 0;
        string failedNames = "";

        // 2. 遍历选中的资源，筛选 RenderTexture 并导出
        foreach (var obj in selectedObjects)
        {
            if (obj is RenderTexture rt)
            {
                // 执行导出逻辑
                if (ExportSingleRT(rt))
                {
                    successCount++;
                }
                else
                {
                    failedNames += rt.name + "\n";
                }
            }
            else
            {
                failedNames += $"{obj.name}（非 RenderTexture 类型）\n";
            }
        }

        // 3. 导出结果提示
        string resultMsg = successCount > 0 ? 
            $"成功导出 {successCount} 个 RenderTexture 为 PNG！\n失败的资源：\n{failedNames}" : 
            $"导出失败！\n{failedNames}";
        EditorUtility.DisplayDialog("导出完成", resultMsg, "确定");

        // 4. 刷新 Project 面板（若导出到 Assets 文件夹下，可自动显示）
        AssetDatabase.Refresh();
    }

    /// <summary>
    /// 验证菜单是否可用（只在选中 RenderTexture 时显示菜单）
    /// 特性说明：菜单路径与导出函数一致，第三个参数为 true 表示是验证函数
    /// </summary>
    [MenuItem("Assets/导出为PNG", true, 100)]
    public static bool ValidateExportRTToPNG()
    {
        // 筛选选中的资源中是否有 RenderTexture 类型
        foreach (var obj in Selection.objects)
        {
            if (obj is RenderTexture)
            {
                return true; // 有 RenderTexture 时，菜单可用
            }
        }
        return false; // 无 RenderTexture 时，菜单灰色不可点击
    }

    /// <summary>
    /// 导出单个 RenderTexture 为 PNG
    /// </summary>
    /// <param name="rt">要导出的 RenderTexture</param>
    /// <returns>导出是否成功</returns>
    private static bool ExportSingleRT(RenderTexture rt)
    {
        try
        {
            // 1. 获取 RT 的原始参数（后续恢复用，避免影响原 RT）
            RenderTexture originalActiveRT = RenderTexture.active;
            bool originalEnableMSAA = rt.antiAliasing > 1;

            // 2. 处理 MSAA 类型的 RT（MSAA 纹理无法直接读取，需先拷贝到非 MSAA 纹理）
            RenderTexture tempRT = rt;
            if (originalEnableMSAA)
            {
                // 创建临时非 MSAA RT（与原 RT 同分辨率、格式）
                tempRT = new RenderTexture(rt.width, rt.height, rt.depth, rt.format)
                {
                    filterMode = rt.filterMode,
                    wrapMode = rt.wrapMode,
                    antiAliasing = 1 // 关闭 MSAA
                };
                // 拷贝原 RT 内容到临时 RT
                Graphics.Blit(rt, tempRT);
            }

            // 3. 读取 RT 像素数据
            RenderTexture.active = tempRT;
            Texture2D tex = new Texture2D(tempRT.width, tempRT.height, TextureFormat.ARGB32, false);
            tex.ReadPixels(new Rect(0, 0, tempRT.width, tempRT.height), 0, 0);
            tex.Apply(); // 应用像素数据

            // 4. 弹出保存对话框，选择保存路径
            string defaultFileName = $"{rt.name}_{rt.width}x{rt.height}_{System.DateTime.Now:yyyyMMddHHmmss}.png";
            string savePath = EditorUtility.SaveFilePanel(
                "导出 RenderTexture 为 PNG",
                Application.dataPath, // 默认保存到 Assets 文件夹
                defaultFileName,
                "png"
            );

            if (string.IsNullOrEmpty(savePath))
            {
                Debug.LogWarning($"取消导出：{rt.name}");
                Cleanup(originalActiveRT, tempRT, originalEnableMSAA);
                return false;
            }

            // 5. 编码并保存 PNG 文件
            byte[] pngData = tex.EncodeToPNG();
            File.WriteAllBytes(savePath, pngData);

            // 6. 清理资源（避免内存泄漏）
            DestroyImmediate(tex);
            Cleanup(originalActiveRT, tempRT, originalEnableMSAA);

            Debug.Log($"RenderTexture 导出成功：\n原资源：{rt.name}\n保存路径：{savePath}");
            return true;
        }
        catch (System.Exception e)
        {
            Debug.LogError($"导出 RenderTexture 失败：{rt.name}\n错误信息：{e.Message}");
            return false;
        }
    }

    /// <summary>
    /// 清理临时资源，恢复原始状态
    /// </summary>
    private static void Cleanup(RenderTexture originalActiveRT, RenderTexture tempRT, bool isTempRT)
    {
        // 恢复原始激活的 RT
        RenderTexture.active = originalActiveRT;
        // 销毁临时创建的 RT（如果是 MSAA 转存的临时 RT）
        if (isTempRT && tempRT != null)
        {
            tempRT.Release();
        }
    }
}