//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Fire effect : Normal
//
#define RGB(r,g,b) vec3(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0)
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    // 255, 152, 56
    const vec4 colorCore = vec4(RGB(255, 152, 56), 1.0);
    // 255, 84, 0
    const vec4 colorMid = vec4(RGB(255, 84, 41), 1.0);
    
    // 99, 9, 0
    const vec4 colorSmokeA = vec4(RGB(15, 15, 15), 0.0);
    const vec4 colorSmokeB = vec4(RGB(56, 53, 54), 0.8);
    
    vec4 composite = vec4(0.0);
    vec4 source = texture2D( gm_BaseTexture, v_vTexcoord );
    float lumFire = source.r;
    float lumSmoke = source.b;
    
    // Step gradient from
    // https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader
    float stepLow = 0.0;
    float stepMidStart = 0.35;
    float stepMidEnd = 0.95;
    float stepHigh = 1.0;
    
    // Smoke
    vec4 smokeFinal = mix(colorSmokeA, colorSmokeB, lumSmoke);
    
    // Fire
    // composite = mix(smokeFinal, colorAmber, smoothstep(stepLow, stepMidStart, lumFire));
    composite = mix(smokeFinal, colorMid, smoothstep(stepMidStart, stepMidEnd, lumFire));
    composite = mix(composite, colorCore, smoothstep(stepMidEnd, stepHigh, lumFire));
    
    // gl_FragColor = v_vColour * clamp(smokeFinal + composite, 0.0, 1.0);
    gl_FragColor = v_vColour * composite;
    // gl_FragColor = vec4(vec3(texture2D( gm_BaseTexture, v_vTexcoord ).r), 1.0);
}
