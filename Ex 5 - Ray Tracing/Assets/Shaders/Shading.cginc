// Implements an adjusted version of the Blinn-Phong lighting model
float3 blinnPhong(float3 n, float3 v, float3 l, float shininess, float3 albedo)
{
    // Your implementation
    float3 diffuse = max(dot(n, l), 0) * albedo;
    float3 h = normalize(l + v);
    float3 specular = pow(max(dot(n, h), 0), shininess) * 0.4;
    return diffuse + specular;
}

// Reflects the given ray from the given hit point
void reflectRay(inout Ray ray, RayHit hit)
{
    // Your implementation
    ray.direction = normalize(2 * dot(-ray.direction, hit.normal) * hit.normal + ray.direction);
    ray.origin = hit.position + (EPS * hit.normal);
    ray.energy *= hit.material.specular;
}

// Refracts the given ray from the given hit point
void refractRay(inout Ray ray, RayHit hit)
{
    // Your implementation
    float3 n = -hit.normal;
    float eta = hit.material.refractiveIndex;
    if (dot(ray.direction, hit.normal) < 0) {
        eta = 1 / eta;
        n = -n;
    }

    float c1 = abs(dot(n, ray.direction));
    float c2 = sqrt(1 - pow(eta, 2) * (1 - pow(c1, 2)));
    float3 t = eta * ray.direction + (eta * c1 - c2) * n;

    ray.origin = hit.position + (t * EPS);
    ray.direction = t;
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction)
{
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}