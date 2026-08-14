
local lp = Turbine.Gameplay.LocalPlayer:GetInstance()

function lp.TargetChanged(sender, args)

    local localPlayer = Turbine.Gameplay.LocalPlayer:GetInstance()
    local target = localPlayer:GetTarget()

    local targetName = target and target:GetName() or nil

    for _, window in ipairs(_G.PotatoWindows) do
        window:TargetChanged(targetName)
    end

end