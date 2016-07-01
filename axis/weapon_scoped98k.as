enum ScopedK98Animation_e
{
	SCOPED98K_IDLE = 0,
	SCOPED98K_SHOOT,
	SCOPED98K_RELOAD,
	SCOPED98K_DRAW,
	SCOPED98K_STAB1,
	SCOPED98K_STAB2,
	SCOPED98K_EMPTY_IDLE
};

const int SCOPED98K_MAX_CARRY			= 36;
const int SCOPED98K_DEFAULT_GIVE		= 20;
const int SCOPED98K_MAX_CLIP			= 5;
const int SCOPED98K_WEIGHT				= 25;

class weapon_scoped98k : ScriptBasePlayerWeaponEntity
{
	int m_iShell;
	int g_iCurrentMode;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/scoped98k/w_scoped98k.mdl" );
		
		self.m_iDefaultAmmo = SCOPED98K_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/scoped98k/p_k98s.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/scoped98k/v_scoped98kBETA.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/scoped98k/w_scoped98k.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/kar_shoot1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/boltback.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/boltforward.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/tommy_reload_clipin.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/kar_shoot1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/boltback.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/boltforward.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/tommy_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/german_scope4.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_scoped98k.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_scoped98k.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= SCOPED98K_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= SCOPED98K_MAX_CLIP;
		info.iSlot		= 5;
		info.iPosition	= 5;
		info.iFlags		= 0;
		info.iWeight	= SCOPED98K_WEIGHT;
		
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
			NetworkMessage axis10( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				axis10.WriteLong( self.m_iId );
			axis10.End();
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
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/scoped98k/v_scoped98kBETA.mdl" ), self.GetP_Model( "models/ww2projekt/scoped98k/p_k98s.mdl" ), SCOPED98K_DRAW, "sniper" );
			
			float deployTime = 0.8f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	void Holster( int skipLocal = 0 ) 
	{
		self.m_fInReload = false;

		if ( self.m_fInZoom ) 
		{
			SecondaryAttack();
        }

		g_iCurrentMode = 0;
		ToggleZoom( 0 );
		self.m_pPlayer.pev.maxspeed = 0;
		self.m_pPlayer.m_szAnimExtension = "sniper";

		BaseClass.Holster( skipLocal );
	}
	
	void SetFOV( int fov )
	{
		self.m_pPlayer.pev.fov = self.m_pPlayer.m_iFOV = fov;
	}
	
	void ToggleZoom( int zoomedFOV )
	{
		if ( self.m_fInZoom == true )
		{
			SetFOV( 0 ); // 0 means reset to default fov
			self.m_pPlayer.m_szAnimExtension = "sniperscope";
		}
		else if ( self.m_fInZoom == false )
		{
			SetFOV( zoomedFOV );
			self.m_pPlayer.m_szAnimExtension = "sniper";
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.7;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		self.SendWeaponAnim( SCOPED98K_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/kar_shoot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 115;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = -7.5;

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming + x * g_vecZero.x * g_Engine.v_right + y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;
		
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
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 15, 7, -10 );
		
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.4f;
		switch ( g_iCurrentMode )
		{
			case MODE_NOSCOPE:
			{
				g_iCurrentMode = MODE_SCOPED;
				ToggleZoom( 20 );
				self.m_pPlayer.m_szAnimExtension = "sniperscope";
				self.m_pPlayer.pev.maxspeed = 150;
				break;
			}
		
			case MODE_SCOPED:
			{
				g_iCurrentMode = MODE_NOSCOPE;
				ToggleZoom( 0 );
				self.m_pPlayer.m_szAnimExtension = "sniper";
				self.m_pPlayer.pev.maxspeed = 0;
				break;
			}
		}
	}
	
	void Reload()
	{
		self.m_pPlayer.m_szAnimExtension = "sniper";
		if( self.m_iClip < SCOPED98K_MAX_CLIP )
		{	
			BaseClass.Reload();
			g_iCurrentMode = 0;
			ToggleZoom( 0 );
			self.m_pPlayer.pev.maxspeed = 0;
		}
		self.DefaultReload( SCOPED98K_MAX_CLIP, SCOPED98K_RELOAD, 3.361, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( SCOPED98K_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetSCOPED98KName()
{
	return "weapon_scoped98k";
}

void RegisterSCOPED98K()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetSCOPED98KName(), GetSCOPED98KName() );
	g_ItemRegistry.RegisterWeapon( GetSCOPED98KName(), "ww2projekt", "357" );
}