
Shader "ShaderMan/Keyboard"
	{


	Properties{
		_MainTex("MainTex", 2D) = "white" {}
	_SecondTex("SecondTex", 2D) = "white" {}
	_ThirdTex("ThirdTex", 2D) = "white" {}
	[Toggle] _Reset("Reset",float) = 0.0
	}

	SubShader
	{
	Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

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
	sampler2D _MainTex;
	sampler2D _SecondTex;
	sampler2D _ThirdTex;
fixed _Reset;

static const fixed2 iChannelResolution0 = fixed2(256, 3);
static const fixed2 iChannelResolution1 = fixed2(800, 450);
static const fixed2 iChannelResolution2 = fixed2(800, 450);
static const fixed iChannel1Scale = 21;
static const fixed iChannel2Scale = 21;
#define var(name, x, y) static const fixed2 name = fixed2(x, y)
#define varRow 0.
var(_button1, 49, varRow);
var(_button2, 50, varRow);
var(_button3, 51, varRow);
var(_button4, 52, varRow);
var(_button5, 53, varRow);
var(_button6, 54, varRow);
var(_button7, 55, varRow);
var(_button8, 56, varRow);
var(_buttonW, 87, varRow);
var(_buttonS, 83, varRow);
var(_buttonA, 65, varRow);
var(_buttonD, 68, varRow);
var(_buttonspace, 32, varRow);
var(_buttonshift, 16, varRow);
var(_buttonsprint, 17, varRow);
var(_buttonf3, 114, varRow);
var(_buttonQ, 81, varRow);
var(_buttonE, 69, varRow);
//var(_buttonO, 79, varRow);
//var(_buttonP, 80, varRow);
var(_buttoninvnext, 88, varRow);
var(_buttoninvprev, 90, varRow);
var(_buttonmouseUp, 120, varRow);
var(_buttonmouseDown, 121, varRow);
var(_buttonmouseLeft, 122, varRow);
var(_buttonmouseRight, 123, varRow);
var(_buttonreset, 124, varRow);
var(_buttondebug, 125, varRow);
var(_buttonfly, 126, varRow);
var(_buttonfastforward, 127, varRow);
var(_buttonrewind, 128, varRow);
var(_buttonland, 129, varRow);
var(_buttonpx, 130, varRow);
var(_buttonnx, 131, varRow);
var(_buttonpy, 132, varRow);
var(_buttonny, 133, varRow);
var(_buttonpz, 134, varRow);
var(_buttonnz, 135, varRow);
var(_old, 0, 1);

//-400+58/2+x
//225-58/2-y
#define control(name, x, y, z, w) static const fixed4 name = fixed4(x, y, z, w)
control(_c1, 24, 25, 58, 58);
control(_c2, 123, 25, 58, 58);
control(_c3, 222, 25, 58, 58);
control(_c4, 321, 25, 58, 58);
control(_c5, 420, 25, 58, 58);
control(_c6, 519, 25, 58, 58);
control(_c7, 619, 25, 58, 58);
control(_c8, 718, 25, 58, 58);
control(_cW, 107, 127, 58, 58);
control(_cS, 107, 275, 58, 58);
control(_cA, 33, 200, 58, 58);
control(_cD, 181, 200, 58, 58);
control(_cmouseUp, 633, 127, 58, 58);
control(_cmouseDown, 633, 275, 58, 58);
control(_cmouseLeft, 559, 200, 58, 58);
control(_cmouseRight, 707, 200, 58, 58);
control(_cspace, 315, 284, 167, 57);
control(_csprint, 287, 374, 167, 57);
control(_cshift, 413, 374, 167, 57);
control(_cfly, 24, 374, 98, 57);
control(_cland, 150, 374, 98, 57);
control(_cbreak, 413, 190, 98, 57);
control(_cplace, 287, 190, 98, 57);
control(_creset, 289, 119, 93, 31);
control(_cdebug, 416, 119, 93, 31);
control(_ctimeslow, 559, 374, 58, 58);
control(_ctimefast, 707, 374, 58, 58);

control(_cPX, 107, 127, 58, 58);
control(_cNX, 107, 275, 58, 58);
control(_cPY, 33, 200, 58, 58);
control(_cNY, 181, 200, 58, 58);
control(_cPZ, 255, 127, 58, 58);
control(_cNZ, 255, 275, 58, 58);
control(_cInvPrev, 559, 275, 58, 58);
control(_cInvNext, 707, 275, 58, 58);


fixed4 load(fixed2 coord) {
	return pow(tex2Dlod(_MainTex, float4(fixed2((floor(coord) + 0.5) / iChannelResolution0.xy), 0.0, 0)), 0.454545);
	//return tex2Dlod(_MainTex,float4(fixed2((floor(coord) + 0.5) / iChannelResolution[0].xy), 0.0,0));
}

bool inBox(fixed2 coord, fixed4 bounds) {
	return coord.x >= bounds.x && coord.y >= bounds.y && coord.x < (bounds.x + bounds.z) && coord.y < (bounds.y + bounds.w);
}

bool controlPressed(fixed4 control) {
	control.x = iChannelResolution1.x - control.x;
	control.y = iChannelResolution1.y - control.y;
	control.z *= -1;
	control.w *= -1;
	fixed2 controluv = control.xy;
	fixed2 controlxy = control.xy + control.zw;
	controluv /= iChannel1Scale;
	controlxy /= iChannel1Scale;
	/*[unroll(50)]
	while (controluv.x > controlxy.x && controluv.y < controlxy.y) {
	half4 pixel = tex2D(_SecondTex, controluv / (iChannelResolution1 / 16));
	if (pixel.r < 0.9 || pixel.g < 0.9 || pixel.b < 0.9) {
	return 1;
	}
	controluv.x -= 1;
	controluv.y += 1;
	}*/
	for (fixed i = controluv.x; i > controlxy.x; i--) {
		for (fixed j = controluv.y; j > controlxy.y; j--) {
			half4 pixel = tex2D(_SecondTex, fixed2(i, j) / (iChannelResolution1 / iChannel1Scale));
			if (pixel.r < 0.9 || pixel.g < 0.9 || pixel.b < 0.9) {
				return 1;
			}
		}
	}
	return 0;
}

bool controlPressedFree(fixed4 control) {
	control.x = iChannelResolution2.x - control.x;
	control.y = iChannelResolution2.y - control.y;
	control.z *= -1;
	control.w *= -1;
	fixed2 controluv = control.xy;
	fixed2 controlxy = control.xy + control.zw;
	controluv /= iChannel2Scale;
	controlxy /= iChannel2Scale;
	for (fixed i = controluv.x; i > controlxy.x; i--) {
		for (fixed j = controluv.y; j > controlxy.y; j--) {
			half4 pixel = tex2D(_ThirdTex, fixed2(i, j) / (iChannelResolution2 / iChannel2Scale));
			if (pixel.r < 0.9 || pixel.g < 0.9 || pixel.b < 0.9) {
				return 1;
			}
		}
	}
	return 0;
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
		if (_Reset) {
			return half4(0, 0, 0, 1);
		}

		half4 red = half4(1, 0, 0, 1);
		fixed2 juv = i.uv;
		juv = floor(juv*iChannelResolution0);

		if (juv.x == _buttonW.x && controlPressed(_cW)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonS.x && controlPressed(_cS)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonA.x && controlPressed(_cA)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonD.x && controlPressed(_cD)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonmouseUp.x && controlPressed(_cmouseUp)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonmouseDown.x && controlPressed(_cmouseDown)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonmouseLeft.x && controlPressed(_cmouseLeft)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonmouseRight.x && controlPressed(_cmouseRight)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonspace.x && controlPressed(_cspace)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _buttonreset.x && controlPressed(_creset)) {
			if (juv.y < 1) {
				return red;
			}
		}
		else if (juv.x == _button1.x && controlPressed(_c1)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _button2.x && controlPressed(_c2)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _button3.x && controlPressed(_c3)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _button4.x && controlPressed(_c4)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _button5.x && controlPressed(_c5)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _button6.x && controlPressed(_c6)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _button7.x && controlPressed(_c7)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _button8.x && controlPressed(_c8)) {
			if (juv.y > 0) {
				return red;
			}
		}
		else if (juv.x == _buttonrewind.x && controlPressed(_ctimeslow)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonfastforward.x && controlPressed(_ctimefast)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonQ.x && controlPressed(_cplace)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonE.x && controlPressed(_cbreak)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonshift.x && controlPressed(_cshift)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonsprint.x && controlPressed(_csprint)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttondebug.x && controlPressed(_cdebug)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonfly.x && controlPressed(_cfly)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonland.x && controlPressed(_cland)) {
			if (juv.y >= 0) {
				return red;
			}
		}


		if (juv.x == _buttonpx.x && controlPressedFree(_cPX)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonnx.x && controlPressedFree(_cNX)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonpy.x && controlPressedFree(_cPY)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonny.x && controlPressedFree(_cNY)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonpz.x && controlPressedFree(_cPZ)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttonnz.x && controlPressedFree(_cNZ)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttoninvprev.x && controlPressedFree(_cInvPrev)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		else if (juv.x == _buttoninvnext.x && controlPressedFree(_cInvNext)) {
			if (juv.y >= 0) {
				return red;
			}
		}
		//half4 fragColor = tex2D(_MainTex, i.uv);
		return half4(0, 0, 0, 1);
		//return fragColor;
	}
	ENDCG
	}
  }
}

