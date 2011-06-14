// This shader is mostly an adaptation of the shader found at
//  http://www.bonzaisoftware.com/water_tut.html and its glsl conversion
//  available at http://forum.bonzaisoftware.com/viewthread.php?tid=10
//  © Michael Horsch - 2005

varying vec4 waterTex1;
varying vec4 waterTex2;
varying vec4 waterTex4;
varying vec4 ecPosition;
uniform float osg_SimulationTime;
varying vec3 viewerdir;
varying vec3 lightdir;
varying vec3 normal;

void main(void)
{
vec3 N = normalize(gl_Normal);
normal = N;

ecPosition = gl_ModelViewMatrix * gl_Vertex;

viewerdir = vec3(gl_ModelViewMatrixInverse[3]) - vec3(gl_Vertex);
lightdir = normalize(vec3(gl_ModelViewMatrixInverse * gl_LightSource[0].position));

waterTex4 = vec4( ecPosition.xzy, 0.0 );

vec4 t1 = vec4(0.0, osg_SimulationTime*0.005217, 0.0,0.0);
vec4 t2 = vec4(0.0, osg_SimulationTime*-0.0012, 0.0,0.0);

waterTex1 = gl_MultiTexCoord0 + t1;
waterTex2 = gl_MultiTexCoord0 + t2;

gl_Position = ftransform();
}