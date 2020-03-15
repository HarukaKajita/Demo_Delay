Shader "Unlit/Trail"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" { }
    
    [Header(Raymarching)]
    [IntRange]_Iteration ("Marching Iteration", Range(0, 3000)) = 256
    [IntRange]_BinarySearchIteration ("Binary Search Iteration", Range(0, 20)) = 10
    
    [Header(Noise)]
    _Threshold ("Threshold", Range(0, 1)) = 0.5
    [KeywordEnum(Value, Perlin, Cellular, Curl, fbm)]
    _NoiseType ("Noise Type", int) = 0
    _NoiseScale ("Noise Scale", Range(0, 100)) = 10
    [Toggle]_InvertFlag ("Invert Flag", int) = 0
    
    [Header(Lighting)]
    _InnerColor ("Inner Color", color) = (1, 0, 1, 1)
    _RimLightColor ("Rim Light Color", color) = (0, 1, 1, 1)
    _RimLightPower ("Rim Light Power", Range(0, 100)) = 20
    _SpecularPower ("Specular Power", Range(0, 100)) = 30
    [Header(Surface)]
    _NormalCheckThreshold("Noraml Check Threshold", Range(0,1)) = 0.03
  }
  SubShader
  {
    Tags { "RenderType" = "Opaque" }
    Cull Off
    
    Pass
    {
      Tags{"LightMode"="ForwardBase"}
      
      CGPROGRAM
      #pragma exclude_renderers d3d11 gles
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
      #pragma multi_compile_fwdbase_fullshadows
      
      #include "UnityCG.cginc"
      #include "Lighting.cginc"
      #include "AutoLight.cginc"
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
        float4 pos: SV_POSITION;
        float3 wPos : WORLDPOS;
        float2 uv : UV;
        float zlen: ZLEN;
        float3 normal : NORMAL;
        float3 center : CENTER;
        SHADOW_COORDS(0)
      };
      
      struct fout
      {
        fixed4 col: SV_Target;
        float depth: SV_Depth;
      };
      
      sampler2D _MainTex;
      float4 _MainTex_ST;
      
      uint _Iteration; //レイの行進の最大数
      uint _BinarySearchIteration; //二分探索の回数

      float _Threshold;
      int _NoiseType;
      float _NoiseScale;
      bool _InvertFlag;
      
      //Inside of Object
      fixed3 _InnerColor;
      
      //RimLight
      fixed3 _RimLightColor;
      float _RimLightPower;
      
      //Specular
      float _SpecularPower;
      
      //Surface
      float _NormalCheckThreshold;
      
      StructuredBuffer<float3> posBuffer;
      StructuredBuffer<float3> dirBuffer;
      
      float getNoise(float3 pos);
      float getDepth(float3 oPos);
      float distFromCube(float3 pos);
      float3 getDDCrossNormal(float3 wPos);
      float3 binarySearch(float3 currentPos, float3 previousPos, float threshold, uint iteration);
      
      v2g vert(appdata v)
      {
        v2g o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
      }
      
      [maxvertexcount(24)]
      void geom(triangle v2g input[3], uint pid: SV_PRIMITIVEID, inout TriangleStream < g2f > stream)
      {
        uint trailID = pid / TRAIL_BUFF_NODE_NUM;
        uint nodeID = pid % TRAIL_BUFF_NODE_NUM;
        if(trailID >= _TrailNum+1) return;
        #ifdef DELAYPASS
        if(nodeID < DELAY) return;
        #else
        if(nodeID >= TRAIL_NODE_NUM) return;
        #endif
        float3 pos = posBuffer[pid];
        float3 dir = dirBuffer[pid];
        
        float3 zDir = dir;
        float3 yDir = float3(0,1,0);
        float3 xDir = normalize(cross(yDir,zDir));
        
        float len = _Delta/2.0;
        if(nodeID != 0){
            float3 pre = posBuffer[pid-1];
            len = length(pos - pre)/1.0;
        }
        
        float width = WIDTH;
        float3 objCamPos = mul(unity_WorldToObject, _WorldSpaceCameraPos);
        int xface = distance(pos + xDir * width, objCamPos) < distance(pos - xDir * width, objCamPos) ? 1 : -1;  
        int yface = distance(pos + yDir * width, objCamPos) < distance(pos - yDir * width, objCamPos) ? 1 : -1;
        int zface = distance(pos + zDir * width, objCamPos) < distance(pos - zDir * width, objCamPos) ? 1 : -1;
        
        float3 centerPos = pos;
        //上面
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface * x + 
                        yDir * width * yface +
                        zDir * len * zface * y;
          g2f o;
          o.pos = UnityObjectToClipPos(float4(oPos, 1));
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          o.normal = UnityObjectToWorldNormal(normalize(yDir*yface));
          o.center = centerPos;
          o.zlen = len;
          o.uv = float2(x, y)*0.5 + 0.5;
          TRANSFER_SHADOW(o);
          stream.Append(o);
        }
        stream.RestartStrip();
        //左右面
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface +
                        yDir * width * yface * x + 
                        zDir * len * zface * y;
          
          g2f o;
          o.pos = UnityObjectToClipPos(float4(oPos, 1));
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          o.normal = UnityObjectToWorldNormal(normalize(xDir*xface));
          o.center = centerPos;
          o.zlen = len;
          o.uv = float2(x, y)*0.5 + 0.5;
          TRANSFER_SHADOW(o);
          stream.Append(o);
        }
        stream.RestartStrip();
        //前後面
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface * x +
                        yDir * width * yface * y + 
                        zDir * len * zface;
          
          g2f o;
          o.pos = UnityObjectToClipPos(float4(oPos, 1));
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          o.normal = UnityObjectToWorldNormal(normalize(zDir*zface));
          o.center = centerPos;
          o.zlen = len;
          o.uv = float2(x, y)*0.5 + 0.5;
          TRANSFER_SHADOW(o);
          stream.Append(o);
        }
        stream.RestartStrip();
      }
      
      fout frag(g2f i)
      {
        //fout debug;
        //debug.col = float4(i.normal, 1);
        //debug.depth = 1;
        float3 rayDir = normalize(i.wPos - _WorldSpaceCameraPos);
        float3 delta = rayDir * (1.0 / _Iteration);
        float3 currentPos = i.wPos;
        bool isCollided = false;
        uint loopNum = 0;
        float noiseValue = 0;
        float threshold = _Threshold;
        if (_InvertFlag) threshold = 1.0 - threshold;
        for (uint j = 0; j < _Iteration; j ++)
        { 
          noiseValue = getNoise(currentPos);
          isCollided = noiseValue > threshold;
          if(isCollided) break;
          currentPos += delta;
          loopNum ++ ;
        }
        
        if(!isCollided) discard;
        currentPos = binarySearch(currentPos, currentPos - delta, threshold, _BinarySearchIteration);
        fout o;
        UNITY_INITIALIZE_OUTPUT(fout, o);
        float3 collidedWPos = currentPos;
        
        //法線,ライト方向,ビュー方向,ビューの方向の反射方向
        float3 normal = getDDCrossNormal(collidedWPos);
        float3 lightDir = UnityWorldSpaceLightDir(collidedWPos);
        float3 viewDir = UnityWorldSpaceViewDir(collidedWPos);
        float3 reflectDir = normalize(reflect(-viewDir, normal));
        
        //主要な値
        float NdotL = dot(normal, lightDir);
        float NdotV = dot(normal, viewDir);
        float RdotL = dot(reflectDir, lightDir);
        
        //色
        float3 reflectCol = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
        float3 rimLightCol = pow(saturate(1 - NdotV), _RimLightPower) * _RimLightColor;
        float3 specularCol = pow(saturate(RdotL), _SpecularPower) * _LightColor0;
        
        float3 surfaceCol = specularCol + reflectCol + rimLightCol;
        o.col.rgb = (NdotL*0.5+0.5)*_InnerColor + rimLightCol;
        float interpolate = 1;//saturate(length(collidedWPos - i.wPos)*10);
        o.col.rgb = lerp(surfaceCol, o.col.rgb, interpolate);
        //o.col.rgb = surfaceCol;
        //不適切な法線を推定している場合は適当な色で上書きして見栄えを整える
        if(length(normal) == 0) o.col.rgb = _InnerColor;
        
        o.col.rgb = saturate(o.col.rgb);
        o.depth = getDepth(currentPos);
        UNITY_LIGHT_ATTENUATION(atten, i, collidedWPos);
        o.col.rgb *= atten;
        return o;
      }
      
      float3 binarySearch(float3 currentPos, float3 previousPos, float threshold, uint iteration)
      {
        float3 back = previousPos;
        float3 front = currentPos;
        for (uint k = 0; k < iteration; k ++)
        {
          float3 center = 0.5 * (front + back);
          float noiseValue = getNoise(center);
          
          bool isCollided = noiseValue > threshold;
          front = lerp(front, center, isCollided);
          back = lerp(center, back, isCollided);
        }
        return front;
      }
      
      
      float3 getDDCrossNormal(float3 wPos)
      {
        float3 ddxVec = ddx(wPos);
        float3 ddyVec = ddy(wPos);
        float len = length(ddxVec) + length(ddyVec);
        float3 normal = normalize(cross(ddyVec, ddxVec));
        //急激な法線の変化は不適切な法線になるのでエラーとして0を返す
        return len > _NormalCheckThreshold ? float3(0,0,0) : normal;
      }
      
      float getNoise(float3 pos)
      {
        float value = 0;
        float3 noisePos = pos * _NoiseScale;
        if(_NoiseType == 0)
        {
          value = valNoise(noisePos);
        }
        else if(_NoiseType == 1)
        {
          value = pNoise(noisePos);
        }
        else if(_NoiseType == 2)
        {
          value = cNoise(noisePos);
        }
        else if(_NoiseType == 3)
        {
          value = curlNoise(noisePos).r * 0.5 + 0.5;
        }
        else if(_NoiseType == 4)
        {
          value = fbm(noisePos);
        }
        value = lerp(value, 1.0 - value, _InvertFlag);
        return value;
      }
      
      float getDepth(float3 wPos)
      {
        float4 pos = mul(UNITY_MATRIX_VP,float4(wPos, 1.0));
        #if UNITY_UV_STARTS_AT_TOP
          return pos.z / pos.w;
        #else
          return(pos.z / pos.w) * 0.5 + 0.5;
        #endif
      }
      ENDCG
      
    }
    
    Pass
    {
      Tags{"LightMode"="ShadowCaster"}
      ZWrite On ZTest LEqual Cull Off
      
      CGPROGRAM
      #pragma exclude_renderers d3d11 gles
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
      #pragma multi_compile_shadowcasterv
      
      #include "UnityCG.cginc"
      #include "Noise.cginc"
      #include "TrailUtility.cginc"
      #include "MemoryUtility.cginc"
      
      #define DELAYPASS
      
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
        float3 wPos : WORLDPOS;
      };
      
      struct fout{
        float depth : SV_depth;
        float4 col : SV_Target;
      };
      
      sampler2D _MainTex;
      float4 _MainTex_ST;
      
      uint _Iteration; //レイの行進の最大数
      uint _BinarySearchIteration; //二分探索の回数

      float _Threshold;
      int _NoiseType;
      float _NoiseScale;
      bool _InvertFlag;
      
      //Inside of Object
      fixed3 _InnerColor;
      
      //RimLight
      fixed3 _RimLightColor;
      float _RimLightPower;
      
      //Specular
      float _SpecularPower;
      
      //Surface
      float _NormalCheckThreshold;
      
      StructuredBuffer<float3> posBuffer;
      StructuredBuffer<float3> dirBuffer;
      
      float getNoise(float3 pos);
      float getDepth(float3 oPos);
      float distFromCube(float3 pos);
      float3 getDDCrossNormal(float3 wPos);
      float3 binarySearch(float3 currentPos, float3 previousPos, float threshold, uint iteration);
      
      v2g vert(appdata v)
      {
        v2g o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
      }
      
      [maxvertexcount(24)]
      void geom(triangle v2g input[3], uint pid: SV_PRIMITIVEID, inout TriangleStream < g2f > stream)
      {
        uint trailID = pid / TRAIL_BUFF_NODE_NUM;
        uint nodeID = pid % TRAIL_BUFF_NODE_NUM;
        if(trailID >= _TrailNum+1) return;
        #ifdef DELAYPASS
        if(nodeID < DELAY) return;
        #else
        if(nodeID >= TRAIL_NODE_NUM) return;
        #endif
        float3 pos = posBuffer[pid];
        float3 dir = dirBuffer[pid];
        
        float3 zDir = dir;
        float3 yDir = float3(0,1,0);
        float3 xDir = normalize(cross(yDir,zDir));
        
        float len = _Delta/2.0;
        if(nodeID != 0){
            float3 pre = posBuffer[pid-1];
            len = length(pos - pre);
        }
        float width = WIDTH;
        float3 objCamPos = mul(unity_WorldToObject, _WorldSpaceCameraPos);
        int xface = 1;//distance(pos + xDir * width, objCamPos) < distance(pos - xDir * width, objCamPos) ? 1 : -1;  
        int yface = 1;//distance(pos + yDir * width, objCamPos) < distance(pos - yDir * width, objCamPos) ? 1 : -1;
        int zface = 1;//distance(pos + zDir * width, objCamPos) < distance(pos - zDir * width, objCamPos) ? 1 : -1;
        
        float3 centerPos = pos;
        //上面
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface * x + 
                        yDir * width * yface +
                        zDir * len * zface * y;
          float3 normal = normalize(yDir*yface);
          g2f o;
          o.vertex = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(float4(oPos,1), normal));
          o.uv = float2(x, y)*0.5 + 0.5;
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          stream.Append(o);
        }
        stream.RestartStrip();
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface * x + 
                        yDir * width * yface*-1 +
                        zDir * len * zface * y;
          float3 normal = normalize(yDir*yface*-1);
          g2f o;
          o.vertex = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(float4(oPos,1), normal));
          o.uv = float2(x, y)*0.5 + 0.5;
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          stream.Append(o);
        }
        stream.RestartStrip();
        //左右面
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface +
                        yDir * width * yface * x + 
                        zDir * len * zface * y;
          
          float3 normal = normalize(xDir*xface);
          g2f o;
          o.vertex = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(float4(oPos,1), normal));
          o.uv = float2(x, y)*0.5 + 0.5;
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          stream.Append(o);
        }
        stream.RestartStrip();
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface * -1 +
                        yDir * width * yface * x + 
                        zDir * len * zface * y;
          
          float3 normal = normalize(xDir*xface*-1);
          g2f o;
          o.vertex = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(float4(oPos,1), normal));
          o.uv = float2(x, y)*0.5 + 0.5;
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          stream.Append(o);
        }
        stream.RestartStrip();
        //前後面
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface * x +
                        yDir * width * yface * y + 
                        zDir * len * zface;
          
          float3 normal = normalize(zDir*zface);
          g2f o;
          o.vertex = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(float4(oPos,1), normal));
          o.uv = float2(x, y)*0.5 + 0.5;
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          stream.Append(o);
        }
        stream.RestartStrip();
        for (uint i = 0; i < 4; i ++)
        {
          float x = i / 2 == 0 ? - 1: 1;
          float y = i % 2 == 0 ? - 1: 1;
          float3 oPos = centerPos + 
                        xDir * width * xface * x +
                        yDir * width * yface * y + 
                        zDir * len * zface * -1;
          
          float3 normal = normalize(zDir*zface*-1);
          g2f o;
          o.vertex = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(float4(oPos,1), normal));
          o.uv = float2(x, y)*0.5 + 0.5;
          o.wPos = mul(unity_ObjectToWorld, float4(oPos, 1));
          stream.Append(o);
        }
      }
      
      fout frag(g2f i)
      {
        float3 rayDir = normalize(i.wPos - _WorldSpaceCameraPos);
        float3 delta = rayDir * (1.0 / _Iteration);
        float3 currentPos = i.wPos;
        bool isCollided = false;
        uint loopNum = 0;
        float noiseValue = 0;
        float threshold = _Threshold;
        if (_InvertFlag) threshold = 1.0 - threshold;
        for (uint j = 0; j < _Iteration; j ++)
        { 
          noiseValue = getNoise(currentPos);
          isCollided = noiseValue > threshold;
          if(isCollided) break;
          currentPos += delta;
          loopNum ++ ;
        }
        
        if(!isCollided) discard;
        currentPos = binarySearch(currentPos, currentPos - delta, threshold, _BinarySearchIteration);
        float3 collidedWPos = currentPos;
        fout o;
        UNITY_INITIALIZE_OUTPUT(fout, o);
        o.depth = getDepth(currentPos);
        o.col = 0;
        return o;
      }
      
      
      
      float3 binarySearch(float3 currentPos, float3 previousPos, float threshold, uint iteration)
      {
        float3 back = previousPos;
        float3 front = currentPos;
        for (uint k = 0; k < iteration; k ++)
        {
          float3 center = 0.5 * (front + back);
          float noiseValue = getNoise(center);
          
          bool isCollided = noiseValue > threshold;
          front = lerp(front, center, isCollided);
          back = lerp(center, back, isCollided);
        }
        return front;
      }
      
      
      float3 getDDCrossNormal(float3 wPos)
      {
        float3 ddxVec = ddx(wPos);
        float3 ddyVec = ddy(wPos);
        float len = length(ddxVec) + length(ddyVec);
        float3 normal = normalize(cross(ddyVec, ddxVec));
        //急激な法線の変化は不適切な法線になるのでエラーとして0を返す
        return len > _NormalCheckThreshold ? float3(0,0,0) : normal;
      }
      
      float getNoise(float3 pos)
      {
        float value = 0;
        float3 noisePos = pos * _NoiseScale;
        if(_NoiseType == 0)
        {
          value = valNoise(noisePos);
        }
        else if(_NoiseType == 1)
        {
          value = pNoise(noisePos);
        }
        else if(_NoiseType == 2)
        {
          value = cNoise(noisePos);
        }
        else if(_NoiseType == 3)
        {
          value = curlNoise(noisePos).r * 0.5 + 0.5;
        }
        else if(_NoiseType == 4)
        {
          value = fbm(noisePos);
        }
        value = lerp(value, 1.0 - value, _InvertFlag);
        return value;
      }
      
      float getDepth(float3 wPos)
      {
        float4 pos = mul(UNITY_MATRIX_VP,float4(wPos, 1.0));
        #if UNITY_UV_STARTS_AT_TOP
          return pos.z / pos.w;
        #else
          return(pos.z / pos.w) * 0.5 + 0.5;
        #endif
      }
      ENDCG
      
    }
  }
}
