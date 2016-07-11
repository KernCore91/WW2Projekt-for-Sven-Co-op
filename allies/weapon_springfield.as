enum SPRINGFIELDAnimation_e
{
	SPRINGF_IDLE = 0,
	SPRINGF_SHOOT1,
	SPRINGF_SHOOT2,
	SPRINGF_RELOAD,
	SPRINGF_DRAW,
	SPRINGF_IDLE_EMPTY,
	SPRINGF_OUTOFWAY
};

const int SPRINGF_MAX_CARRY			= 36;
const int SPRINGF_DEFAULT_GIVE		= 20;
const int SPRINGF_MAX_CLIP			= 5;
const int SPRINGF_WEIGHT			= 25;

class weapon_springfield : ScriptBasePlayerWeaponEntity
{
	int m_iShell;
	int g_iCurrentMode;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/springfield/w_spring.mdl" );
		
		self.m_iDefaultAmmo = SPRINGF_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/springfield/w_spring.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/springfield/v_spring.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/springfield/p_spring.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/springfield_shoot.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/boltback.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/tommy_reload_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/boltforward.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/springfield_shoot.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/boltback.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/tommy_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/boltforward.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/allies_scope.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_springfield.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_springfield.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= SPRINGF_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= SPRINGF_MAX_CLIP;
		info.iSlot		= 5;
		info.iPosition	= 7;
		info.iFlags		= 0;
		info.iWeight	= SPRINGF_WEIGHT;
		
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
			NetworkMessage allies6( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				allies6.WriteLong( self.m_iId );
			allies6.End();
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
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/springfield/v_spring.mdl" ), self.GetP_Model( "models/ww2projekt/springfield/p_spring.mdl" ), SPRINGF_DRAW, "sniper" );
			
			float deployTime = 1.15f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	void Holster( int skipLocal = 0 ) 
	{
		self.m_fInReload = false;

		if ( self.m_fInZoom ) 
			SecondaryAttack();

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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.85;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		switch ( g_PlayerFuncs.SharedRandomLong( self.m_pPlayer.random_seed, 0, 1 ) )
		{
			case 0: self.SendWeaponAnim( SPRINGF_SHOOT1, 0, 0 ); break;
			case 1: self.SendWeaponAnim( SPRINGF_SHOOT2, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/springfield_shoot.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
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
		
		Vector vecDir;
		
		if( g_iCurrentMode == MODE_SCOPED )
			vecDir = vecAiming + x * g_vecZero.x * g_Engine.v_right + y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;
		else if( g_iCurrentMode == MODE_NOSCOPE )
			vecDir = vecAiming + x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;
		
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
		if( self.m_iClip < SPRINGF_MAX_CLIP )
		{	
			BaseClass.Reload();
			g_iCurrentMode = 0;
			ToggleZoom( 0 );
			self.m_pPlayer.pev.maxspeed = 0;
		}
		self.DefaultReload( SPRINGF_MAX_CLIP, SPRINGF_RELOAD, 2.74, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		if( self.m_iClip == 0 )
			self.SendWeaponAnim( SPRINGF_IDLE_EMPTY );
		else
			self.SendWeaponAnim( SPRINGF_IDLE );
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetSPRINGFName()
{
	return "weapon_springfield";
}

void RegisterSPRINGF()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetSPRINGFName(), GetSPRINGFName() );
	g_ItemRegistry.RegisterWeapon( GetSPRINGFName(), "ww2projekt", "357" );
}