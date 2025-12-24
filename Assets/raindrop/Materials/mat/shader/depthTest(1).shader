Shader "Hidden/DepthDebugURP"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _CameraDepthTexture("DepthTex", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }

        // Pass
        // {
        //     // Tags{"LightMode" = "HeightMask"}
        //     Name "DepthDebug"
        //     ZTest Always
        //     ZWrite Off
        //     Cull Off
        //     Blend Off

        //     HLSLPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //     struct Attributes
        //     {
        //         float4 positionOS : POSITION;
        //         float2 uv : TEXCOORD0;
        //     };

        //     struct Varyings
        //     {
        //         float4 positionHCS : SV_POSITION;
        //         float2 uv : TEXCOORD0;
        //     };

        //     Varyings vert (Attributes IN)
        //     {
        //         Varyings OUT;
        //         OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
        //         OUT.uv = IN.uv;
        //         return OUT;
        //     }

        //     TEXTURE2D(_CameraDepthTexture);
        //     SAMPLER(sampler_CameraDepthTexture);

        //     float LinearEyeDepth(float rawDepth)
        //     {
        //         return Linear01Depth(rawDepth, _ZBufferParams);
        //     }

        //     float4 frag (Varyings IN) : SV_Target
        //     {
        //         float rawDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, IN.uv).r;
        //         float linearDepth = LinearEyeDepth(rawDepth);
        //         return float4(linearDepth.xxx, 1); // 灰度显示
        //     }
        //     ENDHLSL
        // }

        Pass
        {
            // Tags{"LightMode" = "HeightMask"}
            Name "HeightMask"
            ZWrite Off
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float eyeZ : TEXCOORD1;
                float4 screenPos:TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv+float2(_Time.x,0.3*_Time.x);
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.eyeZ = -TransformWorldToView(worldPos).z;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float eyeZ = i.eyeZ;
                float2 screenUV =  i.screenPos.xy/i.screenPos.w;
                float screenZ = LinearEyeDepth(SampleSceneDepth(screenUV),_ZBufferParams);
                // float diff = 1-min(1,abs(screenZ-eyeZ)/_width);
                float diff = step(0,(screenZ-eyeZ));
                // clip(diff);
                return float4(diff,0,0,1);
            }
            ENDHLSL
        }

    }
    FallBack Off
}
