#version 120
 
// Atmospheric scattering shader for flightgear
// Written by Lauri Peltonen (Zan)
// Implementation of O'Neil's algorithm
 
 
uniform mat4 osg_ViewMatrix;
uniform mat4 osg_ViewMatrixInverse;
 
varying vec3 rayleigh;
varying vec3 mie;
varying vec3 eye;
 
// Dome parameters from FG and screen
const float domeSize = 80000.0;
const float realDomeSize = 100000.0;
const float groundRadius = 0.984503332 * domeSize;
const float altitudeScale = domeSize - groundRadius;
 
// Dome parameters when calculating scattering
// Assuming dome size is 5.0
const float groundLevel = 0.984503332 * 5.0;
const float heightScale = (5.0 - groundLevel);
 
// Integration parameters
const int nSamples = 7;
const float fSamples = float(nSamples);
 
// Scattering parameters
uniform float rK = 0.0003; //0.00015;
uniform float mK = 0.003; //0.0025;
uniform float density = 0.5; //1.0
vec3 rayleighK = rK * vec3(5.602, 7.222, 19.644);
vec3 mieK = vec3(mK);
vec3 sunIntensity = 10.0*vec3(120.0, 125.0, 130.0);
 
// Find intersections of ray to skydome
// ray must be normalized
// cheight is camera height
float intersection (in float cheight, in vec3 ray, in float rad2)
{
  float B = 2.0 * cheight*ray.y;
  float C = cheight*cheight - rad2;  // 25.0 is skydome radius * radius
  float fDet = max(0.0, B*B - 4.0 * C);
  return 0.5 * (-B - sqrt(fDet));
}
 
// Return the scale function at height = 0 for different thetas
float outscatterscale(in float costheta)
{
  float x = 1.0 - costheta;
 
  float a = 1.16941;
  float b = 0.618989;
  float c = 6.34484;
  float d = -31.4138;
  float e = 75.3249;
  float f = -80.1643;
  float g = 32.2878;
 
  return exp(a+x*(b+x*(c+x*(d+x*(e+x*(f+x*g))))));
}
 
// Return the amount of outscatter for different heights and thetas
// assuming view ray hits the skydome
// height is 0 at ground level and 1 at space
// Assuming average density of atmosphere is at 1/4 height
// and atmosphere height is 100 km
float outscatter(in float costheta, in float height)
{
  return density * outscatterscale(costheta) * exp(-4.0 * height);
}
 
 
void main()
{
    // Make sure the dome is of a correct size
    vec4 realVertex = gl_Vertex; //vec4(normalize(gl_Vertex.xyz) * domeSize, 1.0);
 
    // Ground point (skydome center) in eye coordinates
    vec4 groundPoint = gl_ModelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0);
 
    // Calculate altitude as the distance from skydome center to camera
    // Make it so that 0.0 is ground level and 1.0 is 100km (space) level
    float altitude = distance(groundPoint, vec4(0.0, 0.0, 0.0, 1.0));
    float scaledAltitude = altitude / realDomeSize;
 
    // Camera's position, z is up!
    float cameraRealAltitude = groundLevel + heightScale*scaledAltitude;
    vec3 camera = vec3(0.0, 0.0, cameraRealAltitude);
    vec3 sample = 5.0 * realVertex.xyz / domeSize; // Sample is the dome vertex
    vec3 relativePosition = camera - sample; // Relative position
 
    // Find intersection of skydome and view ray
    float space = intersection(cameraRealAltitude, -normalize(relativePosition), 25.0);
    if(space > 0.0) {
      // We are in space, calculate correct positiondelta!
      relativePosition -= space * normalize(relativePosition);
    }
 
    vec3 positionDelta = relativePosition / fSamples;
    float deltaLength = length(positionDelta); // Should multiply by something?
 
    vec3 lightDirection = gl_LightSource[0].position.xyz;
 
    // Cos theta of camera's position and sample point
    // Since camera is 0,0,z, dot porduct is just the z coordinate
    float cameraCosTheta;
 
    // If sample is above camera, reverse ray direction
    if(positionDelta.z < 0.0) cameraCosTheta = -positionDelta.z / deltaLength;
    else cameraCosTheta = positionDelta.z / deltaLength;
 
    // Total attenuation from camera to skydome
    float totalCameraScatter = outscatter(cameraCosTheta, scaledAltitude);
 
 
    // Do numerical integration of scsattering function from skydome to camera
    vec3 color = vec3(0.0);
    for(int i = 0; i < nSamples; i++) 
    {
      // Altitude of the sample point 0...1
      float sampleAltitude = (length(sample) - groundLevel) / heightScale;
 
      // Cosine between the angle of sample's up vector and sun
      // Since lightDirection is in eye space, we must transform sample too
      vec3 sampleUp = gl_NormalMatrix * normalize(sample);
      float cosTheta = dot(sampleUp, lightDirection);
 
      // Scattering from sky to sample point
      float skyScatter = outscatter(cosTheta, sampleAltitude);
 
      // Calculate the attenuation from this point to camera
      // Again, reverse the direction if vertex is over the camera
      float cameraScatter;
      if(relativePosition.z < 0.0) {  // Vertex is over the camera
        cameraCosTheta = -dot(normalize(positionDelta), normalize(sample));
        cameraScatter = totalCameraScatter - outscatter(cameraCosTheta, sampleAltitude);
      } else {  // Vertex is below camera
        cameraCosTheta = dot(normalize(positionDelta), normalize(sample));
        cameraScatter = outscatter(cameraCosTheta, sampleAltitude) - totalCameraScatter;
      }
 
      // Total attenuation
      vec3 totalAttenuate = 4.0 * 3.14159 * (rayleighK + mieK) * (-skyScatter - cameraScatter);
 
      vec3 inScatter = exp(totalAttenuate - sampleAltitude*4.0);
 
      color += inScatter * deltaLength;
      sample += positionDelta;
    }
 
    color *= sunIntensity;
 
    rayleigh = rayleighK * color;
    mie = mieK * color;
    eye = gl_NormalMatrix * positionDelta;
 
 
 
    // We need to move the camera so that the dome appears to be centered around earth
    // to make the dome render correctly!
    float moveDown = -altitude; // Center dome on camera
    moveDown += groundRadius;
    moveDown += scaledAltitude * altitudeScale; // And move correctly according to altitude
 
    // Vertex transformed correctly so that at 100km we are at space border
    vec4 finalVertex = realVertex - vec4(0.0, 0.0, 1.0, 0.0) * moveDown;
    // Transform
    gl_Position = gl_ModelViewProjectionMatrix * finalVertex;
}
