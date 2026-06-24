local function refreshInit()
    aura_env.init = Skippy.macrosReady == true
end

refreshInit()
if not aura_env.init then
    C_Timer.After(0, refreshInit)
end
