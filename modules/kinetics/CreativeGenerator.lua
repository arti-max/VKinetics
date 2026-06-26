require "utils";
local KineticGeneratorBlock = require "KineticGeneratorBlock";

---@class CreativeGenerator : KineticGeneratorBlock
local CreativeGenerator = setmetatable({}, {__index = KineticGeneratorBlock});
CreativeGenerator.__index = CreativeGenerator;

CreativeGenerator.base_rpm = 32;
CreativeGenerator.base_capacity = 2048;

function CreativeGenerator:on_placed()
    KineticGeneratorBlock.on_placed(self);

    local ent = entities.spawn(make_entity_prefix("shaft"), make_position_offs(self.x, self.y, self.z, 0.5));

    if ent then
        ent.transform:set_rot(self:get_base_rotation());
        self:set_entity_uid(ent:get_uid());
        self:sync_entity_uid(true);
    end

    self:cache_rotation();
    self:apply_network();
end

function CreativeGenerator:on_render(gtime, dt)
    KineticBlock.on_render(self, gtime, dt);

    local uid = self.entity_uid;
    if uid == -1 or not entities.exists(uid) then return end;

    local ent = entities.get(uid);

    local dir = self:get_direction();
    local rpm = self:get_rpm();

    local current_angle = (gtime * rpm * 6 * dir);

    current_angle = current_angle % 360;
    local base_mat = self:get_base_rotation();
    local spin_mat = mat4.rotate({0, 1, 0}, current_angle);
    local final_mat = mat4.mul(base_mat, spin_mat);

    ent.transform:set_rot(final_mat);
end

function CreativeGenerator:cache_rotation()
    local rot = block.get_rotation(self.x, self.y, self.z)
    
    local yx, yy, yz = block.get_Y(self.x, self.y, self.z)

    self._cached_offsets = {{x = yx, y = yy, z = yz}}

    if rot == 1 or rot == 3 then -- X
        self._base_rot = mat4.rotate({0, 0, 1}, 90);
    elseif rot == 2 or rot == 0 then -- Z
        self._base_rot = mat4.rotate({1, 0, 0}, 90);
    else -- Y
        self._base_rot = mat4.idt();
    end
end

return CreativeGenerator;