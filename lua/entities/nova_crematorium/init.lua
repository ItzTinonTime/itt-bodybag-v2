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

util.AddNetworkString("BodyBag.OpenMenu")
function ENT:Use(ply)
    net.Start("BodyBag.OpenMenu")
        net.WriteEntity(self)
        net.WriteTable(self.storedBodies)
    net.Send(ply)

    self:EmitSound("doors/door1_move.wav", 100, 80)
end
