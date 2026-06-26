local Registry = require "network/KineticRegistry";

local KineticPathfinder = {};

function KineticPathfinder.propagate(block0, netid)
    local queue = {block0};
    local visited = {};

    visited[Registry.get_key(block0.x, block0.y, block0.z)] = true;

    local head = 1;
    while head <= #queue do
        local current = queue[head];
        head = head+1;

        local connections = current:get_connections();

        for _, conn in pairs(connections) do
            local nx, ny, nz = conn.x, conn.y, conn.z;
            local key = Registry.get_key(nx, ny, nz);

            if not visited[key] then
                local neighbor = Registry.get(nx, ny, nz);

                if neighbor and neighbor:can_connect_from(current.x, current.y, current.z) then
                    visited[key] = true;

                    if neighbor:get_network_id() ~= netid then
                        neighbor:set_network_id(netid);

                        neighbor.net_source_x = current.x;
                        neighbor.net_source_y = current.y;
                        neighbor.net_source_z = current.z;

                        local new_dir = current:get_direction() * conn.dir_mult;
                        neighbor:set_direction(new_dir);

                        local new_ratio = current:get_ratio() * conn.ratio_mult;
                        neighbor:set_ratio(new_ratio);

                        if neighbor.is_generator then
                            require("network/KineticNetwork").add_capacity(netid, neighbor.base_capacity, neighbor.base_rpm, new_ratio, nx, ny, nz);
                        else
                            require("network/KineticNetwork").add_impact(netid, neighbor.base_impact, new_ratio);
                        end

                        table.insert(queue, neighbor);
                    end
                end
            end
        end
    end
end

function KineticPathfinder.destroy_network(block0)
    local netid = block0:get_network_id();
    if netid == 0 then return end;

    local net = require("network/KineticNetwork").get(netid)
    local gens_to_reload = {}

    if net then
        for _, pos in ipairs(net.generators) do
            table.insert(gens_to_reload, {x=pos[1], y=pos[2], z=pos[3]})
        end
    end

    require("network/KineticNetwork").destroy(netid)

    Registry.remove(block0.x, block0.y, block0.z)

    for _, pos in ipairs(gens_to_reload) do
        local gen = Registry.get(pos.x, pos.y, pos.z)
        if gen and gen ~= block0 then
            gen:set_network_id(0)
        end
    end

    for _, pos in ipairs(gens_to_reload) do
        local gen = Registry.get(pos.x, pos.y, pos.z)
        if gen and gen ~= block0 and gen:get_network_id() == 0 then
            gen:apply_network()
        end
    end
end

function KineticPathfinder.rebuild_network(netid)
    if netid == 0 then return end;

    local net = require("network/KineticNetwork").get(netid)
    if not net then return end

    local gens_to_reload = {}
    for _, pos in ipairs(net.generators) do
        table.insert(gens_to_reload, {x=pos[1], y=pos[2], z=pos[3]})
    end

    require("network/KineticNetwork").destroy(netid)

    for _, pos in ipairs(gens_to_reload) do
        local gen = Registry.get(pos.x, pos.y, pos.z)
        if gen then
            gen:set_network_id(0)
        end
    end

    for _, pos in ipairs(gens_to_reload) do
        local gen = Registry.get(pos.x, pos.y, pos.z)
        if gen and gen:get_network_id() == 0 then
            gen:apply_network()
        end
    end
end

return KineticPathfinder;