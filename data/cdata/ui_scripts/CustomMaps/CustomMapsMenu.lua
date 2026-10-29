local mapListPath = "frontEnd.CustomMaps"

-- Built-in test entries. They are aliases: selecting one starts the stock map named by
-- `alias`. Once usermaps/<ref>/<ref>.ff exists, the real map replaces the alias entry.
local aliasMaps = {
    {
        ref = "cp_testmap",
        name = "TEST MAP",
        alias = "cp_town",
        desc = "Test entry, not a real custom map. It starts the stock cp_town map so the menu can be tested. Install a map in usermaps/cp_testmap/ (cp_testmap.ff and cp_testmap.arena) to replace it."
    }
}

local function isAliensMap(ref)
    return ref:sub(1, 3) == "cp_"
end

local function isInstalled(ref)
    return io.fileexists("usermaps/" .. ref .. "/" .. ref .. ".ff")
end

local function prettifyName(ref)
    local name = ref:gsub("^%a%a_", ""):gsub("_", " ")
    return ToUpperCase(name)
end

local function readDescription(ref)
    local path = "usermaps/" .. ref .. "/desc.txt"
    if io.fileexists(path) then
        return io.readfile(path)
    end
    return nil
end

local function getCustomMaps()
    local aliens = Engine.IsAliensMode()
    local maps = {}
    local seen = {}

    if io.directoryexists("usermaps") then
        for _, folder in ipairs(io.listfiles("usermaps/")) do
            local ref = folder:match("([^/\\]+)$")
            if ref and not seen[ref] and isAliensMap(ref) == aliens and isInstalled(ref) then
                seen[ref] = true
                maps[#maps + 1] = {
                    ref = ref,
                    name = prettifyName(ref),
                    desc = readDescription(ref) or "Custom map installed in usermaps/" .. ref .. "/",
                    installed = true
                }
            end
        end
    end

    for _, aliasMap in ipairs(aliasMaps) do
        if not seen[aliasMap.ref] and isAliensMap(aliasMap.ref) == aliens then
            maps[#maps + 1] = {
                ref = aliasMap.ref,
                name = aliasMap.name,
                desc = aliasMap.desc,
                alias = aliasMap.alias,
                installed = false
            }
        end
    end

    return maps
end

local function canStartMap()
    return not (Lobby.IsInPrivateParty() and not Lobby.IsPrivatePartyHost())
end

local function setStatus(menuElement, text)
    menuElement.MapStatus:setText(text)
end

local function setMapInfo(menuElement, map)
    menuElement.MapInfoTitle:setText(map.name)
    menuElement.MapInfoText:setText(map.desc)
    if map.alias then
        setStatus(menuElement, "^3Test entry^7: starts " .. map.alias)
    else
        setStatus(menuElement, "")
    end
end

local function startMap(menuElement, map)
    local target = map.alias or map.ref

    if map.alias and not io.zoneexists(target) then
        setStatus(menuElement, "^1" .. target .. " is not installed")
        return
    end

    if not canStartMap() then
        setStatus(menuElement, "^1Only the party host can start a map")
        return
    end

    Engine.Exec("map " .. target)
end

local function leaveMenu(menuElement, controllerIndex)
    LUI.FlowManager.RequestLeaveMenu(menuElement)
end

local function populateMapList(menuElement, controllerIndex)
    local maps = getCustomMaps()

    local dataSource = LUI.DataSourceFromList.new(#maps)
    dataSource.MakeDataSourceAtIndex = function(dataSource, index, controllerIndex)
        local map = maps[index + 1]
        local buttonLabel = LUI.DataSourceInGlobalModel.new(mapListPath .. ".maps." .. index, map.name)
        -- the model outlives the menu, so overwrite any label left over from a previous list
        buttonLabel:SetValue(controllerIndex, map.name)
        return {
            buttonLabel = buttonLabel,
            buttonOnClickFunction = function(buttonElement, controllerIndex)
                startMap(menuElement, map)
            end,
            buttonOnHoverFunction = function(buttonElement, controllerIndex)
                setMapInfo(menuElement, map)
            end
        }
    end

    assert(menuElement.MapSelectionList)
    menuElement.MapSelectionList:SetGridDataSource(dataSource, controllerIndex)

    if #maps > 0 then
        setMapInfo(menuElement, maps[1])
    else
        setStatus(menuElement, "No custom maps found in usermaps/")
    end
end

local function postLoadFunction(menuElement, controllerIndex, controller)
    assert(menuElement.bindButton)
    menuElement.bindButton:addEventHandler("button_secondary", leaveMenu)

    populateMapList(menuElement, controllerIndex)
    menuElement:addEventHandler("gain_focus", function(focusElement, controllerIndex)
        local mapSelectionList = focusElement.MapSelectionList

        if mapSelectionList:getNumChildren() == 0 then
            return
        end

        local contentOffset = mapSelectionList:GetContentOffset(LUI.DIRECTION.vertical)
        mapSelectionList:SetFocusedPosition({
            x = 0,
            y = contentOffset
        }, true)
        local focusedElement = mapSelectionList:GetElementAtPosition(0, contentOffset)
        if focusedElement then
            focusedElement:processEvent({
                name = "gain_focus",
                controllerIndex = controllerIndex
            })
        end
    end)
end

local function CustomMapsMenu(arg0, controller)
    local menuElement = LUI.UIElement.new()
    menuElement.id = "CustomMapsMenu"

    local controllerIndex = controller and controller.controllerIndex
    if not controllerIndex and not Engine.InFrontend() then
        controllerIndex = menuElement:getRootController()
    end
    assert(controllerIndex)

    menuElement:playSound("menu_open")

    if Engine.IsSingleplayer() then
        local backgroundImage = LUI.UIImage.new()
        backgroundImage.id = "Background"
        backgroundImage:setImage(RegisterMaterial("sp_frontend_bink_background"), 0)
        menuElement:addElement(backgroundImage)
        menuElement.Background = backgroundImage

        local binkImage = LUI.UIImage.new()
        binkImage.id = "Bink"
        binkImage:setImage(RegisterMaterial("cinematic"), 0)
        menuElement:addElement(binkImage)
        menuElement.Bink = binkImage
    end

    local buttonHelperBar = MenuBuilder.BuildRegisteredType("ButtonHelperBar", {
        controllerIndex = controllerIndex
    })
    buttonHelperBar.id = "ButtonHelperBar"
    buttonHelperBar:SetAnchorsAndPosition(0, 0, 1, 0, 0, 0, _1080p * -85, 0)
    menuElement:addElement(buttonHelperBar)
    menuElement.ButtonHelperBar = buttonHelperBar

    local menuTitle = nil
    if Engine.IsAliensMode() then
        menuTitle = MenuBuilder.BuildRegisteredType("CPMenuTitle", {
            controllerIndex = controllerIndex
        })
    else
        menuTitle = MenuBuilder.BuildRegisteredType("MenuTitle", {
            controllerIndex = controllerIndex
        })
        menuTitle.MenuBreadcrumbs:setText(ToUpperCase("IW7D"), 0)
        menuTitle.Icon:SetTop(_1080p * -28.5, 0)
        menuTitle.Icon:SetBottom(_1080p * 61.5, 0)
    end
    menuTitle.id = "MenuTitle"
    menuTitle.MenuTitle:setText(ToUpperCase("Custom Maps"), 0)
    menuTitle:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 96, _1080p * 1056, _1080p * 54, _1080p * 134)
    menuElement:addElement(menuTitle)
    menuElement.MenuTitle = menuTitle

    local mapInfoTitle = LUI.UIStyledText.new()
    mapInfoTitle.id = "MapInfoTitle"
    mapInfoTitle:setText("", 0)
    mapInfoTitle:SetFontSize(30 * _1080p)
    mapInfoTitle:SetFont(FONTS.GetFont(FONTS.MainMedium.File))
    mapInfoTitle:SetAlignment(LUI.Alignment.Left)
    mapInfoTitle:SetStartupDelay(2000)
    mapInfoTitle:SetLineHoldTime(400)
    mapInfoTitle:SetAnimMoveTime(300)
    mapInfoTitle:SetEndDelay(1500)
    mapInfoTitle:SetCrossfadeTime(750)
    mapInfoTitle:SetAutoScrollStyle(LUI.UIStyledText.AutoScrollStyle.ScrollH)
    mapInfoTitle:SetMaxVisibleLines(1)
    mapInfoTitle:SetDecodeLetterLength(15)
    mapInfoTitle:SetDecodeMaxRandChars(6)
    mapInfoTitle:SetDecodeUpdatesPerLetter(4)
    mapInfoTitle:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 1254, _1080p * 1824, _1080p * 216, _1080p * 246)
    menuElement:addElement(mapInfoTitle)
    menuElement.MapInfoTitle = mapInfoTitle

    local mapInfoText = LUI.UIStyledText.new()
    mapInfoText.id = "MapInfoText"
    mapInfoText:setText("", 0)
    mapInfoText:SetFontSize(20 * _1080p)
    mapInfoText:SetFont(FONTS.GetFont(FONTS.MainCondensed.File))
    mapInfoText:SetAlignment(LUI.Alignment.Left)
    mapInfoText:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 1254, _1080p * 1824, _1080p * 248, _1080p * 420)
    menuElement:addElement(mapInfoText)
    menuElement.MapInfoText = mapInfoText

    local mapSelectionList = LUI.UIDataSourceGrid.new(nil, {
        maxVisibleColumns = 1,
        maxVisibleRows = 17,
        controllerIndex = controllerIndex,
        buildChild = function()
            return MenuBuilder.BuildRegisteredType("ModSelectButton", {
                controllerIndex = controllerIndex
            })
        end,
        wrapX = true,
        wrapY = true,
        spacingX = _1080p * 10,
        spacingY = _1080p * 10,
        columnWidth = _1080p * 500,
        rowHeight = _1080p * 30,
        scrollingThresholdX = 1,
        scrollingThresholdY = 1,
        adjustSizeToContent = false,
        horizontalAlignment = LUI.Alignment.Left,
        verticalAlignment = LUI.Alignment.Top,
        springCoefficient = 600,
        maxVelocity = 5000
    })
    mapSelectionList.id = "MapSelectionList"
    mapSelectionList:setUseStencil(false)
    mapSelectionList:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 130, _1080p * 630, _1080p * 216, _1080p * 886)
    menuElement:addElement(mapSelectionList)
    menuElement.MapSelectionList = mapSelectionList

    local arrowUp = MenuBuilder.BuildRegisteredType("ArrowUp", {
        controllerIndex = controllerIndex
    })
    arrowUp.id = "ArrowUp"
    arrowUp:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 452.5, _1080p * 472.5, _1080p * 887, _1080p * 927)
    menuElement:addElement(arrowUp)
    menuElement.ArrowUp = arrowUp

    local arrowDown = MenuBuilder.BuildRegisteredType("ArrowDown", {
        controllerIndex = controllerIndex
    })
    arrowDown.id = "ArrowDown"
    arrowDown:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 287.5, _1080p * 307.5, _1080p * 886, _1080p * 926)
    menuElement:addElement(arrowDown)
    menuElement.ArrowDown = arrowDown

    local listCount = LUI.UIText.new()
    listCount.id = "ListCount"
    listCount:setText("1/1", 0)
    listCount:SetFontSize(24 * _1080p)
    listCount:SetFont(FONTS.GetFont(FONTS.MainMedium.File))
    listCount:SetAlignment(LUI.Alignment.Center)
    listCount:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 307.5, _1080p * 452.5, _1080p * 894, _1080p * 918)
    menuElement:addElement(listCount)
    menuElement.ListCount = listCount

    local mapStatus = LUI.UIText.new()
    mapStatus.id = "MapStatus"
    mapStatus:setText("", 0)
    mapStatus:SetFontSize(20 * _1080p)
    mapStatus:SetFont(FONTS.GetFont(FONTS.MainBold.File))
    mapStatus:SetAlignment(LUI.Alignment.Left)
    mapStatus:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 130, _1080p * 630, _1080p * 942, _1080p * 966)
    menuElement:addElement(mapStatus)
    menuElement.MapStatus = mapStatus

    mapSelectionList:AddArrow(arrowUp)
    mapSelectionList:AddArrow(arrowDown)
    mapSelectionList:AddItemNumbers(listCount)

    menuElement:addEventHandler("menu_create", function(element, event)
        element:AddButtonHelperText({
            helper_text = Engine.Localize("MENU_BACK"),
            button_ref = "button_secondary",
            side = "left",
            clickable = true
        })
    end)

    local bindButton = LUI.UIBindButton.new()
    bindButton.id = "selfBindButton"
    menuElement:addElement(bindButton)
    menuElement.bindButton = bindButton

    postLoadFunction(menuElement, controllerIndex, controller)

    if Engine.InFrontend() then
        local blur = LUI.UIElement.new({
            worldBlur = 5
        })
        blur:setupWorldBlur()
        blur.id = "blur"
        menuElement:addElement(blur)
    end

    return menuElement
end

MenuBuilder.registerType("CustomMapsMenu", CustomMapsMenu)
