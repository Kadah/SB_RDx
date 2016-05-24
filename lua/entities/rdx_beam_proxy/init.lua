--Beam Drawer by TAD2020
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')


function ENT:Initialize()
	self.Entity:SetModel("models/props_c17/oildrum001.mdl") --for debuging
	
	--RDx_Beams.EntInit( self )
	
	self.Beams = {}
	self.ProxiedEntities = {}
	
end




--[[
		These are example functions for RDx_Beam data, override for your own use
]]
function ENT:NEDT_SetNetworkData( tab ) --this function can be called anything you like, you just have to call QueryUpdate
	self.data = tab
	if not self.rp then self.rp = RecipientFilter() end
	self.rp:AddAllPlayers()
	RDx_Beams.QueryUpdate( self )
end

function ENT:NEDT_Update()
	
	MsgN("Update ",tostring(self))
	
	if self.rp then
		umsg.Start("RDxBeams_test", self.rp)
			umsg.Short( self:EntIndex() )
			umsg.Char( self.data[1])
			umsg.Long( self.data[2] )
		umsg.End() 
	end
end

function ENT:NEDT_PlayerJoin( ply )
	if not self.rp then self.rp = RecipientFilter() end
	self.rp:AddPlayer( ply )
	RDx_Beams.QueryUpdate( self )
end

