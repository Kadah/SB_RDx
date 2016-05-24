--[[-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- 	===RDx Beam===						-- 
-- 	==Client Side Beams Library==				-- 
-- 	Custom Networked Vars and Beams Module		-- 
-- 	By: TAD2020						-- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- ]]

MsgN("====== Loading RDx Beams Module ======")

AddCSLuaFile( "rdx_beams.lua" )



module("RDx_Beams", package.seeall)



local Buffer = {}
local nedts = {}


--an extension system, use it
--your extension will need to do AddCSLuaFile("BeamVarsExtensions/yourfile.lua") if clients need it too
--[[for _,v in pairs( file.FindInLua("BeamVarsExtensions/*.lua") ) do
	Msg("Loading BeamVarExtension: "..v.."\n")
	include( "BeamVarsExtensions/"..v )
end]]




--TODO: this stuff:
--[[
	class for networked entity data table (NEDT class, working name for now)  on both client and server that has to be made on the ent by the ent's init
	NEDT class needs to:
		have an update member function that is called by this module (for by other for forced update)
		update function needs to handle umsg and umsg recpt list (or something similar)
		a data table retrieve function(s) (shared) that will check if its data table is nil, it needs to check with this module to see if data has been recieved while the ent was not existant on client end
		needs a set function(s) on server side that queres the update with this module
		needs a function to quere update to single player when they join. NEDT:PlayerJoin(ply)
		can have as many data tables as it likes as long as it handles which one it needs to update (ie. internal update managment)
		use index of its parent entity so this module can index it on the client side before it;s entity exists
		be stored in a predefinded place on the entity (ie. ent.myNEDT)
		NEDT objects need to be tracked by this module, like how networks on on RDx module, so they can be told when a player has joined
		need support for NEDT objects for networks
		actually, this should work:
			we have to make our NEDT objects on both the server and client, this module will not make them for you.
			you have to give the index for the NEDT to use
			the index must be unique, or does it?
			when we make a NEDT, register it with this module so when data is recieved by the client, this module can directly set it on the NEDT
			maybe NEDTs can be told when they have the data it was waiting for, ie. "when i get my data, turn this on"
	
	this class needs a function to make and define NEDT object and classes like main RDx module
	
	
]]



function EntInit( ent )
	MsgN("EntInit ",tostring(ent))
	
	local entID = ent:EntIndex()
	
	nedts[entID] = ent
	
	--check for messages
	if CLIENT and Buffer[entID] then
		--MsgN("Have data in buffer ",tostring(ent))
		RDx.PrintTable1(Buffer[entID])
		for i,data in pairs(Buffer[entID]) do
			--MsgN("buffer ",entID," i:",i)
			ent:NEDT_DataRecieved(data)
		end
		Buffer[entID] = nil
	end
	
	
end

function EntRemove( ent )
	--MsgN("EntRemove ",tostring(ent))
	nedts[ent:EntIndex()] = nil
end


-- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 	Server Side Functions
-- -- -- -- -- -- -- -- -- -- -- -- -- --
if SERVER then
	
	function QueryUpdate( ent )
		MsgN("QueryUpdate ",tostring(ent))
		Buffer[ent:EntIndex()] = ent
		
	end
	
	local function NetworkVarsSend()
		--while true do
			--flip buffers
			local SendingBuffer = Buffer
			Buffer = {}
			
			local i = 0
			for Index, ent in pairs(SendingBuffer) do
				
				if ent and ent:IsValid() and ent.NEDT_Update then
					--MsgN("doing Update")
					ent:NEDT_Update()
				end
				--i = i + 1
				--if i > 10 then
					--coroutine.yield()
					--i = 0
					--break
				--end
			end
			
			--coroutine.yield()
		--end
	end
	--local co_send = coroutine.create(NetworkVarsSend)

	local NextSendTime = 0
	local function NetworkVarsSend_think()
		if CurTime() >= NextSendTime then
			
			--coroutines in gmod are foobar right now
			--bad argument #1 to 'resume' (string expected, got thread)
			--[[if not co_send then co_send = coroutine.create(NetworkVarsSend) end
			coroutine.resume(co_send)]]
			
			NetworkVarsSend()
			
			NextSendTime = CurTime() +  .1
		end
	end
	hook.Add("Think", "RDxBeams_Think", NetworkVarsSend_think)
	
	
	
	-- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- 	Player join stuff
	-- -- -- -- -- -- -- -- -- -- -- -- -- --
	function FullPlayerUpdate( ply )
		Msg("==sending netbeamvar var data to "..tostring(ply).."\n")
		for entID,ent in pairs(nedts) do
			ent:NEDT_PlayerJoin( ply )
		end
	end
	
	--  Offset the sending of data a little after the player has join
	function PlayerJoin( ply )
		timer.Simple(4, FullPlayerUpdate, ply)
		hook.Add("Think", "RDxBeams_Think", NetworkVarsSend_think)
	end
	hook.Add( "PlayerInitialSpawn", "FullUpdateEntityNetworkBeamVars", PlayerJoin )
	
	
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
	-- 	Save/Load hooks
	-- -- -- -- -- -- -- -- -- -- -- -- -- -- /
	--  Save net vars to file
	local function Save( save )
		local data = {
			Buffer = Buffer,
			nedts = nedts,
		}
		saverestore.WriteTable( data, save )
	end
	local function Restore( restore )
		local data = saverestore.ReadTable( restore )
		Buffer = data.Buffer
		nedts = data.nedts
		PrintTable1(data)
	end
	saverestore.AddSaveHook( "EntityRDxBeams", Save )
	saverestore.AddRestoreHook( "EntityRDxBeams", Restore )
	
	
end --SERVER only


-- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 	Client Side Functions
-- -- -- -- -- -- -- -- -- -- -- -- -- --
if CLIENT then
	
	function GetData(entID, data)
		if nedts[entID] and nedts[entID]:IsValid() then
			MsgN("doing DataRecieved ",entID)
			nedts[entID]:NEDT_DataRecieved(data)
		else
			MsgN("buffering data ",entID)
			Buffer[entID] = Buffer[entID] or {}
			table.insert(Buffer[entID], data)
		end
	end
	
	
	--  Net vars dump
	local function Dump()
		Msg("Networked Beam Vars...\n")
		--PrintTable( NetworkVars )
	end
	concommand.Add( "networkbeamvars_dump", Dump )

end

