require "utils";
local KineticGeneratorBlock = require "KineticGeneratorBlock";
local Registry = require "network/KineticRegistry";

---@class HandCrank : KineticGeneratorBlock
local HandCrank = setmetatable({}, {__index = KineticGeneratorBlock});
HandCrank.__index = HandCrank;

HandCrank.base_rpm = 0;
HandCrank.base_capacity = 8;

function HandCrank:on_placed()
    KineticGeneratorBlock.on_placed(self);

    local ent = entities.spawn(make_entity_prefix("hand_crank"), make_position_offs(self.x, self.y, self.z, 0.5));

    self._current_angle = 0;

    if ent then
        ent.transform:set_rot(self:get_base_rotation());
        self:set_entity_uid(ent:get_uid());
        self:sync_entity_uid(true);
    end

    self:cache_rotation();
    self:apply_network();
end

function HandCrank:rotate()
    self._timer = 10;

    if self.base_rpm == 0 or self.base_rpm == nil then
        self.base_rpm = 32;
        
        local netid = self:get_network_id();
        if netid ~= 0 then
            require("network/KineticPathfinder").rebuild_network(netid);
        else
            self:apply_network();
        end
    end
end

function HandCrank:on_tick()
    KineticGeneratorBlock.on_tick(self);

    if self._timer <= 0 and self.base_rpm > 0 then
        local angle = self._current_angle or 0;
        local remainder = angle % 90;
        
        if remainder < 7 or remainder > 83 then
            self.base_rpm = 0;
            
            local netid = self:get_network_id();
            if netid ~= 0 then
                require("network/KineticPathfinder").rebuild_network(netid);
            end
        else
            self._timer = 1;
        end
    end
end

function HandCrank:on_render(gtime, dt)
    KineticBlock.on_render(self, gtime, dt);

    local uid = self.entity_uid;
    if uid == -1 or not entities.exists(uid) then return end;

    local ent = entities.get(uid);

    local dir = self:get_direction();
    local rpm = self:get_rpm();

    if not self._saved_angle then
        self._saved_angle = 0;
    end

    local current_angle = 0
    if rpm > 0 then
        current_angle = self._saved_angle + (gtime * rpm * 6 * dir) % 360;
        if self._saved_angle > 0 then
            self._saved_angle = 0;
        end
        self._current_angle = current_angle;
    else
        if self._current_angle then
            self._saved_angle = current_angle;
            current_angle = math.floor((self._current_angle + 45) / 90) * 90;
        else
            current_angle = 0;
        end
        self._current_angle = current_angle;
    end

    local yx, yy, yz = block.get_Y(self.x, self.y, self.z)

    if yx == 1 or yz == -1 or yy == -1 then
        current_angle = -current_angle;
    end

    local base_mat = self:get_base_rotation();
    local spin_mat = mat4.rotate({0, 1, 0}, current_angle);
    local final_mat = mat4.mul(base_mat, spin_mat);

    ent.transform:set_rot(final_mat);
end

function HandCrank:cache_rotation()
    local yx, yy, yz = block.get_Y(self.x, self.y, self.z)

    self._cached_offsets = {{x = yx, y = yy, z = yz}}

    if yx == 1 then
        self._base_rot = mat4.rotate({0, 0, -1}, 90);
    elseif yx == -1 then
        self._base_rot = mat4.rotate({0, 0, 1}, 90);
    elseif yz == 1 then
        self._base_rot = mat4.rotate({1, 0, 0}, 90);
    elseif yz == -1 then
        self._base_rot = mat4.rotate({-1, 0, 0}, 90);
    elseif yy == -1 then
        self._base_rot = mat4.rotate({1, 0, 0}, 180);
    else
        self._base_rot = mat4.idt();
    end
end

return HandCrank;