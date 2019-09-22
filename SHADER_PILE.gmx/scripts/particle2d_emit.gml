///particle2d_emit(x, y, vx, vy, sprite)
/*
    Emits particle (2D demo)
*/
var _i = instance_create(argument0, argument1, oFX);
_i.vx = argument2;
_i.vy = argument3;
_i.sprite_index = argument4;

return _i;
