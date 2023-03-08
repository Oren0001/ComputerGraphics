Shader "CG/Bricks"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(-100, 100)) = 40
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

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float4 worldPos : TEXCOORD1;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
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
                    float3 l = normalize(_WorldSpaceLightPos0.xyz);

                    fixed4 albedo = tex2D(_AlbedoMap, input.uv);
                    fixed4 specularity = tex2D(_SpecularMap, input.uv);

                    // bump
                    float3 t = normalize(input.tangent.xyz);
                    bumpMapData b = {n, t, input.uv, _HeightMap, _HeightMap_TexelSize.x, 
                        _HeightMap_TexelSize.y, _BumpScale / BUMP_DIVISOR};
                    float3 bumpNormal = getBumpMappedNormal(b);

                    fixed3 phong = blinnPhong(bumpNormal, v, l, _Shininess, albedo, specularity, _Ambient);
                    return fixed4(phong, 1);
                }

            ENDCG
        }
    }
}
