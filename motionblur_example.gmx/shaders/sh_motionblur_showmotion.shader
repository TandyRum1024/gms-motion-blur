//
// Motion visualization
//
attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec4 v_vColour;
varying vec2 v_vTexcoord;
varying vec2 v_vTexsize; // size of texture
varying vec2 v_vPixelsize; // Size of single pixel in uv space (aka inverse texture size)

uniform vec2 uTexsize; // Size of texture : [width, height]

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
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Motion vector debug
//
varying vec4 v_vColour;
varying vec2 v_vTexcoord;
varying vec2 v_vTexsize; // size of texture
varying vec2 v_vPixelsize; // Size of single pixel in uv space (aka inverse texture size)

uniform vec4 uVelocity; // camera velocity : [vx, vy, vzoom, vrotate]
uniform vec3 uStrength; // blur strength : [translate, zoom, rotate]

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

    // calculate distance from center
    // we multiply it with distance from the center to avoid lens-like distortion
    vec2 ctDelta = v_vTexcoord - vec2(0.5); // distance from center
    vec2 ctNormalized = normalize(ctDelta); // normalized direction from center
    float zoomStr = length(ctDelta) * uStrength.y * uVelocity.z;

    vec2 uvOff = v_vPixelsize * uStrength.x * uVelocity.xy + -ctNormalized * zoomStr;
    
    // Calculate rotation blur offset
    float rotAngle = -uVelocity.w * uStrength.z;
    vec2 rotOff = rot2D(v_vTexcoord, v_vTexsize, rotAngle) + uvOff;
    uvOff = rotOff - v_vTexcoord;
    
    // clamp the results to prevent colour values from getting out of bounds
    final = vec4(fract(uvOff.xy * 0.5 + 0.5), 0.5, 1.0);
    final = clamp(final, 0.0, 1.0);
    gl_FragColor = final * v_vColour;
}

