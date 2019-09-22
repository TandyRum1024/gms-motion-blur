#define mdl_add_floor
///mdl_add_floor(model, x, y, z, xsize, ysize, zsize, texindex, colour, alpha)
/*
    Appends floor primitive into vertex buffer
*/
var _mdl = argument0;
var _x = argument1, _y = argument2, _z = argument3;
var _x2 = _x + argument4, _y2 = _y + argument5, _z2 = _z - argument6;
var _tex = argument7;
var _u1 = _tex * global.textureAtlasUnitWid, _v1 = 0;
var _u2 = _u1 + global.textureAtlasUnitWid, _v2 = 1;
var _colour = argument8, _alpha = argument9;

// first tri
d3d_model_vertex_texture_colour(_mdl, _x, _y, _z, _u1, _v1, _colour, _alpha); // tl
d3d_model_vertex_texture_colour(_mdl, _x2, _y, _z2, _u2, _v1, _colour, _alpha); // tr
d3d_model_vertex_texture_colour(_mdl, _x, _y2, _z, _u1, _v2, _colour, _alpha); //bl

// second tri
d3d_model_vertex_texture_colour(_mdl, _x, _y2, _z, _u1, _v2, _colour, _alpha); //bl
d3d_model_vertex_texture_colour(_mdl, _x2, _y, _z2, _u2, _v1, _colour, _alpha); // tr
d3d_model_vertex_texture_colour(_mdl, _x2, _y2, _z2, _u2, _v2, _colour, _alpha); // br

#define mdl_add_floor_rot
///mdl_add_floor_rot(model, x, y, z, size, rot, texindex, colour, alpha)
/*
    Appends floor primitive into vertex buffer
*/
var _mdl = argument0;
var _x = argument1, _y = argument2, _z = argument3;
var _size = argument4, _rot = argument5;
var _tex = argument6;

var _hypo = _size / dcos(45);
var _sin = dsin(_rot + 45) * _hypo, _cos = dcos(_rot + 45) * _hypo;
var _tlx = _x + _sin, _tly = _y - _cos;
var _trx = _x + _cos, _try = _y + _sin;
var _blx = _x - _cos, _bly = _y - _sin;
var _brx = _x - _sin, _bry = _y + _cos;

var _u1 = _tex * global.textureAtlasUnitWid, _v1 = 0;
var _u2 = _u1 + global.textureAtlasUnitWid, _v2 = 1;
var _colour = argument7, _alpha = argument8;

// first tri
d3d_model_vertex_texture_colour(_mdl, _tlx, _tly, _z, _u1, _v1, _colour, _alpha); // tl
d3d_model_vertex_texture_colour(_mdl, _trx, _try, _z, _u2, _v1, _colour, _alpha); // tr
d3d_model_vertex_texture_colour(_mdl, _blx, _bly, _z, _u1, _v2, _colour, _alpha); //bl

// second tri
d3d_model_vertex_texture_colour(_mdl, _blx, _bly, _z, _u1, _v2, _colour, _alpha); //bl
d3d_model_vertex_texture_colour(_mdl, _trx, _try, _z, _u2, _v1, _colour, _alpha); // tr
d3d_model_vertex_texture_colour(_mdl, _brx, _bry, _z, _u2, _v2, _colour, _alpha); // br