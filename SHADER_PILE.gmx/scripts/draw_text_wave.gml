#define draw_text_wave
///draw_text_wave(x, y, str, xscale, yscale, colour, alpha, time, frequency, amplitude, angleAmplitude)
/*
    Draws wavy text
*/
var _x = argument0, _y = argument1, _str = argument2;
var _xscale = argument3, _yscale = argument4;
var _colour = argument5, _alpha = argument6;
var _t = argument7, _freq = argument8, _amp = argument9, _angleAmp = argument10;
var _ch = '', _len = string_length(_str), _em = string_height('M') * _yscale;
var _prev;

for (var i=0; i<_len; i++)
{
    _prev = _ch;
    _ch = string_char_at(_str, i + 1);

    if (_ch == "\" && _prev != "\")
    {
        continue;
    }
    else if (_ch == "#" && _prev != "\")
    {
        _x = argument0;
        _y += _em;
    }
    else
    {
        if (_ch == "#") _ch = "\" + _ch;
        
        var _sin = dsin((_t + i) * _freq);
        draw_text_transformed_color(_x, _y + _sin * _amp, _ch, _xscale, _yscale, _sin * _angleAmp, _colour, _colour, _colour, _colour, _alpha);
        _x += string_width(_ch) * _xscale;
    }
}

#define draw_text_wave_align
///draw_text_wave_align(x, y, str, xscale, yscale, colour, alpha, time, frequency, amplitude, angleAmplitude, halign, valign)
/*
    Draws wavy text but aligned
*/
var _x = argument0, _y = argument1, _str = argument2;
var _xscale = argument3, _yscale = argument4;
var _colour = argument5, _alpha = argument6;
var _t = argument7, _freq = argument8, _amp = argument9, _angleAmp = argument10;
var _halign = argument11, _valign = argument12;
var _ch = '', _len = string_length(_str), _em = string_height('M') * _yscale;
var _prev;

var _ox = _x - string_width(_str) * 0.5 * _xscale * _halign;
var _oy = _y - string_height(_str) * 0.5 * _yscale * _valign;

_x = _ox;
_y = _oy;

for (var i=0; i<_len; i++)
{
    _prev = _ch;
    _ch = string_char_at(_str, i + 1);
    
    if (_ch == "\" && _prev != "\")
    {
        continue;
    }
    else if (_ch == "#" && _prev != "\")
    {
        _x = _ox;
        _y += _em;
    }
    else
    {
        if (_ch == "#") _ch = "\" + _ch;
        
        var _sin = dsin((_t + i) * _freq);
        draw_text_transformed_color(_x, _y + _sin * _amp, _ch, _xscale, _yscale, _sin * _angleAmp, _colour, _colour, _colour, _colour, _alpha);
        _x += string_width(_ch) * _xscale;
    }
}

#define draw_text_wave_hsv
///draw_text_wave_hsv(x, y, str, xscale, yscale, hue, saturation, value, alpha, time, frequency, amplitude, angleAmplitude, halign, valign)
/*
    Draws HSV coloured wavy text but aligned
*/
var _x = argument0, _y = argument1, _str = argument2;
var _xscale = argument3, _yscale = argument4;
var _hue = argument5, _sat = argument6, _val = argument7, _alpha = argument8;
var _t = argument9, _freq = argument10, _amp = argument11, _angleAmp = argument12;
var _halign = argument13, _valign = argument14;
var _ch = '', _len = string_length(_str), _em = string_height('M') * _yscale;
var _prev;

var _ox = _x - string_width(_str) * 0.5 * _xscale * _halign;
var _oy = _y - string_height(_str) * 0.5 * _yscale * _valign;

_x = _ox;
_y = _oy;

for (var i=0; i<_len; i++)
{
    _prev = _ch;
    _ch = string_char_at(_str, i + 1);
    
    if (_ch == "\" && _prev != "\")
    {
        continue;
    }
    else if (_ch == "#" && _prev != "\")
    {
        _x = _ox;
        _y += _em;
    }
    else
    {
        if (_ch == "#") _ch = "\" + _ch;
        
        var _sin = dsin((_t + i) * _freq);
        var _col = make_colour_hsv(_hue + (_t + i) * _freq, _sat, _val);
        draw_text_transformed_color(_x, _y + _sin * _amp, _ch, _xscale, _yscale, _sin * _angleAmp, _col, _col, _col, _col, _alpha);
        _x += string_width(_ch) * _xscale;
    }
}