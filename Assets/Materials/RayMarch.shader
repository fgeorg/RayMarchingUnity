// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "RayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            #define MAX_STEPS 50
            #define MAX_DIST 100
            #define SURF_DIST 1e-3
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ro = _WorldSpaceCameraPos;
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                o.hitPos = v.vertex;

                return o;
            }

            float SMinCubic( float a, float b, float k )
            {
                float h = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - h*h*h*k*(1.0/6.0);
            }

            float GetDist(float3 p) {
                float4 s = float4(0.0, 0.0, 0.0, 0.2);
                float dSphere = length(p - s.xyz) - s.w;
                float dTorus = length(float2(length(p.xy) - .4, p.z)) - .1;
                return SMinCubic(dSphere, dTorus, .30 + sin(_Time * 50) * .14);
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(1e-2, 0);
                float3 n = float3(
                GetDist(p + e.xyy),
                GetDist(p + e.yxy),
                GetDist(p + e.yyx)
                ) - GetDist(p);
                return normalize(n);
            }

            float2 RayMarch(float3 ro, float3 rd) {
                float dO = 0;
                int i = 0;
                for (; i < MAX_STEPS; i++) {
                    float3 p = ro + dO * rd;
                    float dS = GetDist(p);
                    if (dS < SURF_DIST || dO > MAX_DIST) break;
                    dO += dS;
                }
                return float2(dO,float(i) / MAX_STEPS);
            }

            float3 GetLighting (float3 pos) {
                float3 lightDir = normalize(float3(-84.3400146, 124.7201937, 92.0409749));
                float3 localLightDir = mul(unity_WorldToObject, float4(lightDir, 0));
                return (dot(GetNormal(pos), localLightDir) + .2)/1.5;
            }

            void frag (v2f i, out float4 color:COLOR, out float depth : DEPTH)
            {
                float objectZ = i.screenPos.z;

                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float2 rm = RayMarch(ro, rd);
                float d = rm.x;
                float4 col = 0;
                col.a = 1;
                if (d > MAX_DIST)  {
                    col.a = 0;
                    discard;
                }
                
                float3 p = ro + d * rd;
                col.rgb = GetLighting(p);
                col.b += rm.y;
                if (col.g < 0) {
                    col.g *= -.1;
                }

                color =  saturate(col);

                float3 objSpacePos = p;

                float4 clipSpacePos = UnityObjectToClipPos(objSpacePos);
                depth = clipSpacePos.z / clipSpacePos.w;

            }
            ENDCG
        }
    }
}
