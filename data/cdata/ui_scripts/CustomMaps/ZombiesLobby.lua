-- Adds a clickable CUSTOM MAPS entry to the button helper bar of the zombies lobby screens.
-- The zombies lobby menus ship inside the game, so they are wrapped instead of replaced and
-- everything here is protected: a failure is logged and never stops the lobby from opening.

local lobbyMenus = {
    CPPrivateMatchMenu = true
}

local wrappers = {}

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
    if wrappers[build] then
        return build
    end

    local wrapped = function(menu, controller)
        local self = build(menu, controller)
        local ok, err = pcall(addCustomMapsEntry, name, self, controller)
        if not ok then
            log("failed to hook " .. name .. ": " .. tostring(err))
        end
        return self
    end
    wrappers[wrapped] = true
    return wrapped
end

local function wrapRegistered()
    for name in pairs(lobbyMenus) do
        local build = MenuBuilder.m_types[name]
        if build and not wrappers[build] then
            MenuBuilder.m_types[name] = wrap(name, build)
            log("wrapped registered " .. name)
        end
    end
end

-- diagnostics: which lobby-like menu types exist, and which menus get opened
local function logLobbyTypes()
    local names = {}
    for name in pairs(MenuBuilder.m_types) do
        if type(name) == "string" and (name:find("Lobby") or name:find("Private") or name:find("Party") or name:find("Match") or name:find("Setup")) then
            names[#names + 1] = name
        end
    end
    table.sort(names)
    log("lobby-like menu types (" .. #names .. "): " .. table.concat(names, ", "))
end

local function safe(label, fn)
    local ok, err = pcall(fn)
    if not ok then
        log(label .. " failed: " .. tostring(err))
    end
end

-- Wrap the lobby builder right when the menu is requested, so it does not matter how or
-- when the stock menu was registered.
local function hookOpenedMenus()
    local requestAddMenu = LUI.FlowManager.RequestAddMenu
    LUI.FlowManager.RequestAddMenu = function(name, ...)
        if type(name) == "string" then
            log("opening menu " .. name)
            if lobbyMenus[name] then
                local build = MenuBuilder.m_types[name]
                log(name .. " builder is " .. type(build) .. ", already wrapped: " .. tostring(wrappers[build] ~= nil))
                if build and not wrappers[build] then
                    MenuBuilder.m_types[name] = wrap(name, build)
                end
            end
        end
        return requestAddMenu(name, ...)
    end
end

safe("wrapRegistered", wrapRegistered)
safe("logLobbyTypes", logLobbyTypes)
safe("hookOpenedMenus", hookOpenedMenus)

-- menus registered with registerType after this script has loaded
local registerType = MenuBuilder.registerType
MenuBuilder.registerType = function(name, build)
    if lobbyMenus[name] then
        build = wrap(name, build)
    end
    return registerType(name, build)
end

-- menus assigned straight into the type table after this script has loaded
if getmetatable(MenuBuilder.m_types) == nil then
    setmetatable(MenuBuilder.m_types, {
        __newindex = function(types, name, build)
            if lobbyMenus[name] and type(build) == "function" then
                build = wrap(name, build)
            end
            rawset(types, name, build)
        end
    })
end

-- the stock menus may register after the scripts load, so look again once the UI is up
safe("scheduler.once", function()
    scheduler.once(function()
        safe("wrapRegistered (late)", wrapRegistered)
        safe("logLobbyTypes (late)", logLobbyTypes)
    end)
end)
