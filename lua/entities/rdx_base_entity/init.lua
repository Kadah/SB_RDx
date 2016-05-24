
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()
	--self.BaseClass.Initialize(self) --use this in all ents
	
	self.RDx = {
		devices={},
	}
	
	RDx_Beams.EntInit( self )
end


local proxy
function ENT:NewBeam(pos, material, color)
	proxy = proxy or self.RDx_BeamProxy
	if not proxy then
		proxy = ents.Create("rdx_beam_proxy")
		if not proxy then error("RDx_NewBeam: unable to create beam proxy") end
		proxy:SetPos(self:GetPos())
		proxy:SetAngles(self:GetAngles())
		proxy:Spawn()
		proxy:Activate()
		proxy:SetParent(self.Entity)
		table.insert(proxy.ProxiedEntities, self.Entity)
		proxy.ProxiedEntity = self.Entity
		self.Entity:DeleteOnRemove( proxy )
		self.RDx_BeamProxy = proxy
	end
	
	return proxy:RDx_StartBeam(self.Entity, pos, material, color)
	
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
			umsg.Long( self:EntIndex() )
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




function ENT:Think()
	--self.BaseClass.Think(self)
	--use this in all ents that use standard setoverlaytext
	--[[if self.NextOverlayTextTime and CurTime() >= self.NextOverlayTextTime then
		if (self.NextOverlayText) then
			self.Entity:SetNetworkedString( "GModOverlayText", self.NextOverlayText )
			self.NextOverlayText = nil
		end
		self.NextOverlayTextTime = CurTime() + 0.2 + math.random() * 0.2
	end]]
end

function ENT:OnRemove()
	--self.BaseClass.OnRemove(self) --use this if you have to use OnRemove
	
	RDx.RemoveAllDevices( self.Entity )
	RDx_Beams.EntRemove( self.Entity )
	
	if WireAddon ~= nil then Wire_Remove(self.Entity) end
end

function ENT:OnRestore()
	--self.BaseClass.OnRestore(self) --use this if you have to use OnRestore
	if WireAddon ~= nil then Wire_Restored(self.Entity) end
end

function ENT:PreEntityCopy()
	--self.BaseClass.PreEntityCopy(self) --use this if you have to use PreEntityCopy
	RDx.BuildDupeInfo(self.Entity)
	if WireAddon ~= nil then
		local DupeInfo = WireLib.BuildDupeInfo(self.Entity)
		if DupeInfo then
			duplicator.StoreEntityModifier( self.Entity, "WireDupeInfo", DupeInfo )
		end
	end
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	--self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities ) --use this if you have to use PostEntityPaste
	RDx.ApplyDupeInfo(Ent, CreatedEntities)
	if WireAddon ~= nil and Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end
