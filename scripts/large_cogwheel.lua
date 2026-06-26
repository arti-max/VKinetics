require "utils"
local LCog = require "kinetics/LargeCogwheel";
local Registry = require "network/KineticRegistry"

function on_placed(x, y, z, playerid)
    smart_placement(x, y, z, playerid);
    local cog = LCog:new(x, y, z);
    cog:on_placed();
end

function on_broken(x, y, z, playerid)
    local cog = Registry.get(x, y, z);

    if cog then
        cog:on_broken();
    end

end

function on_block_present(x, y, z)
    -- print("Пресент!!")
    KineticBlock.handle_present(LCog, x, y, z);
end

function on_block_removed(x, y, z)
    -- print("Ремувд!!")
    KineticBlock.handle_removed(x, y, z);
end