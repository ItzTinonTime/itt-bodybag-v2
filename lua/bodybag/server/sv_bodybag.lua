-------------------------------------
-------------------------------------
--            BodyBag              --
--                                 --
--          Copyright by           --
-- Florian 'ItzTinonTime' Reinertz --
-------------------------------------
-------------------------------------

--- Checks if a player is allowed to interact with an entity.
-- @param ply player
-- @param ent entity
-- @param maxDist number
local function isAllowed(ply, ent, maxDist)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not IsValid(ent) or ent:GetClass() ~= "bodybag_crematorium" then return end
    if maxDist and maxDist > 0 then
        if ply:GetPos():DistToSqr(ent:GetPos()) > (maxDist * maxDist) then
            return false
        end
    end
    return true
end

--- Create a body bag from a ragdoll.
-- @param ragdoll Entity (ragdoll)
-- @param target  Entity (player or nil)
function BodyBag:CreateBodyBag(ragdoll, target)
    if not IsValid(ragdoll) or not ragdoll:IsRagdoll() then return end

    -- Cache before removal
    local pos   = ragdoll:GetPos()
    local ang   = ragdoll:GetAngles()
    local model = ragdoll:GetModel()

    ragdoll:Remove()

    local bag = ents.Create("prop_physics")
    if not IsValid(bag) then return end

    bag:SetModel("models/props_misc/bodybag/bodybag_fox.mdl")
    bag:SetPos(pos + Vector(2, 0, 0))
    bag:SetAngles(ang)

    bag.isBodyBag   = true
    bag.deathName   = (IsValid(target) and target:IsPlayer()) and target:Nick() or "Unknown"
    bag.deathFaction= BodyBag.Config.DefaultFaction or "Unknown"
    bag.deathModel  = model

    bag:Spawn()
    bag:Activate()
    bag:SetCollisionGroup(COLLISION_GROUP_NONE)

    local phys = bag:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    -- Respawn a dead player that was bagged
    if IsValid(target) and target:IsPlayer() and not target:Alive() and BodyBag.Config.RespawnOnBag then
        target:Spawn()
        PrintMessage(HUD_PRINTTALK, target:Nick() .. " respawned because they were placed in a body bag.")
    end

    return bag
end

--- Collect nearby body bags into ENT.storedBodies and remove them.
util.AddNetworkString("BodyBag.TriggerCheck")
net.Receive("BodyBag.TriggerCheck", function(_, ply)
    local ENT = net.ReadEntity()
    if not isAllowed(ply, ENT, BodyBag.Config.SearchDistance) then return end

    ENT.storedBodies = ENT.storedBodies or {}

    local entities = ents.FindInSphere(ENT:GetPos(), BodyBag.Config.SearchDistance or 128)
    for _, e in ipairs(entities) do
        if IsValid(e) and e.isBodyBag then
            table.insert(ENT.storedBodies, {
                name    = e.deathName   or "Unknown",
                faction = e.deathFaction or "Unknown",
                model   = e.deathModel  or ""
            })
            e:Remove()
        end
    end
end)

--- Burn all stored bodies in ENT.storedBodies. Plays a fire loop for nearby players.
util.AddNetworkString("BodyBag.TriggerBurnAll")
net.Receive("BodyBag.TriggerBurnAll", function(_, ply)
    local ENT = net.ReadEntity()
    if not isAllowed(ply, ENT, BodyBag.Config.EmitFireSoundRadius) then return end

    ENT.storedBodies = ENT.storedBodies or {}
    table.Empty(ENT.storedBodies)

    local entPos = ENT:GetPos()

    -- Start fire entity (10s)
    local fire = ents.Create("env_fire")
    if IsValid(fire) then
        fire:SetPos(entPos + Vector(0, 0, 10))
        fire:SetKeyValue("health", "8")
        fire:SetKeyValue("firesize", "64")
        fire:SetKeyValue("fireattack", "1")
        fire:SetKeyValue("damagescale", "1.0")
        fire:Spawn()
        fire:Activate()
        fire:Fire("StartFire", "", 0)

        timer.Simple(10, function()
            if IsValid(fire) then fire:Remove() end
        end)
    end

    -- Play/stop fire loop for players in radius
    local radius  = BodyBag.Config.EmitFireSoundRadius or 512
    local level   = BodyBag.Config.FireSoundLevel or 70
    local volume  = BodyBag.Config.FireSoundVolume or 0.6

    for _, p in ipairs(ents.FindInSphere(entPos, radius)) do
        if IsValid(p) and p:IsPlayer() then
            -- EmitSound(name, level, pitch, volume, channel)
            p:EmitSound("ambient/fire/fire_big_loop1.wav", level, 100, volume, CHAN_AUTO)
        end
    end

    -- Stop loop after 10s (re-scan sphere to include late joiners)
    timer.Simple(10, function()
        for _, p in ipairs(ents.FindInSphere(entPos, radius)) do
            if IsValid(p) and p:IsPlayer() then
                p:StopSound("ambient/fire/fire_big_loop1.wav")
            end
        end
    end)
end)