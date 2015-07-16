--***************************************************************
--
-- automatically change height of cutter attached to combine
-- 
-- version 0.1 by mogli (biedens)
-- 2014/08/06
--
--***************************************************************

source(Utils.getFilename("mogliBase20.lua", g_currentModDirectory))
mogliBase20.newClass( "CutterAttacherHeight" )

function CutterAttacherHeight.prerequisitesPresent(specializations) 
	return true
end 

function CutterAttacherHeight:load(xmlFile)

	CutterAttacherHeight.registerState( self, "cutterAttacherHeightControlToggle", true, CutterAttacherHeight.onToggle )
	CutterAttacherHeight.registerState( self, "cutterAttacherHeightControlDelta", 0, nil, "float32" )
	CutterAttacherHeight.registerState( self, "cutterAttacherHeightIsLowered",  false )
	
	self.cutterAttacherHeightBaseInitial   = true
	self.cutterAttacherHeightControlIndex  = nil
	self.cutterAttacherHeightBaseHeight    = nil
	self.cutterAttacherHeightMinHeight     = -0.20
	self.cutterAttacherHeightMaxHeight     =  0.50

end

function CutterAttacherHeight:showKeys()
	if      self.isClient and self:getIsActive() 
			and self.cutterAttacherHeightIsLowered
			and ( self.aiLeftMarker ~= nil or self.aiRightMarker ~= nil )
			and self.attacherVehicle                     ~= nil 
			and self.attacherVehicle.isEntered
			and self.attacherVehicle.attacherJoints      ~= nil
			and self.attacherVehicleJointDescIndex       ~= nil then
		return true 
	end
	return false
end

function CutterAttacherHeight:update(dt)

	--if self:getIsActiveForInput() then
	if CutterAttacherHeight.showKeys( self ) then
		if InputBinding.hasEvent(InputBinding.ZZZ_CAH_TOGGLE) then
			CutterAttacherHeight.mbSetState( self,"cutterAttacherHeightControlToggle", not self.cutterAttacherHeightControlToggle)
		end
		if      self.cutterAttacherHeightControlToggle
				and self.cutterAttacherHeightBaseHeight ~= nil then
			if     InputBinding.isPressed(InputBinding.ZZZ_CAH_UP) then
				CutterAttacherHeight.mbSetState( self,"cutterAttacherHeightControlDelta", math.min(self.cutterAttacherHeightControlDelta+0.005, self.cutterAttacherHeightMaxHeight))
			elseif InputBinding.isPressed(InputBinding.ZZZ_CAH_DOWN) then
				CutterAttacherHeight.mbSetState( self,"cutterAttacherHeightControlDelta", math.max(self.cutterAttacherHeightControlDelta-0.005, self.cutterAttacherHeightMinHeight))
			end 
		end 
	end 
	
	if      self.cutterAttacherHeightIsLowered
			and self.cutterAttacherHeightControlToggle
			and self.attacherVehicle                     ~= nil 
			and self.attacherVehicle.attacherJoints      ~= nil
			and self.attacherVehicleJointDescIndex       ~= nil 
			and self.attacherJoint                       ~= nil
			and self.attacherJoint.lowerDistanceToGround ~= nil
			and ( self.attacherVehicle.isAIThreshing or self.attacherVehicle.isEntered or self.attacherVehicle.isHired or self.isAITractorActivated )
			and ( self.aiLeftMarker ~= nil or self.aiRightMarker ~= nil ) then 

		if self.cutterAttacherHeightControlIndex == nil then 
			if     self.aiLeftMarker  ~= nil and self.aiRightMarker ~= nil then 
				local p = getParent( self.aiLeftMarker )
				local x1, y1, z1 = getTranslation( self.aiLeftMarker )
				local x2, y2, z2 = CutterAttacherHeight.getRelativeTranslation( p, self.aiRightMarker )
				local n = createTransformGroup( "cutterAttacherHeightControlIndex" )
				link( p, n )
				setTranslation( n, 0.5*(x1+x2), 0.5*(y1+y2), 0.5*(z1+z2) )
				self.cutterAttacherHeightControlIndex = { self.aiLeftMarker, n, self.aiRightMarker }
			elseif self.aiLeftMarker  ~= nil then
				self.cutterAttacherHeightControlIndex = { self.aiLeftMarker }
			elseif self.aiRightMarker ~= nil then 
				self.cutterAttacherHeightControlIndex = { self.aiRightMarker }
			end
		end
		
		local jointDescIndex = self.attacherVehicleJointDescIndex
		local jointDesc      = self.attacherVehicle.attacherJoints[jointDescIndex]
		local eps            = 1E-3
		local delta          = 0.8 * dt / jointDesc.moveTime
		local factor         = 3.0 * dt / jointDesc.moveTime
			
		if      ( math.abs( self.attacherVehicle.attacherJoints[self.attacherVehicleJointDescIndex].moveAlpha 
							  			- self.attacherVehicle.attacherJoints[self.attacherVehicleJointDescIndex].lowerAlpha ) <= eps
					 or ( self.cutterAttacherHeightBaseHeight ~= nil 
						and	math.abs( self.attacherVehicle.attacherJoints[self.attacherVehicleJointDescIndex].moveAlpha 
												- self.attacherVehicle.attacherJoints[self.attacherVehicleJointDescIndex].lowerAlpha ) <= delta ) )
				and self.cutterAttacherHeightControlIndex    ~= nil
				and self.attacherVehicle.attacherJoints[self.attacherVehicleJointDescIndex].lowerAlpha > eps
				then
				
			local t, n   = 0, 1
			local tMin   = nil
			
			for _,i in pairs( self.cutterAttacherHeightControlIndex ) do
				local x,y,z = getWorldTranslation(i);
				local ti = y - getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
				n = n + 1
				t = t + ti
				if     tMin == nil then 
					tMin = ti 
				elseif tMin > ti then
					tMin = ti 
				end
			end
			
			if n > 0 then
				
				if self.cutterAttacherHeightBaseHeight == nil then
					self.cutterAttacherHeightBaseHeight    = t / n
					self.cutterAttacherHeightLowerAlpha    = jointDesc.lowerAlpha
				end 
				
				local diff = self.cutterAttacherHeightBaseHeight + self.cutterAttacherHeightControlDelta - t / n --tMin
				if math.abs( diff ) > eps then
					jointDesc.lowerAlpha = Utils.clamp( jointDesc.lowerAlpha - Utils.clamp(diff * factor,-delta,delta), 0, 1)
					CutterAttacherHeight.updateJointDesc( self, self.attacherVehicle, jointDesc, dt )
				end
			end
		end
	end
end

function CutterAttacherHeight:updateJointDesc( vehicle, jointDesc, dt )
	jointDesc.moveAlpha  = Utils.getMovedLimitedValue(jointDesc.moveAlpha, jointDesc.lowerAlpha, jointDesc.upperAlpha, jointDesc.moveTime, dt, not jointDesc.moveDown)
	if jointDesc.rotationNode ~= nil then
		setRotation(jointDesc.rotationNode, Utils.vector3ArrayLerp(jointDesc.minRot, jointDesc.maxRot, jointDesc.moveAlpha))
	end
	if jointDesc.rotationNode2 ~= nil then
		setRotation(jointDesc.rotationNode2, Utils.vector3ArrayLerp(jointDesc.minRot2, jointDesc.maxRot2, jointDesc.moveAlpha))
	end
	vehicle:updateAttacherJointRotation(jointDesc, self)
	jointDesc.jointFrameInvalid = false
	if self.isServer then
		setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
	end
end

function CutterAttacherHeight:draw()
	if CutterAttacherHeight.showKeys( self ) then
		if self.cutterAttacherHeightControlToggle then
			g_currentMission:addHelpButtonText( CutterAttacherHeight.getText("ZZZ_CAH_ON"),  InputBinding.ZZZ_CAH_TOGGLE);
		else                                  
			g_currentMission:addHelpButtonText( CutterAttacherHeight.getText("ZZZ_CAH_OFF"), InputBinding.ZZZ_CAH_TOGGLE);
		end
		if      self.cutterAttacherHeightControlToggle
				and self.cutterAttacherHeightBaseHeight ~= nil then
		  if self.cutterAttacherHeightControlDelta > self.cutterAttacherHeightMinHeight then
				g_currentMission:addHelpButtonText( string.format( CutterAttacherHeight.getText("ZZZ_CAH_DOWN"), self.cutterAttacherHeightControlDelta ), InputBinding.ZZZ_CAH_DOWN);
			end
			if self.cutterAttacherHeightControlDelta < self.cutterAttacherHeightMaxHeight then
				g_currentMission:addHelpButtonText( string.format( CutterAttacherHeight.getText("ZZZ_CAH_UP"),   self.cutterAttacherHeightControlDelta ), InputBinding.ZZZ_CAH_UP);
			end
		end
	end;
end

function CutterAttacherHeight:onSetLowered(lowered)
	if      self.attacherVehicle ~= nil then
		CutterAttacherHeight.mbSetState( self,"cutterAttacherHeightIsLowered", lowered, false)
	end
end
function CutterAttacherHeight:onAttached(attacherVehicle, jointDescIndex)
	self.cutterAttacherHeightBaseHeight  = nil
	self.attacherVehicleJointDescIndex   = jointDescIndex
	self.onAttachedTime                  = g_currentMission.time
end
function CutterAttacherHeight:onDetach(attacherVehicle, jointDescIndex)
	self.cutterAttacherHeightBaseHeight  = nil
	self.attacherVehicleJointDescIndex   = nil
	self.onAttachedTime                  = nil 
end
function CutterAttacherHeight:onToggle( old, new, noEventSend )		
	self.cutterAttacherHeightControlToggle = new
	if      self.cutterAttacherHeightBaseHeight ~= nil
			and self.attacherVehicleJointDescIndex  ~= nil then
		local jointDescIndex = self.attacherVehicleJointDescIndex
		self.cutterAttacherHeightBaseHeight  = nil
		self.attacherVehicle.attacherJoints[jointDescIndex].lowerAlpha = self.cutterAttacherHeightLowerAlpha
	--CutterAttacherHeight.updateJointDesc( self, self.attacherVehicle, self.attacherVehicle.attacherJoints[jointDescIndex], 100 )
	end
end

------------------------------------------------------------------------
-- getSaveAttributesAndNodes
------------------------------------------------------------------------
function CutterAttacherHeight:getSaveAttributesAndNodes(nodeIdent)

	local attributes = ""

	attributes = attributes.." cutterAttacherHeightToggle=\"" .. tostring(self.cutterAttacherHeightControlToggle) .. "\""
	attributes = attributes.." cutterAttacherHeightDelta=\"" .. tostring(self.cutterAttacherHeightControlDelta) .. "\""
		
	return attributes
end;


------------------------------------------------------------------------
-- loadFromAttributesAndNodes
------------------------------------------------------------------------
function CutterAttacherHeight:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
		
	local b = getXMLBool(xmlFile, key .. "#cutterAttacherHeightToggle")
	if b ~= nil then
		self.cutterAttacherHeightControlToggle = b
	end
	local f = getXMLFloat(xmlFile, key .. "#cutterAttacherHeightDelta")
	if f ~= nil then
		self.cutterAttacherHeightControlDelta = f
	end
		
	return BaseMission.VEHICLE_LOAD_OK;
end


------------------------------------------------------------------------
-- getRelativeTranslation
------------------------------------------------------------------------
function CutterAttacherHeight.getRelativeTranslation(root,node)
	if root == nil or node == nil then
		return 0,0,0
	end
	local x,y,z;
	if getParent(node)==root then
		x,y,z = getTranslation(node);
	else
		x,y,z = worldToLocal(root,getWorldTranslation(node));
	end;
	return x,y,z;
end

