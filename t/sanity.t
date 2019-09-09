# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::IP 'no_plan';

repeat_each(1);
run_tests();


__DATA__

=== TEST 1: ipv4 address
--- config
    location /t {
        content_by_lua_block {
            local ip = require("resty.ipmatcher").new({
                "127.0.0.1",
                "127.0.0.2",
                "192.168.0.0/16",
            })

            ngx.say(ip:match("127.0.0.1"))
            ngx.say(ip:match("127.0.0.2"))
            ngx.say(ip:match("127.0.0.3"))
            ngx.say(ip:match("192.168.1.1"))
            ngx.say(ip:match("192.168.1.100"))
            ngx.say(ip:match("192.100.1.100"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
true
true
false
true
true
false



=== TEST 2: ipv6 address
--- config
    location /t {
        content_by_lua_block {
            local ip = require("resty.ipmatcher").new({
                "::1",
                "fe80::/32",
            })

            ngx.say(ip:match("::1"))
            ngx.say(ip:match("::2"))
            ngx.say(ip:match("fe80::"))
            ngx.say(ip:match("fe80:1::"))

            ngx.say(ip:match("127.0.0.1"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
true
false
true
false
false
