//
// OH GOD
// IM BURNING
attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_pixelsize; // Pixel's size in texture space

uniform vec2 u_texturesize; // Size of the u_source texture

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    // Get pixel size in texture space
    v_pixelsize = (vec2(1.0) / u_texturesize);
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Fire calculation shader
// You can use the output from this and stick it into shd_fire_effect_* to render fire
// This shader outputs to red and blue channel
// zik@2019
// -------------------------
// Related : https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm
// #define SHOW_NOISE_DEBUG

// Use user defined cooling map texture? (u_coolingmap)
// Commenting this would make shader to generate noise & use it as cooling map
// #define USE_EXTERNAL_NOISE

// Emulate the wind?
#define USE_WINDMAP

// Render smoke & save it to blue channel?
#define RENDER_SMOKE

#define M_PI 3.14159265358979323846

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_pixelsize; // Pixel's size in texture space

// Cooling map -- You can use any noise for this or you can comment "#define USE_EXTERNAL_NOISE" above to use internal one instead.
uniform sampler2D u_coolingmap;
uniform sampler2D u_source; // Source texture to calculate over -- You want this to be same as the one you're writting onto.
uniform float u_time; // Time

uniform float u_scrollspeed; // How fast the fire's scrolling up
uniform float u_windstrength; // Strength of wind -- Needs "#define USE_WINDMAP" uncommented to use
uniform float u_windspeed; // Speed of wind

// Fractional Brownian motion noise by Inigo Quilez
// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
const mat2 m2 = mat2(0.8,-0.6,0.6,0.8);
float rand(vec2 n) { 
return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 n) {
const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}
float fbm( in vec2 p ){
    float f = 0.0;
    f += 0.5000*noise( p ); p = m2*p*2.02;
    f += 0.2500*noise( p ); p = m2*p*2.03;
    f += 0.1250*noise( p ); p = m2*p*2.01;
    f += 0.0625*noise( p );

    return f/0.9375;
}

// Voronoi cellular noise
// https://thebookofshaders.com/12/
vec2 random2( vec2 p )
{
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float getVoronoi (vec2 uv, vec2 offset, float size, float time)
{
    float minDist = 1.0;
    float minVal = 0.0;
    
    vec2 scaled = uv * size;
    vec2 ipos = floor(scaled);
    vec2 fpos = fract(scaled);
    
    for (float j=-1.0; j<=1.0; j+=1.0)
    {
        for (float i=-1.0; i<=1.0; i+=1.0)
        {
            vec2 neighbor = vec2(i, j);
            vec2 gridPoint = random2(ipos + neighbor);
            float pointDist = length(neighbor + gridPoint + offset - fpos);
            
            if (pointDist < minDist)
            {
                // minVal = mix(fbm(ipos + neighbor), fbm(ipos + neighbor + vec2(42.0)), sin(time) * 0.5 + 0.5);
                minVal = fbm(ipos + neighbor);
                minDist = pointDist;
            }
        }
    }
    
    return minVal;
}
//

// Function to get the average of fire and smoke intensity
float intensity (sampler2D src, vec2 uv)
{
    vec4 tex = texture2D(src, uv);
    return (tex.r + tex.b) * 0.5;
}

// Function to get the average of the neighbor's red channel
float neighbor2D (sampler2D src, vec2 uv)
{
    float pl = texture2D(src, uv - vec2(v_pixelsize.x, 0.0)).r;
    float pr = texture2D(src, uv + vec2(v_pixelsize.x, 0.0)).r;
    float pt = texture2D(src, uv - vec2(0.0, v_pixelsize.y)).r;
    float pb = texture2D(src, uv + vec2(0.0, v_pixelsize.y)).r;
    
    return (pl + pr + pt + pb) * 0.25;
}

// Function to get the average of the neighbor's red and blue channel (= fire and smoke intensity)
float neighborSmoke (sampler2D src, vec2 uv)
{
    float pl = intensity(src, uv - vec2(v_pixelsize.x, 0.0));
    float pr = intensity(src, uv + vec2(v_pixelsize.x, 0.0));
    float pt = intensity(src, uv - vec2(0.0, v_pixelsize.y));
    float pb = intensity(src, uv + vec2(0.0, v_pixelsize.y));
    
    return (pl + pr + pt + pb) * 0.5;
}

// Function to get the wind value for offseting the sampling UV
vec2 windmap2D (vec2 uv, float time, float strength)
{
    float windx = fbm(uv * 5.0 + vec2(time)) + (sin(uv.y * 16.0 + 21.0 + uv.x * 21.0 + time) + sin(time + uv.x * 32.0 + 0.42)) * strength;
    float windy = fbm(uv * 5.0 + vec2(time)) + (cos(uv.x * 16.0 + 21.0 + uv.y * 2.0 + time) + sin(uv.y * 32.0 + time + 0.24 + cos(uv.x * 2.0 + time) * 1.0) * 0.5) * strength;
    
    return vec2((windx - 0.5), (windy - 0.5)) * 0.001;
}

void main()
{
    vec4 final = vec4(vec3(0.0), 1.0);
    float timeOff = u_time * 0.05;
    
    /*
        Calculate fire
        ==============
    */
    vec2 uvFire = v_vTexcoord + vec2(0.0, v_pixelsize.y * u_scrollspeed);
    
    // Get wind offset value
    #ifdef USE_WINDMAP
        vec2 flowmap = windmap2D(v_vTexcoord, timeOff * u_windspeed, u_windstrength);
    #else
        vec2 flowmap = vec2(0.0);
    #endif
    
    // Get fire intensity
    float lumFire = neighbor2D(u_source, uvFire + flowmap);
    
    
    // Get the value of cooling map
    float fireY = (v_vTexcoord.y + v_pixelsize.y * u_scrollspeed * u_time);
    
    #ifdef USE_EXTERNAL_NOISE
        // use fract() to keep the UVs in the [0..1] bounds
        float coolmapRaw = texture2D(u_coolingmap, vec2(v_vTexcoord.x, fract(fireY)) + flowmap).r;
        // Adjust cooling map
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= coolmap;
        coolmap *= 0.75;
    #else
        //float coolmapRaw = fbm((vec2(v_vTexcoord.x, fireY) + flowmap) * 40.0);
        float coolmapRaw = fbm((vec2(v_vTexcoord.x, fireY) + flowmap) * 30.0);
        //float coolmapRaw = getVoronoi(vec2(v_vTexcoord.x, fireY), flowmap * 10.0, 20.0, u_time * 0.1);
        
        // Adjust cooling map
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= 0.35; // coolmap *= 0.25;
    #endif
    //
    
    // Subtract, Clamp it and save the result into red channel.
    float fireFinal = max(lumFire - coolmap, 0.0);
    final.r = fireFinal;
    
    /*
        Calculate smoke
        ==============
    */
    #ifdef RENDER_SMOKE
        const float smokeMultiplier = 1.5;
        vec2 uvSmoke = uvFire + vec2(0.0, v_pixelsize.y * smokeMultiplier);
        
        #ifdef USE_WINDMAP
            flowmap += windmap2D(v_vTexcoord, timeOff * u_windspeed, u_windstrength * 0.01 * smokeMultiplier);
        #else
            flowmap = vec2(0.0);
        #endif
        
        float lumSmoke = neighborSmoke(u_source, uvSmoke + flowmap);
        float smokeY = (v_vTexcoord.y + smokeMultiplier + v_pixelsize.y * smokeMultiplier * u_scrollspeed * u_time);
        
        #ifdef USE_EXTERNAL_NOISE
            coolmapRaw = texture2D(u_coolingmap, (vec2(v_vTexcoord.x, fract(smokeY)) + (flowmap * smokeMultiplier)) * 0.5).r;
            // Adjust cooling map
            coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
            coolmap *= coolmap;
            coolmap *= 0.75;
        #else
            // coolmapRaw = fbm((vec2(v_vTexcoord.x, smokeY) + (flowmap * smokeMultiplier)) * 15.0);
            // coolmapRaw = getVoronoi(vec2(v_vTexcoord.x, smokeY), flowmap * smokeMultiplier * 10.0, 5.0, u_time * 2.0);
            coolmapRaw = fbm((vec2(v_vTexcoord.x, smokeY) + flowmap) * smokeMultiplier * 30.0);
            
            // Adjust cooling map
            coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
            coolmap *= 0.55; // coolmap *= 0.25;
        #endif
        
        // Subtract, Clamp it and save the result into blue channel.
        float smokeFinal = max(lumSmoke - coolmap, 0.0);
        final.b = smokeFinal;
    #endif

    #ifdef SHOW_NOISE_DEBUG
        gl_FragColor = vec4(vec3(coolmapRaw), 1.0);
    #else
        gl_FragColor = final;
    #endif
    
}

