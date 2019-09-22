///define_tex_idx()
/*
    Sets up the texture atlas attributes / index
*/

enum ePTEX
{
    MAIN = 0,
    PLAYER,
    NPC,
    BARREL,
    BARREL_DEAD,
    SMOKE,
    SMOKE_TRAIL,
    SPARK,
    SCRAP,
    FLASH,
    IMPULSE
}

// Array of sprites to be appended into texture atlas & it's texture index in atlas
var _idx = ePTEX.MAIN; // See enum above for hardcoded texture index
global.textureList = -1;
global.textureList[_idx, 0] = tex3DMain;
global.textureList[_idx, 1] = 0;
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.PLAYER;
global.textureList[_idx, 0] = tex3DPlayer;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.NPC;
global.textureList[_idx, 0] = tex3DNPC;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.BARREL;
global.textureList[_idx, 0] = tex3DBarrel;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.BARREL_DEAD;
global.textureList[_idx, 0] = tex3DBarrelDead;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.SMOKE;
global.textureList[_idx, 0] = tex3DParticleSmoke;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.SMOKE_TRAIL;
global.textureList[_idx, 0] = tex3DParticleSmokeTrail;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.SPARK;
global.textureList[_idx, 0] = tex3DParticleSpark;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.SCRAP;
global.textureList[_idx, 0] = tex3DParticleScrap;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.FLASH;
global.textureList[_idx, 0] = tex3DParticleFlash;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);

_idx = ePTEX.IMPULSE;
global.textureList[_idx, 0] = tex3DParticleImpulse;
global.textureList[_idx, 1] = global.textureList[@ _idx - 1, 1] + global.textureList[@ _idx - 1, 2];
global.textureList[_idx, 2] = sprite_get_number(global.textureList[_idx, 0]);
