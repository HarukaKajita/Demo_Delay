Shader "Unlit/ShadowTest"
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
      
      fixed4 frag(v2f i): SV_Target
      {
        // sample the texture
        fixed4 col = tex2D(_MainTex, i.uv);
        // apply fog
        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }
      ENDCG
      
    }
    // Pass to render object as a shadow caster
    Pass
    {
      Name "ShadowCaster"
      Tags { "LightMode" = "ShadowCaster" }
      
      ZWrite On ZTest LEqual Cull Off
      
      CGPROGRAM
      
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_shadowcaster
      #include "UnityCG.cginc"
      
      struct v2f
      {
        float4 pos: SV_POSITION;
      };
      
      v2f vert(appdata_base v)
      {
        v2f o;
        //バイアス依存で法線方向にオフセット+バイアス依存で深度値を調整?
        o.pos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
        o.pos = UnityApplyLinearShadowBias(o.pos);
        return o;
      }
      
      float4 frag(v2f i): SV_Target
      {
        return 0;
      }
      ENDCG
      
    }
  }
}
