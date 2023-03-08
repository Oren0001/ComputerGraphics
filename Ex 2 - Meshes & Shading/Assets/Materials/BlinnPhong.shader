Shader "CG/BlinnPhong"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (0.14, 0.43, 0.84, 1)
        _SpecularColor ("Specular Color", Color) = (0.7, 0.7, 0.7, 1)
        _AmbientColor ("Ambient Color", Color) = (0.05, 0.13, 0.25, 1)
        _Shininess ("Shininess", Range(0.1, 50)) = 10
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
                #include "Lighting.cginc"

                // Declare used properties
                uniform fixed4 _DiffuseColor;
                uniform fixed4 _SpecularColor;
                uniform fixed4 _AmbientColor;
                uniform float _Shininess;

                struct appdata
                { 
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float4 vertex : TEXCOORD0;
                    float3 normal : TEXCOORD1;
                };

                // Calculates diffuse lighting of secondary point lights (part 3)
                fixed4 pointLights(v2f input)
                {
                    fixed4 pointsLightsDiffuse[4];
                    for (int i = 0; i < 4; i++) 
                    {
                       // Diffuse secondary point i:
                       float3 lightPos = float3(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i]);
                       // Intensity:
                       float d = distance(lightPos, input.vertex);
                       float3 l = normalize(lightPos - input.vertex);
                       float intensity = 1.0 / (1.0 + (unity_4LightAtten0[i] * (d * d)));
                       // Diffuse angle:
                       float diffuseAngle = max(dot(l, input.normal), 0);
                       pointsLightsDiffuse[i] = _DiffuseColor * unity_LightColor[i] * diffuseAngle * intensity;
                     }
                    return pointsLightsDiffuse[0] + pointsLightsDiffuse[1] + pointsLightsDiffuse[2] + pointsLightsDiffuse[3];
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.vertex = input.vertex;
                    output.normal = input.normal;
                    return output;
                }


                fixed4 frag (v2f input) : SV_Target
                {
                    input.vertex = mul(unity_ObjectToWorld, input.vertex);
                    input.normal = normalize(mul(unity_ObjectToWorld, input.normal));
                    float4 l = normalize(_WorldSpaceLightPos0);
                    float4 v = normalize(float4(_WorldSpaceCameraPos - input.vertex.xyz, 0));
                    float4 h = normalize(l + v);

                    fixed4 ambient = _AmbientColor * _LightColor0;
                    float diffuseAngle = max(dot(l, input.normal), 0);
                    fixed4 diffuse = _DiffuseColor * _LightColor0 * diffuseAngle;
                    float specularAngle = max(dot(input.normal, h), 0);
                    fixed4 specular = _SpecularColor * _LightColor0 * pow(specularAngle, _Shininess);

                    return ambient + diffuse + specular + pointLights(input);
                }

            ENDCG
        }
    }
}
