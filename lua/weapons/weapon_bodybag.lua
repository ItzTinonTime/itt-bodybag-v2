-------------------------------------
-------------------------------------
--            BodyBag              --
--                                 --
--          Copyright by           --
-- Florian 'ItzTinonTime' Reinertz --
-------------------------------------
-------------------------------------

if SERVER then
    AddCSLuaFile()
end

SWEP.PrintName      = "Bodybag"
SWEP.Author         = "ItzTinonTime"
SWEP.Purpose        = "Put a ragdoll/player into a bodybag."
SWEP.Instructions   = "LEFT: put a ragdoll into a bodybag."
SWEP.Slot           = 5
SWEP.SlotPos        = 0
SWEP.DrawAmmo       = false
SWEP.Category       = "Tinon's stuff"

SWEP.Spawnable      = true
SWEP.AdminOnly      = false

SWEP.ViewModelFOV   = 70
SWEP.DefaultHoldType = "normal"

SWEP.Scope          = false

SWEP.ViewModel = ""
SWEP.WorldModel     = ""
SWEP.UseHands   = false

SWEP.Primary = {
    Damage       = 0,
    TakeAmmo     = 0,
    ClipSize     = 0,
    Ammo         = "none",
    DefaultClip  = 0,
    NumShots     = 0,
    Automatic    = false,
    Recoil       = 0,
    Delay        = 0.2,
}

SWEP.Secondary = {
    Damage       = 0,
    TakeAmmo     = 0,
    ClipSize     = 0,
    Ammo         = "none",
    DefaultClip  = 0,
    NumShots     = 0,
    Automatic    = false,
    Recoil       = 0,
    Delay        = 2,
}

-- intern NW-Keys
local NW_SHOW = "BB_ShowTimerBar"
local NW_START= "BB_TimerStart"
local NW_DUR  = "BB_TimerDur"

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:DrawWorldModel()
end

local function withinUseDistance(ply, ent, maxDist)
    if not IsValid(ply) or not IsValid(ent) then return false end
    local d2 = (maxDist or 70)
    d2 = d2 * d2
    return ply:GetPos():DistToSqr(ent:GetPos()) <= d2
end

local function stopTimerBar(wep)
    if not IsValid(wep) then return end
    wep:SetNWBool(NW_SHOW, false)
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    local tr  = owner:GetEyeTrace()
    local ent = IsValid(tr.Entity) and tr.Entity or nil
    if not IsValid(ent) or not ent:IsRagdoll() then return end
    if not withinUseDistance(owner, ent, BodyBag.Config.SwepUseDistance) then return end

    local duration = tonumber(BodyBag.Config.TimeToPackBody) or 2
    local timerEnabled = (BodyBag.Config.SwepTimerEnabled ~= false)

    -- Initialize HUD bar (only if desired and duration > 0)
    local showBar = timerEnabled and duration > 0
    self:SetNWBool(NW_SHOW, showBar)
    self:SetNWFloat(NW_START, CurTime())
    self:SetNWFloat(NW_DUR,   duration)

    -- Cooldown: cannot be triggered again during the action
    self:SetNextPrimaryFire(CurTime() + math.max(duration, self.Primary.Delay))

    if SERVER then
        -- Immediately place if timer is disabled or duration <= 0
        if not timerEnabled or duration <= 0 then
            BodyBag:CreateBodyBag(ent, ent:GetOwner())
            stopTimerBar(self)
            return
        end

        -- Timer-controlled action
        local id        = ("bodybag_swep_%d"):format(self:EntIndex())
        local startTime = CurTime()
        local step      = 0.05

        -- ensure that there is only one active timer per SWEP
        timer.Remove(id)

        timer.Create(id, step, 0, function()
            if not IsValid(self) or not IsValid(owner) or not IsValid(ent) then
                timer.Remove(id)
                stopTimerBar(self)
                return
            end

            -- Termination criteria: too far away / target no longer a ragdoll
            if not ent:IsRagdoll() or not withinUseDistance(owner, ent, BodyBag.Config.SwepUseDistance) then
                timer.Remove(id)
                stopTimerBar(self)
                return
            end

            -- ready?
            local elapsed = CurTime() - startTime
            if elapsed >= duration then
                BodyBag:CreateBodyBag(ent, ent:GetOwner())
                timer.Remove(id)
                stopTimerBar(self)
            end
        end)
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

if CLIENT then
    function SWEP:Deploy()
        local vm = LocalPlayer():GetViewModel()
        if IsValid(vm) then
            vm:SetNoDraw(true)
        end
        return true
    end
end

-- Tidying up / Visibility
function SWEP:Holster()
    if CLIENT then
        local vm = LocalPlayer():GetViewModel()
        if IsValid(vm) then
            vm:SetNoDraw(false)
        end
    end
    if SERVER then
        timer.Remove(("bodybag_swep_%d"):format(self:EntIndex()))
    end
    stopTimerBar(self)
    return true
end

function SWEP:OnRemove()
    if SERVER then
        timer.Remove(("bodybag_swep_%d"):format(self:EntIndex()))
    end
    stopTimerBar(self)
end

-- HUD: Progress bar (client)
if CLIENT then
    hook.Add("HUDPaint", "BodyBag.DrawTimer", function()
        local lp = LocalPlayer()
        if not IsValid(lp) then return end

        local wep = lp:GetActiveWeapon()
        if not IsValid(wep) then return end

        if not wep:GetNWBool(NW_SHOW, false) then return end

        local startTime = wep:GetNWFloat(NW_START, 0)
        local duration  = wep:GetNWFloat(NW_DUR, 3)
        if duration <= 0 then return end

        local timePassed = CurTime() - startTime
        if timePassed >= duration then
            wep:SetNWBool(NW_SHOW, false)
            return
        end

        local progress = math.Clamp(timePassed / duration, 0, 1)
        local timeLeft = math.max(0, duration - timePassed)

        local screenWidth, screenHeight = ScrW(), ScrH()
        local width, height = screenWidth * 0.20, screenHeight * 0.02
        local x, y = (screenWidth - width) / 2, screenHeight - 100

        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(x, y, width, height)

        surface.SetDrawColor(63, 127, 0, 255)
        surface.DrawRect(x, y, width * progress, height)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(x, y, width, height)

        local displayTime = string.format("%.1f", timeLeft)
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetFont("Trebuchet24")
        local tw, th = surface.GetTextSize(displayTime)
        surface.SetTextPos(x + (width - tw) / 2, y + (height - th) / 2)
        surface.DrawText(displayTime)
    end)
end