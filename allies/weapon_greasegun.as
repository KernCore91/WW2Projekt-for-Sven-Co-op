enum GREASEGUNAnimation_e
{
	GREASEGUN_IDLE = 0,
	GREASEGUN_RELOAD,
	GREASEGUN_DRAW,
	GREASEGUN_SHOOT1,
	GREASEGUN_SHOOT2,
	GREASEGUN_IDLE_EMPTY,
	GREASEGUN_FASTDRAW
};

const int GREASEGUN_MAX_CARRY		= 250;
const int GREASEGUN_DEFAULT_GIVE	= 150;
const int GREASEGUN_MAX_CLIP		= 30;
const int GREASEGUN_WEIGHT			= 25;

class weapon_greasegun : ScriptBasePlayerWeaponEntity
{
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/greasegun/w_greasegun.mdl" );
		
		self.m_iDefaultAmmo = GREASEGUN_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/greasegun/w_greasegun.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/greasegun/v_greasegun.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/greasegun/p_grease.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/greasegun_shoot.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mp40_reload_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mp44_reload_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mp44_draw_slideback.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/greasegun_shoot.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mp40_reload_clipout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mp44_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mp44_draw_slideback.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_greasegun.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_greasegun.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= GREASEGUN_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= GREASEGUN_MAX_CLIP;
		info.iSlot		= 2;
		info.iPosition	= 8;
		info.iFlags		= 0;
		info.iWeight	= GREASEGUN_WEIGHT;
		
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
			NetworkMessage allies3( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				allies3.WriteLong( self.m_iId );
			allies3.End();
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
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/greasegun/v_greasegun.mdl" ), self.GetP_Model( "models/ww2projekt/greasegun/p_grease.mdl" ), GREASEGUN_FASTDRAW, "mp5" );
			
			float deployTime = 1.01f;
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
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.143;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		switch ( g_PlayerFuncs.SharedRandomLong( self.m_pPlayer.random_seed, 0, 1 ) )
		{
			case 0: self.SendWeaponAnim( GREASEGUN_SHOOT1, 0, 0 ); break;
			case 1: self.SendWeaponAnim( GREASEGUN_SHOOT2, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/greasegun_shoot.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 30;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = Math.RandomFloat( -2.75f, -1.75f );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
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
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 17, 4, -9 );
		
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void Reload()
	{
		if( self.m_iClip < GREASEGUN_MAX_CLIP )
			BaseClass.Reload();

		self.DefaultReload( GREASEGUN_MAX_CLIP, GREASEGUN_RELOAD, 4.1, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		if( self.m_iClip <= 0 )
			self.SendWeaponAnim( GREASEGUN_IDLE_EMPTY );
		else
			self.SendWeaponAnim( GREASEGUN_IDLE );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetGREASEGUNName()
{
	return "weapon_greasegun";
}

void RegisterGREASEGUN()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetGREASEGUNName(), GetGREASEGUNName() );
	g_ItemRegistry.RegisterWeapon( GetGREASEGUNName(), "ww2projekt", "9mm" );
}