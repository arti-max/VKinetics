local KineticNetwork = require "network/KineticNetwork";
local Pathfinder = require "network/KineticPathfinder";
local Registry = require "network/KineticRegistry";

---@class KineticBlock
---@field x number
---@field y number
---@field z number
KineticBlock = {}
KineticBlock.__index = KineticBlock;

KineticBlock.is_generator = false;
KineticBlock.base_capacity = 0; -- su gen
KineticBlock.base_impact = 0;   -- su red
KineticBlock.base_rpm = 0;      -- only for gens
KineticBlock.entity_uid = -1;
KineticBlock.network_id = 0;

KineticBlock.net_source_x = 0;
KineticBlock.net_source_y = 0;
KineticBlock.net_source_z = 0;

KineticBlock.overstress = false;
KineticBlock._timer = 0;

function KineticBlock:new(x, y, z)
    local obj = setmetatable({}, self);
    obj.x = x;
    obj.y = y;
    obj.z = z;
    return obj;
end

function KineticBlock:sync_entity_uid(write)
    write = write or false;
    if self.entity_uid == -1 or write == nil then
        self.entity_uid = block.get_field(self.x, self.y, self.z, "entity_uid");
    elseif write == true then
        block.set_field(self.x, self.y, self.z, "entity_uid", self.entity_uid);
    end
end

function KineticBlock:get_network_id()
    if self.network_id == 0 then
        self.network_id = block.get_field(self.x, self.y, self.z, "network_id") or 0;
    end
    return self.network_id;
end

function KineticBlock:set_network_id(id)
    self.network_id = id;
    return block.set_field(self.x, self.y, self.z, "network_id", id);
end

function KineticBlock:get_direction()
    local dir = block.get_field(self.x, self.y, self.z, "direction");

    if dir == nil or dir == 0 then
        return 1;
    end

    return dir;
end

function KineticBlock:set_direction(dir)
    block.set_field(self.x, self.y, self.z, "direction", dir);
end

function KineticBlock:get_ratio()
    local ratio = block.get_field(self.x, self.y, self.z, "ratio");
    if ratio == nil or ratio == 0 then
        return 1.0;
    end
    return ratio;
end

function KineticBlock:set_ratio(ratio)
    block.set_field(self.x, self.y, self.z, "ratio", ratio);
end

function KineticBlock:get_abs_rpm(network_rpm)
    return network_rpm * self:get_ratio() * self:get_direction();
end

function KineticBlock:get_rpm()
    local netid = self:get_network_id();

    -- print("networkid in rpm: " .. netid);

    if netid == 0 then
        return 0;
    end

    local base_rpm = KineticNetwork.get_rpm(netid);
    return base_rpm * self:get_ratio();
end

function KineticBlock:set_entity_uid(uid)
    self.entity_uid = uid;
end

function KineticBlock:get_entity_uid()
    return self.entity_uid;
end

function KineticBlock:cache_rotation()
    local rot = block.get_rotation(self.x, self.y, self.z)

    if rot == 1 or rot == 3 then -- X
        self._cached_offsets = {{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0}};
        self._base_rot = mat4.rotate({0, 0, 1}, 90);
    elseif rot == 2 or rot == 0 then -- Z
        self._cached_offsets = {{x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1}};
        self._base_rot = mat4.rotate({1, 0, 0}, 90);
    else -- Y
        self._cached_offsets = {{x = 0, y = 1, z = 0}, {x = 0, y = -1, z = 0}};
        self._base_rot = mat4.idt();
    end
end

function KineticBlock:get_visual_angle(gtime)
    local rpm = self:get_rpm()
    local dir = self:get_direction()

    return (gtime * rpm * 6 * dir) % 360
end

function KineticBlock:get_axis_offsets()
    if not self._cached_offsets then self:cache_rotation() end
    return self._cached_offsets;
end

function KineticBlock:get_axis_name()
    local rot = block.get_rotation(self.x, self.y, self.z);
    if rot == 1 or rot == 3 then return "X";
    elseif rot == 2 or rot == 0 then return "Z";
    else return "Y" end;
end

function KineticBlock:get_base_rotation()
    if not self._base_rot then self:cache_rotation() end
    return self._base_rot;
end

function KineticBlock:get_connections()
    local offsets = self:get_axis_offsets()
    local conn = {}
    for _, offset in ipairs(offsets) do
        table.insert(conn, {
            x = self.x + offset.x,
            y = self.y + offset.y,
            z = self.z + offset.z,
            dir_mult = 1,
            ratio_mult = 1.0,
        })
    end
    return conn
end

function KineticBlock:can_connect_from(x, y, z)
    local offsets = self:get_axis_offsets()
    for _, offset in ipairs(offsets) do
        if (self.x + offset.x == x) and (self.y + offset.y == y) and (self.z + offset.z == z) then
            return true
        end
    end
    return false
end

--- вызывать из on_placed
function KineticBlock:on_placed()
    Registry.add(self.x, self.y, self.z, self);
end

--- вызывать из on_broken
function KineticBlock:on_broken()
    Registry.remove(self.x, self.y, self.z);
    Pathfinder.destroy_network(self);

    local uid = self.entity_uid;
    if uid == -1 then
        uid = block.get_field(self.x, self.y, self.z, "entity_uid") or -1;
    end

    if uid ~= -1 and entities.exists(uid) then
        entities.get(uid):despawn();
    end
end

--- вызывается при удалении из регистров
function KineticBlock:on_remove()

end

--- вызывается еври тик
function KineticBlock:on_tick()
    if self._timer > 0 then
        self._timer = self._timer - 1;
    end
end

--- само вызывается каждый кадр
function KineticBlock:on_render(time, dt)
    ---@type number
---@diagnostic disable-next-line: assign-type-mismatch
    local uid = self:get_entity_uid();
    local networkid = self:get_network_id();
    if networkid ~= 0 then
        if uid and entities.exists(uid) then
            local ent = entities.get(uid);
            local rig = ent.skeleton;
            if rig then
                local is_overstressed = KineticNetwork.is_overstressed(networkid);
                if is_overstressed and not self.overstress then
                    self.overstress = true;
                    self.fade_timer = 1.0;
                    self.flash_type = 1;
                elseif self.overstress == true and not is_overstressed then
                    self.overstress = false;
                    self.fade_timer = 1.0;
                    self.flash_type = 2;
                end

                if self.fade_timer and self.fade_timer > 0 then
                    self.fade_timer = math.max(self.fade_timer - dt, 0);

                    local t = self.fade_timer / 1.0; 

                    if self.flash_type == 1 then
                        rig:set_color({1.0, 1.0 - t, 1.0 - t}); 
                    elseif self.flash_type == 2 then
                        rig:set_color({1.0 - t, 1.0, 1.0 - t});
                    end     
                else
                    rig:set_color({1.0, 1.0, 1.0});
                end
            end
        end
    end
end

function KineticBlock:on_loaded()
    self:cache_rotation();
    self:sync_entity_uid(false);

    local netid = self:get_network_id();
    if netid ~= 0 then
        KineticNetwork.restore(netid, self.base_rpm, self.is_generator, self.base_capacity, self.base_impact, self:get_ratio(), self.x, self.y, self.z);
    end

end

function KineticBlock:on_unload()

end

function KineticBlock.handle_present(Block, x, y, z)
    if not Registry.get(x, y, z) then
        local block = Block:new(x, y, z);
        Registry.add(x, y, z, block);
        block:on_loaded();
    end
end

function KineticBlock.handle_removed(x, y, z)
    local block = Registry.get(x, y, z);
    if block then
        block:on_unload()
        Registry.remove(x, y, z);
    end
end

function KineticBlock:apply_network()
    if self.is_generator then
        local netid = KineticNetwork.create(self.base_rpm);
        self:set_direction(1);
        self:set_ratio(1.0);
        self:set_network_id(netid);
        
        KineticNetwork.add_capacity(netid, self.base_capacity, self.base_rpm, self:get_ratio(), self.x, self.y, self.z);
        Pathfinder.propagate(self, netid);
        return;
    end

    local rebuilt = false;
    local conns = self:get_connections();

    for _, conn in ipairs(conns) do
        local neighbor = Registry.get(conn.x, conn.y, conn.z);

        if neighbor and neighbor:can_connect_from(self.x, self.y, self.z) then
            local neighbor_netid = neighbor:get_network_id();

            if neighbor_netid > 0 and KineticNetwork.get(neighbor_netid) then
                Pathfinder.rebuild_network(neighbor_netid);
                rebuilt = true;
                break;
            end
        end
    end

    if not rebuilt then
        self:set_network_id(0);
    end
end

return KineticBlock;