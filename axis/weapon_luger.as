enum LUGERAnimation_e
{
	LUGER_IDLE1 = 0,
	LUGER_IDLE2,
	LUGER_IDLE3,
	LUGER_SHOOT,
	LUGER_SHOOT_EMPTY,
	LUGER_RELOAD_EMPTY,
	LUGER_RELOAD,
	LUGER_DRAW,
	LUGER_EMPTY_IDLE
};

const int LUGER_MAX_CARRY			= 60;
const int LUGER_DEFAULT_GIVE		= 36;
const int LUGER_MAX_CLIP			= 8;
const int LUGER_WEIGHT				= 25;

class weapon_luger : ScriptBasePlayerWeaponEntity
{
	int m_iShell;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/luger/w_luger.mdl" );
		
		self.m_iDefaultAmmo = LUGER_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/luger/w_luger.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/luger/v_luger.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/luger/p_luger.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/luger_shoot1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/luger_reload_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/luger_reload_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/luger_reload_boltforward.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/luger_shoot1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/luger_reload_clipout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/luger_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/luger_reload_boltforward.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_luger.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_luger.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= LUGER_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= LUGER_MAX_CLIP;
		info.iSlot		= 1;
		info.iPosition	= 6;
		info.iFlags		= 0;
		info.iWeight	= LUGER_WEIGHT;
		
		return true;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer ( pPlayer ) )
		{
			NetworkMessage axis2( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				axis2.WriteLong( self.m_iId );
			axis2.End();
			return true;
		}
		
		return false;
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/luger/v_luger.mdl" ), self.GetP_Model( "models/ww2projekt/luger/p_luger.mdl" ), LUGER_DRAW, "onehanded" );
			
			float deployTime = 0.89f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	void PrimaryAttack()
	{
		if( self.m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.223;
		
		self.m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if( self.m_iClip == 0 )
			self.SendWeaponAnim( LUGER_SHOOT_EMPTY, 0, 0 );
		else
			self.SendWeaponAnim( LUGER_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/luger_shoot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 16;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = Math.RandomFloat( -1.9, -1.1 );

		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming + x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
		
		Vector vecShellVelocity, vecShellOrigin;
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 13, 6, -10 );
		
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void Reload()
	{
		if( self.m_iClip < LUGER_MAX_CLIP )
			BaseClass.Reload();
		
		if( self.m_iClip == 0 )
			self.DefaultReload( LUGER_MAX_CLIP, LUGER_RELOAD_EMPTY, 2.143, 0 );
		else
			self.DefaultReload( LUGER_MAX_CLIP, LUGER_RELOAD, 2.143, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		if( self.m_iClip <= 0 )
			self.SendWeaponAnim( LUGER_EMPTY_IDLE );
		else
			self.SendWeaponAnim( LUGER_IDLE1 );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetLUGERName()
{
	return "weapon_luger";
}

void RegisterLUGER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetLUGERName(), GetLUGERName() );
	g_ItemRegistry.RegisterWeapon( GetLUGERName(), "ww2projekt", "9mm" );
}