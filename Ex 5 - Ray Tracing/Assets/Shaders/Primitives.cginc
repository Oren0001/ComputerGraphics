// Solves quadratic equation
float solveQuadraticEquation(float a, float b, float c) {
    float discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0) { 
        return -1;
    }  
    float t1 = (-b + sqrt(discriminant)) / (2.0 * a);
    float t2 = (-b - sqrt(discriminant)) / (2.0 * a);
    if (max(t1, t2) < 0) {
        return -1;
    }
    return (min(t1, t2) < 0) ? max(t1, t2) : min(t1, t2);
}

// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    // Your implementation
    float b = 2.0 * dot(ray.origin - sphere.xyz, ray.direction);
    float c = dot(ray.origin - sphere.xyz, ray.origin - sphere.xyz) - (sphere.w * sphere.w);
    float curDistance = solveQuadraticEquation(1, b, c);
    if ((curDistance <= 0) || (bestHit.distance <= curDistance)) {
        return;
    }
    
    bestHit.distance = curDistance;
    bestHit.position = ray.origin + curDistance * ray.direction;
    bestHit.normal = normalize(bestHit.position - sphere.xyz);
    bestHit.material = material;
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
void intersectPlane(Ray ray, inout RayHit bestHit, Material material, float3 c, float3 n)
{
    // Your implementation
    if (dot(n, ray.direction) >= 0) {
        return;
    }
    float curDistance = dot(-(ray.origin - c), n) / dot(ray.direction, n);
    if (curDistance <= 0 || bestHit.distance <= curDistance) {
        return;
    }
    bestHit.distance = curDistance;
    bestHit.position = ray.origin + curDistance * ray.direction;
    bestHit.normal = n;
    bestHit.material = material;
}

// First it checks if the uv coordinates are at the left side or right side
// of the square, then it checks if the uv coordinates are the upper side of 
// the square or not, and it finally returns the material accordignly.
Material getMaterial(Material m1, Material m2, float2 uv) {
    bool isLeft = (uv.x - floor(uv.x)) < 0.5;
    bool isDown = (uv.y - floor(uv.y)) < 0.5;
    // check left half
    if (isLeft) {
        if (isDown) {
            return m1;
        }
        return m2;
    }
    // check right half
    else {
        if (isDown) {
            return m2;
        }
        return m1;
    }
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
// The material returned is either m1 or m2 in a way that creates a checkerboard pattern 
void intersectPlaneCheckered(Ray ray, inout RayHit bestHit, Material m1, Material m2, float3 c, float3 n)
{
    // Your implementation
    if (dot(n, ray.direction) >= 0) {
        return;
    }
    float curDistance = dot(-(ray.origin - c), n) / dot(ray.direction, n);
    if ((curDistance <= 0) || (bestHit.distance <= curDistance)) {
        return;
    }

    bestHit.distance = curDistance;
    bestHit.position = ray.origin + curDistance * ray.direction;
    bestHit.normal = n;

    // we assume plane is axis-aligned
    if (abs(abs(dot(n, float3(1.0, 0.0, 0.0))) - 1.0) < EPS) { // plane is along YZ
        bestHit.material = getMaterial(m1, m2, bestHit.position.zy);
    } else if (abs(abs(dot(n, float3(0.0, 1.0, 0.0))) - 1.0) < EPS) { // plane is along XZ
        bestHit.material = getMaterial(m1, m2, bestHit.position.xz);
    } else { // plane is along XY
        bestHit.material = getMaterial(m1, m2, bestHit.position.yx);
    }
}


// Checks for an intersection between a ray and a triangle
// The triangle is defined by points a, b, c
void intersectTriangle(Ray ray, inout RayHit bestHit, Material material, float3 a, float3 b, float3 c, bool drawBackface = false)
{
    // Your implementation
    float3 n = normalize(cross(a - c, b - c));
    if (dot(n, ray.direction) == 0) {
        return;
    }
    if (!drawBackface && (dot(n, ray.direction) > 0)) {
        return;
    } 

    float curDistance = dot(-(ray.origin - c), n) / dot(ray.direction, n);
    if (curDistance <= 0 || bestHit.distance <= curDistance) {
        return;
    }
    float3 p = ray.origin + curDistance * ray.direction;
    if (dot(cross(b - a, p - a), n) >= 0 && 
        dot(cross(c - b, p - b), n) >= 0 && 
        dot(cross(a - c, p - c), n) >= 0) {   
        bestHit.distance = curDistance;
        bestHit.position = p;
        bestHit.normal = n;
        bestHit.material = material;
    }
}


// Checks for an intersection between a ray and a 2D circle
// The circle center is given by circle.xyz, its radius is circle.w and its orientation vector is n 
void intersectCircle(Ray ray, inout RayHit bestHit, Material material, float4 circle, float3 n, bool drawBackface = false)
{
    // Your implementation
    if (dot(n, ray.direction) == 0) {
        return;
    }
    if (!drawBackface && (dot(n, ray.direction) > 0)) {
        return;
    } 

    float curDistance = dot(-(ray.origin - circle.xyz), n) / dot(ray.direction, n);
    if (curDistance <= 0 || bestHit.distance <= curDistance) {
        return;
    }
    float3 p = ray.origin + curDistance * ray.direction;
    float3 v = p - circle.xyz;
    if (length(v) <= circle.w) {
        bestHit.distance = curDistance;
        bestHit.position = p;
        bestHit.normal = n;
        bestHit.material = material;
    }
}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    // Your implementation
    float originalDistance = bestHit.distance;
    float4 topCenter = float4(cylinder.x, cylinder.y + h/2.0, cylinder.z, cylinder.w);
    intersectCircle(ray, bestHit, material, topCenter, float3(0, 1, 0));
    if (originalDistance != bestHit.distance) {   // check intersection with top circle
        return;
    } else {   // check intersection with bottom circle
        float4 bottomCenter = float4(cylinder.x, cylinder.y - h/2.0, cylinder.z, cylinder.w);
        intersectCircle(ray, bestHit, material, bottomCenter, float3(0, -1, 0));
        if (originalDistance != bestHit.distance) {
            return;
        }
    }

    // check for intersection with a cylinder of infinite height.
    float2 deltaOC = ray.origin.xz - cylinder.xz;
    float a = dot(ray.direction.xz, ray.direction.xz);
    float b = 2 * dot(deltaOC, ray.direction.xz);
    float c = dot(deltaOC, deltaOC) - pow(cylinder.w, 2);

    float curDistance = solveQuadraticEquation(a, b, c);
    if ((curDistance <= 0) || (bestHit.distance <= curDistance)) {
        return;
    }

    // check if the intersection point is within the boundaries
    // and update bestHit accordignly
    float3 p = ray.origin + curDistance * ray.direction;
    if ((p.y <= (cylinder.y + h/2)) && (p.y >= (cylinder.y - h/2))) {
        bestHit.distance = curDistance;
        bestHit.position = p;
        bestHit.normal = normalize(p - float3(cylinder.x, p.y, cylinder.z));
        bestHit.material = material;
    }
}
