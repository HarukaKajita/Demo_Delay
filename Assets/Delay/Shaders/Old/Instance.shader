Shader "Unlit/Instance"
{
    Properties
    {
        _MemoryTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "MemoryUtility.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MemoryTex;
            float4 _MemoryTex_TexelSize;
            #define MEMORY_SIZE _MemoryTex_TexelSize.zw

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                return o;
            }

            [maxvertexcount(100)]
            void geom(triangle v2g input[3], uint pid:SV_PRIMITIVEID, inout TriangleStream<g2f> stream){
                float3 pos = GETPOS(pid, _MemoryTex);
                float3 voPos = UnityObjectToViewPos(pos);
                for(uint i = 0; i < 4; i++){
                    float x = i/2 == 0 ? -0.5 : 0.5;
                    float y = i%2 == 0 ? -0.5 : 0.5;
                    float3 vPos = voPos + float3(x,y,0)*0.1;
                    g2f o;
                    o.vertex = mul(UNITY_MATRIX_P, float4(vPos,1));
                    o.uv = float2(x,y);
                    stream.Append(o);
                }
            }

            fixed4 frag (g2f i) : SV_Target
            {
                if(length(i.uv) > 0.5) discard;
                fixed4 col = 1;
                return col;
            }
            ENDCG
        }
    }
}
