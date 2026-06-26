
function on_hud_render()
    local dt = time.delta()
    
    events.emit("voxel_kinetics:render", dt)
end