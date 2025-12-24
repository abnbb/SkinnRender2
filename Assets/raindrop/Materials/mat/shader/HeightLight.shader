Shader "Custom/HeightLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
        _alpha("alpha",range(0,1)) = 0.5
        _width("width",range(0,1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Cull OFF ZWrite Off ZTest always

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            float _alpha;
            float _width;
            float4 _Color;
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
                
                float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
                float eyeZ = i.eyeZ;
                float2 screenUV =  i.screenPos.xy/i.screenPos.w;
                float screenZ = LinearEyeDepth(SampleSceneDepth(screenUV),_ZBufferParams);
                float diff = 1-min(1,abs(screenZ-eyeZ)/_width);
                // float diff = step(0,(screenZ-eyeZ));
                // clip(diff);
                return float4(diff,0,0,diff);
            }
            ENDHLSL
        }
    }
}
