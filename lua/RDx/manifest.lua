if VERSION < 46 then
	Msg("Your GMod is out of date! RDx will not work on version: ",VERSION,"\n")
	return
end


require "RDx"
	

if SERVER then
	
	AddCSLuaFile( "autorun/RDx.lua" )
	AddCSLuaFile( "manifest.lua" )
	AddCSLuaFile( "cl_tab.lua" )
	
	if file.Exists("../lua/RDx/.svn/entries") then
		RDxVersion = tonumber( string.Explode( "\n", file.Read( "../lua/RDx/.svn/entries" ) )[ 4 ] ) --get svn revision, stolen from ULX
	else
		RDxVersion = 0	--change this value to the current revision number when making a general release
	end
	Msg("===============================\n===  RDx  "..RDxVersion.."   Loaded   ===\n===============================\n")
	local function initplayer(ply)
		umsg.Start( "rdx_initplayer", ply )
			umsg.Short( RDxVersion or 0 )
		umsg.End()
	end
	hook.Add( "PlayerInitialSpawn", "RD2PlayerInitSpawn", initplayer )
	
	return
end


include( "cl_tab.lua" )

local function initplayer(um)
	RDxVersion = um:ReadShort()
	Msg("===============================\n===  RDx  "..RDxVersion.."   Loaded   ===\n===============================\n")
end
usermessage.Hook( "rdx_initplayer", initplayer )

