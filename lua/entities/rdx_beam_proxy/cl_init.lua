
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

local minvect = Vector(-1, -1, -1)
local maxvect = Vector(1, 1, 1)
local zerovect = Vector(0, 0, 0)

local mats = {}
function GetMaterial(mat)
	if mats[mat] == nil then
		mats[mat] = Material(mat)
	end
	return mats[mat]
end

function ENT:Initialize()
	self.Entity:DrawShadow( false )
	self.Entity:SetRenderBounds(minvect, maxvect, 0)
	
	self.Beams = { }
	self.iBeams = {}
	
	RDx_Beams.EntInit(self)
end

function ENT:OnRemove()
	--self.BaseClass.OnRemove(self) --use this if you have to use OnRemove
	RDx_Beams.EntRemove( self.Entity )
end

function ENT:Draw()
	--self.Entity:DrawModel()
	local ent = self.Entity
	local bbmin = ent:LocalToWorld(minvect)
	local bbmax = ent:LocalToWorld(maxvect)

	for _,b in ipairs(self.iBeams) do
	    if (#b.Nodes > 1) then
	        render.SetMaterial(GetMaterial(b.Material))
	        render.StartBeam(#b.Nodes)

	        local scroll = 0
            local prevpos
            if (b.Nodes[1].Entity)  &&  (b.Nodes[1].Entity:IsValid()  ||  b.Nodes[1].Entity:IsWorld()) then
				prevpos = b.Nodes[1].Entity:LocalToWorld(b.Nodes[1].Position)
			else
			    prevpos = zerovect
			end
	        for _,n in ipairs(b.Nodes) do
	            if (n.Entity)  &&  (n.Entity:IsValid()  ||  n.Entity:IsWorld()) then
		            local endpos = n.Entity:LocalToWorld(n.Position)

		            scroll = scroll + (endpos - prevpos):Length()/10
		            prevpos = endpos

			        render.AddBeam(endpos, 0.75, scroll, b.Color)

					if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
					if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
					if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
					if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
					if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
					if (endpos.z > bbmax.z) then bbmax.z = endpos.z end
				end
			end

	        render.EndBeam()
	    end
	end

	ent:SetRenderBoundsWS(bbmin, bbmax, Vector()*6)
end

