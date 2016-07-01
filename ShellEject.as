void GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale )
{  
	Vector vecForward, vecRight, vecUp;
	
	g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
	
	const float fR = Math.RandomFloat( 50, 70 );
	const float fU = Math.RandomFloat( 100, 150 );
 
	for( int i = 0; i < 3; ++i )
	{
		ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
		ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
	}
}

enum InShoulder_e
{
	NotInShoulder = 0,
	InShoulder
};

enum Bipod_e
{
	BIPOD_UNDEPLOY = 0,
	BIPOD_DEPLOY
};

enum ScopedSniper_e
{
	MODE_NOSCOPE = 0,
	MODE_SCOPED
};

enum ScopedRifle_e
{
	MODE_UNSCOPE = 0,
	MODE_SCOPE
};