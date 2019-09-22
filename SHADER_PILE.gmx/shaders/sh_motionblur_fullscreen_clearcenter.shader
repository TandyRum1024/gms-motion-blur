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
varying vec2 v_vNoisesize; // size of noise texture
varying vec2 v_vUVRatio; // Ratio of uv (To fix ratio of pixel)
varying vec2 v_vPixelsize; // Size of single pixel in uv space

uniform vec2 uTexsize; // Size of texture : [width, height]
uniform vec2 uNoisesize; // Size of noise texture : [width, height]

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    // texcoords ratio
    v_vUVRatio = uTexsize / uTexsize.y;
    
    // set pixel size
    v_vPixelsize = vec2(1.0) / uTexsize;
    v_vTexsize = uTexsize;
    
    v_vNoisesize = uNoisesize;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Fullscreen Motionblur shader
//
// #define DEBUG_NOISEUV
#define NOISE_DITHER // Use dithering to smooth out the clunkiness?
#define CLEAN_CENTER // Make the zoom blur strength decrease as we get closer to the center of the screen for visibility sakes?
#define CLEAN_CENTER_RADIUS 0.05
#define CLEAN_CENTER_FEATHER 0.6

varying vec4 v_vColour;
varying vec2 v_vTexcoord;

varying vec2 v_vTexsize; // size of texture
varying vec2 v_vNoisesize; // size of noise texture
varying vec2 v_vUVRatio; // Ratio of uv (To fix ratio of pixel)
varying vec2 v_vPixelsize; // Size of single pixel in uv space

uniform vec4 uVelocity; // camera velocity : [vx, vy, vzoom, vrotate]
uniform vec3 uStrength; // blur strength : [translate, zoom, rotate]
uniform float uTime; // time, used for random

// (Blue) noise texture
// http://momentsingraphics.de/?p=127
uniform sampler2D sNoise;

float noise2D (vec2 uv)
{
    return texture2D(sNoise, fract(uv)).r; //texture2D(sNoise, fract(uv + (vec2(uTime) * (vec2(1.0) / v_vNoisesize)))).r;
}

vec2 rot2D (vec2 uv, vec2 texsize, float ang)
{
    /// Calc rotated UV
    float rot = radians(ang);
    mat2 rotm = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    
    vec2 size = texsize;
    vec2 rotuv = ((uv - 0.5) * texsize * rotm) / texsize + 0.5;
    return rotuv;
}

void main()
{
    // Screen-space uv for sampling noises, With correct aspect ratio.
    vec2 screenuv = v_vTexsize * v_vTexcoord;
    vec2 uvnoise = screenuv / v_vNoisesize;

    // calculate distance from center
    vec2 ctDelta = v_vTexcoord - vec2(0.5);
    vec2 ctNormalized = normalize(ctDelta);
    float zoomStr = smoothstep(0.0, 0.5, length(ctDelta)) * uStrength.y * uVelocity.z;
    
    #ifdef CLEAN_CENTER
        // Make it so that the zoom strength decreases the closer to the center of the screen
        float ctDist = length(ctDelta);
        float ctMix = min(smoothstep(CLEAN_CENTER_RADIUS, CLEAN_CENTER_RADIUS + CLEAN_CENTER_FEATHER, ctDist), 1.0);
        zoomStr *= ctMix;
    #endif
    
    // and sum all the linear uv offsets that can be extrapolated.
    // we need to calculate rotated uv in the following loop because unlike translation and zoom, Rotation offsets cannot be extrapolated via just scaling it.
    vec2 offsum = v_vPixelsize * uStrength.x * uVelocity.xy + -ctNormalized * zoomStr;
    vec4 final = vec4(0.0);
    
    // loop setup
    const float steps = 6.0;
    const float stepSize = 1.0 / steps;
    
    #ifdef NOISE_DITHER
        // dithered blur
        // since we're offsetting the loop index (i) with dithered value of range [-stepsize, stepsize],
        // we exclude the first and last step in the loop.
        const float stepBegin = 1.0;
        const float stepEnd = steps - 1.0;
        const float stepFactor = 1.0 / (steps - 1.0);
        
        // fetch screenspace noise value in [-1.0, 1.0] range for dithering
        const float ditherScale = 1.00; // this controls the dithering-ness, the bigger the value is, the more dithered it is.
        float noise = noise2D(uvnoise);
        float dither = (noise - 0.5) * (ditherScale * 2.0);
        
        for (float i = stepBegin; i <= stepEnd; i += 1.0)
        {
            // calculate dithered offset factor (current factor +- stepsize)
            float stepOffset = (i + dither) * stepSize;
            
            // offset UV
            vec2 uvoff = offsum * stepOffset;
            
            // get rotated uv
            float angle = (-uVelocity.w * uStrength.z) * stepOffset;
            vec2 uvrot = rot2D(v_vTexcoord, v_vTexsize, angle);
            
            // sample & accumulate to final buffer
            final += texture2D(gm_BaseTexture, uvrot + uvoff) * stepFactor;
        }
    #else
        // non-dithered blur
        const float stepFactor = 1.0 / (steps + 1.0);
        for (float i = 0.0; i <= 1.0; i += stepSize)
        {
            // offset UV
            vec2 uvoff = offsum * i;
            
            // get rotated uv
            float angle = (-uVelocity.w * uStrength.z) * i;
            vec2 uvrot = rot2D(v_vTexcoord, v_vTexsize, angle);
            
            // sample & accumulate to final buffer
            final += texture2D(gm_BaseTexture, uvrot + uvoff) * stepFactor;
        }
    #endif
    
    gl_FragColor = final * v_vColour;
    
    // debug
    #ifdef DEBUG_NOISEUV
        gl_FragColor = vec4(vec3(noise2D(uvnoise)), 1.0);
    #endif
}

