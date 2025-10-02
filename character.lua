-------------------------------------------
----- AUSPixel Custom UI For QBX_Core -----
-------------------------------------------
local config = require 'config.client'
local defaultSpawn = require 'config.shared'.defaultSpawn
if config.characters.useExternalCharacters then return end
local previewCam
local randomLocation = config.characters.locations[math.random(1, #config.characters.locations)]
local nationalities = {}
local uiOpen = false
local lastCharacters = nil
local pendingFirstClothing = false
local randomPeds = {
    {
        model = `mp_m_freemode_01`,
        headOverlays = {
            beard = {color = 0, style = 0, secondColor = 0, opacity = 1},
            complexion = {color = 0, style = 0, secondColor = 0, opacity = 0},
            bodyBlemishes = {color = 0, style = 0, secondColor = 0, opacity = 0},
            blush = {color = 0, style = 0, secondColor = 0, opacity = 0},
            lipstick = {color = 0, style = 0, secondColor = 0, opacity = 0},
            blemishes = {color = 0, style = 0, secondColor = 0, opacity = 0},
            eyebrows = {color = 0, style = 0, secondColor = 0, opacity = 1},
            makeUp = {color = 0, style = 0, secondColor = 0, opacity = 0},
            sunDamage = {color = 0, style = 0, secondColor = 0, opacity = 0},
            moleAndFreckles = {color = 0, style = 0, secondColor = 0, opacity = 0},
            chestHair = {color = 0, style = 0, secondColor = 0, opacity = 1},
            ageing = {color = 0, style = 0, secondColor = 0, opacity = 1},
        },
        components = {
            {texture = 0, drawable = 0, component_id = 0},
            {texture = 0, drawable = 0, component_id = 1},
            {texture = 0, drawable = 0, component_id = 2},
            {texture = 0, drawable = 0, component_id = 5},
            {texture = 0, drawable = 0, component_id = 7},
            {texture = 0, drawable = 0, component_id = 9},
            {texture = 0, drawable = 0, component_id = 10},
            {texture = 0, drawable = 15, component_id = 11},
            {texture = 0, drawable = 15, component_id = 8},
            {texture = 0, drawable = 15, component_id = 3},
            {texture = 0, drawable = 34, component_id = 6},
            {texture = 0, drawable = 61, component_id = 4},
        },
        props = {
            {prop_id = 0, drawable = -1, texture = -1},
            {prop_id = 1, drawable = -1, texture = -1},
            {prop_id = 2, drawable = -1, texture = -1},
            {prop_id = 6, drawable = -1, texture = -1},
            {prop_id = 7, drawable = -1, texture = -1},
        }
    },
    {
        model = `mp_f_freemode_01`,
        headBlend = { shapeMix = 0.3, skinFirst = 0, shapeFirst = 31, skinSecond = 0, shapeSecond = 0, skinMix = 0, thirdMix = 0, shapeThird = 0, skinThird = 0 },
        hair = { color = 0, style = 15, texture = 0, highlight = 0 },
        headOverlays = {
            chestHair = {secondColor = 0, opacity = 0, color = 0, style = 0},
            bodyBlemishes = {secondColor = 0, opacity = 0, color = 0, style = 0},
            beard = {secondColor = 0, opacity = 0, color = 0, style = 0},
            lipstick = {secondColor = 0, opacity = 0, color = 0, style = 0},
            complexion = {secondColor = 0, opacity = 0, color = 0, style = 0},
            blemishes = {secondColor = 0, opacity = 0, color = 0, style = 0},
            moleAndFreckles = {secondColor = 0, opacity = 0, color = 0, style = 0},
            makeUp = {secondColor = 0, opacity = 0, color = 0, style = 0},
            ageing = {secondColor = 0, opacity = 1, color = 0, style = 0},
            eyebrows = {secondColor = 0, opacity = 1, color = 0, style = 0},
            blush = {secondColor = 0, opacity = 0, color = 0, style = 0},
            sunDamage = {secondColor = 0, opacity = 0, color = 0, style = 0},
        },
        components = {
            {drawable = 0, component_id = 0, texture = 0},
            {drawable = 0, component_id = 1, texture = 0},
            {drawable = 0, component_id = 2, texture = 0},
            {drawable = 0, component_id = 5, texture = 0},
            {drawable = 0, component_id = 7, texture = 0},
            {drawable = 0, component_id = 9, texture = 0},
            {drawable = 0, component_id = 10, texture = 0},
            {drawable = 15, component_id = 3, texture = 0},
            {drawable = 15, component_id = 11, texture = 3},
            {drawable = 14, component_id = 8, texture = 0},
            {drawable = 15, component_id = 4, texture = 3},
            {drawable = 35, component_id = 6, texture = 0},
        },
        props = {
            {prop_id = 0, drawable = -1, texture = -1},
            {prop_id = 1, drawable = -1, texture = -1},
            {prop_id = 2, drawable = -1, texture = -1},
            {prop_id = 6, drawable = -1, texture = -1},
            {prop_id = 7, drawable = -1, texture = -1},
        }
    }
}
if config.characters.limitNationalities then
    local nationalityList = lib.load('data.nationalities')
    CreateThread(function()
        for i = 1, #nationalityList do
            nationalities[#nationalities + 1] = nationalityList[i]
        end
    end)
end
local function setBaseModelForGender(genderInt)
    local modelHash = (genderInt == 0) and `mp_m_freemode_01` or `mp_f_freemode_01`
    lib.requestModel(modelHash, config.loadingModelsTimeout)
    SetPlayerModel(cache.playerId, modelHash)
    SetModelAsNoLongerNeeded(modelHash)
end
local function findGenderByCitizenId(citizenid)
    if not lastCharacters or not citizenid then return nil end
    for i = 1, #lastCharacters do
        local c = lastCharacters[i]
        if c and c.citizenid == citizenid then
            return c.charinfo and c.charinfo.gender or nil
        end
    end
    return nil
end
local function setupPreviewCam()
    DoScreenFadeIn(800)
    SetTimecycleModifier('default')
    FreezeEntityPosition(cache.ped, false)
    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        randomLocation.camCoords.x, randomLocation.camCoords.y, randomLocation.camCoords.z,
        -6.0, 0.0, randomLocation.camCoords.w, 40.0, false, 0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 1, true, true)
end
local function destroyPreviewCam()
    if not previewCam then return end
    SetTimecycleModifier('default')
    SetCamActive(previewCam, false)
    DestroyCam(previewCam, true)
    RenderScriptCams(false, false, 1, true, true)
    FreezeEntityPosition(cache.ped, false)
    DisplayRadar(true)
    previewCam = nil
end
local function randomPed()
    local ped = randomPeds[math.random(1, #randomPeds)]
    lib.requestModel(ped.model, config.loadingModelsTimeout)
    SetPlayerModel(cache.playerId, ped.model)
    pcall(function() exports['illenium-appearance']:setPedAppearance(PlayerPedId(), ped) end)
    SetModelAsNoLongerNeeded(ped.model)
end
local function previewPed(citizenId)
    if not citizenId then
        randomPed()
        return
    end
    local clothing, model = lib.callback.await('qbx_core:server:getPreviewPedData', false, citizenId)
    if model and clothing then
        lib.requestModel(model, config.loadingModelsTimeout)
        SetPlayerModel(cache.playerId, model)
        pcall(function() exports['illenium-appearance']:setPedAppearance(PlayerPedId(), json.decode(clothing)) end)
        SetModelAsNoLongerNeeded(model)
        return
    end
    local g = findGenderByCitizenId(citizenId)
    if g == 0 or g == 1 then
        setBaseModelForGender(g)
    else
        randomPed()
    end
end
local function spawnLastLocation()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    destroyPreviewCam()
    if QBX and QBX.PlayerData and QBX.PlayerData.position then
        pcall(function()
            exports.spawnmanager:spawnPlayer({
                x = QBX.PlayerData.position.x,
                y = QBX.PlayerData.position.y,
                z = QBX.PlayerData.position.z,
                heading = QBX.PlayerData.position.w
            })
        end)
    end
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    while not IsScreenFadedIn() do Wait(0) end
end
local function spawnDefault()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    destroyPreviewCam()
    pcall(function() exports.spawnmanager:spawnPlayer({
        x = defaultSpawn.x, y = defaultSpawn.y, z = defaultSpawn.z, heading = defaultSpawn.w
    }) end)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    while not IsScreenFadedIn() do Wait(0) end
end
local function setFocus(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    if state then DisplayRadar(false) end
end
local function openUI(characters, slots)
    lastCharacters = characters
    local list = {}
    for i = 1, slots do
        local c = characters[i]
        if c then
            list[#list+1] = {
                idx = i,
                citizenid = c.citizenid,
                name = ('%s %s'):format(c.charinfo.firstname, c.charinfo.lastname),
                gender = c.charinfo.gender == 0 and 'Male' or 'Female',
                birthdate = c.charinfo.birthdate,
                nationality = c.charinfo.nationality,
                bank = c.money.bank,
                cash = c.money.cash,
                job = (c.job and c.job.label) or 'Civilian',
                job_key = (c.job and c.job.name) or 'unemployed',
                grade = (c.job and c.job.grade and c.job.grade.name) or 'Freelancer',
                phone = c.charinfo.phone,
                gang = c.gang and c.gang.label or '—',
            }
        else
            list[#list+1] = { idx = i, empty = true }
        end
    end
    SendNUIMessage({
        type = 'char:open',
        characters = list,
        slots = slots,
        nationalityOptions = nationalities
    })
    SendNUIMessage({ type = 'char:force-close-modal' })
    setFocus(true)
    SetTimecycleModifier('default')
end
local function closeUI()
    setFocus(false)
    SendNUIMessage({ type = 'char:close' })
    SetTimecycleModifier('default')
end
local function capString(str)
    return str and str:gsub("(%w)([%w']*)", function(a, b) return a:upper() .. b:lower() end) or str
end
local function createOnServer(payload)
    local genderInt = (payload.gender == 'Male') and 0 or 1
    setBaseModelForGender(genderInt)
    DoScreenFadeOut(150)
    local newData = lib.callback.await('qbx_core:server:createCharacter', false, {
        firstname  = capString(payload.firstname),
        lastname   = capString(payload.lastname),
        nationality= capString(payload.nationalityName or payload.nationality or 'Unknown'),
        gender     = genderInt, -- 0 male, 1 female
        birthdate  = payload.birthdate,
        cid        = payload.cid
    })
    pendingFirstClothing = true
    if GetResourceState('qbx_apartments'):find('start') then
        TriggerEvent('apartments:client:setupSpawnUI', newData)
    elseif GetResourceState('qbx_spawn'):find('start') then
        TriggerEvent('qb-spawn:client:setupSpawns', newData)
        TriggerEvent('qb-spawn:client:openUI', true)
    else
        spawnDefault()
    end
    destroyPreviewCam()
end
local function chooseCharacter()
    local characters, amount = lib.callback.await('qbx_core:server:getCharacters')
    local firstCitizenId = characters[1] and characters[1].citizenid
    randomLocation = config.characters.locations[math.random(1, #config.characters.locations)]
    SetFollowPedCamViewMode(2)
    DisplayRadar(false)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() and cache.ped ~= PlayerPedId() do Wait(0) end
    FreezeEntityPosition(cache.ped, true)
    Wait(1000)
    SetEntityCoords(cache.ped, randomLocation.pedCoords.x, randomLocation.pedCoords.y, randomLocation.pedCoords.z, false, false, false, false)
    SetEntityHeading(cache.ped, randomLocation.pedCoords.w)
    NetworkStartSoloTutorialSession()
    while not NetworkIsInTutorialSession() do Wait(0) end
    Wait(1500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    setupPreviewCam()
    openUI(characters, amount)
    previewPed(firstCitizenId)
end
RegisterNUICallback('ui_ready', function(_, cb) cb(1) end)
RegisterNUICallback('char_preview', function(data, cb)
    previewPed(data and data.citizenid)
    cb(1)
end)
RegisterNUICallback('char_play', function(data, cb)
    cb(1)
    closeUI()
    DoScreenFadeOut(10)
    lib.callback.await('qbx_core:server:loadCharacter', false, data.citizenid)
    spawnLastLocation()
    destroyPreviewCam()
end)
RegisterNUICallback('char_delete', function(data, cb)
    local ok = lib.callback.await('qbx_core:server:deleteCharacter', false, data.citizenid)
    cb(ok and 1 or 0)
    if ok then
        destroyPreviewCam()
        chooseCharacter()
    end
end)
RegisterNUICallback('char_create', function(data, cb)
    cb(1)
    closeUI()
    createOnServer(data)
end)
RegisterNUICallback('char_cancel', function(_, cb)
    cb(1)
end)
RegisterNUICallback('char_enable_blur', function(_, cb)
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(0.9)
    cb(1)
end)
RegisterNUICallback('char_disable_blur', function(_, cb)
    SetTimecycleModifier('default'); cb(1)
end)
RegisterNetEvent('qbx_core:client:spawnNoApartments', function()
    DoScreenFadeOut(500)
    Wait(2000)
    SetEntityCoords(cache.ped, defaultSpawn.x, defaultSpawn.y, defaultSpawn.z, false, false, false, false)
    SetEntityHeading(cache.ped, defaultSpawn.w)
    Wait(500)
    destroyPreviewCam()
    SetEntityVisible(cache.ped, true, false)
    Wait(500)
    DoScreenFadeIn(250)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    TriggerEvent('qb-weathersync:client:EnableSync')
    if pendingFirstClothing then
        pendingFirstClothing = false
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    end
end)
RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end
    chooseCharacter()
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if pendingFirstClothing then
        SetTimeout(300, function()
            pendingFirstClothing = false
            TriggerEvent('qb-clothes:client:CreateFirstCharacter')
        end)
    end
end)
CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
            Wait(250)
            chooseCharacter()
            break
        end
    end
    while NetworkIsInTutorialSession() do
        SetEntityInvincible(PlayerPedId(), true)
        Wait(250)
    end
    SetEntityInvincible(PlayerPedId(), false)
end)
CreateThread(function()
    while true do
        if uiOpen then
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 202, true)
            DisableControlAction(0, 322, true)
        end
        Wait(0)
    end
end)
