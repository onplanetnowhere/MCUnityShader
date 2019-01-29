
Shader "ShaderMan/MinecraftTex4ScreenSpace"
	{

	Properties{
	_MainTex ("MainTex", 2D) = "white" {}
	_SecondTex("SecondTex", 2D) = "white" {}
	_ThirdTex("ThirdTex", 2D) = "white" {}
	_FOVScale("FOVScale", float) = 1.0
		[Toggle]_Stereo("Stereo", float) = 0.0
		[Toggle]_Pano("Pano", float) = 0.0
		//_TestVar("TestVar", float) = 0.0
	}

	SubShader
	{
	Tags { "Queue" = "Overlay"
	"IgnoreProjector" = "True" }

	Pass
	{
	//ZWrite Off
	//Blend SrcAlpha OneMinusSrcAlpha
	ZTest Off
	//ZTest Always

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
	fixed4 posWorld : TEXCOORD1;
	fixed2 uv:TEXCOORD0;
	float eye : EYE;
	//VertexOutput
	};

	//Variables
sampler2D _ThirdTex;
sampler2D _SecondTex;
sampler2D _MainTex;
fixed _FOVScale;
//fixed _TestVar;
fixed _Stereo, _Pano;
static const fixed2 iResolution = fixed2(1200, 675);
static const fixed2 iChannelResolution0 = fixed2(800, 450);
static const fixed2 iChannelResolution2 = fixed2(1200, 675);
static const fixed2 iChannelResolution3 = fixed2(800, 450);

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

fixed3 rotateX(fixed3 rayDir, fixed angle) {
	float3x3 rotMatX = float3x3(
		1, 0, 0,
		0, cos(angle), -sin(angle),
		0, sin(angle), cos(angle));
	return mul(rayDir, rotMatX);
}

fixed3 rotateY(fixed3 rayDir, fixed angle) {
	float3x3 rotMatY = float3x3(
		cos(angle), 0, -sin(angle),
		0, 1, 0,
		sin(angle), 0, cos(angle));
	return mul(rayDir, rotMatY);
}

fixed3 rotateZ(fixed3 rayDir, fixed angle) {
	float3x3 rotMatZ = float3x3(
		cos(angle), sin(angle), 0,
		-sin(angle), cos(angle), 0,
		0, 0, 1);
	return mul(rayDir, rotMatZ);
}

fixed fmod2(fixed x, fixed y) {
	fixed result = abs(fmod(x, y));
	if (y < 0) {
		result *= -1;
	}
	return result;
}

fixed2 greaterThan2(fixed2 a, fixed2 b) {
	fixed2 result;
	result[0] = a[0] > b[0];
	result[1] = a[1] > b[1];
	return result;
}

fixed4 load(fixed2 coord) {
	return pow(tex2Dlod(_MainTex, float4(fixed2((floor(coord) + 0.5) / iChannelResolution0.xy), 0.0, 0)), 0.454545);
	//return tex2Dlod(_MainTex,float4( fixed2((floor(coord) + 0.5) / iChannelResolution[0].xy), 0.0,0));
}

fixed2 unswizzleChunkCoord(fixed2 storageCoord) {
 	fixed2 s = storageCoord;
    fixed dist = max(s.x, s.y);
    fixed offset = floor(dist / 2.);
    fixed neg = step(0.5, fmod2(dist, 2.)) * 2. - 1.;
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


static const fixed2 packedChunkSize = fixed2(12,7);

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
	return pow(tex2Dlod(_SecondTex, float4((floor(pos) + 0.5) / iChannelResolution2.xy, 0.0, 0)), 0.454545);
 	//return tex2Dlod(_SecondTex,float4( (floor(pos) + 0.5) / iChannelResolution[0].xy, 0.0,0));   
}

fixed2 voxToTexCoord(fixed3 p) {
 	p = floor(p);
    return swizzleChunkCoord(p.xy) * packedChunkSize + fixed2(fmod2(p.z, packedChunkSize.x), floor(p.z / packedChunkSize.x));
}

bool getHit(fixed3 c) {
	fixed3 p = c + fixed3(0.5,0.5,0.5);
	fixed d = readMapTex(voxToTexCoord(p)).r;
	return d > 0.5;
}

fixed2 rotate2d(fixed2 v, fixed a) {
	fixed sinA = sin(a);
	fixed cosA = cos(a);
	return fixed2(v.x * cosA - v.y * sinA, v.y * cosA + v.x * sinA);	
}

//From https://github.com/hughsk/glsl-hsv2rgb
fixed3 hsv2rgb(fixed3 c) {
  fixed4 K = fixed4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  fixed3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

fixed4 getTexture(fixed id, fixed2 c) {
    fixed2 gridPos = fixed2(fmod2(id, 16.), floor(id / 16.));
	return pow(tex2Dlod(_ThirdTex, float4(16. * (c + gridPos) / iChannelResolution3.xy, 0.0, 0)), 0.454545);
	//return tex2Dlod(_ThirdTex,float4( 16. * (c + gridPos) / iChannelResolution[3].xy, 0.0,0));
}


bool inRange(fixed2 p, fixed4 r) {
	return (p.x > r.x && p.x < r.y && p.y > r.z && p.y < r.w);
}

struct voxel {
	fixed id;
    fixed2 light;
    fixed hue;
};

voxel decodeTextel(fixed4 textel) {
	voxel o;
    o.id = textel.r;
    o.light.x = floor(fmod2(textel.g, 16.)) + 3;
    o.light.y = floor(fmod2(textel.g / 16., 16.)) + 3;
    o.hue = textel.b;
    return o;
}

voxel getVoxel(fixed3 p) {
    return decodeTextel(readMapTex(voxToTexCoord(p)));
}

fixed2 max24(fixed2 a, fixed2 b, fixed2 c, fixed2 d) {
	return max(max(a, b), max(c, d));   
}

fixed lightLevelCurve(fixed t) {
    t = fmod2(t, 1200.);
	return 1. - ( smoothstep(400., 700., t) - smoothstep(900., 1200., t));
}

fixed3 lightmap(fixed2 light) {
    light = 15. - light;
    return clamp(lerp(fixed3(0,0,0), lerp(fixed3(0.11, 0.11, 0.21), fixed3(1,1,1), lightLevelCurve(load(_time).r)), pow(.8, light.x)) + lerp(fixed3(0,0,0), fixed3(1.3, 1.15, 1), pow(.75, light.y)), 0., 1.);   
}

fixed vertexAo(fixed side1, fixed side2, fixed corner) {
	return 1. - (side1 + side2 + max(corner, side1 * side2)) / 5.0;
}

fixed opaque(fixed id) {
	return id > .5 ? 1. : 0.;   
}

fixed3 calcLightingFancy(fixed3 r, fixed3 s, fixed3 t, fixed2 uv) {
	voxel v1, v2, v3, v4, v5, v6, v7, v8, v9;
    //uv = (floor(uv * 16.) + .5) / 16.;
    v1 = getVoxel(r - s + t);
    v2 = getVoxel(r + t);
    v3 = getVoxel(r + s + t);
    v4 = getVoxel(r - s);
    v5 = getVoxel(r);
    v6 = getVoxel(r + s);
    v7 = getVoxel(r - s - t);
    v8 = getVoxel(r - t);
    v9 = getVoxel(r + s - t);
    
    //return fixed3(uv, 0.) - .5 * opaque(v6.id);
    
    fixed2 light1, light2, light3, light4, light;
    light1 = max24(v1.light, v2.light, v4.light, v5.light);
    light2 = max24(v2.light, v3.light, v5.light, v6.light);
    light3 = max24(v4.light, v5.light, v7.light, v8.light);
    light4 = max24(v5.light, v6.light, v8.light, v9.light);
    
    fixed ao1, ao2, ao3, ao4, ao;
    ao1 = vertexAo(opaque(v2.id), opaque(v4.id), opaque(v1.id));
    ao2 = vertexAo(opaque(v2.id), opaque(v6.id), opaque(v3.id));
    ao3 = vertexAo(opaque(v8.id), opaque(v4.id), opaque(v7.id));
    ao4 = vertexAo(opaque(v8.id), opaque(v6.id), opaque(v9.id));
    
    light = lerp(lerp(light3, light4, uv.x), lerp(light1, light2, uv.x), uv.y);
    ao = lerp(lerp(ao3, ao4, uv.x), lerp(ao1, ao2, uv.x), uv.y);
    
    return lightmap(light) * pow(ao, 1. / 1.);
}

fixed3 calcLightingFast(fixed3 r, fixed3 s, fixed3 t, fixed2 uv) {
    return lightmap(min(getVoxel(r).light + 0.2, 15.));
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

rayCastResults rayCast(fixed3 rayPos, fixed3 rayDir, fixed3 offset, fixed4 range) {
	fixed3 mapPos = floor(rayPos);
    fixed3 deltaDist = abs(fixed3(length(rayDir), length(rayDir), length(rayDir)) / rayDir);
    fixed3 rayStep = sign(rayDir);
    fixed3 sideDist = (sign(rayDir) * (mapPos - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist; 
    fixed3 mask;
    bool hit = false;
    for (int i = 0; i < 384; i++) {
		mask = step(sideDist.xyz, sideDist.yzx) * step(sideDist.xyz, sideDist.zxy);
		sideDist += mask * deltaDist;
		mapPos += mask * rayStep;
		
        if (!inRange(mapPos.xy, range) || mapPos.z < 0. || mapPos.z >= packedChunkSize.x * packedChunkSize.y) break;
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
	

fixed3 skyColor(fixed3 rayDir) {
    fixed t = load(_time).r;
    fixed lightLevel = lightLevelCurve(t);
    fixed sunAngle = (t * PI * 2. / 1200.) + PI / 4.;
    fixed3 sunDir = fixed3(cos(sunAngle), 0, sin(sunAngle));
    
    fixed3 daySkyColor = fixed3(.5,.75,1);
    fixed3 dayHorizonColor = fixed3(0.8,0.8,0.9);
    fixed3 nightSkyColor = fixed3(0.1,0.1,0.2) / 2.;
    
    fixed3 skyColor = lerp(nightSkyColor, daySkyColor, lightLevel);
    fixed3 horizonColor = lerp(nightSkyColor, dayHorizonColor, lightLevel);
	//fixed sunVis = smoothstep(.99, 0.995, dot(sunDir, rayDir));
	//fixed moonVis = smoothstep(.999, 0.9995, dot(-sunDir, rayDir));
	fixed sunRange = 0.01;
	fixed sunVis = 0;
	fixed moonVis = 0;
	for (int x = -5; x <= 5; x++) {
		for (int y = -5; y <= 5; y++) {
			fixed3 sunDir2 = sunDir;
			sunDir2.z += cos(PI - sunAngle) * sunRange * x;
			sunDir2.x += sin(sunAngle) * sunRange * x;
			sunDir2.y += sunRange * y;
			sunDir2 = normalize(sunDir2);
			sunVis += smoothstep(0.9993, 0.9999, dot(sunDir2, rayDir));
			if (abs(x) < 2 && abs(y) < 2) {
				moonVis += smoothstep(.9992, 0.9995, dot(-sunDir2, rayDir));
			}
		}
	}
	moonVis = saturate(moonVis);
	sunVis = saturate(sunVis / 4);
    return lerp(lerp(lerp(horizonColor, skyColor, clamp(dot(rayDir, fixed3(0,0,1)), 0., 1.)), fixed3(1,1,0.95), sunVis), fixed3(0.6,0.6,0.6), moonVis);
    
}





	VertexOutput vert (VertexInput v)
	{
	VertexOutput o;
	o.pos = UnityObjectToClipPos (v.vertex);
	o.uv = v.uv;
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.eye = 0;
	if (unity_StereoEyeIndex != 0 && _Stereo)
	{
		o.eye = 1;
	}
	//VertexFactory
	return o;
	}
	fixed4 frag(VertexOutput i) : SV_Target
	{

		i.uv.x *= 1200;
	i.uv.y *= 675;
	//i.uv = ceil(i.uv);

    fixed scaleFactor = pow(sqrt(2.), load(_renderScale).r);
    fixed2 renderResolution = ceil(iResolution.xy / scaleFactor);
	half4 fragColor = (0,0,0,0);
	if (any(greaterThan2(i.uv, renderResolution))) {
		fragColor = fixed4(0, 0, 0, 0);
		return fragColor;
	}
	fixed2 screenPos = (i.uv.xy / renderResolution.xy) * 2.0 - 1.0;
	fixed3 pos = load(_pos);
	pos = fixed3(ceil(pos.xy * 100), floor(pos.z * 100));
	pos += load(_pos2).xyz;
	pos += load(_pos3).xyz / 100;
	fixed3 rayPos = pos.xyz + fixed3(0, 0, 1.6);
	fixed2 angle = load(_angle).xy;
	// View bobbing
	fixed3 flightMode = load(_flightMode).rgb;
	fixed2 sprintMode = ceil(load(_sprintMode).ba);
	fixed moveTimer = sprintMode.x;
	fixed moveType = sprintMode.y;
	fixed fovScale = _FOVScale;
	fixed3 rightVector, forwardsVector;
	if (moveType != 0) {
		fixed3 vel = load(_vel).xyz - 100;
		fixed speed = sqrt(vel.x * vel.x + vel.y * vel.y);
		fixed3 oldvel = load(10 * _old + _vel).xyz - 100;
		// Sprinting FOV
		if (moveType != 0) {
			//if (speed > 0.2) { speed = 1; }
			fixed speedScale = 1 + (moveTimer - 1) * (1 + sin((moveTimer - 2) / (5 / PI))) / 80;
			//speedScale = speedScale*(1 + speed / 50) / speedScale;
			if (speedScale < 1) { speedScale = 1; }
			fovScale *= speedScale;
		}
		// Bobbing
		if (!bool(flightMode.r)) {
			if (vel.x > 1) { vel.x = 1; }
			if (vel.y > 1) { vel.y = 1; }
			fixed zadjust = max(abs(vel.z), abs(oldvel.z));
			if (zadjust > 1) { zadjust = 1; }
			fixed bob = sin(_Time.y * 14);
			fixed bobAdjust = speed / 24;
			if (bobAdjust > 0.05) { bobAdjust = 0.05; }
			bob *= bobAdjust;
			bob -= zadjust * bob;
			rayPos.z += bob * sin(angle.y);
			bob = sin(_Time.y * 7);
			bob *= speed / 48;
			bob -= zadjust * bob;
			fixed bobAngleX = angle.x - PI / 2;
			rayPos.x -= bob * cos(bobAngleX);
			rayPos.y -= bob * sin(bobAngleX);
		}
	}
	if (moveType == 0) {
		// Sneaking
		rayPos.z -= 0.125;
	}
	//fixed4 range = load(_loadRange);
	fixed4 range = calcLoadRange(pos);
	fixed3 cameraDir = fixed3(sin(angle.y) * cos(angle.x), sin(angle.y) * sin(angle.x), cos(angle.y));

	fixed3 cameraPlaneU = fixed3(normalize(fixed2(cameraDir.y, -cameraDir.x)), 0);
	fixed3 cameraPlaneV = cross(cameraPlaneU, cameraDir) * renderResolution.y / renderResolution.x;
	fixed2 iuv = (i.uv.xy / iResolution) - 0.5;
	iuv /= (1 / (fovScale * 2 - 2));
	fixed3 rayDir;
	if (!_Pano) {
		rayDir = normalize(cameraDir + (screenPos.x + iuv.x) * cameraPlaneU + (screenPos.y + iuv.y) * cameraPlaneV);
	}
	else
	{
		// Pano Rotation
		fixed3 viewFwd = UNITY_MATRIX_V[2].xzy;
		viewFwd = (fovScale - 1) * viewFwd;
		rayDir = normalize(normalize(_WorldSpaceCameraPos.xzy - i.posWorld.xzy) - viewFwd);
		rayDir.z *= -1;
		rayDir = rotateY(rayDir, angle.y - PI / 2); // up & down
		rayDir = rotateZ(rayDir, angle.x); // left & right
		if (_Stereo) {
			fixed ipd = 0.02;
			//fixed eyeAngle = 0.05;
			if (i.eye != 0) {
				ipd *= -1;
				//eyeAngle *= -1;
			}
			// Stereo IPD Position
			rightVector = UNITY_MATRIX_V[0].xzy;
			rightVector = rotateY(rightVector, PI / 2 - angle.y);
			rightVector = rotateZ(rightVector, angle.x);
			rightVector.z *= -1;
			rayPos += rightVector * ipd;

			//rayDir = rotateX(rayDir, -cos(_TestVar)*rightVector);
			//rayDir = rotateY(rayDir, -sin(_TestVar)*rightVector);
			//rayDir = rotateZ(rayDir, rightVector*_TestVar);
			//rayDir = normalize(mul(rayDir, rightVector*_TestVar));
			/*fixed4x4 rotatedUnityMatrixTMV = mul(UNITY_MATRIX_T_MV, -UNITY_MATRIX_T_MV);
			fixed3x3 rotatedUnityMatrixTMV3 = fixed3x3(
				UNITY_MATRIX_T_MV[0][0], UNITY_MATRIX_T_MV[0][1], UNITY_MATRIX_T_MV[0][2],
				UNITY_MATRIX_T_MV[1][0], UNITY_MATRIX_T_MV[1][1], UNITY_MATRIX_T_MV[1][2],
				UNITY_MATRIX_T_MV[2][0], UNITY_MATRIX_T_MV[2][1], UNITY_MATRIX_T_MV[2][2]
			);
			rotatedUnityMatrixTMV3 = fixed3x3(
				rotateY(rotatedUnityMatrixTMV3[0], -PI/2),
				rotateY(rotatedUnityMatrixTMV3[1], -PI/2),
				rotateY(rotatedUnityMatrixTMV3[2], -PI/2)
			);*/
			//rayDir = normalize(mul(rayDir, rotatedUnityMatrixTMV3));
			//rayDir = normalize(rayDir + UNITY_MATRIX_V[0].xzy);
		}

		//rayDir = rotateY(rayDir, asin(rightVector.z / rightVector.x) / _TestVar); // up & down
		//rayDir = rotateZ(rayDir, asin(rightVector.y / rightVector.x) / _TestVar); // left & right
	}

	if (_Stereo && !_Pano) {
		fixed eyeAdjust = 0;
		fixed ipd = 0.2;
		fixed eyeAngle = 0.05;
		if (i.eye == 0) {
			eyeAdjust += ipd;
			angle.x += eyeAngle;
		}
		else {
			eyeAdjust -= ipd;
			angle.x -= eyeAngle;
		}
		fixed offsetAngleX = angle.x - PI / 2;
		rayPos.x -= eyeAdjust * cos(offsetAngleX);
		rayPos.y -= eyeAdjust * sin(offsetAngleX);
	}
	fixed3 mapPos = fixed3(floor(rayPos));
	fixed3 offset = fixed3(floor(pos.xy), 0.);
	fixed3 deltaDist = abs(fixed3(length(rayDir), length(rayDir), length(rayDir)) / rayDir);
	/*fixed3 newoffset = fixed3((load(_pos).xy), 0.);
	fixed3 oldoffset = fixed3((load(_old + _pos).xy), 0.);
	if (newoffset.x % 1 == 0 && oldoffset.x < newoffset.x) {
		offset.x -= 1;
		mapPos.x -= 1;
	}
	if (newoffset.x % 1 == 0 && oldoffset.x > newoffset.x) {
		offset.x += 1;
		mapPos.x += 1;
	}
	if (newoffset.y % 1 == 0 && oldoffset.y < newoffset.y) {
		offset.y -= 1;
		mapPos.y -= 1;
	}
	if (newoffset.y % 1 == 0 && oldoffset.y > newoffset.y) {
		offset.y += 1;
		mapPos.y += 1;
	}*/

	fixed3 rayStep = fixed3(sign(rayDir));

	fixed3 sideDist = (sign(rayDir) * (fixed3(mapPos) - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist;

	fixed3 mask;

	mapPos;

	rayCastResults res = rayCast(rayPos, rayDir, offset, range);

	fixed3 color = fixed3(0, 0, 0);
	voxel vox = getVoxel(res.mapPos - offset);
	if (res.hit) {

		color = calcLightingFancy(res.mapPos - offset + res.normal, res.tangent, res.bitangent, res.uv);
		//color *= hsv2rgb(fixed3(getVoxel(mapPos + .5 - offset).hue, .1, 1));
		float textureId = ceil(vox.id);							
		if (textureId == 3.) textureId += res.normal.z;
		color *= getTexture(textureId, res.uv).rgb;
		fixed4 pick = load(_pick);
		pick = fixed4(ceil(pick.rg * 100), floor(pick.b * 100), pick.a);
		pick.rgb += load(_pick2).rgb;
		pick.rgb += load(_pick3).rgb / 100;
		pick = ceil(pick);
		res.mapPos = ceil(res.mapPos);
		if (res.mapPos.x == pick.x && res.mapPos.y == pick.y && res.mapPos.z == pick.z) {
			if (pick.a == 1.) color *= getTexture(32., res.uv).r;
			else color = lerp(color, fixed3(1,1,1), 0.2);
		}
		//color.rgb = res.uv.xyx;
	}
	//else color = lerp(lightmap(fixed2(0)) / 2., skyColor(rayDir), vox.light.s / 15.);
	else color = skyColor(rayDir);
	fragColor.rgb = pow(color, fixed3(1,1,1));
	//fragColor = saturate(fragColor);
	return pow(fragColor, 2.2);
    
	}
	ENDCG
	}
  }
}

