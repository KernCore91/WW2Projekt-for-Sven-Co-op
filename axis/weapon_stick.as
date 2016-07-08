enum Model24Animation_e
{
	STICK_IDLE = 0,
	STICK_DRAW,
	STICK_PINPULL,
	STICK_HOLSTER,
	STICK_THROW,
	STICK_E_IDLE,
	STICK_E_DRAW,
	STICK_E_PINPULL,
	STICK_E_THROW
};

const int STICK_DEFAULT_GIVE	= 5;
const int STICK_MAX_CARRY		= 10;
const int STICK_WEIGHT			= 30;
const int STICK_DAMAGE			= 160;

class weapon_stick : ScriptBasePlayerWeaponEntity
{
	float m_flStartThrow;
	float m_flReleaseThrow;
	CBaseEntity@ pGrenade;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/ww2projekt/stick/w_stick.mdl" );
		
		self.m_iDefaultAmmo = STICK_DEFAULT_GIVE;
		m_flReleaseThrow = -1.0f;
		m_flStartThrow = 0;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/ww2projekt/stick/w_stick.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/stick/v_stick.mdl" );
		g_Game.PrecacheModel( "models/ww2projekt/stick/p_stick.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/rifleselect.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/grenpinpull.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/ww2projekt/grenthrow.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/rifleselect.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/grenpinpull.wav" );
		g_SoundSystem.PrecacheSound( "weapons/ww2projekt/grenthrow.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_stick.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/ammo_stick.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "ww2projekt/weapon_stick.txt" );
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage axis9( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				axis9.WriteLong( self.m_iId );
			axis9.End();
			return true;
		}

		return false;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= STICK_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 4;
		info.iPosition = 8;
		info.iWeight = STICK_WEIGHT;
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
			bResult = self.DefaultDeploy( self.GetV_Model( "models/ww2projekt/stick/v_stick.mdl" ), self.GetP_Model( "models/ww2projekt/stick/p_stick.mdl" ), STICK_DRAW, "gren" );

			float deployTime = 0.7;
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
			self.SendWeaponAnim( STICK_HOLSTER );
			return;
		}
		else
		{
			self.m_pPlayer.pev.weapons &= ~( 1 << 0 );
			self.DestroyItem();
			
			m_flStartThrow = g_Engine.time;
			m_flReleaseThrow = 0;
			
			self.SendWeaponAnim( STICK_PINPULL );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.31;
		}
	}
	
	void PrimaryAttack()
	{
		if( m_flStartThrow == 0 && self.m_pPlayer.m_rgAmmo ( self.m_iPrimaryAmmoType ) > 0 )
		{
			m_flReleaseThrow = 0;
			m_flStartThrow = g_Engine.time;
		
			self.SendWeaponAnim( STICK_PINPULL );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 1;
		}
	}
	
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
			float time = m_flStartThrow - g_Engine.time + 5.0;
			if( time < 0 )
				time = 0;

			@pGrenade = g_EntityFuncs.ShootTimed( self.m_pPlayer.pev, vecSrc, vecThrow, time );
			g_EntityFuncs.SetModel( pGrenade, "models/ww2projekt/stick/w_stick.mdl" );
			pGrenade.pev.dmg = STICK_DAMAGE;

			if ( flVel < 500 )
			{
				self.SendWeaponAnim ( STICK_THROW );
			}
			else if ( flVel < 1000 )
			{
				self.SendWeaponAnim ( STICK_THROW );
			}
			else
			{
				self.SendWeaponAnim ( STICK_THROW );
			}

			// player "shoot" animation
			self.m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			m_flReleaseThrow = g_Engine.time;
			m_flStartThrow = 0;
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.0;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.65;

			self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

			if( self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			{
				// just threw last grenade
				// set attack times in the future, and weapon idle in the future so we can see the whole throw
				// animation, weapon idle will automatically retire the weapon for us.
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.65;
			}
			return;
		}
		else if( m_flReleaseThrow > 0 )
		{
			m_flStartThrow = 0;

			if( self.m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
			{
				self.SendWeaponAnim( STICK_DRAW );
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
				self.SendWeaponAnim( STICK_IDLE );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( self.m_pPlayer.random_seed, 10, 15 );
			}
		}
	}
}

string GetSTICKName()
{
	return "weapon_stick";
}

void RegisterSTICK()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetSTICKName(), GetSTICKName() );
	g_ItemRegistry.RegisterWeapon( GetSTICKName(), "ww2projekt", "Hand Grenade" );
}