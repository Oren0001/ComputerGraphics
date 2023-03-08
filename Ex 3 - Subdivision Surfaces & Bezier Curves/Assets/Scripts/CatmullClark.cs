using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;


public class CCMeshData
{
    public List<Vector3> points; // Original mesh points
    public List<Vector4> faces; // Original mesh quad faces
    public List<Vector4> edges; // Original mesh edges
    public List<Vector3> facePoints; // Face points, as described in the Catmull-Clark algorithm
    public List<Vector3> edgePoints; // Edge points, as described in the Catmull-Clark algorithm
    public List<Vector3> newPoints; // New locations of the original mesh points, according to Catmull-Clark
}


public static class CatmullClark
{
    // Returns a QuadMeshData representing the input mesh after one iteration of Catmull-Clark subdivision.
    public static QuadMeshData Subdivide(QuadMeshData quadMeshData)
    {
        // Create and initialize a CCMeshData corresponding to the given QuadMeshData
        CCMeshData meshData = new CCMeshData();
        meshData.points = quadMeshData.vertices;
        meshData.faces = quadMeshData.quads;
        meshData.edges = GetEdges(meshData);
        meshData.facePoints = GetFacePoints(meshData);
        meshData.edgePoints = GetEdgePoints(meshData);
        meshData.newPoints = GetNewPoints(meshData);

        // Combine facePoints, edgePoints and newPoints into a subdivided QuadMeshData

        // Your implementation here...
        // new vetices should include new points, edge points and face points.
        List<Vector3> newVertices = new List<Vector3>(meshData.newPoints);
        newVertices.AddRange(meshData.edgePoints);

        Dictionary<Vector4, int> edgeToIndex = new Dictionary<Vector4, int>(new EdgeComparer());
        for (int i = 0; i < meshData.edges.Count; i++)
        {
            edgeToIndex[meshData.edges[i]] = i;
        }

        // build quads
        int edgeStartIndex = meshData.newPoints.Count;
        int edgeEndIndex = newVertices.Count;
        List<Vector4> newQuads = new List<Vector4>();
        for (int i = 0; i < meshData.faces.Count; i++)
        {
            newVertices.Add(meshData.facePoints[i]);
            Vector4 face = meshData.faces[i];
            int edgePoint1 = edgeStartIndex + edgeToIndex[new Vector4(face.x, face.y, 0, 0)];
            int edgePoint2 = edgeStartIndex + edgeToIndex[new Vector4(face.y, face.z, 0, 0)];
            int edgePoint3 = edgeStartIndex + edgeToIndex[new Vector4(face.z, face.w, 0, 0)];
            int edgePoint4 = edgeStartIndex + edgeToIndex[new Vector4(face.w, face.x, 0, 0)];
            newQuads.Add(new Vector4(edgeEndIndex + i, edgePoint1, face.y, edgePoint2));
            newQuads.Add(new Vector4(edgeEndIndex + i, edgePoint2, face.z, edgePoint3));
            newQuads.Add(new Vector4(edgeEndIndex + i, edgePoint3, face.w, edgePoint4));
            newQuads.Add(new Vector4(edgeEndIndex + i, edgePoint4, face.x, edgePoint1));
        }
        return new QuadMeshData(newVertices, newQuads);
    }

    /* Returns an array where each index of it represents index of a point,
     * and for a given index it contains the faces that are connected to the point.
     */
    public static List<int>[] GetFacesOfPoint(CCMeshData mesh)
    {
        List<int>[] facesOfPoint = new List<int>[mesh.points.Count];
        // For each point we will add the faces that are connected to it.
        for (int i = 0; i < mesh.faces.Count; i++)
        {
            for (int j = 0; j < 4; j++)
            {
                int pointIndex = (int)mesh.faces[i][j];
                if (facesOfPoint[pointIndex] == null)
                {
                    facesOfPoint[pointIndex] = new List<int>();
                }
                facesOfPoint[pointIndex].Add(i);
            }
        }
        return facesOfPoint;
    }

    // Returns a list of all edges in the mesh defined by given points and faces.
    // Each edge is represented by Vector4(p1, p2, f1, f2)
    // p1, p2 are the edge vertices
    // f1, f2 are faces incident to the edge. If the edge belongs to one face only, f2 is -1
    public static List<Vector4> GetEdges(CCMeshData mesh)
    {
        List<int>[] facesOfPoint = GetFacesOfPoint(mesh);
        HashSet<Vector4> edges = new HashSet<Vector4>(new EdgeComparer());
        for (int i = 0; i < mesh.faces.Count; i++)
        {
            Vector4 face1 = mesh.faces[i];
            for (int j = 0; j < 4; j++)
            {
                int p1 = (int)face1[j];
                int p2 = (int)face1[(j + 1) % 4];
                int f2 = -1;
                // Find f2 by going over a constant number of faces.
                foreach (int p1Face in facesOfPoint[p1])
                {
                    if (p1Face == i) continue;
                    Vector4 face2 = mesh.faces[p1Face];
                    if (face2.x == p2 || face2.y == p2 || face2.z == p2 || face2.w == p2)
                    {
                        f2 = p1Face;
                        break;
                    }
                }
                edges.Add(new Vector4(p1, p2, i, f2));
            }
        }
        List<Vector4> res = edges.ToList();
        return res;
    }

    // Returns a list of "face points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetFacePoints(CCMeshData mesh)
    {
        List<Vector3> facePoints = new List<Vector3>();
        for (int i = 0; i < mesh.faces.Count; i++)
        {
            Vector3 p1 = mesh.points[(int)mesh.faces[i].x];
            Vector3 p2 = mesh.points[(int)mesh.faces[i].y];
            Vector3 p3 = mesh.points[(int)mesh.faces[i].z];
            Vector3 p4 = mesh.points[(int)mesh.faces[i].w];
            facePoints.Add((p1 + p2 + p3 + p4) / 4f);
        }
        return facePoints;
    }

    // Returns a list of "edge points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetEdgePoints(CCMeshData mesh)
    {
        List<Vector3> edgePoints = new List<Vector3>();
        for (int i = 0; i < mesh.edges.Count; i++)
        {
            Vector3 point1 = mesh.points[(int)mesh.edges[i].x];
            Vector3 point2 = mesh.points[(int)mesh.edges[i].y];
            Vector3 facePoint1 = mesh.facePoints[(int)mesh.edges[i].z];
            Vector3 facePoint2 = mesh.edges[i].w == -1 ? Vector3.zero : mesh.facePoints[(int)mesh.edges[i].w];
            edgePoints.Add((point1 + point2 + facePoint1 + facePoint2) / 4f);

        }
        return edgePoints;
    }

    // Returns a list of new locations of the original points for the given CCMeshData, as described in the CC algorithm 
    public static List<Vector3> GetNewPoints(CCMeshData mesh)
    {
        List<int>[] facesOfPoint = GetFacesOfPoint(mesh);
        // add for each point the number of edges touching it, which is also the number of faces touching it.
        int[] n = new int[facesOfPoint.Length];
        for (int i = 0; i < facesOfPoint.Length; i++)
        {
            n[i] = facesOfPoint[i].Count;
        }

        // add for each point the average of all n face points touching it.
        Vector3[] f = new Vector3[facesOfPoint.Length];
        for (int i = 0; i < facesOfPoint.Length; i++)
        {
            Vector3 avgFacePoints = Vector3.zero;
            foreach (int faceIndex in facesOfPoint[i])
            {
                avgFacePoints += mesh.facePoints[faceIndex];
            }
            avgFacePoints /= n[i];
            f[i] = avgFacePoints;
        }

        // add for each point the average of all n edge midpoints touching it.
        Vector3[] r = new Vector3[mesh.points.Count];
        for (int i = 0; i < mesh.edges.Count; i++)
        {
            int p1 = (int)mesh.edges[i].x;
            int p2 = (int)mesh.edges[i].y;
            Vector3 midPoint = (mesh.points[p1] + mesh.points[p2]) / 2;
            r[p1] += midPoint;
            r[p2] += midPoint;
        }
        for (int i = 0; i < mesh.points.Count; i++)
        {
            r[i] /= n[i];
        }

        List<Vector3> newPoints = new List<Vector3>();
        for (int i = 0; i < mesh.points.Count; i++)
        {
            newPoints.Add((f[i] + 2 * r[i] + (n[i] - 3) * mesh.points[i]) / n[i]);
        }
        return newPoints;
    }
}

/* Checks if 2 edges equal to each other.
 * Each edge is represented by Vector4(p1, p2, f1, f2), where p1, p2 are 
 * the edge vertices and we ignore f1 and f2 in the comparison.
 */
public class EdgeComparer : EqualityComparer<Vector4>
{
    public override bool Equals(Vector4 v1, Vector4 v2)
    {
        return (v1.x == v2.x && v1.y == v2.y) || (v1.x == v2.y && v1.y == v2.x);
    }
    public override int GetHashCode(Vector4 obj)
    {
        return 0;
    }

}
