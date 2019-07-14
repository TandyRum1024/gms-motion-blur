//
// motion blur wip - (kinda works in texture atlas'd texture)
// > calculates uv coords in 0.0...1.0 space, you can skip this if you're not using animated sprites
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec4 v_vColour;
varying vec2 v_vTexcoord;
varying vec2 v_vUVNormalized; // Normalized UV in 0..1 space
varying vec4 v_vUVBound; // UV's bounds (AKA max size)
varying vec2 v_vUVSize; // UV's size
varying vec2 v_vUVRatio; // Ratio of uv (To fix ratio of pixel)
varying vec2 v_vPixelsize; // Size of single pixel in uv space

uniform vec4 uTexinfo; // Texture uv info (in uv space) : [left, top, texture width, texture height]
uniform vec2 uTexsize; // Texture size (in pixels) : [texture width, texture height]

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    // normalize texcoords & set ratio
    v_vUVBound = vec4(uTexinfo.xy, uTexinfo.xy + uTexinfo.zw);
    v_vUVNormalized = (in_TextureCoord - uTexinfo.xy) / uTexinfo.zw;
    v_vUVRatio = uTexsize / uTexsize.x;
    v_vUVSize = uTexinfo.zw;
    
    // set pixel size
    v_vPixelsize = uTexsize;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Fullscreen Motionblur shader
//
varying vec4 v_vColour;
varying vec2 v_vTexcoord;

// v THOSE CAN BE STRIPPED AWAY ONLY IF YOU USE THIS SHADER ON SURFACES v
// (AKA ANYTHING THAT HAS IT'S TEXTURE COORDS ALREADY IN 0..1 RANGE & USES ITS OWN TEXTURE, INSTEAD OF COORDS IN ANOTHER BIG TEXTURE PAGE)
varying vec2 v_vUVNormalized; // Normalized UV in 0..1 space
varying vec4 v_vUVBound; // UV's bounds (AKA max size)

varying vec2 v_vUVSize; // UV's size
varying vec2 v_vUVRatio; // Ratio of uv (To fix ratio of pixel)
varying vec2 v_vPixelsize; // Size of single pixel in uv space

uniform vec4 uVelocity; // camera velocity : [vx, vy, vzoom, vrotate]
uniform vec3 uStrength; // blur strength : [translate, zoom, rotate]

// (Blue) noise texture
// http://momentsingraphics.de/?p=127
uniform sampler2D sNoise;
uniform sampler2D sTex; // DEBUG

//#define DEBUG_CENTER
//#define NOISE_DITHER
#define CLAMP_COORDS // Should I clamp the texture coordinates so it doesn't "bleed" over other sprites texture? (costs additional clamp() func)
#define DEBUG_ROTATE

float noise2D (vec2 uv)
{
    return texture2D(sNoise, fract(uv)).a;
}

void main()
{
    const float noiseSize = 16.0;
    vec2 uvnoise = v_vUVNormalized * v_vUVRatio * noiseSize;

    // zoom : calculate distance from center & zoom blur offsets
    vec2 delta = vec2(0.5) - v_vUVNormalized;
    float zoomStr = length(delta) * uStrength.y * uVelocity.z;
    
    /*
    vec2 velOff = v_vPixelsize * uStrength.x * uVelocity.xy; // Velocity blur
    vec2 zoomOff = normalize(delta) * zoomStr; // Zoom blur
    vec2 rotOff = -normalize(delta).yx * uStrength.z * uVelocity.z; // Rotation blur
    */
    /*
    vec2 offsum =   v_vPixelsize * uStrength.x * uVelocity.xy +
                    normalize(delta) * zoomStr +
                    -normalize(delta).yx * (uStrength.z * uVelocity.w);
    */
    // Idea : better use transform
    float rot = radians(45.0);
    mat2 rotm = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    vec2 offsum = v_vTexcoord - (v_vUVSize * 0.5);
    offsum *= rotm;
    offsum += (v_vUVSize * 0.5);
    
    #ifdef DEBUG_CENTER
        gl_FragColor = vec4(vec3(angDelta.x * 0.5 + 0.5, angDelta.y * 0.5 + 0.5, 0.5), 1.0);
        // gl_FragColor = vec4(vec3(clamp(offset.x, 0.0, 1.0), clamp(offset.y, 0.0, 1.0), 0.5), 1.0);
        // gl_FragColor = vec4(mix(vec3(0.0), vec3(1.0), fract(length(delta) * 2.0)), 1.0);
    #else
        #ifdef DEBUG_ROTATE
            gl_FragColor = texture2D(gm_BaseTexture, offsum); //vec4(vec3(offsum.x * 0.5 + 0.5, offsum.y * 0.5 + 0.5, 0.5), 1.0);
        #else
            vec4 final = vec4(0.0); // texture2D(gm_BaseTexture, v_vTexcoord);
            
            // blur
            const float stepSize = 0.1;
            for (float i = 0.0; i <= 1.0; i += stepSize)
            {
                vec2 sampuv = offsum * i;
                
                // dither up, if we have to
                #ifdef NOISE_DITHER
                    // float noiseOffset = noise2D(uvnoise) * 0.02 + 1.0;
                    const float ditherFactor = stepSize * 1.5; // this controls the dithering-ness, the bigger the value is, the more dithered it is.
                    float noiseOffset = noise2D(uvnoise) * 1.02 - 0.01; // remap it into [-0.01..1.01] range for intended "overshoot" of coordinates
                    sampuv = offsum * (i + noiseOffset * ditherFactor);
                #endif
                
                // translate to texture coords
                sampuv += v_vTexcoord;
                
                // clamp coords if needed
                #ifdef CLAMP_COORDS
                    sampuv = vec2(clamp(sampuv.x, v_vUVBound.x, v_vUVBound.z), clamp(sampuv.y, v_vUVBound.y, v_vUVBound.w));
                #endif
                
                vec4 samp = texture2D(gm_BaseTexture, sampuv);
                final += samp * stepSize;
            }
    
            // final = texture2D(sTex, v_vUVNormalized + vec2(v_vPixelsize.x * 10.0, 0.0));
            // final = vec4(vec3(noise2D(uvnoise)), 1.0);
            gl_FragColor = final * v_vColour;
        #endif
    #endif
}

