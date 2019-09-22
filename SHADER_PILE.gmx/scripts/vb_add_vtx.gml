///vb_add_vtx(vb, x, y, z, u, v, colour, alpha)
/*
    Appends vertex into vertex buffer
*/
var _vb = argument0;
/*
var _x = argument1, _y = argument2, _z = argument3;
var _u = argument4, _v = argument5;
var _colour = argument6, _alpha = argument7;
*/

vertex_position_3d(_vb, argument1, argument2, argument3);
vertex_texcoord(_vb, argument4, argument5);
vertex_colour(_vb, argument6, argument7);
