local KineticRegistry = {};

KineticRegistry.blocks = {};
KineticRegistry.global_time = 0

local OFFSET_XZ = 1000000
local MULTIPLIER_Z = 2000000
local MULTIPLIER_Y = 4000000000000

function KineticRegistry.get_key(x, y, z)
    local px = x + OFFSET_XZ;
    local pz = z + OFFSET_XZ;

    return px + (pz * MULTIPLIER_Z) + (y * MULTIPLIER_Y);
end

function KineticRegistry.add(x, y, z, kblock)
    local key = KineticRegistry.get_key(x, y, z);
    KineticRegistry.blocks[key] = kblock;
end

function KineticRegistry.get(x, y, z, kblock)
    local key = KineticRegistry.get_key(x, y, z);
    return KineticRegistry.blocks[key];
end

function KineticRegistry.remove(x, y, z)
    local key = KineticRegistry.get_key(x, y, z);
    if KineticRegistry.blocks[key] ~= nil then
        KineticRegistry.blocks[key]:on_remove();
        KineticRegistry.blocks[key] = nil;
    end
end

events.on("voxel_kinetics:render", function(dt)
    KineticRegistry.global_time = KineticRegistry.global_time + dt
    for key, block in pairs(KineticRegistry.blocks) do
        if block.on_render then
            block:on_render(KineticRegistry.global_time, dt)
        end
    end
end)

events.on("voxel_kinetics:tick", function()
    for key, block in pairs(KineticRegistry.blocks) do
        if block.on_tick then
            block:on_tick()
        end
    end
end)

return KineticRegistry;