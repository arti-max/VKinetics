local KineticBlock = require "KineticBlock";
local KineticNetwork = require "network/KineticNetwork";

---@class KineticGeneratorBlock : KineticBlock
local KineticGeneratorBlock = setmetatable({}, {__index = KineticBlock});
KineticGeneratorBlock.__index = KineticGeneratorBlock;

KineticGeneratorBlock.is_generator = true;
KineticGeneratorBlock.base_capacity = 0;
KineticGeneratorBlock.base_rpm = 0;

function KineticGeneratorBlock:on_placed()
    KineticBlock.on_placed(self);
end

function KineticGeneratorBlock:on_broken()
    KineticBlock.on_broken(self);
end

return KineticGeneratorBlock;