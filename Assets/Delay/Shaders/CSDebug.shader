Shader "Unlit/CSDebug"
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
      
      struct v2f
      {
        float2 uv: TEXCOORD0;
        float4 vertex: SV_POSITION;
      };
      
      sampler2D _MainTex;
      float4 _MainTex_ST;
      
      StructuredBuffer<float3> posBuffer;
      uint _TrailNum;
      
      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        uint2 coord = uvToCoord(i.uv, uint2(PARTS_NUM, _TrailNum));
        uint id = coordToID(coord, PARTS_NUM);
        uint trailID = id / PARTS_NUM;
        uint partsID = id % PARTS_NUM;
        float3 pos = posBuffer[id];
        uint3 maxNum = uint3(_TrailNum, PARTS_NUM, 1);
        fixed4 col = float4(pos / maxNum , 1);
        if(partsID == 0) return 1;
        return col;
      }
      ENDCG
      
    }
  }
}
