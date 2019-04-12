/*
 *                    ____      ____  _               _
 *                   |  _ \ ___/ ___|| |__   __ _  __| | ___
 *                   | |_) / _ \___ \| '_ \ / _` |/ _` |/ _ \
 *                   |  _ '  __/___) | | | | (_| | (_| |  __/
 *                   |_| \_\___|____/|_| |_|\__,_|\__,_|\___|
 *
 * =============================================================================
 *                           ReShade Framework Globals
 * =============================================================================
 */

uniform float  Timer < source = "timer"; >;

static const float AspectRatio = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
static const float2 PixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
static const float2 ScreenSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

texture2D texColor : COLOR;
texture2D texDepth : DEPTH;

sampler2D SamplerColor
{
	Texture = texColor;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

sampler2D SamplerDepth
{
	Texture = texDepth;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

void RFX_VS_PostProcess(in uint id : SV_VertexID, out float4 pos : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	pos = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

float GetLinearDepth(float2 coords)
{
	float depth = tex2Dlod(SamplerDepth, float4(coords.xy,0,0)).x;
	depth = 1.0 - depth;

	depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE + depth;
	return depth;
}

#include "MXAO.h"
#include "HeatHaze.h"
#include "AmbientLight.h"
#include "MaskPixels.h"
