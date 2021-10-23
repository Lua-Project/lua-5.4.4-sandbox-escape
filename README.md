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

### Reference

[https://github.com/erezto/lua-sandbox-escape](https://github.com/erezto/lua-sandbox-escape)