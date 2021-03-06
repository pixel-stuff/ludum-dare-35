﻿Shader "Custom/Sprite/Cell-Custom-Lighting" {
	Properties{
		_Color("Main Color", Color) = (1,1,1,1)
		_BorderFreq("Border Frequency", Range(0.0, 100.0)) = 10.0
		_BorderAmp("Border Amplitude", Range(0.0, 0.1)) = 0.005
		_BorderSpeed("Border Speed", Range(0.0, 10000.0)) = 4.0
		_MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
/*#ifdef _REFRACTION
		_MaskTex("Mask texture", 2D) = "white" {}
	// refraction thing
		_Refraction("Refraction", Range(0.00, 100.0)) = 1.0
		_Speed("Distort. Speed", Float) = 0.2
		_Freq("Distort. Freq", Float) = 1.0
		_Amp("Distort. Amp", Float) = 1.0
		_DistortTex("Distort (RGB)", 2D) = "white" {}
#endif*/
		// Lighting
		_LightPos("Light Pos", Vector) = (0, 0, 0)
		_LightColor("Light Color", Color) = (1,1,1,1)
		_LightDistanceMax("Light Distance Max.", Float) = 10.0
		[Toggle]_IsLightActive("Is Light Active ?", Float) = 1.0
		_LightIntensity("Light Intensity", Float) = 1.0
		_NormalTex("Normal Map", 2D) = "bleu" {}
		// shifting penetration
		_AnglePenetration("Angle of Penetration", Float) = -1.0
	}
	SubShader{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True"/* "RenderType" = "Transparent"*/ }
		LOD 200
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha

		//GrabPass {}

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			struct v2f
			{
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 color : COLOR;
				float2 uv : TEXCOORD0;
				float3 worldRefl : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float3 lPos : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
			};

			sampler2D _MainTex;
			sampler2D _MaskTex;
			fixed4 _Color;
			// Border stuff
			float _BorderFreq;
			float _BorderAmp;
			float _BorderSpeed;
			float4 _MainTex_ST;
#ifdef _REFRACTION
			// refraction thing
			float4 _GrabTexture_TexelSize;
			float _Refraction;
			float _Speed;
			float _Freq;
			float _Amp;
			sampler2D _GrabTexture : register(s0);
			sampler2D _DistortTex : register(s2);
#endif
			// Lighting
			sampler2D _NormalTex;
			float3 _LightPos;
			float4 _LightColor;
			float _LightDistanceMax;
			float _IsLightActive;
			float _LightIntensity;

			// Penetration
			float _AnglePenetration;

			v2f vert(appdata v)
			{
				v2f o = (v2f)0;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				//v.vertex = v.vertex*sin(v.vertex+_Time.y);
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);
#ifdef _REFRACTION
				o.color = v.color;

				half4 screenpos = ComputeGrabScreenPos(o.vertex);
				o.screenPos.xy = screenpos.xy / screenpos.w;
				half depth = length(mul(UNITY_MATRIX_MV, v.vertex));
				o.screenPos.z = depth;
				o.screenPos.w = depth;
				o.lPos = unity_LightPosition[0];
#endif
				return o;
			}
#ifdef _REFRACTION
			float hash(float2 uv) {
				return frac(sin(dot(uv, float2(100.3f, 10.73f)))*51.214255);
			}

			float noise(float2 uv) {
				return lerp(hash(uv + float2(-0.1f, 0.0f)), hash(uv + float2(0.1f, 0.0f)), hash(uv));
			}

			float hash3D(float3 uv) {
				return frac(sin(dot(uv, float3(100.3f, 10.73f, 1.0f)))*51.214255);
			}

			float noise3D(float3 uv) {
				float3 fl = floor(uv);
				float3 fr = frac(uv);
				return lerp(
					lerp(
						lerp(hash3D(fl + float3(0.0f, 0.0f, 0.0f)), hash3D(fl + float3(1.0f, 0.0f, 0.0f)), fr.x),
						lerp(hash3D(fl + float3(0.0f, 1.0f, 0.0f)), hash3D(fl + float3(1.0f, 1.0f, 0.0f)), fr.x),
						fr.y),
					lerp(
						lerp(hash3D(fl + float3(0.0f, 0.0f, 1.0f)), hash3D(fl + float3(1.0f, 0.0f, 1.0f)), fr.x),
						lerp(hash3D(fl + float3(0.0f, 1.0f, 1.0f)), hash3D(fl + float3(1.0f, 1.0f, 1.0f)), fr.x),
						fr.y),
					fr.z);
			}

			float perlin3D(float3 uv) {
				float total = 0;
				float p = 1.3f;
				for (int i = 0; i < 4; i++) {
					float freq = 2.0f*float(i);
					float amplitude = p*float(i);
					total += noise3D(uv*freq) * amplitude;
				}
				return total;
			}

			float heatNoise(float3 uv) {
				float h = 0.0f;
				h = perlin3D(uv);
				return h;
			}

			float3 disp(float2 uv) {
				return float3(sin((uv.y + _Time.y*_Speed)*_Freq)*_Amp, 0.0f, 0.0f);
			}

			float3 dispHeat(float2 uv) {
				float N = heatNoise(float3(uv.x, uv.y, _Time.y*_Speed));
				return float3(N, N, N);
			}

			float3 dispTex(float2 uv) {
				return tex2D(_DistortTex, uv*3.0f + float2(_Time.y / 40.0f, _Time.w / 40.0f)).rgb;
			}

			/**
			* Rotate UV from angle around center
			* @author pierre.plans@gmail.com
			**/
			float2 rotateUV(in float2 uv, in float2 center, float angle) {
				float cosO = cos(angle*0.0174533);
				float sinO = sin(angle*0.0174533);
				uv = center + mul((uv - center), float2x2(cosO, -sinO, sinO, cosO));
				return uv;
			}

			/**
			* Scale UV
			* @author pierre.plans@gmail.com
			**/
			float2 scaleUV(in float2 uv, in float2 scale) {
				return uv / scale;
			}
#endif
			#define DEG2RAD (3.14159 / 180.0)
			#define RAD2DEG (180.0 / 3.14159)
			#define PI 3.14159

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = fixed4(0, 0, 0, 1);
				// getting the sprite texture
				//float4 spriteColor = tex2D(_SpriteTex, i.uv);

				float2 uv = i.uv;
				float2 coord = -1.0 + 2.0*uv;
				// computing mathematical stuff for borders
				float dist = length(coord);
				float dt = dot(float2(0.0, 1.0), coord);
				float cosO = dot(float2(0.0, 1.0), coord) / dist;
				/*float angle = atan2(0.0, 1.0) - atan2(coord.y, coord.x);// acos(dot(float2(0.0, 1.0), coord) / dist);
																		// computing mathematical stuff for ovalization
																		// ovalization
				if (angle < 0.0) angle = angle + 200.0*DEG2RAD;*/
				//float angle = atan2(0.0*coord.y + 1.0*coord.x, 1.0*coord.y + 0.0*coord.x) + 3.14/2.0;
				//float angle = fmod(-atan2(0.0*coord.y - 1.0*coord.x, dot(coord, float2(0.0, 1.0))), 2.0*3.14);
				//float angle = atan2(0.0*coord.y - coord.x*1.0, 0.0*coord.x + 1.0*coord.y);
				// NICEUH
				float angle = atan2(coord.y, coord.x);
				angle = fmod(-180.0 / PI * angle, 360.0)*DEG2RAD;
				if (angle < 0.0) angle += 2.0 * PI;
				float sinAngle = sin(angle);

				// penetration
				float penetrationAngleStart = (_AnglePenetration - 15.0)*DEG2RAD;
				if (penetrationAngleStart < -15.0*DEG2RAD) penetrationAngleStart += 2.0 * PI;
				float penetrationAngleEnd = (_AnglePenetration + 15.0)*DEG2RAD;
				if (penetrationAngleEnd < 15.0*DEG2RAD) penetrationAngleEnd += 2.0 * PI;

				// deformation for velocity
				float2 speedV = float2(1.0, 1.0);
				float2 speedVM = float2(1.0, 1.0);
				float speed = length(speedV);
				float cosOS = dot(speedV, coord) / (dist*speed);
				float angleS = acos(dot(speedV, coord) / (dist*speed));
				float dtS = dot(speedV, coord);
				float2 offset = float2(cos(angleS)*speedV.x, sin(angleS)*speedV.y);

				float2 uvOv = float2(dtS, dtS);
				//uv = scaleUV(uv, speedV);
				//uv = uv + uvOv;
				//uv = scaleUV(uv, speedV);
				//uv = rotateUV(uv, vec2(0.0, 0.0), angleS);
				//float2 center = float2(0.0, 0.0);
				//center = scaleUV(center, speedV);
				//center = rotateUV(center, float2(0.0, 0.0), angleS);

				float _borderOffset = sin(sinAngle*_BorderFreq + _Time.y*_BorderSpeed)*_BorderAmp;
				if (_AnglePenetration >=0.0 && abs(penetrationAngleStart - angle)<15.0*DEG2RAD) {
					_borderOffset -= (sin(sinAngle*_BorderFreq*4.0 + _Time.y*_BorderSpeed)+PI*0.5)*_BorderAmp*1.6;
				}

				bool testOval = length(coord) > abs(_borderOffset);
				// border animation
				if (dist > 0.7)
					uv += _borderOffset;

				fixed4 spriteColor = tex2D(_MainTex, uv) * _Color;
#ifdef _REFRACTION
				fixed4 mask = tex2D(_MaskTex, uv).a;
				//col.r = spriteColor.a;
				// getting 
				if (mask.a == 0.0f) {
					col = tex2D(_GrabTexture, i.screenPos);
				}else if(spriteColor.a==0.0) {
					float3 distort = dispTex(uv);// hash(i.uv) * float3(i.color.r, i.color.g, i.color.b);
					float2 offset = distort * _Refraction * _GrabTexture_TexelSize.xy;
					//if (!(spriteColor.r == 1.0f && spriteColor.g == 1.0f && spriteColor.b == 1.0f)) {
						i.screenPos.xy = offset * i.screenPos.z + i.screenPos.xy;
					//}
					col = tex2D(_GrabTexture, i.screenPos);
					/*col.r = 1.0;
					col.gb = 0.0;*/
				}
				else col = spriteColor;
#else
				col = spriteColor;
#endif
				/*else if (spriteColor.a > 0.0f) {
					float2 grabTexcoord = i.screenPos.xy;
					fixed4 colTransparency = tex2D(_GrabTexture, grabTexcoord);

					float3 distort = dispHeat(i.uv) * float3(i.color.r, i.color.g, i.color.b);
					float2 offset = distort * _Refraction * _GrabTexture_TexelSize.xy;
					if (!(spriteColor.r == 1.0f && spriteColor.g == 1.0f && spriteColor.b == 1.0f)) {
						i.screenPos.xy = offset * i.screenPos.z + i.screenPos.xy;
					}
					fixed4 colDistort = tex2D(_GrabTexture, i.screenPos);

					col = lerp(colTransparency, colDistort, 1.0-spriteColor.a);

				}
				else {
					float2 grabTexcoord = i.screenPos.xy;
					col = tex2D(_GrabTexture, grabTexcoord);
				}*/


				//col.r = spriteColor.a;
				/*col.r = spriteColor.a>0.0?1.0:0.0;
				col.g = col.b = 0.0;*/

				// Lighting
				if (_IsLightActive) {
					float3 worldPos = i.worldPos;
					float3 lPos = _LightPos;
					float3 LtoD = lPos - worldPos.xyz;
					float3 EtoD = _WorldSpaceCameraPos - worldPos.xyz;
					float3 normal = tex2D(_NormalTex, uv).rgb;
					float Lambert = min(1.0, max(0.0, dot(normalize(float3(0.0, 0.0, 1.0)/*LtoD*/), normalize(normal))));
					float gradient = (1.0 - length(LtoD) / _LightDistanceMax);
					float3 debug = Lambert;
					//col.rgb = lerp(col.rgb, _LightColor, (1.0 - length(LtoD) / _LightDistanceMax))*max(0.0, dot(normalize(LtoD), normalize(normal)));
					// Ambient + Diffuse(LambertTerm * Light Color * attenuation * intensity)
					col.rgb = lerp(col.rgb, Lambert * _LightColor * gradient * _LightIntensity, gradient);
					//col.rgb = debug;
				}
				// apply fog
				//col.rgb = debug;
				/*col.rgb = (angle+3.14/2.0);
				col.r = abs(penetrationAngleStart-angle)<15.0*DEG2RAD ? 1.0 : 0.0;
				col.g = col.b = 0.0;*/
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
	Fallback "Legacy Shaders/Transparent/Diffuse"
}
