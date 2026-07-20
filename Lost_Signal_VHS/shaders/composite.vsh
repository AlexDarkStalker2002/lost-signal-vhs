#version 120

// Full-screen vertex shader. Iris supplies a screen-sized quad for composite
// programs, so this pass only forwards its texture coordinates.
varying vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

