--
--	Resource Distribution 2 Tab Module and Tool Helper
--

local usetab = CreateClientConVar( "RDx_UseLSTab", "1", true, false )

local function LSTab()
	if usetab:GetBool() then
		spawnmenu.AddToolTab( "Life Support", "Life Support" )
	end
end
hook.Add( "AddToolMenuTabs", "LSTab", LSTab)

--put this in your tool to support the tab
--if not ( RES_DISTRIB == 2 ) then Error("Please Install Resource Distribution 2 Addon.'" ) return end
--if (CLIENT and GetConVarNumber("RDx_UseLSTab") == 1) then TOOL.Tab = "Life Support" end

function RD2_BuildCPanel( cp, toolname, listname, custom )
	if (RES_DISTRIB and RES_DISTRIB == 2) then
		--cp:AddControl( 'Header', { Text = '#Tool_'..toolname..'_name', Description	= '#Tool_'..toolname..'_desc' })  
		cp:AddControl("CheckBox", { Label = "Don't Weld", Command = toolname.."_DontWeld" })
		cp:AddControl("CheckBox", { Label = "Allow welding to world", Command = toolname.."_AllowWorldWeld" })
		cp:AddControl("CheckBox", { Label = "Make Frozen", Command = toolname.."_Frozen" })
		--Create the custom controls
		if custom then
			for k, v in pairs(custom) do
				if v.type == "slider" then
					cp:AddControl( "slider", { Label = v.text..":", Type = "Integer", Description =  v.description, Min = v.min, Max = v.max, Command = toolname.."_"..k })
				elseif v.type == "checkbox" then
					cp:AddControl( "CheckBox", { Label = v.text..":", Command = toolname.."_"..k })
				elseif v.type == "text" then
					cp:AddControl( "TextBox", {  Label = v.text..":", MaxLength = 255, Text = v.text or "",  Command = toolname.."_"..k  })
				elseif v.type == "modellist" and v.models then
					cp:AddControl( "PropSelect" ,{ Label= "Model "..v.text..":" , ConVar = toolname.."_"..k ,Category="" , Models=v.models })
				end
			end
		end
		-------------------------
		local ListControl = vgui.Create( "RD2Control" )
		cp:AddPanel( ListControl )
		ListControl:SetList( toolname, listname )
	else --hmmmm
		cp:AddControl( "Label", { Text = "Install Resource Distribution 2 Addon" } )
	end
end

