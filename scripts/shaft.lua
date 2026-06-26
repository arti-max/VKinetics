require "utils"
local Shaft = require "kinetics/Shaft";
local Registry = require "network/KineticRegistry"

function on_placed(x, y, z, playerid)
    smart_placement(x, y, z, playerid);
    local shaft = Shaft:new(x, y, z);
    shaft:on_placed();
end

function on_broken(x, y, z, playerid)
    local shaft = Registry.get(x, y, z);

    if shaft then
        shaft:on_broken();
    end

end

function on_block_present(x, y, z)
    -- print("Пресент!!")
    KineticBlock.handle_present(Shaft, x, y, z);
end

function on_block_removed(x, y, z)
    -- print("Ремувд!!")
    KineticBlock.handle_removed(x, y, z);
end