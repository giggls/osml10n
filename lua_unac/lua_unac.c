/* 

Quick and dirty lua interface for libunac
assuming utf-8 encoding

(c) 2020 Sven Geggus <sven@geggus.net>

*/

#include <stdlib.h>
#include <string.h>
#include <unac.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static int unac4lua(lua_State *L) {
  int res;
  size_t olen;
  char *out;
  const char *input = lua_tostring(L, 1);
  // according to unac.h this will allocate an output buffer for us
  out=NULL;
  res = unac_string("UTF-8", input, strlen(input)+1, &out, &olen);
  if (0==res) {
    lua_pushstring(L, out);
  } else {
    lua_pushnil(L);
  }
  free(out);
  return 1;
}

/* register function in lua
int luaopen_unaccent(lua_State *L){
  lua_register(L,"unaccent",unac4lua);
  return 1;
}
*/

/* library to be registered */
static const struct luaL_Reg lib_unaccent [] = {
  {"unaccent", unac4lua},
  {NULL, NULL}
};

/* name of this function must be exactly called like this */
int luaopen_unaccent (lua_State *L){
    luaL_newlib(L, lib_unaccent);
    return 1;
}
