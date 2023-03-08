#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
float bicubicInterpolation(float v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float v[4], float2 t)
{
    // Your implementation
    float2 u = 6 * pow(t, 5) - 15 * pow(t, 4) + 10 * pow(t, 3); // quintic hermite curve

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float v[8], float3 t)
{
    // Your implementation
    float3 u = 6 * pow(t, 5) - 15 * pow(t, 4) + 10 * pow(t, 3);

    float arr1[4] = {v[0],v[1],v[2],v[3]};
    float arr2[4] = {v[4],v[5],v[6],v[7]};

    float x1 = biquinticInterpolation(arr1, float2(u.x,u.y));
    float x2 = biquinticInterpolation(arr2, float2(u.x,u.y));
    return lerp(x1, x2, u.z);
}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    // Your implementation
    float uLeft = floor(c.x);
    float uRight = ceil(c.x);
    float vDown = floor(c.y);
    float vUp = ceil(c.y);

    float cornersValue[4];
    cornersValue[0] = random2(float2(uLeft, vDown)).x;
    cornersValue[1] = random2(float2(uRight, vDown)).x;
    cornersValue[2] = random2(float2(uLeft, vUp)).x;
    cornersValue[3] = random2(float2(uRight, vUp)).x;
    float2 t = frac(c);

    return bicubicInterpolation(cornersValue, t);
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    // Your implementation
    float uLeft = floor(c.x);
    float uRight = ceil(c.x);
    float vDown = floor(c.y);
    float vUp = ceil(c.y);
    float2 corners[4] = {float2(uLeft, vDown), float2(uRight, vDown), 
        float2(uLeft, vUp), float2(uRight, vUp)};

    float cornersValue[4];
    for(int i=0; i<4; i++) {
        float2 gradient = random2(corners[i]);
        float2 distance = c - corners[i];
        cornersValue[i] = dot(gradient, distance);
    }
    float2 t = frac(c);

    return biquinticInterpolation(cornersValue, t);
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{                    
    // Your implementation
    float3 cornerArray[8];
    cornerArray[0] = floor(c); // downLeft1 
    cornerArray[2] = float3(cornerArray[0].x, cornerArray[0].y + 1, cornerArray[0].z); // upLeft1 
    cornerArray[3] = float3(cornerArray[2].x + 1, cornerArray[2].y, cornerArray[0].z); // upRight1 
    cornerArray[1] = float3(cornerArray[3].x, cornerArray[3].y - 1, cornerArray[0].z); // downRight1
    cornerArray[4] = floor(c) + float3(0, 0, 1); // downLeft2 
    cornerArray[6] = float3(cornerArray[4].x, cornerArray[4].y + 1, cornerArray[4].z); //  upLeft2  
    cornerArray[7] = float3(cornerArray[6].x + 1, cornerArray[6].y, cornerArray[4].z); // upRight2 
    cornerArray[5] = float3(cornerArray[7].x, cornerArray[7].y - 1, cornerArray[4].z); // downRight2 

    // Calculate the dot product of each distance vector and its corresponding gradient vector
    // and get 8 influence values.
    float influences[8];
    for (int i = 0; i < 8; i++) {
        float3 gradient = random3(cornerArray[i]);
        float3 distance = c - cornerArray[i];
        influences[i] = dot(gradient, distance);
        }

    float3 t = frac(c); 
    return triquinticInterpolation(influences, t);
}


#endif // CG_RANDOM_INCLUDED
