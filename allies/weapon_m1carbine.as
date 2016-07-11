enum M1CARBINEAnimation_e
{
	M1CARB_IDLE = 0,
	M1CARB_RELOAD,
	M1CARB_DRAW,
	M1CARB_SHOOT,
	M1CARB_FASTDRAW
};

const int M1CARB_MAX_CARRY			= 36;
const int M1CARB_DEFAULT_GIVE		= 20;
const int M1CARB_MAX_CLIP			= 15;
const int M1CARB_WEIGHT			= 25;

class weapon_m1carbine : ScriptBasePlayerWeaponEntity
{
	int m_iShell;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/m1carbine/w_fcarb.mdl" );
		
		self.m_iDefaultAmmo = M1CARB_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/m1carbine/w_fcarb.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/m1carbine/v_fcarb.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/m1carbine/p_fcarb.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/m1carbine_shoot.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/m1carbine_reload_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/m1carbine_reload_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/m1carbine_reload_boltback.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/m1carbine_reload_boltforward.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/m1carbine_shoot.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/m1carbine_reload_clipout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/m1carbine_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/m1carbine_reload_boltback.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/m1carbine_reload_boltforward.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_m1carbine.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_m1carbine.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= M1CARB_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= M1CARB_MAX_CLIP;
		info.iSlot		= 3;
		info.iPosition	= 9;
		info.iFlags		= 0;
		info.iWeight	= M1CARB_WEIGHT;
		
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
			NetworkMessage allies5( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				allies5.WriteLong( self.m_iId );
			allies5.End();
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
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/m1carbine/v_fcarb.mdl" ), self.GetP_Model( "models/ww2projekt/m1carbine/p_fcarb.mdl" ), M1CARB_DRAW, "m16" );
			
			float deployTime = 1.23f;
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.252;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		

		self.SendWeaponAnim( M1CARB_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/m1carbine_shoot.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 45;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = Math.RandomLong( -5, -4 );

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
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 16, 6, -10 );
		
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void Reload()
	{
		if( self.m_iClip < M1CARB_MAX_CLIP )
			BaseClass.Reload();

		self.DefaultReload( M1CARB_MAX_CLIP, M1CARB_RELOAD, 2.775, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( M1CARB_IDLE );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetM1CARBName()
{
	return "weapon_m1carbine";
}

void RegisterM1CARB()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetM1CARBName(), GetM1CARBName() );
	g_ItemRegistry.RegisterWeapon( GetM1CARBName(), "ww2projekt", "357" );
}