-- Adds a clickable CUSTOM MAPS entry to the button helper bar of the zombies lobby screens.
-- The zombies lobby menus ship inside the game, so they are wrapped instead of replaced and
-- everything here is protected: a failure is logged and never stops the lobby from opening.

local lobbyMenus = {
    CPPrivateMatchMenu = true
}

local function log(text)
    print("[CustomMaps] " .. text)
end

local function logChildren(element, depth, maxDepth)
    local child = element:getFirstChild()
    while child do
        log(string.rep("  ", depth) .. tostring(child.id))
        if depth < maxDepth then
            logChildren(child, depth + 1, maxDepth)
        end
        child = child:getNextSibling()
    end
end

local function addCustomMapsEntry(name, menu, controller)
    local controllerIndex = controller and controller.controllerIndex or menu:getRootController()

    log("hooked " .. name)
    local ok, err = pcall(logChildren, menu, 1, 2)
    if not ok then
        log("could not list children: " .. tostring(err))
    end

    local function openCustomMaps(element, event)
        LUI.FlowManager.RequestAddMenu("CustomMapsMenu", true, event and event.controller or controllerIndex, false)
    end

    menu:addEventHandler("menu_create", function(element, event)
        local added, addErr = pcall(function()
            element:AddButtonHelperText({
                helper_text = "CUSTOM MAPS",
                button_ref = "button_alt2",
                side = "left",
                clickable = true
            })
        end)
        if not added then
            log("could not add helper entry: " .. tostring(addErr))
        end
    end)

    local bindButton = LUI.UIBindButton.new()
    bindButton.id = "CustomMapsBindButton"
    bindButton:addEventHandler("button_alt2", openCustomMaps)
    menu:addElement(bindButton)
end

local function wrap(name, build)
    return function(menu, controller)
        local self = build(menu, controller)
        local ok, err = pcall(addCustomMapsEntry, name, self, controller)
        if not ok then
            log("failed to hook " .. name .. ": " .. tostring(err))
        end
        return self
    end
end

local types = MenuBuilder.m_types
for name in pairs(lobbyMenus) do
    if types[name] then
        types[name] = wrap(name, types[name])
    end
end

-- menus registered after this script has loaded
local registerType = MenuBuilder.registerType
MenuBuilder.registerType = function(name, build)
    if lobbyMenus[name] then
        build = wrap(name, build)
    end
    return registerType(name, build)
end
