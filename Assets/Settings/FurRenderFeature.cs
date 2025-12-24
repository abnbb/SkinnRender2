using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class FurRenderFeature : ScriptableRendererFeature
{
    
    class FurRenderPass : ScriptableRenderPass
    {
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        private int FurLayers;
        private ShaderTagId shaderTag;
        RenderQueueType renderQueueType;
        FilteringSettings m_FilteringSettings;

        public FurRenderPass(int FurLayers, string passLightMode,RenderQueueType renderQueueType,int layerMask)
        {
            this.FurLayers = FurLayers;
        
            this.renderQueueType = renderQueueType;

            RenderQueueRange renderQueueRange = (renderQueueType == RenderQueueType.Transparent)
                ? RenderQueueRange.transparent
                : RenderQueueRange.opaque;
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);

            if (passLightMode != null)
            {
                shaderTag = new ShaderTagId(passLightMode);
            }

        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("FurRendering");
            SortingCriteria sortingCriteria = (renderQueueType == RenderQueueType.Transparent)
                ? SortingCriteria.CommonTransparent
                : renderingData.cameraData.defaultOpaqueSortFlags;
            DrawingSettings drawingSettings;
            if (shaderTag != null)
            {
                drawingSettings = CreateDrawingSettings(shaderTag, ref renderingData, sortingCriteria);
            }
            else return;
            float inter = 1.0f / FurLayers;
            for (int i = 0; i <= FurLayers; i++)
            {
                cmd.Clear();
                cmd.SetGlobalFloat("_FurOffset", i*inter);
                context.ExecuteCommandBuffer(cmd);
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
            }
            cmd.Release();
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    FurRenderPass m_ScriptablePass;

    [System.Serializable]
    public class Settings{
        [Range(1, 32)]public int FurLayers = 16;
        public string passLightMode = "FurRendering";
        public RenderPassEvent PassEvent = RenderPassEvent.AfterRenderingSkybox;
        public RenderQueueType RenderQueueType = RenderQueueType.Opaque;
        public LayerMask LayerMask = ~0;

    }
    public Settings settings = new Settings();


    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new FurRenderPass(settings.FurLayers,settings.passLightMode, settings.RenderQueueType, settings.LayerMask);
        // Configures where the render pass should be injected.
        
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.renderPassEvent = settings.PassEvent;
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


