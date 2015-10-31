
CutterAttacherHeightRegister = {};
CutterAttacherHeightRegister.isLoaded = true;
CutterAttacherHeightRegister.g_currentModDirectory = g_currentModDirectory;

if SpecializationUtil.specializations["CutterAttacherHeight"] == nil then
	SpecializationUtil.registerSpecialization("CutterAttacherHeight", "CutterAttacherHeight", g_currentModDirectory.."cutterAttacherHeight.lua")
	CutterAttacherHeightRegister.isLoaded = false;
end;

function CutterAttacherHeightRegister:loadMap(name)	
  if not CutterAttacherHeightRegister.isLoaded then	
		CutterAttacherHeightRegister:add();
    CutterAttacherHeightRegister.isLoaded = true;
  end;
end;

function CutterAttacherHeightRegister:deleteMap()
  --CutterAttacherHeightRegister.isLoaded = false;
end;

function CutterAttacherHeightRegister:mouseEvent(posX, posY, isDown, isUp, button)
end;

function CutterAttacherHeightRegister:keyEvent(unicode, sym, modifier, isDown)
end;

function CutterAttacherHeightRegister:update(dt)
end;

function CutterAttacherHeightRegister:draw()
end;

function CutterAttacherHeightRegister:add()
	print("--- loading "..g_i18n:getText("ZZZ_CAH_VERSION").." by mogli ---")

	local searchTable = { };	
	
	for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
		local modName           = string.match(k, "([^.]+)");
		local addSpecialization = true;
		local correctLocation   = false;
		
		for _, search in pairs(searchTable) do
			if SpecializationUtil.specializations[modName .. "." .. search] ~= nil then
				addSpecialization = false;
				break;
			end;
		end;
		
		for i = 1, table.maxn(v.specializations) do
			local vs = v.specializations[i];
			if      vs ~= nil 
					and vs == SpecializationUtil.getSpecialization("cutter") then
				correctLocation = true;
				break;
			end;
		end;
		
		if addSpecialization and correctLocation then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("CutterAttacherHeight"));			
		  print("  CutterAttacherHeight was inserted on " .. k);
		end;
	end;
	
	g_i18n.globalI18N.texts["ZZZ_CAH_UP"]   = g_i18n:getText("ZZZ_CAH_UP");
	g_i18n.globalI18N.texts["ZZZ_CAH_DOWN"] = g_i18n:getText("ZZZ_CAH_DOWN");
	g_i18n.globalI18N.texts["ZZZ_CAH_ON"]   = g_i18n:getText("ZZZ_CAH_ON");
	g_i18n.globalI18N.texts["ZZZ_CAH_OFF"]  = g_i18n:getText("ZZZ_CAH_OFF");
	
end;

addModEventListener(CutterAttacherHeightRegister);
