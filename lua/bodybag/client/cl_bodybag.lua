-------------------------------------
-------------------------------------
--            BodyBag              --
--                                 --
--          Copyright by           --
-- Florian 'ItzTinonTime' Reinertz --
-------------------------------------
-------------------------------------

local COL_BG        = Color(0, 0, 0, 230)
local COL_OUTLINE   = Color(255, 255, 255, 255)
local COL_PANEL     = Color(25, 25, 25, 200)
local COL_ITEM      = Color(50, 50, 50, 255)
local COL_BTN_STOP  = Color(213, 0, 0)
local COL_BTN_GO    = Color(0, 213, 0)
local COL_WHITE     = Color(255, 255, 255)

--- Creates a row for a body in the list.
-- @param parent Panel
-- @param person Table
-- @return Panel
local function createBodyRow(parent, person)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:DockMargin(5, 5, 5, 5)
    row:SetTall(ScrH() * 0.075)
    row.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COL_ITEM)
    end

    -- Model panel (left)
    local mp = vgui.Create("DModelPanel", row)
    mp:Dock(LEFT)
    mp:DockMargin(0, 0, 0, 0)
    mp:SetWide(ScrW() * 0.05)
    mp:SetFOV(15)
    function mp:LayoutEntity(_) return end

    -- Models may be missing – set defensively
    local model = person.model or ""
    if model ~= "" then
        mp:SetModel(model)
        local ent = mp.Entity
        if IsValid(ent) then
            local min, max = ent:GetRenderBounds()
            mp:SetCamPos(min:Distance(max) * Vector(0.75, 0, 0.5))
            mp:SetLookAt((max + min) * 0.9)
        end
    end

    -- Name (top)
    local nameLabel = vgui.Create("DLabel", row)
    nameLabel:Dock(TOP)
    nameLabel:DockMargin(15, ScrH() * 0.02, 5, 0)
    nameLabel:SetText(person.name or "Unknown")
    nameLabel:SetFont("BodyBag.Name")
    nameLabel:SetTextColor(COL_WHITE)

    -- Faction (below)
    local factionLabel = vgui.Create("DLabel", row)
    factionLabel:Dock(TOP)
    factionLabel:DockMargin(15, 5, 5, 5)
    factionLabel:SetText(person.faction or "Unknown")
    factionLabel:SetFont("BodyBag.Faction")
    factionLabel:SetTextColor(COL_WHITE)

    return row
end

--- Closes the body bag menu.
function BodyBag:CloseMenu()
    if IsValid(self.Frame) then
        self.Frame:Remove()
    end
end

-- Open crematorium menu.
-- @param entity Forwarding of the entities currently in use.
-- @param table Data that must already be displayed in the menu.
function BodyBag:OpenMenu(entity, bodies)
    self:CloseMenu()

    if not IsValid(entity) then
        notification.AddLegacy("BodyBag: invalid entity.", NOTIFY_ERROR, 3)
        return
    end

    bodies = istable(bodies) and bodies or {}

    local width, height  = ScrW() * 0.3, ScrH() * 0.6

    -- Frame
    local frame = vgui.Create("DFrame")
    self.Frame = frame
    frame:SetSize(width, height)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COL_BG)
        surface.SetDrawColor(COL_OUTLINE)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(
            BodyBag:GetLangString("frame_title") or "Crematorium",
            "BodyBag.Title",
            8, 6,
            COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )
    end

    -- Close button (top right, relative to the frame)
    local btnClose = vgui.Create("DButton", frame)
    btnClose:SetSize(28, 28)
    btnClose:SetPos(width - btnClose:GetWide() - 6, 4)
    btnClose:SetText("")
    btnClose.Paint = function(me, w, h)
        local c = me:IsHovered() and Color(255, 0, 0) or COL_WHITE
        draw.SimpleText("X", "BodyBag.CloseButton", w / 2, h / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnClose.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
        self:CloseMenu() 
    end

    -- Scrollpanel (List)
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 34, 6, 6)
    scroll.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COL_PANEL)
    end

    local sbar = scroll:GetVBar()
    function sbar.btnGrip:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(60, 60, 60))
    end

    -- Rendering bodies or placeholders
    if #bodies == 0 then
        local empty = vgui.Create("DLabel", scroll)
        empty:Dock(TOP)
        empty:DockMargin(10, 10, 10, 10)
        empty:SetText(BodyBag:GetLangString("no_bodies") or "No bodies stored.")
        empty:SetFont("BodyBag.Faction")
        empty:SetTextColor(COL_WHITE)
        empty:SetContentAlignment(5) -- Center alignment
    else
        for _, person in ipairs(bodies) do
            createBodyRow(scroll, person)
        end
    end

    -- button bar
    local bar = vgui.Create("DPanel", frame)
    bar:Dock(BOTTOM)
    bar:DockMargin(6, 0, 6, 6)
    bar:SetTall(ScrH() * 0.06)
    bar.Paint = nil

    -- Burn All
    local burn = vgui.Create("DButton", bar)
    burn:Dock(RIGHT)
    burn:DockMargin(6, 0, 0, 0)
    burn:SetWide(width * 0.45)
    burn:SetText("")
    burn.Paint = function(me, w, h)
        local c = me:IsHovered() and Color(255, 0, 0) or COL_BTN_STOP
        draw.RoundedBox(6, 0, 0, w, h, c)
        draw.SimpleText(BodyBag:GetLangString("frame_burnall") or "Burn all", "BodyBag.Faction", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    burn.DoClick = function()
        net.Start("BodyBag.TriggerBurnAll")
            net.WriteEntity(entity)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
        self:CloseMenu()
    end

    -- Store All
    local store = vgui.Create("DButton", bar)
    store:Dock(FILL)
    store:SetText("")
    store.Paint = function(me, w, h)
        local c = me:IsHovered() and Color(0, 255, 0) or COL_BTN_GO
        draw.RoundedBox(6, 0, 0, w, h, c)
        draw.SimpleText(BodyBag:GetLangString("frame_storeall") or "Store all", "BodyBag.Faction", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    store.DoClick = function()
        net.Start("BodyBag.TriggerCheck")
            net.WriteEntity(entity)
        net.SendToServer()

        notification.AddLegacy(BodyBag:GetLangString("bodies_stored") or "Bodies stored.", NOTIFY_GENERIC, 4)
        surface.PlaySound("ambient/levels/canals/drip1.wav")
        Msg((BodyBag:GetLangString("bodies_stored") or "Bodies stored.") .. "\n")

        surface.PlaySound("buttons/button14.wav")
        self:CloseMenu()
    end

    frame:MakePopup()
    frame:DoModal()
end

-- Networking because we are using ENT:Use on server.
net.Receive("BodyBag.OpenMenu", function()
    local ent   = net.ReadEntity()
    local bodies= net.ReadTable() or {}
    BodyBag:OpenMenu(ent, bodies)
end)