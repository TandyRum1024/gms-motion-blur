//
// Fullscreen motion blur
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec4 v_vColour;
varying vec2 v_vTexcoord;
varying vec2 v_vTexsize; // size of texture
varying vec2 v_vUVRatio; // Ratio of uv (To fix ratio of pixel)
varying vec2 v_vPixelsize; // Size of single pixel in uv space

uniform vec2 uTexsize; // Size of texture : [width, height]

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    /*
    /// Calc rotated UV
    float rot = radians(uVelocity.w * uStrength.z);
    mat2 rotm = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    
    // 1] remap [0..1] to [-sz, sz] 
    v_vTexrotated = (in_TextureCoord - 0.5) * uTexsize;
    
    // 2] apply rotation matrix
    v_vTexrotated *= rotm;
    
    // 3] remap [-sz, sz] to [0..1] & get delta uvs from original coords
    v_vTexrotated = (v_vTexrotated / uTexsize + 0.5) - v_vTexcoord;
    */
    // texcoords ratio
    v_vUVRatio = uTexsize / uTexsize.x;
    
    // set pixel size
    v_vPixelsize = vec2(1.0) / uTexsize;
    v_vTexsize = uTexsize;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Fullscreen Motionblur shader
//
//#define DEBUG_CENTER
//#define DEBUG_ROTATE
//#define DEBUG_FALLOFF

#define NOISE_DITHER // Use dithering to smooth out the clunkiness?
#define CLEAN_CENTER // Make the blur strength decrease as we get closer to the center of the screen for visibility sakes?
#define CLEAN_CENTER_RADIUS 0.1
#define CLEAN_CENTER_FEATHER 0.4

varying vec4 v_vColour;
varying vec2 v_vTexcoord;
varying vec2 v_vTexsize; // size of texture
varying vec2 v_vUVRatio; // Ratio of uv (To fix ratio of pixel)
varying vec2 v_vPixelsize; // Size of single pixel in uv space

uniform vec4 uVelocity; // camera velocity : [vx, vy, vzoom, vrotate]
uniform vec3 uStrength; // blur strength : [translate, zoom, rotate]
uniform float uTime; // time, used for random

// (Blue) noise texture
// http://momentsingraphics.de/?p=127
uniform sampler2D sNoise;
// uniform sampler2D sTex; // DEBUG

float noise2D (vec2 uv)
{
    return texture2D(sNoise, fract(uv + uTime)).a;
}

vec2 rot2D (vec2 uv, vec2 texsize, float ang)
{
    /// Calc rotated UV
    float rot = radians(ang);
    mat2 rotm = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    
    vec2 size = texsize;
    vec2 rotuv = (uv - 0.5) * texsize;
    rotuv *= rotm;
    rotuv = rotuv / texsize + 0.5;
    return rotuv;
}


void main()
{
    const float noiseSize = 24.0;
    vec2 uvnoise = v_vTexcoord * v_vUVRatio * noiseSize;

    // calculate distance from center
    vec2 ctDelta = v_vTexcoord - vec2(0.5);
    vec2 ctNormalized = normalize(ctDelta);
    float zoomStr = uStrength.y * uVelocity.z;
    
    #ifdef CLEAN_CENTER // Make it so that the zoom strength decreases the closer to the center of the screen
        float ctDist = length(ctDelta);
        float ctMix = min(smoothstep(CLEAN_CENTER_RADIUS, CLEAN_CENTER_RADIUS + CLEAN_CENTER_FEATHER, ctDist), 1.0);
        zoomStr *= ctMix;
    #endif
    
    // and sum all the offsets
    vec2 offsum = v_vPixelsize * uStrength.x * uVelocity.xy + -ctNormalized * zoomStr;

    #ifdef DEBUG_CENTER
        gl_FragColor = vec4(vec3(angDelta.x * 0.5 + 0.5, angDelta.y * 0.5 + 0.5, 0.5), 1.0);
    #else
        #ifdef DEBUG_ROTATE
            gl_FragColor = texture2D(gm_BaseTexture, v_vTexcoord);
        #else
            vec4 final = vec4(0.0);
            
            // blur
            const float stepSize = 0.1;
            const float stepDiv = 1.0 / 11.0;
            for (float i = 0.0; i <= 1.0; i += stepSize)
            {
                vec2 baseuv = v_vTexcoord;
                vec2 sampuv = offsum * i;
                
                // dither up, if we have to
                #ifdef NOISE_DITHER
                    const float ditherFactor = stepSize * 1.0; // this controls the dithering-ness, the bigger the value is, the more dithered it is.
                    float noiseOffset = noise2D(uvnoise) * 1.02 - 0.01; // remap it into [-0.01..1.01] range for intended "overshoot" of coordinates                    
                    
                    sampuv = offsum * (i + noiseOffset * ditherFactor);
                    
                    // Make the base uv as rotated one (and dithered)
                    float offang = (-uVelocity.w * uStrength.z) * (i + noiseOffset * ditherFactor);
                    baseuv = rot2D(v_vTexcoord, v_vTexsize, offang);
                #else
                    baseuv = rot2D(v_vTexcoord, v_vTexsize, i * -uVelocity.w * uStrength.z);
                #endif
                
                vec4 samp = texture2D(gm_BaseTexture, baseuv + sampuv);
                final += samp * stepDiv;
            }
            
            gl_FragColor = final * v_vColour;
        #endif
    #endif
    
    #ifdef DEBUG_FALLOFF
        gl_FragColor = vec4(vec3(fract(ctMix)), 1.0);
    #endif
}

