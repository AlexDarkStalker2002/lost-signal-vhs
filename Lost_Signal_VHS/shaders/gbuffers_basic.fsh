#version 120

varying vec4 glcolor;

/* RENDERTARGETS: 0 */

void main() {
    gl_FragData[0] = glcolor;
}
