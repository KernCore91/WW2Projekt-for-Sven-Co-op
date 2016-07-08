enum MG42Animation_e
{
	MG42_UPIDLE = 0,
	MG42_UPIDLE8,
	MG42_UPIDLE7,
	MG42_UPIDLE6,
	MG42_UPIDLE5,
	MG42_UPIDLE4,
	MG42_UPIDLE3,
	MG42_UPIDLE2,
	MG42_UPIDLE1,
	MG42_UPIDLE_EMPTY,
	MG42_DOWNIDLE,
	MG42_DOWNIDLE8,
	MG42_DOWNIDLE7,
	MG42_DOWNIDLE6,
	MG42_DOWNIDLE5,
	MG42_DOWNIDLE4,
	MG42_DOWNIDLE3,
	MG42_DOWNIDLE2,
	MG42_DOWNIDLE1,
	MG42_DOWNIDLE_EMPTY,
	MG42_DOWNTOUP,
	MG42_DOWNTOUP8,
	MG42_DOWNTOUP7,
	MG42_DOWNTOUP6,
	MG42_DOWNTOUP5,
	MG42_DOWNTOUP4,
	MG42_DOWNTOUP3,
	MG42_DOWNTOUP2,
	MG42_DOWNTOUP1,
	MG42_DOWNTOUP_EMPTY,
	MG42_UPTODOWN,
	MG42_UPTODOWN8,
	MG42_UPTODOWN7,
	MG42_UPTODOWN6,
	MG42_UPTODOWN5,
	MG42_UPTODOWN4,
	MG42_UPTODOWN3,
	MG42_UPTODOWN2,
	MG42_UPTODOWN1,
	MG42_UPTODOWN_EMPTY,
	MG42_UPSHOOT,
	MG42_UPSHOOT8,
	MG42_UPSHOOT7,
	MG42_UPSHOOT6,
	MG42_UPSHOOT5,
	MG42_UPSHOOT4,
	MG42_UPSHOOT3,
	MG42_UPSHOOT2,
	MG42_UPSHOOT1,
	MG42_DOWNSHOOT,
	MG42_DOWNSHOOT8,
	MG42_DOWNSHOOT7,
	MG42_DOWNSHOOT6,
	MG42_DOWNSHOOT5,
	MG42_DOWNSHOOT4,
	MG42_DOWNSHOOT3,
	MG42_DOWNSHOOT2,
	MG42_DOWNSHOOT1,
	MG42_RELOAD
}; //THATS A VERY BIG NUMBER OF ANIMATIONS DONT YA THINK?

const int MG42_DEFAULT_GIVE		= 400;
const int MG42_MAX_CARRY		= 600;
const int MG42_MAX_CLIP			= 200;
const int MG42_WEIGHT			= 50;

class weapon_mg42 : ScriptBasePlayerWeaponEntity
{
	int g_iCurrentMode;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/mg42/w_mg42.mdl" );
		
		self.m_iDefaultAmmo = MG42_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/mg42/w_mg42.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/mg42/v_mg42.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/mg42/p_mg42bu.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/mg42/p_mg42bd.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mg42_shoot1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgchainpull.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgclampup.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/bulletchain.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgchainpull.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgclampdown.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgbolt.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgup.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/mgdeploy.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mg42_shoot1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgchainpull.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgclampup.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/bulletchain.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgchainpull.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgclampdown.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgbolt.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgup.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/mgdeploy.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_mg42.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_mg42.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= MG42_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= MG42_MAX_CLIP;
		info.iSlot		= 5;
		info.iPosition	= 7;
		info.iFlags		= 0;
		info.iWeight	= MG42_WEIGHT;
		
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer ( pPlayer ) )
		{
			NetworkMessage axis11( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				axis11.WriteLong( self.m_iId );
			axis11.End();
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
		int AmmoAnim; //here we go
		bool bResult;
		{
			AmmoAnim = self.m_iClip <= 8 ? MG42_DOWNTOUP_EMPTY - self.m_iClip : MG42_DOWNTOUP;
			
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/mg42/v_mg42.mdl" ), self.GetP_Model( "models/ww2projekt/mg42/p_mg42bu.mdl" ), AmmoAnim, "saw" );
			
			float deployTime = 1.20f;
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
		int AmmoAnim; //again...
		
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.045;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		self.m_iClip -= 1;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if( g_iCurrentMode == BIPOD_UNDEPLOY )
		{
			if( self.m_iClip == 7 )
				AmmoAnim = MG42_UPSHOOT8;
			else if( self.m_iClip == 6 )
				AmmoAnim = MG42_UPSHOOT7;
			else if( self.m_iClip == 5 )
				AmmoAnim = MG42_UPSHOOT6;
			else if( self.m_iClip == 4 )
				AmmoAnim = MG42_UPSHOOT5;
			else if( self.m_iClip == 3 )
				AmmoAnim = MG42_UPSHOOT4;
			else if( self.m_iClip == 2 )
				AmmoAnim = MG42_UPSHOOT3;
			else if( self.m_iClip == 1 )
				AmmoAnim = MG42_UPSHOOT2;
			else if( self.m_iClip == 0 )
				AmmoAnim = MG42_UPSHOOT1;
			else
				AmmoAnim = MG42_UPSHOOT;
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			if( self.m_iClip == 7 )
				AmmoAnim = MG42_DOWNSHOOT8;
			else if( self.m_iClip == 6 )
				AmmoAnim = MG42_DOWNSHOOT7;
			else if( self.m_iClip == 5 )
				AmmoAnim = MG42_DOWNSHOOT6;
			else if( self.m_iClip == 4 )
				AmmoAnim = MG42_DOWNSHOOT5;
			else if( self.m_iClip == 3 )
				AmmoAnim = MG42_DOWNSHOOT4;
			else if( self.m_iClip == 2 )
				AmmoAnim = MG42_DOWNSHOOT3;
			else if( self.m_iClip == 1 )
				AmmoAnim = MG42_DOWNSHOOT2;
			else if( self.m_iClip == 0 )
				AmmoAnim = MG42_DOWNSHOOT1;
			else
				AmmoAnim = MG42_DOWNSHOOT;
		}
		
		self.SendWeaponAnim( AmmoAnim, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/mg42_shoot1.wav", 0.85, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 20;
		
		self.m_pPlayer.FireBullets( 2, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

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
			self.m_pPlayer.pev.punchangle.x -= 1.5;
			self.m_pPlayer.pev.punchangle.y -= Math.RandomFloat( -0.5f, 0.5f );
			
			if( self.m_pPlayer.pev.punchangle.x < -15 ) //defines a max recoil
				self.m_pPlayer.pev.punchangle.x = -15;
			
			vecDir = vecAiming + x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			self.m_pPlayer.pev.punchangle.x = -1.65;
			
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
		
		GetDefaultShellInfo( self.m_pPlayer, vecShellVelocity, vecShellOrigin, 14, 7, -8 );
		
		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, self.m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void SecondaryAttack()
	{
		int AmmoAnim; // oh shiet...

		switch( g_iCurrentMode )
		{
			case BIPOD_UNDEPLOY:
			{
				if( self.m_pPlayer.pev.waterlevel == WATERLEVEL_DRY || self.m_pPlayer.pev.waterlevel == WATERLEVEL_FEET )
				{
					if( self.m_pPlayer.pev.flags & FL_DUCKING != 0 && self.m_pPlayer.pev.flags & FL_ONGROUND != 0 ) //needs to be fully crouched and not jumping-crouched
					{
						g_iCurrentMode = BIPOD_DEPLOY;
					
						AmmoAnim = self.m_iClip <= 8 ? MG42_UPTODOWN_EMPTY - self.m_iClip : MG42_UPTODOWN;
				
						self.m_pPlayer.pev.maxspeed = -1.0;
						self.m_pPlayer.pev.fuser4 = 1;
						/**self.m_pPlayer.pev.button |= IN_DUCK;**/ //supposed to force the player to be always crouched
						/**self.m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
						self.m_pPlayer.pev.v_angle.x = Math.min( -90, 90 );
						self.m_pPlayer.pev.v_angle.z = Math.min( -90, 90 );
						self.m_pPlayer.pev.v_angle.y = Math.min( -90, 90 );**/ //supposed to limit the player view angle
						self.m_pPlayer.pev.weaponmodel = ( "models/ww2projekt/mg42/p_mg42bd.mdl" );
						self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.2f;
					}
					else if( self.m_pPlayer.pev.flags & FL_DUCKING == 0 )
					{
						if( self.m_pPlayer.pev.flags & FL_ONGROUND == 0 )
						{
							g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, "Crouch before deploying \n" );
							self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.000000001;
						}
						g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, "Crouch before deploying \n" );
						self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.000000001;
					}
				}
				else
				{
					g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, "Can not deploy while in the water \n" );
					self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.000000001;
				}
		
				self.SendWeaponAnim( AmmoAnim );
				break;
			}

			case BIPOD_DEPLOY:
			{
				g_iCurrentMode = BIPOD_UNDEPLOY;

				AmmoAnim = self.m_iClip <= 8 ? MG42_DOWNTOUP_EMPTY - self.m_iClip : MG42_DOWNTOUP;

				self.m_pPlayer.pev.maxspeed = 0;
				self.m_pPlayer.pev.fuser4 = 0;
				self.m_pPlayer.pev.weaponmodel = ( "models/ww2projekt/mg42/p_mg42bu.mdl" );
				
				self.SendWeaponAnim( AmmoAnim );
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.0f;

				break;
			}
		}
	}
	
	void Reload()
	{
		if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			if( self.m_iClip < MG42_MAX_CLIP )
				BaseClass.Reload();
			
			self.DefaultReload( MG42_MAX_CLIP, MG42_RELOAD, 6.95, 0 );
		}
		else
			g_EngineFuncs.ClientPrintf( self.m_pPlayer, print_center, " You need to deploy before reloading \n" );
	}
	
	void WeaponIdle()
	{
		int AmmoAnim; //Again with this?

		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( g_iCurrentMode == BIPOD_UNDEPLOY )
		{
			AmmoAnim = self.m_iClip <= 8 ? MG42_UPIDLE_EMPTY - self.m_iClip : MG42_UPIDLE;
		}
		else if( g_iCurrentMode == BIPOD_DEPLOY )
		{
			AmmoAnim = self.m_iClip <= 8 ? MG42_DOWNIDLE_EMPTY - self.m_iClip : MG42_DOWNIDLE;
		}
		
		self.SendWeaponAnim( AmmoAnim );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetMG42Name()
{
	return "weapon_mg42";
}

void RegisterMG42()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetMG42Name(), GetMG42Name() );
	g_ItemRegistry.RegisterWeapon( GetMG42Name(), "ww2projekt", "556" );
}