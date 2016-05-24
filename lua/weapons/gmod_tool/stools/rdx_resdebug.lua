
TOOL.Category		= "(Resource Dist. x)"
TOOL.Name			= "Res. Debuger"
TOOL.Command		= nil
TOOL.ConfigName		= nil
if (CLIENT and GetConVarNumber("RDx_UseLSTab") == 1) then TOOL.Tab = "Life Support" end


if CLIENT then
	language.Add( "Tool_resdebug_name",	"RD Resource Debuger" )
	language.Add( "Tool_resdebug_desc",	"Spams teh ent's resource table to the console" )
	language.Add( "Tool_resdebugr_0", "Click an RD Ent" )
end

function TOOL:LeftClick( trace )
	if not trace.Entity:IsValid()  then return false end
	if CLIENT then return true end
	
	if not (trace.Entity.RDx and trace.Entity.RDx.devices and trace.Entity.RDx.devices["base"]) then Msg("ent has no devices\n") return end
	
	RDx.PrintResources(trace.Entity.RDx.devices["basic"])
	
	return true
	
end

function TOOL:RightClick( trace )
	if not trace.Entity:IsValid()  then return false end
	if CLIENT then return true end
	
	local ent = trace.Entity
	
	--local dev = RDx.devices.New("base", ent)
	local dev = RDx.AttachNewDevice("base", "basic", ent)
	local res = dev:AddRes("air", "base")
	
	return true
end

function TOOL:Reload( trace )
	if not trace.Entity:IsValid()  then return false end
	if CLIENT then return true end
	
	--for something else
	
	return true
end