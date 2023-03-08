Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
                uniform float _BumpScale;

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float4 worldPos : TEXCOORD1;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    // Your implementation
                    return perlin3d(float3(0.5 * uv[0], 0.5* uv[1], 0.5 * t)) +
                    0.5 * perlin3d(float3(uv[0], uv[1], t)) +
                    0.2 * perlin3d(float3(2 * uv[0], 2 * uv[1], 3 * t));
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                {
                    // Your implementation
                    float derivative_u = (waterNoise(i.uv + i.du, t) - waterNoise(i.uv, t)) / i.du;
                    float derivative_v = (waterNoise(i.uv + i.dv, t) - waterNoise(i.uv, t)) / i.dv;
                    float s = i.bumpScale;
                    float3 n_h = normalize(float3(-s * derivative_u, -s * derivative_v, 1));
                    float3 binormalVector = cross(i.tangent, i.normal);
                    return i.tangent * n_h.x + i.normal * n_h.z + binormalVector * n_h.y;
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    float noise = waterNoise(_NoiseScale * input.uv, _Time.y * _TimeScale) * _BumpScale;
                    float4 newPos = input.vertex + noise * float4(input.normal, 0);
                    output.pos = UnityObjectToClipPos(newPos);
                    output.uv = input.uv; 
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex); 
                    output.normal = mul(unity_ObjectToWorld, input.normal); 
                    output.tangent = mul(unity_ObjectToWorld, input.tangent); 
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos.xyz); 
                    float3 n = normalize(input.normal); 
                    float3 t = normalize(input.tangent);

                    bumpMapData bump;
                    bump.du = DELTA;
                    bump.dv = DELTA;
                    bump.bumpScale = _BumpScale;
                    bump.normal = n;
                    bump.tangent = t;
                    bump.uv = input.uv * _NoiseScale;

                    float3 bumpedNormal = normalize(getWaterBumpMappedNormal(bump, _Time.y * _TimeScale)); 
                    float3 r = normalize(2 * dot(v, bumpedNormal) * bumpedNormal - v);
                    fixed4 reflectedColor = texCUBE(_CubeMap, r);
                    fixed4 color = (1 - max(0, dot(v, bumpedNormal)) + 0.2) * reflectedColor;
                    return color;
                }

            ENDCG
        }
    }
}