--[[=================================
	Resource Distribution 2
	Author: TAD2020
	
=================================]]

MsgN("====== Loading RDx Module ======")

--load our oop class system
oop = require "loop/multiple"
--[[ Q&D howto:
--basic
new_class = oop.class() -- new empty class
new_class = oop.class(tab) -- make new class from table
--simple inheritance
new_class = oop.class(nil, super_class) --make new class inherited from super_class
new_class = oop.class(tab, super_class) --make new class from tab inherited from super_class
--multiple inheritance
new_class = oop.class(nil, super_class1, super_class2, ...) --make new class inherited from super_class1, super_class2, ...
new_class = oop.class(tab, super_class1, super_class2, ...) --make new class from tab inherited from super_class1, super_class2, ...
--you can mix methods as needed
--see http://loop.luaforge.net/manual/index.html for more info
]]

-- this is just a shared table to make sharing classes easier
oop.classes = {}

--storeclass(class, key1, key2, key3, ...)
--	stores a class in the classes table as classes[key1][key2][key3] = class
function oop.storeclass(class, ...)
	if arg[1] then
		local name = table.remove(arg)
		local tab = oop.classes
		while arg[1] do
			local key = table.remove(arg, 1)
			if not tab[key] then tab[key] = {} end
			tab = tab[key]
		end
		tab[name] = class
	end
end

--getclass(class, key1, key2, key3, ...)
--	get a class in the classes table as class = classes[key1][key2][key3]
function oop.getclass(...)
	if arg[1] then
		local name = table.remove(arg)
		local tab = oop.classes
		while arg[1] do
			local key = table.remove(arg, 1)
			if not tab[key] then return end
			tab = tab[key]
		end
		return tab[name]
	end
end

AddCSLuaFile( "loop/base.lua" )
AddCSLuaFile( "loop/multiple.lua" )
AddCSLuaFile( "loop/simple.lua" )
AddCSLuaFile( "loop/table.lua" )
AddCSLuaFile( "loop/collection/ObjectCache.lua" )


local RDx_Beams = require "RDx_Beams"


--TODO: use all local vars instead of package.seeall

module("RDx", package.seeall)

--global setting for links
MAX_LINK_LENGTH = 2048
EXTRA_LINK_LENGTH = 64

--[[		== Network Tables Structures ==
--		=== A New, New Method by TAD2020 ===


There are basically two tables on each device that maintain the 
links between devices for sharing resources: the links table and 
the networks table. This separation was used for simplicity.

Links are the 'physical' links between devices as far as the users 
sees. These are used to build the networks links. The table just 
says which other devices this one is joined to directly with 'hoses', 
it goes no farther than immediate next device. By walking across 
these links to devices with common resource a network is built. A 
full rebuild of the networks from links is never needed because we 
can only add one device at a time or remove one either completely 
or just a single link.

Networks are a shared object/table for a single resource on all 
devices that are linked that have that resource.

Example: 5 devices are linked to each other in a chain
dev1 --- dev2 --- dev3 --- dev4 --- dev5
air  -1- air               air  -2- air
engy -3- engy -3- engy -3- engy -3- engy
                  cool
Even though they are all link, dev1&2's air will not get to dev4 or 
dev5 because dev3 does not have air, so this system has 2 networks 
for air, 1 for energy and none for coolant. Actually dev3 has a 'local' 
netowrk for coolant, but that really just a placeholder/stater network 
until/for linking to another coolant device.
]]

--	==notes==
-- BeamNetVars.SetNetAmount( net.ID, net.amount ) -- this updates client side of the ammount of res on this net
-- ent.Entity:SetResourceNetID( net1.resID, net1.ID, true ) -- this tells the client side of the ent what net it is on






-- debug crap

function PrintTable2(t,tabs,dt,tn)
	tabs = tabs or 0
	dt = dt or {}
	tn = tn or 1
	dt[tostring(t)] = tn
	tn = tn + 1
	for k,v in pairs(t) do
		if type(v) == "table" then
			if !dt[tostring(v)] then
				Msg(string.rep("\t",tabs)..k.."\t=\t"..tostring(v).." t: "..tn.."\n")
				tn = PrintTable2(v,tabs+1,dt,tn)
			else
				Msg(string.rep("\t",tabs)..k.."\t=\t"..tostring(v).." t: "..dt[tostring(v)].."\n")
			end
		else
			Msg(string.rep("\t",tabs)..k.."\t=\t"..tostring(v).."\n")
		end
	end
	return tn
end

function PrintTable1(t,tabs)
	tabs = tabs or 0
	Msg(string.rep("\t",tabs)..tostring(t).." t: 1\n")
	return PrintTable2(t,tabs)
end


if CLIENT then return end --nothing here yet for clients

function PrintResources(dev)
	if not dev then Msg("no devices\n") return end
	Msg("=== device on ent: "..tostring(dev.ent).." ===\n")
	PrintTable1( dev )
	--[[local tn = PrintTable1( ent.RDx.resources )
	Msg("num tables: "..tn.."\n=== networks ===\n")
	for resID, restab in pairs( ent.RDx.resources ) do
		if ent.is_valve then
			for netID,_  in pairs( restab.nets ) do
				Msg("\t=== net "..Networks[ netID ].res_name.." "..netID.." ===\n")
				local tn = PrintTable1(  Networks[ netID ] or {}, 1 )
				Msg("\t=== num tables: "..tn.." ===\n")
			end
		else
			Msg("\t=== net "..Networks[ restab.net ].res_name.." "..restab.net.." ===\n")
			local tn = PrintTable1( Networks[ restab.net ] or {}, 1 )
			Msg("\t=== num tables: "..tn.." ===\n")
		end
	end]]
	Msg("=========================\n")
end







networks = {classes = {}, next_netID = 1, nets = {}}
--RDx.networks.New( resID, entID )
--	makes a new empty network.
function networks.New( res_type, net_class_name, tab )
	if not networks.classes[net_class_name] then
		error("RDx: cannot fine net_class_name: "..net_class_name)
	end
	
	local netID = networks.next_netID
	networks.next_netID = networks.next_netID + 1
	
	local net = networks.classes[ net_class_name ](tab, netID, res_type)
	
	-- add the new network to our list
	networks.nets[ net.ID ] = net
	
	MsgN("made new network "..net.ID)
	
	return net
end
--RDx.networks.Remove( netID )
--	deletes given net.
function networks.Remove( net )
	networks.nets[ net.ID ] = nil
	--BeamNetVars.ClearNetAmount( net.ID ) --clears the net table to clients won't be sent this on join
end
--RDx.networks.Define(res_name, net_class)
--	defines a network class
function DefineNetwork(net_class, net_class_name)
	MsgN("DefineNetwork: net_class_name: ",net_class_name)
	net_class.net_class_name			= net_class_name
	networks.classes[net_class_name]	= net_class
end



resources = {classes = {}, next_resID = 1}
function resources.New(res_type, res_class_name, dev, tab)
	if not resources.classes[res_class_name] then
		error("RDx: cannot fine res_class_name: "..res_class_name)
	end
	
	local resID = resources.next_resID
	resources.next_resID = resources.next_resID + 1
	
	local res = resources.classes[res_class_name](tab, dev, resID, res_type)
	
	return res
end
function DefineResource( res_class, res_class_name, net_class_name )
	MsgN("DefineResource: res_class_name: ",res_class_name," net_class_name: ",net_class_name)
	res_class.res_class_name			= res_class_name
	res_class.net_class_name			= net_class_name
	resources.classes[res_class_name]	= res_class
end




devices = {classes = {}, next_devID = 1}
function devices.New(dev_class_name, ent, tab)
	if not devices.classes[dev_class_name] then
		error("RDx: cannot fine dev_class_name: "..dev_class_name)
	end
	
	local devID = devices.next_devID
	devices.next_devID = devices.next_devID + 1
	
	local dev = devices.classes[dev_class_name](tab, ent, devID)
	
	return dev
end
function DefineDevice( dev_class, dev_class_name, dev_type )
	MsgN("DefineDevice: dev_class_name: ",dev_class_name," dev_type: ",dev_type)
	dev_class.dev_class_name		= dev_class_name
	dev_class.dev_type				= dev_type
	devices.classes[dev_class_name]	= dev_class
end



function AttachNewDevice( dev_class_name, dev_type, ent, tab )
	--make a new device
	local dev = RDx.devices.New(dev_class_name, ent, tab)
	--store the device on the entity
	ent.RDx = ent.RDx or {}
	ent.RDx.devices = ent.RDx.devices or {}
	ent.RDx.devices[dev_type] = dev
	return dev
end


function RemoveDevice( dev_type, ent )
	if not (ent and ent.RDx and ent.RDx.devices) then 
		error("RDx.RemoveAllDevices: no devices on ent "..tostring(ent))
	end
	ent.RDx.devices[dev_type]:Remove()
	ent.RDx.devices[dev_type] = nil
end

function RemoveAllDevices( ent )
	if not (ent and ent.RDx and ent.RDx.devices) then 
		error("RDx.RemoveAllDevices: no devices on ent "..tostring(ent))
	end
	for dev_type,dev in pairs(ent.RDx.devices) do
		RemoveDevice( dev_type, ent )
	end
end


include("RDx/classes/dev_base.lua")
include("RDx/classes/res_base.lua")
include("RDx/classes/net_base.lua")








--Save/Load local data tabels --TODO: not save module functions in this :S
local function RDxSave( save )
	local savetab			= {}
	savetab.networks		= networks
	savetab.resources		= resources
	savetab.devices			= devices
	saverestore.WriteTable( savetab, save )
end
local function RDxRestore( restore )
	local restoretab		= saverestore.ReadTable( restore )
	networks				= restoretab.networks
	resources				= restoretab.resources
	devices					= restoretab.devices
end
saverestore.AddSaveHook( "RDxSave", RDxSave )
saverestore.AddRestoreHook( "RDxSave", RDxRestore )




--crap for junctions that need to be reworked

--RDx.GetJuncRes( ent1, class, ent2, recurse_res )
--	
function GetJuncRes( ent1, ent2, recurse_res )
	if ent1.RDx.act_as_junction == true then
		for resID,restab in pairs( ent2.RDx.resources ) do
			AddResource(ent1, restab.res_name, 0)
			-- Msg( "Adding " .. restab.res_name .. "\n" )
			recurse_res[resID] = restab.res_name
		end
	end
end

--RDx.RecurseJunc( ent, recurse_res, done )
--	
-- Makes all linked pumps, valves and junctions connected together all share the same resources (TAD2020)
-- This is a costly funciton when lots of junctions are linked
function RecurseJunc( ent, recurse_res, done )
	done = done or {}
	for ent1ID,ent1 in pairs(ent.RDx.links) do
		if not done[ent1] then
			if not ent1:IsValid() then
				ent.RDx.links[ent1ID] = nil
			else
				done[ent1] = ent1
				local ent1_class = ent1.Entity:GetClass()
				if ent.RDx.act_as_junction == true then
					for _, res in pairs( recurse_res ) do
						AddResource(ent1, res, 0)
					end
					RecurseJunc(ent1, recurse_res, done)
				end
			end
		end
	end
end

--RDx.SetJuncRes( ent, class, recurse_res )
--	
function SetJuncRes( ent, recurse_res )
	if ent.RDx.act_as_junction == true then
		RecurseJunc( ent, recurse_res )
	end
end

--RDx.CheckEntsOnLink( ent1, ent2 )
--	
function CheckEntsOnLink( ent1, ent2 )
	local recurse_res = {}
	GetJuncRes( ent1, ent2, recurse_res )
	GetJuncRes( ent2, ent1, recurse_res )
	SetJuncRes( ent1, recurse_res )
	SetJuncRes( ent2, recurse_res )
end

--RDx.GetCommonRes( ent1, ent2 )
--	
function GetCommonRes( ent1, ent2 )
	local commonres = {}
	for resID, restab in pairs( ent1.RDx.resources ) do
		if (ent2.RDx.resources[resID]) then table.insert( commonres, resID ) end
	end
	return commonres
end




--duplicator support

--build the DupeInfo table and save it as an entity mod
function BuildDupeInfo( ent )
	if not ent.RDx.resources then return end
	
	local info = {}
	info.devices = {}
	
	--local beamtable = RDbeamlib.GetBeamTable( ent )
	info.beams = {}
	
	for ent2ID, ent2 in pairs( ent.RDx.links ) do
		if ent2 and ent2:IsValid() then 
			table.insert(info.devices, ent2ID)
			
			--[[if beamtable[ent2] then
				info.beams[ent2ID] = beamtable[ent2]
			end]]
		end
	end
	
	if info.devices then
		duplicator.StoreEntityModifier( ent, "RDxDupeInfo", info )
	end
	
end

--apply the DupeInfo
function ApplyDupeInfo( ent, CreatedEntities )
	if ent.EntityMods and ent.EntityMods.RDxDupeInfo and ent.EntityMods.RDxDupeInfo.devices then
		
		local RDxDupeInfo = ent.EntityMods.RDxDupeInfo
		
		for _,ent2ID in pairs(RDxDupeInfo.devices) do
			local ent2 = CreatedEntities[ ent2ID ]
			
			if ent2 and ent2:IsValid() then
				
				--TODO: redo
				--[[if RDxDupeInfo.beams and RDxDupeInfo.beams[ ent2ID ] then
					Dev_Link(
						ent, ent2, 
						RDxDupeInfo.beams[ ent2ID ].start_pos, 
						RDxDupeInfo.beams[ ent2ID ].dest_pos, 
						RDxDupeInfo.beams[ ent2ID ].material, 
						RDxDupeInfo.beams[ ent2ID ].color, 
						RDxDupeInfo.beams[ ent2ID ].width
					)
				else
					Dev_Link(ent, ent2)
				end]]
			end
		end
		
		ent.EntityMods.RDxDupeInfo = nil --trash this info, we'll never need it again
		
	end
end	

function AfterPasteMods(ply, Ent, DupeInfo)
	--doesn't need to do anything for now
end







--old crap to rewrite

function ModifyNetAmount( net, amount )
	if (!net) then return 0 end
	
	local oldamount = net.amount
	net.amount = math.Clamp( (net.amount + amount), 0, net.max )
	--BeamNetVars.SetNetAmount( net.ID, net.amount )
	
	return net.amount - oldamount
end

function SetUpPod( ent )
	if (LIFESUPPORT and LIFESUPPORT == 2) then
		Msg("pod registered: "..tostring(ent).."\n")
		LS_RegisterEnt(ent, "Pod")
		AddResource(ent, "air", 0)
		AddResource(ent, "energy", 0)
		AddResource(ent, "coolant", 0)
	end
end


--Consumes a named resource from the entity
function ConsumeResource( ent, res, amount )
	if not (ent and res and amount) then return end
	local resID = EnumResource(res)
	local net = networks.Get( ent, resID )
	return (-1 * ModifyNetAmount( net, (-1 * amount) ))
end

--Replenishes a named resource on the entity by a specified amount
function SupplyResource( ent, res, amount )
	if not (ent and res and amount) then return end
	local resID = EnumResource(res)
	local net = networks.Get( ent, resID )
	return ModifyNetAmount( net, amount )
end


local PUMP_NONE = 0 --no pump installed
local PUMP_NO_POWER = 1 --pump has no power
local PUMP_READY = 2 --pump ready for connection
local PUMP_ACTIVE = 3 --pump on
local PUMP_RECEIVING = 4 --not used
local Pump_Energy_Increment = 5

-- PumpResource: move a resource from one net to another one
-- pump (bool): true = res moves from net1 to net2. false = equlize both net to within a precent
-- rate: for pumps, how much of the resource is moved per tick
-- pump true and rate 0 make a one way check valve
-- returns amount moved from net1 to net2
function PumpResource( net1, net2, pump, rate, ispump )
	if (net1.ID == net2.ID) then return 0 end --dummy, we can't pump to our own net
	if (net1.max == net1.amount and net2.max == net2.amount) or (net1.amount == 0 and net2.amount == 0) then return 0 end --nothing to do
	
	--TODO: fix this code to work :V
	--[[local pullnet, pushnet = net1, net2
	if (pump and rate < 0) then pullnet, pushnet = net2, net1 end
	-- local pullnetfactor = net1.amount / net1.max
	-- local pushnetfactor = net2.amount / net2.max
	local pullnetfactor = net1:GetNetFactor()
	local pushnetfactor = net1:GetNetFactor()
	local pressure = pushnetfactor - pullnetfactor
	local take = math.min( (pushnet.max - pushnet.amount),  math.min( pullnet.amount, math.abs(rate) )) --how much we're going to move
	local energyused = 0
	
	if (pump and pressure < 0 and ispump) then --LS2 is installed and we has a pump
		if (LIFESUPPORT and LIFESUPPORT == 2) then
			local energyneeded = math.abs(math.floor(math.max(take, 50) / 100 * Pump_Energy_Increment))
			if (energyneeded >= 0) then --going to need energy to do this
				if (pullnet.res_name == "energy" and GetResourceAmount(self, "energy") >= energyneeded + take)
				 or (pullnet.res_name != "energy" and GetResourceAmount(self, "energy") >= energyneeded) then
					energyused = ConsumeResource( self, "energy", energyneeded )
				else --not enought energy!!!
					return 0
				end
			end
		end
	elseif (!pump and pressure < 0) then --are we crazy, we can't pump that if we can't pump!
		return 0
	elseif (pressure > 0) then
		-- local pullnetfactorafter = (net1.amount - take) / net1.max
		-- local pushnetfactorafter = (net2.amount + take) / net2.max
		local pullnetfactorafter = GetFactor( (net1.amount - take), net1.max )
		local pushnetfactorafter = GetFactor( (net2.amount + take), net2.max )
		local pressureafter = pushnetfactorafter - pullnetfactorafter
		if (pressureafter < 0) then --shit, we can pump all of this
			if (pump and ispump) then
				if (LIFESUPPORT and LIFESUPPORT == 2) then --LS2 is installed and we has a pump
					local energyneeded = math.abs(math.floor(math.max(take * (pressureafter - pressure), 50) / 100 * Pump_Energy_Increment))
					if (energyneeded >= 0) then --going to need energy to do this
						if (pullnet.res_name == "energy" and GetResourceAmount(self, "energy") >= energyneeded + take)
						 or (pullnet.res_name != "energy" and GetResourceAmount(self, "energy") >= energyneeded) then
							energyused = ConsumeResource( self, "energy", energyneeded )
						else --not enought energy!!!
							take = take * (pressure - pressureafter)
						end
					end
				end
			else
				take = take * (pressure - pressureafter)
			end
		end
	end
	
	
	local result = SupplyResource( pushnet, ConsumeResource( pullnet, take ) ) --pump
	
	if (rate > 0) then return result else return -1 * result end]]
	
	--TODO: fuckit, this will work for now
	if (pump and rate != 0) then
		local pullnet, pushnet = net1, net2
		if (rate < 0) then pullnet, pushnet = net2, net1 end
		if (pullnet.amount <= 0 or pushnet.amount >= pushnet.max) then return 0 end --net1 must have soemthing and net2 must have some room
		
		local take = math.min( (pushnet.max - pushnet.amount),  math.min( pullnet.amount, math.abs(rate) )) --how much we can take
		if (take <= 0) then return 0 end
		local result = ModifyNetAmount( pushnet, (-1 * ModifyNetAmount( pullnet, (-1 * take) )) ) --pump
		if (rate > 0) then return result else return -1 * result end
	else --equalize nets
		-- local factor1 = net1.amount / net1.max
		-- local factor2 = net2.amount / net2.max
		local factor1 = net1:GetNetFactor()
		local factor2 = net2:GetNetFactor()
		
		if (pump and rate == 0 and factor1  > factor2) or (!pump) then --one way or equalize
			local oldamount = net1.amount
			local factor = (net1.amount + net2.amount) / (net1.max + net2.max) --average factor
			net1.amount = math.Round(net1.max * factor)
			net2.amount = math.Round(net2.max * factor)
			--BeamNetVars.SetNetAmount( net1.ID, net1.amount )
			--BeamNetVars.SetNetAmount( net2.ID, net2.amount )
			return oldamount - net1.amount --chage from net1 to net2
		end
	end
	-- return 0
end

function Pump( Socket, OtherSocket )
	if (Socket and OtherSocket) then
		local pump, rate = false, 100
		if (Socket.pump_active == 1) then
			local SocketStatus, SocketRate = Socket.pump_status, Socket.pump_rate
			if (SocketStatus <= PUMP_NO_POWER) then SocketRate = 0 end --don't pump if there's no power
			local OtherSocketStatus, OtherSocketRate = OtherSocket.pump_status, OtherSocket.pump_rate
			if (OtherSocketStatus <= PUMP_NO_POWER) then OtherSocketRate = 0 end --don't pump if there's no power
			rate = SocketRate - OtherSocketRate
			pump = (SocketStatus == PUMP_ACTIVE or SocketStatus == PUMP_NO_POWER or OtherSocketStatus == PUMP_ACTIVE or OtherSocketStatus == PUMP_NO_POWER)
		end
		
		--Msg("rate= "..rate.." pump= "..tostring(pump).."\n")
		local pusshed = 0 --this is the ammount we had to push past equilibrium
		for resID1, restab1 in pairs( Socket.RDx.resources ) do
			for resID2, restab2 in pairs( OtherSocket.RDx.resources ) do
				if ( resID1 == resID2 ) then 
					local net1 = networks.Get( Socket, resID1 )
					local net2 = networks.Get( OtherSocket, resID1 )
					
					--Msg("SocketStatus= "..SocketStatus.." OtherSocketStatus= "..OtherSocketStatus.."  "..tostring(pump).." rate= "..rate.." net1= "..net1.ID.." net2= "..net2.ID.."\n")
					
					pusshed = pusshed + RDx_PumpResource( net1, net2, pump, rate, (Socket.pump_active == 1) )
					
				end
			end
		end
		return pusshed
	end
	return 0
end


function EqualizeNets( ent )
	for resID,restab  in pairs( ent.RDx.resources ) do
		local amount, max = 0,0
		for _,netID in pairs( restab.nets ) do
			local net = Networks[ netID ]
			if (net == nil) then
				restab.nets[netID] = nil
			else
				amount = amount + net.amount
				max = max + net.max
			end
		end
		-- if (max > 0) then factor = amount / max end
		local factor = GetFactor( amount, max )
		--Msg("amount= "..amount.." max= "..max.." factor= "..factor.."\n")
		for _,netID in pairs( restab.nets ) do
			local net = Networks[ netID ]
			--Msg("netID: "..netID.." net.max= "..net.max.." net.amount= "..net.amount)
			net.amount = math.Round(net.max * factor)
			--BeamNetVars.SetNetAmount( net.ID, net.amount )
			--Msg(" after= "..net.amount.."\n")
		end
	end
end


--Returns true if device uses resource
function CheckResource( ent, res )
	local resID = EnumResource(res)
	local check = GetRes( ent, resID )
	if (check) then return 1 end
	return 0
end

--Returns the amount of a named resource accessable to the entity
function GetResourceAmount( ent, res )
	local resID = EnumResource(res)
	local net = networks.Get( ent, resID )
	if (net) then return net.amount end
	return 0
end

--Returns the maximum storage capacity of a specified entity, disregarding the network size(for named resource only)
function GetUnitCapacity( ent, res )
	local resID = EnumResource(res)
	local check = GetRes( ent, resID )
	if (check) then return check.capacity end
	return 0
end

--Returns the maximum storage capacity of an entire network accessable to the entity(for named resource only)
function GetNetworkCapacity( ent, res )
	local resID = EnumResource(res)
	local net = networks.Get( ent, resID )
	if (net) then return net.max end
	return 0
end

--Disables or Enables the passage of all resources through this device(0 = closed, 1 = open)
function ValveState( ent, toggle )
	if (ent.is_valve) then
		if not (toggle == 0) then toggle = 1 end --open
		ent.valve_state = toggle
	end
end

