require "utils";
local KineticBlock = require "KineticBlock";
local Registry = require "network/KineticRegistry";

---@class Gearbox : KineticBlock
local Gearbox = setmetatable({}, {__index = KineticBlock});
Gearbox.__index = Gearbox;

Gearbox.base_mat_north = mat4.rotate({0, 1, 0}, 180)
Gearbox.base_mat_east = mat4.rotate({0, 1, 0}, 0)
Gearbox.base_mat_west = mat4.rotate({0, 1, 0}, -90)

function Gearbox:on_placed()
    KineticBlock.on_placed(self);
    local ent = entities.spawn(make_entity_prefix("gearbox"), make_position_offs(self.x, self.y, self.z, 0.5));

    if ent then
        self:set_entity_uid(ent:get_uid());
        self:sync_entity_uid(true);
    end

    self:apply_network();
end

function Gearbox:on_render(gtime, dt)
    KineticBlock.on_render(self, gtime, dt);

    local uid = self.entity_uid;
    if uid == -1 or not entities.exists(uid) then return end;

    local ent = entities.get(uid);

    local dir = self:get_direction();
    local rpm = self:get_rpm();

    local mult_zp, mult_zn, mult_xp, mult_xn = 1, 1, 1, 1;

    if self.net_source_z and self.net_source_z > self.z then -- +Z
        mult_zp = 1;
        mult_zn = -1;
        mult_xp = 1;
        mult_xn = -1;
    elseif self.net_source_z and self.net_source_z < self.z then -- -Z
        mult_zp = -1;
        mult_zn = 1;
        mult_xp = -1;
        mult_xn = 1;
    elseif self.net_source_x and self.net_source_x > self.x then -- +X
        mult_zp = 1;
        mult_zn = -1;
        mult_xp = 1;
        mult_xn = -1;
    elseif self.net_source_x and self.net_source_x < self.x then -- -X
        mult_zp = -1;
        mult_zn = 1;
        mult_xp = -1;
        mult_xn = 1;
    end

    local angle_zp = (gtime * rpm * 6 * dir * mult_zp) % 360;
    local angle_zn = (gtime * rpm * 6 * dir * mult_zn) % 360;
    local angle_xp = (gtime * rpm * 6 * dir * mult_xp) % 360;
    local angle_xn = (gtime * rpm * 6 * dir * mult_xn) % 360;

    local rig = ent.skeleton;
    if not rig then return end;

    -- debug.print(rig:get_color());
    -- rig:set_color({255, 1, 1});

    local idx_s = rig:index("shaft_south");
    local idx_n = rig:index("shaft_north");
    local idx_e = rig:index("shaft_east");
    local idx_w = rig:index("shaft_west");

    local spin_s = mat4.rotate({0, 0, 1}, angle_zp);
    local spin_n = mat4.rotate({0, 0, 1}, angle_zn);
    local spin_e = mat4.rotate({1, 0, 0}, angle_xp);
    local spin_w = mat4.rotate({1, 0, 0}, angle_xn);

    if idx_s then
        rig:set_matrix(idx_s, spin_s);
    end

    if idx_n then
        rig:set_matrix(idx_n, spin_n);
    end

    if idx_e then
        rig:set_matrix(idx_e, spin_e);
    end

    if idx_w then
        rig:set_matrix(idx_w,  spin_w);
    end
end

function Gearbox:get_connections()
    local conn = {};


    if self.net_source_z and self.net_source_z > self.z then -- +Z
        table.insert(conn, {x = self.x, y = self.y, z = self.z + 1, dir_mult = 1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x, y = self.y, z = self.z - 1, dir_mult = -1, ratio_mult = 1.0});

        table.insert(conn, {x = self.x + 1, y = self.y, z = self.z, dir_mult = 1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x - 1, y = self.y, z = self.z, dir_mult = -1, ratio_mult = 1.0});
    elseif self.net_source_z and self.net_source_z < self.z then -- -Z
        table.insert(conn, {x = self.x, y = self.y, z = self.z + 1, dir_mult = -1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x, y = self.y, z = self.z - 1, dir_mult = 1, ratio_mult = 1.0});

        table.insert(conn, {x = self.x + 1, y = self.y, z = self.z, dir_mult = -1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x - 1, y = self.y, z = self.z, dir_mult = 1, ratio_mult = 1.0});
    elseif self.net_source_x and self.net_source_x > self.x then -- +X
        table.insert(conn, {x = self.x, y = self.y, z = self.z + 1, dir_mult = 1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x, y = self.y, z = self.z - 1, dir_mult = -1, ratio_mult = 1.0});

        table.insert(conn, {x = self.x + 1, y = self.y, z = self.z, dir_mult = 1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x - 1, y = self.y, z = self.z, dir_mult = -1, ratio_mult = 1.0});
    elseif self.net_source_x and self.net_source_x < self.x then -- -X
        table.insert(conn, {x = self.x, y = self.y, z = self.z + 1, dir_mult = -1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x, y = self.y, z = self.z - 1, dir_mult = 1, ratio_mult = 1.0});

        table.insert(conn, {x = self.x + 1, y = self.y, z = self.z, dir_mult = -1, ratio_mult = 1.0});
        table.insert(conn, {x = self.x - 1, y = self.y, z = self.z, dir_mult = 1, ratio_mult = 1.0});
    end

    return conn;
end

function Gearbox:can_connect_from(x, y, z)
    local dx = math.abs(self.x - x);
    local dy = math.abs(self.y - y);
    local dz = math.abs(self.z - z);
    
    if dy == 0 and (dx + dz == 1) then
        return true;
    end
    
    return false;
end

return Gearbox;