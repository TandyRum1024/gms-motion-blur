///particle3d_spark_emit(size, life, x, y, z, vx, vy, vz)
var _size = argument0, _life = argument1;
var _x = argument2, _y = argument3, _z = argument4;
var _vx = argument5, _vy = argument6, _vz = argument7;

var _fx = instance_create(_x, _y, oParticle3D);
_fx.z = _z;

// animation settings
_fx.texOff = 11; // 11th tex from atlas
_fx.animLen = 3;
_fx.texIdx = _fx.texOff + 0;

// velocity
_fx.vx = _vx;
_fx.vy = _vy;
_fx.vz = _vz;

// misc
_fx.life = _life;
_fx.size = _size;
_fx.radius = _size;
