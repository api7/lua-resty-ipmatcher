# lua-resty-ipmatcher

High performance match IP address for OpenResty Lua.

## API

```lua
local ipmatcher = require("resty.ipmatcher")
local ip = ipmatcher.new({
    "127.0.0.1",
    "192.168.0.0/16",
    "::1",
    "fe80::/32",
})

ngx.say(ip:match("127.0.0.1"))
ngx.say(ip:match("192.168.1.100"))
ngx.say(ip:match("::1"))
```

## ipmatcher.new

`syntax: ok, err = ipmatcher.new(ips)`

The `ips` is a array table, like `{ip1, ip2, ip3, ...}`,
each element in the array is a string IP address.

```lua
local ip, err = ipmatcher.new({"127.0.0.1", "192.168.0.0/16"})
```

Returns `nil` and error message if failed to create new `ipmatcher` instance.

It supports any CIDR format for IPv4 and IPv6.

```lua
local ip, err = ipmatcher.new({
        "127.0.0.1", "192.168.0.0/16",
        "::1", "fe80::/16",
    })
```

## ip.match

`syntax: ok, err = ip:match(ip)`

Returns a `true` if the IP exists within any of the specified IP list.

Returns `nil` and an error message with an invalid IP address.

```lua
local ok, err = ip:match("127.0.0.1")
```

## ipmatcher.parse_ipv4

`syntax: res = ipmatcher.parse_ipv4(ip)`

Tries to parse an IPv4 address to host byte order.

Returns a `false` if the ip is not a valid IPv4 address.


## ipmatcher.parse_ipv6

`syntax: res = ipmatcher.parse_ipv6(ip)`

Tries to parse an IPv6 address to host byte order. The given IPv6 address
can be wrapped by square brackets like `[::1]`.

Returns a `false` if the ip is not a valid IPv6 address.
