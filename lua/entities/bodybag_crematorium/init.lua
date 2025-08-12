-------------------------------------
-------------------------------------
--            BodyBag              --
--                                 --
--          Copyright by           --
-- Florian 'ItzTinonTime' Reinertz --
-------------------------------------
-------------------------------------

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Open menu on use. (network request)
-- Play sound.
util.AddNetworkString("BodyBag.OpenMenu")
ENT._nextUse = 0
function ENT:Use(ply)
    if self._nextUse > CurTime() then return end
    self._nextUse = CurTime() + 0.3

    net.Start("BodyBag.OpenMenu")
        net.WriteEntity(self)
        net.WriteTable(self.storedBodies or {})
    net.Send(ply)

    self:EmitSound("doors/door1_move.wav", 100, 80)
end

-- Stop fire sound for players in range when entity is removed.
function ENT:OnRemove()
    local radius = BodyBag.Config.EmitFireSoundRadius or 512
    for _, p in ipairs(ents.FindInSphere(self:GetPos(), radius)) do
        if IsValid(p) and p:IsPlayer() then
            p:StopSound("ambient/fire/fire_big_loop1.wav")
        end
    end
end