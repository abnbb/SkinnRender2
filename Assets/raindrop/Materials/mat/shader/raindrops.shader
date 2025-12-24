Shader "Unlit/raindrops"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _rainStaticAmount("RainStaticAmount",float) = 1
        _rainDropAmount("RainDropAmount",float) = 1
        _rainSpeed("RainSpeed",range(0,1)) = 1
        _rainDropSize("RainDropSize",range(0,1))=1
        _ifRainDropFllow("_ifRainDropFllow",range(0,1)) = 1
        _rainDropFollowSize("RainDropFollowSize",range(0,1))=1
        _rainDropFollowAmount("RainFollowAmount",int) = 6
        _rainDropFllowLength("RainDropFllowLength",range(0.01,1)) = 0.6
        _randomX("Migration X", range(0,1)) = 0.8
        _randomY("Migration Y", range(0,1)) = 0.8
        _drop_uv_disturb("drop uv disturb", range(0,1)) = 0.5
        _level2("rain drop level 2", float) = 3.1415
        _level3("rain drop level 3", float) = 3.1415
        _Blur("blur",range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        ZWrite Off
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
                float4 uv_PS : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            float _rainSpeed;
            float _rainDropAmount;
            float _rainStaticAmount;
            float _rainDropSize;
            float _ifRainDropFllow;
            float _rainDropFollowSize;
            float _rainDropFollowAmount;
            float _randomX;
            float _randomY;
            float _randomX_trace;
            float _drop_uv_disturb;
            float _rainDropFllowLength;
            float _Blur;
            float _level2;
            float _level3;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv_PS = ComputeScreenPos(o.vertex);
                return o;
            }
            float uv_x_trace(float x){
                // return 8*pow(sin(x),4)*sin(x+0.2*cos(0.7*x+cos(5*x)));
                // x-=0.5;
                x*=_rainDropAmount;
                // return 0.2*pow(sin(x),6)*sin(3*x);
                return _randomX_trace*pow(sin(x),6)*sin(x+cos(0.7*x+cos(5*x)));
            }
            float uv_y_trace(float x){
                return 0.4*sin(x+sin(x+0.3*sin(4*x)));
            }

            float2 droppingTrace(float2 uv){
                float x = _Time.y*_rainSpeed;
                uv.y+= uv_y_trace(x);
                uv.x+= uv_x_trace(x);
                return uv;
            }
            

            float DropFollowMask(float2 drop_uv,float2 small_drop_uv){
                float samll_drop_mask_down = step(0,float(drop_uv.y));
                float samll_drop_mask_up = 1-smoothstep(0.1,0.1+_rainDropFllowLength,float(drop_uv.y-small_drop_uv.y));
                return samll_drop_mask_down*samll_drop_mask_up;
            }

            float DropFollowGTraceMask(float2 drop_uv,float2 id_uv){
                id_uv = frac(id_uv);
                float drop_trace_mask_y =smoothstep(0,0.05,drop_uv.y)
                                    *smoothstep(_rainDropFllowLength+0.5 ,-0.5 ,drop_uv.y)*step(0,drop_uv.y)
                                    *smoothstep(1,0.7,id_uv.y);
                float drop_trace_mask_x = smoothstep(-_rainDropSize*2,_rainDropSize*2,drop_uv.x)
                                            *smoothstep(_rainDropSize*2,-_rainDropSize*2,drop_uv.x);
                return drop_trace_mask_x*drop_trace_mask_y;
            }

            float drop_circle(float2 uv, float size){
                float col = length(uv);
                col = smoothstep(size+0.01,size,col);
                return col;
            }
            float Random2D(float2 uv) {
                // 增加偏移量和更复杂的哈希组合，打破周期性
                uv = frac(uv * float2(45.3235, 23.6234)); // 缩放并取小数部分
                uv += dot(uv, uv + 23.1234); // 引入非线性交互
                return frac(uv.x * uv.y); // 最终哈希值
            }
            float N(float t) {
                return frac(sin(t*12345.564)*7658.76);
            }
            float2 randomOffset(float id){
                float2 offset = float2(0,0);
                offset.x = (sin(id+cos(3*id))*sin(3*id)-0.5)*_randomX;
                // offset.y = (sin(id+sin(3*id))*sin(3*id)-0.5)*0.5;
                return offset;
            }


            void parameterScale(){
                _randomX = _randomX;
                _randomX_trace= _randomX*0.45;
                _randomY = _randomY*10;
                _rainDropFollowSize = _rainDropFollowSize/50;
                _rainDropSize = _rainDropSize/10;
                _drop_uv_disturb = _drop_uv_disturb*2;
                _rainDropFllowLength = _rainDropFllowLength*0.5;
                _ifRainDropFllow = _ifRainDropFllow;
                _rainSpeed = _rainSpeed*3;
                _Blur/=30;
                _level2 = pow(_level2,0.5);
                _level3 = pow(_level3,0.25);
            }

            float4 rain_drop(float2 input_uv,float level){
                input_uv = input_uv*level + level;
                float2 offset = float2(0.5,0.5);
                float2 drop_uv = input_uv*_rainDropAmount;
                drop_uv.x*=3;

                float2 small_drop_uv = drop_uv;
                small_drop_uv.y*= _rainDropFollowAmount;
                
                
                drop_uv.x += uv_x_trace(drop_uv.y);
                drop_uv.y+=_Time.y*_rainSpeed/level;
                small_drop_uv.x += uv_x_trace(input_uv.y*_rainDropAmount);
                small_drop_uv.y+=_Time.y*_rainSpeed/level; 
                float2 id_uv = drop_uv;
                drop_uv = frac(drop_uv);
                small_drop_uv = frac(small_drop_uv);

                float id = Random2D(floor(id_uv));
                
                drop_uv.y+=uv_y_trace(_Time.y*_rainSpeed+id*_randomY);

                drop_uv += randomOffset(id);
                small_drop_uv += randomOffset(id);
                
                // float box_x = step(0.95,id_uv.x);
                // float box_y = step(0.95,id_uv.y);
                

                drop_uv-= offset;
                small_drop_uv-=offset;
        
                drop_uv.x/=2;
                small_drop_uv.y/=_rainDropFollowAmount;
                small_drop_uv.x/=2;
                
                
                float drop_trace_mask = DropFollowGTraceMask(drop_uv,id_uv);
                float small_drop_mask = DropFollowMask(drop_uv, small_drop_uv);
                drop_trace_mask = smoothstep(0,0.05,drop_trace_mask);
                float yMap = _rainSpeed;
                drop_uv.y = drop_uv.y * (drop_uv.y > 0.0 ? 1.0 / yMap : yMap);
                float small_drop = drop_circle(small_drop_uv,_rainDropFollowSize);
                float drop = drop_circle(drop_uv,_rainDropSize);
                // return float4(drop_uv+small_drop_uv, drop+(drop_trace_mask+small_drop)*small_drop_mask*_ifRainDropFllow, drop_trace_mask);
                return float4(drop_uv, drop+(drop_trace_mask+small_drop*0.5)*_ifRainDropFllow, drop_trace_mask);
            }

            float4 rain_static(float2 input_uv){
                input_uv = input_uv;
                float2 offset = float2(0.5,0.5);
                float2 drop_uv = input_uv*_rainStaticAmount;
                
                float id = Random2D(floor(drop_uv));
                drop_uv.x +=Random2D(id)*0.4;
                drop_uv.y +=Random2D(id)*0.4;
                
                drop_uv = frac(drop_uv);
                drop_uv -=offset;
                float drop = drop_circle(drop_uv,_rainDropSize*id);
                return float4(drop_uv,drop,0);
            }

            float4 grainBlur(float2 uv,float a){
                float4 col = float4(0,0,0,0);
                float2 offset;
                for (int i = 0;i<32;i++){
                    offset = float2(sin(a),cos(a))*_Blur;
                    offset*=frac(sin(i)*524.895);
                    col+=tex2D(_MainTex,uv+offset);
                    a++;
                }
                col/=32;
                return col;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                parameterScale();
                float2 iuv = float2(i.uv.y,-i.uv.x);
                float4 rainDrop1 = rain_drop(iuv,1);
                float4 rainDrop2 = rain_drop(iuv,_level2);
                float4 rainDrop3 = rain_drop(iuv,_level3);
                float4 rain_static_drop = rain_static(iuv);

                float2 screen_uv = i.uv_PS.xy/i.uv_PS.w;
                // float2 uv_distor1 = screen_uv+rainDrop1.xy*rainDrop1.z*_drop_uv_disturb;
                // float2 uv_distor2 = screen_uv+rainDrop2.xy*rainDrop2.z*_drop_uv_disturb;
                // float2 uv_distor3 = screen_uv+rainDrop1.xy*rainDrop1.z*_drop_uv_disturb;

                float2 uv =(screen_uv+rainDrop1.xy*rainDrop1.z*_drop_uv_disturb)
                            +(rainDrop2.xy*rainDrop2.z*_drop_uv_disturb)
                            +(rainDrop3.xy*rainDrop3.z*_drop_uv_disturb)
                            +(rain_static_drop.xy*rain_static_drop.z*_drop_uv_disturb);
                // float2 uv = screen_uv+rain_static_drop.xy*rain_static_drop.z*_drop_uv_disturb;
                // uv.y = 1-uv.y;
                float track_mask = rainDrop1.z+rainDrop1.w+rainDrop2.z+rainDrop2.w+rainDrop3.z+rainDrop3.w+rain_static_drop.z;
                // float track_mask = rain_static_drop.z;
                float4 mian_tex = tex2D(_MainTex,uv);

                float4 blur_tex = grainBlur(screen_uv,Random2D(uv));
                float4 final_col = blur_tex*(1-track_mask)+track_mask*mian_tex;
                return float4(final_col);
                // return float4(drop+small_drop*small_drop_mask,drop_trace_mask,0,1);
            }
            ENDCG
        }
    }
}
