enum BARAnimation_e
{
	BAR_UPIDLE = 0,
	BAR_UPRELOAD,
	BAR_DRAW,
	BAR_UPSHOOT,
	BAR_UPTODOWN,
	BAR_DOWNIDLE,
	BAR_DOWNRELOAD,
	BAR_DOWNSHOOT,
	BAR_DOWNTOUP
};

const int BAR_MAX_CARRY		= 600;
const int BAR_DEFAULT_GIVE	= 120;
const int BAR_MAX_CLIP		= 20;
const int BAR_WEIGHT		= 35;

class weapon_bar : ScriptBasePlayerWeaponEntity
{
	int g_iCurrentMode;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/bar/w_bar.mdl" );
		
		self.m_iDefaultAmmo = BAR_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/bar/w_bar.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/bar/v_barSUSHI.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/bar/p_barbu.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/bar/p_barbd.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/bar_shoot.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/bar_reload_clipout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/bar_reload_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mp44_draw_slideback.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgdeploy.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/bar_flip.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/bar_shoot.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/bar_reload_clipout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/bar_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mp44_draw_slideback.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgdeploy.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/bar_flip.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_bar.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_bar.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= BAR_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= BAR_MAX_CLIP;
		info.iSlot		= 2;
		info.iPosition	= 9;
		info.iFlags		= 0;
		info.iWeight	= BAR_WEIGHT;
		
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer ( pPlayer ) )
		{
			NetworkMessage allies7( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				allies7.WriteLong( self.m_iId );
			allies7.End();
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
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/bar/v_barSUSHI.mdl" ), self.GetP_Model( "models/ww2projekt/bar/p_barbu.mdl" ), BAR_DRAW, "saw" );
			
			float deployTime = 1.06f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	void Holster( int skipLocal = 0 ) 
	{
		self.m_fInReload = false;
		
		if( g_iCurrentMode == BIPOD_DEPLOY )
			SecondaryAttack();
		
		g_iCurrentMode = 0;
		self.m_pPlayer.pev.maxspeed = 0;
		self.m_pPlayer.pev.fuser4 = 0;
		
		BaseClass.Holster( skipLocal );
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		self.m_iClip -= 1;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if( g_iCurrentMode == BIPOD_UNDEPLOY )
		{
			self.SendWeaponAnim( BAR_UPSHOOT, 0, 0 );
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			self.SendWeaponAnim( BAR_DOWNSHOOT, 0, 0 );
		}
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/bar_shoot.wav", 0.85, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 43;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
		
		Vector vecDir;
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		if( g_iCurrentMode == BIPOD_UNDEPLOY )
		{
			self.m_pPlayer.pev.punchangle.x -= 1.65;
			self.m_pPlayer.pev.punchangle.y -= Math.RandomFloat( -0.5f, 0.5f );
			
			vecDir = vecAiming + x * VECTOR_CONE_4DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_3DEGREES.y * g_Engine.v_up;
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			self.m_pPlayer.pev.punchangle.x = 1.1;
			
			vecDir = vecAiming + x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;
		}
		
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
		
		if( g_iCurrentMode == BIPOD_UNDEPLOY )
			GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 13, 6, -8 );
		else if( g_iCurrentMode == BIPOD_DEPLOY )
			GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 14, 4, -7 );
			
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void SecondaryAttack()
	{
		switch( g_iCurrentMode )
		{
			case BIPOD_UNDEPLOY:
			{
				if( self.m_pPlayer.pev.waterlevel == WATERLEVEL_DRY || self.m_pPlayer.pev.waterlevel == WATERLEVEL_FEET )
				{
					if( self.m_pPlayer.pev.flags & FL_DUCKING != 0 && self.m_pPlayer.pev.flags & FL_ONGROUND != 0 ) //needs to be fully crouched and not jump-crouched
					{
						g_iCurrentMode = BIPOD_DEPLOY;
						
						self.SendWeaponAnim( BAR_UPTODOWN );
						
						self.m_pPlayer.pev.maxspeed = -1.0;
						self.m_pPlayer.pev.fuser4 = 1;
						self.m_pPlayer.pev.weaponmodel = ( "models/ww2projekt/bar/p_barbd.mdl" );
						self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.3f;
					}
					else if( self.m_pPlayer.pev.flags & FL_DUCKING == 0 )
					{
						if( self.m_pPlayer.pev.flags & FL_ONGROUND == 0 )
							g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, "Crouch before deploying \n" );
						
						g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, "Crouch before deploying \n" );
					}
				}
				else
					g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, "Can not deploy while in the water \n" );
				
				break;
			}
			
			case BIPOD_DEPLOY:
			{
				g_iCurrentMode = BIPOD_UNDEPLOY;
				
				self.SendWeaponAnim( BAR_DOWNTOUP );
				
				self.m_pPlayer.pev.maxspeed = 0;
				self.m_pPlayer.pev.fuser4 = 0;
				
				self.m_pPlayer.pev.weaponmodel = ( "models/ww2projekt/bar/p_barbu.mdl" );
				
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.65f;
				break;
			}
		}
	}
	
	void Reload()
	{
		if( self.m_iClip < BAR_MAX_CLIP )
		{
			if( g_iCurrentMode == BIPOD_DEPLOY )
			{
				self.DefaultReload( BAR_MAX_CLIP, BAR_DOWNRELOAD, 3.4, 0 );
			}
			else if( g_iCurrentMode == BIPOD_UNDEPLOY )
			{
				self.DefaultReload( BAR_MAX_CLIP, BAR_UPRELOAD, 3.16, 0 );
			}
			
			BaseClass.Reload();
		}
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		if( g_iCurrentMode == BIPOD_UNDEPLOY )
		{
			self.SendWeaponAnim( BAR_UPIDLE );
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			self.SendWeaponAnim( BAR_DOWNIDLE );
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetBARName()
{
	return "weapon_bar";
}

void RegisterBAR()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetBARName(), GetBARName() );
	g_ItemRegistry.RegisterWeapon( GetBARName(), "ww2projekt", "556" );
}