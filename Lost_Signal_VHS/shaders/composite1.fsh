#version 120

// History-storage pass. composite has already written the finished VHS frame to
// colortex0 and matching depth/AGC metadata to persistent colortex5. This pass
// copies color to colortex4 so both histories describe the same finished frame.
uniform sampler2D colortex0;
varying vec2 texcoord;

/* RENDERTARGETS: 4 */

void main() {
    gl_FragData[0] = texture2D(colortex0, texcoord);
}

