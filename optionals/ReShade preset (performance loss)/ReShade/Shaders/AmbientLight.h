/**
 * Copyright (C) 2015 Lucifer Hawk (mediehawk@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software with restriction, including without limitation the rights to
 * use and/or sell copies of the Software, and to permit persons to whom the Software 
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and below) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "Software"), to deal in the Software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the Software, and subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#define alThreshold 30.00f


uniform float2 AL_t < source = "pingpong"; min = 0.0f; max = 6.28f; step = float2(0.1f, 0.2f); >;

#define GEMFX_PIXEL_SIZE float2(1.0f/(BUFFER_WIDTH/16.0f),1.0f/(BUFFER_HEIGHT/16.0f))

texture2D alInTex { Width = BUFFER_WIDTH/16; Height = BUFFER_HEIGHT/16; Format = RGBA32F; };
texture2D alOutTex { Width = BUFFER_WIDTH/16; Height = BUFFER_HEIGHT/16; Format = RGBA32F; };


sampler2D alInColor { Texture = alInTex; };
sampler2D alOutColor { Texture = alOutTex; };

bool IsPausedGame()
{
	float fadeoutTex = tex2D(SamplerColor, float2(0.0, 0.0)).b;
	return (fadeoutTex < 1.0f);
}

void PS_AL_DetectHigh(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 highR : SV_Target0)
{
	float4 x = tex2D(SamplerColor, texcoord);

	x = float4 (x.rgb * pow (max (x.r, max (x.g, x.b)), 8.0), 1.0f);

	float base = (x.r + x.g + x.b)/3;

	float4 n = float4((x.rgb * 2) - base, 1.0f);

	[flatten]if (n.r < 0) { n.gb += n.r/2; n.r = 0; }
	[flatten]if (n.g < 0) { n.b += n.g/2; [flatten]if (n.r > -n.g/2) n.r += n.g/2; else n.rg = 0; }
	[flatten]if (n.b < 0) { [flatten]if (n.r > -n.b/2) n.r += n.b/2; else n.r = 0; [flatten]if (n.g > -n.b/2) n.g += n.b/2; else n.gb = 0; }

	[flatten]if (n.r > 1) { n.gb += (n.r-1)/2; n.r = 1; }
	[flatten]if (n.g > 1) { n.b += (n.g-1)/2; [flatten]if (n.r+(n.g-1) < 1) n.r += (n.g-1)/2; else n.rg = 1; }
	[flatten]if (n.b > 1) { [flatten]if (n.r+(n.b-1) < 1) n.r += (n.b-1)/2; else n.r = 1; [flatten]if (n.g+(n.b-1) < 1) n.g += (n.b-1)/2; else n.gb = 1; }

	highR = n;
}

void PS_AL_HGB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hgbR : SV_Target0)
{
	float4 hgb = tex2D(alInColor, texcoord);
	
	[branch]
	if (!IsPausedGame())
	{
		static const float sampleOffsets[4] = { 2.4347825f * GEMFX_PIXEL_SIZE.x, 4.347826f * GEMFX_PIXEL_SIZE.x, 6.2608695f * GEMFX_PIXEL_SIZE.x, 8.173913f * GEMFX_PIXEL_SIZE.x };
		static const float sampleWeights[5] = { 0.16818994f, 0.27276957f, 0.111690126f, 0.0240679048f, 0.00211121956f };

		hgb = hgb * sampleWeights[0];
		hgb = float4(max(hgb.rgb - alThreshold, 0.0), hgb.a);
		float step = 1.08 + (AL_t.x / 100)* 0.02;

		[flatten]if ((texcoord.x + sampleOffsets[0]) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[0], 0.0)) * sampleWeights[1] * step;
		[flatten]if ((texcoord.x - sampleOffsets[0]) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[0], 0.0)) * sampleWeights[1] * step;

		[flatten]if ((texcoord.x + sampleOffsets[1]) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[1], 0.0)) * sampleWeights[2] * step;
		[flatten]if ((texcoord.x - sampleOffsets[1]) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[1], 0.0)) * sampleWeights[2] * step;

		[flatten]if ((texcoord.x + sampleOffsets[2]) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[2], 0.0)) * sampleWeights[3] * step;
		[flatten]if ((texcoord.x - sampleOffsets[2]) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[2], 0.0)) * sampleWeights[3] * step;

		[flatten]if ((texcoord.x + sampleOffsets[3]) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[3], 0.0)) * sampleWeights[4] * step;
		[flatten]if ((texcoord.x - sampleOffsets[3]) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[3], 0.0)) * sampleWeights[4] * step;
	}
	hgbR = hgb;
}

void PS_AL_VGB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 vgbR : SV_Target0)
{
	float4 vgb = tex2D(alOutColor, texcoord);
	
	[branch]
	if (!IsPausedGame())
	{
		static const float sampleOffsets[4] = { 2.4347825f * GEMFX_PIXEL_SIZE.y, 4.347826f * GEMFX_PIXEL_SIZE.y, 6.2608695f * GEMFX_PIXEL_SIZE.y, 8.173913f * GEMFX_PIXEL_SIZE.y };
		static const float sampleWeights[5] = { 0.16818994f, 0.27276957f, 0.111690126f, 0.0240679048f, 0.00211121956f };

		vgb = vgb * sampleWeights[0];
		vgb = float4(max(vgb.rgb - alThreshold, 0.0), vgb.a);
		float step = 1.08 + (AL_t.x / 100)* 0.02;

		[flatten]if ((texcoord.y + sampleOffsets[0]) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[0])) * sampleWeights[1] * step;
		[flatten]if ((texcoord.y - sampleOffsets[0]) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[0])) * sampleWeights[1] * step;
		
		[flatten]if ((texcoord.y + sampleOffsets[1]) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[1])) * sampleWeights[2] * step;
		[flatten]if ((texcoord.y - sampleOffsets[1]) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[1])) * sampleWeights[2] * step;

		[flatten]if ((texcoord.y + sampleOffsets[2]) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[2])) * sampleWeights[3] * step;
		[flatten]if ((texcoord.y - sampleOffsets[2]) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[2])) * sampleWeights[3] * step;

		[flatten]if ((texcoord.y + sampleOffsets[3]) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[3])) * sampleWeights[4] * step;
		[flatten]if ((texcoord.y - sampleOffsets[3]) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[3])) * sampleWeights[4] * step;
	}
	vgbR = vgb;
}

float4 PS_AL_Magic(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 base = tex2D(SamplerColor, texcoord);
	
	[branch]
	if (IsPausedGame())
	{
		return base;
	}
	
	float4 high = tex2D(alInColor, texcoord);

	high = min(0.0325f,high)*max(0.0f,(1.15f));

#define GEMFX_alb1 max(0.0f,AMBIENT_LIGHT_STRENGTH*0.85f)
	float4 highSampleMix = (1.0 - ((1.0 - base) * (1.0 - high)));
	float4 baseSample = lerp(base, highSampleMix, AMBIENT_LIGHT_STRENGTH);
	float baseSampleMix = baseSample.r + baseSample.g + baseSample.b;
	[flatten]if (baseSampleMix>0.008)
		return baseSample;
	else
		return lerp(base, highSampleMix, GEMFX_alb1*baseSampleMix);
}

technique AmbientLight
{
	pass AL_DetectHigh
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_DetectHigh;
		RenderTarget = alInTex;
	}

	pass AL_H1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H4
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V4
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H5
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V5
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H6
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V6
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H7
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V7
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H8
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V8
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}
	
	pass AL_Magic
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_Magic;
	}
}
