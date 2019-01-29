# MCUnityShader
Converted/modified shaders from shadertoy from GLSL into HLSL with alterations to be playable when used in Unity via render textures (with argb float) or graphics blit to send output data images to other shaders as sources for input and finally to a final combined render of a Voxel Game world with inspiration from Minecraft. These shaders, when setup with the right systems in Unity, allow one to play the voxel game entirely through the shader code without additional scripts except to enable game object 'buttons' that a camera then reads. The final output shader result has an option to be displayed either on a screen, or directly in screenspace, and supports panospheric stereoscopic 3D for VR and panospheric 2D for desktop.

Changes from source:

- Converted from GLSL to HLSL
- Readjustments to add additional movement options and button inputs
- Reformatted data transfer between shaders to avoid float errors
- 2D/3D panospheric support for VR/Desktop
- Adjustments to movement physics

Original GLSL Shader: https://www.shadertoy.com/view/MtcGDH

Example Shader Setup


<img src="MCShaderExample.png?raw=true" width = 100%>
