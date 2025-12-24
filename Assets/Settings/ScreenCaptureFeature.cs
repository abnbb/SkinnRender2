using System.Diagnostics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScreenCaptureFeature : ScriptableRendererFeature
{
    class CopyScreenPass : ScriptableRenderPass
    {
        public RenderTexture outputRT; // 输出纹理
        private RenderTargetIdentifier source; // 源纹理（屏幕缓冲）
        private string profilerTag = "Copy Screen Pass";

        public void Setup(RenderTargetIdentifier sourceRT)
        {
            source = sourceRT; // 接收当前渲染目标（如屏幕）
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (outputRT == null) return;

            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);

            // 确保输出纹理尺寸匹配
            // if (outputRT.width != renderingData.cameraData.cameraTargetDescriptor.width ||
            //     outputRT.height != renderingData.cameraData.cameraTargetDescriptor.height)
            // {
            //     outputRT.Release();
            //     outputRT = new RenderTexture(renderingData.cameraData.cameraTargetDescriptor);
            // }

            // GPU端复制：从源纹理（屏幕）到outputRT
            cmd.Blit(source, outputRT);
            // Debug.log("copy!");

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    public RenderTexture outputRT; // 暴露给外部的输出纹理
    public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    private CopyScreenPass copyPass;


    public override void Create()
    {
        copyPass = new CopyScreenPass();
        // 设置复制时机（如所有渲染完成后）
        copyPass.renderPassEvent = renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        // 将当前相机的渲染目标（屏幕）作为源纹理
        copyPass.Setup(renderer.cameraColorTarget);
        copyPass.outputRT = outputRT;
        renderer.EnqueuePass(copyPass);
    }
}


