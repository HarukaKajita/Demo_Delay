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
    private int kernelID_Update;
    private ComputeBuffer posBuffer;
    public ComputeBuffer PosBuffer => posBuffer;
    private ComputeBuffer dirBuffer;
    public ComputeBuffer DirBuffer => dirBuffer;

    private int id_posBuffer;
    private int id_dirBuffer;
    private int id_time;
    private int id_trailNum;
    private int id_delta;
    
    [SerializeField] int trailNum = 20;
    [Range(0.1f, 0.5f)]
    public float delta = 0.05f;
    private const int TrailNodeNum = 20;//must equal trail.compute
    private const float DelayNodeDiff = 10;

    [SerializeField] private List<Material> renderingMats;
    
    void Start()
    {
        int trailBuffNodeNum = TrailNodeNum + (int)DelayNodeDiff; 
        int totalNodeNum = trailNum * trailBuffNodeNum;
        kernelID_Update = trailCs.FindKernel("Update");
        id_posBuffer = Shader.PropertyToID("posBuffer");
        id_dirBuffer = Shader.PropertyToID("dirBuffer");
        id_time = Shader.PropertyToID("T");
        id_trailNum = Shader.PropertyToID("_TrailNum");
        id_delta = Shader.PropertyToID("_Delta");
        
        posBuffer = new ComputeBuffer(totalNodeNum, Marshal.SizeOf(typeof(Vector3)));
        posBuffer.SetData(Enumerable.Repeat(Vector3.zero, totalNodeNum).ToArray());
        
        dirBuffer = new ComputeBuffer(totalNodeNum, Marshal.SizeOf(typeof(Vector3)));
        dirBuffer.SetData(Enumerable.Repeat(Vector3.zero, totalNodeNum).ToArray());
        
        
        trailCs.SetFloat(id_time, 0);
        trailCs.SetFloat(id_delta, delta);
        trailCs.SetBuffer(trailCs.FindKernel("Init"), id_posBuffer, posBuffer);
        trailCs.SetBuffer(trailCs.FindKernel("Init"), id_dirBuffer, dirBuffer);
        trailCs.Dispatch(trailCs.FindKernel("Init"), trailNum, 1,1);
        
        renderingMats.ForEach(m => {
            m.SetBuffer(id_posBuffer, posBuffer);
            m.SetBuffer(id_dirBuffer, dirBuffer);
            m.SetInt(id_trailNum, trailNum);
        });
    }

    void FixedUpdate()
    {
        trailCs.SetFloat(id_time, Time.timeSinceLevelLoad);
        trailCs.SetFloat(id_delta, delta);
        trailCs.SetBuffer(kernelID_Update, id_posBuffer, posBuffer);
        trailCs.SetBuffer(kernelID_Update, id_dirBuffer, dirBuffer);
        trailCs.Dispatch(kernelID_Update, trailNum, 1,1);
        
        renderingMats.ForEach(m => {
            m.SetBuffer(id_posBuffer, posBuffer);
            m.SetBuffer(id_dirBuffer, dirBuffer);
            m.SetInt(id_trailNum, trailNum);
            m.SetFloat(id_delta, delta);
        });
    }

    private void OnDestroy()
    {
        posBuffer.Release();
        dirBuffer.Release();
    }
}
