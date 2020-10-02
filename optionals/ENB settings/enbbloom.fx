//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries TES Skyrim SE hlsl DX11 format, sample file of bloom
// visit http://enbdev.com for updates
// Author: Boris Vorontsov
// It's works with hdr input and output
// Bloom texture is always forced to 1024*1024 resolution
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



//+++++++++++++++++++++++++++++
//internal parameters, modify or add new
//+++++++++++++++++++++++++++++
float	EFalloff
<
	string UIName="Falloff";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=1.0;
> = {0.0};

int	EFalloffType
<
	string UIName="Falloff Type";
	string UIWidget="Spinner";
	int UIMin=0;
	int UIMax=5;
> = {0};

float	EOctaveWeight1
<
	string UIName="Octave weight 1";
	string UIWidget="Spinner";
	float UIMin=-0.3;
	float UIMax=1.0;
> = {0.027};

float	EOctaveWeight2
<
	string UIName="Octave weight 2";
	string UIWidget="Spinner";
	float UIMin=-0.3;
	float UIMax=1.0;
> = {0.11};

float	EOctaveWeight3
<
	string UIName="Octave weight 3";
	string UIWidget="Spinner";
	float UIMin=-0.3;
	float UIMax=1.0;
> = {0.25};

float	EOctaveWeight4
<
	string UIName="Octave weight 4";
	string UIWidget="Spinner";
	float UIMin=-0.3;
	float UIMax=1.0;
> = {0.44};

float	EOctaveWeight5
<
	string UIName="Octave weight 5";
	string UIWidget="Spinner";
	float UIMin=-0.3;
	float UIMax=1.0;
> = {0.7};

float	EOctaveWeight6
<
	string UIName="Octave weight 6";
	string UIWidget="Spinner";
	float UIMin=-0.3;
	float UIMax=1.0;
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
//x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4	BloomSize;



//+++++++++++++++++++++++++++++
//mod parameters, do not modify
//+++++++++++++++++++++++++++++
Texture2D			TextureDownsampled; //color R16B16G16A16 64 bit or R11G11B10 32 bit hdr format. 1024*1024 size
Texture2D			TextureColor; //color which is output of previous technique (except when drawed to temporary render target), R16B16G16A16 64 bit hdr format. 1024*1024 size

Texture2D			TextureOriginal; //color R16B16G16A16 64 bit or R11G11B10 32 bit hdr format, screen size. PLEASE AVOID USING IT BECAUSE OF ALIASING ARTIFACTS, UNLESS YOU FIX THEM
Texture2D			TextureDepth; //scene depth R32F 32 bit hdr format, screen size. PLEASE AVOID USING IT BECAUSE OF ALIASING ARTIFACTS, UNLESS YOU FIX THEM
Texture2D			TextureAperture; //this frame aperture 1*1 R32F hdr red channel only. computed in PS_Aperture of enbdepthoffield.fx

//temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D			RenderTarget1024; //R16B16G16A16F 64 bit hdr format, 1024*1024 size
Texture2D			RenderTarget512; //R16B16G16A16F 64 bit hdr format, 512*512 size
Texture2D			RenderTarget256; //R16B16G16A16F 64 bit hdr format, 256*256 size
Texture2D			RenderTarget128; //R16B16G16A16F 64 bit hdr format, 128*128 size
Texture2D			RenderTarget64; //R16B16G16A16F 64 bit hdr format, 64*64 size
Texture2D			RenderTarget32; //R16B16G16A16F 64 bit hdr format, 32*32 size
Texture2D			RenderTarget16; //R16B16G16A16F 64 bit hdr format, 16*16 size
Texture2D			RenderTargetRGBA32; //R8G8B8A8 32 bit ldr format, screen size
Texture2D			RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format, screen size

SamplerState		Sampler0
{
	Filter = MIN_MAG_MIP_POINT;
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



//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//helper function
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	texBiquadratic(Texture2D tex, SamplerState smp, float2 texsize, float2 invtexsize, float2 uv)
{
	float2	q = frac(uv * texsize);
	float2	c = (q*(q - 1.0) + 0.5) * invtexsize;
	float2	w0 = uv - c;
	float2	w1 = uv + c;
	float4	s =
		  tex.Sample(smp, float2(w0.x, w0.y))
		+ tex.Sample(smp, float2(w0.x, w1.y))
		+ tex.Sample(smp, float2(w1.x, w1.y))
		+ tex.Sample(smp, float2(w1.x, w0.y));
	return s * 0.25;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
VS_OUTPUT_POST	VS_Quad(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST	OUT;
	OUT.pos.xyz = IN.pos.xyz;
	OUT.pos.w = 1.0;
	OUT.txcoord0.xy = IN.txcoord.xy;
	return OUT;
}



float3	FuncBlur(Texture2D inputtex, float2 uvsrc, float srcsize, float destsize)
{
	const float	scale=4.0; //blurring range, samples count (performance) is factor of scale*scale
	//const float	srcsize=1024.0; //in current example just blur input texture of 1024*1024 size
	//const float	destsize=1024.0; //for last stage render target must be always 1024*1024

	float2	invtargetsize=scale/srcsize;
	invtargetsize.y*=ScreenSize.z; //correct by aspect ratio

	float2	fstepcount;
	fstepcount=srcsize;

	fstepcount*=invtargetsize;
	fstepcount=min(fstepcount, 16.0);
	fstepcount=max(fstepcount, 2.0);

	int	stepcountX=(int)(fstepcount.x+0.4999);
	int	stepcountY=(int)(fstepcount.y+0.4999);

	fstepcount=1.0/fstepcount;
	float4	curr=0.0;
	curr.w=0.000001;
	float2	pos;
	float2	halfstep=0.5*fstepcount.xy;
	pos.x=-0.5+halfstep.x;
	invtargetsize *= 2.0;
	for (int x=0; x<stepcountX; x++)
	{
		pos.y=-0.5+halfstep.y;
		for (int y=0; y<stepcountY; y++)
		{
			float2	coord=pos.xy * invtargetsize + uvsrc.xy;
			float3	tempcurr=inputtex.Sample(Sampler1, coord.xy).xyz;
			float	tempweight;
			float2	dpos=pos.xy*2.0;
			float	rangefactor=dot(dpos.xy, dpos.xy);
			//loosing many pixels here, don't program such unefficient cycle yourself!
			tempweight=saturate(1001.0 - 1000.0*rangefactor);//arithmetic version to cut circle from square
			tempweight*=saturate(1.0 - rangefactor); //softness, without it bloom looks like bokeh dof
			curr.xyz+=tempcurr.xyz * tempweight;
			curr.w+=tempweight;

			pos.y+=fstepcount.y;
		}
		pos.x+=fstepcount.x;
	}
	curr.xyz *= 1.0/curr.w;

	return curr.xyz;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//draw in several passes to different render targets
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float4	PS_Resize(VS_OUTPUT_POST IN, float4 v0 : SV_Position0,
	uniform Texture2D inputtex, uniform float srcsize, uniform float destsize) : SV_Target
{
	float4	res;

	res.xyz = FuncBlur(inputtex, IN.txcoord0.xy, srcsize, destsize);

	res = max(res, 0.0);
	res = min(res, 32768.0);

	res.w = 1.0;
	return res;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//last pass mix all textures
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
VS_OUTPUT_POST	VS_BloomPostPass(VS_INPUT_POST IN, out float4 table1 : TEXCOORD1, out float4 table2 : TEXCOORD2)
{
	VS_OUTPUT_POST	OUT;
	OUT.pos.xyz = IN.pos.xyz;
	OUT.pos.w = 1.0;
	OUT.txcoord0.xy = IN.txcoord.xy;

//	table1 = float4(0.027, 0.11, 0.25, 0.44);
//	table2 = float4(0.7, 1.0, 0.0, 0.0);
	table1.x = EOctaveWeight1;
	table1.y = EOctaveWeight2;
	table1.z = EOctaveWeight3;
	table1.w = EOctaveWeight4;
	table2.x = EOctaveWeight5;
	table2.y = EOctaveWeight6;

	if (EFalloffType == 1)
	{
		table1 = float4(0.001, 0.11, 0.25, 0.44);
		table2 = float4(0.7, 1.0, 0.0, 0.0);
	}
	if (EFalloffType == 2)
	{
		table1 = float4(0.01, 0.2, 0.6, 1.0);
		table2 = float4(0.6, 0.1, 0.0, 0.0);
	}
	if (EFalloffType == 3)
	{
		table1 = float4(0.0, 0.01, 0.2, 0.6);
		table2 = float4(0.2, 0.01, 0.0, 0.0);
	}
	if (EFalloffType == 4)
	{
		table1 = float4(0.05, 0.8, 0.4, 0.1);
		table2 = float4(0.05, 0.01, 0.0, 0.0);
	}
	if (EFalloffType == 5)
	{
		table1 = float4(0.0,0.01,-0.3, 0.7);
		table2 = float4(0.2, 0.1, 0.0, 0.0);
	}

	float	falloff = 1.0 - EFalloff;
	falloff = falloff * falloff;
	table1 = lerp(table1, 1.0, falloff);
	table2 = lerp(table2, 1.0, falloff);

	return OUT;
}



float4	PS_BloomPostPass(VS_OUTPUT_POST IN, in float4 table1 : TEXCOORD1, in float4 table2 : TEXCOORD2, float4 vPos : SV_Position0) : SV_Target
{
	float4	bloom;
	float	weight;

	bloom.xyz = RenderTarget512.Sample(Sampler1, IN.txcoord0.xy) * table1.x;
	bloom.xyz+= texBiquadratic(RenderTarget256, Sampler1, 256.0, 1.0/256.0, IN.txcoord0.xy) * table1.y;
	bloom.xyz+= texBiquadratic(RenderTarget128, Sampler1, 128.0, 1.0/128.0, IN.txcoord0.xy) * table1.z;
	bloom.xyz+= texBiquadratic(RenderTarget64, Sampler1, 64.0, 1.0/64.0, IN.txcoord0.xy) * table1.w;
	bloom.xyz+= texBiquadratic(RenderTarget32, Sampler1, 32.0, 1.0/32.0, IN.txcoord0.xy) * table2.x;
	bloom.xyz+= texBiquadratic(RenderTarget16, Sampler1, 16.0, 1.0/16.0, IN.txcoord0.xy) * table2.y;

	weight = dot(table1, 1.0) + dot(table2, 1.0);
	bloom.xyz *= 1.0/weight;

	bloom = max(bloom, 0.0);
	bloom = min(bloom, 32768.0);

	bloom.w = 1.0;
	return bloom;
}



//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Techniques are drawn one after another and they use the result of
// the previous technique as input color to the next one.  The number
// of techniques is limited to 255.  If UIName is specified, then it
// is a base technique which may have extra techniques with indexing
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
technique11 Draw <string UIName="Multipass bloom"; string RenderTarget="RenderTarget512";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Resize(TextureDownsampled, 1024.0, 512.0)));
	}
}

technique11 Draw1 <string RenderTarget="RenderTarget256";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Resize(RenderTarget512, 512.0, 256.0)));
	}
}

technique11 Draw2 <string RenderTarget="RenderTarget128";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Resize(RenderTarget256, 256.0, 128.0)));
	}
}

technique11 Draw3 <string RenderTarget="RenderTarget64";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Resize(RenderTarget128, 128.0, 64.0)));
	}
}

technique11 Draw4 <string RenderTarget="RenderTarget32";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Resize(RenderTarget64, 64.0, 32.0)));
	}
}

technique11 Draw5 <string RenderTarget="RenderTarget16";>
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_Quad()));
		SetPixelShader(CompileShader(ps_5_0, PS_Resize(RenderTarget64, 32.0, 16.0)));
	}
}

technique11 Draw6
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, VS_BloomPostPass()));
		SetPixelShader(CompileShader(ps_5_0, PS_BloomPostPass()));
	}
}
