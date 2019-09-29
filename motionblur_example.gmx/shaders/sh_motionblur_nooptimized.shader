//
// Fullscreen motion blur, Sacrifices optimization for more readable code.
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
    // normal vertex transforming procedure, as usual.
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    /// set varyings..
    // set size of texture, and size of single pixel in texture uv space
    v_vTexsize = uTexsize;
    v_vPixelsize = vec2(1.0) / uTexsize;
    
    // set size of noise texture, and size of single pixel in texture uv space
    v_vNoisesize = uNoisesize;
    v_vNoisePixelSize = vec2(1.0) / uNoisesize;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Fullscreen Motionblur shader
//
// #define DEBUG_NOISEUV // debug.
#define NOISE_DITHER // If uncommented, The shader uses dithering to reduce the banding effect. Works best with lower steps.

/// varying
varying vec4 v_vColour;
varying vec2 v_vTexcoord;

varying vec2 v_vTexsize; // size of texture
varying vec2 v_vNoisesize; // size of noise texture
varying vec2 v_vPixelsize; // Size of single pixel in uv space (aka inverse texture size)
varying vec2 v_vNoisePixelSize; // Size of single pixel in noise texture uv space (aka inverse noise size)

/// uniforms
uniform vec4 uVelocity; // camera velocity : [vx, vy, vzoom, vrotate]
uniform vec3 uStrength; // blur strength : [translate, zoom, rotate]
uniform float uTime; // time, used for random

// (Blue) noise texture, Grab one from the link below.
// http://momentsingraphics.de/?p=127
uniform sampler2D sNoise;

float noise2D (vec2 uv)
{
    // Below is the non-scrolling & ordinary noise sampling
    // return texture2D(sNoise, fract(uv)).r;
    
    // .... But we're using pixel perfect noise scrolling, baby!
    // This makes the noise more "random" since we're modulating the UVs over time.
    const float scrollSpeed = 16.0; // Speed of noise texture scrolling, 0.0 to disable.
    
    // Calculate UVs to sample the noise with
    vec2 scrolluv = vec2(uTime * scrollSpeed); // scroll offset UVs
    
    // Make the scroll uv loop around noise's texture size,
    // to eliminate floating prescision loss due to big number.
    // Then we divide it by noise's texture size to normalize it into [0.0 .. 1.0] range.
    scrolluv = mod(scrolluv, v_vNoisesize) / v_vNoisesize;

    // We're using fract() to make the sum of uv and its offset warp around the [0.0 .. 1.0] range.    
    return texture2D(sNoise, fract(uv + scrolluv)).r;
}

/// Calculates rotated UV
vec2 rot2D (vec2 uv, vec2 texsize, float ang)
{
    float rot = radians(ang);
    
    // build rotation matrix.
    // https://en.wikipedia.org/wiki/Rotation_matrix
    mat2 rotm = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    
    // calculate rotated UV with correct aspect.
    vec2 rotuv = uv - 0.5;
    rotuv *= texsize; // aspect ratio fixing #1
    rotuv *= rotm; // apply rotation
    rotuv /= texsize; // aspect ratio fixing #2
    rotuv += 0.5; // transform the -0.5..0.5 ranged uv into 0..1 ranged one
    return rotuv;
}

void main()
{
    // the resulting colour that we will accumulate the blurred result onto.
    vec4 final = vec4(0.0);

    // Screen-space uv for sampling noises, With correct aspect ratio.
    vec2 screenuv = v_vTexsize * v_vTexcoord; // get screen uv
    vec2 uvnoise = screenuv / v_vNoisesize; // normalize it down into the uv range of noise texture.

    // Calculate distance and direction from center
    vec2 ctDelta = v_vTexcoord - vec2(0.5); // distance from center
    vec2 ctNormalized = normalize(ctDelta); // normalized direction from center
    
    // zoom strength = [distance from center] * [zoom blur strength] * [zoom velocity];
    // we multiply it with distance from the center to avoid lens-like distortion
    float zoomStr = length(ctDelta) * uStrength.y * uVelocity.z;
    
    // and sum all the linear uv offsets that can be extrapolated from camera motion information.
    // we need to calculate rotated uv in the following loop because unlike translation and zoom, Rotation offsets cannot be extrapolated via just scaling it.
    // offset sum is multiplied with inverse texture size (pixel size in uv space) for pixel perfect camera offset.
    vec2 offsum = v_vPixelsize * uStrength.x * uVelocity.xy + -ctNormalized * zoomStr;
    
    // Calculate rotation blur strength
    float rotStr = -uVelocity.w * uStrength.z;
    
    // loop setup
    // Determine how many samples we use for blurring.
    // Bigger nubmer means better quality, But slower speed..
    // But Dithering can be used to eliminate some of the banding caused by lower sample counts.
    const float steps = 5.0;
    const float stepSize = 1.0 / steps; // inverse steps for multipling it inside of the loop
    
    #ifdef NOISE_DITHER
        // dithered blur
        // since we're offsetting the loop index (i) with dithered value of range [-stepsize, stepsize],
        // we exclude the first and last step in the loop.
        const float stepBegin = 1.0;
        const float stepEnd = steps - 1.0;
        const float stepFactor = 1.0 / (steps - 1.0);
        
        // fetch screenspace noise value in [-1.0, 1.0] range for dithering
        const float ditherScale = 1.00; // this controls the dithering-ness, the bigger the value is, the more dithered it is.
        float noise = noise2D(uvnoise) - 0.5; // noise in [-0.5..0.5] range
        
        // normalize the dither offset to [-1.0 - (ditherscale * 2.0) .. 1.0 + (ditherscale * 2.0)] range
        float dither = noise * ditherScale * 2.0;
        
        for (float i = stepBegin; i <= stepEnd; i += 1.0)
        {
            // calculate dithered offset factor (current factor +- stepsize)
            float stepOffset = (i + dither) * stepSize;
            
            // offset UV
            vec2 uvoff = offsum * stepOffset;
            
            // get rotated uv
            float angle = rotStr * stepOffset;
            vec2 uvrot = rot2D(v_vTexcoord, v_vTexsize, angle);
            
            // sample & accumulate to final buffer
            final += texture2D(gm_BaseTexture, uvrot + uvoff) * stepFactor;
        }
    #else
        // non-dithered blur
        const float stepFactor = 1.0 / (steps + 1.0);
        for (float i = 0.0; i <= steps; i += 1.0)
        {
            // get offset UV
            vec2 uvoff = offsum * i * stepSize;
            
            // get rotated uv
            float angle = rotStr * i * stepSize;
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

