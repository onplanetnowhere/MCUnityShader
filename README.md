# MCUnityShader
This is a playable voxel game using only shaders and cameras through Unity. The original source of these shaders was from fb39ca4 on Shadertoy. These shaders are converted from GLSL into HLSL with modifications to be playable when used in Unity via cameras and render textures (with argb float) or graphics blit to send output data images to other shaders as sources for input and finally to a final combined render of a Voxel Game world with inspiration from Minecraft. These shaders, when setup with the right systems in Unity, allow one to play the voxel game entirely through the shader code without additional scripts except to enable game object 'buttons' that a camera then reads as inputs. The final output shader result has an option to be displayed either on a screen, or directly in screenspace, and supports panospheric stereoscopic 3D for VR and panospheric 2D for desktop.

Changes from source:

- Converted from GLSL to HLSL including various bug fixes and changes to code due to conversion issues
- Readjustments to add additional movement options and button inputs
- Reformatted data transfer between shaders to avoid float errors with ARGB Float render textures
- 2D/3D panospheric screenspace support for VR/Desktop
- FOV adjustment support, including FOV changes according to movement speed
- Adjustments to movement physics

Original GLSL Shader: https://www.shadertoy.com/view/MtcGDH

Example Shader Setup


<img src="MCShaderExample.png?raw=true" width = 100%>
