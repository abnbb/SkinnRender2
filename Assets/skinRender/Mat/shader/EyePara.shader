Shader "Unlit/EyePara"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_NoramlTex("Noraml", 2D) = "white" {}
        [NoScaleOffset]_NoramlDetailTex("NoramlDetail", 2D) = "white" {}
        [NoScaleOffset]_Mask("Mask", 2D) = "white" {}
        _Height("Height", 2D) = "white" {}
        [NoScaleOffset]_PrefilterMap("PrefilterMap",Cube)= "black"{}
        [NoScaleOffset]_IrradianceMap("IrradianceMap",Cube)= "black"{}
        _IBLExposure("IBLExposure", Range(0, 10)) = 1.0
        [NoScaleOffset] _BRDF ("BRDF", 2D) = "white" {}
        _roughness("roughtness",range(0,1)) = 1
        _Heightoffset("Parallax HeightOffset", range(0,1)) = 1
        _Steplayers("Parallax Steplayers", int) = 8
        _HeightScale("Parallax HeightScale", range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline"  }
        
        LOD 100

        Pass
        {

            HLSLINCLUDE
            const float PI = 3.14159265359;
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

            float fresnelReflectance( float3 H, float3 V, float F0 )
			{
  				float base = 1.0 - dot( V, H );
  				float exponential = pow( base, 5.0 );
  				return exponential + F0 * ( 1.0 - exponential );
			}
            ENDHLSL

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
               
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 inoraml: TEXCOORD1;
                float3 Wnormal :TEXCOORD2;
                float3 Wtangent : TEXCOORD3;
                float3 WBitangent : TEXCOORD4;
                float3 Wpos  : TEXCOORD5;
                float3 viewDirTS : TEXCOORD6;
                // half4 tspace0 : TEXCOORD1;
				// half4 tspace1 : TEXCOORD2;
				// half4 tspace2 : TEXCOORD3;
                
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoramlTex); SAMPLER(sampler_NoramlTex);
            TEXTURE2D(_NoramlDetailTex) ;SAMPLER(sampler_NoramlDetailTex);
            TEXTURE2D(_Height) ;SAMPLER(sampler_Height);
            TEXTURE2D(_BRDF) ;SAMPLER(sampler_BRDF);
            TEXTURE2D(_Mask) ;SAMPLER(sampler_Mask);

            TEXTURECUBE(_PrefilterMap); SAMPLER(sampler_PrefilterMap);
            TEXTURECUBE(_IrradianceMap); SAMPLER(sampler_IrradianceMap);
            float _IBLExposure;
            float _roughness;
            float _Heightoffset;
            float _Steplayers;
            float _HeightScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.inoraml = normalize(TransformObjectToWorld(v.normal));

                float4x4 mat = UNITY_MATRIX_M;
                o.Wnormal = normalize(mul(mat, float4(v.normal, 0)).xyz);
                o.Wpos = mul(mat, v.vertex).xyz;

                o.Wtangent = normalize(mul(mat, v.tangent).xyz);
                o.WBitangent = normalize(cross(o.Wnormal, o.Wtangent)*v.tangent.w);

                float3 binoraml = cross(v.normal, v.tangent.xyz)*v.tangent.w;
                float3x3 rotMat = float3x3(v.tangent.xyz,binoraml, v.normal);
                float3 viewDirOS = TransformWorldToObject(float4(_WorldSpaceCameraPos,1)).xyz - v.vertex.xyz;
                o.viewDirTS = mul(rotMat, viewDirOS);
                return o;
            }
            float2 ParallaxOffset(float2 uv, float3 viewDirTS)
            {
                // 从高度图获取高度值（假设R通道存储高度）
                float height = SAMPLE_TEXTURE2D(_Height, sampler_Height, uv).r;
                
                // 计算视差偏移量（将视角方向转换为纹理坐标偏移）
                // 高度值越接近1，偏移越大；高度值越接近0，偏移越小
                float h = (_Heightoffset - height) * _HeightScale;
                viewDirTS.z+=0.42;
                float2 offset = h*viewDirTS/viewDirTS.z;
                return uv-offset;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 normalWS = normalize(i.Wnormal);
                float3 tangentWS = normalize(i.Wtangent);
                float3 bitangentWS = normalize(i.WBitangent);
                float3x3 TBN = float3x3(tangentWS, bitangentWS, normalWS);
                float3 viewDirTS = normalize(i.viewDirTS);

                float2 parallaxUV = ParallaxOffset(i.uv, viewDirTS);
                
                
                float2 mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, parallaxUV).ga;
                // sample the texture
                float3 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, parallaxUV).rgb;
                
                float3 n = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_NoramlTex,sampler_NoramlTex,parallaxUV)));
                float3 nD = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_NoramlDetailTex,sampler_NoramlDetailTex,parallaxUV)));
                n+=0.5*nD;
                float3 normal;
                // normal.x = dot(i.tspace0.xyz, n);
                // normal.y = dot(i.tspace1.xyz, n);
                // normal.z = dot(i.tspace2.xyz, n);
                // float3x3 TBN = float3x3(i.tspace0.xyz,i.tspace1.xyz,i.tspace2.xyz);
                normal = mul(TBN,n);

                
                
                normal = normalize(normal);
                // float3 pos = float3(i.tspace0.w, i.tspace1.w, i.tspace2.w);

                float3 V = normalize(_WorldSpaceCameraPos-i.Wpos);
                float3 F;
                float3 KD;
                float3 Lo = float3(0,0,0);
                Light mainLight = GetMainLight();
                float3 lightColor = mainLight.color;
                float3 L = mainLight.direction;
                float3 N = normal;
                float3 R = reflect(-V, N);
                float3 H = SafeNormalize(V+L);
                float3 F0 = float3(0.04,0.04,0.04);
                float NdotL = saturate(dot(N, L));

                float D = DistributionGGX(i.inoraml, H, _roughness);
                float G = GeometrySmith(i.inoraml, V, L , _roughness); 
                F = fresnelSchlick(max(dot(H,V),0.0),F0);
                KD = 1-F;

                float3 numerator = D*G*F;
                float denominator = 4.0*max(dot(i.inoraml,V),0.0)*max(0.0,dot(i.inoraml,L))+0.00001;
                Lo += (KD*baseColor/PI + numerator/denominator)*lightColor*max(dot(i.inoraml,L),0.0);


                // float highlit = saturate(pow(max(0.0,dot(H,i.inoraml)),256));
                // Lo+=float3(highlit,highlit,highlit);
                
                
                float roughness =0.6;
                float NoH = saturate(dot(N, H));
                half LoH = half(saturate(dot(L, H)));
                float d = NoH * NoH * (roughness*roughness-1) + 1.00001f;
                half d2 = half(d * d);

                half LoH2 = LoH * LoH;
                half specular = (roughness*roughness) / (d2 * max(half(0.1), LoH2)*2);
                half3 specularTerm = specular * half3(0.04, 0.04, 0.04);
                Lo += (specularTerm+baseColor)*lightColor*NdotL*mask.x;


                // float numerator = D*G*F;
                // float denominator = 4.0*max(dot(N,V),0.0)*max(0.0,dot(N,L))+0.00001;
                // Lo += (KD*baseColor/PI + numerator/denominator)*lightColor*max(dot(N,L),0.0);
                F = fresnelSchlick(max(dot(H,V),0.0),F0);
                KD = 1-F;
                float3 Irradiance = SAMPLE_TEXTURECUBE(_IrradianceMap, sampler_IrradianceMap, i.inoraml).rgb;
                float3 diffuse = baseColor*(Irradiance*_IBLExposure+0.1);

                float3 prefilteredColor = SAMPLE_TEXTURECUBE_LOD(_PrefilterMap, sampler_PrefilterMap, R,1-_roughness*7).rgb;
                float2 brdf = SAMPLE_TEXTURE2D(_BRDF,sampler_BRDF, float2(max(0.0,dot(i.inoraml,V)),1-_roughness));
                specular = prefilteredColor * (F*brdf.x+brdf.y)*_IBLExposure;

                float3 ambient = (KD*diffuse/PI+specular*max(dot(N,L),0.0));

                float3 finalColor = ambient+Lo;

                return float4(finalColor, 1);
            }   
            ENDHLSL
        }
    }
}
