require "utils";
local KineticBlock = require "KineticBlock";
local Registry = require "network/KineticRegistry";

---@class Cogwheel : KineticBlock
local Cogwheel = setmetatable({}, {__index = KineticBlock});
Cogwheel.__index = Cogwheel;

Cogwheel.is_cogwheel = true;
Cogwheel.is_large_cogwheel = false;

function Cogwheel:on_placed()
    KineticBlock.on_placed(self);
    local ent = entities.spawn(make_entity_prefix("cogwheel"), make_position_offs(self.x, self.y, self.z, 0.5));

    if ent then
        ent.transform:set_rot(self:get_base_rotation());
        self:set_entity_uid(ent:get_uid());
        self:sync_entity_uid(true);
    end

    self:apply_network();
end

function Cogwheel:on_render(gtime, dt)
    KineticBlock.on_render(self, gtime, dt);

    local uid = self.entity_uid;
    if uid == -1 or not entities.exists(uid) then return end;

    local ent = entities.get(uid);

    local dir = self:get_direction();
    local rpm = self:get_rpm();
    local add_angle = 0;
    -- if dir == -1 then
    --     add_angle = 22.5;
    -- end

    local current_angle = (gtime * rpm * 6 * dir);
    -- print("angle: ", current_angle);

    current_angle = current_angle % 360;
    local base_mat = self:get_base_rotation();
    local spin_mat = mat4.rotate({0, 1, 0}, current_angle);
    local final_mat = mat4.mul(base_mat, spin_mat);

    ent.transform:set_rot(final_mat);

    local rig = ent.skeleton
    local bone_idx = rig:index("wheel")
    
    if bone_idx then
        rig:set_matrix(bone_idx, self:get_bone_matrix())
    end
end

function Cogwheel:get_rotation_offset()
    local sum = math.floor(self.x + self.y + self.z)
    return (sum % 2) * 22.5
end

function Cogwheel:get_bone_matrix()
    if not self._bone_mat then
        self._bone_mat = mat4.rotate({0, 1, 0}, self:get_rotation_offset())
    end
    return self._bone_mat
end

function Cogwheel:get_connections()
    local conn = KineticBlock.get_connections(self);
    local axis = self:get_axis_name();

    for _, p in ipairs(get_perp_offsets(axis)) do
        local nx, ny, nz = self.x + p[1], self.y + p[2], self.z + p[3];
        local neighbor = Registry.get(nx, ny, nz);
        
        if neighbor and neighbor.is_cogwheel and not neighbor.is_large_cogwheel then
            table.insert(conn, {x = nx, y = ny, z = nz, dir_mult = -1, ratio_mult = 1.0});
        end
    end

    for _, p in ipairs(get_diag_offsets(axis)) do
        local nx, ny, nz = self.x + p[1], self.y + p[2], self.z + p[3];
        local neighbor = Registry.get(nx, ny, nz);
        
        if neighbor and neighbor.is_large_cogwheel then
            table.insert(conn, {x = nx, y = ny, z = nz, dir_mult = -1, ratio_mult = 0.5});
        end
    end

    return conn;
end

function Cogwheel:can_connect_from(x, y, z)
    if KineticBlock.can_connect_from(self, x, y, z) then return true end;

    local src = Registry.get(x, y, z);
    if not src then return false end;
    
    local dx, dy, dz = math.abs(self.x - x), math.abs(self.y - y), math.abs(self.z - z);
    local dist_sqr = dx*dx + dy*dy + dz*dz;
    
    if src.get_axis_name and src:get_axis_name() == self:get_axis_name() then
        if dist_sqr == 1 and src.is_cogwheel and not src.is_large_cogwheel then
            return true;
        end
        if dist_sqr == 2 and src.is_large_cogwheel then
            return true;
        end
    end

    return false;
end

return Cogwheel;