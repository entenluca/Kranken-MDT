Postal = {}

local function tryNearestPostal(coords)
    if GetResourceState('nearest-postal') ~= 'started' then
        return nil
    end

    local ok, result = pcall(function()
        if exports['nearest-postal'] and exports['nearest-postal'].getPostal then
            return exports['nearest-postal']:getPostal(coords)
        end
        return exports['nearest-postal']:GetNearestPostal(coords)
    end)

    if ok and result then
        return tostring(result)
    end

    return nil
end

local function tryPostals(coords)
    if GetResourceState('postals') ~= 'started' then
        return nil
    end

    local ok, result = pcall(function()
        return exports['postals']:getPostal(coords)
    end)

    if ok and result then
        return tostring(result)
    end

    return nil
end

function Postal.GetPostal(coords)
    local vec = Utils.CoordsToVector3(coords)

    if Config.PostalResource == 'nearest-postal' then
        return tryNearestPostal(vec) or '0000'
    end

    if Config.PostalResource == 'postals' then
        return tryPostals(vec) or '0000'
    end

    if Config.PostalResource == 'none' then
        return '0000'
    end

    return tryNearestPostal(vec) or tryPostals(vec) or '0000'
end
