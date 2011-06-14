// -*-C++-*-
uniform sampler2D texture;

void main()
{
    vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 texel;
    vec4 fragColor;

    texel = texture2D(texture, gl_TexCoord[0].st);
    fragColor = color * texel;

    gl_FragColor = fragColor;

}
