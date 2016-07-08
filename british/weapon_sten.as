enum STENAnimation_e
{
	STEN_IDLE = 0,
	STEN_RELOAD,
	STEN_DRAW,
	STEN_SHOOT
};

const int STEN_MAX_CARRY		= 250;
const int STEN_DEFAULT_GIVE		= 96;
const int STEN_MAX_CLIP			= 32;
const int STEN_WEIGHT			= 25;

class weapon_sten : ScriptBasePlayerWeaponEntity
{
	int m_iShell;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/sten/w_sten.mdl" );
		
		self.m_iDefaultAmmo = STEN_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/sten/w_sten.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/sten/p_sten.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/sten/v_sten.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		//Precache for download
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/sten_shoot.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/sten_reload_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/sten_reload_clipin.wav" );
		
		//Precache for the Engine
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/sten_shoot.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/sten_reload_clipout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/sten_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_sten.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_sten.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= STEN_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= STEN_MAX_CLIP;
		info.iSlot		= 2;
		info.iPosition	= 6;
		info.iFlags		= 0;
		info.iWeight	= STEN_WEIGHT;
		
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer ( pPlayer ) )
		{
			NetworkMessage british2( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				british2.WriteLong( self.m_iId );
			british2.End();
			return true;
		}
		return false;
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
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/sten/v_sten.mdl" ), self.GetP_Model( "models/ww2projekt/sten/p_sten.mdl" ), STEN_DRAW, "mp5" );
		
			float deployTime = 0.9f;
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
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.099;
		
		self.m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		self.SendWeaponAnim( STEN_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/sten_shoot.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 25;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = Math.RandomFloat( -1.75, -1.2 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming + x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_3DEGREES.y * g_Engine.v_up;

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
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 16, 6, -7 );
		
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void Reload()
	{
		if( self.m_iClip < STEN_MAX_CLIP )
			BaseClass.Reload();

		self.DefaultReload( STEN_MAX_CLIP, STEN_RELOAD, 2.925, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( STEN_IDLE );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetSTENName()
{
	return "weapon_sten";
}

void RegisterSTEN()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetSTENName(), GetSTENName() );
	g_ItemRegistry.RegisterWeapon( GetSTENName(), "ww2projekt", "9mm" );
}