Shader "Custom/RiverRipple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            float4 _CurrentTex_TexelSize;
            sampler2D _PreTex;
            sampler2D _CurrentTex;
            float _RippleSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 base = tex2D(_CurrentTex,i.uv);
                float3 e = float3(_CurrentTex_TexelSize.xy,0);

                float a = tex2D(_CurrentTex,i.uv+e.zy).x;
                float b = tex2D(_CurrentTex,i.uv-e.zy).x;
                float c = tex2D(_CurrentTex,i.uv+e.xz).x;
                float d = tex2D(_CurrentTex,i.uv-e.xz).x;
                
                float r = tex2D(_CurrentTex,i.uv+e.xy).x;
                float f = tex2D(_CurrentTex,i.uv-e.xy).x;
                float g = tex2D(_CurrentTex,i.uv+float2(e.x,-e.y)).x;
                float h = tex2D(_CurrentTex,i.uv+float2(-e.x,e.y)).x;
                float m = tex2D(_PreTex,i.uv).x;

                float result = (a+b+c+d+r+f+g+h)/4-m;
                result*=_RippleSize;
                return result;
            }
            ENDCG
        }
    }
}
