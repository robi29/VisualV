//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries TES Skyrim SE hlsl DX11 format, example adaptation
// visit http://enbdev.com for updates
// Author: Boris Vorontsov
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



//+++++++++++++++++++++++++++++
//internal parameters, modify or add new
//+++++++++++++++++++++++++++++



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
//game and mod parameters, do not modify
//+++++++++++++++++++++++++++++
//x = AdaptationMin, y = AdaptationMax, z = AdaptationSensitivity, w = AdaptationTime multiplied by time elapsed
float4				AdaptationParameters;

Texture2D			TextureCurrent;
Texture2D			TexturePrevious;

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



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
VS_OUTPUT_POST	VS_Quad(VS_INPUT_POST IN, uniform float sizeX, uniform float sizeY)
{
	VS_OUTPUT_POST	OUT;
	float4	pos;
	pos.xyz=IN.pos.xyz;
	pos.w=1.0;
	OUT.pos=pos;
	float2	offset;
	offset.x=sizeX;
	offset.y=sizeY;
	OUT.txcoord0.xy=IN.txcoord.xy + offset.xy;
	return OUT;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//output size is 16*16
//TextureCurrent size is 256*256, it's internally downscaled from full screen
//input texture is R16G16B16A16 or R11G11B10 float format (alpha ignored)
//output texture is R32 float format (red channel only)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	PS_Downsample(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;

	//downsample 256*256 to 16*16
	//more complex blurring methods affect result if sensitivity uncommented
	float2	pos;
	float2	coord;
	float4	curr=0.0;
	float4	currmax=0.0;
	const float	scale=1.0/16.0;
	const float	step=1.0/16.0;
	const float	halfstep=0.5/16.0;
	pos.x=-0.5+halfstep;
	for (int x=0; x<16; x++)
	{
		pos.y=-0.5+halfstep;
		for (int y=0; y<16; y++)
		{
			coord=pos.xy * scale;
			float4	tempcurr=TextureCurrent.Sample(Sampler0, IN.txcoord0.xy + coord.xy);
			currmax=max(currmax, tempcurr);
			curr+=tempcurr;

			pos.y+=step;
		}
		pos.x+=step;
	}
	curr*=1.0/(16.0*16.0);

	res=curr;

	//adjust sensitivity to small bright areas on the screen
	//Warning! Uncommenting the next line increases sensitivity a lot
	//res=lerp(curr, currmax, AdaptationParameters.z); //AdaptationSensitivity

	//TODO modify this math to your taste, for example lower intensity for blue colors
	//gray output
	//v1
	res=max(res.x, max(res.y, res.z));
	//v2
	//res=dot(res.xyz, 0.3333);
	//v3
	//res=dot(res.xyz, float3(0.2125, 0.7154, 0.0721));

	res.w=1.0;
	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//output size is 1*1
//TexturePrevious size is 1*1
//TextureCurrent size is 16*16
//output and input textures are R32 float format (red channel only)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	PS_Adaptation(VS_OUTPUT_POST IN, float4 v0 : SV_Position0) : SV_Target
{
	float4	res;

	float	prev=TexturePrevious.Sample(Sampler0, IN.txcoord0.xy).x;

	//downsample 16*16 to 1*1
	float2	pos;
	float	curr=0.0;
	float	currmax=0.0;
	const float	step=1.0/16.0;
	const float	halfstep=0.5/16.0;
	pos.x=-0.5+halfstep;
	for (int x=0; x<16; x++)
	{
		pos.y=-0.5+halfstep;
		for (int y=0; y<16; y++)
		{
			float	tempcurr=TextureCurrent.Sample(Sampler0, IN.txcoord0.xy + pos.xy).x;
			currmax=max(currmax, tempcurr);
			curr+=tempcurr;

			pos.y+=step;
		}
		pos.x+=step;
	}
	curr*=1.0/(16.0*16.0);

	//adjust sensitivity to small bright areas on the screen
	curr=lerp(curr, currmax, AdaptationParameters.z); //AdaptationSensitivity

	//smooth by time
	res=lerp(prev, curr, AdaptationParameters.w); //AdaptationTime with elapsed time

	//clamp to avoid bugs in post process shader, which have much lower floating point precision
	res=max(res, 0.001);
	res=min(res, 16384.0);

	//limit value if ForceMinMaxValues=true
	float	valmax;
	float	valcut;
	valmax=max(res.x, max(res.y, res.z));
	valcut=max(valmax, AdaptationParameters.x); //AdaptationMin
	valcut=min(valcut, AdaptationParameters.y); //AdaptationMax
	res*=valcut/(valmax + 0.000000001f);

	res.w=1.0;
	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//techniques
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//first pass for downscaling and computing sensitivity
technique11 Downsample
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad(0.0, 0.0)));
		SetPixelShader(CompileShader(ps_5_0, PS_Downsample()));
	}
}

//last pass for mixing everything
technique11 Draw //<string UIName="ENBAdaptation";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad(0.0, 0.0)));
		SetPixelShader(CompileShader(ps_5_0, PS_Adaptation()));
	}
}

