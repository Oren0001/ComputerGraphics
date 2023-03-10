using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MeshData
{
    public List<Vector3> vertices; // The vertices of the mesh 
    public List<int> triangles; // Indices of vertices that make up the mesh faces
    public Vector3[] normals; // The normals of the mesh, one per vertex

    // Class initializer
    public MeshData()
    {
        vertices = new List<Vector3>();
        triangles = new List<int>();
    }

    // Returns a Unity Mesh of this MeshData that can be rendered
    public Mesh ToUnityMesh()
    {
        Mesh mesh = new Mesh
        {
            vertices = vertices.ToArray(),
            triangles = triangles.ToArray(),
            normals = normals
        };

        return mesh;
    }


    // Calculates surface normals for each vertex, according to face orientation
    public void CalculateNormals()
    {
        // Your implementation
        normals = new Vector3[vertices.Count];
        for (int i = 0; i < triangles.Count; i += 3)
        {
            Vector3 v1 = vertices[triangles[i + 0]];
            Vector3 v2 = vertices[triangles[i + 1]];
            Vector3 v3 = vertices[triangles[i + 2]];
            Vector3 triangleNormal = Vector3.Cross(v1 - v3, v2 - v3).normalized;
            normals[triangles[i + 0]] += triangleNormal;
            normals[triangles[i + 1]] += triangleNormal;
            normals[triangles[i + 2]] += triangleNormal;
        }
        for (int i = 0; i < vertices.Count; i++)
        {
            normals[i] = normals[i].normalized;
        }
    }

    // Edits mesh such that each face has a unique set of 3 vertices
    public void MakeFlatShaded()
    {
        // Your implementation
        bool[] visited = new bool[vertices.Count];
        for (int i=0; i < triangles.Count; i++)
        {
            int vertexIndex = triangles[i];
            if (visited[vertexIndex])
            {
                Vector3 v = vertices[vertexIndex];
                vertices.Add(new Vector3(v.x, v.y, v.z));
                triangles[i] = vertices.Count - 1;
            }
            else
            {
                visited[vertexIndex] = true;
            }
        }
    }
}
