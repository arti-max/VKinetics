require "utils";
local KineticBlock = require "KineticBlock";

---@class Shaft : KineticBlock
local Shaft = setmetatable({}, {__index = KineticBlock});
Shaft.__index = Shaft;

Shaft.base_impact = 512;

function Shaft:on_placed()
    KineticBlock.on_placed(self);
    local ent = entities.spawn(make_entity_prefix("shaft"), make_position_offs(self.x, self.y, self.z, 0.5));

    if ent then
        ent.transform:set_rot(self:get_base_rotation());
        self:set_entity_uid(ent:get_uid());
        self:sync_entity_uid(true);
    end

    self:apply_network();
end

function Shaft:on_render(gtime, dt)
    KineticBlock.on_render(self, gtime, dt);

    local uid = self.entity_uid;
    if uid == -1 or not entities.exists(uid) then return end;

    local ent = entities.get(uid);

    local current_angle = self:get_visual_angle(gtime)
    -- print("angle: ", current_angle);

    local base_mat = self:get_base_rotation();
    local spin_mat = mat4.rotate({0, 1, 0}, current_angle);
    local final_mat = mat4.mul(base_mat, spin_mat);

    ent.transform:set_rot(final_mat);
end

return Shaft;