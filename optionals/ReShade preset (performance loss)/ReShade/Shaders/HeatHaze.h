//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Heat Haze Effect by robi29
// Copyright © 2015-2020 robi29
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#define EXTRASUNNY_HEATHAZE 	0.9f
#define CLEAR_HEATHAZE 			0.8f
#define NEUTRAL_HEATHAZE 		1.0f
#define SMOG_HEATHAZE			0.5f
#define FOGGY_HEATHAZE			0.0f
#define OVERCAST_HEATHAZE		0.0f
#define CLOUDS_HEATHAZE			0.2f
#define CLEARING_HEATHAZE		0.0f
#define RAIN_HEATHAZE			0.0f
#define THUNDER_HEATHAZE		0.0f
#define SNOW_HEATHAZE			0.0f
#define BLIZZARD_HEATHAZE		0.0f
#define LIGHTSNOW_HEATHAZE		0.0f
#define XMAS_HEATHAZE			0.0f
#define HALLOWEEN_HEATHAZE		0.0f
#define NULL_HEATHAZE			0.0f

#define H0			0.0f
#define H1			0.0f
#define H2			0.0f
#define H3			0.0f
#define H4			0.0f
#define H5			0.0f
#define H6			0.0f
#define H7			0.0f
#define H8			0.0f
#define H9			0.0f
#define H10			0.5f
#define H11			1.0f
#define H12			1.0f
#define H13			1.0f
#define H14			1.0f
#define H15			1.0f
#define H16			1.0f
#define H17			1.0f
#define H18			0.7f
#define H19			0.3f
#define H20			0.0f
#define H21			0.0f
#define H22			0.0f
#define H23			0.0f

texture2D texBlur1 		{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
texture2D texBlur2 		{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };

texture2D texHeatHaze  < source = "heathaze.png"; > { Width = 128; Height = 128; Format = R8; };

sampler2D SamplerBlur1
{
	Texture = texBlur1;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

sampler2D SamplerBlur2
{
	Texture = texBlur2;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

sampler2D SamplerHeatHaze
{
	Texture = texHeatHaze;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float ComputeFadeOutHeatHaze()
{
	float3 fadeOutTex = tex2D(SamplerColor, float2(0.0f, 0.0f)).rgb;
	[flatten]
	if (fadeOutTex.b < 1.0f)
	{
		return 0.0f;
	}

	int R = fadeOutTex.r * 255;

	int w0 = (R & 0x000000F0) >> 4;
	int w1 = R & 0x0000000F;

	static const float weathers[16] = {
		EXTRASUNNY_HEATHAZE,
		CLEAR_HEATHAZE,
		CLOUDS_HEATHAZE,
		SMOG_HEATHAZE,
		FOGGY_HEATHAZE,
		OVERCAST_HEATHAZE,
		RAIN_HEATHAZE,
		THUNDER_HEATHAZE,
		CLEARING_HEATHAZE,
		NEUTRAL_HEATHAZE,
		SNOW_HEATHAZE,
		BLIZZARD_HEATHAZE,
		LIGHTSNOW_HEATHAZE,
		XMAS_HEATHAZE,
		HALLOWEEN_HEATHAZE,
		NULL_HEATHAZE
	};

	static const float hours[25] = {
		H0,
		H1,
		H2,
		H3,
		H4,
		H5,
		H6,
		H7,
		H8,
		H9,
		H10,
		H11,
		H12,
		H13,
		H14,
		H15,
		H16,
		H17,
		H18,
		H19,
		H20,
		H21,
		H22,
		H23,
		H0
	};

	float3 timeTex = tex2D(SamplerColor, float2(1.0f, 0.0f)).rgb;

	float hour = timeTex.r*255.0f + timeTex.g*255.0f/60.0f + timeTex.b*255.0f/3600.0f;

	return float(lerp(hours[int(hour)], hours[(int(hour)+1)], timeTex.g*255.0f/60.0f) * lerp(weathers[w0], weathers[w1], fadeOutTex.g));
}

float3 GetCameraAngleXAndHeight()
{
	float3 angle = tex2D(SamplerColor, float2(0.0f, 1.0f)).rgb;
	angle.r = (angle.r + angle.g/256.0f)* 5 - 1.35;
	return angle;
}

float GetCameraAngleZ()
{
	float2 angle = tex2D(SamplerColor, float2(1.0f, 1.0f)).rg;
	float angleZ = (angle.x + angle.y/256.0f)*55.7f;
	return angleZ;
}

struct VSOut
{
	float4 pos      : SV_Position;
	float2 texcoord : TEXCOORD0;

	float4 blur0  : TEXCOORD1;
	float4 blur1  : TEXCOORD2;
	float4 blur2  : TEXCOORD3;
	float4 blur3  : TEXCOORD4;
	float4 blur4  : TEXCOORD5;
	float4 blur5  : TEXCOORD6;
	float4 blur6  : TEXCOORD7;

	float4 blur7  : TEXCOORD8;
	float4 blur8  : TEXCOORD9;
	float4 blur9  : TEXCOORD10;
	float4 blur10 : TEXCOORD11;
	float4 blur11 : TEXCOORD12;
	float4 blur12 : TEXCOORD13;
	float4 blur13 : TEXCOORD14;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Vertex Shaders
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

VSOut VS_HeatHaze(in uint id : SV_VertexID)
{
	VSOut res;

	res.texcoord.x = (id == 2) ? 2.0 : 0.0;
	res.texcoord.y = (id == 1) ? 2.0 : 0.0;
	res.pos = float4(res.texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

	res.blur0.xy = res.texcoord + float2(0.0f, -7.0f*BUFFER_RCP_HEIGHT);
	res.blur0.zw = res.texcoord + float2(0.0f, -6.0f*BUFFER_RCP_HEIGHT);

	res.blur1.xy = res.texcoord + float2(0.0f, -5.0f*BUFFER_RCP_HEIGHT);
	res.blur1.zw = res.texcoord + float2(0.0f, -4.0f*BUFFER_RCP_HEIGHT);

	res.blur2.xy = res.texcoord + float2(0.0f, -3.0f*BUFFER_RCP_HEIGHT);
	res.blur2.zw = res.texcoord + float2(0.0f, -2.0f*BUFFER_RCP_HEIGHT);

	res.blur3.xy = res.texcoord + float2(0.0f, -1.0f*BUFFER_RCP_HEIGHT);
	res.blur3.zw = res.texcoord + float2(0.0f,  1.0f*BUFFER_RCP_HEIGHT);

	res.blur4.xy = res.texcoord + float2(0.0f,  2.0f*BUFFER_RCP_HEIGHT);
	res.blur4.zw = res.texcoord + float2(0.0f,  3.0f*BUFFER_RCP_HEIGHT);

	res.blur5.xy = res.texcoord + float2(0.0f,  4.0f*BUFFER_RCP_HEIGHT);
	res.blur5.zw = res.texcoord + float2(0.0f,  5.0f*BUFFER_RCP_HEIGHT);

	res.blur6.xy = res.texcoord + float2(0.0f,  6.0f*BUFFER_RCP_HEIGHT);
	res.blur6.zw = res.texcoord + float2(0.0f,  7.0f*BUFFER_RCP_HEIGHT);

	res.blur7.xy = res.texcoord + float2(-7.0f*BUFFER_RCP_WIDTH, 0.0f);
	res.blur7.zw = res.texcoord + float2(-6.0f*BUFFER_RCP_WIDTH, 0.0f);

	res.blur8.xy = res.texcoord + float2(-5.0f*BUFFER_RCP_WIDTH, 0.0f);
	res.blur8.zw = res.texcoord + float2(-4.0f*BUFFER_RCP_WIDTH, 0.0f);

	res.blur9.xy = res.texcoord + float2(-3.0f*BUFFER_RCP_WIDTH, 0.0f);
	res.blur9.zw = res.texcoord + float2(-2.0f*BUFFER_RCP_WIDTH, 0.0f);

	res.blur10.xy = res.texcoord + float2(-1.0f*BUFFER_RCP_WIDTH, 0.0f);
	res.blur10.zw = res.texcoord + float2( 1.0f*BUFFER_RCP_WIDTH, 0.0f);

	res.blur11.xy = res.texcoord + float2( 2.0f*BUFFER_RCP_WIDTH, 0.0f);
	res.blur11.zw = res.texcoord + float2( 3.0f*BUFFER_RCP_WIDTH, 0.0f);

	res.blur12.xy = res.texcoord + float2( 4.0f*BUFFER_RCP_WIDTH, 0.0f);
	res.blur12.zw = res.texcoord + float2( 5.0f*BUFFER_RCP_WIDTH, 0.0f);

	res.blur13.xy = res.texcoord + float2( 6.0f*BUFFER_RCP_WIDTH, 0.0f);
	res.blur13.zw = res.texcoord + float2( 7.0f*BUFFER_RCP_WIDTH, 0.0f);

	return res;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Pixel Shaders
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_Blur1(in VSOut vsIn, out float4 color : SV_Target0)
{
	float2 texcoord = vsIn.texcoord;

	color = tex2Dlod(SamplerColor, float4(texcoord, 0.0f, 0.0f));
	float fadeOut = ComputeFadeOutHeatHaze();
	[branch]
	if (fadeOut > 0.0f)
	{
		float3 angle = GetCameraAngleXAndHeight();
		float distance = GetLinearDepth(texcoord);
		[branch]
		if (angle.r < texcoord.y && distance > 0.4f)
		{
			color *= 0.159576912161;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur0.xy, 0.0f, 0.0f))*0.0044299121055113265;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur0.zw, 0.0f, 0.0f))*0.00895781211794;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur1.xy, 0.0f, 0.0f))*0.0215963866053;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur1.zw, 0.0f, 0.0f))*0.0443683338718;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur2.xy, 0.0f, 0.0f))*0.0776744219933;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur2.zw, 0.0f, 0.0f))*0.115876621105;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur3.xy, 0.0f, 0.0f))*0.147308056121;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur3.zw, 0.0f, 0.0f))*0.147308056121;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur4.xy, 0.0f, 0.0f))*0.115876621105;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur4.zw, 0.0f, 0.0f))*0.0776744219933;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur5.xy, 0.0f, 0.0f))*0.0443683338718;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur5.zw, 0.0f, 0.0f))*0.0215963866053;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur6.xy, 0.0f, 0.0f))*0.00895781211794;
			color += tex2Dlod(SamplerColor, float4(vsIn.blur6.zw, 0.0f, 0.0f))*0.0044299121055113265;

			angle.r = saturate(abs(texcoord.y - angle.r) * 10.0f);

			float multiply = 1.2f*angle.r*fadeOut*angle.b * smoothstep(0.4f, 0.7f, distance);
			color *= multiply;
			color += tex2Dlod(SamplerColor, float4(texcoord, 0.0f, 0.0f))*(1.0f-multiply);
		}
	}
}

void PS_Blur2(in VSOut vsIn, out float4 color : SV_Target0)
{
	float2 texcoord = vsIn.texcoord;

	color = tex2Dlod(SamplerBlur1, float4(texcoord, 0.0f, 0.0f));
	float fadeOut = ComputeFadeOutHeatHaze();
	[branch]
	if (fadeOut > 0.0f)
	{
		float3 angle = GetCameraAngleXAndHeight();
		float distance = GetLinearDepth(texcoord);
		[branch]
		if (angle.r < texcoord.y && distance > 0.4f)
		{
			color *= 0.159576912161;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur7.xy, 0.0f, 0.0f))*0.0044299121055113265;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur7.zw, 0.0f, 0.0f))*0.00895781211794;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur8.xy, 0.0f, 0.0f))*0.0215963866053;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur8.zw, 0.0f, 0.0f))*0.0443683338718;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur9.xy, 0.0f, 0.0f))*0.0776744219933;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur9.zw, 0.0f, 0.0f))*0.115876621105;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur10.xy, 0.0f, 0.0f))*0.147308056121;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur10.zw, 0.0f, 0.0f))*0.147308056121;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur11.xy, 0.0f, 0.0f))*0.115876621105;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur11.zw, 0.0f, 0.0f))*0.0776744219933;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur12.xy, 0.0f, 0.0f))*0.0443683338718;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur12.zw, 0.0f, 0.0f))*0.0215963866053;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur13.xy, 0.0f, 0.0f))*0.00895781211794;
			color += tex2Dlod(SamplerBlur1, float4(vsIn.blur13.zw, 0.0f, 0.0f))*0.0044299121055113265;

			angle.r = saturate(abs(texcoord.y - angle.r) * 10.0f);

			float multiply = 1.2f*angle.r*fadeOut*angle.b * smoothstep(0.4f, 0.7f, distance);
			color *= multiply;
			color += tex2Dlod(SamplerBlur1, float4(texcoord, 0.0f, 0.0f))*(1.0f-multiply);
		}
	}
}

void PS_Refraction(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
{
	color = tex2Dlod(SamplerBlur2, float4(texcoord, 0.0f, 0.0f));
	float fadeOut = ComputeFadeOutHeatHaze();
	[branch]
	if (fadeOut > 0.0f && !(texcoord.x < PixelSize.x && texcoord.y < PixelSize.y) &&
		!(texcoord.x > 1.0f-PixelSize.x && texcoord.y < PixelSize.y) &&
		!(texcoord.x < PixelSize.x && texcoord.y > 1.0f-PixelSize.y) &&
		!(texcoord.x > 1.0f-PixelSize.x && texcoord.y > 1.0f-PixelSize.y))
	{
		float3 angle = GetCameraAngleXAndHeight();
		float distance = GetLinearDepth(texcoord);

		[branch]
		if (angle.r < texcoord.y && distance > 0.4f)
		{
			float angleZ = GetCameraAngleZ();
			float angleX = angle.r*8.2f;

			float4 texOffset = float4(texcoord * float2(BUFFER_WIDTH,BUFFER_HEIGHT) * 0.008f, 0.0f, 0.0f);
			texOffset += float4(Timer.x*0.0001f-angleZ,Timer.x*0.0002f-angleX, 0.0f, 0.0f);

			float2 heatTex = tex2Dlod(SamplerHeatHaze, texOffset).rg;

			heatTex.r = heatTex.r - 0.5f;

			float offset = texcoord.y;

			float angle2 = saturate(abs(texcoord.y - angle.r) * 10.0f);

			offset += ((heatTex.g+heatTex.r)*HEAT_HAZE_STRENGTH*fadeOut) * angle.b * angle2 * smoothstep(0.4f, 0.7f, distance) * step(-texcoord.y,-angle.r);

			color = tex2Dlod(SamplerBlur2, float4(texcoord.x, offset, 0.0f, 0.0f));
		}
	}
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique HeatHaze
{
	pass P0
	{
		VertexShader = VS_HeatHaze;
		PixelShader  = PS_Blur1;
		RenderTarget0 = texBlur1;
	}
	pass P1
	{
		VertexShader = VS_HeatHaze;
		PixelShader  = PS_Blur2;
		RenderTarget0 = texBlur2;
	}
	pass P2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader  = PS_Refraction;
	}
}
