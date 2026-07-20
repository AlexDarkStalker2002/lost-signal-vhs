#version 120

// The analog processing is complete; copy it to the screen without another
// color transform. Iris will handle non-sRGB display conversion when requested.
uniform sampler2D colortex0;
varying vec2 texcoord;

void main() {
    gl_FragColor = texture2D(colortex0, texcoord);
}

