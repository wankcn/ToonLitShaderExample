Shader "Toon"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _SSSMap ("SSS Map", 2D) = "black" {}
        _ILMMap ("ILM Map", 2D) = "gray" {}

        _ToonThreshold ("ToonThreshold", Range(0,1)) = 0.5 // 阈值范围
        _ToonHardness ("ToonHardness",Float) = 20.0 // 过渡的生硬情况
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 pos_world : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float4 vertex_color : TEXCOORD3;
            };

            sampler2D _BaseMap;
            sampler2D _SSSMap;
            sampler2D _ILMMap;
            float _ToonThreshold;
            float _ToonHardness;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.uv = float4(v.texcoord0, v.texcoord1);
                o.vertex_color = v.color;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half2 uv1 = i.uv.xy;
                half2 uv2 = i.uv.zw;

                float3 normalDir = normalize(i.normal_world); // 单位向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // 光照方向

                // Base贴图
                half4 base_map = tex2D(_BaseMap, uv1);
                half3 base_color = base_map.rgb; // 亮区颜色

                // sss贴图
                half4 sss_map = tex2D(_SSSMap, uv1);
                half3 sss_color = sss_map.rgb; // 暗部颜色

                // ILM贴图
                half4 ilm_map = tex2D(_ILMMap, uv1);
                float spec_intensity = ilm_map.r; // r通道用来控制高光的强度
                float diffuse_control = ilm_map.g * 2.0 - 1.0; // g通道用来控制光照偏移，从0-1转换成-1~1
                float spec_size = ilm_map.b; // b通道用来控制高光的大小
                float inner_line = ilm_map.a; // alpha通道用来控制内描线

                // 顶点色
                float ao = i.vertex_color.r;

                // light
                half NdotL = dot(normalDir, lightDir); // 结果在（-1~1）
                half half_lambert = (NdotL + 1.0) * 0.5; // 缩放到0-1之间
                half lambert_term = half_lambert * ao + diffuse_control; // 做一个偏移控制
                // half toon_diffuse = step(0.0, half_lambert); // 色阶化

                // 偏移光照位置
                half toon_diffuse = saturate((lambert_term - _ToonThreshold) * _ToonHardness);
                // toon_diffuse = saturate(toon_diffuse + 0.5); // 提亮光照 原来的0.5倍
                // half3 final_diffuse = toon_diffuse * base_color; // 颜色*base图片的灰度值
                half3 final_diffuse = lerp(sss_color, base_color, toon_diffuse);

                return float4(final_diffuse, 1.0);
            }
            ENDCG
        }
    }
}