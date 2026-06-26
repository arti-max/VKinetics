require "utils"
local HC = require "kinetics/HandCrank";
local Registry = require "network/KineticRegistry"

function on_placed(x, y, z, playerid)
    smart_placement(x, y, z, playerid);
    local hc = HC:new(x, y, z);
    hc:on_placed();
end

function on_broken(x, y, z, playerid)
    local hc = Registry.get(x, y, z);

    if hc then
        hc:on_broken();
    end

end

function on_interact(x, y, z, playerid)
    local hc = Registry.get(x, y, z);
    if hc then
        hc:rotate();
    end

    return true;
end

function on_block_present(x, y, z)
    -- print("Пресент!!")
    KineticBlock.handle_present(HC, x, y, z);
end

function on_block_removed(x, y, z)
    -- print("Ремувд!!")
    KineticBlock.handle_removed(x, y, z);
end