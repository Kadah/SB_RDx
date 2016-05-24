local net_base = oop.class()

--res_name are assigned when the network class is regersteredS
function net_base:__init(net, netID, res_type)
	net = oop.rawnew (self, net or {})
	net.res			= {}
	net.ID			= netID
	net.res_type	= res_type
	
	--TODO: replace
	net.amount		= 0
	net.max			= 0
	
	return net
end

function net_base:__type()
	return "RDxNetwork"
end

function net_base:__tostring()
	return "RDxNetwork["..self.ID.."]"
end

--.InitEnt( res )
--	called when a resource is added to an entity. resources should only be added to an device when its created and not linked yet,
--	so in this function you shold only be dealing with a local net, but note that this behavior may be changed to allow for that
function net_base:InitRes( res )
	res:SetNet(self)
	self.res[ res.ID ] = res
end




--.MoveEnt( res, net1, net2 )
--	move ent from net2 to net1
function net_base:MoveRes( res )
	--tell the res obj to move to this network
	res:SetNet(self)
	
	res.net.res[ res.ID ] = nil --remove ent from net2
	self.res[ res.ID ] = res --put ent on net1
end



--function(s) used by link

--Absorb( old_net )
--	absorb everything from old_net and kill it
function net_base:Absorb( old_net )
	
	--move all the res objects to this network
	for _,res in pairs(old_net.res) do
		self:MoveRes( res )
	end
	
	--TODO: replace
	--self.max = self.max + net.max
	--self.amount = self.amount + net.amount
	--BeamNetVars.SetNetAmount( self.ID, self.amount )
	
	old_net:Remove()
end


--functions used by unlink

--TODO: see if we can reuse old net again and just break off seperated devices from it

--.RebuildNets( res_name, res_list, factor )
--	res_list is list of res objects to rebuild out from
--	this function is run on a network that is being split and rebuilt in to a new network(s)
function net_base:RebuildNet( res_list, factor )
	local out = {} --list of new nets made (DEBUG)
	local res_list_done = {} --list of all res objects linked so far, used to prevent inf. loop and to skip redundant links
	for _,res in pairs(res_list) do
		if not res_list_done[ res.ID ] then --was this res linked to another res in a the rebuild on the previous loop?
			
			MsgN("RebuildNets ent "..tostring(res).." next link ",next(res.links))
			
			--make a new network and start our rebuild our from res
			local new_net = RDx.networks.New( res.res_type, res.net_class_name )
			
			res:RebuildLinks( new_net, factor, res_list_done )
			
			--TODO: replace
			new_net:ApplyNetFactor(factor)
			--BeamNetVars.SetNetAmount( new_net.ID, new_net.amount )
			
			out[ new_net.ID ] = new_net
		end
	end
	--remove this network, everything was moved to a new network(s)
	self:Remove()
	return out
end


--remove this network
function net_base:Remove()
	RDx.networks.Remove( self )
end



--.GetNetFactor( net )
--	factor of res on this net, used when networks are split during rebuilds
function net_base:GetNetFactor()
	--TODO: replace
	local factor = 0
	if (self.max > 0) then --no zero division, no oh shi-
		--factor = math.Clamp( (self.amount / self.max), 0, 1 ) --we can't be more than full or less than empty, lol
	end
	return factor
end

--.ApplyNetFactor( factor )
--	applies the given facor to the network
function net_base:ApplyNetFactor( factor )
	
	--TODO: replace
	--self.amount = math.Round(self.max * factor)
	--BeamNetVars.SetNetAmount( net.ID, net.amount )
	
end


oop.storeclass(net_base, "RDx", "basic", "net", "base")

--RDx.DefineNetwork(net_class, net_class_name)
RDx.DefineNetwork(net_base, "base")