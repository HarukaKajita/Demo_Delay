Shader "Unlit/CSDebug"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" { }
    [Enum(POS, 0, DIR, 1)] _Debug("Debug Color", int) = 0
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
      StructuredBuffer<float3> dirBuffer;
      int _Debug;
      
      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        //xにnode
        //yにtrail
        uint2 coord = uvToCoord(i.uv, uint2(TRAIL_BUFF_NODE_NUM, _TrailNum));
        uint trailID = coord.y;
        uint nodeID = coord.x;
        uint id = trailID * TRAIL_BUFF_NODE_NUM + nodeID;
        float3 ids = float3(nodeID, trailID, 0);
        float3 pos = posBuffer[id];
        float3 dir = dirBuffer[id];
        uint3 maxNum = uint3(TRAIL_BUFF_NODE_NUM, _TrailNum, 1);
        fixed4 col = float4(pos / maxNum , 1);
        if(_Debug == 1)col = float4(dir / maxNum , 1);
        return col;
      }
      ENDCG
      
    }
  }
}
