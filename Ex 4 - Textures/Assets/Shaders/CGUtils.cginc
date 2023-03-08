#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    // Your implementation
    float r = length(pos);
    float theta = atan2(pos.z, pos.x);
    float phi = acos(pos.y / r);

    float u = 0.5 + theta / (2 * PI);
    float v = 1 - phi / PI;

    return float2(u, v);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    // Your implementation
    fixed4 ambient = ambientIntensity * albedo;

    float diffuseAngle = max(0, dot(n, l));
    fixed4 diffuse = diffuseAngle * albedo;

    float3 h = normalize(l + v);
    float specularAngle = max(0, dot(n, h));
    fixed4 specular = pow(specularAngle, shininess) * specularity;

    return (ambient + diffuse + specular).xyz;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    // Your implementation
    fixed4 fp = tex2D(i.heightMap, i.uv);
    float uDerivative = (tex2D(i.heightMap, float2(i.uv.x + i.du, i.uv.y)) - fp) / i.du;
    float vDerivative = (tex2D(i.heightMap, float2(i.uv.x, i.uv.y + i.dv)) - fp) / i.dv;
    float3 nh = normalize(float3(-i.bumpScale * uDerivative, -i.bumpScale * vDerivative, 1)); // texture space normal
    float3 binormal = normalize(cross(i.tangent, i.normal)); // in object space
    return normalize(nh.x * i.tangent + nh.y * binormal + nh.z * i.normal); // in world space
}


#endif // CG_UTILS_INCLUDED
