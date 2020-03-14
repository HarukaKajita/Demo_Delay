inline uint2 idToCoord(uint id, uint texWidth);
inline float2 coordToUV(uint2 coord, float2 texelSize);
inline float2 idToUV(uint id, float3 texelSize);
inline uint2 uvToCoord(float2 uv, uint2 textureSize);
inline uint uvToID(float2 uv, uint2 textureSize);
inline float unpackFloat(fixed4 col);
inline float3 getPos(uint id);
inline fixed4 pack(float value);
inline fixed4 extractCompCol(float3 pos, uint compId);

inline uint2 idToCoord(uint id, uint texWidth)
{
  uint x = id % texWidth;
  uint y = id / texWidth;
  return uint2(x, y);
}

inline float2 coordToUV(uint2 coord, float2 texelSize)
{
  return coord * texelSize.xy + texelSize.xy / 2.0;
}

inline float2 idToUV(uint id, float3 texelSize)
{
  return idToCoord(id, texelSize.z) * texelSize.xy + texelSize.xy / 2.0;
}

inline uint2 uvToCoord(float2 uv, uint2 textureSize)
{
  return uv * textureSize;
}

inline uint uvToID(float2 uv, uint2 textureSize)
{
  uint2 coord = uvToCoord(uv, textureSize.xy);
  return coord.y * textureSize.x + coord.x;
}

float unpackFloat(fixed4 col)
{
  uint R = uint(col.r * 255) << 0;
  uint G = uint(col.g * 255) << 8;
  uint B = uint(col.b * 255) << 16;
  uint A = uint(col.a * 255) << 24;
  return asfloat(R | G | B | A);
}

#define GETPOS(id, memTex)\
  float3(\
    unpackFloat(tex2Dlod(memTex, float4(idToUV(id * 3, memTex##_TexelSize.xyz), 0, 0))),\
    unpackFloat(tex2Dlod(memTex, float4(idToUV(id * 3 + 1, memTex##_TexelSize.xyz), 0, 0))),\
    unpackFloat(tex2Dlod(memTex, float4(idToUV(id * 3 + 2, memTex##_TexelSize.xyz), 0, 0)))\
  )

//original function
// inline float3 getPos(uint id)
// {
//   float3 pos = 0;
//   float2 uv = idToUV(id * 3, _SelfTex_TexelSize.xyz);
//   pos.x = unpackFloat(tex2Dlod(_SelfTex, float4(uv, 0, 0)));
//   uv = idToUV(id * 3 + 1, _SelfTex_TexelSize.xyz);
//   pos.y = unpackFloat(tex2Dlod(_SelfTex, float4(uv, 0, 0)));
//   uv = idToUV(id * 3 + 2, _SelfTex_TexelSize.xyz);
//   pos.z = unpackFloat(tex2Dlod(_SelfTex, float4(uv, 0, 0)));
//   return pos;
// }

inline fixed4 pack(float value)
{
  uint uintVal = asuint(value);
  uint4 elements = uint4(uintVal >> 0, uintVal >> 8, uintVal >> 16, uintVal >> 24);
  fixed4 color = ((elements & 0x000000FF) + 0.5) / 255.0;
  return color;
}

inline fixed4 extractCompCol(float3 pos, uint compId)
{
  float v = compId == 0 ? pos.x: (compId == 1 ? pos.y: pos.z);
  return pack(v);
}