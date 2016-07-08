#include "ShellEject"
#include "british/weapon_enfield"
#include "british/weapon_sten"
#include "british/weapon_webley"
#include "british/weapon_enfieldscoped"
#include "british/weapon_bren"
#include "british/weapon_piat"
#include "british/weapon_mills"
#include "british/weapon_fairbairn"

void MapInit()
{
	RegisterENFIELD();
	RegisterSTEN();
	RegisterWEBLEY();
	RegisterENFIELDS();
	RegisterBREN();
	RegisterPIAT();
	RegisterSTICK();
	RegisterFAIRB();
}