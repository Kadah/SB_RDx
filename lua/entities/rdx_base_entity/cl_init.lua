include('shared.lua')


function ENT:Initialize()
	--self.BaseClass.Initialize(self)
	RDx_Beams.EntInit(self)
end


function ENT:OnRemove()
	--self.BaseClass.OnRemove(self) --use this if you have to use OnRemove
	RDx_Beams.EntRemove( self.Entity )
end




--[[
		These are example functions for RDx_Beam data, override for your own use
]]
function ENT:NEDT_DataRecieved(data)
	
	self.data = data
	MsgN("DataRecieved ",self.data[1]," ",self.data[2])
	
end

local function getumsg(um)
	local entID = um:ReadLong()
	
	local data = {}
	data[1] = um:ReadChar()
	data[2] = um:ReadLong()
	
	MsgN("getumsg ",entID)
	
	RDx_Beams.GetData(entID, data)
	
end
usermessage.Hook("RDxBeams_test", getumsg)





function ENT:Draw( bDontDrawModel )
	self:DoNormalDraw()
	
	if Wire_Render then
		Wire_Render(self.Entity)
	end
end

function ENT:DrawTranslucent( bDontDrawModel )
	if bDontDrawModel then return end
	self:Draw()
end

function ENT:DoNormalDraw( bDontDrawModel )
	if LocalPlayer():GetEyeTrace().Entity == self.Entity && EyePos():Distance( self.Entity:GetPos() ) < 256 then
		if self.RenderGroup == RENDERGROUP_OPAQUE then
			self.OldRenderGroup = self.RenderGroup
			self.RenderGroup = RENDERGROUP_TRANSLUCENT
		end
		
		if not bDontDrawModel then self:DrawModel() end
		
		--[[if self:GetOverlayText() ~= "" then
			AddWorldTip( self.Entity:EntIndex(), self:GetOverlayText(), 0.5, self.Entity:GetPos(), self.Entity  )
		end]]
	else
		if self.OldRenderGroup ~= nil then
			self.RenderGroup = self.OldRenderGroup
			self.OldRenderGroup = nil
		end
		
		if not bDontDrawModel then self:DrawModel() end
	end
end

function ENT:Think()
	--[[if Wire_UpdateRenderBounds and CurTime() >= (self.NextRBUpdate or 0) then
		self.NextRBUpdate = CurTime()+2
		Wire_UpdateRenderBounds(self.Entity)
	end]]
end
