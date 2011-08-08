// -*-C++-*-
#version 120

varying float fogFactor;

attribute vec3 usrAttr1;
attribute vec3 usrAttr2;

float textureIndexX = usrAttr1.r;
float textureIndexY = usrAttr1.g;
float wScale = usrAttr1.b;
float hScale = usrAttr2.r;
float shade = usrAttr2.g;
float cloud_height = usrAttr2.b;

void main(void)
{
  gl_TexCoord[0] = gl_MultiTexCoord0 + vec4(textureIndexX, textureIndexY, 0.0, 0.0);
  vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
  vec4 l  = gl_ModelViewMatrixInverse * vec4(0.0,0.0,1.0,1.0);
  vec3 u = normalize(ep.xyz - l.xyz);

  // Find a rotation matrix that rotates 1,0,0 into u. u, r and w are
  // the columns of that matrix.
  vec3 absu = abs(u);
  vec3 r = normalize(vec3(-u.y, u.x, 0.0));
  vec3 w = cross(u, r);

  // Do the matrix multiplication by [ u r w pos]. Assume no
  // scaling in the homogeneous component of pos.
  gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
  gl_Position.xyz = gl_Vertex.x * u;
  gl_Position.xyz += gl_Vertex.y * r * wScale;
  gl_Position.xyz += gl_Vertex.z * w  * hScale;
  gl_Position.xyz += gl_Color.xyz;

  // Determine a lighting normal based on the vertex position from the
  // center of the cloud, so that sprite on the opposite side of the cloud to the sun are darker.

// fix flickering of 3d clouds on some macs
// http://code.google.com/p/flightgear-bugs/issues/detail?id=123
//  float n = dot(normalize(-gl_LightSource[0].position.xyz),
//                normalize(mat3x3(gl_ModelViewMatrix) * (- gl_Position.xyz)));;
  float n = dot(normalize(-gl_LightSource[0].position.xyz),
                normalize(vec3(gl_ModelViewMatrix * vec4(- gl_Position.xyz,0.0))));

  // Determine the position - used for fog and shading calculations
  vec3 ecPosition = vec3(gl_ModelViewMatrix * gl_Position);
  float fogCoord = abs(ecPosition.z);
  float fract = smoothstep(0.0, cloud_height, gl_Position.z + cloud_height);

  // Final position of the sprite
  gl_Position = gl_ModelViewProjectionMatrix * gl_Position;

// Determine the shading of the sprite based on its vertical position and position relative to the sun.
  n = min(smoothstep(-0.5, 0.0, n), fract);
// Determine the shading based on a mixture from the backlight to the front
  vec4 backlight = gl_LightSource[0].diffuse * shade;

  gl_FrontColor = mix(backlight, gl_LightSource[0].diffuse, n);
  gl_FrontColor += gl_FrontLightModelProduct.sceneColor;

  // As we get within 100m of the sprite, it is faded out. Equally at large distances it also fades out.
  gl_FrontColor.a = min(smoothstep(10.0, 100.0, fogCoord), 1.0 - smoothstep(15000.0, 20000.0, fogCoord));
  gl_BackColor = gl_FrontColor;

  // Fog doesn't affect clouds as much as other objects.
  fogFactor = exp( -gl_Fog.density * fogCoord * 0.5);
  fogFactor = clamp(fogFactor, 0.0, 1.0);
}
