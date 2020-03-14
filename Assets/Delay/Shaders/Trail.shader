Shader "Unlit/Trail"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" { }
  }
  SubShader
  {
    Tags { "RenderType" = "Opaque" }
    Cull Off
    
    Pass
    {
      CGPROGRAM
      
      #pragma exclude_renderers d3d11 gles
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
      
      #include "UnityCG.cginc"
      #include "Noise.cginc"
      #include "TrailUtility.cginc"
      #include "MemoryUtility.cginc"
      
      struct appdata
      {
        float4 vertex: POSITION;
        float2 uv: TEXCOORD0;
      };
      
      struct v2g
      {
        float4 vertex: SV_POSITION;
        float2 uv: TEXCOORD0;
      };
      
      struct g2f
      {
        float4 vertex: SV_POSITION;
        float2 uv : UV;
        uint2 id: ID;
      };
      
      sampler2D _MainTex;
      float4 _MainTex_ST;
      
      StructuredBuffer<float3> posBuffer;
      uint _TrailNum;
      
      v2g vert(appdata v)
      {
        v2g o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
      }
      
      [maxvertexcount(100)]
      void geom(triangle v2g input[3], uint pid: SV_PRIMITIVEID, inout TriangleStream < g2f > stream)
      {
        uint totalPrimNum = PARTS_NUM * _TrailNum;
        if(totalPrimNum <= pid) return;
        uint trailID = pid / PARTS_NUM;
        uint partsID = pid % PARTS_NUM;
        uint2 ids = uint2(trailID, partsID);
        float3 pos = posBuffer[pid];
        //pos.y += trailID;
        float3 voPos = UnityObjectToViewPos(pos);
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 0.5: 0.5;
          float y = i % 2 == 0 ? - 0.5: 0.5;
          float3 vPos = voPos + float3(x, y, 0) * 0.05;
          g2f o;
          o.vertex = mul(UNITY_MATRIX_P, float4(vPos, 1));
          o.uv = float2(x, y)+0.5;
          o.id = ids;
          stream.Append(o);
        }
      }
      
      fixed4 frag(g2f i): SV_Target
      {
        uint2 maxNum = uint2(_TrailNum, PARTS_NUM);
        fixed4 col = float4((float2)i.id / maxNum, 0, 1);
        //if(i.id.x == 2) col = 0;
        
        // fixed4 col = rand(id);
        // col.rg = i.uv;
        // col.b = 0;
        return col;
      }
      ENDCG
      
    }
  }
}
