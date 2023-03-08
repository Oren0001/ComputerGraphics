using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.Rendering;

public class CharacterAnimator : MonoBehaviour
{
    public TextAsset BVHFile; // The BVH file that defines the animation and skeleton
    public bool animate; // Indicates whether or not the animation should be running
    public bool interpolate; // Indicates whether or not frames should be interpolated
    [Range(0.01f, 2f)] public float animationSpeed = 1; // Controls the speed of the animation playback

    public BVHData data; // BVH data of the BVHFile will be loaded here
    public float t = 0; // Value used to interpolate the animation between frames
    public float[] currFrameData; // BVH channel data corresponding to the current keyframe
    public float[] nextFrameData; // BVH vhannel data corresponding to the next keyframe

    // Constants:
    private const string HEAD_JOINT = "Head";
    private const int HEAD_SCALE_FACTOR = 8;
    private const int REGULAR_SCALE_FACTOR = 2;
    private const int X_IDX = 0;
    private const int Y_IDX = 1;
    private const int Z_IDX = 2;
    private const float RIGHT_ANGLE = 90;
    private const float BONE_DIAMETER = 0.6f;

    // Start is called before the first frame update
    void Start()
    {
        BVHParser parser = new BVHParser();
        data = parser.Parse(BVHFile);
        CreateJoint(data.rootJoint, Vector3.zero);
        animate = true;
        interpolate = true;
    }

    /* Returns a Matrix4x4 representing a rotation aligning the up direction of an object with the given v.
     * - Vector3 v: a vector representing the new up direction, after the rotation.
     */
    public Matrix4x4 RotateTowardsVector(Vector3 v)
    {
        // Normalize the given direction vector v:
        Vector3 u = Vector3.Normalize(v);
        // Construct and return the rotation matrix R:
        // Rotate Into XY Plane:
        float angleX = (Mathf.Atan2(u[Y_IDX], u[Z_IDX])) * Mathf.Rad2Deg; // MatrixUtils uses degrees, so convert radians to degrees.
        float thetaX = RIGHT_ANGLE - angleX;
        Matrix4x4 rX = MatrixUtils.RotateX(-thetaX); // we are using clockwise rotations, so we must actually rotate by minus theta_x.
        // Rotate Into YZ Plane:
        float angleZ = (Mathf.Atan2(Mathf.Sqrt(Mathf.Pow(u[Y_IDX], 2) + Mathf.Pow(u[Z_IDX], 2)), u[X_IDX])) * Mathf.Rad2Deg;
        float thetaZ = RIGHT_ANGLE - angleZ;
        Matrix4x4 rZ = MatrixUtils.RotateZ(thetaZ);

        return rX.inverse * rZ.inverse;
    }


    /* Creates a Cylinder GameObject between two given points in 3D space
     * - Vector3 p1: first point from which to draw the cylinder
     * - Vector3 p2: second point at which the cylinder should end
     * - float diameter: width(diameter) of the cylinder to be drawn
     */
    public GameObject CreateCylinderBetweenPoints(Vector3 p1, Vector3 p2, float diameter)
    {
        // create the cylinder:
        GameObject cylinder = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        // Transformation matrix:
        Matrix4x4 t = MatrixUtils.Translate(0.5f * (p1 + p2));
        Matrix4x4 r = RotateTowardsVector(p2 - p1);
        Matrix4x4 s = MatrixUtils.Scale(new Vector3(diameter, 0.5f * Vector3.Distance(p1, p2), diameter));
        // Apply the matrix to the cylinder:
        MatrixUtils.ApplyTransform(cylinder, t * r * s);
        return cylinder;
    }


    /* Creates a GameObject representing a given BVHJoint and recursively creates GameObjects for it's child joints.
     * - BVHJoint joint: the joint that will be drawn, along with any child joints it may have.
     * - Vector3 parentPosition: the 3D position of the parent of the given joint.
     */
    public GameObject CreateJoint(BVHJoint joint, Vector3 parentPosition)
    {
        // Initialize the BVHJoint’s gameObject field:
        joint.gameObject = new GameObject(joint.name);
        // Create a sphere:
        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.parent = joint.gameObject.transform;
        // Construct a scaling matrix:
        Matrix4x4 scaleMatrix;
        if (joint.name == HEAD_JOINT)
        {
            scaleMatrix = MatrixUtils.Scale(new Vector3(HEAD_SCALE_FACTOR, HEAD_SCALE_FACTOR, HEAD_SCALE_FACTOR));
        }
        else
        {
            scaleMatrix = MatrixUtils.Scale(new Vector3(REGULAR_SCALE_FACTOR, REGULAR_SCALE_FACTOR, REGULAR_SCALE_FACTOR));
        }
        MatrixUtils.ApplyTransform(sphere, scaleMatrix);
        // Construct a translation matrix:
        Matrix4x4 translationMatrix = MatrixUtils.Translate(parentPosition + joint.offset);
        // Apply the matrix to joint.gameObject:
        MatrixUtils.ApplyTransform(joint.gameObject, translationMatrix);
        // Apply this recursively to all child joints:
        if (!joint.isEndSite)
        {
            foreach (BVHJoint child in joint.children)
            {
                CreateJoint(child, parentPosition + joint.offset);
                // Connect all the joints with bones:
                GameObject bone = CreateCylinderBetweenPoints(joint.gameObject.transform.position, child.gameObject.transform.position, BONE_DIAMETER);
                // Make the cylinder GameObject a child of joint.gameObject in the scene hierarchy:
                bone.transform.parent = joint.gameObject.transform;
            }

        }
        return joint.gameObject;
    }

    /* Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
     * BVHJoint joint - the joint to be transformed, along with any child joints it may have
     * Vector3 parentTransform - the parent joint’s transformation matrix
    */
    public void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform)
    {
        // For each joint in the skeleton, construct and apply a global transform matrix
        // Translation:
        Matrix4x4 translationMatrix;
        Vector3 currPosition = new Vector3(
            currFrameData[joint.positionChannels.x],
            currFrameData[joint.positionChannels.y],
            currFrameData[joint.positionChannels.z]);
        if (joint == data.rootJoint)
        {
            if (interpolate)
            {
                Vector3 nextPosition = new Vector3(
                    nextFrameData[joint.positionChannels.x],
                    nextFrameData[joint.positionChannels.y],
                    nextFrameData[joint.positionChannels.z]);
                translationMatrix = MatrixUtils.Translate(Vector3.Lerp(currPosition, nextPosition, t));
            }
            else
            {
                translationMatrix = MatrixUtils.Translate(currPosition);
            }
        }
        else
        {
            translationMatrix = MatrixUtils.Translate(joint.offset);
        }
        // Rotation:
        Matrix4x4 rotationMatrix;
        if (interpolate)
        {
            Vector3 currEuler = new Vector3(
                currFrameData[joint.rotationChannels.x],
                currFrameData[joint.rotationChannels.y],
                currFrameData[joint.rotationChannels.z]);
            Vector4 currQuatVec = QuaternionUtils.FromEuler(currEuler, joint.rotationOrder);
            Quaternion currQuat = new Quaternion(currQuatVec.x, currQuatVec.y, currQuatVec.z, currQuatVec.w);
            Vector3 nextEuler = new Vector3(
                nextFrameData[joint.rotationChannels.x],
                nextFrameData[joint.rotationChannels.y],
                nextFrameData[joint.rotationChannels.z]);
            Vector4 nextQuatVec = QuaternionUtils.FromEuler(nextEuler, joint.rotationOrder);
            Quaternion nextQuat = new Quaternion(nextQuatVec.x, nextQuatVec.y, nextQuatVec.z, nextQuatVec.w);
            Quaternion q = Quaternion.Slerp(currQuat, nextQuat, t);
            Vector4 interpolated = new Vector4(q.x, q.y, q.z, q.w);
            rotationMatrix = MatrixUtils.RotateFromQuaternion(interpolated);
        }
        else
        {
            List<Matrix4x4> orderedRotations = new List<Matrix4x4> { Matrix4x4.identity, Matrix4x4.identity, Matrix4x4.identity };
            Matrix4x4 xRotation = MatrixUtils.RotateX(currFrameData[joint.rotationChannels.x]);
            Matrix4x4 yRotation = MatrixUtils.RotateY(currFrameData[joint.rotationChannels.y]);
            Matrix4x4 zRotation = MatrixUtils.RotateZ(currFrameData[joint.rotationChannels.z]);
            orderedRotations[joint.rotationOrder.x] = xRotation;
            orderedRotations[joint.rotationOrder.y] = yRotation;
            orderedRotations[joint.rotationOrder.z] = zRotation;
            rotationMatrix = orderedRotations[0] * orderedRotations[1] * orderedRotations[2];
        }

        Matrix4x4 localM = translationMatrix * rotationMatrix;
        Matrix4x4 globalM = parentTransform * localM;
        MatrixUtils.ApplyTransform(joint.gameObject, globalM);
        foreach (BVHJoint child in joint.children)
        {
            TransformJoint(child, globalM);

        }
    }

    /* Returns the frame nunmber of the BVH animation at a given time
     * - time: time that has passed since initializing the program.
     */
    public int GetFrameNumber(float time)
    {
        int frameNum = (int)Mathf.Floor(time / data.frameLength);
        return frameNum % data.numFrames;
    }

    // Returns the proportion of time elapsed between the last frame and the next one, between 0 and 1
    public float GetFrameIntervalTime(float time)
    {
        float remainder = time % data.frameLength;
        return remainder / data.frameLength;
    }

    // Update is called once per frame
    void Update()
    {
        float time = Time.time * animationSpeed;
        if (animate)
        {
            int currFrame = GetFrameNumber(time);
            // Use the current frame number to update the CurrFrameData property from the BVHData
            currFrameData = data.keyframes[currFrame];
            if (interpolate)
            {
                t = GetFrameIntervalTime(time);
                // Update the nextFrameData array from the BVHData at each frame in the animation.
                if (currFrame < data.numFrames - 1) // There is no need to update on the last frame of the animation.
                {
                    nextFrameData = data.keyframes[currFrame + 1];
                }
            }
            // Call TransformJoint on the root BVHJoint.
            TransformJoint(data.rootJoint, Matrix4x4.identity);
        }
    }
}
