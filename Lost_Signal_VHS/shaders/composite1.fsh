#version 120

// History-storage pass. composite has already written the finished VHS frame to
// colortex0; this pass copies it to persistent colortex4 for the next frame.
uniform sampler2D colortex0;
varying vec2 texcoord;

/* RENDERTARGETS: 4 */

void main() {
    gl_FragData[0] = texture2D(colortex0, texcoord);
}

