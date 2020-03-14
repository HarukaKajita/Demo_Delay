Shader "Unlit/BoundsGradient1"
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
        //return normalize(xz);
        float2 fold = abs(xz);
        float2 diff = fold - bb;
        float d = length(max(diff, 0));
        d = d == 0 ? abs(max(diff.x, diff.y)): 0;
        const float c = 1.0;
        return smoothstep(1,0, pow(d / c, 1));//適当に見やすく
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        i.uv -= 0.5;
        i.uv *= 20;
        float2 bb = float2(16,9)/2.0;
        fixed4 col = boundStrength(i.uv, bb);
        return col;
      }
      ENDCG
      
    }
  }
}
