"""Run mocked UI and catalog regression checks with system liblua 5.4."""
import os
import ctypes
from pathlib import Path

os.chdir(Path(__file__).resolve().parents[1])

lua = ctypes.CDLL("liblua5.4.so.0")
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.luaL_loadfilex.restype = ctypes.c_int
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_pcallk.restype = ctypes.c_int
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
test = Path(__file__).with_name("smoke.lua")
status = lua.luaL_loadfilex(state, str(test).encode(), None)
if not status:
    status = lua.lua_pcallk(state, 0, 0, 0, 0, None)
if status:
    error = lua.lua_tolstring(state, -1, None)
    print(error.decode() if error else "Unknown Lua error")
lua.lua_close(state)
raise SystemExit(bool(status))
