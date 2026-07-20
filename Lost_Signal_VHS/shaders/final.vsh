#version 120

// Iris final programs render directly to the Minecraft window backbuffer.
varying vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

