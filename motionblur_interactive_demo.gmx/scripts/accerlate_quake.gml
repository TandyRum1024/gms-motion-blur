///accerlate_quake(accel, maxvel, wishdirH)
var _accel = argument0, _maxvel = argument1, _wishdir = argument2;
var _wishdirx = dcos(_wishdir), _wishdiry = dsin(_wishdir);

var _currentvel = dot_product(_wishdirx, _wishdiry, vx, vy);
var _addvel = _accel;

if (_currentvel + _accel > _maxvel)
{
    _addvel = _maxvel - _currentvel;
}

vx += _wishdirx * _addvel;
vy += _wishdiry * _addvel;
