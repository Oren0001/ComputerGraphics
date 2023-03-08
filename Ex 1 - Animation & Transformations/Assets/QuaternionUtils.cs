using System;
using System.Collections.Generic;
using UnityEngine;

public class QuaternionUtils
{
    // The default rotation order of Unity. May be used for testing
    public static readonly Vector3Int UNITY_ROTATION_ORDER = new Vector3Int(1, 2, 0);


    // Returns the product of 2 given quaternions
    public static Vector4 Multiply(Vector4 q1, Vector4 q2)
    {
        return new Vector4(
            q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z,
            q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x,
            q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        );
    }

    // Returns the conjugate of the given quaternion q
    public static Vector4 Conjugate(Vector4 q)
    {
        return new Vector4(-q.x, -q.y, -q.z, q.w);
    }

    // Returns the Hamilton product of given quaternions q and v
    public static Vector4 HamiltonProduct(Vector4 q, Vector4 v)
    {
        return Multiply(q, Multiply(v, Conjugate(q)));
    }

    // Returns a quaternion representing a rotation of theta degrees around the given axis
    public static Vector4 AxisAngle(Vector3 axis, float theta)
    {
        float real = Mathf.Cos(theta * Mathf.Deg2Rad / 2) * Mathf.Rad2Deg;
        float a = Mathf.Sin(theta * Mathf.Deg2Rad / 2) * Mathf.Rad2Deg;
        return new Vector4(a * axis.x, a * axis.y, a * axis.z, real);
    }

    // Returns a quaternion representing the given Euler angles applied in the given rotation order
    public static Vector4 FromEuler(Vector3 euler, Vector3Int rotationOrder)
    {
        List<Vector4> orderedRotations = new List<Vector4> { Vector4.one, Vector4.one, Vector4.one };
        orderedRotations[rotationOrder.x] = AxisAngle(Vector3.right, euler.x);
        orderedRotations[rotationOrder.y] = AxisAngle(Vector3.up, euler.y);
        orderedRotations[rotationOrder.z] = AxisAngle(Vector3.forward, euler.z);
        return Multiply(orderedRotations[0], Multiply(orderedRotations[1], orderedRotations[2]));
    }

    // Returns a spherically interpolated quaternion between q1 and q2 at time t in [0,1]
    public static Vector4 Slerp(Vector4 q1, Vector4 q2, float t)
    {
        q1 = q1.normalized;
        q2 = q2.normalized;
        float realComponent = Multiply(q1, Conjugate(q2)).w;
        if (realComponent < 0 || realComponent > 180)
        {
            q2 = -q2;
        }
        float theta = Mathf.Acos(realComponent * Mathf.Deg2Rad);
        float numerator1 = Mathf.Sin((1 - t) * theta);
        float numerator2 = Mathf.Sin(t * theta);
        float denominator = Mathf.Sin(theta);
        return denominator == 0 ? q1 : (numerator1 / denominator * q1 + numerator2 / denominator * q2).normalized;
    }
}
