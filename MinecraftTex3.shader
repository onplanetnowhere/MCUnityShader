
Shader "ShaderMan/MinecraftTex3"
	{

	Properties{
	_MainTex ("MainTex", 2D) = "white" {}
	_SecondTex("SecondTex", 2D) = "white" {}
	_ThirdTex("ThirdTex", 2D) = "white" {}
	}

		SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }

		Pass
	{
		//ZWrite Off
		//Blend SrcAlpha OneMinusSrcAlpha

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
sampler2D _ThirdTex;
sampler2D _SecondTex;
sampler2D _MainTex;
static const fixed2 iChannelResolution0 = fixed2(800, 450);
static const fixed2 iChannelResolution1 = fixed2(256, 256);
static const fixed2 iChannelResolution3 = fixed2(800, 450);

	#define var(name, x, y) static const fixed2 name = fixed2(x, y)
#define varRow 0.
var(_pos, 0, varRow);
var(_angle, 2, varRow);
var(_mouse, 3, varRow);
var(_loadRange, 4, varRow);
var(_inBlock, 5, varRow);
var(_vel, 6, varRow);
var(_pick, 7, varRow);
var(_pickTimer, 8, varRow);
var(_renderScale, 9, varRow);
var(_selectedInventory, 10, varRow);
var(_flightMode, 11, varRow);
var(_sprintMode, 12, varRow);
var(_time, 13, varRow);
var(_old, 0, 1);


fixed2 greaterThan2(fixed2 a, fixed2 b) {
	fixed2 result;
	result[0] = a[0] > b[0];
	result[1] = a[1] > b[1];
	return result;
}

fixed4 load(fixed2 coord) {
	return pow(tex2D(_MainTex, fixed2((floor(coord) + 0.5) / iChannelResolution0.xy)), 0.454545);
	//return tex2D(_MainTex, fixed2((floor(coord) + 0.5) / iChannelResolution[0].xy));
}


#define HASHSCALE1 .1031
#define HASHSCALE3 fixed3(.1031, .1030, .0973)
#define HASHSCALE4 fixed4(1031, .1030, .0973, .1099)

fixed4 noiseTex(fixed2 c) {
	return pow(tex2D(_SecondTex, c / iChannelResolution1.xy*2), 0.454545);
	//return tex2D(_SecondTex, c / iChannelResolution[1].xy);
}

fixed hash12(fixed2 p)
{
	fixed3 p3  = frac(p.xyx * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

fixed2 hash22(fixed2 p)
{
	fixed3 p3 = frac(p.xyx * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return frac(fixed2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

fixed signedx(fixed x) {
	return x * 2. - 1.;   
}


//From https://www.shadertoy.com/view/4djGRh
fixed tileableWorley(in fixed2 p, in fixed numCells)
{
	p *= numCells;
	fixed d = 1.0e10;
	for (int xo = -1; xo <= 1; xo++)
	{
		for (int yo = -1; yo <= 1; yo++)
		{
			fixed2 tp = floor(p) + fixed2(xo, yo);
			tp = p - tp - hash22(256. * fmod(tp, numCells));
			d = min(d, dot(tp, tp));
		}
	}
	return sqrt(d);
	//return 1.0 - d;// ...Bubbles.
}

fixed crackingAnimation(fixed2 p, fixed t) {
    t = ceil(t * 8.) / 8.;
	fixed d = 1.0e10;
    //t *= ;
    for (fixed i = 0.; i < 25.; i++) {
    	fixed2 tp = pow(tex2D(_SecondTex, fixed2(4, i) / 256.), 0.454545).xy - 0.5;
        tp *= max(0., (length(tp) + clamp(t, 0., 1.) - 1.) / length(tp));
        d = min(d, length(tp + 0.5 - p));
    }
    return pow(lerp(clamp(1. - d * 3., 0., 1.), 1., smoothstep(t - 0.3, t + 0.3, max(abs(p.x - 0.5), abs(p.y - 0.5)) * 2.)), .6) * 1.8 - 0.8;
}

fixed brickPattern(fixed2 c) {
	fixed o = 1.;
    if (fmod(c.y, 4.) < 1.) o = 0.;
	if (fmod(c.x - 4. * step(4., fmod(c.y, 8.)), 8.) > 7.) o = 0.;
	if (fmod(c.x + 4. * step(4., fmod(c.y, 8.)), 8.) > 7.) o = 0.;
    return o;
}
fixed woodPattern(fixed2 c) {
	fixed o = 1.;
    if (fmod(c.y, 4.) < 1.) o = 0.;
	if (fmod(c.x + 2. - 6. * step(4., fmod(c.y, 8.)), 16.) > 15.) o = 0.;
	if (fmod(c.x - 2. + 14. * step(4., fmod(c.y, 8.)), 16.) > 15.) o = 0.;
    return o;
}

//From https://github.com/hughsk/glsl-hsv2rgb
fixed3 hsv2rgb(fixed3 c) {
  fixed4 K = fixed4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  fixed3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

fixed4 getTexture(fixed id, fixed2 c) {
    fixed2 gridPos = fixed2(fmod(id, 16.), floor(id / 16.));
	return pow(tex2D(_ThirdTex, (c + gridPos * 16.) / iChannelResolution3.xy), 0.454545);
	//return tex2D(_ThirdTex, (c + gridPos * 16.) / iChannelResolution[3].xy);
}







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
	i.uv = floor(i.uv) + 0.5;

	fixed2 gridPos = floor(i.uv / 16.);
	fixed2 c = fmod(i.uv, 16.);
	int id = int(gridPos.x + gridPos.y * 16.);
	half4 fragColor = (0,0,0,0);
	fragColor.a = 1.;
	if (id == 0) {
		fragColor = fixed4(1, 0, 1, 1);
	}
	if (id == 1) {
		fixed noiseb = noiseTex(c * fixed2(.5, 1.) + fixed2(floor(hash12(c + fixed2(27, 19)) * 3. - 1.), 0.)).b;
		fragColor.rgb = 0.45 + 0.2 * fixed3(noiseb, noiseb, noiseb);
	}
	if (id == 2) {
		fragColor.rgb = fixed3(0.55, 0.4, 0.3) * (1. + 0.3 * signedx(noiseTex(c + 37.).r));
		if (hash12(c * 12.) > 0.95) fragColor.rgb = fixed3(0.4, 0.4, 0.4) + 0.2 * noiseTex(c + 92.).g;
	}
	if (id == 3) {
		fragColor.rgb = getTexture(2., c).rgb;
		if (noiseTex(fixed2(0, c.x) + 12.).a * 3. + 1. > 16. - c.y) fragColor.rgb = getTexture(4., c).rgb;
	}
	if (id == 4) {
		fragColor.rgb = hsv2rgb(fixed3(0.22, .8 - 0.3 * noiseTex(c + 47.).b, 0.6 + 0.1 * noiseTex(c + 47.).b));
	}
	if (id == 5) {
		fixed worley = clamp(pow(1. - tileableWorley(c / 16., 4.), 2.), 0.2, 0.6) + 0.2 * tileableWorley(c / 16., 5.);
		fragColor.rgb = fixed3(worley, worley, worley);
	}
	if (id == 6) {
		float w = 1. - tileableWorley(c / 16., 4.);
		float l = clamp(0.7 * pow(w, 4.) + 0.5 * w, 0., 1.);
		fragColor.rgb = lerp(fixed3(.3, .1, .05), fixed3(1, 1, .6), l);
		if (w < 0.2) fragColor.rgb = fixed3(0.3, 0.25, 0.05);
	}
	if (id == 7) {
		fragColor.rgb = -0.1 * hash12(c) + lerp(fixed3(.6, .3, .2) + 0.1 * (1. - brickPattern(c + fixed2(-1, 1)) * brickPattern(c)), fixed3(0.8,0.8,0.8), 1. - brickPattern(c));
	}
	if (id == 8) {
		fragColor.rgb = lerp(fixed3(1, 1, .2), fixed3(1, .8, .1), sin((c.x - c.y) / 3.) * .5 + .5);
		if (any(greaterThan2(abs(c - 8.), fixed2(7,7)))) fragColor.rgb = fixed3(1, .8, .1);
	}
	if (id == 9) {
		fixed thingx = floor(hash12(c + fixed2(27, 19)));
		fragColor.rgb = fixed3(0.5, 0.4, 0.25)*(0.5 + 0.5 * woodPattern(c)) * (1. + 0.2 * noiseTex(c * fixed2(.5, 1.) + fixed2(thingx, thingx) * 3. - 1.).b);
	}
	if (id == 16) {
		fragColor.rgb = (-1. + 2. * getTexture(1., c).rgb) * 2.5;
	}
	if (id == 32) {
		fixed loadanim = crackingAnimation(c / 16., load(_pickTimer).r);
		fragColor.rgb = fixed3(loadanim, loadanim, loadanim);
	}
	if (id == 48) {
		fragColor = fixed4(0.2, 0.2, 0.2, 0.7);
		fixed2 p = c - 8.;
		float d = max(abs(p.x), abs(p.y));
		if (d > 6.) {
			fragColor.rgb = fixed3(0.7, 0.7, 0.7);
			fragColor.rgb += 0.05 * hash12(c);
			fragColor.a = 1.;
			if ((d < 7. && p.x < 6.) || (p.x > 7. && abs(p.y) < 7.)) fragColor.rgb -= 0.3;
		}
		fragColor.rgb += 0.05 * hash12(c);

	}
	fragColor = saturate(fragColor);
	return pow(fragColor, 2.2);
	}
	ENDCG
	}
  }
}

