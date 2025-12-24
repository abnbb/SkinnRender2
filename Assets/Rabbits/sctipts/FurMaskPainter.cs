using UnityEngine;
using UnityEngine.Rendering;
[ExecuteInEditMode]
public class FurMaskPainter : MonoBehaviour
{
    private RenderTexture temp0; // 临时缓冲（避免读写冲突）
    public Camera mainCamera; // 主相机（用于射线检测获取 UV）
    public RenderTexture CurrentRT; // 最终保存结果的 RenderTexture
    public Color clearColor = new Color(0, 0, 0, 0); // 清理后的颜色
    
    public Color pointColor = Color.white; // 点的颜色
    public Shader scatterShader; // 用于画点的 Shader
    public Material _scatterMat; // 由 scatterShader 生成的材质
    [HideInInspector] public Vector2 _targetUV = Vector2.zero; // 鼠标对应的 UV 坐标
    [HideInInspector] public bool _needDrawPoint = false; // 是否需要画点（鼠标点击时触发）
    public float pointSize = 0.02f; // 点的大小（UV 空间，[0,1]）

    private Material _rippleMat; // 由 scatterShader 生成的材质
    private CommandBuffer _cmd; // CommandBuffer 实例


    void OnEnable()
    {
        // 1. 初始化相机（默认取主相机）
        if (mainCamera == null)
            mainCamera = Camera.main;

        // 2. 验证关键资源（缺一不可）
        if (!ValidateResources())
        {
            enabled = false;
            return;
        }

        // 3. 创建临时缓冲（与 CurrentRT 同分辨率、格式）
        temp0 = new RenderTexture(CurrentRT.width, CurrentRT.height, 0, CurrentRT.format);
        temp0.filterMode = FilterMode.Bilinear;
        temp0.wrapMode = TextureWrapMode.Clamp;

        // 4. 初始化 CommandBuffer（命名用于 Debug）
        _cmd = new CommandBuffer { name = "FurMask_ScatterPoint" };

        // 5. 初始化画点材质（由 Shader 生成）
        _scatterMat = new Material(scatterShader);
        _scatterMat.SetColor("_PointColor", pointColor);
        _scatterMat.SetFloat("_PointSize", pointSize);
        

        RenderTexture ori = RenderTexture.active;
        RenderTexture.active = CurrentRT;
        GL.Clear(true, true, clearColor); // 核心清理命令
        RenderTexture.active = ori;

        
    }

    void Update()
    {
         // 1. 检测鼠标左键点击（触发画点）
        if (Input.GetMouseButtonDown(0) || Input.GetMouseButton(0))
        {
            Debug.Log("1");
            // 射线检测：获取鼠标点击模型表面的 UV 坐标
            if (GetMouseHitUV(out Vector2 hitUV))
            {
                _targetUV = hitUV;
                _needDrawPoint = true; // 标记需要画点
                Debug.Log("2");
            }
        }
        // Debug.Log("3");

        // 2. 执行 CommandBuffer 画点（每帧执行，确保 CurrentRT 结果更新）
       
        ExecuteDrawPointCmd();
    }

    /// <summary>
    /// 验证必要资源是否齐全
    /// </summary>
    private bool ValidateResources()
    {
        if (CurrentRT == null)
        {
            Debug.LogError("请赋值 RenderTexture（RT）！", this);
            return false;
        }

        if (scatterShader == null)
        {
            Debug.LogError("请赋值 scatterShader！", this);
            return false;
        }

        if (!scatterShader.isSupported)
        {
            Debug.LogError("scatterShader 不支持当前平台！", this);
            return false;
        }

        if (mainCamera == null)
        {
            Debug.LogError("请赋值主相机（mainCamera）！", this);
            return false;
        }

        return true;
    }

    /// <summary>
    /// 射线检测：获取鼠标点击模型表面的 UV 坐标
    /// </summary>
    public bool GetMouseHitUV(out Vector2 hitUV)
    {
        hitUV = Vector2.zero;
        Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);
        // Debug.Log(Input.mousePosition);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            // 直接获取点击点的 UV 坐标（hit.texcoord 已验证可用）
            hitUV = hit.textureCoord;
            Debug.Log($"点击 UV 坐标：{hitUV}", this);
            return true;
        }

        Debug.LogWarning("鼠标未点击任何带 MeshCollider 的模型！", this);
        return false;
    }

    /// <summary>
    /// 执行 CommandBuffer 画点逻辑
    /// </summary>
    public void ExecuteDrawPointCmd()
    {
        // if (_cmd == null || _scatterMat == null || CurrentRT == null || temp0 == null)
        //     return;
        if(_cmd == null)
        {
            _cmd = new CommandBuffer { name = "FurMask_ScatterPoint" };
        }
        // 1. 清空 CommandBuffer 之前的指令
        _cmd.Clear();

        // 2. 步骤1：将 CurrentRT 的当前内容拷贝到临时缓冲 temp0（保留历史画点结果）
        _cmd.Blit(CurrentRT, temp0);

        // 3. 步骤2：将 temp0 作为输入，调用 scatterShader 画新点，输出到 CurrentRT
        _scatterMat.SetVector("_TargetUV", _targetUV); // 传递鼠标 UV 坐标
        _scatterMat.SetFloat("_NeedDraw", _needDrawPoint? 1f:0f); // 控制是否画点
        _cmd.Blit(temp0, CurrentRT, _scatterMat); // 执行 Shader 渲染，更新 CurrentRT
        // Debug.Log(_targetUV );
        // 4. 执行 CommandBuffer（通过相机提交 GPU 指令）
        // mainCamera.AddCommandBuffer(CameraEvent.AfterImageEffects, _cmd);
        Graphics.ExecuteCommandBuffer(_cmd);

        // 5. 重置画点标记（只画一次，避免持续画点）
        if (_needDrawPoint)
            _needDrawPoint = false;
    }

    /// <summary>
    /// 清理资源（避免内存泄漏）
    /// </summary>
    void OnDestroy()
    {
        // 移除 CommandBuffer
        if (mainCamera != null && _cmd != null)
            mainCamera.RemoveCommandBuffer(CameraEvent.AfterImageEffects, _cmd);

        // 销毁材质和临时 RenderTexture
        if (_scatterMat != null)
            DestroyImmediate(_scatterMat);

        if (temp0 != null)
            temp0.Release();
    }

    // 可选：在 Scene 视图绘制 Gizmos，显示 CurrentRT 分辨率（辅助调试）
    // void OnDrawGizmos()
    // {
    //     if (CurrentRT != null)
    //     {
    //         Gizmos.color = Color.cyan;
    //         Gizmos.DrawWireCube(transform.position + Vector3.up, new Vector3(1f, 0.1f, 1f));
    //         UnityEditor.Handles.Label(transform.position + Vector3.up * 0.6f, 
    //             $"CurrentRT 分辨率：{CurrentRT.width}x{CurrentRT.height}\n当前 UV：{_targetUV:F3}");
    //     }
    // }
}