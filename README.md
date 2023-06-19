# Name

High-performance IP address matching for OpenResty Lua.

# Table of Contents

- [Name](#name)
- [Table of Contents](#table-of-contents)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [ipmatcher.new](#ipmatchernew)
    - [Usage](#usage)
    - [Example](#example)
  - [ipmatcher.new\_with\_value](#ipmatchernew_with_value)
    - [Usage](#usage-1)
    - [Example](#example-1)
  - [ip:match](#ipmatch)
    - [Usage](#usage-2)
    - [Example](#example-2)
  - [ip:match\_bin](#ipmatch_bin)
    - [Usage](#usage-3)
    - [Example](#example-3)
  - [ipmatcher.parse\_ipv4](#ipmatcherparse_ipv4)
  - [ipmatcher.parse\_ipv6](#ipmatcherparse_ipv6)
- [Installation](#installation)
  - [From LuaRocks](#from-luarocks)
  - [From Source](#from-source)

# Synopsis

```lua
location / {
    content_by_lua_block {
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
    }
}
```

[Back to TOC](#table-of-contents)

# Methods

## ipmatcher.new

Creates a new hash table to store IP addresses.

### Usage

`ips` is a list of IPv4 or IPv6 IP addresses in a CIDR format (`{ip1, ip2, ip3, ...}`). 

```lua
ok, err = ipmatcher.new(ips)
```

Returns `nil` and the error if it fails to create a new `ipmatcher` instance. 

### Example

```lua
local ip, err = ipmatcher.new({
        "127.0.0.1", "192.168.0.0/16", "::1", "fe80::/16",
    })
```

[Back to TOC](#table-of-contents)

## ipmatcher.new_with_value

Creates a new hash table to store IP addresses and corresponding values.

### Usage

`ips` is a list of key-value pairs (`{[ip1] = val1, [ip2] = val2, ...}`), where each key is an IP address string (CIDR format for IPv4 and IPv6).

```lua
matcher, err = ipmatcher.new_with_value(ips)
```

Returns `nil` and the error if it fails to create a new `ipmatcher` instance. 

### Example

```lua
local ip, err = ipmatcher.new_with_value({
    ["127.0.0.1"] = {info = "a"},
    ["192.168.0.0/16"] = {info = "b"},
})
local data, err = ip:match("192.168.0.1")
print(data.info) -- "b"
```

If the IP address matches multiple values, the returned value can be either one of the values:

```lua
local ip, err = ipmatcher.new_with_value({
    ["192.168.0.1"] = {info = "a"},
    ["192.168.0.0/16"] = {info = "b"},
})
local data, err = ip:match("192.168.0.1")
print(data.info) -- "a" or "b"
```

[Back to TOC](#table-of-contents)

## ip:match

Checks if an IP address exists in the specified IP list.

### Usage

`ip` is an IP address string.

```lua
ok, err = ip:match(ip)
```

Returns `true` or `value` if the specified `ip` exists in the list. Returns `false` if the `ip` does not exist in the list. And returns `false` and an error message if the IP address is invalid.

### Example

```lua
local ip, err = ipmatcher.new({
        "127.0.0.1", "192.168.0.0/16", "::1", "fe80::/16",
    })

local ok, err = ip:match("127.0.0.1") -- true
```

[Back to TOC](#table-of-contents)

## ip:match_bin

Checks if an IP address in binary format exists in the specified IP list.

### Usage

`bin_ip` is an IP address in binary format.

```lua
ok, err = ip:match_bin(bin_ip)
```

Returns `true` if the specified `bin_ip` exists in the list. Returns `false` if it does not exist. Returns `nil` and an error message if `bin_ip` is invalid.

### Example

```lua
local ok, err = ip:match_bin(ngx.var.binary_remote_addr)
```

[Back to TOC](#table-of-contents)

## ipmatcher.parse_ipv4

Tries to parse an IPv4 address to a host byte order FFI `uint32_t` type integer.

```lua
ipmatcher.parse_ipv4(ip)
```

Returns `false` if the IP address is invalid.

[Back to TOC](#table-of-contents)

## ipmatcher.parse_ipv6

Tries to parse an IPv6 address to a table with four host byte order FF1 `uint32_t` type integer. The IP address can be wrapped in square brackets like `[::1]`.

```lua
ipmatcher.parse_ipv6(ip)
```

Returns a `false` if the ip is not a valid IPv6 address.

[Back to TOC](#table-of-contents)

# Installation

## From LuaRocks

```shell
luarocks install lua-resty-ipmatcher
```

## From Source

```shell
make install
```

[Back to TOC](#table-of-contents)
