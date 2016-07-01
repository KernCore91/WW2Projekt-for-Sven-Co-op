enum MG34Animation_e
{
	MG34_DOWNIDLE = 0,
	MG34_DOWNIDLE_EMPTY,
	MG34_DOWNTOUP,
	MG34_DOWNTOUP_EMPTY,
	MG34_DOWNSHOOT,
	MG34_DOWNSHOOT_EMPTY,
	MG34_UPIDLE,
	MG34_UPIDLE_EMPTY,
	MG34_UPTODOWN,
	MG34_UPTODOWN_EMPTY,
	MG34_UPSHOOT,
	MG34_UPSHOOT_EMPTY,
	MG34_RELOAD
};

const int MG34_DEFAULT_GIVE			= 600;
const int MG34_MAX_CARRY			= 175;
const int MG34_MAX_CLIP				= 75;
const int MG34_WEIGHT				= 50;

class weapon_mg34 : ScriptBasePlayerWeaponEntity
{
	int g_iCurrentMode;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/mg34/w_mg34.mdl" );
		
		self.m_iDefaultAmmo = MG34_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/mg34/w_mg34.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/mg34/v_mg34.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/mg34/p_mg34bd.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mg34_shoot1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgup.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgdeploy.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgchainpull2.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgclampup.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mg34_magout.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mg34_magin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgclampdown.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgbolt.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mg34_shoot1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgup.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgdeploy.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgchainpull2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgclampup.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mg34_magout.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mg34_magin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgclampdown.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgbolt.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_mg34.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_mg34.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= MG34_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= MG34_MAX_CLIP;
		info.iSlot		= 3;
		info.iPosition	= 7;
		info.iFlags		= 0;
		info.iWeight	= MG34_WEIGHT;
		
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
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer ( pPlayer ) )
		{
			NetworkMessage axis8( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				axis8.WriteLong( self.m_iId );
			axis8.End();
			return true;
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			if( self.m_iClip > 0 )
				bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/mg34/v_mg34.mdl" ), self.GetP_Model( "models/ww2projekt/mg34/p_mg34bd.mdl" ), MG34_DOWNTOUP, "saw" );
			else
				bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/mg34/v_mg34.mdl" ), self.GetP_Model( "models/ww2projekt/mg34/p_mg34bd.mdl" ), MG34_DOWNTOUP_EMPTY, "saw" );
				
			float deployTime = 0.7f;
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.065;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		self.m_iClip -= 1;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if( g_iCurrentMode == BIPOD_UNDEPLOY )
		{
			self.SendWeaponAnim( MG34_UPSHOOT );
			
			if( self.m_iClip == 0 )
				self.SendWeaponAnim( MG34_UPSHOOT_EMPTY );
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			self.SendWeaponAnim( MG34_DOWNSHOOT );
			
			if( self.m_iClip == 0 )
				self.SendWeaponAnim( MG34_DOWNSHOOT_EMPTY );
		}
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/mg34_shoot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		int m_iBulletDamage = 28;
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
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
			self.m_pPlayer.pev.punchangle.x -= 1.4f;
			self.m_pPlayer.pev.punchangle.y -= Math.RandomFloat( -0.5f, 0.5f );
			
			if( self.m_pPlayer.pev.punchangle.x < -13 )
				self.m_pPlayer.pev.punchangle.x = -13;
			
			vecDir = vecAiming + x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			self.m_pPlayer.pev.punchangle.x = -1.5;
			
			vecDir = vecAiming + x * VECTOR_CONE_3DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;
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
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 11, 8, -8 );
		
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
					if( self.m_pPlayer.pev.flags & FL_DUCKING != 0 && self.m_pPlayer.pev.flags & FL_ONGROUND != 0 )
					{
						g_iCurrentMode = BIPOD_DEPLOY;
						
						self.SendWeaponAnim( MG34_UPTODOWN );
						if( self.m_iClip == 0 )
							self.SendWeaponAnim( MG34_UPTODOWN_EMPTY );
				
						self.m_pPlayer.pev.maxspeed = -1.0;
						self.m_pPlayer.pev.fuser4 = 1;
						
						self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.45f;
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

				self.SendWeaponAnim( MG34_DOWNTOUP );
				if( self.m_iClip == 0 )
					self.SendWeaponAnim( MG34_DOWNTOUP_EMPTY );

				self.m_pPlayer.pev.maxspeed = 0;
				self.m_pPlayer.pev.fuser4 = 0;
				
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.65f;

				break;
			}
		}
	}
	
	void Reload()
	{
		if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			if( self.m_iClip < MG34_MAX_CLIP )
				BaseClass.Reload();
			
			self.DefaultReload( MG34_MAX_CLIP, MG34_RELOAD, 5.73, 0 );
		}
		else
			g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, " You need to deploy before reloading \n" );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( g_iCurrentMode == BIPOD_UNDEPLOY )
		{
			self.SendWeaponAnim( MG34_UPIDLE );
			if( self.m_iClip == 0 )
				self.SendWeaponAnim( MG34_UPIDLE_EMPTY );
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			self.SendWeaponAnim( MG34_DOWNIDLE );
			if( self.m_iClip == 0 )
				self.SendWeaponAnim( MG34_DOWNIDLE_EMPTY );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
	
	void ItemPreFrame()
	{
		if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			//self.m_pPlayer.pev.flags = FL_DUCKING;
			//self.m_pPlayer.pev.button = IN_DUCK;
			
			Vector vecAngles = self.m_pPlayer.pev.angles;
			Vector m_ShootAngles = self.m_pPlayer.pev.angles;
			Vector vecViewAngles = self.m_pPlayer.pev.v_angle;
			Vector m_ViewShootAngles = self.m_pPlayer.pev.v_angle;
			
			/**if( abs( vecAngles.x - m_ShootAngles.x ) > 90 )
			{
				if( vecAngles != self.m_pPlayer.pev.angles )
				{
					vecAngles.x = m_ShootAngles.x + Math.min( 90, Math.max( -90, vecAngles.x - m_ShootAngles.x ) );
					self.m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
				}
			}*/
			
			/**abs( vecViewAngles.x - m_ViewShootAngles.x ) > 90;
			vecViewAngles.x = m_ViewShootAngles.x + Math.min( 90, Math.max( -90, vecViewAngles.x - m_ViewShootAngles.x ) );
			if( vecViewAngles != self.m_pPlayer.pev.v_angle )
					self.m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;*/
			
			//g_Game.AlertMessage( at_console, "Value: " + self.m_pPlayer.pev.fixangle );
			//self.m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
			//vecAngles.x = vecVAngles.x + Math.min( 90, Math.max( -90, vecAngles.x - vecVAngles.x ) );
		}
		
		BaseClass.ItemPreFrame();
	}
}

string GetMG34Name()
{
	return "weapon_mg34";
}

void RegisterMG34()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetMG34Name(), GetMG34Name() );
	g_ItemRegistry.RegisterWeapon( GetMG34Name(), "ww2projekt", "556" );
}