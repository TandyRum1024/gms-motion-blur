///iui_reset()
/**
    Resets IMGUI system.
**/

ds_map_clear(iui_idMap);
ds_map_clear(iui_varmap);
ds_stack_clear(iui_alignStack);
iui_init_vars();
