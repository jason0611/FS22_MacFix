fillTypeManagerFix = {}

function fillTypeManagerFix.overwrite_constructFillTypeTextureArrays(self, superfunc, force)
	if force then
		superfunc(self)
		print("FS22_z_MacFix: constructFillTypeTextureArrays executed for all fillTypes")
	else
		print("FS22_z_MacFix: constructFillTypeTextureArrays skipped")
	end
end
FillTypeManager.constructFillTypeTextureArrays = Utils.overwrittenFunction(FillTypeManager.constructFillTypeTextureArrays, fillTypeManagerFix.overwrite_constructFillTypeTextureArrays)

function fillTypeManagerFix.append_loadMapData(self, xmlFile, missionInfo, baseDirectory)
	self:constructFillTypeTextureArrays(true)
end
FillTypeManager.loadMapData = Utils.appendedFunction(FillTypeManager.loadMapData, fillTypeManagerFix.append_loadMapData)
