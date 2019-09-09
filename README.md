# lua-resty-ip-matcher
High performance match IP address for OpenResty Lua.

# API


```lua
local ip = require("resty.ipmatcher").new({
    "127.0.0.1",
    "192.168.0.0/16",
    "::1",
    "fe80::/32",
})

ngx.say(ip.match("127.0.0.1"))
ngx.say(ip.match("192.168.1.100"))
ngx.say(ip.match("::1"))
```

# ip.new


# match
