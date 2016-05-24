--[[

	RD2 BeamVars Extension

]]

AddCSLuaFile("BeamVarsExtensions/rd2.lua")

local meta = FindMetaTable( "Entity" )
--  Return if there's nothing to add on to
if (!meta) then return end


-- 	SetOOO (3 cap o's)
--  sets off/on/overdrive
if (SERVER) then
	meta[ "SetOOO" ] = function ( self, value )
		if ( value == BeamVars.Get( self, "OOO", 1 ) ) then return end
		BeamVars.Set( self, "OOO", 1, value )
	end
	function BeamVarsSend.OOO( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvEntityVarBeam_OOO", Player )
			umsg.Short( Index )
			umsg.Short( Value )
		umsg.End()
	end
end

meta[ "GetOOO" ] = function ( self, default )
	local out = BeamVars.Get( self, "OOO", 1 )
	if ( out != nil ) then return out end
	return default or {}
end

if ( CLIENT ) then
	local function RecvFunc( m )
		local EntIndex 	= m:ReadShort()
		local Value		= m:ReadShort()
		
		local IndexKey = Entity( EntIndex )
		if ( IndexKey == NULL ) then IndexKey = EntIndex end
		
		BeamVars.GetAll( IndexKey, "OOO" )[1] = Value
		
		if (type(IndexKey) != "number") and (IndexKey.RecvOOO) and (IndexKey:IsValid()) then
			IndexKey:RecvOOO(Value)
		end
		
	end
	usermessage.Hook( "RcvEntityVarBeam_OOO", RecvFunc )
end


-- 
--  SetNetworked NetInfo
-- 
if (SERVER) then
	function BeamNetVars.SetNetAmount( net, value, priority )
		value = math.floor( value )
		if ( value == BeamVars.Get( -2, "NetInfo", net ) ) then return end
		
		BeamVars.Set( -2, "NetInfo", net, value, priority )
	end
	function BeamNetVars.ClearNetAmount( net )
		BeamVars.GetAll( -2, "NetInfo" )[ net ] = nil
	end
	function BeamVarsSend.NetInfo( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvEntityVarBeam_NetInfo", Player )
			umsg.Short( Key )
			umsg.Long( Value )
		umsg.End()
	end
end
--  GetNetworked ShortFloat
function BeamNetVars.GetNetAmount( net )
	if (!net or net == 0) then return 0 end
	return BeamVars.Get( -2, "NetInfo", net ) or 0
end

-- 	Recvs ShortFloat
if ( CLIENT ) then
	local function RecvFunc( m )
		local net 	= m:ReadShort()
		local Value	= m:ReadLong()
		
		BeamVars.GetAll( -2, "NetInfo" )[ net ] = Value
	end
	usermessage.Hook( "RcvEntityVarBeam_NetInfo", RecvFunc )
end


--list of resources keyed by name
local resnames = {}
local ResNamesPrint = {}
local ResNamesPrintByName = {}
local ResUnitsPrint = {}

if ( SERVER ) then
	meta[ "SetResourceNetID" ] = function ( self, res, ID, urgent )
		if ( ID == BeamVars.Get( self, "ResourceNetID", res ) ) then return end
		BeamVars.Set( self, "ResourceNetID", res, ID )
	end
	function BeamVarsSend.ResourceNetID( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvEntityVarBeam_ResourceNetID", Player )
			umsg.Short( Index )
			umsg.Short( Key )
			umsg.Short( Value )
		umsg.End()
	end
end
--  give a resouce id or name and get the ent's net's index
meta[ "GetResourceNetID" ] = function ( self, res )
	if (type(res) != "number") then res = resnames[res] end
	if (!res) then return 0 end
	local out = BeamVars.Get( self, "ResourceNetID", res )
	return out or 0
end
--  give a resouce id or name and get amount on that net
meta[ "GetResourceAmount" ] = function ( self, res )
	if (type(res) != "number") then res = resnames[res] end
	if (!res) then return 0 end
	return BeamNetVars.GetNetAmount( BeamVars.Get( self, "ResourceNetID", res ) )
end
--  give a resouce id or name and get amount on that net with units attached
meta[ "GetResourceAmountText" ] = function ( self, res )
	if (type(res) != "number") then res = resnames[res] end
	if (!res) then return 0 end
	return BeamNetVars.GetNetAmount( BeamVars.Get( self, "ResourceNetID", res ) )..ResUnitsPrint[res]
end
meta[ "GetResourceAmountTextPrint" ] = function ( self, res )
	if (type(res) != "number") then res = resnames[res] end
	if (!res) then return "" end
	return ResNamesPrint[res]..self.Entity:GetResourceAmountText( self, res )
end
--  get all the ent's net's indexes keyed with the resource IDs
meta[ "GetResourceNetIDAll" ] = function ( self )
	return BeamVars.GetAll( self, "ResourceNetID" )
end
--   get all the ent's net's indexes keyed with the resource names
meta[ "GetResourceNetIDAllNamed" ] = function ( self )
	local rez = BeamNetVars.GetResourceNames() 
	local out = {}
	for k,v in pairs (BeamVars.GetAll( self, "ResourceNetID" )) do
		out[ rez[k].name ] = v
	end
	return out
end
--  get all amount of resouces on this ents nets key with resource names
meta[ "GetAllResourcesAmounts" ] = function ( self )
	local rez = BeamNetVars.GetResourceNames() 
	local amounts, units = {}, {}
	for k,v in pairs (BeamVars.GetAll( self, "ResourceNetID" )) do
		amounts[ rez[k].name ] = BeamNetVars.GetNetAmount( v )
		units[ rez[k].name ] =  rez[k].unit
	end
	return amounts, units
end
--  get all amount of resouces on this ents nets ready for overlay text readout
meta[ "GetAllResourcesAmountsText" ] = function ( self, GreaterThanOneOnly )
	local out = {}
	for k,v in pairs (BeamVars.GetAll( self, "ResourceNetID" )) do
		--Msg("k= "..k.." ("..type(k)..") v= "..v.."ResNamesPrint[k]= "..tostring(ResNamesPrint[k]).." BeamNetVars.GetNetAmount(v)= "..tostring(BeamNetVars.GetNetAmount(v)).."\n")
		local amount = BeamNetVars.GetNetAmount(v)
		if (!GreaterThanOneOnly) or (amount > 0) then
			table.insert( out, (ResNamesPrint[k] or "")..(amount or 0)..ResUnitsPrint[k] )
		end
	end
	local txt = table.concat(out, "\n")
	if txt == "" then txt = "-None-" end
	return txt
end
meta[ "GetNumOfResources" ] = function ( self, GreaterThanOneOnly )
	return table.Count(BeamVars.GetAll( self, "ResourceNetID" ))
end
if ( CLIENT ) then
	local function RecvFunc( m )
		--Msg("RecvFunc\n")
		local EntIndex 	= m:ReadShort()
		local res		= m:ReadShort()
		local ID		= m:ReadShort()
		local IndexKey = Entity( EntIndex )
		if ( IndexKey == NULL ) then IndexKey = EntIndex end
		BeamVars.GetAll( IndexKey, "ResourceNetID" )[res] = ID	
	end
	usermessage.Hook( "RcvEntityVarBeam_ResourceNetID", RecvFunc )
end




function BeamNetVars.SetResourcePrintName( resname, printname )
	ResNamesPrintByName[ resname ] = printname
end
if ( SERVER ) then
	--  Tell clients the names of resources and their IDs
	function BeamNetVars.SetResourceNames( id, name, unit, priority ) 
		local tab = {}
		tab.name = name
		tab.unit = unit
		resnames[name] = id
		ResNamesPrint[id] = string.upper(string.sub(name,1,1)) .. string.sub(name,2) .. ": " --makes "air" in to "Air: " for overlaytext
		if ( unit and unit != "") then
			ResUnitsPrint[id] = " "..unit
		else
			ResUnitsPrint[id] = ""
		end
		BeamVars.Set( -4, "ResNames", id, tab, priority )
	end
	function BeamVarsSend.ResNames( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvEntityVarBeam_ResNames", Player )
			umsg.Short( Key )
			umsg.String( Value.name )
			umsg.String( Value.unit )
		umsg.End()
	end
end
--  returns the name from given id
function BeamNetVars.GetResourceName( id ) 
	local out = BeamVars.Get( -4, "ResNames", id )
	if ( out != nil ) then return out.name, out.unit end
	return "", ""
end
--  returns table of all name indexed by id
function BeamNetVars.GetResourceNames() 
	return BeamVars.GetAll( -4, "ResNames" ) or {}
end
if ( CLIENT ) then
	local function RecvFunc( m )
		local id		= m:ReadShort()
		local name		= m:ReadString()
		local unit		= m:ReadString()
		local tab		= {}
		tab.name		= name
		tab.unit		= unit
		BeamVars.GetAll( -4, "ResNames" )[id] = tab
		resnames[name] = id
		if not (ResNamesPrintByName[name] == nil) then
			ResNamesPrint[id] = ResNamesPrintByName[name]
		else
			ResNamesPrint[id] = string.upper(string.sub(name,1,1)) .. string.sub(name,2) .. ": " --makes "air" in to "Air: " for overlaytext
		end
		if ( unit and unit != "") then
			ResUnitsPrint[id] = " "..unit
		else
			ResUnitsPrint[id] = ""
		end
	end
	usermessage.Hook( "RcvEntityVarBeam_ResNames", RecvFunc )
end

