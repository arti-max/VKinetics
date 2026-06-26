require "utils"
local Gen = require "kinetics/CreativeGenerator";
local Registry = require "network/KineticRegistry"

function on_placed(x, y, z, playerid)
    smart_placement(x, y, z, playerid);
    local gen = Gen:new(x, y, z);
    gen:on_placed();
end

function on_broken(x, y, z, playerid)
    local gen = Registry.get(x, y, z);

    if gen then
        gen:on_broken();
    end

end

function on_block_present(x, y, z)
    -- print("Пресент!!")
    KineticBlock.handle_present(Gen, x, y, z);
end

function on_block_removed(x, y, z)
    -- print("Ремувд!!")
    KineticBlock.handle_removed(x, y, z);
end