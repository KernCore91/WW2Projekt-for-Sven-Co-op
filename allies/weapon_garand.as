enum M1GARANDAnimation_e
{
	M1GARAND_IDLE = 0,
	M1GARAND_SHOOT1,
	M1GARAND_SHOOT2,
	M1GARAND_SHOOT3,
	M1GARAND_SHOOT_EMPTY,
	M1GARAND_RELOAD,
	M1GARAND_DRAW,
	M1GARAND_IDLE_EMPTY,
	M1GARAND_DRAW_EMPTY,
	M1GARAND_SMASH,
	M1GARAND_SMASH_EMPTY
};

const int GARAND_MAX_CARRY		= 36;
const int GARAND_DEFAULT_GIVE		= 24;
const int GARAND_MAX_CLIP			= 8;
const int GARAND_WEIGHT			= 25;

class weapon_garand : ScriptBasePlayerWeaponEntity
{
	int m_iShell;
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/garand/w_garand.mdl" );
		
		self.m_iDefaultAmmo = GARAND_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/garand/w_garand.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/garand/v_garand.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/garand/p_garand.mdl" );
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/garand_shoot.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/garand_shoot_ping.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/garand_reload_clipin.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/knife_hit1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/knife_hit2.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/knife_hit3.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/knife_hit4.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/cbar_hit1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/cbar_hit2.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/knife_slash1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/knife_slash2.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/garand_shoot.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/garand_shoot_ping.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/garand_reload_clipin.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/knife_hit1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/knife_hit2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/knife_hit3.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/knife_hit4.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/cbar_hit1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/cbar_hit2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/knife_slash1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/knife_slash2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_garand.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_garand.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= GARAND_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= GARAND_MAX_CLIP;
		info.iSlot		= 3;
		info.iPosition	= 8;
		info.iFlags		= 0;
		info.iWeight	= GARAND_WEIGHT;
		
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
			NetworkMessage allies1( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				allies1.WriteLong( self.m_iId );
			allies1.End();
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
		int AmmoAnim;
		
		bool bResult;
		{
			if( self.m_iClip == 0 )
				AmmoAnim = M1GARAND_DRAW_EMPTY;
			else
				AmmoAnim = M1GARAND_DRAW;
			
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/ww2projekt/garand/v_garand.mdl" ), self.GetP_Model( "models/ww2projekt/garand/p_garand.mdl" ), AmmoAnim, "sniper" );
			
			float deployTime = 1.2f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	void PrimaryAttack()
	{
		int AmmoAnim;
		
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
		
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.3;
		
		self.m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		self.m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;
		
		self.m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if( self.m_iClip == 0 )
			AmmoAnim = M1GARAND_SHOOT_EMPTY;
		else
		{
			switch( g_PlayerFuncs.SharedRandomLong( self.m_pPlayer.random_seed, 0, 2 ) )
			{
				case 0: AmmoAnim = M1GARAND_SHOOT1; break;
				case 1: AmmoAnim = M1GARAND_SHOOT2; break;
				case 2: AmmoAnim = M1GARAND_SHOOT3; break;
			}
		}
		
		self.SendWeaponAnim( AmmoAnim );
		
		if( self.m_iClip == 0 )
			g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/garand_shoot_ping.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		else
			g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/garand_shoot.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
			
		Vector vecSrc	 = self.m_pPlayer.GetGunPosition();
		Vector vecAiming = self.m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 60;
		
		self.m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_pPlayer.pev.punchangle.x = -5;

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming + x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;

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
	
	void SecondaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}
	
	void SwingAgain()
	{
		Swing( 0 );
	}
	
	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( self.m_pPlayer.pev.v_angle );
		Vector vecSrc	= self.m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 50;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, self.m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, self.m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 2 )
				{
				case 0:
					self.SendWeaponAnim( M1GARAND_SMASH ); break;
				case 1:
					self.SendWeaponAnim( M1GARAND_SMASH ); break;
				}
				if( self.m_iClip == 0 )
					self.SendWeaponAnim( M1GARAND_SMASH_EMPTY );
				
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.95;
				// play wiff or swish sound
				switch ( Math.RandomLong ( 0, 1) )
				{
					case 0: g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/knife_slash1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) ); break;
					case 1: g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/knife_slash2.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) ); break;
				}
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) )
			{
			case 0:
				self.SendWeaponAnim( M1GARAND_SMASH ); break;
			case 1:
				self.SendWeaponAnim( M1GARAND_SMASH ); break;
			}
			if( self.m_iClip == 0 )
				self.SendWeaponAnim( M1GARAND_SMASH_EMPTY );
			
			// AdamR: Custom damage option
			float flDamage = 50;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextSecondaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( self.m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( self.m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( self.m_pPlayer.pev, self.m_pPlayer.pev );

			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.95; //0.25

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{

					if( pEntity.IsPlayer() )
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}

					switch( Math.RandomLong( 0, 3 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/knife_hit1.wav", 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/knife_hit2.wav", 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/knife_hit3.wav", 1, ATTN_NORM ); break;
					case 3:
						g_SoundSystem.EmitSound( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/knife_hit4.wav", 1, ATTN_NORM ); break;
					}
					self.m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.95; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				
				switch( Math.RandomLong( 0, 1 ) )
				{
					case 0: g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/cbar_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
					case 1: g_SoundSystem.EmitSoundDyn( self.m_pPlayer.edict(), CHAN_WEAPON, "weapons/ww2projekt/cbar_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				}
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.1;

			self.m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
	
	void Reload()
	{
		if( self.m_iClip == 0 )
		{
			BaseClass.Reload();
			self.DefaultReload( GARAND_MAX_CLIP, M1GARAND_RELOAD, 1.92, 0 );
		}
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		self.m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( self.m_iClip > 0 )
			self.SendWeaponAnim( M1GARAND_IDLE );
		else if( self.m_iClip == 0 )
			self.SendWeaponAnim( M1GARAND_IDLE_EMPTY );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetGARANDName()
{
	return "weapon_garand";
}

void RegisterGARAND()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetGARANDName(), GetGARANDName() );
	g_ItemRegistry.RegisterWeapon( GetGARANDName(), "ww2projekt", "357" );
}