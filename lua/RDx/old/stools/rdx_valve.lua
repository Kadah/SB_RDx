TOOL.Category			= "(Resource Dist. x)"
TOOL.Name				= "#Cutoff Valve"

TOOL.DeviceName			= "Cutoff Valve"
TOOL.DeviceNamePlural	= "Cutoff Valves"
TOOL.ClassName			= "res_valve"
TOOL.Model				= "models/props_c17/utilityconnecter006.mdl"
TOOL.DevSelect			= false

TOOL.Limited			= true
TOOL.MaxName			= "cutoffvalves"
TOOL.Limit				= 10

if ( CLIENT ) then
	language.Add( 'Tool_cutoff_valve_name', 'Cutoff Valve' )
	language.Add( 'Tool_cutoff_valve_desc', 'Create a Cutoff Valve attached to any surface.' )
	language.Add( 'Tool_cutoff_valve_0', 'Left-Click: Spawn a Device.' )
end

if SERVER then
	function MakeCutoffValve( ply, Ang, Pos, frozen )
		if ( !ply:CheckLimit( "cutoffvalves" ) ) then return nil end
		
		local ent = ents.Create( "res_valve" )
		if !ent:IsValid() then return false end
			ent:SetModel("models/props_c17/utilityconnecter006.mdl")
			ent:SetAngles(Ang)
			ent:SetPos(Pos)
			ent:SetPlayer(ply)
		ent:Spawn()
		
		if frozen and ent:GetPhysicsObject():IsValid() then
			local phys = ent:GetPhysicsObject()
			phys:EnableMotion(false) 
			ply:AddFrozenPhysicsObject( ent, phys )
		end
		
		ply:AddCount('cutoffvalves', ent)
		
		return ent
	end
	duplicator.RegisterEntityClass("res_valve", MakeCutoffValve, "Ang", "Pos", "frozen")
	TOOL.MakeFunc = MakeCutoffValve
end



