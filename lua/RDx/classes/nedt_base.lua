local nedt_base = oop.class()

function nedt_base:__init(nedt, ent, nedtID)
	nedt = oop.rawnew (self, nedt or {})
	
	nedt.ID = nedtID
	
	if ent then
		nedt.ent = ent
		ent.myNEDT = nedt
	end
	
	return nedt
end

function nedt_base:__type()
	return "RDxBeamsNEDT"
end

function nedt_base:__tostring()
	return "RDxBeamsNEDT["..self.ID.."]"
end


function nedt_base:SetData(tab)
	self.data = tab
	RDx_Beams.QuereUpdate( self )
end

if CLIENT then
	function nedt_base:RunOnceOnDataRecieved( func, ... )
		self._RunOnceOnDataRecieved = {func = func, args = arg}
	end
	
	
	function nedt_base:RunOnDataRecieved( func, ... )
		self._RunOnDataRecieved = {func = func, args = arg}
	end
	
	
	function nedt_base:DataRecieved(um)
		
		self.data = {}
		self.data[1] = um:ReadChar()
		self.data[2] = um:ReadLong()
		MsgN("DataRecieved ",self.data[1]," ",self.data[2])
		
		if self._RunOnceOnDataRecieved then
			assert(pcall(self._RunOnceOnDataRecieved.func, unpack(self._RunOnceOnDataRecieved.args)))
			self._RunOnceOnDataRecieved = nil
		end
		
		if self._RunOnDataRecieved then
			assert(pcall(self._RunOnDataRecieved.func, unpack(self._RunOnDataRecieved.args)))
		end
	end
end

if SERVER then
	
	function nedt_base:Update()
		
		MsgN("Update")
		
		umsg.Start("RDxBeams", self.rp)
			umsg.Short( self.ID )
			umsg.Char( self.data[1])
			umsg.Long( self.data[2] )
		umsg.End() 
		
	end
	

	function nedt_base:PlayerJoin( ply )
		
		
	end

end

--[[
lua_run PrintTable(player.GetByID(1):GetEyeTrace().Entity.myNEDT)
lua_run_cl PrintTable(player.GetByID(1):GetEyeTrace().Entity.myNEDT)
]]


oop.storeclass(nedt_base, "RDx", "beams", "base")

RDx_Beams.DefineNEDT(nedt_base, "base")

