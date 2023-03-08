Shader "CG/BlinnPhongGouraud"
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
                    fixed4 color: COLOR0;
                };


                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);

                    float4 worldVertex = mul(unity_ObjectToWorld, input.vertex);
                    float4 worldNormal = normalize(mul(unity_ObjectToWorld, input.normal));
                    float4 l = normalize(_WorldSpaceLightPos0);
                    float4 v = normalize(float4(_WorldSpaceCameraPos - worldVertex.xyz, 0));
                    float4 h = normalize(l + v);

                    fixed4 ambient = _AmbientColor * _LightColor0;
                    float diffuseAngle = max(dot(l, worldNormal), 0);
                    fixed4 diffuse = _DiffuseColor * _LightColor0 * diffuseAngle;
                    float specularAngle = max(dot(worldNormal, h), 0);
                    fixed4 specular = _SpecularColor * _LightColor0 * pow(specularAngle, _Shininess);

                    output.color = ambient + diffuse + specular;
                    return output;
                }


                fixed4 frag (v2f input) : SV_Target
                {
                    return input.color;
                }

            ENDCG
        }
    }
}
