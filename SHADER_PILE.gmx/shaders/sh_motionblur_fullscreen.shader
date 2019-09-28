//
// Fullscreen Motionblur shader, See sh_motionblur_nooptimized() for more explaination & comments.
//
attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec4 v_vColour;
varying vec2 v_vTexcoord;

varying vec2 v_vTexsize; // size of texture
varying vec2 v_vNoisesize; // size of noise texture
varying vec2 v_vPixelsize; // Size of single pixel in uv space (aka inverse texture size)
varying vec2 v_vNoisePixelSize; // Size of single pixel in noise texture uv space (aka inverse noise size)

uniform vec2 uTexsize; // Size of texture : [width, height]
uniform vec2 uNoisesize; // Size of noise texture : [width, height]

void main()
{
    // normal vertex transformation & stuff
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    // calculate texture size and inverse texture sizes.
    v_vTexsize = uTexsize;
    v_vPixelsize = vec2(1.0) / uTexsize;
    
    v_vNoisesize = uNoisesize;
    v_vNoisePixelSize = vec2(1.0) / uNoisesize;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Fullscreen Motionblur shader, See sh_motionblur_nooptimized() for more explaination & comments.
//
// #define DEBUG_NOISEUV // debug.
#define SAMPLES_COUNT 5.0 // Number of samples used by blur, High samples means high quality blur.
#define NOISE_DITHER // If uncommented, The shader uses dithering to reduce the banding effect. Works best with lower samples.

varying vec4 v_vColour;
varying vec2 v_vTexcoord;
varying vec2 v_vTexsize; // size of texture
varying vec2 v_vNoisesize; // size of noise texture
varying vec2 v_vPixelsize; // Size of single pixel in uv space (aka inverse texture size)
varying vec2 v_vNoisePixelSize; // Size of single pixel in noise texture uv space (aka inverse noise size)

uniform vec4 uVelocity; // camera velocity : [vx, vy, vzoom, vrotate]
uniform vec3 uStrength; // blur strength : [translate, zoom, rotate]
uniform float uTime; // time, used for random

// noise texture! you can grab one from the link below :
// http://momentsingraphics.de/?p=127
uniform sampler2D sNoise;

/// samples the noise texure and returns its red component.
float noise2D (vec2 uv)
{
    // pixel perfect noise scrolling
    const float scrollSpeed = 16.0; // speed of noise texture scrolling, 0.0 to disable.
    return texture2D(sNoise, fract(uv + mod(vec2(uTime * scrollSpeed), v_vNoisesize) * v_vNoisePixelSize)).r;
}

/// rotates given UV around the vec2(0.5) center and returns the result.
vec2 rot2D (vec2 uv, vec2 texsize, float ang)
{
    /// Calc rotated UV
    float rot = radians(ang);
    vec2 rotuv = ((uv - 0.5) * texsize * mat2(cos(rot), -sin(rot), sin(rot), cos(rot))) / texsize + 0.5;
    return rotuv;
}

void main()
{
    // the resulting colour that we will accumulate the blurred result onto.
    vec4 final = vec4(0.0);

    // Screen-space uv for sampling noises, With correct aspect ratio.
    vec2 uvnoise = v_vTexsize * v_vTexcoord * v_vNoisePixelSize;

    // calculate distance from center
    // we multiply it with distance from the center to avoid lens-like distortion
    vec2 ctDelta = v_vTexcoord - vec2(0.5); // distance from center
    vec2 ctNormalized = normalize(ctDelta); // normalized direction from center
    
    // calculate zoom strength
    float zoomStr = length(ctDelta) * uStrength.y * uVelocity.z;
    
    // and sum all the linear uv offsets that can be extrapolated from camera motion information.
    // we need to calculate rotated uv in the loop below because unlike translation and zoom,
    // Rotation offsets cannot be extrapolated via just scaling it by some factor.
    vec2 offsum = v_vPixelsize * uStrength.x * uVelocity.xy + -ctNormalized * zoomStr;
    
    // Calculate rotation blur strength
    float rotStr = -uVelocity.w * uStrength.z;
    
    // loop setup
    const float stepSize = 1.0 / SAMPLES_COUNT; // inverse steps
    
    // pre-multiply blur factors by stepSize outside of the loop
    offsum *= stepSize;
    rotStr *= stepSize;
    
    #ifdef NOISE_DITHER
        // dithered blur
        // since we're offsetting the loop index (i) with dithered value of range [-stepsize, stepsize],
        // we exclude the first and last step in the loop.
        const float stepBegin = 1.0;
        const float stepEnd = SAMPLES_COUNT - 1.0;
        const float stepFactor = 1.0 / (SAMPLES_COUNT - 1.0);
        
        // fetch screenspace noise value in [-1.0, 1.0] range for dithering
        const float ditherScale = 1.00 * 2.0; // this controls the dithering-ness, the bigger the value is, the more dithered it is.
        float noise = noise2D(uvnoise);
        float dither = (noise - 0.5) * ditherScale;
        
        for (float i = stepBegin; i <= stepEnd; i += 1.0)
        {
            // calculate dithered offset factor (current factor +- stepsize)
            float stepOffset = i + dither;
            
            // offset UV
            // Since we've pre-multiplied offsum and rotStr above by stepSize, We don't have to multiply it here.
            // if we didn't do it, We'd have to manually multiply the uv offset with stepSize to scale it down :
            // vec2 uvoff = offsum * ((i + dither) * stepSize);
            vec2 uvoff = offsum * stepOffset;
            
            // get rotated uv
            float angle = rotStr * stepOffset;
            vec2 uvrot = rot2D(v_vTexcoord, v_vTexsize, angle);
            
            // sample & accumulate to final buffer
            final += texture2D(gm_BaseTexture, uvrot + uvoff) * stepFactor;
        }
    #else
        // non-dithered blur
        const float stepFactor = 1.0 / (SAMPLES_COUNT + 1.0); // factor to make the result into [0.0..1.0] range
        for (float i = 0.0; i <= SAMPLES_COUNT; i += 1.0)
        {
            // offset UV
            vec2 uvoff = offsum * i;
            
            // get rotated uv
            float angle = rotStr * i;
            vec2 uvrot = rot2D(v_vTexcoord, v_vTexsize, angle);
            
            // sample & accumulate to final buffer
            final += texture2D(gm_BaseTexture, uvrot + uvoff) * stepFactor;
        }
    #endif
    
    // clamp the results to prevent colour values from getting out of bounds
    final = clamp(final, 0.0, 1.0);
    gl_FragColor = final * v_vColour;
    
    // debug
    #ifdef DEBUG_NOISEUV
        gl_FragColor = vec4(vec3(noise2D(uvnoise)), 1.0);
    #endif
}

