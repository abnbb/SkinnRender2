Shader "Custom/RiverRippleAnim"
{
    Properties
    {
        _Color("Color",Color) = (0,0,0)
        _RippleColor("RippleColor",Color) = (1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _MinCircleSize("MinCircleSize",float) = 0.01
        _MaxCircleSize("MaxCircleSize",float) = 0.01
        _RippleWidth("RippleWidth",float) = 0.001
        _rippleFadeTime("Fadetime",float) = 2
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _Color;
            float3 _RippleColor;
            float _minCircleSize;
            float _MaxCircleSize;
            float _RippleWidth;
            float _rippleFadeTime;
            float2 _Objxy;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float distance = length(i.uv-_Objxy);
                float t = frac(_Time.y/_rippleFadeTime);
                float mD = lerp(_minCircleSize,_MaxCircleSize,t);
                half4 col;
                col.rgb = step(mD,distance)
                        *(1-step(mD+_RippleWidth,distance))
                        *_RippleColor;
                col.a= 1-t;
                half4 baseColor = half4(_Color,1);
                return col;
            }
            ENDCG
        }
    }
}
