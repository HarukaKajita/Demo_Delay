#ifndef TRAILUTILITY
#define TRAILUTILITY 
#define TRAIL_NODE_NUM 20
#define DELAY 10
#define TRAIL_BUFF_NODE_NUM (TRAIL_NODE_NUM + DELAY)
#define THREADNUM 30

#define WIDTH 0.2
#include "Noise.cginc"
uint _TrailNum;
float _T;
float _Delta;
uint getBufferIndex(uint trailID, uint nodeID)
{
  return trailID * TRAIL_BUFF_NODE_NUM + nodeID;
}

float2 rot(float2 dir, float amount){
    float s = sin(amount);
    float c = cos(amount);
    float2x2 mat = float2x2(c,-s,s,c);
    return mul(mat, dir);
}

float3 updateDir(float3 pos, float3 dir){
  //float noise = pNoise(pos*10 + _T) - 0.5;
  float noise = curlNoise(pos*0.5 + _T);
  float3 rotStrength = 0.1;//旋回の自由度
  dir.xz = rot(dir.xz, noise * rotStrength);
  return normalize(dir);
}

float3 updatePos(float3 pos, float3 dir){
    return pos + normalize(dir) * _Delta;
}

float boundStrength(float2 xz, float2 bb)
{
  float2 normalizedCoord = abs(xz / bb);
  float len = length(normalizedCoord) * 1;//
  float2 darken = pow(normalizedCoord, 10);
  float scaler = max(darken.x, darken.y);
  
  return smoothstep(0, 1, scaler * len)/10.0;//適当に見やすく
}

float bs(float2 p, float2 bb){
    float2 foldUV = abs(p);
    float2 diff = foldUV - bb;
    float d = length(max(diff, 0));
    if(d > 0) return 1;//d = abs(max(diff.x,diff.y));
    else return 0;
}
float2 boundDirection(float2 xz, float2 bb)
{
  float2 fold = abs(xz);
  if (bb.x > bb.y)
  {
    fold.x *= bb.y / bb.x;
  }
  else
  {
    fold.y *= bb.x / bb.y;
  }
  
  fold -= min(fold.x, fold.y);
  return -normalize(fold) * sign(xz);
}
#endif