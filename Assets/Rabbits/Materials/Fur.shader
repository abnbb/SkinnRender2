Shader "Unlit/Fur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Normal("Normal",2D) = "white"{}
        [Header(Lighting)][Space(10)]
        [NoScaleOffset]_IrradianceMap("IrradianceMap",Cube)= "white"{}
        [NoScaleOffset]_PrefilterMap("PrefilterMap",Cube)= "white"{}
        _IBLExposure("IBLExposure", Range(0, 10)) = 1.0
        [NoScaleOffset] _BRDF ("BRDF", 2D) = "white" {}

        [Header(Fur)][Space(10)]
        [NoScaleOffset]_FurPattern("FurPattern", 2D)= "white"
        _FurPatternScale("FurScale", float) = 1
        _FurLength("furLength",float) = 10
        _FurDirandFurFlow("furDirection", Vector) = (0,0.05,3.0,0)
        _FurEdgeFade("FurEdgeFade",float) = 0.0
        _FurMaskByAlpha("FurMaskByAlpha",float) = 1

        [Header(Shadow)][Space(10)]
        _ShadowStrength("ShadowStrength",float) = 1
    }  

    SubShader
    {
        Tags{"LightMode" = "FurRendering"}
        Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

       
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 tangentWS : TEXCOORD1;
                float4 normalWS : TEXCOORD2;
                float3 posWs : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Normal;
            samplerCUBE  _IrradianceMap;
            samplerCUBE  _PrefilterMap;
            sampler2D _BRDF;
            float _IBLExposure;

            sampler2D _FurPattern;
            float _FurPatternScale;
            float _FurOffset;
            float _FurLength;
            float4 _FurDirandFurFlow;
            float _FurEdgeFade;
            float _FurMaskByAlpha;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.xyz += v.normal*_FurLength*_FurOffset*0.001;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
               
                float4x4 mat = UNITY_MATRIX_M;

                o.posWs = mul(mat, v.vertex).xyz;
                
                o.tangentWS = normalize(mul(mat, v.tangent));
                o.normalWS = normalize(mul(mat, float4(v.normal, 0)));

                return o;
            }
            
            float DistributionGGX(float3 N, float3 H, float roughness)
            {
                const float PI = 3.14159265359;
                float a = roughness * roughness;
                float a2 = a * a;
                float NdotH = max(dot(N, H), 0.0);
                float NdotH2 = NdotH * NdotH;

                float nom = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = PI * denom * denom;

                return nom / denom;
            }
            // ----------------------------------------------------------------------------
            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1.0);
                float k = (r * r) / 8.0;

                float nom = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }
            // ----------------------------------------------------------------------------
            float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
            {
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx2 = GeometrySchlickGGX(NdotV, roughness);
                float ggx1 = GeometrySchlickGGX(NdotL, roughness);

                return ggx1 * ggx2;
            }
            // ----------------------------------------------------------------------------
            float3 fresnelSchlick(float cosTheta, float3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
            }
            // ----------------------------------------------------------------------------
            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
                float smoothness = 1.0 - roughness;
                return F0 + (max(float3(smoothness, smoothness, smoothness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                const float PI = 3.14159265359;
                // sample the texture
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                float2 FurGravity = _FurOffset*_FurOffset*_FurDirandFurFlow.xy;
                float2 furUV = i.uv*_FurPatternScale+FurGravity;
                
                float FurPattern = tex2D(_FurPattern,furUV).r;
                FurPattern -= _FurOffset*_FurOffset*_FurEdgeFade;
                FurPattern = saturate(FurPattern);

                float FurAlpha = saturate(lerp(FurPattern,1.0,step(_FurOffset,0.0001)));
                float furmask = step(_FurOffset,baseColor.a);
                half BaseAlpha = FurAlpha*furmask;



                float3 V = normalize(_WorldSpaceCameraPos-i.posWs);
                float3 normalTS = normalize(UnpackNormal(tex2D(_Normal,i.uv)));
                float3 sgn = i.tangentWS.w;
                float3 bitangentWS = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3x3 TBN = float3x3(i.tangentWS.xyz,bitangentWS.xyz,i.normalWS.xyz);
                float3 N = mul(TBN,normalTS);
                N= i.normalWS;
                float3 L = UnityWorldSpaceLightDir(i.posWs);
                float3 LightColor = _LightColor0;
                float3 H = normalize(V+L);
                float3 R = reflect(-V, N);
                
                float NdotL = dot(N,L);

                float3 Lo = float3(0,0,0);
                float roughness =0.7;
                float3 F0 = float3(0.04,0.04,0.04);
                float D = DistributionGGX(N, H,roughness);
                float G = GeometrySmith(N, V, L, roughness);
                float3 F = fresnelSchlickRoughness(max(0,dot(H, V)),F0,roughness);

                float3 numerator  = F * G * D;
                float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)  + 0.0001;
                float3 specular = numerator/denominator;
                float3 KD = 1-F;
                Lo = (KD * baseColor.rgb / PI + specular)*max(NdotL,0)*LightColor;

                F = fresnelSchlickRoughness(max(0,dot(H,V)),F0, roughness);
                KD =1-F;
                float3 Irradiance = texCUBE(_IrradianceMap,N).rgb;
                float3 diffuse = Irradiance * baseColor.rgb;
                const float MAX_REFLECTION_LOD = 7;
                float3 prefilteredColor = texCUBElod(_PrefilterMap,float4(R,MAX_REFLECTION_LOD*roughness)).rgb;
                float2 brdf = tex2D(_BRDF, float2(max(0,dot(N,V)),roughness)).rg;
                specular = prefilteredColor * (F*brdf.x+brdf.y);

                float3 ambient = (KD*diffuse+specular)*_IBLExposure;
                // float3 color = (ambient+Lo)*;

                return half4(ambient+Lo,BaseAlpha);

            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" } // 标记为阴影投射 Pass

            ZWrite On
            ZTest LEqual
            Cull Off
            ColorMask 0 // 不输出颜色，仅写入深度（优化性能）
            AlphaToMask On // 支持 Alpha 裁剪（镂空图阴影正确）

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster // 编译阴影相关变体（适配不同光照）

            // #include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _FurEdgeFade; // Alpha 裁剪阈值
                float _ShadowStrength; // 阴影强度（影响阴影浓度）
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                V2F_SHADOW_CASTER; // URP 内置阴影投射顶点数据（含深度变换）
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // 1. 采样纹理，进行 Alpha 裁剪（避免透明区域投射阴影）
                half4 texCol = tex2Dlod(_MainTex, float4(o.uv, 0, 0));

                // 2. URP 内置阴影投射顶点变换（自动处理阴影贴图的深度写入）
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // 输出阴影强度（影响阴影的透明度，0=完全透明，1=完全黑）
                // 注意：ShadowCaster Pass 的输出颜色不影响阴影颜色（由光照设置控制），仅影响浓度
                return half4(_ShadowStrength, _ShadowStrength, _ShadowStrength, 1);
            }
            ENDCG
        }

    }
}
