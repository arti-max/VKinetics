require "utils"
local GBox = require "kinetics/Gearbox";
local Registry = require "network/KineticRegistry"

function on_placed(x, y, z, playerid)
    smart_placement(x, y, z, playerid);
    local gbox = GBox:new(x, y, z);
    gbox:on_placed();
end

function on_broken(x, y, z, playerid)
    local gbox = Registry.get(x, y, z);

    if gbox then
        gbox:on_broken();
    end

end

function on_block_present(x, y, z)
    -- print("Пресент!!")
    KineticBlock.handle_present(GBox, x, y, z);
end

function on_block_removed(x, y, z)
    -- print("Ремувд!!")
    KineticBlock.handle_removed(x, y, z);
end