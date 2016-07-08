enum FG42Animation_e
{
	FG42_UP_IDLE = 0,
	FG42_UP_RELOAD,
	FG42_UP_DRAW,
	FG42_UP_SHOOT,
	FG42_UP_DOWN,
	FG42_DOWN_IDLE,
	FG42_DOWN_RELOAD,
	FG42_DOWN_SHOOT,
	FG42_DOWN_UP,
	FG42_UP_OUTOFWAY
};

const int FG42_MAX_CARRY		= 600;
const int FG42_DEFAULT_GIVE		= 120;
const int FG42_MAX_CLIP			= 20;
const int FG42_WEIGHT			= 25;

class weapon_fg42 : ScriptBasePlayerWeaponEntity
{
	int g_iCurrentMode;
	int m_iShell;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/fg42/w_fg42s.mdl" );
		
		self.m_iDefaultAmmo = G43_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/fg42/w_fg42s.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/fg42/v_scopedfg42.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/fg42/p_fg42s.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/fg42_shoot1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/fg42_reload_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/fg42_reload_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mp44_draw_slideback.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/fg42_shoot1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/fg42_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/fg42_reload_clipout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mp44_draw_slideback.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_fg42.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/german_scope4.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_fg42.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= FG42_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= FG42_MAX_CLIP;
		info.iSlot		= 2;
		info.iPosition	= 8;
		info.iFlags		= 0;
		info.iWeight	= FG42_WEIGHT;
		
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
			NetworkMessage axis5( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				axis5.WriteLong( self.m_iId );
			axis5.End();
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
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/fg42/v_scopedfg42.mdl" ), self.GetP_Model( "models/ww2projekt/fg42/p_fg42s.mdl" ), FG42_UP_DRAW, "m16" );
			
			float deployTime = 0.95f;
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
		}
		else if ( self.m_fInZoom == false )
		{
			SetFOV( zoomedFOV );
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
		
		if( g_iCurrentMode != MODE_UNSCOPE )
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.175;
		else
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		self.SendWeaponAnim( FG42_UP_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/fg42_shoot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 39;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = Math.RandomFloat( -3.0f, -1.9f );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir;
		
		if( g_iCurrentMode == MODE_SCOPE )
			vecDir = vecAiming + x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;
		else
			vecDir = vecAiming + x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

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
	
	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3f;
		switch ( g_iCurrentMode )
		{
			case MODE_UNSCOPE:
			{
				g_iCurrentMode = MODE_SCOPE;
				ToggleZoom( 45 );
				self.m_pPlayer.pev.maxspeed = 180;
				break;
			}
		
			case MODE_SCOPE:
			{
				g_iCurrentMode = MODE_UNSCOPE;
				ToggleZoom( 0 );
				self.m_pPlayer.pev.maxspeed = 0;
				break;
			}
		}
	}
	
	void Reload()
	{
		if( self.m_iClip < FG42_MAX_CLIP )
		{	
			BaseClass.Reload();
			g_iCurrentMode = 0;
			ToggleZoom( 0 );
			self.m_pPlayer.pev.maxspeed = 0;
		}
		self.DefaultReload( FG42_MAX_CLIP, FG42_UP_RELOAD, 3.875, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( FG42_UP_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetFG42Name()
{
	return "weapon_fg42";
}

void RegisterFG42()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetFG42Name(), GetFG42Name() );
	g_ItemRegistry.RegisterWeapon( GetFG42Name(), "ww2projekt", "556" );
}