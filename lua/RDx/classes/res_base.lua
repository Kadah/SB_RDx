local res_base = oop.class()

--resID are assigned when the network class is regersteredS
function res_base:__init(res, dev, resID, res_type)
	res = oop.rawnew (self, res or {})
	
	res.links = {}
	res.dev = dev
	res.ID = resID
	res.res_type = res_type
	
	res:PutOnNewNet()
	
	return res
end

function res_base:__type()
	return "RDxResource"
end

function res_base:__tostring()
	return "RDxRes["..self.ID.."]"
end


function res_base:PutOnNewNet()
	RDx.networks.New( self.res_type, self.net_class_name ):InitRes( self )
end


--res_base:SetNet( net )
--	called by the network when the device is moved from it's old network to new one
function res_base:SetNet( new_net )
	
	if self.dev.is_valve then --ent is a valve
		if self.net then self.nets[ self.net.ID ] = nil end
		self.nets[ new_net.ID ] = new_net
	else
		self.net = new_net
		
		--TODO: replace
		--new_net.max = new_net.max + self.capacity
		--res.Entity:SetResourceNetID( self.res_name, new_net.ID, true )
		
	end
end


--.Adjust( capacity )
--	called when the resource on the entity is adjusted
function res_base:Adjust( capacity )
	--TODO: replace
	--capacity = capacity or 0
	if not self.dev.is_valve then
		
		--TODO: replace
		--[[local oldcapacity	= self.capacity or 0
		local diff			= capacity - oldcapacity
		self.net.max			= self.net.max + diff
		if (diff < 0) then	self.net.amount = math.Clamp( self.net.amount, 0, self.net.max ) end
		self.capacity			= capacity]]
		
	end
end



--.RebuildNetLink( net, res_name, res, restab, list )
--	this is run on a new network that was made while spliting an old network
function res_base:RebuildLinks( new_net, factor, res_list_done )
	res_list_done[ self.ID ] = self
	
	--move this resources to the new network
	new_net:MoveRes( self )
	
	--TODO: redo
	if self.dev.is_valve then return end
	
	--rebuild links on all resources connected to this on
	for _,res2 in pairs(self.links) do
		if not new_net.res[ res2.ID ] then --is this ent alread on this net?
			if res2 then --just to be sure that is does has this res still
				res2:RebuildLinks( new_net, factor, res_list_done ) --recurse
			end
		end
	end
	
end


function res_base:Link(res)
	
	if self.links[ res.ID ] and res.links[ self.ID ] then return end -- nothing to do
	
	self.links[ res.ID ] = res
	res.links[ self.ID ] = self
	
	local net1 = self.net
	local net2 = res.net
	
	local res1localnet = net1.ID < 0 
	local res2localnet = net2.ID < 0
	
	--[[if (res1localnet and res2localnet) then -- both are on local nets, make net net and put both on
		MsgN("RDx Link: putting self "..self.ID.." and res "..res.ID.." on new net")
		--net1.PutEntsOnNewNet( net1, self.res_name, self, res, net2 )
		
		local new_net = RDx.networks.New(self.net_class_name)
		new_net:Absorb(net1)
		new_net:Absorb(net2)
		
	elseif (not res1localnet and res2localnet) then -- res on local net, put it on self's net
		MsgN("RDx Link: joining res "..res.ID.." to net "..net1.ID)
		--net1.PutEntOnNet( net1, res, net2 )
		
		net1:Absorb(net2)
		
	elseif (res1localnet and not res2localnet) then -- self on local net, put it on res's net
		MsgN("RDx Link: joining self "..self.ID.." to net "..net2.ID)
		--net2.PutEntOnNet( net2, self, net1 )
		
		net2:Absorb(net1)
		
	elseif (not res1localnet and not res2localnet and net1.ID != net2.ID) then -- both have own net, put net2 on net1 and remove net2
		MsgN("RDx Link: combining nets "..net1.ID.." and "..net2.ID)
		--net1.Combine( net1, net2 )
		
		net1:Absorb(net2)
		
	else]]
	
	if (net1.ID == net2.ID) then -- both are on the same net already, don't do anything more.
		MsgN("RDx Link: redundant link made for net "..net1.ID)
	else
		net1:Absorb(net2)
	end
	
end


function res_base:Unlink(res)
	
	if not next(self.links) then
		MsgN("res_base:Unlink() no other resources linked to this one")
		return
	end
	
	if res == self then
		self:Unlink_all()
	end
	
	if not self.links[res.ID] then
		error("res_base:Unlink(res): this resource is not linked to given resource, cannot unlink them")
	end
	
	--get the nets from each entity, these should be the same network unless one of them is a valve
	local oldnet = self.net
	local oldnet2 = res.net
	
	if self.dev.is_valve and res.dev.is_valve then
		Error("RDx_Unlink: two valves were linked to each other, this should not have happened!!!\n")
	elseif self.dev.is_valve then --self is a valve
		oldnet = oldnet2
		self.nets[ oldnet2.ID ] = nil
	elseif res.dev.is_valve then --dev is a valve
		oldnet2 = oldnet
		res.nets[ oldnet.ID ] = nil
	end
	
	if oldnet.ID ~= oldnet2.ID then Error("RDx_Unlink: nets missmatch!!!\n") return end
	
	local factor = oldnet:GetNetFactor()
	
	--make list of all ents connected to these two
	local ent_list = {}
	for _,res2 in pairs(self.links) do
		ent_list[ res2.ID ] = res2
	end
	for _,res2 in pairs(res.links) do
		ent_list[ res2.ID ] = res2
	end
	
	--remove ents from eachothers links
	self.links[ res.ID ] = nil
	res.links[ self.ID ] = nil
	
	--build new nets for all connected ents
	local newnets = oldnet:RebuildNet( ent_list, factor )
	
	--Msg("=== new nets ===\n")
	--PrintTable1(newnets)
	--Msg("=== ======== ===\n")
	
end


function res_base:Unlink_all()
	local ent_list = self.links
	
	if not next(self.links) then
		MsgN("res_base:Unlink_all() no other resources linked to this one")
		return
	end
	
	--remove this ent from links on other ents
	for _,res2 in pairs(self.links) do
		res2.links[ self.ID ] = nil --remove ent1 from links
	end
	
	--remove links to other ents from this ent
	self.links = {}
	
	if self.dev.is_valve then --ent is a valve
		self.nets = {}
	else
		local oldnet = self.net
		
		local factor = oldnet:GetNetFactor()
		
		--put this ent back on it's own net
		self:PutOnNewNet()
		
		--build new nets for all connected ents
		local newnets = oldnet:RebuildNet( ent_list, factor )
		
		--Msg("=== new nets ===\n")
		--PrintTable1(newnets)
		--Msg("=== = ===\n")
	end
end

function res_base:Remove()
	self:Unlink_all()
	
	if self.dev.is_valve then --ent is a valve
		--TODO: redo
		--self.nets
	else
		--this resource is not linked to anything else, remove the network
		if not next(self.links) then
			MsgN("res_base:Remove(): this resource is not linked to anything else, removing the network")
			self.net:Remove()
		end
	end
end


oop.storeclass(res_base, "RDx", "basic", "res", "base")

--RDx.DefineResource( res_class, res_class_name, net_class_name )
RDx.DefineResource( res_base, "base", "base")
