enum MILLSAnimation_e
{
	MILLS_IDLE = 0,
	MILLS_DRAW,
	MILLS_PINPULL,
	MILLS_HOLSTER,
	MILLS_THROW,
	MILLS_E_IDLE,
	MILLS_E_DRAW,
	MILLS_E_PINPULL,
	MILLS_E_THROW
};

const int MILLS_DEFAULT_GIVE	= 5;
const int MILLS_MAX_CARRY		= 10;
const int MILLS_WEIGHT			= 30;
const int MILLS_DAMAGE			= 160;

class weapon_mills : ScriptBasePlayerWeaponEntity
{
	float m_flStartThrow;
	float m_flReleaseThrow;
	CBaseEntity@ pGrenade;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/mills/w_mills.mdl" );
		
		self.m_iDefaultAmmo = MILLS_DEFAULT_GIVE;
		m_flReleaseThrow = -1.0f;
		m_flStartThrow = 0;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/mills/w_mills.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/mills/v_mills.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/mills/p_mills.mdl" );
		
		//Precache for Download
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/grenpinpull.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/grenthrow.wav" );
		
		//Precache for the Engine
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/grenpinpull.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/grenthrow.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_mills.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_mills.txt" );
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage british7( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				british7.WriteLong( self.m_iId );
			british7.End();
			return true;
		}

		return false;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= MILLS_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 4;
		info.iPosition = 6;
		info.iWeight = MILLS_WEIGHT;
		info.iFlags = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;

		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			m_flReleaseThrow = -1;
			bResult = self.DefaultDeploy( self.GetV_Model( "models/ww2projekt/mills/v_mills.mdl" ), self.GetP_Model( "models/ww2projekt/mills/p_mills.mdl" ), MILLS_DRAW, "gren" );

			float deployTime = 0.87;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	bool CanHolster()
	{
		// can only holster hand grenades when not primed!
		return ( m_flStartThrow == 0 );
	}
	
	bool CanDeploy()
	{
		return self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) != 0;
	}
	
	void Holster( int skiplocal )
	{
		self.m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.75;

		if ( self.m_pPlayer.m_rgAmmo ( self.m_iPrimaryAmmoType ) > 0 )
		{
			self.SendWeaponAnim( MILLS_HOLSTER );
			return;
		}
		else
		{
			self.m_pPlayer.pev.weapons &= ~( 1 << 0 );
			self.DestroyItem();
			
			m_flStartThrow = g_Engine.time;
			m_flReleaseThrow = 0;
			
			self.SendWeaponAnim( MILLS_PINPULL );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.31;
		}
	}
	
	void PrimaryAttack()
	{
		if( m_flStartThrow == 0 && self.m_pPlayer.m_rgAmmo ( self.m_iPrimaryAmmoType ) > 0 )
		{
			m_flReleaseThrow = 0;
			m_flStartThrow = g_Engine.time;
		
			self.SendWeaponAnim( MILLS_PINPULL );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 1;
		}
	}
	
	/**void te_trail( CBaseEntity@ target, string sprite = "sprites/laserbeam.spr", uint8 life = 100, uint8 width = 2, Color c = PURPLE, NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_BEAMFOLLOW );
		m.WriteShort( target.entindex() );
		m.WriteShort( g_EngineFuncs.ModelIndex( sprite ) );
		m.WriteByte( life );
		m.WriteByte( width );
		m.WriteByte( c.r );
		m.WriteByte( c.g );
		m.WriteByte( c.b );
		m.WriteByte( c.a );
		m.End();
	}*/
	
	void WeaponIdle()
	{
		if ( m_flReleaseThrow == 0 && m_flStartThrow > 0.0 )
			m_flReleaseThrow = g_Engine.time;

		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if ( m_flStartThrow > 0.0 )
		{
			Vector angThrow = self.m_pPlayer.pev.v_angle + self.m_pPlayer.pev.punchangle;

			if ( angThrow.x < 0 )
				angThrow.x = -10 + angThrow.x * ( ( 90 - 10 ) / 90.0 );
			else
				angThrow.x = -10 + angThrow.x * ( ( 90 + 10 ) / 90.0 );

			float flVel = ( 90.0f - angThrow.x ) * 6;

			if ( flVel > 750.0f )
				flVel = 750.0f;

			Math.MakeVectors ( angThrow );

			Vector vecSrc = self.m_pPlayer.pev.origin + self.m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
			Vector vecThrow = g_Engine.v_forward * flVel + self.m_pPlayer.pev.velocity;

			// always explode 3 seconds after the pin was pulled
			float time = m_flStartThrow - g_Engine.time + 4.0;
			if( time < 0 )
				time = 0;

			@pGrenade = g_EntityFuncs.ShootTimed( self.m_pPlayer.pev, vecSrc, vecThrow, time );
			g_EntityFuncs.SetModel( pGrenade, "models/ww2projekt/mills/w_mills.mdl" );
			
			//te_trail( pGrenade );
			pGrenade.pev.dmg = MILLS_DAMAGE;

			if ( flVel < 500 )
			{
				self.SendWeaponAnim ( MILLS_THROW );
			}
			else if ( flVel < 1000 )
			{
				self.SendWeaponAnim ( MILLS_THROW );
			}
			else
			{
				self.SendWeaponAnim ( MILLS_THROW );
			}

			// player "shoot" animation
			self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			m_flReleaseThrow = g_Engine.time;
			m_flStartThrow = 0;
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.4;

			self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

			if( self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			{
				// just threw last grenade
				// set attack times in the future, and weapon idle in the future so we can see the whole throw
				// animation, weapon idle will automatically retire the weapon for us.
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.4;
			}
			return;
		}
		else if( m_flReleaseThrow > 0 )
		{
			m_flStartThrow = 0;

			if( self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
			{
				self.SendWeaponAnim( MILLS_DRAW );
			}
			else
			{
				self.RetireWeapon();
				return;
			}

			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( self.m_pPlayer.random_seed, 10, 15 );
			m_flReleaseThrow = -1;
			return;
		}

		if( self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
		{
			int iAnim;
			float flRand = g_PlayerFuncs.SharedRandomFloat( self.m_pPlayer.random_seed, 0, 1 );
			if( flRand <= 1.0 )
			{
				self.SendWeaponAnim( MILLS_IDLE );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( self.m_pPlayer.random_seed, 10, 15 );
			}
		}
	}
}

string GetMILLSName()
{
	return "weapon_mills";
}

void RegisterMILLS()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetMILLSName(), GetMILLSName() );
	g_ItemRegistry.RegisterWeapon( GetMILLSName(), "ww2projekt", "Hand Grenade" );
}