//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// light sprites sample effect, feel free to modify
// ENBSeries GTA 5 hlsl DX11 format
// visit http://enbdev.com for updates
// Author: Boris Vorontsov
// Author: original shader code by Rockstar Games
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//Warning! Size of sprites affect performance, so try to keep them smaller
//and do not draw areas of quads where pixels are not visible.



//+++++++++++++++++++++++++++++
//internal parameters, modify or add new
//+++++++++++++++++++++++++++++
string textline01 = "Night light sprites shader file"; 

float	EIntensity
<
	string UIName="Intensity";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=1000.0;
> = {10.0};

float	ESize
<
	string UIName="Size (performance penalty)";
	string UIWidget="Spinner";
	float UIStep=0.01;
	float UIMin=0.05;
	float UIMax=8.0;
> = {0.25};

float	EGlowSize
<
	string UIName="Glow:: size (performance penalty)";
	string UIWidget="Spinner";
	float UIStep=0.01;
	float UIMin=0.1;
	float UIMax=8.0;
> = {1.0};

float	EGlowAmount
<
	string UIName="Glow:: amount";
	string UIWidget="Spinner";
	float UIStep=0.01;
	float UIMin=0.0;
	float UIMax=8.0;
> = {0.25};
/*
//other example parameters
float3	ExampleColor
<
	string UIName = "Example color";
	string UIWidget = "color";
> = {0.0, 1.0, 0.0};
float4	ExampleVector
<
	string UIName="Example vector";
	string UIWidget="vector";
> = {0.0, 1.0, 0.0, 0.0};
int	ExampleQuality
<
	string UIName="Example quality";
	string UIWidget="quality";
	int UIMin=0;
	int UIMax=3;
> = {1};

//example of texture loaded from file, not used in shader though
Texture2D SpriteTexture
<
	string UIName = "Sprite texture";
	string ResourceName = "xxx.bmp";
>;
SamplerState SpriteSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
	SRGBTexture = FALSE;
};
*/


//+++++++++++++++++++++++++++++
//external enb parameters, do not modify
//+++++++++++++++++++++++++++++
//x = generic timer in range 0..1, period of 16777216 ms (4.6 hours), y = average fps, w = frame time elapsed (in seconds)
float4	Timer;
//x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4	ScreenSize;
//changes in range 0..1, 0 means full quality, 1 lowest dynamic quality (0.33, 0.66 are limits for quality levels)
float	AdaptiveQuality;
//x = current weather index, y = outgoing weather index, z = weather transition, w = time of the day in 24 standart hours. Weather index is value from weather ini file, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4	Weather;
//x = dawn, y = sunrise, z = day, w = sunset. Interpolators range from 0..1
float4	TimeOfDay1;
//x = dusk, y = night. Interpolators range from 0..1
float4	TimeOfDay2;
//+++++++++++++++++++++++++++++
//external enb debugging parameters for shader programmers, do not modify
//+++++++++++++++++++++++++++++
//keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4	tempF1; //0,1,2,3
float4	tempF2; //5,6,7,8
float4	tempF3; //9,0
//xy = cursor position in range 0..1 of screen, z = is shader editor window active
float4	tempInfo1;



//+++++++++++++++++++++++++++++
//game parameters and objects, do not modify
//+++++++++++++++++++++++++++++
float4				Params01;
float4				Params02;
row_major float4x4	WorldViewProj;
row_major float4x4	ViewInverse;
float4				ClipPlanes;
float4				globalFogParams[5];
float4				refMipBlurParams;

Texture2D			DepthTexture;
Texture2D			DiffuseTexture;// : register(t2);
Texture2D			NoiseTexture;// : register(t7);

SamplerState		DiffuseSampler//; : register(s2);
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
SamplerState		NoiseSampler//; : register(s7);
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};
SamplerState		DepthSampler
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Clamp;
	AddressV = Clamp;
};


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Vanilla shaders
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
void	VS_Draw( 
	float3 v0 : POSITION0,
	float4 v1 : COLOR0,
	float2 v2 : TEXCOORD0,
	out float4 o0 : TEXCOORD0,
	out float3 o1 : TEXCOORD1,
	out float4 o2 : SV_Position0,
	out float4 o3 : SV_ClipDistance0)
{
	float4	r0, r1;

	o0.xy = v2.xy;
	o0.zw = v0.xy;
	r0.xyz = -ViewInverse._m30_m31_m32 + v0.xyz;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = sqrt(r0.w);
	r1.x = -globalFogParams[0].x + r0.w;
	r1.x = max(0.0, r1.x);
	r1.y = r1.x / r0.w;
	r1.y = r1.y * r0.z;
	r0.x = dot(r0.xyz, -ViewInverse._m20_m21_m22);
	r0.x = Params02.z * r0.x;
	r0.x = max(1.0, r0.x);
	r0.y = globalFogParams[2].z * r1.y;
	r0.z = 0.01 < abs(r1.y);
	r1.y = -1.442695 * r0.y;
	r1.y = exp2(r1.y);
	r1.y = 1.0 - r1.y;
	r0.y = r1.y / r0.y;
	r0.y = r0.z ? r0.y : 1.0;
	r0.z = globalFogParams[1].w * r1.x;
	r1.x = -globalFogParams[2].x + r1.x;
	r1.x = max(0.0, r1.x);
	r1.x = globalFogParams[1].x * r1.x;
	r1.x = 1.442695 * r1.x;
	r1.x = exp2(r1.x);
	r1.x = 1.0 - r1.x;
	r0.y = r0.z * r0.y;
	r0.y = min(1.0, r0.y);
	r0.y = 1.442695 * r0.y;
	r0.y = exp2(r0.y);
	r0.y = min(1.0, r0.y);
	r0.y = 1.0 - r0.y;
	r0.z = -r0.y * globalFogParams[2].y + 1.0;
	r0.y = globalFogParams[2].y * r0.y;
	r0.z = globalFogParams[1].y * r0.z;
	r0.y = saturate(r0.z * r1.x + r0.y);
	r0.y = 1.0 - r0.y;
	r0.z = r0.x * r0.x;
	r1.x = Params02.y; //near clipping distance
	r1.x = r0.w - r1.x;
	r1.x = r1.x >= 0.0;
	r1.x = r1.x ? 1.000000 : 0;
	r0.z = r1.x / r0.z;
	r0.y = r0.y * r0.z;
	r0.z = -refMipBlurParams.y + r0.w;
	r0.w = -500.0 + r0.w;
	r0.w = saturate(0.0005 * r0.w);
	r0.w = r0.w * 15.0 + 1.0;
	r0.z = saturate(r0.z / refMipBlurParams.z);
	r0.z = r0.y * r0.z;
	r1.x = 0.0 != refMipBlurParams.x;
	r0.y = r1.x ? r0.z : r0.y;
	r0.z = Params02.w * v1.w;
	r1.xyz = v1.xyz * r0.zzz;
	r1.xyz = r1.xyz * r0.yyy;
	r0.y = 0.0 < r0.y;
	r0.y = r0.y ? 1.000000 : 0;
	o1.xyz = r1.xyz * r0.www;
	r0.zw = float2(-0.5, -0.5) + v2.xy;
	r0.zw = Params02.xx * r0.zw * ESize; //size
	r1.xyz = ViewInverse._m10_m11_m12 * r0.www;
	r1.xyz = r0.zzz * ViewInverse._m00_m01_m02 + r1.xyz;
	r0.xzw = r1.xyz * r0.xxx;
	r0.xyz = r0.xzw * r0.yyy + v0.xyz;
	r1.xyzw = WorldViewProj._m10_m11_m12_m13 * r0.yyyy;
	r1.xyzw = r0.xxxx * WorldViewProj._m00_m01_m02_m03 + r1.xyzw;
	r0.xyzw = r0.zzzz * WorldViewProj._m20_m21_m22_m23 + r1.xyzw;
	r0.xyzw = WorldViewProj._m30_m31_m32_m33 + r0.xyzw;
	o2.xyzw = r0.xyzw;
	o3.x = dot(r0.xyzw, ClipPlanes.xyzw);
	o3.yzw = float3(0.0, 0.0, 0.0);
	return;
}



float4	PS_Draw(
	float4 v0 : TEXCOORD0,
	float3 v1 : TEXCOORD1,
	float4 v2 : SV_Position0,
	float4 v3 : SV_ClipDistance0) : SV_Target
{
	float4	res;
	float4	r0, r1, r2;

	r0.xyzw = DiffuseTexture.Sample(DiffuseSampler, v0.xy).xyzw;
	r0.x = r0.x * r0.x;
	r0.x = r0.x * r0.x;
	r0.xyz = v1.xyz * r0.xxx;
	r1.xy = Params01.zz + v0.zw;
	r1.xyzw = NoiseTexture.Sample(NoiseSampler, r1.xy).xyzw;
	r1.xz = float2(1.0, 1.0) - Params01.yw;
	r0.w = r1.y * r1.x + Params01.y;
	r0.xyz = r0.xyz * r0.www;
	r1.xy = v0.zw * float2(0.0019531, 0.0019531) + Params01.zz;
	r2.xyzw = NoiseTexture.Sample(NoiseSampler, r1.xy).xyzw;
	r0.w = r2.y * r1.z + Params01.w;
	r0.xyz = r0.xyz * r0.www;
	res.xyz = Params01.x * r0.xyz * EIntensity;
	res.w = 1.0;
	//optimization
	float	clipped=dot(res.xyz, 0.3333);
	clip(clipped-0.001);

	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Glow shaders
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
void	VS_DrawGlow( 
	float3 v0 : POSITION0,
	float4 v1 : COLOR0,
	float2 v2 : TEXCOORD0,
	out float4 o0 : TEXCOORD0,
	out float3 o1 : TEXCOORD1,
	out float4 o2 : SV_Position0,
	out float4 o3 : SV_ClipDistance0)
{
	float4	r0, r1;

	o0.xy = v2.xy;
	o0.zw = v0.xy;
	r0.xyz = -ViewInverse._m30_m31_m32 + v0.xyz;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = sqrt(r0.w);
	r1.x = -globalFogParams[0].x + r0.w;
	r1.x = max(0.0, r1.x);
	r1.y = r1.x / r0.w;
	r1.y = r1.y * r0.z;
	r0.x = dot(r0.xyz, -ViewInverse._m20_m21_m22);
	r0.x = Params02.z * r0.x;
	r0.x = max(1.0, r0.x);
	r0.y = globalFogParams[2].z * r1.y;
	r0.z = 0.01 < abs(r1.y);
	r1.y = -1.442695 * r0.y;
	r1.y = exp2(r1.y);
	r1.y = 1.0 - r1.y;
	r0.y = r1.y / r0.y;
	r0.y = r0.z ? r0.y : 1.0;
	r0.z = globalFogParams[1].w * r1.x;
	r1.x = -globalFogParams[2].x + r1.x;
	r1.x = max(0.0, r1.x);
	r1.x = globalFogParams[1].x * r1.x;
	r1.x = 1.442695 * r1.x;
	r1.x = exp2(r1.x);
	r1.x = 1.0 - r1.x;
	r0.y = r0.z * r0.y;
	r0.y = min(1.0, r0.y);
	r0.y = 1.442695 * r0.y;
	r0.y = exp2(r0.y);
	r0.y = min(1.0, r0.y);
	r0.y = 1.0 - r0.y;
	r0.z = -r0.y * globalFogParams[2].y + 1.0;
	r0.y = globalFogParams[2].y * r0.y;
	r0.z = globalFogParams[1].y * r0.z;
	r0.y = saturate(r0.z * r1.x + r0.y);
	r0.y = 1.0 - r0.y;
	r0.z = r0.x * r0.x;
	r1.x = Params02.y; //near clipping distance
	r1.x = r0.w - r1.x;
	r1.x = r1.x >= 0.0;
	r1.x = r1.x ? 1.000000 : 0;
	r0.z = r1.x / r0.z;
	r0.y = r0.y * r0.z;
	r0.z = -refMipBlurParams.y + r0.w;
	r0.w = -500.0 + r0.w;
	r0.w = saturate(0.0005 * r0.w);
	r0.w = r0.w * 15.0 + 1.0;
	r0.z = saturate(r0.z / refMipBlurParams.z);
	r0.z = r0.y * r0.z;
	r1.x = 0.0 != refMipBlurParams.x;
	r0.y = r1.x ? r0.z : r0.y;
	r0.z = Params02.w * v1.w;
	r1.xyz = v1.xyz * r0.zzz;
	r1.xyz = r1.xyz * r0.yyy;
	r0.y = 0.0 < r0.y;
	r0.y = r0.y ? 1.000000 : 0.0;
	o1.xyz = r1.xyz * r0.www;
	r0.zw = float2(-0.5, -0.5) + v2.xy;
	r0.zw = Params02.xx * r0.zw * EGlowSize; //size
	r1.xyz = ViewInverse._m10_m11_m12 * r0.www;
	r1.xyz = r0.zzz * ViewInverse._m00_m01_m02 + r1.xyz;
	r0.xzw = r1.xyz * r0.xxx;
	r0.xyz = r0.xzw * r0.yyy + v0.xyz;
	r1.xyzw = WorldViewProj._m10_m11_m12_m13 * r0.yyyy;
	r1.xyzw = r0.xxxx * WorldViewProj._m00_m01_m02_m03 + r1.xyzw;
	r0.xyzw = r0.zzzz * WorldViewProj._m20_m21_m22_m23 + r1.xyzw;
	r0.xyzw = WorldViewProj._m30_m31_m32_m33 + r0.xyzw;
	o2.xyzw = r0.xyzw;
	o3.x = dot(r0.xyzw, ClipPlanes.xyzw);
	o3.yzw = float3(0.0, 0.0, 0.0);
	return;
}



float4	PS_DrawGlow(
	float4 v0 : TEXCOORD0,
	float3 v1 : TEXCOORD1,
	float4 v2 : SV_Position0,
	float4 v3 : SV_ClipDistance0) : SV_Target
{
	float4	res;
	float4	r0, r1, r2;

	float	dpfactor;
	float	clipped;
	float2	coord;
	float2	centeruv=v0.xy*2.0-1.0;
	coord.xy=centeruv / max(ESize, 0.01);
	clipped=dot(coord.xy, coord.xy);
	coord.xy=coord*0.5+0.5;
	//v1 smooth edge
//	dpfactor=1.0-saturate(dot(centeruv.xy, centeruv.xy));
//	dpfactor=(dpfactor*dpfactor);
	//v2 sharp edge
	dpfactor=saturate(dot(centeruv.xy, centeruv.xy));
	dpfactor=1.0-(dpfactor*dpfactor*dpfactor);

	//optimization, cut to circles
	clip(dpfactor-0.001);

//	r0 = SpriteTexture.Sample(SpriteSampler, coord.xy); //you may load custom texture here, see it's file name
	r0 = DiffuseTexture.Sample(DiffuseSampler, coord.xy);

	if (clipped>1.0) r0=0.0;
	r0.x+=dpfactor * EGlowAmount;

	r0.x = r0.x * r0.x;
	r0.x = r0.x * r0.x;
	r0.xyz = v1.xyz * r0.xxx;
	r1.xy = Params01.zz + v0.zw;
	r1.xyzw = NoiseTexture.Sample(NoiseSampler, r1.xy).xyzw;
	r1.xz = float2(1.0, 1.0) - Params01.yw;
	r0.w = r1.y * r1.x + Params01.y;
	r0.xyz = r0.xyz * r0.www;
	r1.xy = v0.zw * float2(0.0019531, 0.0019531) + Params01.zz;
	r2.xyzw = NoiseTexture.Sample(NoiseSampler, r1.xy).xyzw;
	r0.w = r2.y * r1.z + Params01.w;
	r0.xyz = r0.xyz * r0.www;
	res.xyz = Params01.x * r0.xyz * EIntensity;
	res.w = 1.0;
	//optimization
	clipped=dot(res.xyz, 0.3333);
	clip(clipped-0.001);

	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//techniques
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//same as vanilla, but only controlled by size and intensity
technique11 Draw <string UIName="Vanilla";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_4_0, VS_Draw()));
		SetPixelShader(CompileShader(ps_4_0, PS_Draw()));
	}
}

//glowing is bigger area of sprite as overlay
technique11 DrawGlow <string UIName="Glow";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_4_0, VS_DrawGlow()));
		SetPixelShader(CompileShader(ps_4_0, PS_DrawGlow()));
	}
}


