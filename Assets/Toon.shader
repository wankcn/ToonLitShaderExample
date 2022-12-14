Shader "Toon"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _SSSMap ("SSS Map", 2D) = "black" {}
        _ILMMap ("ILM Map", 2D) = "gray" {}
        _DetailMap ("Detail Map", 2D) = "white" {}

        _ToonThreshold ("ToonThreshold", Range(0,1)) = 0.5 // 阈值范围
        _ToonHardness ("ToonHardness",Float) = 20.0 // 过渡的生硬情况
        _SpecSize ("Spec Size",Range(0,1)) = 0.1 // 高光系数
        _SpecColor ("Spec Color",Color) = (1,1,1,1) // 高光颜色
        _OutlineWidth ("OutLine Width",Range(0,10)) = 5.0 // 外轮廓宽度
        _OutlineColor ("Outline Color",Color) = (1,1,1,1) // 轮廓颜色
    }
    SubShader
    {
        Tags
        {
            "LightMode"="ForwardBase"
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
            sampler2D _DetailMap;
            float _ToonThreshold;
            float _ToonHardness;
            float _SpecSize;
            float4 _SpecColor;

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
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.pos_world.xyz); // 视觉方向

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

                // 漫反射效果
                half NdotL = dot(normalDir, lightDir); // 结果在（-1~1）
                half half_lambert = (NdotL + 1.0) * 0.5; // 缩放到0-1之间
                half lambert_term = half_lambert * ao + diffuse_control; // 做一个偏移控制
                // half toon_diffuse = step(0.0, half_lambert); // 色阶化
                // 偏移光照位置
                half toon_diffuse = saturate((lambert_term - _ToonThreshold) * _ToonHardness);
                // toon_diffuse = saturate(toon_diffuse + 0.5); // 提亮光照 原来的0.5倍
                // half3 final_diffuse = toon_diffuse * base_color; // 颜色*base图片的灰度值
                half3 final_diffuse = lerp(sss_color, base_color, toon_diffuse);

                // 高光处理
                float NdotV = (dot(normalDir, viewDir) + 1.0) * 0.5; //拿到NdotV并进行数值范围缩放
                float spec_trem = NdotV * ao + diffuse_control; // 光线偏移
                // 当前高光是基于视角的高光 真正高光收到光照方向的影响
                spec_trem = half_lambert * 0.9 + spec_trem * 0.1; // 高光权重分配
                // 限制边缘
                half toon_spec = saturate((spec_trem - (1.0 - spec_size * _SpecSize)) * 500); // 内部数值越大越光滑

                // 自定义的高光颜色与原来的颜色进行混合
                half spec_color = (_SpecColor.xyz + base_color) * 0.5;
                half3 final_spec = toon_spec * spec_color * spec_intensity;

                // 描线效果
                half3 inner_line_color = lerp(base_color * 0.2, float3(1.0, 1.0, 1.0), inner_line);
                half3 detail_color = tex2D(_DetailMap, uv2); // 采样detail map 使用第二套uv
                detail_color = lerp(base_color * 0.2, float3(1.0, 1.0, 1.0), detail_color);
                half3 final_line = inner_line_color * inner_line_color * detail_color;
                half3 final_color = (final_diffuse + final_spec) * final_line;
                // 色彩校正
                final_color = sqrt(max(exp2(log2(max(final_color, 0.0)) * 2.2), 0.0));
                return float4(final_color, 1.0);
            }
            ENDCG
        }

        Pass
        {
            Cull Front
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
                float3 normal : NORMAL;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertex_color : TEXCOORD1;
            };

            sampler2D _BaseMap;
            sampler2D _SSSMap;
            sampler2D _ILMMap;
            float _OutlineWidth;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;
                float3 pos_view = UnityObjectToViewPos(v.vertex);
                // 观察空间下的normal方向
                float3 normal_world = UnityObjectToWorldNormal(v.normal);
                float3 outline_dir = mul((float3x3)UNITY_MATRIX_V, normal_world);
                pos_view += outline_dir * _OutlineWidth * 0.001;
                o.pos = mul(UNITY_MATRIX_P, float4(pos_view, 1.0));
                o.uv = v.texcoord0;
                o.vertex_color = v.color;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // 根据给定颜色降低对比度，降低饱和度，使得颜色偏暗
                float3 baseColor = tex2D(_BaseMap, i.uv.xy).xyz;
                half maxComponent = max(max(baseColor.r, baseColor.g), baseColor.b) - 0.004;
                half3 saturatedColor = step(maxComponent.rrr, baseColor) * baseColor;
                saturatedColor = lerp(baseColor.rgb, saturatedColor, 0.6);
                half3 outlineColor = 0.8 * saturatedColor * baseColor * _OutlineColor.xyz;
                return float4(outlineColor, 1.0);
            }
            ENDCG
        }
    }
}