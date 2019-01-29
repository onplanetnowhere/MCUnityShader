
Shader "ShaderMan/Minecraft"
	{


	Properties{
		_MainTex("MainTex", 2D) = "white" {}
	_SecondTex("SecondTex", 2D) = "white" {}
	_ThirdTex("ThirdTex", 2D) = "white" {}
	_FourthTex("FourthTex", 2D) = "white" {}
	[Toggle] _F3("F3",float) = 0.0
		[Toggle] _UIOnly("UIOnly",float) = 0.0
		[Toggle] _NoDebug("NoDebug",float) = 0.0
		[Toggle] _NoHotbar("NoHotbar",float) = 0.0
		[Toggle] _NoCrosshair("NoCrosshair",float) = 0.0
	}

	SubShader
	{
	Tags { "RenderType" = "Opaque" "Queue" = "Transparent" }

	Pass
	{
	//Source https://www.shadertoy.com/view/MtcGDH
	//ZWrite Off
	//Cull Off
	Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
	#pragma target 3.0
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"

	struct VertexInput {
    fixed4 vertex : POSITION;
	fixed2 uv:TEXCOORD0;
    fixed4 tangent : TANGENT;
    fixed3 normal : NORMAL;
	//VertexInput
	};


	struct VertexOutput {
	fixed4 pos : SV_POSITION;
	fixed2 uv:TEXCOORD0;
	//VertexOutput
	};

	//Variables
sampler2D _FourthTex;
sampler2D _ThirdTex;
sampler2D _SecondTex;
sampler2D _MainTex;
static const fixed2 iResolution = fixed2(800, 450);
static const fixed2 iChannelResolution0 = fixed2(800, 450);
static const fixed2 iChannelResolution2 = fixed2(800, 450);

fixed _F3;
fixed _UIOnly, _NoDebug, _NoHotbar, _NoCrosshair;

	/* 
Voxel Game
fb39ca4's SH16C Entry

This was an attempt to make something like Minecraft entirely in
Shadertoy. The world around the player is saved in a buffer, and as long
as an an area is loaded, changes remain. However, if you go too far
away, blocks you have fmodified will reset. To load more blocks, go to 
fullscreen to increase the size of the buffers. I tried to implement
many of the features from Minecraft's Creative fmode, but at this point,
this shader is more of a tech demo to prove that interactive voxel games
are possible.

Features:
    Semi-persistent world
    Flood-fill sky and torch lighting
    Smooth lighting and ambient occlusion
    Day/Night cycle
    Movement with collision detection
    Flying and sprinting fmode
    Block placment and removal
    Hotbar to choose between: Stone, Dirt, Grass, Cobblestone, Glowstone, 
        Brick, Gold, Wood
    
Controls:
    Click and drag mouse to look, select blocks
    WASD to move
    Space to jump
    Double-tap space to start flying, use space and shift to go up and down.
    Q + mouse button to place block
    E + mouse button to destroy blocks
    Z/X to cycle through available blocks for placement
    0-8 to choose a block type for placement
    Page Up/Down to increase or decrease render resolution
    O,P to decrease/increase speed of day/night cycles

	There are #defines in Buffer A to change the controls.

TODO:
âœ“ Voxel Raycaster
âœ“ Free camera controls
âœ“ Store map in tex2D
âœ“ Infinite World
âœ“ Persistent World
âœ“ Sky Lighting
âœ“ Torch Lighting
âœ“ Smooth Lighting, Ambient Occlusion
âœ“ Vertical Collision Detection
âœ“ Walking, Jumping
âœ“ Horizontal collision detection
âœ“ Textures
âœ“ Proper world generation
âœ“ Block picking
âœ“ Adding/Removing blocks
âœ“ GUI for block selection
âœ“ Sun, Moon, Sky
âœ“ Day/Night Cycle
âœ“ Double jump to fly, double tap forwards to run
*/

#define var(name, x, y) static const fixed2 name = fixed2(x, y)
#define varRow 0.
var(_pos, 0, varRow);
var(_pos2, 1, varRow);
var(_pos3, 14, varRow);
var(_angle, 2, varRow);
var(_mouse, 3, varRow);
var(_loadRange, 4, varRow);
var(_inBlock, 5, varRow);
var(_vel, 6, varRow);
var(_pick, 7, varRow);
var(_pickTimer, 8, varRow);
var(_renderScale, 9, varRow);
var(_selectedInventory, 10, 2);
var(_flightMode, 11, varRow);
var(_sprintMode, 12, varRow);
var(_time, 13, varRow);
var(_old, 0, 1);


fixed2 lessThanEqual2(fixed2 a, fixed2 b) {
	fixed2 result;
	result[0] = a[0] <= b[0];
	result[1] = a[1] <= b[1];
	return result;
}

fixed4 load(fixed2 coord) {
	return pow(tex2Dlod(_MainTex, float4(fixed2((floor(coord) + 0.5) / iChannelResolution0.xy), 0.0, 0)), 0.454545);
	//return tex2Dlod(_MainTex,float4( fixed2((floor(coord) + 0.5) / iChannelResolution[0].xy), 0.0,0));
}

fixed keyToggled(int keyCode) {
	return pow(tex2Dlod(_SecondTex,float4( fixed2((fixed(keyCode) + 0.5) / 256., 2.5/3.), 0.0,0)), 0.454545).r;
}


// ---- 8< ---- GLSL Number Printing - @P_Malin ---- 8< ----
// Creative Commons CC0 1.0 Universal (CC-0) 
// https://www.shadertoy.com/view/4sBSWW

fixed DigitBin(const in int x)
{
    return x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
}

fixed PrintValue(const in fixed2 iuv, const in fixed2 vPixelCoords, const in fixed2 vFontSize, const in fixed fValue, const in fixed fMaxDigits, const in fixed fDecimalPlaces)
{
    fixed2 vStringCharCoords = (iuv.xy - vPixelCoords) / vFontSize;
    if ((vStringCharCoords.y < 0.0) || (vStringCharCoords.y >= 1.0)) return 0.0;
	fixed fLog10Value = log2(abs(fValue)) / log2(10.0);
	fixed fBiggestIndex = max(floor(fLog10Value), 0.0);
	fixed fDigitIndex = fMaxDigits - floor(vStringCharCoords.x);
	fixed fCharBin = 0.0;
	if(fDigitIndex > (-fDecimalPlaces - 1.01)) {
		if(fDigitIndex > fBiggestIndex) {
			if((fValue < 0.0) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
		} else {		
			if(fDigitIndex == -1.0) {
				if(fDecimalPlaces > 0.0) fCharBin = 2.0;
			} else {
				if(fDigitIndex < 0.0) fDigitIndex += 1.0;
				fixed fDigitValue = (abs(fValue / (pow(10.0, fDigitIndex))));
                fixed kFix = 0.0001;
                fCharBin = DigitBin(int(floor(fmod(kFix+fDigitValue, 10.0))));
			}		
		}
	}
    return floor(fmod((fCharBin / pow(2.0, floor(frac(vStringCharCoords.x) * 4.0) + (floor(vStringCharCoords.y * 5.0) * 4.0))), 2.0));
}

fixed getInventory(fixed slot) {
	return slot + 1. + step(2.5, slot);  
}

fixed4 getTexture(fixed id, fixed2 c) {
    fixed2 gridPos = fixed2(fmod(id, 16.), floor(id / 16.));
	return pow(tex2Dlod(_ThirdTex, float4(16. * (c + gridPos) / iChannelResolution2.xy, 0.0, 0)), 0.454545);
	//return tex2Dlod(_ThirdTex,float4( 16. * (c + gridPos) / iChannelResolution[2].xy, 0.0,0));
}

static const fixed numItems = 8.;

fixed4 drawSelectionBox(fixed2 c) {
	fixed4 o = fixed4(0.,0.,0.,0.);
    fixed d = max(abs(c.x), abs(c.y));
    if (d > 6. && d < 9.) {
        o.a = 1.;
        o.rgb = fixed3(0.9,0.9,0.9);
        if (d < 7.) o.rgb -= 0.3;
        if (d > 8.) o.rgb -= 0.1;
    }
    return o;
}

fixed2x2 inv2(fixed2x2 m) {
  return fixed2x2(m[1][1],-m[0][1], -m[1][0], m[0][0]) / (m[0][0]*m[1][1] - m[0][1]*m[1][0]);
}

fixed4 drawGui(fixed2 c) {
	//fixed scale = floor(1 / 128.);
	fixed scale = floor(iResolution.y / 128.);
    c /= scale;
    fixed2 r = iResolution.xy / scale;
    fixed4 o = fixed4(0,0,0,0);
    fixed xStart = (r.x - 16. * numItems) / 2.;
    c.x -= xStart;
    fixed selected = load(_selectedInventory).r;
    fixed2 p = (frac(c / 16.) - .5) * 3.;
    fixed2 u = fixed2(sqrt(3.)/2.,.5);
    fixed2 v = fixed2(-sqrt(3.)/2.,.5);
    fixed2 w = fixed2(0,-1);
    if (c.x < numItems * 16. && c.x >= 0. && c.y < 16.) {
        fixed slot = floor(c.x / 16.);
    	o = getTexture(48., frac(c / 16.));
        fixed3 b = fixed3(dot(p,u), dot(p,v), dot(p,w));
        fixed2 texCoord;
        //if (all(lessThan(b, fixed3(1,1,1)))) o = fixed4(dot(p,u), dot(p,v), dot(p,w),1.);
        fixed top = 0.;
        fixed right = 0.;
        if (b.z < b.x && b.z < b.y) {
			texCoord = mul(p.xy, inv2(fixed2x2(u, v)));
            top = 1.;
        }
        else if(b.x < b.y) {
        	texCoord = 1. - mul(p.xy,inv2(fixed2x2(v,w)));
            right = 1.;
        }
        else {
        	texCoord = mul(p.xy, inv2(fixed2x2(u,w)));
            texCoord.y = 1. - texCoord.y;
        }
        if (all(lessThanEqual2(abs(texCoord - .5), fixed2(.5, .5)))) {
            fixed id = getInventory(slot);
            if (id == 3.) id += top;
            o.rgb = getTexture(id, texCoord).rgb * (0.5 + 0.25 * right + 0.5 * top);
            o.a = 1.;
		}
    }
    fixed4 selection = drawSelectionBox(c - 8. - fixed2(16. * selected, 0));
    o = lerp(o, selection, selection.a);
    return o;
}

// ---- 8< -------- 8< -------- 8< -------- 8< ----

static const fixed2 packedChunkSize = fixed2(11,6);




	VertexOutput vert (VertexInput v)
	{
	VertexOutput o;
	o.pos = UnityObjectToClipPos (v.vertex);
	o.uv = v.uv;
	//VertexFactory
	return o;
	}
	fixed4 frag(VertexOutput i) : SV_Target
	{
		i.uv.x *= 800;
	i.uv.y *= 450;
	//i.uv = ceil(i.uv);

	fixed3 renderScale = load(_renderScale).rgb;
	fixed scaleFactor = pow(sqrt(2.), renderScale.r);
	fixed2 renderResolution = ceil(iResolution.xy / scaleFactor);
	half4 fragColor;
	if (_UIOnly) {
		fragColor = half4(-0.01, -0.01, -0.01, 0);
		fixed2 c = i.uv;
		fixed scale = floor(iResolution.y / 128.);
		c /= scale;
		fixed2 r = iResolution.xy / scale;
		fixed xStart = (r.x - 16. * numItems) / 2.;
		c.x -= xStart;
		if (c.x < numItems * 16. && c.x >= 0. && c.y < 16.) {
			fragColor.a = 1.25;
		}
	}
	else {
		fragColor = pow(tex2D(_FourthTex, i.uv * renderResolution / iResolution.xy / iResolution.xy), 0.454545);
	}
	if (!_NoHotbar) {
		fixed4 gui = drawGui(i.uv);
		fragColor = lerp(fragColor, gui, gui.a);
	}

	//fixed3 pos = load(_pos).xyz;
	fixed3 pos = load(_pos);
	pos = fixed3(ceil(pos.xy * 100), floor(pos.z * 100));
	pos += load(_pos2).xyz;
	pos += load(_pos3).xyz / 100;

	//if (bool(keyToggled(114))) {

	if (!_NoDebug) {
		if (bool(keyToggled(114)) || _F3 || renderScale.b > 0.5) {
			fixed2 startOffset = fixed2(164, 161);
			if (i.uv.x < 20.) fragColor.rgba = lerp(fragColor.rgba, pow(tex2D(_MainTex, i.uv / iResolution.xy), 0.454545).rgba, pow(tex2D(_MainTex, i.uv / iResolution.xy), 0.454545).a);
			fragColor = lerp(fragColor, fixed4(1, 1, 0, 1), PrintValue(i.uv, fixed2(0.0, 5.0), fixed2(8, 15), unity_DeltaTime.x, 4.0, 1.0));
			fragColor = lerp(fragColor, fixed4(1, 0, 1, 1), PrintValue(i.uv, fixed2(0.0, 25.0), fixed2(8, 15), load(_time).r, 6.0, 1.0));
			fragColor = lerp(fragColor, fixed2(1, .5).xyyx, PrintValue(i.uv, fixed2(10., iResolution.y - 20.), fixed2(8, 15), pos.x - startOffset.x, 4.0, 3.0));
			fragColor = lerp(fragColor, fixed2(1, .5).yxyx, PrintValue(i.uv, fixed2(10., iResolution.y - 40.), fixed2(8, 15), pos.y - startOffset.y, 4.0, 3.0));
			fragColor = lerp(fragColor, fixed2(1, .5).yyxx, PrintValue(i.uv, fixed2(10., iResolution.y - 60.), fixed2(8, 15), pos.z, 4.0, 3.0));
		}
	}
	if (!_NoCrosshair) {
		if (i.uv.x > ((iResolution.x / 2) - 1) &&
			i.uv.x < ((iResolution.x / 2) + 1) &&
			i.uv.y >((iResolution.y / 2) - 8) &&
			i.uv.y < ((iResolution.y / 2) + 8)) {
			fragColor = 1 - fragColor;
			fragColor *= 1.5;
		}
		else if (i.uv.x > ((iResolution.x / 2) - 8) &&
			i.uv.x < ((iResolution.x / 2) + 8) &&
			i.uv.y >((iResolution.y / 2) - 1) &&
			i.uv.y < ((iResolution.y / 2) + 1)) {
			fragColor = 1 - fragColor;
			fragColor *= 1.5;
		}
	}
	if (!_UIOnly) {
		fragColor.a = 1;
	}
	if (fragColor.b == -0.01) {
	fragColor = saturate(fragColor);
		clip(1 - i.uv.x);
	}
	return pow(fragColor, 2.2);
	}
	ENDCG
	}
  }
}

