--[[

	BeamLib Extension

]]

AddCSLuaFile("BeamVarsExtensions/beams.lua")


local ThisRDBeamLibVersion = 0.72 --to make existing standalone versions not load

-- 	Stuff for RDbeamlib
RDbeamlib = {}
RDbeamlib.Version = ThisRDBeamLibVersion


-- 	All beam data is stored here
-- Format is BeamData[ source_ent ][ dest_ent ]
local BeamData = {}
-- Format is WireBeams[ wire_dev ].Inputs[ iname ].Nodes[ node_num ]
local WireBeams = {}



-- 
-- 	checks if the source_ent and dest_ent are valid and will clear data as needed
-- 
local function SourceAndDestEntValid( source_ent, dest_ent )
	if (BeamData[ dest_ent ]) and (BeamData[ dest_ent ][ source_ent ]) then
		RDbeamlib.ClearBeam( dest_ent, source_ent )
	end
	if (source_ent) and (source_ent:IsValid()) then
		if (dest_ent) and (dest_ent:IsValid()) then
			return true
		elseif (BeamData[ source_ent ]) and (BeamData[ source_ent ][ dest_ent ]) then
			RDbeamlib.ClearBeam( source_ent, dest_ent )
		end
	elseif (BeamData[ source_ent ]) then
		RDbeamlib.ClearAllBeamsOnEnt( source_ent )
	end
	return false
end



-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
-- 	RDbeamlib Server Side Stuff
-- -- -- -- -- -- -- -- -- -- -- -- -- -- /

if (SERVER) then
	
	function BeamVarsSend.simple( VarType, Index, Key, Value, Player )
		if (!SourceAndDestEntValid( Key.source_ent, Key.dest_ent )) then return end
		if (Value.width == 0) then BeamVarsSend.clearbeam( "clearbeam", Index, Key, Value, Player ) return end
		umsg.Start( "RcvRDBeamSimple", Player )
			umsg.Short(		Key.source_ent:EntIndex() )
			umsg.Short(		Key.dest_ent:EntIndex() )
			umsg.Vector(	Value.start_pos or Vector(0,0,0) )
			umsg.Vector(	Value.dest_pos or Vector(0,0,0) )
			umsg.String(	Value.material )
			umsg.Short(		Value.color.r )
			umsg.Short(		Value.color.g )
			umsg.Short(		Value.color.b )
			umsg.Float(		Value.width )
		umsg.End()
	end
	function BeamVarsSend.clearbeam( VarType, Index, Key, Value, Player )
		if (!SourceAndDestEntValid( Key.source_ent, Key.dest_ent )) then return end
		umsg.Start( "RcvRDClearBeam", Player )
			umsg.Short( Key.source_ent:EntIndex() )
			umsg.Short( Key.dest_ent:EntIndex() )
		umsg.End()
	end
	function BeamVarsSend.clearallentbeams( VarType, Index, Key, Value, Player )
		if (!Key.source_ent or !Key.source_ent:IsValid()) then return end
		umsg.Start( "RcvRDClearAllBeamsOnEnt", Player )
			umsg.Short( Key.source_ent:EntIndex() )
		umsg.End()
	end
	function BeamVarsSend.wirestart( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvRDWireBeamStart", Player )
			umsg.Short(		Key.wire_devIdx )
			umsg.Short(		Key.iname )
			umsg.Vector(	Value.pos or Vector(0,0,0) )
			umsg.String(	Value.material or "" )
			umsg.Short(		Value.color.r )
			umsg.Short(		Value.color.g )
			umsg.Short(		Value.color.b )
			umsg.Float(		Value.width )
		umsg.End()
	end
	function BeamVarsSend.wirenode( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvRDWireBeamNode", Player )
			umsg.Short(		Key.wire_devIdx )
			umsg.Short(		Key.iname )
			umsg.Short(		Key.nodenum )
			umsg.Short(		Key.node_entIdx )
			umsg.Vector(	Value.pos )
		umsg.End()
	end
	function BeamVarsSend.clearwirebeam( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvRDWireBeamClear", Player )
			umsg.Short( Key.wire_dev:EntIndex() )
			umsg.Short( Key.iname )
		umsg.End()
	end
	function BeamVarsSend.clearallwirebeam( VarType, Index, Key, Value, Player )
		umsg.Start( "RcvRDWireBeamClearAll", Player )
			umsg.Short( Key.wire_dev:EntIndex() )
		umsg.End()
	end
	
	
	-- 	checks the links' lengths and breaks if they're too long
	-- 		TODO: this should make some kinda snapping noise when the link is borken
	for i=1,3 do
		util.PrecacheSound( "physics/metal/metal_computer_impact_bullet"..i..".wav" )
	end
	util.PrecacheSound( "physics/metal/metal_box_impact_soft2.wav" )
	function RDbeamlib.CheckLength( source_ent )
		if ( BeamData[ source_ent ] ) then
			for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
				if (dest_ent:IsValid()) then
					local length = ( dest_ent:GetPos() - source_ent:GetPos() ):Length()
					if  ( length > (beam_data.Length or RD_MAX_LINK_LENGTH or 2048) ) then
						if ( (beam_data.LengthOver or 0) > 4 )
						or ( length > (RD_MAX_LINK_LENGTH or 2048) )
						or ( length > (beam_data.Length or RD_MAX_LINK_LENGTH or 2048) + ((RD_EXTRA_LINK_LENGTH or 64) * 1.5) ) then
							source_ent:EmitSound("physics/metal/metal_computer_impact_bullet"..math.random(1,3)..".wav", 500) 
							dest_ent:EmitSound("physics/metal/metal_computer_impact_bullet"..math.random(1,3)..".wav", 500)
							Dev_Unlink(source_ent, dest_ent)
						else
							beam_data.LengthOver = (beam_data.LengthOver or 0) + 1
							local vol = 30 * beam_data.LengthOver
							source_ent:EmitSound("physics/metal/metal_box_impact_soft2.wav", vol) 
							dest_ent:EmitSound("physics/metal/metal_box_impact_soft2.wav", vol)
						end
					elseif ( beam_data.LengthOver ) and ( beam_data.LengthOver > 0 ) then
						beam_data.LengthOver = 0
					end
				else
					RDbeamlib.ClearBeam( source_ent, dest_ent )
				end
			end
		end
	end
	
	
	-- 
	-- 	for duplicating
	-- 
	function RDbeamlib.GetBeamTable( source_ent )
		return BeamData[ source_ent ] or {}
	end
	
	
	-- 
	-- 	function to spam all the BeamData the server has
	-- 
	local function spamBeamData()
		/*Msg("\n\n================= BeamData ======================\n\n")
			PrintTable(BeamData)
		Msg("\n=============== end BeamData ==================\n")*/
		Msg("===BeamData Size: "..table.Count(BeamData).."\n")
		/*Msg("\n\n================= WireBeams ======================\n\n")
			PrintTable(WireBeams)
		Msg("\n=============== end WireBeams ==================\n")*/
		
		/*for wire_dev,beam_data in pairs(WireBeams) do
			Msg("wire_dev= "..tostring(wire_dev).."\n")
			for iname,beam in pairs(beam_data.Inputs) do
				Msg("\tiname= "..iname.."\tnodesize= "..table.Count(beam.Nodes or {}).."\n")
			end
		end*/
		
		Msg("===WireBeams Size: "..table.Count(WireBeams).."\n")
	end
	concommand.Add( "RDBeamLib_PrintBeamData", spamBeamData )
	
	
	-- just in case the duplicator gets a hold of a drawer
	duplicator.RegisterEntityClass("Beam_Drawer", function() return end, "pl" )
	
	
	--  Sends all beams to player
	local function SendAllBeams( ply )
		Msg("==sending Beam data to "..tostring(ply).." ==\n")
		for source_ent, source_ent_table in pairs(BeamData) do
			for dest_ent, beam_data in pairs(source_ent_table) do
				
				local info			= {}
				info.type			= "simple"
				info.source_ent		= source_ent
				info.dest_ent		= dest_ent
				
				BeamVars.AddExtraDelayedNetworkUpdate( "simple", -3 , info, beam_data, ply )
			end
		end
		for wire_dev, wire_dev_table in pairs(WireBeams) do
			local Drawer = wire_dev_table.Drawer
			for iname, beam_data in pairs(wire_dev_table.Inputs) do
				
				local info			= {}
				info.type			= "wirestart"
				info.wire_dev		= wire_dev
				info.wire_devIdx	= wire_dev:EntIndex()
				info.iname			= beam_data.Idx
				
				BeamVars.AddExtraDelayedNetworkUpdate( "wirestart", -3 , info, beam_data, ply )
				
				for node_num, node_data in pairs(beam_data.nodes) do
					local info			= {}
					info.type			= "wirenode"
					info.wire_dev		= wire_dev
					info.wire_devIdx	= wire_dev:EntIndex()
					info.iname			= beam_data.Idx
					info.node_entIdx	= node_data.ent:EntIndex()
					info.nodenum		= node_num
					
					BeamVars.AddExtraDelayedNetworkUpdate( "wirenode", -3 , info, node_data, ply )
				end
				
			end
		end
	end
	--  Offset the sending of data a little after the player has join
	local function DelayedSendAllBeams( ply )
		timer.Simple(7, SendAllBeams, ply)
	end
	hook.Add( "PlayerInitialSpawn", "DelayedSendAllBeams", DelayedSendAllBeams )
	--  Allow players to resend them the data to themselves
	concommand.Add( "networkbeamvars_SendAllNow", DelayedSendAllBeams )
	concommand.Add( "RDBeamLib_SendAllEntityBeamVars",  SendAllBeams)
	
	
	
	local function EntRemoveBeamsCleanup( ent )
		--TODO: make better
		WireBeams[ ent ] = nil
		BeamData[ ent ] = nil
	end
	hook.Add( "EntityRemoved", "EntRemoveBeamsCleanup", EntRemoveBeamsCleanup )
	
	
	
	
	-- 	includes the local BeamData in the save file
	local function RDSave( save )
		--  Remove baggage
		for k, v in pairs(BeamData) do
			if ( k == NULL ) then
				BeamData[k] = nil
			else
				for k2, v2 in pairs(v) do
					if ( k2 == NULL ) then
						BeamData[k][k2] = nil
					end
				end
			end
		end
		saverestore.WriteTable( BeamData, save )
	end
	local function RDRestore( restore )
		BeamData = saverestore.ReadTable( restore )
	end
	local function WireSave( save )
		--  Remove baggage
		for k, v in pairs(WireBeams) do
			if ( k == NULL ) then
				WireBeams[k] = nil
			end
		end
		saverestore.WriteTable( WireBeams, save )
	end
	local function WireRestore( restore )
		WireBeams = saverestore.ReadTable( restore )
	end
	saverestore.AddSaveHook( "EntityRDBeamVars", RDSave )
	saverestore.AddRestoreHook( "EntityRDBeamVars", RDRestore )
	saverestore.AddSaveHook( "EntityRDWireBeamVars", WireSave )
	saverestore.AddRestoreHook( "EntityRDWireBeamVars", WireRestore )
	
	
	
end --SERVER only



-- 
-- 	Get the beam drawer or make one if none
-- 
local function GetDrawer( source_ent, NoCheckLength )
	if (SERVER) and ( !source_ent.RDbeamlibDrawer ) then
		Drawer = ents.Create( "Beam_Drawer2b" )
		Drawer:SetPos( source_ent:GetPos() )
		Drawer:SetAngles( source_ent:GetAngles() )
		Drawer:SetParent( source_ent )
		Drawer:Spawn()
		Drawer:Activate()
		source_ent:DeleteOnRemove( Drawer )
		Drawer:SetEnt( source_ent, not NoCheckLength )
		source_ent.RDbeamlibDrawer = Drawer
		source_ent.Entity:SetNetworkedEntity( "RDbeamlibDrawer", Drawer )
	end
	return source_ent.RDbeamlibDrawer
end
-- 	Set up the drawer for ent to ent beams
-- 	reuse the an existing drawer or make one
-- 	either ent can have the drawer, it doesn't matter
local function SetUpDrawer( source_ent, start_pos, dest_ent, dest_pos, NoCheckLength )
	if (SERVER) and ( !source_ent.RDbeamlibDrawer ) and ( dest_ent.RDbeamlibDrawer ) then
		return dest_ent, dest_pos, source_ent, start_pos, dest_ent.RDbeamlibDrawer
	elseif (SERVER) then
		return source_ent, start_pos, dest_ent, dest_pos, GetDrawer( source_ent, NoCheckLength )
	end
	
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
-- 	RD Beams: ent to ent only
-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
-- 	makes a simple beam from a source ent to dest ent
function RDbeamlib.MakeSimpleBeam(source_ent, start_pos, dest_ent, dest_pos, material, color, width, NoCheckLength)
	if (SERVER) then
		if (!SourceAndDestEntValid( source_ent, dest_ent )) then return end
		source_ent, start_pos, dest_ent, dest_pos = SetUpDrawer( source_ent, start_pos, dest_ent, dest_pos, NoCheckLength )
	end
	
	BeamData[ source_ent ]							= BeamData[ source_ent ] or {}
	BeamData[ source_ent ][ dest_ent ]				= {}
	BeamData[ source_ent ][ dest_ent ].start_pos	= start_pos
	BeamData[ source_ent ][ dest_ent ].dest_pos		= dest_pos
	BeamData[ source_ent ][ dest_ent ].material		= material
	BeamData[ source_ent ][ dest_ent ].width		= width
	BeamData[ source_ent ][ dest_ent ].color		= color
	
	if (CLIENT) then
		RDbeamlib.UpdateRenderBounds(source_ent)
		RDbeamlib.UpdateRenderBounds(dest_ent)
	end
	
	if (SERVER) then
		BeamData[ source_ent ][ dest_ent ].Length = ( dest_ent:GetPos() - source_ent:GetPos() ):Length() + (RD_EXTRA_LINK_LENGTH or 64)
		
		local info			= {}
		info.type			= "simple"
		info.source_ent		= source_ent
		info.dest_ent		= dest_ent
		
		BeamVars.AddDelayedNetworkUpdate( "simple", -3, info, BeamData[ source_ent ][ dest_ent ] )
	end
	
end

-- 
-- 	Clears the beam between two ents
function RDbeamlib.ClearBeam( source_ent, dest_ent )
	if (BeamData[ source_ent ]) then
		BeamData[ source_ent ][ dest_ent ] = nil
	end
	if (BeamData[ dest_ent ]) then
		BeamData[ dest_ent ][ source_ent ] = nil
	end
	if (CLIENT) then
		RDbeamlib.UpdateRenderBounds(source_ent)
		RDbeamlib.UpdateRenderBounds(dest_ent)
	end
	if (SERVER) then
		local info			= {}
		info.type			= "clearbeam"
		info.source_ent		= source_ent
		info.dest_ent		= dest_ent
		
		BeamVars.AddDelayedNetworkUpdate( "clearbeam", -3, info, {} )
	end
end

-- 
-- 	Clears all beams from/to ent
function RDbeamlib.ClearAllBeamsOnEnt( source_ent, DontUpdateCl )
	if (BeamData[ source_ent ]) then
		BeamData[ source_ent ] = nil
	end
	for ent, beamstable in pairs(BeamData) do
		if (BeamData[ent][ source_ent ]) then
			BeamData[ent][ source_ent ] = nil
		end
		if ent == NULL then BeamData[ent] = nil end
	end
	if (CLIENT) then
		RDbeamlib.UpdateRenderBounds(source_ent)
	end
	if (SERVER and !DontUpdateCl) then
		--TODO: for to use ExtraDelayedUpdates
		/*for _, data in pairs (ExtraDelaySendBeamData) do
			if (data.type == "simple") and ((data.source_ent == source_ent) or (data.dest_ent == source_ent)) then
				data = nil
			end
		end*/
		
		local info			= {}
		info.type			= "clearallentbeams"
		info.source_ent		= source_ent
		
		BeamVars.AddDelayedNetworkUpdate( "clearallentbeams", -3, info, {} )
	end
end



-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
-- 	Wire Beams: ent to ent with mid point nodes
-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
-- 
-- 	Start a wire beam
function RDbeamlib.StartWireBeam( wire_dev, iname, pos, material, color, width )
	if (!wire_dev or wire_dev == NULL) then return end
	
	WireBeams[wire_dev]							= WireBeams[wire_dev] or {}
	WireBeams[wire_dev].Inputs					= WireBeams[wire_dev].Inputs or {}
	
	if ( SERVER ) then
		Drawer = GetDrawer( wire_dev )
		
		-- clients don't actually need to know the name of the input, use a index number instead
		local Idx
		if ( WireBeams[wire_dev].Inputs[iname] and WireBeams[wire_dev].Inputs[iname].Idx) then
			Idx = WireBeams[wire_dev].Inputs[iname].Idx --reuse the same index
		else
			WireBeams[wire_dev].inameIdx		= (WireBeams[wire_dev].inameIdx or 0) + 1
			Idx									= WireBeams[wire_dev].inameIdx
		end
		
		-- clear current data (i'm the server, i know what i'm doing)
		WireBeams[wire_dev].Inputs[iname]		= {}
		WireBeams[wire_dev].Inputs[iname].nodes	= {}
		WireBeams[wire_dev].Inputs[iname].Idx	= Idx --set index for this iname
	else
		-- client may not get the start data first, so don't clear it
		WireBeams[wire_dev].Inputs[iname]		= WireBeams[wire_dev].Inputs[iname] or {}
		WireBeams[wire_dev].Inputs[iname].nodes	= WireBeams[wire_dev].Inputs[iname].nodes or {}
	end
	
	WireBeams[wire_dev].Inputs[iname].pos		= pos
	WireBeams[wire_dev].Inputs[iname].material	= material
	WireBeams[wire_dev].Inputs[iname].color		= color or Color(0, 0, 0, 255)
	WireBeams[wire_dev].Inputs[iname].width		= width
	
	if ( CLIENT ) then
		WireBeams[wire_dev].Inputs[iname].nodenum = table.Count( WireBeams[wire_dev].Inputs[iname].nodes )
	end
	
	if ( SERVER ) then
		WireBeams[wire_dev].Inputs[iname].nodenum = 0
		
		local info			= {}
		info.type			= "wirestart"
		info.wire_dev		= wire_dev
		info.wire_devIdx	= wire_dev:EntIndex()
		info.iname			= WireBeams[wire_dev].Inputs[iname].Idx
		if (BeamVars.NumDelayedUpdates() < 550) then
			BeamVars.AddDelayedNetworkUpdate( "wirestart", -3, info, WireBeams[wire_dev].Inputs[iname] )
		else --being flooded (dupe paste), delay these some
			BeamVars.AddExtraDelayedNetworkUpdate( "wirestart", -3, info, WireBeams[wire_dev].Inputs[iname] )
		end
		
	end
	
end

-- 
-- 	Add a node to a wire beam
function RDbeamlib.AddWireBeamNode( wire_dev, iname, node_ent, pos, nodenum )
	if (!wire_dev or wire_dev == NULL) or (!node_ent or node_ent == NULL) then return end
	
	if ( SERVER ) then
		Drawer = GetDrawer( wire_dev )
		nodenum = WireBeams[wire_dev].Inputs[iname].nodenum + 1
	end
	
	WireBeams[wire_dev]										= WireBeams[wire_dev] or {}
	WireBeams[wire_dev].Inputs								= WireBeams[wire_dev].Inputs or {}
	WireBeams[wire_dev].Inputs[iname]						= WireBeams[wire_dev].Inputs[iname] or {}
	WireBeams[wire_dev].Inputs[iname].nodes					= WireBeams[wire_dev].Inputs[iname].nodes or {}
	WireBeams[wire_dev].Inputs[iname].nodes[nodenum]		= {}
	WireBeams[wire_dev].Inputs[iname].nodes[nodenum].pos	= pos
	
	if (type(node_ent) == "number") then
		WireBeams[wire_dev].Inputs[iname].nodes[nodenum].entIdx = node_ent
	else
		WireBeams[wire_dev].Inputs[iname].nodes[nodenum].ent = node_ent
	end
	
	if ( CLIENT ) then
		WireBeams[wire_dev].Inputs[iname].nodenum = table.Count( WireBeams[wire_dev].Inputs[iname].nodes )
	end
	
	if ( SERVER ) then
		WireBeams[wire_dev].Inputs[iname].nodenum = nodenum
		
		local info			= {}
		info.type			= "wirenode"
		info.wire_dev		= wire_dev
		info.wire_devIdx	= wire_dev:EntIndex()
		info.iname			= WireBeams[wire_dev].Inputs[iname].Idx
		info.node_entIdx	= node_ent:EntIndex()
		info.nodenum		= nodenum
		
		if (BeamVars.NumDelayedUpdates() < 500) then
			BeamVars.AddDelayedNetworkUpdate( "wirenode", -3, info, WireBeams[wire_dev].Inputs[iname] )
		else --being flooded (dupe paste), delay these some
			BeamVars.AddExtraDelayedNetworkUpdate( "wirenode", -3, info, WireBeams[wire_dev].Inputs[iname] )
		end
	end
	
end

-- 
-- 	Clears a wire beam
function RDbeamlib.ClearWireBeam( wire_dev, iname )
	if (!wire_dev or !iname or !WireBeams[wire_dev] or !WireBeams[wire_dev].Inputs or !WireBeams[wire_dev].Inputs[iname] or !wire_dev:IsValid()) then return end
	
	if (SERVER) then
		local info		= {}
		info.type		= "clearwirebeam"
		info.wire_dev	= wire_dev
		info.iname		= WireBeams[wire_dev].Inputs[iname].Idx
		
		BeamVars.AddDelayedNetworkUpdate( "clearwirebeam", -3, info, {} )
	end
	
	if (WireBeams[wire_dev]) and (WireBeams[wire_dev].Inputs) then
		WireBeams[wire_dev].Inputs[iname] = nil
	end
	
	if (CLIENT) and (wire_dev:IsValid()) then
		RDbeamlib.UpdateRenderBounds(wire_dev)
	end
end

-- 
-- 	Clears a wire beam
function RDbeamlib.ClearAllWireBeam( wire_dev )
	if (!wire_dev) then return end 
	
	WireBeams[wire_dev] = nil
	
	if (CLIENT) and (wire_dev:IsValid()) then
		RDbeamlib.UpdateRenderBounds(wire_dev)
	end
	
	if (SERVER) then
		local info		= {}
		info.type		= "clearallwirebeam"
		info.wire_dev	= wire_dev
		
		BeamVars.AddDelayedNetworkUpdate( "clearallwirebeam", -3, info, {} )
	end
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
-- 	Client Side Functions
-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
if (CLIENT) then
	
	-- 
	-- 	check for any beam data for NULL ents and removes it
	-- 
	local function CleanupBeams()
		for source_ent, source_ent_table in pairs(BeamData) do
			if ( source_ent == NULL ) then
				BeamData[ source_ent ] = nil
			/*else	
				for dest_ent, beam_data in pairs(source_ent_table) do
					if (dest_ent == NULL) then
						BeamData[source_ent][dest_ent] = nil
					end
				end*/
			end
		end
		for wire_dev, beam_data in pairs(WireBeams) do
			if ( wire_dev == NULL ) then
				WireBeams[ wire_dev ] = nil
			end --TODO: check nodes too
		end
	end
	timer.Create( "RDBeamVarsCleanUp", 35, 0, CleanupBeams )
	
	
	local BEAM_SCROLL_SPEED = 0.5
	local DisableBeamRender = 0
	
	local mats = {
		["cable/rope"] = Material("cable/rope"),
		["cable/cable2"] = Material("cable/cable2"),
		["cable/xbeam"] = Material("cable/xbeam"),
		["cable/redlaser"] = Material("cable/redlaser"),
		["cable/blue_elec"] = Material("cable/blue_elec"),
		["cable/physbeam"] = Material("cable/physbeam"),
		["cable/hydra"] = Material("cable/hydra"),
	}

	-- 
	-- 	renders all the beams on the source_ent
	-- 
	function RDbeamlib.BeamRender( source_ent )
	    if ( !source_ent or !source_ent:IsValid() ) then return end
		if (DisableBeamRender > 0) then return end
		
		if ( BeamData[ source_ent ] ) then
			
			for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
			    
				if ( type(dest_ent) == "number" ) then
					local dest_entIdx = dest_ent
					dest_ent = ents.GetByIndex(dest_entIdx)
					BeamData[ source_ent ][ dest_ent ] = BeamData[ source_ent ][ dest_entIdx ]
					BeamData[ source_ent ][ dest_entIdx ] = nil
				else
					
					if (beam_data.width or 0 > 0) and (dest_ent:IsValid()) then
						local startpos	= source_ent:LocalToWorld(beam_data.start_pos)
						local endpos	= dest_ent:LocalToWorld(beam_data.dest_pos)
						local width	= beam_data.width
						local color = beam_data.color
						local scroll = CurTime() * BEAM_SCROLL_SPEED
						
						render.SetMaterial( mats[beam_data.material] )
						render.DrawBeam(startpos, endpos, width, scroll, scroll+(endpos-startpos):Length()/10, color)
					else
						beam_data = nil
					end
					
				end
			end
			
		elseif (BeamData[ source_ent:EntIndex() ]) then
			BeamData[ source_ent ] = BeamData[ source_ent:EntIndex() ]
			BeamData[ source_ent:EntIndex() ] = nil
		end
		
		if ( WireBeams[ source_ent ] ) then
			
			for iname, beam_data in pairs(WireBeams[ source_ent ].Inputs) do
				if ( beam_data.pos ) then
					
					local scroll = CurTime() * BEAM_SCROLL_SPEED
					local pos		= beam_data.pos
					local material	= beam_data.material
					local color		= beam_data.color
					local width		= beam_data.width
					local nodenum	= beam_data.nodenum
					local start		= source_ent:LocalToWorld(pos)
					
					--TODO: clean up when node becomes invalid
					if (nodenum == 1) then
						local node_ent	= beam_data.nodes[1].ent
						local node_pos	= beam_data.nodes[1].pos
						
						if (!node_ent and beam_data.nodes[1].entIdx) then
							beam_data.nodes[1].ent = ents.GetByIndex(beam_data.nodes[1].entIdx)
							node_ent = beam_data.nodes[1].ent
						end
						
						if (node_ent:IsValid()) then 
							local endpos = node_ent:LocalToWorld(node_pos)
							render.SetMaterial( material )
							render.DrawBeam( start, endpos, width, scroll, scroll+(endpos-start):Length()/10, color )
						end
					else
						render.SetMaterial( material )
						render.StartBeam( nodenum + 1 )
						render.AddBeam( start, width, scroll, color )
						
						for node_num, node_data in pairs(beam_data.nodes) do
							local node_ent	= node_data.ent
							local node_pos	= node_data.pos
							
							if (!node_ent and node_data.entIdx) then
								node_data.ent = ents.GetByIndex(node_data.entIdx)
								node_ent = node_data.ent
							end
							
							if (node_ent:IsValid()) then
								local endpos = node_ent:LocalToWorld(node_pos)
								
								scroll = scroll+(endpos-start):Length()/10
								
								render.AddBeam( endpos, width, scroll, color )
								
								start = endpos
							end
							
						end
						
						render.EndBeam()
					end
				else
					--Msg("no beam_data.pos for "..iname.."\n")
				end
			end
			
		elseif (WireBeams[ source_ent:EntIndex() ]) then
			WireBeams[ source_ent ] = WireBeams[ source_ent:EntIndex() ]
			WireBeams[ source_ent:EntIndex() ] = nil
		end
		
	end
	
	
	-- 
	-- 	updates the render bounds on source_ent
	-- 		TODO: this should be run by the source_ent once in a while
	function RDbeamlib.UpdateRenderBounds(source_ent)
		if (!source_ent) or (type(source_ent) == "number") or (!source_ent:IsValid()) then return end
		
		local Drawer = source_ent.Entity:GetNetworkedEntity( "RDbeamlibDrawer" )
		if ( !Drawer:IsValid() ) then return end
		
		local bbmin = Vector(16,16,16)
		local bbmax = Vector(-16,-16,-16)
		
		if (BeamData[ source_ent ]) then
			
			for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
				if (type(dest_ent) != "number") and (dest_ent:IsValid()) then
					if (beam_data.start_pos.x < bbmin.x) then bbmin.x = beam_data.start_pos.x end
					if (beam_data.start_pos.y < bbmin.y) then bbmin.y = beam_data.start_pos.y end
					if (beam_data.start_pos.z < bbmin.z) then bbmin.z = beam_data.start_pos.z end
					if (beam_data.start_pos.x > bbmax.x) then bbmax.x = beam_data.start_pos.x end
					if (beam_data.start_pos.y > bbmax.y) then bbmax.y = beam_data.start_pos.y end
					if (beam_data.start_pos.z > bbmax.z) then bbmax.z = beam_data.start_pos.z end
					
					local endpos = source_ent:WorldToLocal( dest_ent:LocalToWorld( beam_data.dest_pos ) )
					if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
					if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
					if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
					if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
					if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
					if (endpos.z > bbmax.z) then bbmax.z = endpos.z end
				end
			end
			
		end
		
		if ( WireBeams[ source_ent ] ) then
			
			for iname, beam_data in pairs(WireBeams[ source_ent ].Inputs) do
				if ( beam_data.pos ) then
					
					local start_pos	= source_ent:LocalToWorld(beam_data.pos)
					if (start_pos.x < bbmin.x) then bbmin.x = start_pos.x end
					if (start_pos.y < bbmin.y) then bbmin.y = start_pos.y end
					if (start_pos.z < bbmin.z) then bbmin.z = start_pos.z end
					if (start_pos.x > bbmax.x) then bbmax.x = start_pos.x end
					if (start_pos.y > bbmax.y) then bbmax.y = start_pos.y end
					if (start_pos.z > bbmax.z) then bbmax.z = start_pos.z end
					
					for node_num, node_data in pairs(beam_data.nodes) do --TODO: clean up when node becomes invalid
						local node_ent	= node_data.ent
						local node_pos	= node_data.pos
						if (node_ent and node_ent:IsValid()) then
							local endpos = source_ent:WorldToLocal( node_ent:LocalToWorld( node_pos ) )
							if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
							if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
							if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
							if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
							if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
							if (endpos.z > bbmax.z) then bbmax.z = endpos.z end
						end
					end
					
				end
			end
			
		end
		
		Drawer:SetRenderBounds( bbmin, bbmax )
		
	end
	
	
	-- 
	-- 	turns off beam rendering
	-- 
	local function BeamRenderDisable(pl, cmd, args)
		if not args[1] then return end
		DisableBeamRender = tonumber(args[1])
	end
	concommand.Add( "RDBeamLib_DisableRender", BeamRenderDisable )
	
	
	-- 
	-- 	umsg Recv'r functions
	-- 
	local function RecvBeamSimple( m )
		local source_entIdx	= m:ReadShort()
		local dest_entIdx	= m:ReadShort()
		local start_pos		= m:ReadVector()
		local dest_pos		= m:ReadVector()
		local material		= m:ReadString()
		local color			= Color( m:ReadShort(), m:ReadShort(), m:ReadShort(), 255)
		local width			= m:ReadFloat()
		
		local source_ent = ents.GetByIndex( source_entIdx )
		if (source_ent == NULL) then source_ent = source_entIdx end
		local dest_ent = ents.GetByIndex( dest_entIdx )
		if (dest_ent == NULL) then dest_ent = dest_entIdx end
		
		RDbeamlib.MakeSimpleBeam(source_ent, start_pos, dest_ent, dest_pos, material, color, width)
		
	end
	usermessage.Hook( "RcvRDBeamSimple", RecvBeamSimple )
	
	local function RecvClearBeam( m )
		local source_entIdx	= m:ReadShort()
		local dest_entIdx	= m:ReadShort()
		
		local source_ent = ents.GetByIndex( source_entIdx )
		if (source_ent == NULL) then source_ent = source_entIdx end
		local dest_ent = ents.GetByIndex( dest_entIdx )
		if (dest_ent == NULL) then dest_ent = dest_entIdx end
		
		RDbeamlib.ClearBeam( source_ent, dest_ent )
	end
	usermessage.Hook( "RcvRDClearBeam", RecvClearBeam )
	
	local function RecvClearAllBeamsOnEnt( m )
		local source_entIdx	= m:ReadShort()
		local source_ent	= Entity( source_entIdx )
		if (source_ent == NULL) then source_ent = source_entIdx end
		
		RDbeamlib.ClearAllBeamsOnEnt( source_ent )
	end
	usermessage.Hook( "RcvRDClearAllBeamsOnEnt", RecvClearAllBeamsOnEnt )
	
	
	local function RecvWireBeamStart( m )
		local wire_devIdx	= m:ReadShort()
		local iname			= m:ReadShort()
		local pos			= m:ReadVector()
		local material		= m:ReadString()
		local color			= Color( m:ReadShort(), m:ReadShort(), m:ReadShort(), 255)
		local width			= m:ReadFloat()
		
		local wire_dev = ents.GetByIndex( wire_devIdx )
		if (wire_dev == NULL) then wire_dev = wire_devIdx end
		
		RDbeamlib.StartWireBeam( wire_dev, iname, pos, material, color, width )
		
	end
	usermessage.Hook( "RcvRDWireBeamStart", RecvWireBeamStart )
	
	local function RecvWireBeamNode( m )
		local wire_devIdx	= m:ReadShort()
		local iname			= m:ReadShort()
		local nodenum		= m:ReadShort()
		local node_entIdx	= m:ReadShort()
		local pos			= m:ReadVector()
		
		local wire_dev = ents.GetByIndex( wire_devIdx )
		if (wire_dev == NULL) then wire_dev = wire_devIdx end
		local node_ent = ents.GetByIndex( node_entIdx )
		if (node_ent == NULL) then node_ent = node_entIdx end
		
		RDbeamlib.AddWireBeamNode( wire_dev, iname, node_ent, pos, nodenum )
		
	end
	usermessage.Hook( "RcvRDWireBeamNode", RecvWireBeamNode )
	
	local function RecvClearWireBeam( m )
		local wire_dev = ents.GetByIndex( m:ReadShort() )
		RDbeamlib.ClearWireBeam( wire_dev, m:ReadShort() )
	end
	usermessage.Hook( "RcvRDWireBeamClear", RecvClearWireBeam )
	
	local function RecvClearAllWireBeam( m )
		local wire_dev = ents.GetByIndex( m:ReadShort() )
		RDbeamlib.ClearAllWireBeam( wire_dev )
	end
	usermessage.Hook( "RcvRDWireBeamClearAll", RecvClearAllWireBeam )
	
	
	-- 
	-- 	test function to clear BeamData, for testing FullUpdate function
	-- 
	local function ClearBeamData()
		BeamData = {}
		WireBeams = {}
	end
	concommand.Add( "RDBeamLib_ClearBeamData", ClearBeamData )
	
	
	-- 
	-- 	function to spam all the BeamData the client has
	-- 
	local function spamCLBeamData()
		CleanupBeams()
		/*Msg("\n\n================= CLBeamData ======================\n\n")
			PrintTable(BeamData)
		Msg("\n=============== end CLBeamData ==================\n\n")*/
		Msg("===BeamData Size: "..table.Count(BeamData).."\n")
		/*Msg("\n\n================= CLWireBeams ======================\n\n")
			PrintTable(WireBeams)
		Msg("\n=============== end CLWireBeams ==================\n")*/
		
		for wire_dev,beam_data in pairs(WireBeams) do
			Msg("wire_dev= "..tostring(wire_dev).."\n")
			for iname,beam in pairs(beam_data.Inputs) do
				Msg("\tiname= "..iname.." pos= "..tostring(beam.pos).."\n")
				Msg("\t\tnodesize= "..table.Count(beam.Nodes).."\n")
			end
		end
		
		Msg("===WireBeams Size: "..table.Count(WireBeams).."\n")
	end
	concommand.Add( "RDBeamLib_PrintCLBeamData", spamCLBeamData )
	
end
