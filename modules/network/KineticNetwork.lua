local KineticNetwork = {};

local networks = {}
local netx_network_id = 1;

function KineticNetwork.create(base_rpm)
    local id = netx_network_id;
    netx_network_id = netx_network_id + 1;

    networks[id] = {
        capacity = 0,
        impact = 0,
        rpm = base_rpm or 0,
        generators = {}
    }

    print("Network created! " .. id .. " rpm in net: " .. networks[id].rpm);
    return id;
end

function KineticNetwork.get(id)
    return networks[id];
end

function KineticNetwork.destroy(id)
    networks[id] = nil;
end

function KineticNetwork.add_capacity(id, amnt, rpm, ratio, x, y, z)
    if networks[id] then
        local added_cap = (amnt or 0) * (rpm or 0);
        networks[id].capacity = networks[id].capacity + added_cap;

        local abs_ratio = math.abs(ratio or 1.0);
        if abs_ratio == 0 then abs_ratio = 1.0 end;
        local root_rpm = (rpm or 0) / abs_ratio;

        if root_rpm and root_rpm > networks[id].rpm then
            networks[id].rpm = root_rpm;
        end

        if x and y and z then
            table.insert(networks[id].generators, {x, y, z});
        end
    end
end

function KineticNetwork.add_impact(id, amnt, ratio)
    if networks[id] then
        local impact = (amnt or 0) * math.abs(ratio or 1.0)
        networks[id].impact = networks[id].impact + impact;
    end
end

function KineticNetwork.is_overstressed(id)
    local net = networks[id];
    if not net then
        return true;
    end
    return net.impact*net.rpm > net.capacity;
end

function KineticNetwork.get_rpm(id)
    local net = networks[id];
    if not net then
        return 0;
    end
    if KineticNetwork.is_overstressed(id) then
        return 0;
    end

    return net.rpm;
end

function KineticNetwork.restore(id, base_rpm, is_gen, capacity, impact, ratio, x, y, z)
    if id == 0 then return end;

    if not networks[id] then
        networks[id] = {
            capacity = 0,
            impact = 0,
            rpm = base_rpm or 0,
            generators = {}
        }

        if id >= netx_network_id then
            netx_network_id = id + 1;
        end
    end

    if is_gen then
        KineticNetwork.add_capacity(id, capacity, base_rpm, ratio, x, y, z);
    else
        KineticNetwork.add_impact(id, impact, ratio);
    end
end

return KineticNetwork;