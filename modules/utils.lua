

function make_entity_prefix(name)
    return "voxel_kinetics:" .. name .. "_entity";
end

function make_position_offs(x, y, z, offs)
    return {x+offs, y+offs, z+offs};
end

function get_perp_offsets(axis)
    if axis == "X" then return {{0,1,0}, {0,-1,0}, {0,0,1}, {0,0,-1}};
    elseif axis == "Z" then return {{1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0}};
    else return {{1,0,0}, {-1,0,0}, {0,0,1}, {0,0,-1}} end;
end

function get_diag_offsets(axis)
    if axis == "X" then return {{0,1,1}, {0,1,-1}, {0,-1,1}, {0,-1,-1}};
    elseif axis == "Z" then return {{1,1,0}, {1,-1,0}, {-1,1,0}, {-1,-1,0}};
    else return {{1,0,1}, {1,0,-1}, {-1,0,1}, {-1,0,-1}} end;
end

function smart_placement(x, y, z, playerid)
    if not playerid or playerid == -1 then return end

    local ent_id = player.get_entity(playerid)
    local is_sneaking = false
    if ent_id and ent_id ~= -1 then
        local ent = entities.get(ent_id)
        if ent and ent.rigidbody then
            is_sneaking = ent.rigidbody:is_crouching()
        end
    end

    local dir = player.get_dir(playerid)
    if not dir then return end

    local tx = is_sneaking and -dir[1] or dir[1]
    local ty = is_sneaking and -dir[2] or dir[2]
    local tz = is_sneaking and -dir[3] or dir[3]

    local absX, absY, absZ = math.abs(tx), math.abs(ty), math.abs(tz)
    local new_rot = 4

    if absX > absY and absX > absZ then
        new_rot = (tx > 0) and 1 or 3
    elseif absZ > absX and absZ > absY then
        new_rot = (tz > 0) and 2 or 0
    else
        new_rot = (ty > 0) and 4 or 5
    end

    local cur_rot = block.get_rotation(x, y, z)
    if new_rot ~= cur_rot then
        block.set_rotation(x, y, z, new_rot)
    end

    local roll = 0
    if new_rot == 4 or new_rot == 5 then -- Y
        if absX > absZ then roll = (dir[1] > 0) and 270 or 90
        else roll = (dir[3] > 0) and 180 or 0 end
    elseif new_rot == 1 or new_rot == 3 then -- X
        if absY > absZ then roll = (dir[2] > 0) and 270 or 90
        else roll = (dir[3] > 0) and 180 or 0 end
    else -- Z
        if absX > absY then roll = (dir[1] > 0) and 270 or 90
        else roll = (dir[2] > 0) and 180 or 0 end
    end
    
    pcall(block.set_field, x, y, z, "roll", roll)
end