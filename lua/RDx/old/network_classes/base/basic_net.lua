RDx.classes.basic_net = oop.class()

--resID are assigned when the network class is regersteredS
function RDx.classes.basic_net:__init(net)
	net = oop.rawnew (self, net or {})
	net.ents = {}
	
	--TODO: replace
	net.amount		= 0
	net.max			= 0
	
	return net
end

function RDx.classes.basic_net:__type()
	return "RDxNetwork"
end

function RDx.classes.basic_net:__tostring()
	return "RDxNetwork["..self.ID.."]"
end

--.InitEnt( ent )
--	called when a resource is added to an entity. resources should only be added to an device when its created and not linked yet,
--	so in this function you shold only be dealing with a local net, but note that this behavior may be changed to allow for that
function RDx.classes.basic_net:InitEnt( ent, capacity )
	local restab = RDx.GetRes( ent, self.resID )
	
	if ent.is_valve then
		restab.nets[ self.ID ] = self.ID
	else
		restab.net = self.ID
		
		--TODO: replace
		restab.capacity	= capacity
		self.max		= self.max + restab.capacity
		--ent.Entity:SetResourceNetID( self.resID, self.ID, true )
		
	end
	
	self.ents[ ent:EntIndex() ] = ent
end

--.AdjustEnt( ent, capacity )
--	called when the resource on the entity is adjusted
function RDx.classes.basic_net:AdjustEnt( ent, capacity )
	local restab = RDx.GetRes( ent, self.resID )
	
	if not ent.is_valve then
		
		--TODO: replace
		local oldcapacity	= restab.capacity or 0
		local diff			= capacity - oldcapacity
		net.max				= net.max + diff
		if (diff < 0) then	net.amount = math.Clamp( net.amount, 0, net.max ) end
		restab.capacity			= capacity
		
	end
end

--.MoveEnt( ent, net1, net2 )
--	move ent from net2 to net1
function RDx.classes.basic_net:MoveEnt( ent, net2 )
	local restab = RDx.GetRes( ent, self.resID )
	if ent.is_valve then --ent is a valve
		restab.nets[ net2.ID ] = nil
		restab.nets[ self.ID ] = self.ID
	else
		restab.net = self.ID
		
		--TODO: replace
		self.max = self.max + restab.capacity
		--ent.Entity:SetResourceNetID( self.resID, self.ID, true )
	
	end
	net2.ents[ ent:EntIndex() ] = nil --remove ent from net2
	self.ents[ ent:EntIndex() ] = ent --put ent on net1
	
	
	--TODO: tell ent that it was moved :p
end

--.MoveRes( net1, net2 )
--	moves res on net2 on to net1 then removes net2
function RDx.classes.basic_net:MoveRes( net2 )
	
	--TODO: replace
	--self.max = self.max + net2.max
	self.amount = self.amount + net2.amount
	--BeamNetVars.SetNetAmount( self.ID, self.amount )
	
	RDx.networks.Remove( net2.ID )
end

--.GetNetFactor( net )
--	factor of res on this net, used when networks are split during rebuilds
local function GetFactor( amount, max )
	local factor = 0
	if (max > 0) then --no zero division, no oh shi-
		factor = math.Clamp( (amount / max), 0, 1 ) --we can't be more than full or less than empty, lol
	end
	return factor
end
function  RDx.classes.basic_net:GetNetFactor()
	--TODO: replace
	return GetFactor( self.amount, self.max )
end

--.ApplyNetFactor( factor )
--	applies the given facor to the network
function  RDx.classes.basic_net:ApplyNetFactor( factor )
	
	--TODO: replace
	self.amount = math.Round(self.max * factor)
	--BeamNetVars.SetNetAmount( net.ID, net.amount )
	
end


--.CombineNets( net1, net2 )
--	puts everything on net2 on to net1 then removes net2
function RDx.classes.basic_net:Combine( net2 )
	--move all the ents to new network
	for idx, ent in pairs(net2.ents) do
		self:MoveEnt( ent, net2 )
	end
	self:MoveRes( net2 )
end


--functions used by link

--.PutEntOnNet( ent, net1, net2 )
--	like combine, but faster, puts one ent from a local net2 on to a normal net1
function RDx.classes.basic_net:PutEntOnNet( ent, net2 )
	self:MoveEnt( ent, net2 )
	if not ent.is_valve then self:MoveRes( net2 ) end --ent is not a valve
end

--.PutEntsOnNewNet( resID, ent1, net1, ent2, net2 )
--	puts two ents from their local nets on a normal net
function RDx.classes.basic_net:PutEntsOnNewNet( resID, ent1, ent2, net2 )
	local net = RDx.networks.New(resID)
	net:MoveEnt( ent1, self )
	net:MoveEnt( ent2, net2 )
	if not ent1.is_valve then net:MoveRes( self ) end
	if not ent2.is_valve then net:MoveRes( net2 ) end
end


--functions used by unlink

--.RebuildNetLink( net, resID, ent, restab, list )
--	this is run on a new network that was made while spliting an old network
function RDx.classes.basic_net:RebuildNetLink( oldnet, factor, ent, restab, ent_list_done )
	ent_list_done[ ent:EntIndex() ] = ent
	
	self:MoveEnt( ent, oldnet )
	if ent.is_valve then return end
	
	for _,ent2 in pairs(restab.links) do
		if not self.ents[ ent2:EntIndex() ] then --is this ent alread on this net?
			local restab2 = RDx.GetRes( ent2, self.resID )
			if restab2 then --just to be sure that is does has this res still
				self:RebuildNetLink( oldnet, factor, ent2, restab2, ent_list_done ) --recurse
			end
		end
	end
	
end

--.RebuildNets( resID, ent_list, factor )
--	ent_list is list of entities to rebuild out from
--	this function is run on a network that is being split and rebuilt in to a new network(s)
function RDx.classes.basic_net:RebuildNet( ent_list, factor )
	local out = {} --list of new nets made
	local ent_list_done = {} --list of all ents linked so far, used to prevent inf. loop and to skip redundant links
	for _,ent in pairs(ent_list) do
		if not ent_list_done[ ent:EntIndex() ] then --was this ent linked via another ent in a previous loop?
			local restab = RDx.GetRes( ent, self.resID )
			if restab then --this ent has this res
				
				MsgN("RebuildNets ent "..tostring(ent).." next link ",next(restab.links))
				
				local net
				if not ent.is_valve and not next(restab.links) then -- not linked to other devices, make local net
					net = RDx.networks.New( self.resID, ent:EntIndex() )
				else
					net = RDx.networks.New( self.resID )
				end
				
				net:RebuildNetLink( self, factor, ent, restab, ent_list_done )
				
				--TODO: replace
				net:ApplyNetFactor(factor)
				--BeamNetVars.SetNetAmount( net.ID, net.amount )
				
				out[ net.ID ] = net
			end
		end
	end
	--remove this network, everything was moved to a new network(s)
	RDx.networks.Remove( self.ID )
	return out
end

RDx.DefineResource("air", "basic_net")
RDx.networks.Define("air", basic_net)