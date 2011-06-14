// -*- mode: C; -*-
// Licence: GPL v2
// Author: Frederic Bouvier

varying float fogCoord;

varying vec3 VNormal;
varying vec3 VTangent;
varying vec3 VBinormal;

uniform sampler2D tex_color;
uniform sampler2D tex_normal;

void main (void) 
{
	vec4 ns = texture2D(tex_normal, gl_TexCoord[0].st);
	vec3 N = ns.rgb * 2.0 - 1.0;
	N = normalize(N.x * VTangent + N.y * VBinormal + N.z * VNormal);

	float nDotVP = max(0.0, dot(N, normalize(gl_LightSource[0].position.xyz)));
	float nDotHV = max(0.0, dot(N, gl_LightSource[0].halfVector.xyz));

	float pf;
	if (nDotVP == 0.0)
		pf = 0.0;
	else
		pf = pow(nDotHV, gl_FrontMaterial.shininess);

	vec4 Diffuse  = gl_LightSource[0].diffuse * nDotVP;
	vec4 Specular = gl_LightSource[0].specular * pf;

	vec4 color = gl_Color + Diffuse * gl_FrontMaterial.diffuse;
	color *= texture2D(tex_color, gl_TexCoord[0].xy);

	color += Specular * gl_FrontMaterial.specular * ns.a;
	color = clamp( color, 0.0, 1.0 );


	float fogFactor;
	const float LOG2 = 1.442695;
	fogFactor = exp2(-gl_Fog.density * gl_Fog.density * fogCoord * fogCoord * LOG2);
	fogFactor = clamp(fogFactor, 0.0, 1.0);


	gl_FragColor = mix(gl_Fog.color, color, fogFactor);
}
