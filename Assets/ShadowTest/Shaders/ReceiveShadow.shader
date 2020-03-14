Shader "Unlit/ReceiveShadow"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" { }
  }
  SubShader
  {
    Tags { "RenderType" = "Opaque" }
    
    Pass
    {
      Tags { "LightMode" = "ForwardBase" }
      CGPROGRAM
      
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fwdbase_fullshadows
      
      #include "UnityCG.cginc"
      #include "AutoLight.cginc"
      
      struct appdata
      {
        float4 vertex: POSITION;
        float2 uv: TEXCOORD0;
        float2 uv1: TEXCOORD1;
      };
      
      struct v2f
      {
        float2 uv: TEXCOORD0;
        float4 pos: SV_POSITION;
        float3 worldPos: WORLDPOS;
        //UNITY_LIGHTING_COORDS(3, 4)
        SHADOW_COORDS(3)
      };
      
      sampler2D _MainTex;
      
      v2f vert(appdata v)
      {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        UNITY_TRANSFER_LIGHTING(o, v.uv);
        //TRANSFER_SHADOW(o);
        return o;
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        fixed4 col = tex2D(_MainTex, i.uv);
        UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
        col *= atten;
        return col;
      }
      ENDCG
      
    }
    
    Pass
    {
      Tags { "LightMode" = "ForwardAdd" }
      Blend One One
      CGPROGRAM
      
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fwdadd_fullshadows
      
      #include "UnityCG.cginc"
      #include "AutoLight.cginc"
      
      struct appdata
      {
        float4 vertex: POSITION;
        float2 uv: TEXCOORD0;
        float2 uv1: TEXCOORD1;
      };
      
      struct v2f
      {
        float2 uv: TEXCOORD0;
        float4 pos: SV_POSITION;
        float3 worldPos: WORLDPOS;
        UNITY_LIGHTING_COORDS(3, 4)
        //SHADOW_COORDS(3)
      };
      
      sampler2D _MainTex;
      
      v2f vert(appdata v)
      {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        UNITY_TRANSFER_LIGHTING(o, v.uv);
        //TRANSFER_SHADOW(o);
        return o;
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        fixed4 col = tex2D(_MainTex, i.uv);
        UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
        col *= atten;
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
        //V2F_SHADOW_CASTER;
        float4 pos: SV_POSITION;
      };
      
      v2f vert(appdata_base v)
      {
        v2f o;
        //TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
        //バイアス依存で法線方向にオフセット+バイアス依存で深度値を調整?
        o.pos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
        o.pos = UnityApplyLinearShadowBias(o.pos);
        return o;
      }
      
      float4 frag(v2f i): SV_Target
      {
        //SHADOW_CASTER_FRAGMENT(i)
        return 0;
      }
      ENDCG
      
    }
  }
}
