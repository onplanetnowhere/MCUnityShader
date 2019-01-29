
Shader "ShaderMan/MinecraftTex2"
{

	Properties{
		_MainTex("MainTex", 2D) = "white" {}
	_SecondTex("SecondTex", 2D) = "white" {}
	[Toggle] _Negate("Negate", float) = 0.0
	[Toggle] _Reset("Reset", float) = 0.0
		[Toggle] _Unlit("Unlit", float) = 0.0
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
sampler2D _SecondTex;
sampler2D _MainTex;
fixed _Negate, _Reset, _Unlit;
static const fixed2 iResolution = fixed2(1200, 675);
static const fixed2 iChannelResolution0 = fixed2(800, 450);

	#define var(name, x, y) static const fixed2 name = fixed2(x, y)
#define varRow 0.
var(_pos, 0, varRow);
var(_pos2, 1, varRow);
var(_pos3, 14, varRow);
var(_angle, 2, varRow);
var(_mouse, 3, varRow);
//var(_loadRange, 4, varRow);
var(_inBlock, 5, varRow);
var(_vel, 6, varRow);
var(_pick, 7, varRow);
var(_pick2, 15, varRow);
var(_pick3, 16, varRow);
var(_pickTimer, 8, varRow);
var(_renderScale, 9, varRow);
var(_selectedInventory, 10, varRow);
var(_flightMode, 11, varRow);
var(_sprintMode, 12, varRow);
var(_time, 13, varRow);
var(_old, 0, 1);

bool isNan(float val)
{
	return (val <= 0.0 || 0.0 <= val) ? false : true;
}

fixed fmod2(fixed x, fixed y) {
	fixed result = abs(fmod(x, y));
	if (y < 0) {
		result *= -1;
	}
	return result;
}

fixed4 load(fixed2 coord) {
	return pow(tex2D(_MainTex, fixed2((floor(coord) + 0.5) / iChannelResolution0.xy)), 0.454545);
	//return tex2D(_MainTex, fixed2((floor(coord) + 0.5) / iChannelResolution[0].xy));
}

#define HASHSCALE1 .1031
#define HASHSCALE3 fixed3(.1031, .1030, .0973)
#define HASHSCALE4 fixed4(1031, .1030, .0973, .1099)

fixed hash13(fixed3 p3)
{
	p3  = frac(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

fixed3 hash33(fixed3 p3)
{
	p3 = frac(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return frac(fixed3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

fixed4 hash44(fixed4 p4)
{
	p4 = frac(p4  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return frac(fixed4((p4.x + p4.y)*p4.z, (p4.x + p4.z)*p4.y, (p4.y + p4.z)*p4.w, (p4.z + p4.w)*p4.x));
}

//
// Description : Array and tex2Dless GLSL 2D,3D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastfmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
//
fixed2 fmod289(fixed2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
fixed3 fmod289(fixed3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

fixed4 fmod289(fixed4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
fixed3 permute(fixed3 x) {
  return fmod289(((x*34.0)+1.0)*x);
}
fixed4 permute(fixed4 x) {
     return fmod289(((x*34.0)+1.0)*x);
}
fixed4 taylorInvSqrt(fixed4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

fixed snoise(fixed3 v)
  { 
  static const fixed2  C = fixed2(1.0/6.0, 1.0/3.0) ;
  static const fixed4  D = fixed4(0.0, 0.5, 1.0, 2.0);

// First corner
  fixed3 i  = floor(v + dot(v, C.yyy) );
  fixed3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  fixed3 g = step(x0.yzx, x0.xyz);
  fixed3 l = 1.0 - g;
  fixed3 i1 = min( g.xyz, l.zxy );
  fixed3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  fixed3 x1 = x0 - i1 + C.xxx;
  fixed3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  fixed3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = fmod289(i); 
  fixed4 p = permute( permute( permute( 
             i.z + fixed4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + fixed4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + fixed4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  fixed n_ = 0.142857142857; // 1.0/7.0
  fixed3  ns = n_ * D.wyz - D.xzx;

  fixed4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  fmod2(p,7*7)

  fixed4 x_ = floor(j * ns.z);
  fixed4 y_ = floor(j - 7.0 * x_ );    // fmod2(j,N)

  fixed4 x = x_ *ns.x + ns.yyyy;
  fixed4 y = y_ *ns.x + ns.yyyy;
  fixed4 h = 1.0 - abs(x) - abs(y);

  fixed4 b0 = fixed4( x.xy, y.xy );
  fixed4 b1 = fixed4( x.zw, y.zw );

  //fixed4 s0 = fixed4(lessThan(b0,0.0))*2.0 - 1.0;
  //fixed4 s1 = fixed4(lessThan(b1,0.0))*2.0 - 1.0;
  fixed4 s0 = floor(b0)*2.0 + 1.0;
  fixed4 s1 = floor(b1)*2.0 + 1.0;
  fixed4 sh = -step(h, fixed4(0.0,0.0,0.0,0.0));

  fixed4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  fixed4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  fixed3 p0 = fixed3(a0.xy,h.x);
  fixed3 p1 = fixed3(a0.zw,h.y);
  fixed3 p2 = fixed3(a1.xy,h.z);
  fixed3 p3 = fixed3(a1.zw,h.w);

//Normalise gradients
  fixed4 norm = taylorInvSqrt(fixed4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  fixed4 m = max(0.6 - fixed4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, fixed4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}
fixed snoise(fixed2 v)
  {
  static const fixed4 C = fixed4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  fixed2 i  = floor(v + dot(v, C.yy) );
  fixed2 x0 = v -   i + dot(i, C.xx);

// Other corners
  fixed2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? fixed2(1.0, 0.0) : fixed2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  fixed4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = fmod289(i); // Avoid truncation effects in permutation
  fixed3 p = permute( permute( i.y + fixed3(0.0, i1.y, 1.0 ))
		+ i.x + fixed3(0.0, i1.x, 1.0 ));

  fixed3 m = max(0.5 - fixed3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  fixed3 x = 2.0 * frac(p * C.www) - 1.0;
  fixed3 h = abs(x) - 0.5;
  fixed3 ox = floor(x + 0.5);
  fixed3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  fixed3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}


static const fixed2 packedChunkSize = fixed2(12,7);
static const fixed heightLimit = packedChunkSize.x * packedChunkSize.y;

fixed2 unswizzleChunkCoord(fixed2 storageCoord) {
 	fixed2 s = floor(storageCoord);
    fixed dist = max(s.x, s.y);
    fixed offset = floor(dist / 2.);
    fixed neg = step(0.5, fmod(dist, 2.)) * 2. - 1.;
    return neg * (s - offset);
}

fixed2 swizzleChunkCoord(fixed2 chunkCoord) {
    fixed2 c = chunkCoord;
    fixed dist = max(abs(c.x), abs(c.y));
    fixed2 c2 = floor(abs(c - 0.5));
    fixed offset = max(c2.x, c2.y);
    fixed neg = step(c.x + c.y, 0.) * -2. + 1.;
    return (neg * c) + offset;
}

/*fixed calcLoadRange(void) {
	fixed2 chunks = floor(iResolution.xy / packedChunkSize);
    fixed gridSize = min(chunks.x, chunks.y);
    return floor((gridSize - 1.) / 2.);
}*/

fixed calcLoadDist(void) {
	fixed2 chunks = floor(iResolution.xy / packedChunkSize); //66, 64
	fixed gridSize = min(chunks.x, chunks.y); //64
	return floor((gridSize - 1.) / 2.); //31
}

fixed4 calcLoadRange(fixed2 pos) {
	fixed2 d = calcLoadDist() * fixed2(-1, 1); //-31, 31
	return floor(pos).xxyy + d.xyxy; //-31 31 -31 31
}


fixed4 readMapTex(fixed2 pos) {
	if (_Negate) {
		return pow(tex2D(_SecondTex, (floor(pos) + 0.5) / iResolution.xy), 0.454545);
	}
	return pow(tex2D(_SecondTex, (floor(pos) + 0.5) / iResolution.xy), 0.454545);
 	//return tex2D(_SecondTex, (floor(pos) + 0.5) / iChannelResolution[0].xy);   
}

fixed3 texToVoxCoord(fixed2 textelCoord, fixed3 offset) {
	fixed3 voxelCoord = offset;
    voxelCoord.xy += unswizzleChunkCoord(textelCoord / packedChunkSize);
    voxelCoord.z += fmod(textelCoord.x, packedChunkSize.x) + packedChunkSize.x * fmod(textelCoord.y, packedChunkSize.y);
    return voxelCoord;
}

fixed2 voxToTexCoord(fixed3 voxCoord) {
    fixed3 p = floor(voxCoord);
    return swizzleChunkCoord(p.xy) * packedChunkSize + fixed2(fmod(p.z, packedChunkSize.x), floor(p.z / packedChunkSize.x));
}

struct voxel {
	fixed id;
    fixed sunlight;
    fixed torchlight;
    fixed hue;
};

voxel decodeTextel(fixed4 textel) {
	voxel o;
    o.id = textel.r;
    o.sunlight = floor(fmod(textel.g, 16.));
    o.torchlight = floor(fmod(textel.g / 16., 16.));
    o.hue = textel.b;
    return o;
}

fixed4 encodeVoxel(voxel v) {
	fixed4 o;
    o.r = v.id;
    o.g = clamp(floor(v.sunlight), 0., 15.) + 16. * clamp(floor(v.torchlight), 0., 15.);
    o.b = v.hue;
    o.a = 1.;
    return o;
}

bool inRange(fixed2 p, fixed4 r) {
	return (p.x > r.x && p.x < r.y && p.y > r.z && p.y < r.w);
}

voxel getVoxel(fixed3 p) {
    return decodeTextel(readMapTex(voxToTexCoord(p)));
}

bool overworld(fixed3 p) {
	fixed density = 48. - p.z;
    density += lerp(0., 40., pow(.5 + .5 * snoise(p.xy /557. + fixed2(0.576, .492)), 2.)) * snoise(p / 31.51 + fixed3(0.981, .245, .497));
    return density > 0.;
}

fixed getInventory(fixed slot) {
	return slot + 1. + step(2.5, slot);  
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
		i.uv.x *= 1200;
	i.uv.y *= 675;
	//i.uv = ceil(i.uv);

	fixed2 textelCoord = floor(i.uv);
	fixed3 pos = load(_pos);
	pos = fixed3(ceil(pos.xy * 100), floor(pos.z * 100));
	pos += load(_pos2).xyz;
	pos += load(_pos3).xyz / 100;
	fixed3 offset = fixed3(pos.xy, 0.);
	fixed3 oldpos = load(_old + _pos);
	oldpos = fixed3(ceil(oldpos.xy * 100), floor(oldpos.z * 100));
	oldpos += load(_old + _pos2).xyz;
	oldpos += load(_old + _pos3).xyz / 100;
	fixed3 oldOffset = fixed3(oldpos.xy, 0.);
	fixed2 startOffset = fixed2(64, 64);
	offset.xy += startOffset;
	oldOffset.xy += startOffset;
	//fixed3 vel = oldOffset - offset;
	//fixed correction = 0.0121;
	//fixed correction = 0.0011;
	//2300 0.019
	//1800 0.015
	//1200 0.009
	//770 0.007
	//250 0.003
	//150 0.0018
	//70 0.0015
	//0 0.0011
	//-50 0.001
	/*fixed2 cOffset = offset.xy + fixed2(-228, -225);
	fixed2 correction = 0.0000000007465127*cOffset*cOffset + 0.000002518519002*cOffset + 0.00085043712;
	oldOffset.xy += correction;*/
	/*if (oldOffset.x > offset.x) {
		oldOffset.x += correction;
	}
	if (oldOffset.y > offset.y) {
		oldOffset.y += correction;
	}
	if (oldOffset.x < offset.x) {
		oldOffset.x += correction;
	}
	if (oldOffset.y < offset.y) {
		oldOffset.y += correction;
	}*/
	/*if (vel.x < velmin && oldOffset.x > offset.x) {
		oldOffset.x -= correction;
	}
	if (vel.y < velmin && oldOffset.y > offset.y) {
		oldOffset.y -= correction;
	}
	if (vel.x < velmin && oldOffset.x < offset.x) {
		oldOffset.x += correction;
	}
	if (vel.y < velmin && oldOffset.y < offset.y) {
		oldOffset.y += correction;
	}*/
	offset = floor(offset);
	oldOffset = floor(oldOffset);
	fixed3 voxelCoord = texToVoxCoord(textelCoord, offset);

	voxel vox;
	//fixed4 range = load(_old + _loadRange);
	fixed4 range = calcLoadRange(oldpos.xy);
	range.xy += startOffset;
	range.zw += startOffset;
	/*range.xy = offset.xx;
	range.zw = offset.yy;
	range.xz -= fixed2(31, 31);
	range.yw += fixed2(31, 31);*/
	fixed4 pick = load(_pick);
	pick = fixed4(ceil(pick.rg * 100), floor(pick.b * 100), pick.a);
	pick.rgb += load(_pick2).rgb;
	pick.rgb += load(_pick3).rgb / 100;
	pick.rg += startOffset;
	pick = ceil(pick);
	if (!inRange(voxelCoord.xy, range) || int(_Time.y / unity_DeltaTime.x) == 0 || _Reset || load(_renderScale).g > 0) {
		bool solid = overworld(voxelCoord);
		if (solid) {
			vox.id = 3.;
			if (overworld(voxelCoord + fixed3(0, 0, 1))) vox.id = 2.;
			if (overworld(voxelCoord + fixed3(0, 0, 3))) vox.id = 1.;
			if (hash13(voxelCoord) > 0.98 && !overworld(voxelCoord + fixed3(0, 0, -1))) vox.id = 6.;
		}
		if (snoise(voxelCoord / 27.99 + fixed3(0.981, .245, .497).yzx * 17.) > 1. - (smoothstep(0., 5., voxelCoord.z) - 0.7 * smoothstep(32., 48., voxelCoord.z))) vox.id = 0.;
		if (voxelCoord.z < 1.) vox.id = 16.;
		vox.hue = frac(hash13(voxelCoord));
		vox.sunlight = 0.;
		vox.torchlight = 0.;
	}
	else {
		fixed3 vcoord = voxelCoord - oldOffset;
		/*fixed3 temppos = fixed3(load(_pos).xy, 0.);
		fixed3 tempoldpos = fixed3(load(_old + _pos).xy, 0.);
		fixed fix = 0.0175;
		if ((temppos.x % 1 > (1 - fix) || temppos.x % 1 == 0) && tempoldpos.x > temppos.x) {
			vcoord.x -= 1;
		}
		if ((temppos.y % 1 > (1 - fix) || temppos.y % 1 == 0) && tempoldpos.y > temppos.y) {
			vcoord.y -= 1;
		}
		if (temppos.x % 1 < (0 + fix) && tempoldpos.x < temppos.x) {
			vcoord.x += 1;
		}
		if (temppos.y % 1 < (0 + fix) && tempoldpos.y < temppos.y) {
			vcoord.y += 1;
		}*/
		vcoord = floor(vcoord);
		vox = getVoxel(vcoord);
	}
	if (voxelCoord.x < 234.5 - startOffset.x || voxelCoord.y < 234.5 - startOffset.y) vox.id = 16.;
	voxelCoord = floor(voxelCoord);
	//if (abs(voxelCoord.x-164-64) >= 994) { _Unlit = true;	}

	vox.id = ceil(vox.id);
	if (voxelCoord.x == pick.x && voxelCoord.y == pick.y && voxelCoord.z == pick.z) {
		if (pick.a == 1. && load(_pickTimer).r > 1. && vox.id != 16.) vox.id = 0.;
		else if (pick.a == 2.) vox.id = getInventory(load(_selectedInventory).r);
	}

	voxel temp;
	if (voxelCoord.z >= heightLimit - 1.) {
		vox.sunlight = 15.;
	}
	else vox.sunlight = 0.;
	vox.torchlight = 0.;
	//if (length(voxelCoord + .5 - load(_pos).xyz) < 1.) vox.torchlight = 15.;
	if (voxelCoord.z < heightLimit - 1.) {
		temp = getVoxel(voxelCoord + fixed3(0, 0, 1) - oldOffset);									
		vox.sunlight = max(vox.sunlight, temp.sunlight);
		vox.torchlight = max(vox.torchlight, temp.torchlight - 1);
	}
	if (voxelCoord.z > 1.) {
		temp = getVoxel(voxelCoord + fixed3(0, 0, -1) - oldOffset);
		vox.sunlight = max(vox.sunlight, temp.sunlight - 1);
		vox.torchlight = max(vox.torchlight, temp.torchlight - 1);
	}
	if (voxelCoord.x > range.x + 1.) {
		temp = getVoxel(voxelCoord + fixed3(-1, 0, 0) - oldOffset);
		vox.sunlight = max(vox.sunlight, temp.sunlight - 1);
		vox.torchlight = max(vox.torchlight, temp.torchlight - 1);
	}
	if (voxelCoord.x < range.y - 1.) {
		temp = getVoxel(voxelCoord + fixed3(1, 0, 0) - oldOffset);
		vox.sunlight = max(vox.sunlight, temp.sunlight - 1);
		vox.torchlight = max(vox.torchlight, temp.torchlight - 1);
	}
	if (voxelCoord.y > range.z + 1.) {
		temp = getVoxel(voxelCoord + fixed3(0, -1, 0) - oldOffset);
		vox.sunlight = max(vox.sunlight, temp.sunlight - 1);
		vox.torchlight = max(vox.torchlight, temp.torchlight - 1);
	}
	if (voxelCoord.y < range.w - 1.) {
		temp = getVoxel(voxelCoord + fixed3(0, 1, 0) - oldOffset);
		vox.sunlight = max(vox.sunlight, temp.sunlight - 1);
		vox.torchlight = max(vox.torchlight, temp.torchlight - 1);
	}

	if (vox.id > 0.) {
		vox.sunlight = 0.;
		vox.torchlight = 0.;
	}

	if (ceil(vox.id) == 6.) {
		vox.torchlight = 15.;
	}
	/*if (_Unlit) {
		vox.sunlight = 15.; //test
		vox.torchlight = 15.; //test
	}*/
	vox.sunlight += 1;
	half4 fragColor = encodeVoxel(vox);
	//fragColor = saturate(fragColor);
	fragColor = pow(fragColor, 2.2);
	if (_Negate) {
		fragColor *= -1;
	}
	return fragColor;
	}
	ENDCG
	}
  }
}

