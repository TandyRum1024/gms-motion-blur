///vb_add_wall(vb, x, y, z, xsize, ysize, zsize, texindex, colour, alpha)
/*
    Appends wall primitive into vertex buffer
*/
var _vb = argument0;
var _x = argument1, _y = argument2, _z = argument3;
var _x2 = _x + argument4, _y2 = _y + argument5, _z2 = _z - argument6;
var _tex = argument7;
var _u1 = _tex * global.textureAtlasUnitWid, _v1 = 0;
var _u2 = _u1 + global.textureAtlasUnitWid, _v2 = 1;
var _colour = argument8, _alpha = argument9;

// first tri
vb_add_vtx(_vb, _x, _y, _z, _u1, _v1, _colour, _alpha); // tl
vb_add_vtx(_vb, _x2, _y2, _z, _u2, _v1, _colour, _alpha); // tr
vb_add_vtx(_vb, _x, _y, _z2, _u1, _v2, _colour, _alpha); //bl

// second tri
vb_add_vtx(_vb, _x, _y, _z2, _u1, _v2, _colour, _alpha); //bl
vb_add_vtx(_vb, _x2, _y2, _z, _u2, _v1, _colour, _alpha); // tr
vb_add_vtx(_vb, _x2, _y2, _z2, _u2, _v2, _colour, _alpha); // br
