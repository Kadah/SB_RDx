local dev_base = oop.class()

--resID are assigned when the network class is regersteredS
function dev_base:__init(dev, ent, devID)
	dev = oop.rawnew (self, dev or {})
	dev.res = {}
	dev.ID = devID
	if ent then
		dev.ent = ent
	end
	
	return dev
end

function dev_base:__type()
	return "RDxDevice"
end

function dev_base:__tostring()
	return "RDxDevice["..self.ID.."]"
end

--TODO: update for new define system that also is a todo :-\
function dev_base:AddRes(res_type, res_class_name)
	
	if not self.res[res_type] then
		self.res[res_type] = RDx.resources.New(res_type, res_class_name, self)
	end
	
end


function dev_base:GetRes(res_name)
	return self.res[res_name]
end


function dev_base:Link( dev, LPos1, LPos2, material, color, width )
	
	if not (dev and dev.res) then
		Error("Dev_link: One or both entities are not valid!\n")
		return
	end
	if self.is_valve and dev.is_valve then
		Error("RDx_link: Valves cannot be linked to each other!\n")
		return
	end
	
	--only make beam if parameters call for it
	if LPos1 and LPos2 and material and color and width then
		--RDbeamlib.MakeSimpleBeam( ent1, LPos1, ent2, LPos2, material, color, width )
	end
	
	self.links = self.links or {}
	dev.links = dev.links or {}
	
	--CheckEntsOnLink( ent1, ent2 )
	
	--
	self.links[ dev.ID ] = dev
	dev.links[ self.ID ] = self
	
	for res_name, res in pairs( self.res ) do
		if dev.res[res_name] then
			res:Link(dev.res[res_name])
		end
	end
	
end

--TODO: unlinks should be quered a frame so large undos can be processed simpler, maybe

function dev_base:Unlink_All()
	--RDbeamlib.ClearAllBeamsOnEnt( ent1 )
	
	--[[if (!ent1 or !ent1.RDx.resources) then
		Error("Dev_Unlink_All: Entity is not valid!\n")
		return
	end]]
	
	--local ent1ID = ent1:EntIndex()
	
	for ent2ID,dev2 in pairs( self.links or {} ) do
		dev2.links[ self.ID ] = nil
	end
	self.links = {}
	
	for res_name, res in pairs( self.res ) do
		res:Unlink_all()
	end

end


function dev_base:Unlink( dev )
	--RDbeamlib.ClearBeam( ent1, ent2 )
	
	--[[if (!ent1 or !ent1.RDx.resources) or (!ent2 or !ent2.RDx.resources) then
		Error("RDx_Unlink: One or both entities are not valid!\n")
		return
	end]]
	
	local ent1ID = self.ID
	local ent2ID = dev.ID
	
	if not (self.links[ ent2ID ] and dev.links[ ent1ID ]) then
		MsgN("dev_base:Unlink() devices are not linked to each other")
		return -- nothing to do
	end
	
	self.links[ ent2ID ] = nil
	dev.links[ ent1ID ] = nil
	
	for res_name, res in pairs( self.res ) do
		if dev.res[res_name] then
			res:Unlink(dev.res[res_name])
		end
	end
	
end

function dev_base:Remove()
	--this is all for now
	self:Unlink_All()
	for res_type,res in pairs(self.res) do
		res:Remove()
		self.res[res_type] = nil
	end
end


oop.storeclass(dev_base, "RDx", "basic", "dev", "base")

--RDx.DefineDevice( dev_class, dev_class_name, dev_type )
RDx.DefineDevice(dev_base, "base", "simple")
