///animation_set(index[, no_initial_setups])
/*
    Sets player's animation with given index
    if the optional argument no_initial_setups is set to false,
    the animation system will not execute first-frame routines to set things up
*/

animState = argument[0];

if (argument_count > 1 && argument[1] == false)
{
    animInit = true;
}
else
{
    animInit = false;
}
