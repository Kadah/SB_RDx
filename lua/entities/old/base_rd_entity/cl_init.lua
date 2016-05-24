include('shared.lua')

function ENT:Draw( bDontDrawModel )
	self:DoNormalDraw()
	
	if (Wire_Render) then
		Wire_Render(self.Entity)
	end
end

function ENT:DrawTranslucent( bDontDrawModel )
	if ( bDontDrawModel ) then return end
	self:Draw()
end

function ENT:DoNormalDraw( bDontDrawModel )
	if ( LocalPlayer():GetEyeTrace().Entity == self.Entity && EyePos():Distance( self.Entity:GetPos() ) < 256 ) then
		if ( self.RenderGroup == RENDERGROUP_OPAQUE ) then
			self.OldRenderGroup = self.RenderGroup
			self.RenderGroup = RENDERGROUP_TRANSLUCENT
		end
		
		if ( !bDontDrawModel ) then self:DrawModel() end
		
		if ( self:GetOverlayText() != "" ) then
			AddWorldTip( self.Entity:EntIndex(), self:GetOverlayText(), 0.5, self.Entity:GetPos(), self.Entity  )
		end
	else
		if ( self.OldRenderGroup != nil ) then
			self.RenderGroup = self.OldRenderGroup
			self.OldRenderGroup = nil
		end
		
		if ( !bDontDrawModel ) then self:DrawModel() end
	end
end

function ENT:Think()
	if (Wire_UpdateRenderBounds and CurTime() >= (self.NextRBUpdate or 0)) then
		self.NextRBUpdate = CurTime()+2
		Wire_UpdateRenderBounds(self.Entity)
	end
end
