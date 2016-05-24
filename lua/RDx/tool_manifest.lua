AddCSLuaFile( "tool_manifest.lua" )



TOOL = nil


MsgN("Loading RDx Tools")
include( "tool_helpers.lua" )

for key, val in pairs( file.FindInLua( "../lua/RDx/stools/*.lua" ) ) do
	local char1,char2,s_toolmode = string.find( val, "([%w_]*)\.lua" )

	RDxToolSetup.open( s_toolmode )
	
	AddCSLuaFile( "stools/"..val )
	include( "stools/"..val )
	
	RDxToolSetup.BaseCCVars()
	RDxToolSetup.BaseLang()
	RDxToolSetup.MaxLimit()
	RDxToolSetup.MakeCP()
	RDxToolSetup.close()
end

RDxToolSetup = nil
