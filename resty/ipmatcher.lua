local base        = require("resty.core.base")
local bit         = require("bit")
local clear_tab   = require("table.clear")
local new_tab     = base.new_tab
local find_str    = string.find
local tonumber    = tonumber
local ipairs      = ipairs
local ffi         = require "ffi"
local ffi_cdef    = ffi.cdef
local ffi_new     = ffi.new
local insert_tab  = table.insert
local string      = string
local io          = io
local package     = package
local setmetatable=setmetatable
local type        = type
local error       = error
local str_sub     = string.sub
local concat_tab  = table.concat
local cur_level   = ngx.config.subsystem == "http" and
                    require "ngx.errlog" .get_sys_filter_level()


local _M = {_VERSION = 0.1}


local function load_shared_lib(so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open
    local io_close = io.close

    local cpath = package.cpath
    local tried_paths = new_tab(32, 0)
    local i = 1

    for k, _ in string_gmatch(cpath, "[^;]+") do
        local fpath = string_match(k, "(.*/)")
        fpath = fpath .. so_name
        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io_open(fpath)
        if f ~= nil then
            io_close(f)
            return ffi.load(fpath)
        end
        tried_paths[i] = fpath
        i = i + 1
    end

    return nil, tried_paths
end


local lib_name = "librestyipmatcher.so"
if ffi.os == "OSX" then
    lib_name = "librestyipmatcher.dylib"
end


local libip, tried_paths = load_shared_lib(lib_name)
if not libip then
    tried_paths[#tried_paths + 1] = 'tried above paths but can not load '
                                    .. lib_name
    error(table.concat(tried_paths, '\r\n', 1, #tried_paths))
end



ffi_cdef[[
    unsigned int inet_network(const char *cp);

    int ip_is_valid_ipv4(const char *ipv4);
    int ip_is_valid_ipv6(const char *ipv6);
    int ip_parse_ipv6(const char *ipv6, int *addr_items);
]]


local mt = {__index = _M}


    local ngx_log = ngx.log
    local ngx_INFO = ngx.INFO
local function log_info(...)
    if cur_level and ngx_INFO > cur_level then
        return
    end

    return ngx_log(ngx_INFO, ...)
end


local function split_ip(ip_addr_org)
    local idx = find_str(ip_addr_org, "/", 1, true)
    if not idx then
        return ip_addr_org
    end

    local ip_addr = str_sub(ip_addr_org, 1, idx - 1)
    local ip_addr_mask = str_sub(ip_addr_org, idx + 1)
    return ip_addr, tonumber(ip_addr_mask)
end

    local t = new_tab(4, 0)
local function gen_ipv6_idx(ip, mask)
    local inet_items = ffi_new("unsigned int [4]")
    local ret = libip.ip_parse_ipv6(ip, inet_items)
    if ret ~= 0 then
        error("failed to parse ipv6 address: " .. ip, 2)
    end

    clear_tab(t)
    for i = 0, 3 do
        local valid_mask = mask
        if valid_mask > 32 then
            valid_mask = 32
        end

        if valid_mask == 32 then
            insert_tab(t, inet_items[i])
        else
            insert_tab(t, bit.rshift(inet_items[i], 32 - valid_mask))
        end

        mask = mask - 32
        if mask <= 0 then
            break
        end
    end

    return concat_tab(t, "#")
end


function _M.new(ips)
    if not ips or type(ips) ~= "table" then
        error("missing valid ip argument", 2)
    end

    local parsed_ipv4s = {}
    local parsed_ipv4s_mask = {}
    local parsed_ipv6s = {}
    local parsed_ipv6s_mask = {}

    for _, ip_addr_org in ipairs(ips) do
        local ip_addr, ip_addr_mask = split_ip(ip_addr_org)

        local is_ipv4 = libip.ip_is_valid_ipv4(ip_addr) == 0
        if is_ipv4 then
            ip_addr_mask = ip_addr_mask or 32
            if ip_addr_mask == 32 then
                parsed_ipv4s[ip_addr] = true

            else
                local inet_addr = libip.inet_network(ip_addr)
                local valid_inet_addr = bit.rshift(inet_addr, 32 - ip_addr_mask)

                parsed_ipv4s[ip_addr_mask] = parsed_ipv4s[ip_addr_mask] or {}
                parsed_ipv4s[ip_addr_mask][valid_inet_addr] = true
                parsed_ipv4s_mask[ip_addr_mask] = true
                log_info("ipv4 mask: ", ip_addr_mask,
                         " valid inet: ", valid_inet_addr)
            end
        end

        local is_ipv6 = libip.ip_is_valid_ipv6(ip_addr) == 0
        if is_ipv6 then
            ip_addr_mask = ip_addr_mask or 128
            if ip_addr_mask == 128 then
                parsed_ipv6s[ip_addr] = true
            else
                local inet_items = ffi_new("unsigned int [4]")
                local ret = libip.ip_parse_ipv6(ip_addr, inet_items)
                if ret ~= 0 then
                    error("failed to parse ipv6 address: " .. ip_addr)
                end

                parsed_ipv6s[ip_addr_mask] = parsed_ipv6s[ip_addr_mask] or {}
                local ipv6_idx = gen_ipv6_idx(ip_addr, ip_addr_mask)
                parsed_ipv6s[ip_addr_mask][ipv6_idx] = true
                parsed_ipv6s_mask[ip_addr_mask] = true
            end
        end
    end

    return setmetatable({
        ipv4 = parsed_ipv4s, ipv4_mask = parsed_ipv4s_mask,
        ipv6 = parsed_ipv6s, ipv6_mask = parsed_ipv6s_mask,
    }, mt)
end


function _M.match(self, ip)
    local is_ipv4 = libip.ip_is_valid_ipv4(ip) == 0
    if is_ipv4 then
        local ipv4s = self.ipv4
        if ipv4s[ip] then
            return true
        end

        local inet_addr = libip.inet_network(ip)
        for mask, _ in pairs(self.ipv4_mask) do
            if mask == 0 then
                return true -- match any ip
            end

            local valid_inet_addr = bit.rshift(inet_addr, 32 - mask)

            log_info("ipv4 mask: ", mask,
                     " valid inet: ", valid_inet_addr)

            if ipv4s[mask][valid_inet_addr] then
                return true
            end
        end

        return false
    end

    local is_ipv6 = libip.ip_is_valid_ipv6(ip) == 0
    if not is_ipv6 then
        return error("invalid ip address, not ipv4 and ipv6", 2)
    end

    local ipv6s = self.ipv6
    if ipv6s[ip] then
        return true
    end

    local inet_items = ffi_new("unsigned int [4]")
    local ret = libip.ip_parse_ipv6(ip, inet_items)
    if ret ~= 0 then
        error("failed to parse ipv6 address: " .. ip)
    end

    for mask, _ in pairs(self.ipv6_mask) do
        if mask == 0 then
            return true -- match any ip
        end

        local idx = gen_ipv6_idx(ip, mask)
        if ipv6s[mask][idx] then
            return true
        end
    end

    return false
end


return _M
