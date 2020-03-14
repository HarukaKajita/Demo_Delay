#define PARTS_NUM 32

uint getBufferIndex(uint trailID, uint partsID)
{
  return trailID * PARTS_NUM + partsID;
}


float boundStrength(float2 xz, float2 bb)
{
  float2 normalizedCoord = abs(xz / bb);
  float len = length(normalizedCoord) * 1;//
  float2 darken = pow(normalizedCoord, 2);
  float scaler = max(darken.x, darken.y);
  
  return smoothstep(-1, 1, scaler * len);//適当に見やすく
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