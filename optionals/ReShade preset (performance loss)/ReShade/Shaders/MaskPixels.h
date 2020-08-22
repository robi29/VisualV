void PS_MaskPixels(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
{
	static float2 replacementTexcoord = texcoord;

	[flatten] if (texcoord.x < PixelSize.x && texcoord.y < PixelSize.y)
	{
		replacementTexcoord = float2(PixelSize.x*2.0f, PixelSize.y);
	}
	else [flatten] if (texcoord.x > 1.0f - PixelSize.x && texcoord.y < PixelSize.y)
	{
		replacementTexcoord = float2(1.0f - PixelSize.x*2.0f, PixelSize.y);
	}
	else [flatten] if (texcoord.x < PixelSize.x && texcoord.y > 1.0f - PixelSize.y)
	{
		replacementTexcoord = float2(PixelSize.x*2.0f, 1.0f - PixelSize.y);
	}
	else [flatten] if (texcoord.x > 1.0f - PixelSize.x && texcoord.y > 1.0f - PixelSize.y)
	{
		replacementTexcoord = float2(1.0f - PixelSize.x*2.0f, 1.0f - PixelSize.y);
	}

	color = tex2D(SamplerColor, replacementTexcoord);
}

technique TechMaskPixels
{
	pass Pass0
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_MaskPixels;
	}
}
