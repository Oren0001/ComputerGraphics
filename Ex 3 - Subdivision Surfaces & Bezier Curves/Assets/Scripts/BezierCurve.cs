using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;


public class BezierCurve : MonoBehaviour
{
    // Bezier control points
    public Vector3 p0;
    public Vector3 p1;
    public Vector3 p2;
    public Vector3 p3;

    private float[] cumLengths; // Cumulative lengths lookup table
    private readonly int numSteps = 128; // Number of points to sample for the cumLengths LUT

    // Returns position B(t) on the Bezier curve for given parameter 0 <= t <= 1
    public Vector3 GetPoint(float t)
    {
        float p0Coefficient = Mathf.Pow(1 - t, 3);
        float p1Coefficient = 3 * Mathf.Pow(1 - t, 2) * t;
        float p2Coefficient = 3 * (1 - t) * Mathf.Pow(t, 2);
        float p3Coefficient = Mathf.Pow(t, 3);
        return p0Coefficient * p0 + p1Coefficient * p1 + p2Coefficient * p2 + p3Coefficient * p3;
    }

    // Returns first derivative B'(t) for given parameter 0 <= t <= 1
    public Vector3 GetFirstDerivative(float t)
    {
        Vector3 t2Coefficient = -3 * p0 + 9 * p1 - 9 * p2 + 3 * p3;
        Vector3 tCoefficient = 6 * p0 - 12 * p1 + 6 * p2;
        Vector3 freeTerm = -3 * p0 + 3 * p1;
        return t2Coefficient * Mathf.Pow(t, 2) + tCoefficient * t + freeTerm;
    }

    // Returns second derivative B''(t) for given parameter 0 <= t <= 1
    public Vector3 GetSecondDerivative(float t)
    {
        Vector3 tCoefficient = -6 * p0 + 18 * p1 - 18 * p2 + 6 * p3;
        Vector3 freeTerm = 6 * p0 - 12 * p1 + 6 * p2;
        return tCoefficient * t + freeTerm;
    }

    // Returns the tangent vector to the curve at point B(t) for a given 0 <= t <= 1
    public Vector3 GetTangent(float t)
    {
        return GetFirstDerivative(t).normalized;
    }

    // Returns the Frenet normal to the curve at point B(t) for a given 0 <= t <= 1
    public Vector3 GetNormal(float t)
    {
        return Vector3.Cross(GetTangent(t), GetBinormal(t)).normalized;
    }

    // Returns the Frenet binormal to the curve at point B(t) for a given 0 <= t <= 1
    public Vector3 GetBinormal(float t)
    {
        Vector3 tangent = GetTangent(t);
        Vector3 nearbyPoint = GetFirstDerivative(t) + GetSecondDerivative(t);
        return Vector3.Cross(tangent, nearbyPoint.normalized).normalized;
    }

    // Calculates the arc-lengths lookup table
    public void CalcCumLengths()
    {
        cumLengths = new float[numSteps + 1];
        cumLengths[0] = 0;
        Vector3 currentSample, previousSample;
        for (int i = 1; i <= numSteps; i++)
        {
            currentSample = GetPoint(i / (float)numSteps);
            previousSample = GetPoint((i - 1) / (float)numSteps);
            cumLengths[i] = cumLengths[i - 1] + (currentSample - previousSample).magnitude;
        }
    }

    // Returns the total arc-length of the Bezier curve
    public float ArcLength()
    {
        return cumLengths[numSteps];
    }

    // Returns approximate t s.t. the arc-length to B(t) = arcLength
    public float ArcLengthToT(float a)
    {
        int index = 0;
        for (int i = 0; i < cumLengths.Length - 1; i++)
        {
            if (cumLengths[i] <= a && a <= cumLengths[i + 1] )
            {
                index = i;
                break;
            }
        }
        float curInterpolation = Mathf.InverseLerp(cumLengths[index], cumLengths[index + 1], a);
        return Mathf.Lerp(index / (float)numSteps, (index + 1) / (float)numSteps, curInterpolation);
    }

    // Start is called before the first frame update
    public void Start()
    {
        Refresh();
    }

    // Update the curve and send a message to other components on the GameObject
    public void Refresh()
    {
        CalcCumLengths();
        if (Application.isPlaying)
        {
            SendMessage("CurveUpdated", SendMessageOptions.DontRequireReceiver);
        }
    }

    // Set default values in editor
    public void Reset()
    {
        p0 = new Vector3(1f, 0f, 1f);
        p1 = new Vector3(1f, 0f, -1f);
        p2 = new Vector3(-1f, 0f, -1f);
        p3 = new Vector3(-1f, 0f, 1f);
        Refresh();
    }
}



