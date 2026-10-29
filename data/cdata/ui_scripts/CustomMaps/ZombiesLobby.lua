-- Adds a clickable CUSTOM MAPS entry to the button helper bar of the zombies lobby.
-- The lobby menu (CPPrivateMatchMenu) ships inside the game and is not in the type table when
-- the scripts load, so its builder is wrapped at the moment the menu is requested. Everything
-- here is protected: a failure is logged and never stops the lobby from opening.

local lobbyMenus = {
    CPPrivateMatchMenu = true
}

local wrappers = {}

local function log(text)
    print("[CustomMaps] " .. text)
end

local function addCustomMapsEntry(menu, controller)
    local controllerIndex = controller and controller.controllerIndex or menu:getRootController()

    local function openCustomMaps(element, event)
        LUI.FlowManager.RequestAddMenu("CustomMapsMenu", true, event and event.controller or controllerIndex, false)
    end

    menu:addEventHandler("menu_create", function(element, event)
        local added, err = pcall(function()
            element:AddButtonHelperText({
                helper_text = "CUSTOM MAPS",
                button_ref = "button_alt2",
                side = "left",
                clickable = true
            })
        end)
        if not added then
            log("could not add helper entry: " .. tostring(err))
        end
    end)

    local bindButton = LUI.UIBindButton.new()
    bindButton.id = "CustomMapsBindButton"
    bindButton:addEventHandler("button_alt2", openCustomMaps)
    menu:addElement(bindButton)
end

local function wrap(name, build)
    if wrappers[build] then
        return build
    end

    local wrapped = function(menu, controller)
        local self = build(menu, controller)
        local ok, err = pcall(addCustomMapsEntry, self, controller)
        if not ok then
            log("failed to hook " .. name .. ": " .. tostring(err))
        end
        return self
    end
    wrappers[wrapped] = true
    return wrapped
end

local requestAddMenu = LUI.FlowManager.RequestAddMenu
LUI.FlowManager.RequestAddMenu = function(name, ...)
    if type(name) == "string" and lobbyMenus[name] then
        local build = MenuBuilder.m_types[name]
        if build and not wrappers[build] then
            MenuBuilder.m_types[name] = wrap(name, build)
        end
    end
    return requestAddMenu(name, ...)
end
