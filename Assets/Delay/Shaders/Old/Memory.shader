Shader "Unlit/Memory"
{
  Properties
  {
    _SelfTex ("Self Texture", 2D) = "white" { }
    _Scale ("Scale",Range(0.001,2))=0.5
  }
  SubShader
  {
    Tags { "RenderType" = "Opaque" }
    LOD 100
    
    Pass
    {
      CGPROGRAM
      
      #pragma vertex vert
      #pragma fragment frag
      
      #include "UnityCG.cginc"
      #include "Noise.cginc"
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
      
      sampler2D _SelfTex;
      float4 _SelfTex_TexelSize;
      #define MEMORY_SIZE _SelfTex_TexelSize.zw

      float _Scale;
      
      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        return o;
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        
        uint pixId = uvToID(i.uv, MEMORY_SIZE);
        uint id = pixId / 3;//RGBなので
        uint compId = pixId % 3;//0:x,1:y,2:z
        uint detailId = id / 10;
        uint partId = id % 10;
        float2 uv = idToUV(id, _SelfTex_TexelSize);
        float range = 30;
        /////init
        if (_Time.y < 0.1)
        return extractCompCol(rand3D(id)*range - range/2.0, compId);
        //////
        
        float3 prePos = GETPOS(id, _SelfTex);
        float3 pos = prePos + normalize((pNoise3D(prePos*_Scale + 1000) - 0.5))*0.1;
        if(length(pos) > 10 || length(prePos - pos) < 0.01) pos = rand3D(id + _Time.x)*range - range/2.0;
        float4 col = extractCompCol(pos, compId);
        return col;
      }
      ENDCG
    }
  }
}
