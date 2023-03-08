Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"

                #define BUMP_DIVISOR 10000

                // Declare used properties
                uniform sampler2D _AlbedoMap;
                uniform float _Ambient;
                uniform sampler2D _SpecularMap;
                uniform float _Shininess;
                uniform sampler2D _HeightMap;
                uniform float4 _HeightMap_TexelSize;
                uniform float _BumpScale;
                uniform sampler2D _CloudMap;
                uniform fixed4 _AtmosphereColor;

                struct appdata
                { 
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float4 worldPos : TEXCOORD0;
                    float4 objectPos : TEXCOORD1;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex);
                    output.objectPos = input.vertex;
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos.xyz);
                    float3 n = normalize(input.worldPos.xyz);
                    float3 l = normalize(_WorldSpaceLightPos0.xyz);

                    float2 uv = getSphericalUV(input.objectPos);
                    fixed4 albedo = tex2D(_AlbedoMap, uv);
                    fixed4 specularity = tex2D(_SpecularMap, uv);
                    fixed4 cloudColor = tex2D(_CloudMap, uv);

                    // bump
                    float3 t = normalize(cross(n, float3(0, 1, 0)));
                    bumpMapData i = {n, t, uv, _HeightMap, _HeightMap_TexelSize.x, 
                        _HeightMap_TexelSize.y, _BumpScale / BUMP_DIVISOR};
                    float3 bumpNormal = getBumpMappedNormal(i);
                    float3 finalNormal = normalize((1 - specularity)*bumpNormal + specularity*n);
                    fixed4 phong = fixed4(blinnPhong(finalNormal, v, l, _Shininess, albedo, specularity, _Ambient), 1);

                    // add atmosphere and clouds
                    float lambert = sqrt(max(0, dot(n, l)));
                    float nvAngle = max(0, dot(n, v));
                    fixed4 atmosphere = (1 - nvAngle) * lambert * _AtmosphereColor;
                    fixed4 cloud = (_Ambient + lambert) * cloudColor;

                    return phong + atmosphere + cloud;
                }

            ENDCG
        }
    }
}
