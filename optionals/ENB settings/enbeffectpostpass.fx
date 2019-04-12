//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries TES Skyrim SE hlsl DX11 format, sample file
// visit http://enbdev.com for updates
// Author: Boris Vorontsov
// It's similar to effect.txt shaders and works with ldr input and output
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#define ENB_DEPTH_LINEARIZATION_FAR_PLANE 1000.0f

int CurrentWeather
<
	string UIName="Current Weather";
	string UIWidget="spinner";
	int UIMin=0;
	int UIMax=15;
> = {0};

int NextWeather
<
	string UIName="Next Weather";
	string UIWidget="spinner";
	int UIMin=0;
	int UIMax=15;
> = {0};

float Progress
<
	string UIName="Progress";
	string UIWidget="spinner";
	int UIMin=0.0;
	int UIMax=1.0;
> = {0.0};

int Hour
<
	string UIName="Hour";
	string UIWidget="spinner";
	int UIMin=0;
	int UIMax=23;
> = {12};

int Minute
<
	string UIName="Minute";
	string UIWidget="spinner";
	int UIMin=0;
	int UIMax=59;
> = {0};

int Second
<
	string UIName="Second";
	string UIWidget="spinner";
	int UIMin=0;
	int UIMax=59;
> = {0};

float3 Angle
<
	string UIName="Angle";
	string UIWidget="direction";
> = {1.0, 2.0, 3.0};

float Height
<
	string UIName="Height";
	string UIWidget="spinner";
	int UIMin=0.0;
	int UIMax=1.0;
> = {0.0};

float FadeOut
<
	string UIName="Fade Out";
	string UIWidget="spinner";
	int UIMin=0.0;
	int UIMax=1.0;
> = {0.0};

float HeatHazeSize
<
	string UIName="Heat Haze Size";
	string UIWidget="spinner";
	int UIMin=0.0;
	int UIMax=10.0;
> = {0.15};

float HeatHazeSpeed
<
	string UIName="Heat Haze Speed";
	string UIWidget="spinner";
	int UIMin=0.0;
	int UIMax=10.0;
> = {0.6};

Texture2D HeatHazeTexture
<
	string UIName = "Heat haze texture";
	string ResourceName = "heathaze.bmp";
>;


//+++++++++++++++++++++++++++++
//internal parameters, modify or add new
//+++++++++++++++++++++++++++++
/*
//example parameters with annotations for in-game editor
float	ExampleScalar
<
	string UIName="Example scalar";
	string UIWidget="spinner";
	float UIMin=0.0;
	float UIMax=1000.0;
> = {1.0};

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

Texture2D ExampleTexture
<
	string UIName = "Example texture";
	string ResourceName = "test.bmp";
>;
SamplerState ExampleSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
*/

float	EBlurAmount
<
	string UIName="Blur:: amount";
	string UIWidget="spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {1.0};

float	EBlurRange
<
	string UIName="Blur:: range";
	string UIWidget="spinner";
	float UIMin=0.0;
	float UIMax=2.0;
> = {1.0};

float	ESharpAmount
<
	string UIName="Sharp:: amount";
	string UIWidget="spinner";
	float UIMin=0.0;
	float UIMax=4.0;
> = {1.0};

float	ESharpRange
<
	string UIName="Sharp:: range";
	string UIWidget="spinner";
	float UIMin=0.0;
	float UIMax=2.0;
> = {1.0};



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
//changes in range 0..1, 0 means that night time, 1 - day time
float	ENightDayFactor;
//changes 0 or 1. 0 means that exterior, 1 - interior
float	EInteriorFactor;

//+++++++++++++++++++++++++++++
//external enb debugging parameters for shader programmers, do not modify
//+++++++++++++++++++++++++++++
//keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4	tempF1; //0,1,2,3
float4	tempF2; //5,6,7,8
float4	tempF3; //9,0
// xy = cursor position in range 0..1 of screen;
// z = is shader editor window active;
// w = mouse buttons with values 0..7 as follows:
//    0 = none
//    1 = left
//    2 = right
//    3 = left+right
//    4 = middle
//    5 = left+middle
//    6 = right+middle
//    7 = left+right+middle (or rather cat is sitting on your mouse)
float4	tempInfo1;
// xy = cursor position of previous left mouse button click
// zw = cursor position of previous right mouse button click
float4	tempInfo2;



//+++++++++++++++++++++++++++++
//mod parameters, do not modify
//+++++++++++++++++++++++++++++
Texture2D			TextureOriginal; //color R10B10G10A2 32 bit ldr format
Texture2D			TextureColor; //color which is output of previous technique (except when drawed to temporary render target), R10B10G10A2 32 bit ldr format
Texture2D			TextureDepth; //scene depth R32F 32 bit hdr format

//temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D			RenderTargetRGBA32; //R8G8B8A8 32 bit ldr format
Texture2D			RenderTargetRGBA64; //R16B16G16A16 64 bit ldr format
Texture2D			RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format
Texture2D			RenderTargetR16F; //R16F 16 bit hdr format with red channel only
Texture2D			RenderTargetR32F; //R32F 32 bit hdr format with red channel only
Texture2D			RenderTargetRGB32F; //32 bit hdr format without alpha

SamplerState		Sampler0
{
	Filter = MIN_MAG_MIP_POINT;//MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
SamplerState		Sampler1
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
SamplerState		Sampler2
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};



//+++++++++++++++++++++++++++++
//
//+++++++++++++++++++++++++++++
struct VS_INPUT_POST
{
	float3 pos		: POSITION;
	float2 txcoord	: TEXCOORD0;
};
struct VS_OUTPUT_POST
{
	float4 pos		: SV_POSITION;
	float2 txcoord0	: TEXCOORD0;
};



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
VS_OUTPUT_POST	VS_PostProcess(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST	OUT;
	float4	pos;
	pos.xyz=IN.pos.xyz;
	pos.w=1.0;
	OUT.pos=pos;
	OUT.txcoord0.xy=IN.txcoord.xy;
	return OUT;
}



float4	PS_Blur(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;
	float4	color;
	float4	centercolor;
	float2	pixeloffset=ScreenSize.y;
	pixeloffset.y*=ScreenSize.z;

	centercolor=TextureColor.Sample(Sampler0, IN.txcoord0.xy);
	color=0.0;
	float2	offsets[4]=
	{
		float2(-1.0,-1.0),
		float2(-1.0, 1.0),
		float2( 1.0,-1.0),
		float2( 1.0, 1.0),
	};
	for (int i=0; i<4; i++)
	{
		float2	coord=offsets[i].xy * pixeloffset.xy * EBlurRange + IN.txcoord0.xy;
		color.xyz+=TextureColor.Sample(Sampler1, coord.xy);
	}
	color.xyz+=centercolor.xyz;
	color.xyz *= 0.2;

	res.xyz=lerp(centercolor.xyz, color.xyz, EBlurAmount);

	res.w=1.0;
	return res;
}



float4	PS_Sharp(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;
	float4	color;
	float4	centercolor;
	float2	pixeloffset=ScreenSize.y;
	pixeloffset.y*=ScreenSize.z;

	centercolor=TextureColor.Sample(Sampler0, IN.txcoord0.xy);
	color=0.0;
	float2	offsets[4]=
	{
		float2(-1.0,-1.0),
		float2(-1.0, 1.0),
		float2( 1.0,-1.0),
		float2( 1.0, 1.0),
	};
	for (int i=0; i<4; i++)
	{
		float2	coord=offsets[i].xy * pixeloffset.xy * ESharpRange + IN.txcoord0.xy;
		color.xyz+=TextureColor.Sample(Sampler1, coord.xy);
	}
	color.xyz *= 0.25;

	float	diffgray=dot((centercolor.xyz-color.xyz), 0.3333);
	res.xyz=ESharpAmount * centercolor.xyz*diffgray + centercolor.xyz;

	res.w=1.0;
	return res;
}

float GetLinearDepth(float2 coords)
{
	float depth = TextureDepth.Sample(Sampler0, coords).x;
	depth /= ENB_DEPTH_LINEARIZATION_FAR_PLANE - depth * ENB_DEPTH_LINEARIZATION_FAR_PLANE + depth;
	return depth;
}

//write to temporary render target. you can't read texture which is set as target, result will be black
float4	PS_TemporaryWrite1(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4 res = float4(0.0f, 0.0f, 0.0f, 0.0f);

	float4 color = TextureColor.Sample(Sampler0, IN.txcoord0);

	if (FadeOut > 0.0f)
	{
		static float2 blurTexCoords[14];

		blurTexCoords[ 0] = IN.txcoord0 + float2(0.0f, -7.0f*ScreenSize.y);
		blurTexCoords[ 1] = IN.txcoord0 + float2(0.0f, -6.0f*ScreenSize.y);
		blurTexCoords[ 2] = IN.txcoord0 + float2(0.0f, -5.0f*ScreenSize.y);
		blurTexCoords[ 3] = IN.txcoord0 + float2(0.0f, -4.0f*ScreenSize.y);
		blurTexCoords[ 4] = IN.txcoord0 + float2(0.0f, -3.0f*ScreenSize.y);
		blurTexCoords[ 5] = IN.txcoord0 + float2(0.0f, -2.0f*ScreenSize.y);
		blurTexCoords[ 6] = IN.txcoord0 + float2(0.0f, -1.0f*ScreenSize.y);
		blurTexCoords[ 7] = IN.txcoord0 + float2(0.0f,  1.0f*ScreenSize.y);
		blurTexCoords[ 8] = IN.txcoord0 + float2(0.0f,  2.0f*ScreenSize.y);
		blurTexCoords[ 9] = IN.txcoord0 + float2(0.0f,  3.0f*ScreenSize.y);
		blurTexCoords[10] = IN.txcoord0 + float2(0.0f,  4.0f*ScreenSize.y);
		blurTexCoords[11] = IN.txcoord0 + float2(0.0f,  5.0f*ScreenSize.y);
		blurTexCoords[12] = IN.txcoord0 + float2(0.0f,  6.0f*ScreenSize.y);
		blurTexCoords[13] = IN.txcoord0 + float2(0.0f,  7.0f*ScreenSize.y);

		float distance = GetLinearDepth(IN.txcoord0);

		if (Angle.x < IN.txcoord0.y && distance > 0.4f)
		{
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 0])*0.0044299121055113265;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 1])*0.00895781211794;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 2])*0.0215963866053;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 3])*0.0443683338718;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 4])*0.0776744219933;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 5])*0.115876621105;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 6])*0.147308056121;
			res += color										   *0.159576912161;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 7])*0.147308056121;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 8])*0.115876621105;
			res += TextureColor.Sample(Sampler0, blurTexCoords[ 9])*0.0776744219933;
			res += TextureColor.Sample(Sampler0, blurTexCoords[10])*0.0443683338718;
			res += TextureColor.Sample(Sampler0, blurTexCoords[11])*0.0215963866053;
			res += TextureColor.Sample(Sampler0, blurTexCoords[12])*0.00895781211794;
			res += TextureColor.Sample(Sampler0, blurTexCoords[13])*0.0044299121055113265;

			float multiply = saturate(abs(IN.txcoord0.y - Angle.x) * 10.0f);

			multiply *= 1 - Height;

			float minDistance = lerp(0.4f, 1.0f, Height);
			float maxDistance = lerp(0.7f, 1.0f, Height);

			multiply *= smoothstep(minDistance, maxDistance, distance);
			multiply *= FadeOut;

			res *= multiply;
			res += color*(1.0f-multiply);
		}
		else
		{
			res = color;
		}
	}
	else
	{
		res = color;
	}

	return res;
}

//write to temporary render target
float4	PS_TemporaryWrite2(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res = float4(0,0,0,0);

	float4 color = RenderTargetRGBA64.Sample(Sampler0, IN.txcoord0);

	if (FadeOut > 0.0f)
	{
		static float2 blurTexCoords[14];
		blurTexCoords[ 0] = IN.txcoord0 + float2(-7.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 1] = IN.txcoord0 + float2(-6.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 2] = IN.txcoord0 + float2(-5.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 3] = IN.txcoord0 + float2(-4.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 4] = IN.txcoord0 + float2(-3.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 5] = IN.txcoord0 + float2(-2.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 6] = IN.txcoord0 + float2(-1.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 7] = IN.txcoord0 + float2(1.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 8] = IN.txcoord0 + float2(2.0f*ScreenSize.y, 0.0f);
		blurTexCoords[ 9] = IN.txcoord0 + float2(3.0f*ScreenSize.y, 0.0f);
		blurTexCoords[10] = IN.txcoord0 + float2(4.0f*ScreenSize.y, 0.0f);
		blurTexCoords[11] = IN.txcoord0 + float2(5.0f*ScreenSize.y, 0.0f);
		blurTexCoords[12] = IN.txcoord0 + float2(6.0f*ScreenSize.y, 0.0f);
		blurTexCoords[13] = IN.txcoord0 + float2(7.0f*ScreenSize.y, 0.0f);

		float distance = GetLinearDepth(IN.txcoord0);

		if (Angle.x < IN.txcoord0.y && distance > 0.4f)
		{
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 0])*0.0044299121055113265;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 1])*0.00895781211794;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 2])*0.0215963866053;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 3])*0.0443683338718;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 4])*0.0776744219933;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 5])*0.115876621105;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 6])*0.147308056121;
			res += color												 *0.159576912161;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 7])*0.147308056121;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 8])*0.115876621105;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[ 9])*0.0776744219933;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[10])*0.0443683338718;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[11])*0.0215963866053;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[12])*0.00895781211794;
			res += RenderTargetRGBA64.Sample(Sampler0, blurTexCoords[13])*0.0044299121055113265;

			float multiply = saturate(abs(IN.txcoord0.y - Angle.x) * 10.0f);

			multiply *= 1 - Height;

			float minDistance = lerp(0.4f, 1.0f, Height);
			float maxDistance = lerp(0.7f, 1.0f, Height);

			multiply *= smoothstep(minDistance, maxDistance, distance);
			multiply *= FadeOut;

			res *= multiply;
			res += color*(1.0f-multiply);
		}
		else
		{
			res = color;
		}
	}
	else
	{
		res = color;
	}

	return res;
}

//read from temporary target after it's drawed
float4	PS_TemporaryRead(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4 res = float4(0.0f, 0.0f, 0.0f, 0.0f);

	float4 color = RenderTargetRGBA32.Sample(Sampler0, IN.txcoord0);

	if (FadeOut > 0.0f)
	{
		float distance = GetLinearDepth(IN.txcoord0.xy);

		if (Angle.x < IN.txcoord0.y && distance > 0.4f)
		{
			const float width = ScreenSize.x;
			const float height = ScreenSize.x*ScreenSize.w;

			const float angleZ = Angle.z * HeatHazeSize;
			const float angleY = Angle.y * HeatHazeSize;

			const float2 heatHazeTexcoord = IN.txcoord0.xy * float2(width, height) * (HeatHazeSize * 0.008f);
			const float2 position = float2(angleZ, angleY) + Timer.x * (HeatHazeSpeed * 1000.0f);

			float2 heatHazeTex = HeatHazeTexture.Sample(Sampler2, heatHazeTexcoord + position).rg;

			heatHazeTex.r = heatHazeTex.r - 1.0f;

			float multiply = saturate(abs(IN.txcoord0.y - Angle.x) * 10.0f);

			multiply *= FadeOut * 0.01f;

			multiply *= 1 - Height;

			float minDistance = lerp(0.4f, 1.0f, Height);
			float maxDistance = lerp(0.7f, 1.0f, Height);

			float offset = IN.txcoord0.y;
			offset += (heatHazeTex.g+heatHazeTex.r) * multiply * smoothstep(minDistance, maxDistance, distance);

			res = RenderTargetRGBA32.Sample(Sampler0, float2(IN.txcoord0.x, offset));
		}
		else
		{
			res = color;
		}
	}
	else
	{
		res = color;
	}

	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Techniques are drawn one after another and they use the result of
// the previous technique as input color to the next one.  The number
// of techniques is limited to 255.  If UIName is specified, then it
// is a base technique which may have extra techniques with indexing
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//sharpening example
technique11 Sharp <string UIName="Sharp";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Sharp()));
	}
}


//blur example applied twice
technique11 Blur <string UIName="Blur";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur()));
	}
}

technique11 Blur1
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur()));
	}
}


//blur and then sharpening example applied as two times blur and then sharpening once
technique11 BlurSharp <string UIName="BlurSharp";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur()));
	}
}

technique11 BlurSharp1
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur()));
	}
}

technique11 BlurSharp2
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Sharp()));
	}
}


//example of using temporary render targets in techniques
technique11 TemporaryTarget <string UIName="Heathaze effect"; string RenderTarget="RenderTargetRGBA64";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_TemporaryWrite1()));
	}
}

technique11 TemporaryTarget1 <string RenderTarget="RenderTargetRGBA32";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_TemporaryWrite2()));
	}
}

technique11 TemporaryTarget2
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_TemporaryRead()));
	}
}

