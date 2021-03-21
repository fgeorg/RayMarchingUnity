// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "RayMarchScene"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SMinKValue ("SMinKValue", Range(0,5)) = 0.3
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
            #include "Lighting.cginc" // for _LightColor0

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
            float4x4 _TorusTransform;
            float4x4 _SphereTransform;
            float4x4 _BoxTransform;
            float _SMinKValue;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // everything in world space
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float SMinCubic( float a, float b, float k )
            {
                float h = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - h*h*h*k*(1.0/6.0);
            }

            float GetDistToSphere(float3 p) {
                p = mul(_SphereTransform, float4(p,1));
                return length(p) - 0.6;
            }

            float GetDistToTorus(float3 p) {
                p = mul(_TorusTransform, float4(p,1));
                return length(float2(length(p.xy) - .4, p.z)) - .15;
            }

            float GetDistToBox(float3 p) {
                p = mul(_BoxTransform, float4(p,1));
                float3 q = abs(p) - 0.5;
                return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }

            float GetDist(float3 p) {
                float dSphere = GetDistToSphere(p);
                float dTorus = GetDistToTorus(p);
                float dBox = GetDistToBox(p);
                return SMinCubic(dBox, SMinCubic(dSphere, dTorus, _SMinKValue), _SMinKValue);
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

            float3 GetLighting (float3 p, float3 worldNormal) {
                float3 col;
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                col = nl;// * unity_LightColor[0];
                col += ShadeSH9(half4(worldNormal,1));
                col *= 1 - float3(GetDistToSphere(p), GetDistToTorus(p), GetDistToBox(p));
                return col;
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
                float3 worldNormal = GetNormal(p);
                col.rgb = GetLighting(p, worldNormal);
                col.b += rm.y/2;
                // if (col.g < 0) {
                //     col.g *= -.1;
                // }
                col.rgb += worldNormal * 0.3;

                color =  saturate(col);

                float4 clipSpacePos = UnityWorldToClipPos(p);
                depth = clipSpacePos.z / clipSpacePos.w;

            }
            ENDCG
        }
    }
}
