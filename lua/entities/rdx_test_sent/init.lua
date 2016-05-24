AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:SpawnFunction( ply, tr )
	if not tr.Hit then return end
	local ent = ents.Create("rdx_test_sent")
	ent:SetPos(tr.HitPos+tr.HitNormal*16)
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Entity:SetModel("models/props_junk/PropaneCanister001a.mdl")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	if WireAddon then
		self.Inputs = Wire_CreateInputs(self.Entity,{ "A"})
		self.Outputs = Wire_CreateOutputs(self.Entity,{ "A"})
		Wire_TriggerOutput(self.Entity,"A", 0)
		Wire_TriggerOutput(self.Entity,"A", 0)
	end
	
	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMass(200)
		phys:Wake()
	end
	
	self:NEDT_SetNetworkData({123,456})
	
	local dev = RDx.AttachNewDevice("base", "basic", self)
	local res = dev:AddRes("air", "base")
	
end

function ENT:TriggerInput(key,value)
	if (key == "A") then
		--stuff
	end
end
