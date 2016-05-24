AddCSLuaFile( "tool_helpers.lua" )
MsgN("loaded helpers")

RDxToolSetup = {}

function RDxToolSetup.open( s_toolmode )
	if TOOL then WireToolSetup.close() end
	
	TOOL				= ToolObj:Create()
	TOOL.Mode			= s_toolmode
	TOOL.Command		= nil
	TOOL.ConfigName		= ""
	TOOL.LeftClick		= RD2Tool.LeftClick
	TOOL.RightClick		= RD2Tool.RightClick
	if !TOOL.NoRepair then TOOL.Reload = RD2Tool.Reload end
	TOOL.UpdateGhost	= RD2Tool.UpdateGhost
	TOOL.Think			= RD2Tool.Think
	
	if CLIENT and GetConVarNumber("RDx_UseLSTab") == 1 then TOOL.Tab = "Life Support" end
end

function RDxToolSetup.close()
	if !TOOL then return end
	
	if TOOL.MODEL then util.PrecacheModel(TOOL.MODEL) end
	
	TOOL:CreateConVars()
	SWEP.Tool[ TOOL.Mode ] = TOOL
	TOOL = nil
end

function RDxToolSetup.BaseLang()
	if !TOOL.ClassName then return end
	if CLIENT and TOOL.DeviceName then
		language.Add( "undone_"..TOOL.ClassName, "Undone Wire "..TOOL.DeviceName )
		language.Add( "Cleanup_"..TOOL.ClassName, TOOL.DeviceNamePlural or TOOL.DeviceName )
		language.Add( "Cleaned_"..TOOL.ClassName, "Cleaned Up "..TOOL.DeviceNamePlural or TOOL.DeviceName )
	end
	cleanup.Register(TOOL.ClassName)
end

function RDxToolSetup.MaxLimit()
	if TOOL.Limited == true and TOOL.MaxName and TOOL.Limit >= 0 then
		local sbox = 'sbox_max'..TOOL.MaxName
		MsgN(sbox,' -> ',TOOL.Limit)
		if SERVER then CreateConVar(sbox, TOOL.Limit)
		elseif CLIENT then language.Add( 'SBoxLimit_'..TOOL.MaxName, 'Maximum Cutoff Valves Reached' ) end
	end
end


local baseccvars = {
	AllowWorldWeld = 0,
	DontWeld = 0,
	Frozen = 0
}
local selccvars = {
	name = '',
	type = '',
	model = ''
}
function RDxToolSetup.BaseCCVars()
	TOOL.ClientConVar = TOOL.ClientConVar or {}
	table.Merge(TOOL.ClientConVar ,baseccvars)
	if TOOL.DevSelect then table.Merge(TOOL.ClientConVar, selccvars) end
	if TOOL.ExtraCCVars then table.Merge(TOOL.ClientConVar, TOOL.ExtraCCVars) end
end

function RDxToolSetup.MakeCP()
	if SERVER then return end
	local self = TOOL
	TOOL.BuildCPanel = function(panel)
		panel:CheckBox("Don't Weld", self.Mode.."_DontWeld" )
		panel:CheckBox("Allow welding to world", self.Mode.."_AllowWorldWeld" )
		panel:CheckBox("Make Frozen", self.Mode.."_Frozen" )
		
		--custom stuff
		if self.ExtraCCVarsCP then self:ExtraCCVarsCP(panel) end
		
		if self.DevSelect and self.DevListName then
			local ListControl = vgui.Create( "RD2Control" )
			panel:AddPanel( ListControl )
			ListControl:SetList( self.Mode, self.DevListName )
		end
	end
end



RD2Tool = {}

local function NoGhostOn(self, trace)
	return self.NoGhostOn and table.HasValue( self.NoGhostOn, trace.Entity:GetClass())
end

local function NoHit(self, trace)
	if !trace.HitPos or trace.Entity:IsPlayer() or trace.Entity:IsNPC() then return true end
	if self.NoLeftOnClass and trace.HitNonWorld and (trace.Entity:GetClass() == self.ClassName or NoGhostOn(self, trace)) then return true end
	return false
end

function RD2Tool.LeftClick( self, trace )
	if NoHit(self, trace) then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	local AllowWorldWeld	= self:GetClientNumber('AllowWorldWeld') == 1
	local DontWeld			= self:GetClientNumber('DontWeld') == 1
	local Frozen			= self:GetClientNumber('Frozen') == 1 or (!AllowWorldWeld and trace.Entity:IsWorld())

	local Data
	if self.ExtraCCVars then
		Data = self:GetExtraCCVars() or {}
	end

	local ent
	if self.ToolMakeEnt then --like wire

		ent = self:ToolMakeEnt( trace, ply )
		if ent == true then return true end
		if ent == nil or ent == false or not ent:IsValid() then return false end

	else
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		
		if self.DevSelect then

			local type			= tool:GetClientInfo('type')
			local model			= tool:GetClientInfo('model')
			if !type or type == '' then
				ErrorNoHalt("RD: GetClientInfo('type') is nil!\n")
				return false
			end

			local func = list.Get( FuncListName )[type]
			if func == nil then
				ErrorNoHalt("RD2: Unable to find make function for '"..type.."'\n")
				return false
			end

			ent = func( ply, Ang, trace.HitPos, type, model, Frozen, data )

		elseif self.MakeFunc then

			ent = self.MakeFunc( ply, Ang, trace.HitPos, Frozen, Data )

		else
			return false
		end

		if !ent or !ent:IsValid() then return false end
		ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z)

		if ent.Setup then ent:Setup(Data) end

	end

	
	if PluginFramework then --Replaces the CDS1 spawn function, so not needed anymore
		pf_Spawn(ent) 
	end


	local const
	if !DontWeld and ( trace.Entity:IsValid() or AllowWorldWeld ) then
		const = constraint.Weld(ent, trace.Entity,0, trace.PhysicsBone, 0, true )
	end

	if Frozen and ent:GetPhysicsObject():IsValid() then
		local Phys = ent:GetPhysicsObject()
		Phys:EnableMotion(false)
		ply:AddFrozenPhysicsObject(ent, Phys)
	end

	undo.Create(self.ClassName)
		undo.AddEntity(ent)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup(self.ClassName, ent)

	return true
end

function RD2Tool.RightClick( self, trace )
	if trace.HitNonWorld and trace.Entity:GetClass() != self.ClassName then return false end
	if CLIENT then return true end
	
	--Update trace.Entity
	
	return true
end

function RD2Tool.Reload( self, trace )
	if !trace.Entity:IsValid() then return false end
	if CLIENT then return true end
	if trace.Entity.Repair == nil then
		self:GetOwner():SendLua("GAMEMODE:AddNotify('Object cannot be repaired!', NOTIFY_GENERIC, 7); surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
		return
	end
	trace.Entity:Repair()
	return true
end

function RD2Tool.UpdateGhost( self, ent )
	if ( !ent or !ent:IsValid() ) then return end

	local tr 		= utilx.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (!trace.Hit or trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity:GetClass() == self.ClassName ) or NoGhostOn(self, trace) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	if self.GetGhostAngle then
		Ang = self:GetGhostAngle( Ang )
	elseif self.GhostAngle then
		Ang = Ang + self.GhostAngle
	end
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	if (self.GetGhostMin) then
		ent:SetPos( trace.HitPos - trace.HitNormal * self:GetGhostMin( min ) )
	elseif (self.GhostMin) then
		ent:SetPos( trace.HitPos - trace.HitNormal * min[self.GhostMin] )
	else
		ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end

function RD2Tool.Think( self )
	local model = self.Model or self:GetClientInfo( "model" )
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model) then
		if self.GetGhostAngle then
			self:MakeGhostEntity( model, Vector(0,0,0), self:GetGhostAngle(Angle(0,0,0)) )
		else
			self:MakeGhostEntity( model, Vector(0,0,0), self.GhostAngle or Angle(0,0,0) )
		end
	end
	self:UpdateGhost(self.GhostEntity)
end


