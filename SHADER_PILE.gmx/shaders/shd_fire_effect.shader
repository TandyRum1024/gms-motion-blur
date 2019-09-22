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
    const vec4 colorCore = vec4(RGB(255, 171, 74), 1.0);
    const vec4 colorFire = vec4(RGB(255, 91, 41), 1.0);
    
    const vec4 colorSmokeCore = vec4(RGB(87, 88, 94), 0.5);
    const vec4 colorSmoke = vec4(RGB(34, 35, 36), 0.4);
    const vec4 colorSmokeEdge = vec4(RGB(34, 35, 36), 0.0);
    
    vec4 composite = vec4(0.0);
    vec4 source = texture2D( gm_BaseTexture, v_vTexcoord );
    float lumFire = source.r;
    float lumSmoke = source.b;
    
    // Step gradient from
    // https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader
    float stepSmokeEnd = 0.1;
    float stepSmokeBegin = 0.35;
    float stepSmokeCoreEnd = 0.50;
    float stepSmokeCoreBegin = 0.95;
    
    float stepFireEnd = 0.01;
    float stepFireBegin = 0.45;
    float stepFireCoreEnd = 0.70;
    float stepFireCoreBegin = 0.85;
    
    // Smoke
    vec4 smokeFinal = mix(colorSmokeEdge, colorSmoke, smoothstep(stepSmokeEnd, stepSmokeBegin, lumSmoke));
    smokeFinal = mix(smokeFinal, colorSmokeCore, smoothstep(stepSmokeCoreEnd, stepSmokeCoreBegin, lumSmoke));
    // vec4 smokeFinal = mix(colorSmokeEdge, colorSmokeCore, lumSmoke);
    
    // Fire
    composite = mix(smokeFinal, colorFire, smoothstep(stepFireEnd, stepFireBegin, lumFire));
    composite = mix(composite, colorCore, smoothstep(stepFireCoreEnd, stepFireCoreBegin, lumFire));
    
    // gl_FragColor = v_vColour * clamp(smokeFinal + composite, 0.0, 1.0);
    gl_FragColor = v_vColour * clamp(composite, 0.0, 1.0);
    // gl_FragColor = vec4(vec3(texture2D( gm_BaseTexture, v_vTexcoord ).r), 1.0);
}
