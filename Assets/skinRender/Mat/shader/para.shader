Shader "Unlit/para"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("Height", 2D) = "white" {}
        _heightSCale("heightScale",range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 posWS :TEXCOORD1;
                float3 viewDirTS : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _HeightMap;
            float4 _MainTex_ST;
            float _heightSCale;

            v2f vert (appdata_full v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                // TANGENT_SPACE_ROTATION;
                // o.viewDirTS = mul(rotation, ObjSpaceViewDir(v.vertex));
                float4x4 mat = UNITY_MATRIX_M;
                // float4 tangentWS = normalize( mul(mat, v.tangent));
                // float3 NoramlWS = normalize(mul(mat, v.normal).xyz);
                float3 BiNormalWS = cross( v.normal,v.tangent.xyz)*v.tangent.w;
                float3x3 rotMat = float3x3(v.tangent.xyz, BiNormalWS, v.normal);
                o.viewDirTS = mul(rotMat, ObjSpaceViewDir(v.vertex));
                return o;
            }
            float2 ParallaxOcclusionMapping(float2 uv, float3 viewDirTS, float heightScale) {
                const int layers = 16;
                float layerDepth = 1.0 / layers;
                float currentLayerDepth = 0.0;
                float2 deltaUV = viewDirTS.xy * heightScale / layers; // 每层UV偏移
                
                float2 currentUV = uv;
                float height = tex2D(_HeightMap, currentUV).r;
                
                // 步进采样
                while (currentLayerDepth < height) {
                    currentUV -= deltaUV;
                    height = tex2Dlod(_MainTex,float4(currentUV,0,0)).a;
                    currentLayerDepth += layerDepth;
                }
                
                // 插值优化
                float2 prevUV = currentUV + deltaUV;
                float afterDepth = height - currentLayerDepth;
                float beforeDepth = tex2D(_HeightMap, prevUV).r - (currentLayerDepth - layerDepth);
                float weight = afterDepth / (afterDepth - beforeDepth);
                return prevUV * weight + currentUV * (1 - weight);
            }
            float2 ParallaxOffset(float2 uv, float3 viewDirTS)
            {
                // 从高度图获取高度值（假设R通道存储高度）
                float height = tex2D(_HeightMap, uv).r;
                
                // 计算视差偏移量（将视角方向转换为纹理坐标偏移）
                // 高度值越接近1，偏移越大；高度值越接近0，偏移越小
                float h = (1 - height) * _heightSCale;
                float2 offset = h*viewDirTS/viewDirTS.z;
                return uv-offset;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.viewDirTS);
                viewDir.z+=0.42;
                float2 Puv = saturate(ParallaxOffset(i.uv, viewDir));
                float3 col = tex2D(_MainTex, Puv).rgb;
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
