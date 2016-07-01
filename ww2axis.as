#include "ShellEject"
#include "axis/weapon_mp40"
#include "axis/weapon_mp44"
#include "axis/weapon_kar98k"
#include "axis/weapon_g43"
#include "axis/weapon_fg42"
#include "axis/weapon_luger"
#include "axis/weapon_scoped98k"
#include "axis/weapon_mg42"
#include "axis/weapon_panzerschreck"
#include "axis/weapon_mg34"
#include "axis/weapon_stick"
#include "axis/weapon_spade"

void MapInit()
{
	RegisterMP40();
	RegisterMP44();
	RegisterK98K();
	RegisterG43();
	RegisterFG42();
	RegisterLUGER();
	RegisterSCOPED98K();
	RegisterMG42();
	RegisterPANZERS();
	RegisterMG34();
	RegisterSTICK();
	RegisterSPADE();
}