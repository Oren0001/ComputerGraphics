using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class BezierMesh : MonoBehaviour
{
    private BezierCurve curve; // The Bezier curve around which to build the mesh

    public float Radius = 0.5f; // The distance of mesh vertices from the curve
    public int NumSteps = 16; // Number of points along the curve to sample
    public int NumSides = 8; // Number of vertices created at each point

    // Awake is called when the script instance is being loaded
    public void Awake()
    {
        curve = GetComponent<BezierCurve>();
        BuildMesh();
    }

    // Returns a "tube" Mesh built around the given Bézier curve
    public static Mesh GetBezierMesh(BezierCurve curve, float radius, int numSteps, int numSides)
    {
        QuadMeshData meshData = new QuadMeshData();
        // Your implementation here...
        for (int i = 0; i <= numSteps; i++)
        {
            float t = i / (float)numSteps;
            Vector3 binormal = curve.GetBinormal(t);
            Vector3 normal = curve.GetNormal(t);
            Vector3 si = curve.GetPoint(t);
            for (int j = 0; j < numSides; j++)
            {
                // add numSides vertices evenly spaced on a circle centered on si.
                Vector2 circlePoint = GetUnitCirclePoint(360f / numSides * j);
                Vector3 sideOpposite = circlePoint.x * radius * normal;
                Vector3 sideAdjacent = circlePoint.y * radius * binormal;
                meshData.vertices.Add(si + sideOpposite + sideAdjacent);
                // add numSides quads connecting the current sample point's vertices with the next.
                if (i < numSteps)
                {
                    int index1 = numSides * i + j;
                    int index2 = numSides * i + (j + 1) % numSides;
                    int index3 = numSides * (i + 1) + (j + 1) % numSides;
                    int index4 = numSides * (i + 1) + j;
                    meshData.quads.Add(new Vector4(index1, index2, index3, index4));
                }
            }
        }
        return meshData.ToUnityMesh();
    }

    // Returns 2D coordinates of a point on the unit circle at a given angle from the x-axis
    private static Vector2 GetUnitCirclePoint(float degrees)
    {
        float radians = degrees * Mathf.Deg2Rad;
        return new Vector2(Mathf.Sin(radians), Mathf.Cos(radians));
    }

    public void BuildMesh()
    {
        var meshFilter = GetComponent<MeshFilter>();
        meshFilter.mesh = GetBezierMesh(curve, Radius, NumSteps, NumSides);
    }

    // Rebuild mesh when BezierCurve component is changed
    public void CurveUpdated()
    {
        BuildMesh();
    }
}



[CustomEditor(typeof(BezierMesh))]
class BezierMeshEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        if (GUILayout.Button("Update Mesh"))
        {
            var bezierMesh = target as BezierMesh;
            bezierMesh.BuildMesh();
        }
    }
}
