using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using UnityEngine;

//never useed 避け
#pragma warning disable CS0649
public class TrailDispatch : MonoBehaviour
{
    [SerializeField] ComputeShader trailCs;
    private int kernelID_UpdatePos;
    private ComputeBuffer posBuffer;
    public ComputeBuffer PosBuffer => posBuffer;
    
    private int id_posBuffer;
    private int id_time;
    private int id_trailNum;
    private int trailNum = 100;
    private const int partsNum = 32;//must equal trail.compute

    [SerializeField] private List<Material> renderingMats;
    
    void Start()
    {
        int totalPartsNum = trailNum * partsNum;
        kernelID_UpdatePos = trailCs.FindKernel("UpdatePosition");
        id_posBuffer = Shader.PropertyToID("posBuffer");
        id_time = Shader.PropertyToID("_Time");
        id_trailNum = Shader.PropertyToID("_TrailNum");
        posBuffer = new ComputeBuffer(totalPartsNum, Marshal.SizeOf(typeof(Vector3)));
        posBuffer.SetData(Enumerable.Repeat(Vector3.zero, trailNum * partsNum).ToArray());

        trailCs.SetBuffer(trailCs.FindKernel("InitPosition"), id_posBuffer, posBuffer);
        trailCs.Dispatch(trailCs.FindKernel("InitPosition"), trailNum, 1,1);
    }

    void FixedUpdate()
    {
        trailCs.SetFloat(id_time, Time.timeSinceLevelLoad);
        trailCs.SetBuffer(kernelID_UpdatePos, id_posBuffer, posBuffer);
        trailCs.Dispatch(kernelID_UpdatePos, trailNum, 1,1);
        
        renderingMats.ForEach(m => {
            m.SetBuffer(id_posBuffer, posBuffer);
            m.SetInt(id_trailNum, trailNum);
        });
    }

    private void OnDestroy()
    {
        posBuffer.Release();
    }
}
