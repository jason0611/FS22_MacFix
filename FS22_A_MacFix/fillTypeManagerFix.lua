
fillTypeManagerFix = {}

function fillTypeManagerFix.loadFillTypes(self, superfunc, xmlFile, baseDirectory, isBaseType, customEnv)
if type(xmlFile) ~= "table" then
        xmlFile = XMLFile.wrap(xmlFile, FillTypeManager.xmlSchema)
    end

    local oldNumFillTypes = #self.fillTypes
    local rootName = xmlFile:getRootName()

    if isBaseType then
        self:addFillType("UNKNOWN", "Unknown", false, 0, 0, 0, "", baseDirectory, nil, nil, nil, nil, {}, nil, nil, nil, nil, nil, nil, nil, nil, isBaseType)
    end

    xmlFile:iterate(rootName .. ".fillTypes.fillType", function(_, key)
        local name = xmlFile:getValue(key.."#name")
        local title = xmlFile:getValue(key.."#title")
        local achievementName = xmlFile:getValue(key.."#achievementName")
        local showOnPriceTable = xmlFile:getValue(key.."#showOnPriceTable")
        local fillPlaneColors =  xmlFile:getValue(key.."#fillPlaneColors", "1.0 1.0 1.0", true)
        local unitShort =  xmlFile:getValue(key.."#unitShort", "")

        local kgPerLiter = xmlFile:getValue(key..".physics#massPerLiter")
        local massPerLiter = kgPerLiter and kgPerLiter / 1000
        local maxPhysicalSurfaceAngle = xmlFile:getValue(key..".physics#maxPhysicalSurfaceAngle")

        local hudFilename = xmlFile:getValue(key..".image#hud")

        local palletFilename = xmlFile:getValue(key..".pallet#filename")

        local pricePerLiter = xmlFile:getValue(key..".economy#pricePerLiter")
        local economicCurve = {}

        xmlFile:iterate(key .. ".economy.factors.factor", function(_, factorKey)
            local period = xmlFile:getValue(factorKey .. "#period")
            local factor = xmlFile:getValue(factorKey .. "#value")

            if period ~= nil and factor ~= nil then
                economicCurve[period] = factor
            end
        end)

        local diffuseMapFilename = xmlFile:getValue(key .. ".textures#diffuse")
        local normalMapFilename = xmlFile:getValue(key .. ".textures#normal")
        local specularMapFilename = xmlFile:getValue(key .. ".textures#specular")
        local distanceFilename = xmlFile:getValue(key .. ".textures#distance")

        local prioritizedEffectType = xmlFile:getValue(key..".effects#prioritizedEffectType") or "ShaderPlaneEffect"
        local fillSmokeColor = xmlFile:getValue(key..".effects#fillSmokeColor", nil, true)
        local fruitSmokeColor = xmlFile:getValue(key..".effects#fruitSmokeColor", nil, true)

        self:addFillType(name, title, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle, hudFilename, baseDirectory, customEnv, fillPlaneColors, unitShort, palletFilename, economicCurve, diffuseMapFilename, normalMapFilename, specularMapFilename, distanceFilename, prioritizedEffectType, fillSmokeColor, fruitSmokeColor, achievementName, isBaseType or false)
    end)

    xmlFile:iterate(rootName .. ".fillTypeCategories.fillTypeCategory", function(_, key)
        local name = xmlFile:getValue(key.."#name")
        local fillTypesStr = xmlFile:getValue(key) or ""
        local fillTypeCategoryIndex = self:addFillTypeCategory(name, isBaseType)
        if fillTypeCategoryIndex ~= nil then
            local fillTypeNames = fillTypesStr:split(" ")
            for _, fillTypeName in ipairs(fillTypeNames) do
                local fillType = self:getFillTypeByName(fillTypeName)
                if fillType ~= nil then
                    if not self:addFillTypeToCategory(fillType.index, fillTypeCategoryIndex) then
                        Logging.warning("Could not add fillType '"..tostring(fillTypeName).."' to fillTypeCategory '"..tostring(name).."'!")
                    end
                else
                    Logging.warning("Unknown FillType '"..tostring(fillTypeName).."' in fillTypeCategory '"..tostring(name).."'!")
                end
            end
        end
    end)

    xmlFile:iterate(rootName .. ".fillTypeConverters.fillTypeConverter", function(_, key)
        local name = xmlFile:getValue(key.."#name")
        local converter = self:addFillTypeConverter(name, isBaseType)
        if converter ~= nil then
            xmlFile:iterate(key .. ".converter", function(_, converterKey)
                local from = xmlFile:getValue(converterKey.."#from")
                local to = xmlFile:getValue(converterKey.."#to")
                local factor = xmlFile:getValue(converterKey.."#factor")

                local sourceFillType = g_fillTypeManager:getFillTypeByName(from)
                local targetFillType = g_fillTypeManager:getFillTypeByName(to)

                if sourceFillType ~= nil and targetFillType ~= nil and factor ~= nil then
                    self:addFillTypeConversion(converter, sourceFillType.index, targetFillType.index, factor)
                end
            end)
        end
    end)

    xmlFile:iterate(rootName .. ".fillTypeSounds.fillTypeSound", function(_, key)
        local sample = g_soundManager:loadSampleFromXML(xmlFile, key, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, nil)
        if sample ~= nil then
            local entry = {}
            entry.sample = sample

            entry.fillTypes = {}
            local fillTypesStr = xmlFile:getValue(key.."#fillTypes") or ""
            if fillTypesStr ~= nil then
                local fillTypeNames = fillTypesStr:split(" ")

                for _, fillTypeName in ipairs(fillTypeNames) do
                    local fillType = self:getFillTypeIndexByName(fillTypeName)
                    if fillType ~= nil then
                        table.insert(entry.fillTypes, fillType)
                        self.fillTypeToSample[fillType] = sample
                    else
                        Logging.warning("Unable to load fill type '%s' for fillTypeSound '%s'", fillTypeName, key)
                    end
                end
            end

            if xmlFile:getValue(key.."#isDefault") then
                for fillType, _ in ipairs(self.fillTypes) do
                    if self.fillTypeToSample[fillType] == nil then
                        self.fillTypeToSample[fillType] = sample
                    end
                end
            end

            table.insert(self.fillTypeSamples, entry)
        end
    end)

    --if #self.fillTypes ~= oldNumFillTypes then
    --    self:constructFillTypeTextureArrays()
    --end

    return true
end
FillTypeManager.loadFillTypes = Utils.overwrittenFunction(FillTypeManager.loadFillTypes, fillTypeManagerFix.loadFillTypes)
