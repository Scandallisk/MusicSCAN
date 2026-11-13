"""Run the Retail integration tests with native-frame/audio mocks; requires lupa."""
import os
from pathlib import Path
from lupa.lua51 import LuaRuntime as Lua51
from lupa.lua54 import LuaRuntime as Lua54
ROOT=Path(__file__).resolve().parents[1]
os.chdir(ROOT)
for Runtime in (Lua51,Lua54):
    lua=Runtime()
    lua.execute((ROOT/'tests/smoke.lua').read_text(encoding='utf-8'))
    print(lua.eval('_VERSION'),'PASS')
