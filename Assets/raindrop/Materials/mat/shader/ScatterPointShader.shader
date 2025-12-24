Shader "Custom/ScatterPointShader"
{
    Properties
    {
        _MainTex ("Input Texture（RT 传入）", 2D) = "white" {}
        _Heightmask ("_Heightmask", 2D) = "white" {}
        _TargetUV ("Target UV（鼠标坐标）", Vector) = (0,0,0,0)
        _PointSize ("Point Size（UV 空间）", Float) = 0.02
        _PointColor ("Point Color", Color) = (1,1,1,1)
        _NeedDraw ("Need Draw（0=不画，1=画）", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        ZTest less ZWrite Off Cull Off // 关闭深度测试、写入，关闭剔除（确保全屏渲染）

        Pass
        {
            Name "ScatterPoint"
            Tags { "LightMode"="UniversalForward" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                // sampler2D _Heightmask;
                float4 _MainTex_ST;
                float2 _TargetUV;
                float _PointSize;
                float4 _PointColor;
                float _NeedDraw;
                // float2 _TargetScreenUV;
            CBUFFER_END
            
            // 顶点输入（全屏四边形，用于覆盖整个 RT）
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                // float4 screenPos:TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                // 顶点变换到裁剪空间（全屏渲染，覆盖整个 RT）
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // UV 与 RT 对齐
                // o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 1. 采样临时缓冲的历史结果（保留之前画的点）
                half4 originalColor = tex2D(_MainTex, i.uv);
                // float2 screenUV = i.screenPos.xy / i.screenPos.w;
                // 3. 计算当前像素 UV 与目标 UV 的距离（UV 空间）
                float distance = length(i.uv - _TargetUV);
                // float2 a = _TargetScreenUV;

                // 4. 距离小于点大小，混合新点颜色（smoothstep 实现柔和边缘）
                half _point = smoothstep(_PointSize, _PointSize * 0.8f, distance);
                // 根据深度mask判断是否否绘制
                
                // half ifm = step(0,_TargetScreenUV.x);
                // half m = tex2D(_Heightmask,screenUV).r;
                // m = (m+(1-ifm))*ifm;
                // _point*=m;
                // clip(_NeedDraw);
                half3 finalColor = lerp(originalColor.rgb, _PointColor.rgb, _point * _PointColor.a);
                half finalAlpha = originalColor.a + _point * _PointColor.a; // 叠加透明度
                finalColor*=_NeedDraw;
                return half4(finalColor,1);
                // return half4(finalColor.x,0,0,1);
            }
            ENDCG
        }
    }
    // FallBack "Hidden/Universal Render Pipeline/FallbackError"
}