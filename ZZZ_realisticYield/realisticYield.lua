realisticYield = {};
realisticYield.doit = true
realisticYield.checkit = false
realisticYield.realisticYieldFactor = 0.5
function realisticYield:loadMap(name)
end;

function realisticYield:deleteMap()
	if realisticYield.modificationDone then
		realisticYield.modificationDone = false

		for name,desc in pairs(FruitUtil.fruitTypes) do
			if desc.origLiterPerSqm ~= nil then
				desc.literPerSqm     = desc.origLiterPerSqm
				desc.origLiterPerSqm = nil
			end
		end
	end
end;

function realisticYield:keyEvent(unicode, sym, modifier, isDown)

end;

function realisticYield:mouseEvent(posX, posY, isDown, isUp, button)

end;

function realisticYield:update(dt)
	if realisticYield.doit and not ( realisticYield.modificationDone ) then
		realisticYield.modificationDone = true
		
		print("============================================================")
		print(tostring(g_currentMission.terrainSize).." / "..tostring(g_currentMission.fruitMapSize).." => "..tostring(g_currentMission:getFruitPixelsToSqm()))
		print("============================================================")
		for name,desc in pairs(FruitUtil.fruitTypes) do		
			if desc.literPerSqm ~= nil then
				desc.origLiterPerSqm = desc.literPerSqm
				desc.literPerSqm     = realisticYield.realisticYieldFactor * desc.origLiterPerSqm
				
				local id = getChild(g_currentMission.terrainRootNode, name)
				local sz = 0
				if id > 0 then
					sz = getDensityMapSize(id)
				end

				print(name..": "..tostring(sz).." / "..tostring(desc.origLiterPerSqm).." => "..tostring(desc.literPerSqm).." "..tostring(desc.massPerLiter * desc.literPerSqm * 1E4))
			end
		end
		print("============================================================")
		
		if realisticYield.checkit then
			realisticYield.counter         = 0
			realisticYield.oldCutFruitArea = Utils.cutFruitArea
			Utils.cutFruitArea     = realisticYield.cutFruitArea
		end
	end
end;

function realisticYield.cutFruitArea( ... )
	if      SoilManagement                                ~= nil
			and SoilManagement.fmcModifyFSUtils               ~= nil
			and SoilManagement.fmcModifyFSUtils.origFuncs     ~= nil 
			and type(SoilManagement.fmcModifyFSUtils.origFuncs.cutFruitArea) == "function" then
		local result, flag
		
		realisticYield.counter = realisticYield.counter + 1
		if realisticYield.counter <= 10 then
			result = { realisticYield.oldCutFruitArea( ... ) }
			flag   = true
		else
			result = { SoilManagement.fmcModifyFSUtils.origFuncs.cutFruitArea( ... ) }
			flag   = false
		end
		
		if realisticYield.counter >= 20 then
			realisticYield.counter = 0
		end
			
		print(tostring(flag).." "..tostring(result[1]).." "..tostring(result[2]))
		return unpack(result)
	end
	
	return realisticYield.oldCutFruitArea( ... )
	
end

function realisticYield:draw()
  
end;

addModEventListener(realisticYield);