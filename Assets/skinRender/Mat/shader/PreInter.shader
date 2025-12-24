Shader "Unlit/PreInter"
{
    Properties
    {
        [NoScaleOffset]_BeckmanLUT("Beckman", 2D) ="white"{}
        [NoScaleOffset]_RimLUT("Rim", 2D) ="white"{}
        _rimIntensity("RimInten", range(0,1)) = 1
        [NoScaleOffset]_Curvate("CurvateMap", 2D) ="white"{}
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_NormalTex("NoramlMap",2D) = "white"{}
        [NoScaleOffset]_NormalDetailTex("NoramlDetailMap",2D) = "white"{}
        _DetailTexInten("DetailTexInten",range(0,1)) = 1
        [NoScaleOffset]_NormalDetailSmoothnessTex("_NormalDetailSmoothnessTex",2D) = "white"{}
        _DetailTill("NormalDetailLevel",range(10,50)) = 25
        [NoScaleOffset]_ScatteringTex("_ScatteringMap",2D) = "white"{}
        _Distortion("Distortion", float) = 1
        _ScatteringScale("ScatteringScale",float) =2
        _ScatteringStrength("ScatteringStrength",range(0,1)) =1
        _ScatteringColor("ScatteringColor",Color) = (1,0,0,1)

        [NoScaleOffset]_IrradianceMap("IrradianceMap",Cube)= "white"{}
        [NoScaleOffset]_PrefilterMap("PrefilterMap",Cube)= "white"{}
        _IBLExposure("IBLExposure", Range(0, 10)) = 1.0
        [NoScaleOffset] _BRDF ("BRDF", 2D) = "white" {}
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

            float3 BeckmanSpecular(float3 N,float3 L, float3 V, float m, float rho_s){

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
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
				float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posProj : SV_POSITION;
				half4 tspace0 : TEXCOORD1;
				half4 tspace1 : TEXCOORD2;
				half4 tspace2 : TEXCOORD3;
            };

            TEXTURE2D(_MainTex) ;SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex) ;SAMPLER(sampler_NormalTex);
            TEXTURE2D(_BeckmanLUT) ;SAMPLER(sampler_BeckmanLUT);
            TEXTURE2D(_Curvate) ;SAMPLER(sampler_Curvate);
            TEXTURE2D(_RimLUT) ;SAMPLER(sampler_RimLUT);
            TEXTURE2D(_NormalDetailTex) ;SAMPLER(sampler_NormalDetailTex);
            TEXTURE2D(_NormalDetailSmoothnessTex) ;SAMPLER(sampler_NormalDetailSmoothnessTex);
            TEXTURE2D(_ScatteringTex) ;SAMPLER(sampler_ScatteringTex);
            TEXTURE2D(_BRDF) ;SAMPLER(sampler_BRDF);
            TEXTURECUBE(_IrradianceMap);SAMPLER(sampler_IrradianceMap);
            TEXTURECUBE(_PrefilterMap);SAMPLER(sampler_PrefilterMap);

            float4 _MainTex_ST;
            float _DetailTexInten;
            float _rimIntensity;
            float _DetailTill;
            float _Distortion;
            float _ScatteringScale;
            float _ScatteringStrength;
            float4 _ScatteringColor;
            float _IBLExposure;

            v2f vert (appdata v)
            {
                v2f o;
                o.posProj = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv*_MainTex_ST.xy+_MainTex_ST.zw;

                float4x4 mat = UNITY_MATRIX_M;
                float3 worldPos = mul(mat, v.vertex).xyz;
                half3 worldnormal = normalize(mul(mat, half4(v.normal,0)).xyz);

                half3 worldTangent = normalize(mul(mat, v.tangent).xyz);
                half3 bitworldTangent = normalize(cross(worldnormal, worldTangent)*v.tangent.w);

                o.tspace0 = half4(worldTangent.x, bitworldTangent.x, worldnormal.x, worldPos.x);
                o.tspace1 = half4(worldTangent.y, bitworldTangent.y, worldnormal.y, worldPos.y);
                o.tspace2 = half4(worldTangent.z, bitworldTangent.z, worldnormal.z, worldPos.z);

                return o;
            }

            

             
            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                
                
                float3 n = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv)));
                float3 nD = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_NormalDetailTex, sampler_NormalDetailTex, i.uv*_DetailTill)));
                float3 normal;
                n = normalize(n+_DetailTexInten*nD);
                normal.x = dot(i.tspace0.xyz, n);
                normal.y = dot(i.tspace1.xyz, n);
                normal.z = dot(i.tspace2.xyz, n);
                normal = normalize(normal);
                float3 worldPos = float3(i.tspace0.w, i.tspace1.w,i.tspace2.w);
                
                float3 N = normal;
                float3 V = normalize(_WorldSpaceCameraPos - worldPos);
                float NdotL,D,G;
                float3 L,lightColor,F0,F,transmitColor,Lo,KD,rim;
                float3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv).rgb;
                
                float roughness = SAMPLE_TEXTURE2D(_NormalDetailSmoothnessTex, sampler_NormalDetailSmoothnessTex,i.uv).r;
                
                int additionalLightCount = GetAdditionalLightsCount();
                float3 specular = float3(0,0,0);

                float c = SAMPLE_TEXTURE2D(_Curvate, sampler_Curvate,i.uv).a;

                Light mainLight = GetMainLight();
                lightColor = mainLight.color;
                L = mainLight.direction;
                NdotL = dot(N, L);
                float3 h = V + L;
                float3 H = normalize(h);
                F0 = float3(0.028,0.028,0.028);
                D = DistributionGGX(N, H,roughness);
                G = GeometrySmith(N, V, L, roughness);
                F = fresnelSchlickRoughness(max(0,dot(H, V)),F0, 
                                            0.55+lerp(0,0.45,roughness));

                float3 numerator  = F * G * D;
                float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)  + 0.0001;
                specular += numerator/denominator;
                KD = 1-F;
                
                // if(NdotL>0.0){
                //     float NdotH = dot(N,H);
             
                //     // NdotH = lerp(0.02,0.98,NdotH);
                //     float kelemen = SAMPLE_TEXTURE2D(_BeckmanLUT, sampler_BeckmanLUT, float2(NdotH, roughness));
                //     float PH = pow(2.0 * kelemen, 10.0);
                //     float F = fresnelReflectance(H, V, 0.028);
                //     half3 specularColor = max(PH * F / dot(h, h), 0);
                //     specular = specularColor* _rho_s;
                //     // return float4(specularColor,1);
                // }

                float3 transDir = L+N*_Distortion;
                float scattering = SAMPLE_TEXTURE2D(_ScatteringTex,sampler_ScatteringTex,i.uv).r;
                float transmitLight = pow(dot(-transDir, V)*scattering*scattering,_ScatteringScale)*_ScatteringStrength;
                transmitColor = saturate(transmitLight*lightColor*_ScatteringColor);

                float NdotL_ = NdotL*0.5+0.5;
                NdotL_ = lerp(0.01,0.99,NdotL_);
                rim = SAMPLE_TEXTURE2D(_RimLUT, sampler_RimLUT,float2(NdotL_,c)).rgb;

                Lo = (KD * baseColor / PI + specular)*lightColor*max(NdotL,0);

                LIGHT_LOOP_BEGIN(additionalLightCount)
                    Light light = GetAdditionalLight(lightIndex, worldPos);
                    L = light.direction;
                    lightColor = light.color;
                    NdotL = dot(N, L);
                    float3 h = V + L;
                    float3 H = normalize(h);
                    // if(NdotL>0.0)
                    // {
                    //     float NdotH = min(0.9,max(0.0,dot(N,H)));
                    //     float PH = pow(2.0 * SAMPLE_TEXTURE2D(_BeckmanLUT, sampler_BeckmanLUT, float2(NdotH, roughness)).r, 10.0);
                    //     float F = fresnelReflectance(H, V,0.028);
                    //     float frSpec = max(PH * F / dot(h, h), 0);
                    //     specular += frSpec*NdotH*_rho_s*lightColor* light.distanceAttenuation;
                    // }
                    F0 = float3(0.028,0.028,0.028);
                    D = DistributionGGX(N, H,roughness);
                    G = GeometrySmith(N,V, L, roughness);
                    F = fresnelSchlick(max(0,dot(H, V)),F0);
                    
                    float3 numerator  = F * G* D;
                    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)  + 0.0001;
                    specular += numerator/denominator;
                    KD = 1-F;
                    
                    // float NdotL_ = NdotL*0.5+0.5;
                    // NdotL_ = lerp(0.01,0.99,NdotL_);
                    // rim = SAMPLE_TEXTURE2D(_RimLUT, sampler_RimLUT,float2(NdotL_,c)).rgb;

                    Lo+= (KD * baseColor / PI + specular)*lightColor*max(NdotL,0);

                    float3 transDir = L+N*_Distortion;
                    float scattering = SAMPLE_TEXTURE2D(_ScatteringTex,sampler_ScatteringTex,i.uv).r;
                    float transmitLight = pow(dot(-transDir, V)*scattering*scattering,_ScatteringScale)*_ScatteringStrength;
                    transmitColor += saturate(transmitLight*lightColor*_ScatteringColor);
                LIGHT_LOOP_END

                
                roughness = 0.6+lerp(0,0.4,roughness);
                F = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);
                KD = 1.0 - F;

                float3 Irradiance =  SAMPLE_TEXTURECUBE(_IrradianceMap, sampler_IrradianceMap, N).rgb;
                float3 diffuse = Irradiance * baseColor;
                
                const float MAX_REFLECTION_LOD = 7;
                float3 R = reflect(-V, N);
                float3 prefilteredColor =  SAMPLE_TEXTURECUBE_LOD(_PrefilterMap, sampler_PrefilterMap,R, MAX_REFLECTION_LOD*roughness).rgb;
                float2 brdf = SAMPLE_TEXTURE2D(_BRDF, sampler_BRDF,float2(max(dot(N,V),0.0), roughness)).rg;
                specular = prefilteredColor * (F * brdf.x + brdf.y);

                float3 ambient = (KD * diffuse + specular)*_IBLExposure*c;
                
                // float3 ambient = 0.05*baseColor;
                // float3 diffuse = ambient + baseColor;
                // diffuse = baseColor+(1-_rimIntensity)*baseColor+ambient;
                // specular = specular;
                // float3 finalColor = specular+diffuse;
                float3 finalColor = ambient + _rimIntensity*rim*Lo + transmitColor;

                return float4(finalColor,1);
            }
            ENDHLSL
        }
    }
}
