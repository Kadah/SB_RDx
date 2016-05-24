--
--	RD2 TOOLS HAPPY-FUN TIME-SAVER FUNCTIONS
--

--Compatibility Global
RES_DISTRIB = 2

--put this in your tools
--if not ( RES_DISTRIB == 2 ) then Error("Please Install Resource Distribution 2 Addon.'" ) return end

if SERVER then

	AddCSLuaFile( "RD2_Tools.lua" )
	AddCSLuaFile( "vgui/rd2_gui.lua" )
	AddCSLuaFile( "vgui/rd2_gui_button.lua"	)
	
	-- Global list of callbacks
	RD2_CallbackFuncs = {}
	
	
	--this function can make any RD2 ent (or really any kinda of ent that doesn't take specical args)
	--DO NOT register this function with the duplication, you MUST wrap this function in another one as to add CheckLimit (ther is a generic function to generate these functions below)
	function RD2_MakeRD2Ent( ply, Ang, Pos, system_type, system_class, model, frozen )
		
		local ent = ents.Create( system_class )
		if not ent:IsValid() then return false end
		ent:SetModel( model )
		ent:SetAngles(Ang)
		ent:SetPos(Pos)
		ent:SetPlayer(ply)
		ent:Spawn() --run ENT:Initialize()
		
		local rtable, maxhealth, mass = {}, 0, 0
		
		local SupFunction = list.Get( "RD2_MakeRD2Ent" )[system_class] --supplement function
		if (SupFunction) then
			--[[		== read me ==
			This part allow 3rd party ents to use this function too
			Just make a function that takes (ply, ent, system_type, system_class, model) and returns an ent merge table, maxhealth and mass
			maxheath is only needed for lsents, set it >1 to use the DamageLS hook on the ent
			Your function just needs to do what's done in these ifs (RD_AddResource and/or LS_RegisterEnt)
			Register this function like this: list.Set( "LS_MakeRDEnt", system_class, Function )
			Example: this would do the air_compressor
			local function air_comp(ply, ent, system_class, model)
				local rtable = {}
				local maxhealth = 600 
				local mass = 5500 -- return 0 to not set
				RD_AddResource(ent, "air", 0)
				RD_AddResource(ent, "energy", 0)
				return rtable, maxhealth, mass
			end
			list.Set( "RD2_MakeRD2Ent", "air_compressor", air_comp )
			]]--
			
			--Msg("found MakeRD2EntSupFunction for "..system_class.."\n")
			local noerror, rt, mh, ma = pcall( SupFunction, ply, ent, system_type, system_class, model )
			if (!noerror) then
				ErrorNoHalt("MakeRD2EntSupFunction errored: '"..rt.."'. Removing.\n")
				list.Get( "RD2_MakeRD2Ent" )[system_class] = nil --nuke that shit, someone fucked up
			else --saftey
				rtable = rt or {}
				maxhealth = mh or 0
				mass = ma or 0
			end
		end
		
		if (maxhealth > 0) then
			rtable.health = maxhealth
			rtable.maxhealth = maxhealth
			if (LIFESUPPORT and LIFESUPPORT == 2) and (ent:GetTable().OnTakeDamage) then
				local Prev = ent:GetTable().OnTakeDamage
				function ent:OnTakeDamage(Info)
					DamageLS(self, Info:GetDamage())
					Prev(self, Info)
				end
			end
		end
		
		--rtable[system_type] = system_class --this is silly, we don't have to do this, just use "Class" for that arg with the duplicator.
		table.Merge(ent:GetTable(), rtable )
		
		if (mass > 0) or (frozen) then
			local phys = ent:GetPhysicsObject()
			if (phys:IsValid()) then
				if (mass > 0) then
					phys:SetMass(mass)
					phys:Wake()
				end
				if (frozen) then
					phys:EnableMotion( false ) 
					ply:AddFrozenPhysicsObject( ent, phys )
				end
			end
		end
		
		return ent
	end
	
	function RD2_GenerateMakeFunction( ToolName )
		-- Check to see if we already have a generic function for this tool
		if (RD2_CallbackFuncs[ToolName]) then
			--Msg('Stool CallBack [Existing] -> '..ToolName..'\n')
			return RD2_CallbackFuncs[ToolName]
		end
		
		local MakeFunction = function( ply, Ang, Pos, type, model, Frozen )
			if not ply:CheckLimit( ToolName ) then return nil end
			local ent = RD2_MakeRD2Ent( ply, Ang, Pos, ToolName, type, model, frozen )
			if not (ent and ent:IsValid()) then return nil end
			ply:AddCount( ToolName, ent )
			return ent
		end
		
		RD2_CallbackFuncs[ToolName] = MakeFunction
		--Msg('\nStool CallBack  [Created] -> '..ToolName..'\n')
		
		return MakeFunction
	end
	
	function RD2_SetToolMakeFunc( ToolName, EntClass, EntMakeFunct )
		if not (ToolName and EntClass) then return end
		if (!EntMakeFunct) then
			EntMakeFunct = RD2_GenerateMakeFunction( ToolName ) -- Thats checks to see if a function already exists for this tool or it will make a new one
			duplicator.RegisterEntityClass( EntClass, EntMakeFunct, "Ang", "Pos", "Class", "model", "frozen" )
		else
			--Msg('Stool CallBack [Argument] -- '..EntClass..' -> '..tostring(EntMakeFunct)..'\n')
		end
		list.Set( ToolName.."_Funcs", EntClass, EntMakeFunct )
	end

	function RD2_AddMakeRD2EntSupFunction( EntClass, MakeRD2EntSupFunction )
		if not (EntClass and MakeRD2EntSupFunction) then return end
		--Msg('MakeRD2EntSupFunction set for - '..EntClass..' -\n')
		list.Set( "RD2_MakeRD2Ent", EntClass, MakeRD2EntSupFunction ) --tell RD2_MakeRD2Ent how to set up this ent
	end
	
end	


--RD2_AddStoolItem('cdsweapons', "Heat Gun", 'models/props_junk/TrafficCone001a.mdl', 'gun_heat')
function RD2_AddStoolItem( ToolName, EntPrintName, EntModel, EntClass, EntMakeFunct, MakeRD2EntSupFunction )
	if not (ToolName and EntPrintName and EntModel and EntClass) then 
		--Msg('Error when calling RD2_AddStoolItem -- ToolName: -'..tostring(ToolName)..'- EntPrintName: -'..tostring(EntPrintName)..'- Model: -'..tostring(Model)..'- EntClass: -'..tostring(EntClass)..'-\n')
		return 
	end
	
	list.Set( ToolName.."_Models", EntPrintName, { name = EntPrintName, model = EntModel, type = EntClass } )
	util.PrecacheModel( EntModel )

	if (SERVER) then
		RD2_SetToolMakeFunc( ToolName, EntClass, EntMakeFunct ) --EntMakeFunct should not be in client scope, ever (sloppy)
		RD2_AddMakeRD2EntSupFunction( EntClass, MakeRD2EntSupFunction )
	end
end



--This fucntion saves your day by setting up 95% of your stool for you with a few vars
--TOOL: toolobj
--Models_List: list of ent info used to make the panel options and do ghosting, each member uses this template: { 'EntPrintName', 'EntModel', 'EntClass' } (only needed if you don't set this someother way)
--MakeFunc: function used to make ents in Models_List (not needed if you set Models_List someother way)
--ToolName: name of the tool (ie. filename) (needed
--ToolLimit: for simple tools that limit all ents it make by this number (ie. all ents made by this tool use the same MakeFunc)
--MakeRD2EntSupFunctionList: list of functions used by MakeRD2Ent to setup an EntClass, list is indexed with EntClass (only needed if you're using MakeRD2Ent to make your ents)
function RD2_ToolRegister( TOOL, Models_List, MakeFunc, ToolName, ToolLimit, MakeRD2EntSupFunctionList, custom )

	if (ToolLimit != nil and type(ToolLimit) == "number" and ToolLimit >=0) then
		local sbox = 'sbox_max'..ToolName
		Msg(sbox..' -> '..ToolLimit..'\n')
		CreateConVar(sbox, ToolLimit)
	end

	cleanup.Register(ToolName)

	TOOL.ClientConVar['AllowWorldWeld'] = '0'
	TOOL.ClientConVar['DontWeld'] = '0'
	TOOL.ClientConVar['Frozen'] = '0'
	TOOL.ClientConVar['name'] = ''
	TOOL.ClientConVar['type'] = ''
	TOOL.ClientConVar['model'] = ''
	--Default values for the custom controls
	if custom then
		for k, v in pairs(custom) do
			if not v.text then v.text = tostring(k) end
			if not v.description then v.description = "Change the value of "..k end
			if(v.type == "slider" or v.type == "checkbox") then --all for now
				if not v.defaultvalue then v.defaultvalue = 0 end
				TOOL.ClientConVar[k] = tostring(v.defaultvalue)
			else --v.type == "text" or v.type = "modellist" --Default to string mode for everything else
				if not v.defaultvalue then v.defaultvalue = "" end
				TOOL.ClientConVar[k] = tostring(v.defaultvalue)
			end
		end
		TOOL.custom = custom
	end
	--------------------------
	if not (Models_List == nil) then
		for k, v in pairs(Models_List) do
			RD2_AddStoolItem(ToolName, v[1], v[2], v[3], MakeFunc, v[4]) --v[4] can be a MakeRD2EntSupFunction or nil
		end
	end
	
	if (SERVER and MakeRD2EntSupFunctionList) then
		for EntClass, MakeRD2EntSupFunction in pairs(MakeRD2EntSupFunctionList) do
			RD2_AddMakeRD2EntSupFunction( EntClass, MakeRD2EntSupFunction )
		end
	end
	
	function TOOL:LeftClick( trace )
		if trace.Entity && (trace.Entity:IsPlayer() ) then return false end
		if(CLIENT) then return true end
		
		return RD2_ToolLeftClick( self, trace, ToolName )
		
	end
	
	function TOOL:RightClick( trace )
		if (!trace.Entity:IsValid()) then return false end
		if (CLIENT) then return true end
		if (not trace.Entity:GetTable().Repair) then
	        self:GetOwner():SendLua("GAMEMODE:AddNotify('Object cannot be repaired!', NOTIFY_GENERIC, 7); surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
			return
		end
		trace.Entity:Repair()
		return true
	end
	
	if (CLIENT) then
		
		function TOOL.BuildCPanel( cp )
			RD2_BuildCPanel( cp, ToolName, ToolName.."_Models", custom )
		end
		
	end

	function TOOL:Think()
		if (RD2_UpdateToolGhost) then RD2_UpdateToolGhost( self ) end
	end

	function TOOL:Deploy()
		if not (RES_DISTRIB == 2) then
			self:GetOwner():PrintMessage( HUD_PRINTCENTER, "Please Install Resource Distribution 2 Addon.\nThis mod requires it to function." ) 
		end
	end
	
	
end

if ( SERVER ) then 
	function RD2_ToolLeftClick( tool, trace, ToolName )
		
		local FuncListName = ToolName.."_Funcs"
		local ply = tool:GetOwner()
		local Pos = trace.HitPos
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local type			= tool:GetClientInfo('type')
		local model			= tool:GetClientInfo('model')
		local AllowWorldWeld		= tool:GetClientNumber('AllowWorldWeld') == 1
		local DontWeld			= tool:GetClientNumber('DontWeld') == 1
		local Frozen			= (tool:GetClientNumber('Frozen') == 1) or (AllowWorldWeld and not trace.Entity:IsValid())
		if (!type or type == '') then
			ErrorNoHalt("RD: GetClientInfo('type') is nil!\n")
			return false
		end
		--Checks all custom added controls
		local custom = nil
		if tool.custom then
			custom = {}
			for k, v in pairs(tool.custom) do
				custom[k] = tool:GetClientInfo(k) or "something"
			end
		end
		------------------------------
		--Should be send with the function in a seperate variable, instead of needing to be send through the player
		if custom then
			ply.custom = custom
		end
		-------------------------------
		local func = list.Get( FuncListName )[type]
		if (func == nil) then Error("RD2: Unable to find make function for '"..type.."'\n") end
		local ent = func( ply, Ang, Pos, type, model, Frozen)--somewhere here?
		if (not ent) then return false end
		ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z)
		if PluginFramework then --Replaces the CDS1 spawn function, so not needed anymore
			pf_Spawn(ent) 
		end
		local const
		if (!DontWeld) and ( trace.Entity:IsValid() or AllowWorldWeld ) then
			local const = constraint.Weld(ent, trace.Entity,0, trace.PhysicsBone, 0, true ) --add true to turn DOR on
		end
		
		undo.Create( ToolName )
			undo.AddEntity( ent )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()
		ply:AddCleanup( ToolName, ent )
		
		return true
	end
end

if (SinglePlayer() and SERVER) or (!SinglePlayer() and CLIENT) then --server side in singleplayer, client side in multiplayer
function RD2_UpdateToolGhost( tool, model, min, GetOffset, offset )
	local model = model or tool:GetClientInfo('model')
	if (model == '') then return end
	
	if (!tool.GhostEntity || !tool.GhostEntity:IsValid() || tool.GhostEntity:GetModel() != model) then
		tool:MakeGhostEntity( model, Vector(0,0,0), Angle(0,0,0) )
	end
	
	if ( !tool.GhostEntity ) then return end
	if ( !tool.GhostEntity:IsValid() ) then return end
	
	local tr = utilx.GetPlayerTrace( tool:GetOwner(), tool:GetOwner():GetCursorAimVector() )
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if ( trace.Entity:IsPlayer() ) then
		tool.GhostEntity:SetNoDraw( true )
		return
	end
	
	local Ang = trace.HitNormal:Angle()
	if (!min or min == "z") then
		Ang.pitch = Ang.pitch + 90
	end
	tool.GhostEntity:SetAngles( Ang )
	
	local Pos = trace.HitPos
	if (offset) then
		Pos = Pos + GetOffset( trace.HitNormal:Angle(), offset )
	else
		Pos = Pos - trace.HitNormal * tool.GhostEntity:OBBMins()[ min or "z" ]
	end
	tool.GhostEntity:SetPos( Pos )
	
	tool.GhostEntity:SetNoDraw( false )
end
end


function RD2_SetResourcePrintName( resname, printname ) --to be moved later
	BeamNetVars.SetResourcePrintName( resname, printname ) --to be changed later
end
