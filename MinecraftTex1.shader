
Shader "ShaderMan/MinecraftTex1"
	{

	Properties{
		_MainTex("MainTex", 2D) = "white" {}
	_SecondTex("SecondTex", 2D) = "white" {}
	_ThirdTex("ThirdTex", 2D) = "white" {}
	[Toggle] _Negate("Negate", float) = 0.0
	[Toggle] _Reset("Reset", float) = 0.0
		_iMouseX("MouseX", float) = 0.0
		_iMouseY("MouseY", float) = 0.0
		_iMouseZ("MouseZ", float) = 0.0
		_PosX("PosX", float) = 0.0
		_PosY("PosY", float) = 0.0
		_PosZ("PosZ", float) = 0.0
		_AngleX("AngleX", float) = 0.0
		_AngleY("AngleY", float) = 0.0
		_ResolutionScale("ResolutionScale", float) = 0.0
		_TimeScale("TimeScale", float) = 0.0
		[Toggle] _MouseDestroy("MouseDestroy", float) = 0.0
		[Toggle] _MousePlace("MousePlace", float) = 0.0
		[Toggle] _KeyForwards("KeyForwards", float) = 0.0
		[Toggle]_ViewpointMouse("ViewpointMouse", float) = 0.0
	}

		SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }

		Pass
	{
		//Source https://www.shadertoy.com/view/MtcGDH
		//ZWrite Off
		//Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM
#pragma target 3.0
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"

	struct VertexInput {
	fixed4 vertex : POSITION;
	fixed2 uv : TEXCOORD0;
	fixed4 tangent : TANGENT;
	fixed3 normal : NORMAL;
	//VertexInput
	};


	struct VertexOutput {
	fixed4 pos : SV_POSITION;
	fixed4 posWorld : TEXCOORD1;
	fixed2 uv : TEXCOORD0;
	//VertexOutput
	};
	 
	//Variables
sampler2D _ThirdTex;
sampler2D _SecondTex;
sampler2D _MainTex;
fixed _Negate, _Reset;
fixed _iMouseX, _iMouseY, _iMouseZ;
fixed _MouseDestroy, _MousePlace;
fixed _PosX, _PosY, _PosZ;
fixed _AngleX, _AngleY;
fixed _KeyForwards;
fixed _ResolutionScale, _TimeScale;
fixed _ViewpointMouse;
static const fixed4 _iMouse = fixed4(_iMouseX, _iMouseY, _iMouseZ, 0.0);
static const fixed2 iResolution = fixed2(800, 450);
static const fixed2 iChannelResolution0 = fixed2(1200, 675);

#define KEY_FORWARDS 87
#define KEY_BACKWARDS 83
#define KEY_LEFT 65
#define KEY_RIGHT 68
#define KEY_JUMP 32
#define KEY_SNEAK 16
#define KEY_SPRINT 17
#define KEY_PLACE 81
#define KEY_DESTROY 69
#define KEY_DECREASE_RESOLUTION 34
#define KEY_INCREASE_RESOLUTION 33
#define KEY_INCREASE_TIME_SCALE 80
#define KEY_DECREASE_TIME_SCALE 79
#define KEY_INVENTORY_NEXT 88
#define KEY_INVENTORY_PREVIOUS 90
#define KEY_INVENTORY_ABSOLUTE_START 49

#define KEY_MOUSE_UP 120
#define KEY_MOUSE_DOWN 121
#define KEY_MOUSE_LEFT 122
#define KEY_MOUSE_RIGHT 123
#define KEY_RESET 124
#define KEY_DEBUG 125
#define KEY_FLY 126
#define KEY_FAST_FORWARD 127
#define KEY_REWIND 128
#define KEY_LAND 129

#define KEY_PX 130
#define KEY_NX 131
#define KEY_PY 132
#define KEY_NY 133
#define KEY_PZ 134
#define KEY_NZ 135

static const fixed PI = 3.14159265359;
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

fixed2 lessThan2(fixed2 a, fixed2 b) {
	fixed2 result;
	result[0] = a[0] < b[0];
	result[1] = a[1] < b[1];
	return result;
}

fixed4 load(fixed2 coord) {
	if (_Negate) {
		return -pow(tex2Dlod(_MainTex, float4(fixed2((floor(coord) + 0.5) / iResolution.xy), 0.0, 0)), 0.454545);
	}
	//fixed dt = min(unity_DeltaTime.x, .05);
	//if (coord.y >= 1) { coord.y += 1 * dt; }
	return pow(tex2Dlod(_MainTex, float4(fixed2((floor(coord) + 0.5) / iResolution.xy), 0.0, 0)), 0.454545);
	//return tex2Dlod(_MainTex,float4(fixed2((floor(coord) + 0.5) / iChannelResolution[1].xy), 0.0,0));
}

bool inBox(fixed2 coord, fixed4 bounds) {
	return coord.x >= bounds.x && coord.y >= bounds.y && coord.x < (bounds.x + bounds.z) && coord.y < (bounds.y + bounds.w);
}

fixed2 currentCoord;
fixed4 outValue;
bool store4(fixed2 coord, fixed4 value) {
	if (inBox(currentCoord, fixed4(coord, 1., 1.))) {
		outValue = value;
		return true;
	}
	else return false;
}
bool store3(fixed2 coord, fixed3 value) { return store4(coord, fixed4(value, 1)); }
bool store2(fixed2 coord, fixed2 value) { return store4(coord, fixed4(value, 0, 1)); }
bool store1(fixed2 coord, fixed value) { return store4(coord, fixed4(value, 0, 0, 1)); }

fixed keyDown(int keyCode) {
	/*if (keyCode == KEY_FORWARDS && _KeyForwards) {
		return 256;
	}*/
	return pow(tex2Dlod(_ThirdTex,float4(fixed2((fixed(keyCode) + 0.5) / 256., .5 / 3.), 0.0,0)), 0.454545).r;
}

fixed keyPress(int keyCode) {
	return pow(tex2Dlod(_ThirdTex,float4(fixed2((fixed(keyCode) + 0.5) / 256., 1.5 / 3.), 0.0,0)), 0.454545).r;
}

fixed keySinglePress(int keycode) {
	bool now = bool(keyDown(keycode));
	bool previous = bool(pow(tex2Dlod(_MainTex, fixed4(fixed2(256. + fixed(keycode) + 0.5, 0.5) / iResolution.xy, 0.0, 0.0)), 0.454545).r);
	return fixed(now && !previous);
}

fixed keySingleRelease(int keycode) {
	bool now = bool(keyDown(keycode));
	bool previous = bool(pow(tex2Dlod(_MainTex, fixed4(fixed2(256. + fixed(keycode) + 0.5, 0.5) / iResolution.xy, 0.0, 0.0)), 0.454545).r);
	return fixed(!now && previous);
}

static const fixed2 packedChunkSize = fixed2(12,7);
static const fixed heightLimit = packedChunkSize.x * packedChunkSize.y;

/*fixed calcLoadDist(void) {
	fixed2 chunks = floor(iResolution.xy / packedChunkSize); //66, 64
	fixed gridSize = min(chunks.x, chunks.y); //64
	return floor((gridSize - 1.) / 2.); //31
}

fixed4 calcLoadRange(fixed2 pos) {
	fixed2 d = calcLoadDist() * fixed2(-1,1); //-31, 31
	return floor(pos).xxyy + d.xyxy; //-31 31 -31 31
}*/

fixed2 swizzleChunkCoord(fixed2 chunkCoord) {
	fixed2 c = chunkCoord;
	fixed dist = max(abs(c.x), abs(c.y));
	fixed2 c2 = floor(abs(c - 0.5));
	fixed offset = max(c2.x, c2.y);
	fixed neg = step(c.x + c.y, 0.) * -2. + 1.;
	return (neg * c) + offset;
}

fixed rectangleCollide(fixed2 p1, fixed2 p2, fixed2 s) {
	return fixed(all(lessThan2(abs(p1 - p2), s)));
}

fixed horizontalPlayerCollide(fixed2 p1, fixed2 p2, fixed h) {
	fixed2 s = (fixed2(1,1) + fixed2(.6, h)) / 2.;
	p2.y += h / 2.;
	return rectangleCollide(p1, p2, s);
}

fixed4 readMapTex(fixed2 pos) {
	return pow(tex2Dlod(_SecondTex, float4((floor(pos) + 0.5) / iChannelResolution0.xy, 0.0, 0)), 0.454545);
	//return tex2Dlod(_SecondTex,float4((floor(pos) + 0.5) / iChannelResolution[0].xy, 0.0,0));
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

voxel getVoxel(fixed3 p) {
	return decodeTextel(readMapTex(voxToTexCoord(p)));
}

bool getHit(fixed3 c) {
	fixed3 p = c + fixed3(0.5,0.5,0.5);
	fixed d = readMapTex(voxToTexCoord(p)).r;
	return d > 0.5;
}

struct rayCastResults {
	bool hit;
	fixed3 rayPos;
	fixed3 mapPos;
	fixed3 normal;
	fixed2 uv;
	fixed3 tangent;
	fixed3 bitangent;
	fixed dist;
};


rayCastResults rayCast(fixed3 rayPos, fixed3 rayDir, fixed3 offset) {
	fixed3 mapPos = floor(rayPos);
	fixed3 deltaDist = abs(fixed3(length(rayDir), length(rayDir), length(rayDir)) / rayDir);
	fixed3 rayStep = sign(rayDir);
	fixed3 sideDist = (sign(rayDir) * (mapPos - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist;
	fixed3 mask;
	bool hit = false;
	for (int i = 0; i < 9; i++) {
		mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
		sideDist += mask * deltaDist;
		mapPos += mask * rayStep;

		if (mapPos.z < 0. || mapPos.z >= packedChunkSize.x * packedChunkSize.y) break;
		if (getHit(mapPos - offset)) {
			hit = true;
			break;
		}

	}
	fixed3 endRayPos = rayDir / dot(mask * rayDir, fixed3(1,1,1)) * dot(mask * (mapPos + step(rayDir, fixed3(0,0,0)) - rayPos), fixed3(1,1,1)) + rayPos;
	fixed2 uv;
	fixed3 tangent1;
	fixed3 tangent2;
	if (abs(mask.x) > 0.) {
		uv = endRayPos.yz;
		tangent1 = fixed3(0,1,0);
		tangent2 = fixed3(0,0,1);
	}
	else if (abs(mask.y) > 0.) {
		uv = endRayPos.xz;
		tangent1 = fixed3(1,0,0);
		tangent2 = fixed3(0,0,1);
	}
	else {
		uv = endRayPos.xy;
		tangent1 = fixed3(1,0,0);
		tangent2 = fixed3(0,1,0);
	}
	uv = frac(uv);
	rayCastResults res;
	res.hit = hit;
	res.uv = uv;
	res.mapPos = mapPos;
	res.normal = -rayStep * mask;
	res.tangent = tangent1;
	res.bitangent = tangent2;
	res.rayPos = endRayPos;
	res.dist = length(rayPos - endRayPos);
	return res;
}






	VertexOutput vert(VertexInput v)
	{
	VertexOutput o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.uv = v.uv;
	//VertexFactory
	return o;
	}
	fixed4 frag(VertexOutput i) : SV_Target
	{
		VertexOutput j = i;
		i.uv.x *= 800;
	i.uv.y *= 450;
	//i.uv = ceil(i.uv);

	currentCoord = i.uv;
	fixed2 texCoord = floor(i.uv);
	half4 fragColor = half4(0,0,0,0);
	fixed3 viewFwd, viewRight;
	if (_ViewpointMouse) {
		viewRight = -UNITY_MATRIX_V[0].xzy;
		viewRight.z *= -1;
		viewFwd = UNITY_MATRIX_V[2].xzy;
		viewFwd.z *= -1;
	}
	if (texCoord.x < 512.) {
		if (texCoord.y == varRow) {
			if (texCoord.x >= 256.) {
				fragColor.r = pow(tex2D(_ThirdTex, (i.uv - 256.) / fixed2(256, 3)), 0.454545).r;
				fixed4 old = pow(tex2D(_MainTex, (_old + i.uv) / iResolution.xy), 0.454545);
				if (fragColor.r != old.r) old.a = 0.;
				fragColor.a = old.a + unity_DeltaTime.x;
			}
			else {
				fixed3 pos = load(_pos);
				pos = fixed3(ceil(pos.xy * 100), floor(pos.z * 100));
				pos += load(_pos2).xyz;
				pos += load(_pos3).xyz / 100;
				fixed3 oldPos = pos;
				fixed3 offset = fixed3(floor(pos.xy), 0.);
				fixed2 angle = load(_angle).xy;
				fixed4 oldMouse = load(_mouse);
				fixed3 vel = ceil(load(_vel).xyz*10000)/10000-100;
				fixed4 mouse = _iMouse / length(iResolution.xy);
				fixed3 renderScale = load(_renderScale).rgb;
				renderScale.g = 0.;
				fixed2 time = load(_time).rg;
				fixed3 flightMode = load(_flightMode).rgb;
				fixed4 sprintMode = load(_sprintMode);
				float selected = load(_selectedInventory).r;
				float dt = min(unity_DeltaTime.x, .05);

				if (int(_Time.y / unity_DeltaTime.x) == 0 || _Reset || keySinglePress(KEY_RESET)) {
					//pos = fixed3(0, 0, 52);
					//pos = fixed3(32, 32, 52);
					//pos = fixed3(228.5, 225.5, 54);
					if (_ViewpointMouse) {
						pos = fixed3(abs(_SinTime.y * 400) + 228.5, abs(_CosTime.z * 400) + 225.5, 60);
					}
					else {
						pos = fixed3(228.5, 225.5, 48);
					}
					pos.xy -= 64;
					//angle = fixed2(-0.75, 2.5);
					angle = fixed2(PI/4, 1.62);
					oldMouse = fixed4(-1,-1,-1,-1);
					vel = fixed3(0,0,0);
					renderScale = fixed3(0.,1.,0.);
					time = fixed2(0, 3);
					selected = 0.;
					flightMode.rgb = fixed3(0., 0.3, 25);
					sprintMode = fixed4(0, 0, 1, 1);
				}
				/*if (oldMouse.z > 0. && _iMouse.z > 0.) {
					angle += 5.*(mouse.xy - oldMouse.xy) * fixed2(-1, -1);
					angle.y = clamp(angle.y, 0.1, PI - 0.1);
				}*/
				fixed3 dir = fixed3(sin(angle.y) * cos(angle.x), sin(angle.y) * sin(angle.x), cos(angle.y));
				fixed3 dirU = fixed3(normalize(fixed2(dir.y, -dir.x)), 0);
				fixed3 dirV = cross(dirU, dir);
				fixed3 move = fixed3(0,0,0);

				fixed3 dirFwd, dirRight, dirUp;
				if (_ViewpointMouse) {
					dirFwd = normalize(fixed3(viewFwd.xy, 0));
					dirRight = normalize(fixed3(viewRight.xy, 0));
					dirUp = fixed3(0, 0, 1);
				}
				else {
					dirFwd = fixed3(cos(angle.x), sin(angle.x), 0);
					dirRight = fixed3(dirFwd.y, -dirFwd.x, 0);
					dirUp = fixed3(0, 0, 1);
				}
				/*move += dir * (keyDown(87)-keyDown(83));
				move += dirU * (keyDown(68) - keyDown(65));
				move += fixed3(0,0,1) * (keyDown(82) - keyDown(70));*/

				float inBlock = 0.;
				float minHeight = 0.;
				fixed3 vColPos, hColPos;
				for (float i = 0.; i < 4.; i++) {
					vColPos = fixed3(floor(pos.xy - 0.5), floor(pos.z - 1. - i));
					if (getVoxel(vColPos - offset + fixed3(0, 0, 0)).id * rectangleCollide(vColPos.xy + fixed2(0.5, 0.5), pos.xy, fixed2(.8, .8))
						+ getVoxel(vColPos - offset + fixed3(0, 1, 0)).id * rectangleCollide(vColPos.xy + fixed2(0.5, 1.5), pos.xy, fixed2(.8, .8))
						+ getVoxel(vColPos - offset + fixed3(1, 0, 0)).id * rectangleCollide(vColPos.xy + fixed2(1.5, 0.5), pos.xy, fixed2(.8, .8))
						+ getVoxel(vColPos - offset + fixed3(1, 1, 0)).id * rectangleCollide(vColPos.xy + fixed2(1.5, 1.5), pos.xy, fixed2(.8, .8))
				> .5) {
						minHeight = vColPos.z + 1.001;
						inBlock = 1.;
						break;
					}
				}
				float maxHeight = heightLimit - 1.8;
				vColPos = fixed3(floor(pos.xy - 0.5), floor(pos.z + 1.8 + 1.));
				if (getVoxel(vColPos - offset + fixed3(0, 0, 0)).id * rectangleCollide(vColPos.xy + fixed2(0.5, 0.5), pos.xy, fixed2(.8, .8))
					+ getVoxel(vColPos - offset + fixed3(0, 1, 0)).id * rectangleCollide(vColPos.xy + fixed2(0.5, 1.5), pos.xy, fixed2(.8, .8))
					+ getVoxel(vColPos - offset + fixed3(1, 0, 0)).id * rectangleCollide(vColPos.xy + fixed2(1.5, 0.5), pos.xy, fixed2(.8, .8))
					+ getVoxel(vColPos - offset + fixed3(1, 1, 0)).id * rectangleCollide(vColPos.xy + fixed2(1.5, 1.5), pos.xy, fixed2(.8, .8))
					> .5) {
					maxHeight = vColPos.z - 1.8 - .001;
					inBlock = 1.;
				}
				float minX = pos.x - 1000.;
				hColPos = fixed3(floor(pos.xy - fixed2(.3, .5)) + fixed2(-1, 0), floor(pos.z));
				if (getVoxel(hColPos - offset + fixed3(0, 0, 0)).id * horizontalPlayerCollide(hColPos.yz + fixed2(0.5, 0.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 1, 0)).id * horizontalPlayerCollide(hColPos.yz + fixed2(1.5, 0.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 1)).id * horizontalPlayerCollide(hColPos.yz + fixed2(0.5, 1.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 1, 1)).id * horizontalPlayerCollide(hColPos.yz + fixed2(1.5, 1.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 2)).id * horizontalPlayerCollide(hColPos.yz + fixed2(0.5, 2.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 1, 2)).id * horizontalPlayerCollide(hColPos.yz + fixed2(1.5, 2.5), pos.yz, 1.8)
					> .5) {
					minX = hColPos.x + 1.301;
				}
				float maxX = pos.x + 1000.;
				hColPos = fixed3(floor(pos.xy - fixed2(-.3, .5)) + fixed2(1, 0), floor(pos.z));
				if (getVoxel(hColPos - offset + fixed3(0, 0, 0)).id * horizontalPlayerCollide(hColPos.yz + fixed2(0.5, 0.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 1, 0)).id * horizontalPlayerCollide(hColPos.yz + fixed2(1.5, 0.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 1)).id * horizontalPlayerCollide(hColPos.yz + fixed2(0.5, 1.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 1, 1)).id * horizontalPlayerCollide(hColPos.yz + fixed2(1.5, 1.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 2)).id * horizontalPlayerCollide(hColPos.yz + fixed2(0.5, 2.5), pos.yz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 1, 2)).id * horizontalPlayerCollide(hColPos.yz + fixed2(1.5, 2.5), pos.yz, 1.8)
					> .5) {
					maxX = hColPos.x - .301;
				}
				float minY = pos.y - 1000.;
				hColPos = fixed3(floor(pos.xy - fixed2(.5, .3)) + fixed2(0, -1), floor(pos.z));
				if (getVoxel(hColPos - offset + fixed3(0, 0, 0)).id * horizontalPlayerCollide(hColPos.xz + fixed2(0.5, 0.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(1, 0, 0)).id * horizontalPlayerCollide(hColPos.xz + fixed2(1.5, 0.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 1)).id * horizontalPlayerCollide(hColPos.xz + fixed2(0.5, 1.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(1, 0, 1)).id * horizontalPlayerCollide(hColPos.xz + fixed2(1.5, 1.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 2)).id * horizontalPlayerCollide(hColPos.xz + fixed2(0.5, 2.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(1, 0, 2)).id * horizontalPlayerCollide(hColPos.xz + fixed2(1.5, 2.5), pos.xz, 1.8)
					> .5) {
					minY = hColPos.y + 1.301;
				}
				float maxY = pos.y + 1000.;
				hColPos = fixed3(floor(pos.xy - fixed2(.5, -.3)) + fixed2(0, 1), floor(pos.z));
				if (getVoxel(hColPos - offset + fixed3(0, 0, 0)).id * horizontalPlayerCollide(hColPos.xz + fixed2(0.5, 0.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(1, 0, 0)).id * horizontalPlayerCollide(hColPos.xz + fixed2(1.5, 0.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 1)).id * horizontalPlayerCollide(hColPos.xz + fixed2(0.5, 1.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(1, 0, 1)).id * horizontalPlayerCollide(hColPos.xz + fixed2(1.5, 1.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(0, 0, 2)).id * horizontalPlayerCollide(hColPos.xz + fixed2(0.5, 2.5), pos.xz, 1.8)
					+ getVoxel(hColPos - offset + fixed3(1, 0, 2)).id * horizontalPlayerCollide(hColPos.xz + fixed2(1.5, 2.5), pos.xz, 1.8)
					> .5) {
					maxY = hColPos.y - .301;
				}

				if (abs(pos.z - minHeight) < 0.01) flightMode.rb = fixed2(0., 25.);
				if (bool(keySinglePress(KEY_JUMP))) {
					if (flightMode.g > 0.) {
						flightMode.r = 1. - flightMode.r;
						sprintMode.r = 0.;
					}
					flightMode.g = 0.3;
				}
				if (bool(keyDown(KEY_FLY)) ||
					keyDown(KEY_PX) || 
					keyDown(KEY_NX) || 
					keyDown(KEY_PY) || 
					keyDown(KEY_NY) || 
					keyDown(KEY_PZ) || 
					keyDown(KEY_NZ)) {
					if (flightMode.g > 0.) {
						flightMode.r = 1.;
						sprintMode.r = 0.;
					}
					if (flightMode.b > 0) {
						pos.z += flightMode.b*0.001;
						flightMode.b -= 1;
					}
					flightMode.g = 0.3;
				}
				else if (bool(keyDown(KEY_LAND))) {
					flightMode.r = 0.;
					flightMode.g = 0.3;
					flightMode.b = 25;
				}
				flightMode.g = max(flightMode.g - dt, 0.);

				if (bool(keyDown(KEY_SPRINT))) {
					if (sprintMode.g > 0.) sprintMode.r = 1.;
					sprintMode.g = 0.3;
				}
				if (bool(keySinglePress(KEY_FORWARDS))) {
					if (sprintMode.g > 0.) sprintMode.r = 1.;
					sprintMode.g = 0.3;
				}
				if (!bool(keyDown(KEY_FORWARDS))) {
					if (sprintMode.g <= 0.) sprintMode.r = 0.;
				}
				sprintMode.g = max(sprintMode.g - dt, 0.);
				/*if (bool(keySinglePress(KEY_FORWARDS))) {
					if (sprintMode.g > 0.) sprintMode.r = 1.;
					sprintMode.g = 0.3;
				}
				if (!bool(keyDown(KEY_FORWARDS))) {
					if (sprintMode.g <= 0.) sprintMode.r = 0.;
				}
				sprintMode.g = max(sprintMode.g - dt, 0.);*/
				sprintMode.b = 1;
				sprintMode.a = 1;
				fixed sprintAdjust = 0;
				if (bool(flightMode.r)) {
					if (length(vel) > 0.) vel -= min(length(vel), 35. * dt) * normalize(vel);
					//vel += 50. * dt * dirFwd * sign(keyDown(KEY_FORWARDS) - keyDown(KEY_BACKWARDS) + keyDown(38) - keyDown(40));
					//vel += 50. * dt * dirRight * sign(keyDown(KEY_RIGHT) - keyDown(KEY_LEFT) + keyDown(39) - keyDown(37));
					vel += 50. * dt * dirFwd * sign(keyDown(KEY_FORWARDS) - keyDown(KEY_BACKWARDS));
					vel += 50. * dt * dirRight * sign(keyDown(KEY_RIGHT) - keyDown(KEY_LEFT));
					vel += 50. * dt * dirUp * sign(keyDown(KEY_JUMP) - keyDown(KEY_SNEAK));
					if (keyDown(KEY_JUMP) && keyDown(KEY_SNEAK)) {
						vel.xy *= 0.925;
					}
					if (length(vel.xy) > 17.) vel.xy = normalize(vel.xy) * 17.;
					if (length(vel.z) > 10.) vel.z = normalize(vel.z) * 10.;
					//pos.z += 0.0000000481032*pos.z*pos.z + 0.00000059377*pos.z + 0.000031022;
				}
				else {
					vel.xy *= max(0., (length(vel.xy) - 25. * dt) / length(vel.xy));
					//vel += 50. * dt * dirFwd * sign(keyDown(KEY_FORWARDS) - keyDown(KEY_BACKWARDS) + keyDown(38) - keyDown(40));
					vel += 50. * dt * dirFwd * sign(keyDown(KEY_FORWARDS) - keyDown(KEY_BACKWARDS));
					if (bool(keyDown(KEY_FORWARDS))) { sprintAdjust = 1; }
					if (bool(keyDown(KEY_BACKWARDS))) { sprintAdjust = 0; }
					//else if (sprintAdjust == 0 && sprintMode.b > 1) { sprintMode.b -= 1; }
					vel += 50. * dt * dirFwd * 0.4 * sprintMode.r * sprintAdjust;
					//vel += 50. * dt * dirRight * sign(keyDown(KEY_RIGHT) - keyDown(KEY_LEFT) + keyDown(39) - keyDown(37));
					vel += 50. * dt * dirRight * sign(keyDown(KEY_RIGHT) - keyDown(KEY_LEFT));
					if (abs(pos.z - minHeight) < 0.01) {
						vel.z = 9. * keyDown(32);
					}
					else {
						vel.z -= 32. * dt;
						vel.z = clamp(vel.z, -80., 30.);
					}
					if (length(vel.xy) > 4.317 * (1. + 0.4 * sprintMode.r * sprintAdjust)) vel.xy = normalize(vel.xy) * 4.317 * (1. + 0.4 * sprintMode.r * sprintAdjust);

					if (keyDown(KEY_SNEAK)) {
						vel.xy *= 0.3;
						sprintMode.a = 0;
					}
				}
				// Sprint start/end timer
				fixed speed = 0;
				speed = sqrt(vel.x * vel.x + vel.y * vel.y);
				sprintMode.b = ceil(load(_sprintMode).b);
				if (sprintAdjust > 0 && keyDown(KEY_SPRINT) && !keyDown(KEY_SNEAK) && sprintMode.b <= 6 && speed > 5) { sprintMode.b += 1; }
				else if (sprintMode.b > 1) { sprintMode.b -= 1; }
				if (sprintMode.b > 6) { sprintMode.b = 6; }

				
				pos += dt * vel;
				//pos.z += 0.00025;
				/*fixed3 oldpos = floor(load(_old + _pos));
				if ((pos.x % 1) == 0 && oldpos.x < pos.x) { pos.x += 1; }
				if ((pos.x % 1) == 0 && oldpos.x > pos.x) { pos.x -= 1; }*/
				//fixed2 posxy2 = pos.xy*pos.xy;
				//fixed2 posxy3 = posxy2 * pos.xy;
				//pos.xy += -0.00000000000002161367475*posxy3 + 0.0000000006645322269*posxy2 + 0.000007276335783*pos.xy - 0.0005216917708;
				//pos.xy += -0.00000000000302161367475*posxy3 + 0.0000000015645322269*posxy2 + 0.000009276335783*pos.xy - 0.0007216917708;
				//pos.xy += (-0.00000000000302161367475*posxy3 + 0.0000000015645322269*posxy2 + 0.000009276335783*pos.xy - 0.0007216917708) / 4.25;
				
				if (pos.z < minHeight) {
					pos.z = minHeight;
					vel.z = 0.;
				}
				if (pos.z > maxHeight) {
					pos.z = maxHeight;
					vel.z = 0.;
				}
				if (pos.x < minX) {
					pos.x = minX;
					vel.x = 0.;
				}
				if (pos.x > maxX) {
					pos.x = maxX;
					vel.x = 0.;
				}
				if (pos.y < minY) {
					pos.y = minY;
					vel.y = 0.;
				}
				if (pos.y > maxY) {
					pos.y = maxY;
					vel.y = 0.;
				}

				// NoClip
				fixed posSpeed = 50 * dt;
				//fixed posSpeed = 0.01;
				if (keyDown(KEY_PX)) {
					pos.x += posSpeed;
				}
				else if (keyDown(KEY_NX)) {
					pos.x -= posSpeed;
				}
				if (keyDown(KEY_PY)) {
					pos.y += posSpeed;
				}
				else if (keyDown(KEY_NY)) {
					pos.y -= posSpeed;
				}
				if (keyDown(KEY_PZ)) {
					pos.z += posSpeed/4;
				}
				else if (keyDown(KEY_NZ)) {
					pos.z -= posSpeed/4;
				}

				pos += fixed3(_PosX, _PosY, _PosZ);

				float timer = load(_old + _pickTimer).r;
				fixed4 oldPick = load(_old + _pick);
				oldPick = fixed4(ceil(oldPick.rg * 100), floor(oldPick.b * 100), oldPick.a);
				oldPick.rgb += load(_old + _pick2).rgb;
				oldPick.rgb += load(_old + _pick3).rgb / 100;
				fixed4 pick;
				if (_iMouse.z > 0.) {
					fixed3 cameraDir = fixed3(sin(angle.y) * cos(angle.x), sin(angle.y) * sin(angle.x), cos(angle.y));
					fixed3 cameraPlaneU = fixed3(normalize(fixed2(cameraDir.y, -cameraDir.x)), 0);
					fixed3 cameraPlaneV = cross(cameraPlaneU, cameraDir) * iResolution.y / iResolution.x;
					fixed2 screenPos = _iMouse.xy / iResolution.xy * 2.0 - 1.0;
					fixed3 rayDir = cameraDir + screenPos.x * cameraPlaneU + screenPos.y * cameraPlaneV;
					if (_ViewpointMouse) {
						rayDir = viewFwd;
					}
					rayDir = normalize(rayDir);
					rayCastResults res = rayCast(pos + fixed3(0, 0, 1.6), rayDir, offset);
					if (res.dist <= 5.) {
						pick.xyz = res.mapPos;
						//pick.xy += fixed2(64,64);
						pick.a = 0;
						if (keyDown(KEY_DESTROY) || _MouseDestroy) {
							pick.a = 1.;
							store1(fixed2(0, 9), pick.a);
							timer += dt / 0.25;
						}
						else if (keySinglePress(KEY_PLACE) || _MousePlace) {
							pick.a = 2.;
							timer += dt / 0.3;
							pick.xyz += res.normal;
						}
						pick = floor(pick);
						oldPick = ceil(oldPick);
						if (oldPick.x != pick.x || oldPick.y != pick.y || oldPick.z != pick.z || oldPick.w != pick.w) timer = 0.;
					}
					else {
						//pick = fixed4(-1, -1, -1, 0);
						pick = fixed4(0, 0, 0, 0);
						timer = 0.;
					}
				}
				else {
					//pick = fixed4(-1, -1, -1, 0);
					pick = fixed4(0, 0, 0, 0);
					timer = 0.;
				}
				static const int numItems = 8;
				//selected += keyPress(KEY_INVENTORY_NEXT) - keyPress(KEY_INVENTORY_PREVIOUS);
				selected = ceil(selected);
				selected += keySinglePress(KEY_INVENTORY_NEXT) - keySinglePress(KEY_INVENTORY_PREVIOUS);
				if (selected < -0.5) { selected = 7; }
				if (selected > 7) { selected = 0; }
				for (int i = 0; i < 9; i++) {
					if (bool(keyPress(KEY_INVENTORY_ABSOLUTE_START + i))) selected = float(i);
				}
				selected = fmod(selected, float(numItems));

				renderScale.r = clamp(renderScale.r + keySinglePress(KEY_DECREASE_RESOLUTION) - keySinglePress(KEY_INCREASE_RESOLUTION), 0., 4.);
				if (_ResolutionScale > 0) {
					renderScale.r = _ResolutionScale;
				}
				time.g = clamp(time.g + keySinglePress(KEY_INCREASE_TIME_SCALE) - keyPress(KEY_DECREASE_TIME_SCALE), 0., 8.);
				time.r = fmod2(time.r + dt * sign(time.g) * pow(2., time.g - 1.), 1200.);

				/*fixed posScaleX = 0;
				fixed posScaleY = 0;
				if (pos.x != 0) {
					//posScaleX = (0.00000375*(pos.x - 32) / ((pos.x - 32)/ (pos.x/10) * 250));
					posScaleX = 1;
				}
				if (pos.y != 0) {
					posScaleY = (0.00000375*pos.y / 2500);
				}
				pos.x *= 1.00000375 + posScaleX;
				pos.y *= 1.00000375 + posScaleY;*/
				//Negative Check TEMP
				if (pos.x < 31) { pos.x = 31.0; }
				if (pos.y < 31) { pos.y = 31.0; }
				if (pos.z < 0) { pos.z = 0.0; }
				if (pos.z > 82) { pos.z = 82.0; }
				fixed timeSpeed = 0.03;
				if (keyDown(KEY_FAST_FORWARD)) {
					time.g += timeSpeed;
				}
				else if (keyDown(KEY_REWIND)) {
					time.g -= timeSpeed;
					if (time.g < 0.01) { time.g = 0.01; }
				}
				//pos = fixed3(0 + _Time.y % 2, 0, 0);
				fixed mouseSpeed = 1.25 * dt;
				if (keyDown(KEY_MOUSE_UP)) {
					angle.y -= mouseSpeed;
				}
				else if (keyDown(KEY_MOUSE_DOWN)) {
					angle.y += mouseSpeed;
				}
				if (keyDown(KEY_MOUSE_LEFT)) {
					angle.x += mouseSpeed;
				}
				else if (keyDown(KEY_MOUSE_RIGHT)) {
					angle.x -= mouseSpeed;
				}
				angle += fixed2(_AngleX, _AngleY);
				if (angle.y > PI) { angle.y = PI; }
				if (angle.y < 0.01) { angle.y = 0.01; }
				angle.x %= (2 * PI);
				if (angle.x < 0) {
					angle.x += (2 * PI);
				}
				/*if (angle.y < 0) {
					angle.y += (2 * PI);
				}*/
				if (_ViewpointMouse) {
					//angle.x = PI / 1.5;
					angle.x = 0;
					angle.y = PI / 2;
				}
				if (keySinglePress(KEY_DEBUG)) {
					renderScale.b = 1. - renderScale.b;
				}
				fixed3 posx = floor(pos) / 100;
				fixed3 pos2x = floor((pos % 1) * 100) / 100;
				fixed3 pos3x = floor(((pos * 100) % 1) * 100) / 100;
				fixed4 pickx = fixed4(floor(pick.rgb) / 100, pick.a);
				fixed4 pick2x = fixed4(floor((pick.rgb % 1) * 100) / 100, pick.a);
				fixed4 pick3x = fixed4(floor(((pick.rgb * 100) % 1) * 100) / 100, pick.a);
				store3(_pos, posx);
				store3(_pos2, pos2x);
				store3(_pos3, pos3x);
				store2(_angle, angle);
				//store4(_loadRange, calcLoadRange(pos.xy));
				store4(_mouse, mouse);
				store1(_inBlock, inBlock);
				store3(_vel, vel+100);
				store4(_pick, pickx);
				store4(_pick2, pick2x);
				store4(_pick3, pick3x);
				store1(_pickTimer, timer);
				store3(_renderScale, renderScale);
				store1(_selectedInventory, selected);
				store3(_flightMode, flightMode);
				store4(_sprintMode, sprintMode);
				store2(_time, time);
				fragColor = outValue;
			}
		}
		else fragColor = pow(tex2D(_MainTex, (i.uv - _old) / iResolution.xy),0.454545);
	}
	else fragColor.rgb = fixed3(0, 0, 0);
	//fragColor = saturate(fragColor);
	/*
	if (i.uv.y > 40) {
		half4 testColor = pow(tex2D(_MainTex, (i.uv - _old) / iResolution.xy), 0.454545);
		if (testColor.r > 1000) {
			testColor.r = 1003;
			testColor.g = 1000;
			testColor.ba = 0;
			fragColor.rgb = testColor;
		}
		else {
			fragColor.rgb = fixed3(1001, 0, 0);
		}
		//fragColor.rgb = float3(1, 0, 0);
		//fragColor.rgb = testColor*256;
	}*/
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

