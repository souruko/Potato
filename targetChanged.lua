
local lp = Turbine.Gameplay.LocalPlayer:GetInstance()

function lp.TargetChanged(sender, args)

    local localPlayer = Turbine.Gameplay.LocalPlayer:GetInstance()
    local target = localPlayer:GetTarget()

    if target then
        Potato:TargetChanged(target:GetName())
    else
        Potato:TargetChanged(nil)
    end

end