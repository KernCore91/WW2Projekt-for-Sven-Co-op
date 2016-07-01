enum ENFIELDAnimation_e
{
	ENFIELD_IDLE = 0,
	ENFIELD_SHOOT,
	ENFIELD_RELOAD,
	ENFIELD_DRAW,
	ENFIELD_RELOAD_LONG,
	ENFIELD_STAB
};

const int ENFIELD_MAX_CARRY		= 36;
const int ENFIELD_DEFAULT_GIVE	= 30;
const int ENFIELD_MAX_CLIP		= 10;
const int ENFIELD_WEIGHT		= 30;

class weapon_enfield : ScriptBasePlayerWeaponEntity
{
	int m_iShell;
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/enfield/w_enfield.mdl" );
		
		self.m_iDefaultAmmo = ENFIELD_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/enfield/w_enfield.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/enfield/v_enfield.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/enfield/p_enfield.mdl" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= ENFIELD_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= ENFIELD_MAX_CLIP;
		info.iSlot		= 3;
		info.iPosition	= 5;
		info.iFlags		= 0;
		info.iWeight	= ENFIELD_WEIGHT;
		
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
			NetworkMessage british1( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				british1.WriteLong( self.m_iId );
			british1.End();
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
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/enfield/v_enfield.mdl" ), self.GetP_Model( "models/ww2projekt/enfield/p_enfield.mdl" ), ENFIELD_DRAW, "sniper" );
			
			float deployTime = 0.84f;
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.55;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		self.SendWeaponAnim( ENFIELD_SHOOT, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/kar_shoot.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 100;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = -3;

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.m_pPlayer.edict(), tr );
		
		Vector vecShellVelocity, vecShellOrigin;
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 19, 9, -7 );
		
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
	}
	
	void Reload()
	{
		if( self.m_iClip < ENFIELD_MAX_CLIP )
			BaseClass.Reload();
			
		if( self.m_iClip >= 5 )
			self.DefaultReload( ENFIELD_MAX_CLIP, ENFIELD_RELOAD, 3.68, 0 );
		else if( self.m_iClip < 5 )
			self.DefaultReload( ENFIELD_MAX_CLIP, ENFIELD_RELOAD_LONG, 5.48, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( ENFIELD_IDLE );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetENFIELDName()
{
	return "weapon_enfield";
}

void RegisterENFIELD()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetENFIELDName(), GetENFIELDName() );
	g_ItemRegistry.RegisterWeapon( GetENFIELDName(), "ww2projekt", "357" );
}