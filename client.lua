local ESX = exports["es_extended"]:getSharedObject()

local Config = {
    animDict     = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
    animName     = "machinic_loop_mechandplayer",
    animDuration = 3000,
    maxDistance  = 4.0,
}

local TireBones = {
    { bone = "wheel_lf",  label = "Avant gauche",    id = 0  },
    { bone = "wheel_rf",  label = "Avant droit",     id = 1  },
    { bone = "wheel_lm",  label = "Milieu gauche",   id = 2  },
    { bone = "wheel_rm",  label = "Milieu droit",    id = 3  },
    { bone = "wheel_lr",  label = "Arrière gauche",  id = 4  },
    { bone = "wheel_rr",  label = "Arrière droit",   id = 5  },
    { bone = "wheel_lm1", label = "Milieu gauche 2", id = 2  },
    { bone = "wheel_rm1", label = "Milieu droit 2",  id = 3  },
    { bone = "wheel_lm2", label = "Milieu gauche 3", id = 45 },
    { bone = "wheel_rm2", label = "Milieu droit 3",  id = 47 },
}

local activeTargets = {}

local function loadAnim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(50)
        timeout = timeout + 50
        if timeout > 5000 then
            print("^1[metro_tireflat] ERREUR : impossible de charger le dict : " .. dict)
            return false
        end
    end
    return true
end

local function hasSlashingWeapon()
    local knife       = exports.ox_inventory:Search('count', 'WEAPON_KNIFE')
    local switchblade = exports.ox_inventory:Search('count', 'WEAPON_SWITCHBLADE')

    local knifeCount       = type(knife) == 'number' and knife or (type(knife) == 'table' and (knife['WEAPON_KNIFE'] or 0) or 0)
    local switchbladeCount = type(switchblade) == 'number' and switchblade or (type(switchblade) == 'table' and (switchblade['WEAPON_SWITCHBLADE'] or 0) or 0)

    return knifeCount > 0 or switchbladeCount > 0
end

local function flattenTire(vehicle, tireIndex, tireName)
    local ped = PlayerPedId()

    local pPos = GetEntityCoords(ped)
    local vPos = GetEntityCoords(vehicle)

    if #(pPos - vPos) > Config.maxDistance then
        lib.notify({ title = 'Trop loin', description = 'Rapprochez-vous du véhicule.', type = 'error' })
        return
    end

    if not hasSlashingWeapon() then
        lib.notify({ title = 'Objet manquant', description = 'Vous avez besoin d’un couteau ou cran d’arrêt.', type = 'error' })
        return
    end

    if not loadAnim(Config.animDict) then
        lib.notify({ title = 'Erreur', description = 'Animation introuvable.', type = 'error' })
        return
    end

    -- Choix arme
    local weaponHash = `WEAPON_KNIFE`

    local switchCount = exports.ox_inventory:Search('count', 'WEAPON_SWITCHBLADE')
    local hasSwitchblade = (type(switchCount) == 'number' and switchCount > 0)
        or (type(switchCount) == 'table' and (switchCount['WEAPON_SWITCHBLADE'] or 0) > 0)

    if hasSwitchblade then
        weaponHash = `WEAPON_SWITCHBLADE`
    end

    -- === LOCK PLAYER ===
    FreezeEntityPosition(ped, true)
    SetEntityHeading(ped, GetEntityHeading(ped))

    GiveWeaponToPed(ped, weaponHash, 1, false, true)
    SetCurrentPedWeapon(ped, weaponHash, false)

    Wait(600)

    
    ClearPedTasks(ped)

    TaskPlayAnim(
        ped,
        Config.animDict,
        Config.animName,
        4.0,
        -4.0,
        Config.animDuration,
        0,
        0,
        false,
        false,
        false
    )

    Wait(Config.animDuration)

    ClearPedTasks(ped)

    
    if DoesEntityExist(vehicle) then
        SetVehicleTyreBurst(vehicle, tireIndex, false, 10.0)

        -- lib.notify({
        --     title = 'Pneu dégonflé',
        --     description = tireName .. ' a été dégonflé.',
        --     type = 'success'
        -- })
    else
        lib.notify({
            title = 'Erreur',
            description = 'Véhicule introuvable.',
            type = 'error'
        })
    end

    FreezeEntityPosition(ped, false)

    Wait(300)

    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, false)
end

local function addTireTargets(vehicle)
    if not DoesEntityExist(vehicle) then return end
    if activeTargets[vehicle] then return end

    activeTargets[vehicle] = true

    for _, tire in ipairs(TireBones) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, tire.bone)
        if boneIndex ~= -1 then
            local tireIndex = tire.id
            local tireLabel = tire.label

            exports.ox_target:addLocalEntity(vehicle, {
                {
                    name     = 'flat_tire_' .. tire.bone,
                    icon     = 'fas fa-slash',
                    label    = 'Crever le pneu',
                    bones    = { tire.bone },
                    distance = Config.maxDistance,

                    canInteract = function(entity)
                        if IsVehicleTyreBurst(entity, tireIndex, false) then return false end
                        return hasSlashingWeapon()
                    end,

                    onSelect = function()
                        flattenTire(vehicle, tireIndex, tireLabel)
                    end,
                }
            })
        end
    end
end

local function removeTargets(vehicle)
    if not activeTargets[vehicle] then return end
    exports.ox_target:removeLocalEntity(vehicle)
    activeTargets[vehicle] = nil
end

CreateThread(function()
    while true do
        Wait(1500)

        local ped     = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local nearby  = {}

        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) and veh ~= GetVehiclePedIsIn(ped, false) then
                local dist = #(pCoords - GetEntityCoords(veh))
                if dist <= Config.maxDistance + 1.0 then
                    table.insert(nearby, veh)
                    addTireTargets(veh)
                end
            end
        end

        for veh in pairs(activeTargets) do
            local found = false
            for _, v in ipairs(nearby) do
                if v == veh then found = true; break end
            end
            if not found then removeTargets(veh) end
        end
    end
end)