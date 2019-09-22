///iui_reset()
/**
    Destroys IMGUI system.
**/

ds_map_destroy(iui_idMap);
ds_map_destroy(iui_varmap);
ds_stack_destroy(iui_alignStack);
