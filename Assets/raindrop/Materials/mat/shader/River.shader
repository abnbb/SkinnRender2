Shader "Custom/River"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _RippleColor("RippleColor",Color)= (1,1,1,1)
        _HeightMap("Noraml Map",2D) = "black"{}
        _HeightMap2("Height Map2",2D) = "black"{}
        _flowMap("FlowMap",2D) = "black"{}
        _NormalStrength("HeightNormalStrength",Range(0,10)) = 0.1
        _ReflectMap ("ReflectMap", Cube) = "white" {} // 反射立方体贴图
        _ReflectStrength ("ReflectStrength", Range(0, 1)) = 0.7 // 反射混合比例
        _ReflecRoughness ("ReflecRoughness", Range(0, 1)) = 0 // 反射模糊度（0=模糊，1=清晰）

    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent" // 半透明渲染（水面）
            "Queue"="Transparent" // 渲染队列（半透明物体后渲染）
            "RenderPipeline"="UniversalPipeline" // 标记为URP管线
        }
        Zwrite Off

        LOD 100

        // Pass
        // {
        //     ZWrite On
        //     Cull Back
        //     Blend SrcAlpha OneMinusSrcAlpha

        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag

        //     #include "UnityCG.cginc"

        //     struct appdata
        //     {
        //         float4 vertex : POSITION;
        //         float2 uv : TEXCOORD0;
        //     };

        //     struct v2f
        //     {
        //         float2 uv : TEXCOORD0;
        //         float4 vertex : SV_POSITION;
        //         float3 posWS : TEXCOORD1;
        //         float4 screenPos:TEXCOORD2;
        //     };

        //     float4 _HeightMap_TexelSize;
        //     sampler2D _HeightMap;
        //     sampler2D _Heightmask;
        //     sampler2D _HeightMap2;
        //     samplerCUBE _ReflectMap;
        //     sampler2D _flowMap;
        //     float4 _HeightMap_ST;
        //     float4 _Color;
        //     float4 _RippleColor;
        //     float _NormalStrength;


        //     v2f vert (appdata v)
        //     {
        //         v2f o;
        //         o.vertex = UnityObjectToClipPos(v.vertex);
        //         o.uv = TRANSFORM_TEX(v.uv, _HeightMap);
        //         float4x4 mat = UNITY_MATRIX_M;
        //         o.screenPos = ComputeScreenPos(o.vertex);
        //         o.posWS = mul(mat, v.vertex).xyz;
        //         return o;
        //     }

        //     half3 HeightToNormal(sampler2D heightMap,float2 uv)
        //     {
                
        //         // 1. 采样当前及相邻像素的高度（灰度值 = 高度）
        //         float h = tex2D(heightMap, uv).r;
        //         float hRight = tex2D(heightMap, uv + float2(_HeightMap_TexelSize.x, 0)).r;
        //         float hLeft = tex2D(heightMap, uv - float2(_HeightMap_TexelSize.x, 0)).r;
        //         float hUp = tex2D(heightMap, uv + float2(0, _HeightMap_TexelSize.y)).r;
        //         float hDown = tex2D(heightMap, uv - float2(0, _HeightMap_TexelSize.y)).r;

        //         // 2. 计算梯度（高度差）
        //         float dx = (hRight - hLeft)*_NormalStrength;
        //         float dy = (hDown - hUp)*_NormalStrength;

        //         // 3. 构建并归一化法线向量（适配 Unity 坐标系）
        //         half3 normal = half3(-dx, -dy, 1.0f);
        //         return normalize(normal);
        //     }

        //     half4 frag (v2f i) : SV_Target
        //     {
        //         float2 screenUV = i.screenPos.xy / i.screenPos.w;
        //         float depth = saturate(tex2D(_Heightmask,screenUV));
        //         depth = saturate(pow(depth,8));
        //         // sample the texture
        //         half3 h = tex2D(_HeightMap, i.uv);
        //         half3 N1 = HeightToNormal(_HeightMap,i.uv);
        //         float2 Fdirc = tex2D(_flowMap,i.uv*10+float2(_Time.y,0)).rg;
        //         // float depth = 
        //         half3 N2 = HeightToNormal(_HeightMap2,i.uv*0.7+Fdirc*0.003+float2(_Time.y,0)*0.005);
        //         half3 V = normalize(_WorldSpaceCameraPos-i.posWS);
        //         half3 L = UnityWorldSpaceLightDir(i.posWS);
        //         half3 H = normalize(L+V);
        //         // half3 L = normalize(half3(1,0,1));
        //         half3 N = normalize(N1*1.5+N2);
        //         half3 R = normalize(reflect(-V,N));
        //         half diff = saturate(max(dot(L,N),0));
        //         half spec = pow(max(dot(H,N),0),8);

        //         half3 c = lerp(_Color,_RippleColor,depth);
        //         half3 basecolor = diff*c+10*spec*_RippleColor;

        //         //half3 reflectColor = tex2D(_ReflectionMap,float2(screenUV.x,1-screenUV.y));
        //         half3 reflectColor = texCUBE(_ReflectMap,R).rgb;
        //         // basecolor+=smoothstep(0.01,0,depth)*_RippleColor;
        //         return  half4(basecolor,0.5+pow(0.4-depth,3));
        //         // return pow(max(dot(H,N),0),8);
                
        //     }
        //     ENDCG
        // }


        Pass{
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 posWS : TEXCOORD1;
                float4 screenPos:TEXCOORD2;
            };

            TEXTURE2D(_HeightMap);SAMPLER(sampler_HeightMap);
            TEXTURE2D(_Heightmask);SAMPLER(sampler_Heightmask);
            TEXTURE2D(_HeightMap2);SAMPLER(sampler_HeightMap2);
            //TEXTURE2D(_ReflectMap);SAMPLER(sampler_ReflectMap);
            TEXTURE2D(_flowMap);SAMPLER(sampler_flowMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _HeightMap_ST;
                float4 _Color;
                float4 _RippleColor;
                float _NormalStrength;
                float4 _HeightMap_TexelSize;
                float _ReflectStrength;
                float _ReflecRoughness;
                samplerCUBE  _ReflectMap;
            CBUFFER_END


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _HeightMap);
                float4x4 mat = UNITY_MATRIX_M;
                o.screenPos = ComputeScreenPos(o.vertex);
                o.posWS = mul(mat, v.vertex).xyz;
                return o;
            }

            half3 HeightToNormal( float2 uv)
            {
                // 1. 采样当前及相邻像素的高度（灰度值 = 高度）
                // 注：HLSL 需用 SAMPLE_TEXTURE2D 采样，依赖 TEXTURE2D + SAMPLER 声明
                float h = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv).r;
                float hRight = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv + float2(_HeightMap_TexelSize.x, 0)).r;
                float hLeft = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv - float2(_HeightMap_TexelSize.x, 0)).r;
                float hUp = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv + float2(0, _HeightMap_TexelSize.y)).r;
                float hDown = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv - float2(0, _HeightMap_TexelSize.y)).r;

                // 2. 计算梯度（高度差 × 法线强度，保持原逻辑：hDown - hUp）
                float dx = (hRight - hLeft) * _NormalStrength;
                float dy = (hDown - hUp) * _NormalStrength;

                // 3. 构建并归一化法线向量（适配 Unity 坐标系，Z 轴向上）
                half3 normal = half3(-dx, -dy, 1.0f);
                return normalize(normal);
            }

            half3 HeightToNormal2( float2 uv)
            {
                // 1. 采样当前及相邻像素的高度（灰度值 = 高度）
                // 注：HLSL 需用 SAMPLE_TEXTURE2D 采样，依赖 TEXTURE2D + SAMPLER 声明
                float h = SAMPLE_TEXTURE2D(_HeightMap2, sampler_HeightMap2, uv).r;
                float hRight = SAMPLE_TEXTURE2D(_HeightMap2, sampler_HeightMap2, uv + float2(_HeightMap_TexelSize.x, 0)).r;
                float hLeft = SAMPLE_TEXTURE2D(_HeightMap2, sampler_HeightMap2, uv - float2(_HeightMap_TexelSize.x, 0)).r;
                float hUp = SAMPLE_TEXTURE2D(_HeightMap2, sampler_HeightMap2, uv + float2(0, _HeightMap_TexelSize.y)).r;
                float hDown = SAMPLE_TEXTURE2D(_HeightMap2, sampler_HeightMap2, uv - float2(0, _HeightMap_TexelSize.y)).r;

                // 2. 计算梯度（高度差 × 法线强度，保持原逻辑：hDown - hUp）
                float dx = (hRight - hLeft) * _NormalStrength;
                float dy = (hDown - hUp) * _NormalStrength;

                // 3. 构建并归一化法线向量（适配 Unity 坐标系，Z 轴向上）
                half3 normal = half3(-dx, -dy, 1.0f);
                return normalize(normal);
            }


            half4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float depth = saturate(SAMPLE_TEXTURE2D(_Heightmask,sampler_Heightmask,screenUV).r);
                depth = saturate(pow(depth,2));
                // sample the texture
                half3 h = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap,i.uv).r;
                half3 N1 = HeightToNormal(i.uv);
                float2 Fdirc = SAMPLE_TEXTURE2D(_flowMap,sampler_flowMap,i.uv*10+0.5*float2(_Time.y,0)).rg;
                // float depth = 
                half3 N2 = HeightToNormal2(i.uv*0.5 +Fdirc*0.01 +float2(_Time.y,0)*0.01);
                half3 V = normalize(_WorldSpaceCameraPos-i.posWS);

                Light mainLight = GetMainLight();
                half3 L = mainLight.direction;
                half3 LColor = mainLight.color;
                half3 H = normalize(L+V);
                // half3 L = normalize(half3(1,0,1));
                half3 N = normalize(N1*1.5+N2);

                float3 R = normalize(reflect(V, N));
                half diff = saturate(max(dot(L,N),0));
                half spec = pow(max(dot(H,N),0),8);

                half3 c = lerp(_Color,_RippleColor,depth);
                half3 basecolor = diff*c+50*spec*LColor;

                half3 reflectColor = texCUBElod(_ReflectMap,  float4(R, _ReflecRoughness * 10)).rgb;
                basecolor = lerp(basecolor,reflectColor.rgb,_ReflectStrength);

                // half3 reflectColor = SAMPLE_TEXTURE2D(_ReflectionMap,sampler_ReflectionMap,float2(screenUV.x,0.8*(1-screenUV.y)));
                // float screenZ = Linear01Depth(SampleSceneDepth(screenUV),_ZBufferParams);
                half3 finalColor = basecolor*LColor;
                half finalAlpha = 0.5+pow(0.3-depth,3);
                // basecolor+=smoothstep(0.01,0,depth)*_RippleColor;
                return  half4(finalColor,finalAlpha);
                // return half4(depth,0,0,1);
                
            }
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "HeightMask"}
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
                // float diff = 1-min(1,abs(screenZ-eyeZ));
                // float diff =smoothstep(0,1,saturate(screenZ-eyeZ));
                float diff = 1-min(1,abs(screenZ-eyeZ)/0.1);
                // clip(diff);
                return float4(diff,0,0,1);
            }
            ENDHLSL
        }
    }
}
