//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec3 v_vVertcoord;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    vec4 screen_space_pos = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    gl_Position = screen_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    v_vVertcoord = vec3(screen_space_pos.xy, screen_space_pos.w);
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Simple passthrough fragment shader
//
varying vec3 v_vVertcoord;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 uScreenSize;

const mat4 bayer4x = (mat4(1.0, 13.0, 4.0, 16.0,
                         9.0, 5.0, 12.0, 8.0,
                         3.0, 15.0, 2.0, 14.0,
                         11.0, 7.0 , 10.0, 6.0) - 1.0) / 16.0;

void main()
{
    // calculate bayer matrix index
    vec2 screenuv = (v_vVertcoord.xy / v_vVertcoord.z) * 0.5 + 0.5;
    screenuv.y = 1.0 - screenuv.y;
    ivec2 bayeruv = ivec2(mod(floor(screenuv * uScreenSize + 0.5), 4.0));
    
    // calculate fade factor from depth
    float depth = clamp(gl_FragCoord.w * 32.0, 0.0, 1.0);
    const float rangeStart = 0.45;
    const float rangeEnd = 0.65;
    float fadeFactor = smoothstep(rangeStart, rangeEnd, depth) * 0.5;
    
    // calculate fade
    vec4 base = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );
    float alpha = base.a;
    
    //if ((alpha - fadeFactor) >= ditherResult) base.a = 1.0;
    //else base.a = 0.0;
    float ditherResult = bayer4x[bayeruv.x][bayeruv.y];
    base.a = ceil(clamp((alpha - fadeFactor) - ditherResult, 0.0, 1.0));
    gl_FragColor = base;
}
