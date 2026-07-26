#version 120

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;

/* RENDERTARGETS: 0 */

void main() {
    vec4 color = texture2D(gtexture, texcoord)
               * texture2D(lightmap, lmcoord)
               * glcolor;
    if (color.a < alphaTestRef) {
        discard;
    }
    gl_FragData[0] = color;
}
