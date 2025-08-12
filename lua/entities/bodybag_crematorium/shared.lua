-------------------------------------
-------------------------------------
--            BodyBag              --
--                                 --
--          Copyright by           --
-- Florian 'ItzTinonTime' Reinertz --
-------------------------------------
-------------------------------------

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Crematorium"
ENT.Category = "NOVA"
ENT.Author = "ItzTinonTime"
ENT.Purpose = ""

ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:Initialize()
    self.storedBodies = {}

    if util.IsValidModel(self.WorldModel) then
        self:SetModel(BodyBag.Config.EntityModel or "models/niksacokica/construction/construction_storage_compactor_01.mdl")
    else
        self:SetModel("models/props_wasteland/kitchen_stove001a.mdl")
    end

    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
    end

    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
        phys:SetMass(60)
    end
end