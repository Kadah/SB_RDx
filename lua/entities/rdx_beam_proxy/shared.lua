ENT.Type			= "anim"
--ENT.Base			= "base_gmodentity"
ENT.PrintName		= "RDx Drawer Drawing Base ENT"
ENT.Author			= "TAD2020"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Spawnable		= false
ENT.AdminSpawnable	= false


local Beams_next_index = 1

local BeamStart		= 1
local BeamNode		= 2
local BeamDelete	= 3
local BeamMove		= 4

--lua_run RDx.PrintTable(player.GetByID(1):GetEyeTrace().Entity:RDx_StartBeam(nil, Vector(0,0,0),"cable/cable2",Color(255,255,255,255)))

function ENT:RDx_StartBeam(ent, pos, material, color, index)
	pos = pos or Vector(0,0,0)
	ent = ent or self.Entity
	material = material or "cable/cable2"
	color = color or Color(255,255,255,255)
	
	if not pos then Error('Wire2BeamLib.Start: Invalid arg pos\n') return end

	if CLIENT and not index then Error('Wire2BeamLib.Start: Needs and index when called on client machine!') return end
	
	if SERVER then
		index = Beams_next_index
		Beams_next_index = Beams_next_index + 1
	end
	
	local beam = {
		Index = index,
		Material = material,
		Color = table.Copy(color),
		Nodes = { }
	}
	
	table.insert(beam.Nodes, { Entity = ent, Position = pos })

    if SERVER then
		
		local rp = RecipientFilter()
		rp:AddAllPlayers()
		
		umsg.Start("RDx_Beam", rp)
			umsg.Long( self:EntIndex() )
			umsg.Char( BeamStart )
			
		    umsg.Long(beam.Index)
		    umsg.Long(ent:EntIndex())
		    umsg.Vector(pos)
		    umsg.String(material)
		    umsg.Short(color.r)
		    umsg.Short(color.g)
		    umsg.Short(color.b)
		umsg.End()
		
	else --CLIENT
		table.insert(self.iBeams, beam)
    end
	
    beam.Proxy = self.Entity
	
	self.Beams = self.Beams or {}
	self.Beams[beam.Index] = beam

    return beam
end


function ENT:RDx_AddBeamNode(beam, ent, pos)
	if not beam then Error('Wire2BeamLib.AddNode: Invalid arg beam\n') return end

	if not ent then Error('Wire2BeamLib.AddNode: Invalid arg ent\n') return end

	if not pos then Error('Wire2BeamLib.AddNode: Invalid arg pos\n') return end

	--local lastindex = #beam.Nodes
	table.insert(beam.Nodes, { Entity = ent, Position = pos })
    --beam.Nodes[lastindex] = { Entity = ent, Position = pos }

    if SERVER then
		local rp = RecipientFilter()
		rp:AddAllPlayers()
		
		umsg.Start("RDx_Beam", rp)
			umsg.Long( self:EntIndex() )
			umsg.Char( BeamNode )
			
		    umsg.Long(beam.Index)
		    umsg.Long(ent:EntIndex())
		    umsg.Vector(pos)
		umsg.End()
    end
end


function ENT:RDx_EndBeam(beam, ent, pos)
	self:AddNode(beam, ent, pos)
end


function ENT:RDx_DeleteBeam(beam)
	if not self.Beams then return end
	self.Beams[beam.Index] = nil
	
    if SERVER then
		local rp = RecipientFilter()
		rp:AddAllPlayers()
		
		umsg.Start("RDx_Beam", rp)
			umsg.Long( self:EntIndex() )
			umsg.Char( BeamDelete )
			
		    umsg.Long(beam.Index)
		umsg.End()
		
	else --CLIENT
		for k,v in ipairs(beam.Proxy.Beams) do
		    if v.Index == beam.Index then
		        table.remove(beam.Proxy.Beams, k)
		        return
		    end
		end
    end
end


function ENT:RDx_MoveBeam(beam, nodeindex, ent, pos)
	beam.Nodes[nodeindex].Entity = ent
	beam.Nodes[nodeindex].Position = pos

    if SERVER then
		local rp = RecipientFilter()
		rp:AddAllPlayers()
		
		umsg.Start("RDx_Beam", rp)
			umsg.Long( self:EntIndex() )
			umsg.Char( BeamMove )
			
		    umsg.Long(beam.Index)
		    umsg.Long(nodeindex)
		    umsg.Long(ent:EntIndex())
		    umsg.Vector(pos)
		umsg.End()
    end
end


function ENT:RDx_MoveFirstBeam(beam, ent, pos)
	self:Move(beam, 1, ent, pos)
end


function ENT:RDx_MoveLastBeam(beam, ent, pos)
	self:Move(beam, #beam.Nodes, ent, pos)
end



if CLIENT then
	
	local function GetEnt(data)
		local ent = ents.GetByIndex(data.entidx)
		if ent  and (ent:IsValid()  or  ent:IsWorld()) then
			return ent
		end
	end
	
	
	function ENT:NEDT_DataRecieved(data)
		MsgN("DataRecieved ",data[1])
		
		if data[1] == BeamStart then
			local ent = GetEnt(data)
			if ent then
				self:RDx_StartBeam(ent, data.pos, data.material, data.color, data.index)
			end
			
		elseif data[1] == BeamNode then
			local ent = GetEnt(data)
			if ent and self.Beams then
				self:RDx_AddBeamNode(self.Beams[data.index], ent, data.pos)
			end
			
		elseif data[1] == BeamDelete then
			local beam = self.Beams[data.index]
			if beam then
				beam.Nodes = { }
				if beam.Proxy  and  beam.Proxy:IsValid() then
					beam.Proxy:GetTable():RemoveBeam(beam)
				end
				self:RDx_DeleteBeam(beam)
			end
			
		elseif data[1] == BeamMove then
			local ent = GetEnt(data)
			if ent and self.Beams and self.Beams[data.index] then
				self:RDx_MoveBeam(self.Beams[data.index], data.nodeindex, ent, data.pos)
			end
			
		end
		
	end
	
	function rcvBeam( um )
		local entID		= um:ReadLong()
		local data		= {}
		data[1]			= um:ReadChar()
		
		if data[1] == BeamStart then
			data.index		= um:ReadLong()
			data.entidx		= um:ReadLong()
			data.pos		= um:ReadVector()
			data.material	= um:ReadString()
			data.color		= Color(um:ReadShort(), um:ReadShort(), um:ReadShort(), 255)
			
		elseif data[1] == BeamNode then
			data.index		= um:ReadLong()
			data.entidx		= um:ReadLong()
			data.pos		= um:ReadVector()
			
		elseif data[1] == BeamDelete then
			data.index		= um:ReadLong()
			
		elseif data[1] == BeamMove then
			data.index		= um:ReadLong()
			data.nodeinde	= um:ReadLong()
			data.entidx		= um:ReadLong()
			data.pos		= um:ReadVector()
			
		end
		RDx_Beams.GetData(entID, data)
	end
	usermessage.Hook("RDx_Beam", rcvBeam)
	
end


