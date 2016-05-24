--[[

	SB2 BeamVars Extension

]]


if ( SERVER ) then
	-- 
	--  Updated SB2 planet info
	-- 
	function BeamNetVars.SB2UpdatePlanet( planet )
		BeamVars.Set( -11, "PlanetInfo", planet.num, planet )
	end
	function BeamVarsSend.PlanetInfo( VarType, Index, Key, Value, Player )
		--  add to the planet list on the client.
		umsg.Start( "AddPlanet", Player )
			umsg.Vector( Value.pos )
			umsg.Float( Value.radius )
			umsg.Short( Key ) -- planet.num
			if Value.Color == nil then
				umsg.Bool (false)
			else
				umsg.Bool( true )
				umsg.Short( Value.Color.AddColor_r )
				umsg.Short( Value.Color.AddColor_g )
				umsg.Short( Value.Color.AddColor_b )
				umsg.Short( Value.Color.MulColor_r )
				umsg.Short( Value.Color.MulColor_g )
				umsg.Short( Value.Color.MulColor_b )
				umsg.Float( Value.Color.Brightness )
				umsg.Float( Value.Color.Contrast )
				umsg.Float( Value.Color.Color )	
			end
			if Value.Bloom == nil then
				umsg.Bool(false)
			else
				umsg.Bool(true)
				umsg.Short( Value.Bloom.Col_r )
				umsg.Short( Value.Bloom.Col_g )
				umsg.Short( Value.Bloom.Col_b )
				umsg.Float( Value.Bloom.SizeX )
				umsg.Float( Value.Bloom.SizeY )
				umsg.Float( Value.Bloom.Passes )
				umsg.Float( Value.Bloom.Darken )
				umsg.Float( Value.Bloom.Multiply )
				umsg.Float( Value.Bloom.Color )	
			end
		umsg.End()
	end
	-- 
	--  Updated SB2 star info
	-- 
	function BeamNetVars.SB2UpdateStar( star )
		BeamVars.Set( -11, "StarInfo", star.num, star )
	end
	function BeamVarsSend.StarInfo( VarType, Index, Key, Value, Player )
		umsg.Start( "AddStar", Player )
			umsg.Short( Index ) -- star.num
			umsg.Vector( Value.pos ) -- star.pos
			umsg.Float( Value.radius ) -- star.radius
		umsg.End()
	end
end

