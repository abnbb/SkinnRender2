using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class HeightMaskRenderFeature : ScriptableRendererFeature
{
    class HeightMaskRenderPass : ScriptableRenderPass
    {
        private ShaderTagId m_ShaderTagId;
        private RenderTexture m_RenderTexture;
        static int ID_HeightMaskRT = Shader.PropertyToID("_Heightmask");
        private RTHandle m_RTHandle;
        public HeightMaskRenderPass(string shaderTagId,RenderTexture RT)
        {
            m_ShaderTagId = new ShaderTagId(shaderTagId);
            m_RenderTexture = RT;

        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureInput(ScriptableRenderPassInput.Depth);
            m_RTHandle = RTHandles.Alloc(m_RenderTexture);
            ConfigureTarget(m_RTHandle);
            ConfigureClear(ClearFlag.All, Color.black);
            cmd.SetGlobalTexture(ID_HeightMaskRT ,m_RTHandle.nameID);
        }


        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("HeightMaskRenderPass");
            using (new ProfilingScope(cmd, new ProfilingSampler("HeightMaskRenderPass")))
            {
                // Here you can add your rendering logic, such as drawing meshes or setting up materials.
                // For example, you could draw a full-screen quad with a specific material.
                var sortingCriteria = SortingCriteria.CommonTransparent;
                var drawSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, sortingCriteria);
                var filterSettings = new FilteringSettings(RenderQueueRange.transparent);
                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filterSettings);
            
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            m_RTHandle = null;
        }
    }

    HeightMaskRenderPass m_ScriptablePass;
    public string Lightmode = "HeightMask";
    public RenderTexture RT;
    public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

    /// <inheritdoc/>
    public override void Create()
    {
        if (RT!=null)
        {
            m_ScriptablePass = new HeightMaskRenderPass(Lightmode,RT);
        }
        

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = renderPassEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


