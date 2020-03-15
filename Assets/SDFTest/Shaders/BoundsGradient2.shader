Shader "Unlit/BoundsGradient2"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" { }
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
      // make fog work
      #pragma multi_compile_fog
      
      #include "UnityCG.cginc"
      
      struct appdata
      {
        float4 vertex: POSITION;
        float2 uv: TEXCOORD0;
      };
      
      struct v2f
      {
        float2 uv: TEXCOORD0;
        UNITY_FOG_COORDS(1)
        float4 vertex: SV_POSITION;
      };
      
      sampler2D _MainTex;
      float4 _MainTex_ST;
      
      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        UNITY_TRANSFER_FOG(o, o.vertex);
        return o;
      }
      
      float boundStrength(float2 xz, float2 bb)
      {
        float2 normalizedCoord = abs(xz / bb);
        float len = length(normalizedCoord) * 1;//
        // return 1- len;
        float2 darken = pow(normalizedCoord, 100);
        float scaler = max(darken.x, darken.y);
        
        return smoothstep(0, 0.4, scaler * len);//適当に見やすく
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        i.uv -= 0.5;
        i.uv *= 40;//-20 to +20
        float2 bb = float2(16, 9);
        fixed4 col = boundStrength(i.uv, bb);
        //col = 0;
        //col.rg = pow(abs(i.uv/bb), 2);
        return col;
      }
      ENDCG
      
    }
  }
}
