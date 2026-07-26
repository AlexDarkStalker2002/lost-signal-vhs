#version 120

uniform sampler2D gtexture;
uniform float alphaTestRef;

varying vec2 texcoord;
varying vec4 glcolor;

/* RENDERTARGETS: 0 */

void main() {
    vec4 color = texture2D(gtexture, texcoord) * glcolor;
    if (color.a < alphaTestRef) {
        discard;
    }
    gl_FragData[0] = color;
}
