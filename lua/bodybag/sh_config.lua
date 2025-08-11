-------------------------------------
-------------------------------------
--            BodyBag              --
--                                 --
--          Copyright by           --
-- Florian 'ItzTinonTime' Reinertz --
-------------------------------------
-------------------------------------

-- DONT touch this line:
BodyBag.Config = {}

-- Language: de, en, fr
BodyBag.Config.SetLanguage = "de"

-- Crematorium entity model
-- Default: "models/niksacokica/construction/construction_storage_compactor_01.mdl" from 
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2102911039
BodyBag.Config.EntityModel = "models/niksacokica/construction/construction_storage_compactor_01.mdl"

-- Bodybag model
-- Default: "models/props_misc/bodybag/bodybag_fox.mdl" from
-- https://steamcommunity.com/workshop/filedetails/?id=2559515043
BodyBag.Config.Model = "models/props_misc/bodybag/bodybag_fox.mdl"

-- Search radius for corpses.
-- Needed for crematorium.
BodyBag.Config.SearchDistance = 100

-- Radius in which the fire can be heard when burning.
BodyBag.Config.EmitFireSoundRadius = 500

-- Should there be a timer for the bodybag SWEP?
BodyBag.Config.SwepTimerEnabled = true

-- How long does it take to pack a corpse in a body bag?
BodyBag.Config.TimeToPackBody = 2

-- Distance in which the bodybag SWEP can be used
-- Default: 70
BodyBag.Config.SwepUseDistance = 70