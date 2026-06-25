Skippy.UpdateUnitInfo()

if aura_env.region and aura_env.region.texture then
    if Skippy.index then
        if Skippy.index >= 0 and Skippy.index <= 255 then
            aura_env.region.texture:SetVertexColor(0, 0, Skippy.index / 255, 1)
        elseif Skippy.index > 255 then
            local index = Skippy.index - 255
            aura_env.region.texture:SetVertexColor(0, 1, index, 1)
        end
    end
end
