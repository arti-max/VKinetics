local PonderManager = {};

PonderManager.scenes = {};
PonderManager.active_scene = nil;
PonderManager.is_open = false;

function PonderManager.register(block_id, scene_data)
    PonderManager.scenes[block_id] = scene_data;
end

--- @param block_id string
function PonderManager.open(block_id)
    local scene = PonderManager.scenes[block_id];
    if not scene then
        return;
    end

    PonderManager.active_scene = scene;
    PonderManager.is_open = true;

    -- TODO: ponder_ui.xml
end

function PonderManager.render(canvas, gtime, dt)
    if not PonderManager.is_open or not PonderManager.active_scene then
        return;
    end

    -- TODO: canvas render

    if PonderManager.active_scene.on_render then
        PonderManager.active_scene.on_render(canvas, gtime, dt);
    end
end

function PonderManager.close()
    if not PonderManager.is_open then return end;

    PonderManager.active_scene = nil;
    PonderManager.is_open = false;

    -- TODO: close ui

    print("[Ponder] Интерфейс закрыт.")
end

return PonderManager;