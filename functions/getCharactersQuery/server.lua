-- A SELECT of every character, or one, for the caller to nest as a subquery. Its columns are identifier, firstname,
-- lastname, dob (as the framework stores it), sex ('m', 'f' or 'x') and phone
---@param identifier? CharacterIdentifier @ Only this character when given
---@return string? sql @ nil on a framework without characters in the database
---@return any[] params
function Functions.getCharactersQuery(identifier)
    local params = identifier and {identifier} or {}

    if (Framework == "ESX") then
        -- ESX keeps the number in users.phone_number only when a phone resource added that column
        local phone = Functions.hasDatabaseColumn("users", "phone_number") and "`phone_number`" or "NULL"
        local sql = ([[
            SELECT `identifier`, COALESCE(`firstname`, '') AS `firstname`, COALESCE(`lastname`, '') AS `lastname`,
                `dateofbirth` AS `dob`, CASE LOWER(`sex`) WHEN 'm' THEN 'm' WHEN 'f' THEN 'f' ELSE 'x' END AS `sex`, %s AS `phone`
            FROM `users` %s
        ]]):format(phone, identifier and "WHERE `identifier` = ?" or "")

        return sql, params
    end

    if (Framework == "QB") then
        local sql = ([[
            SELECT `citizenid` AS `identifier`,
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.firstname')), '') AS `firstname`,
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.lastname')), '') AS `lastname`,
                JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.birthdate')) AS `dob`,
                CASE JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.gender')) WHEN '0' THEN 'm' WHEN '1' THEN 'f' ELSE 'x' END AS `sex`,
                JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.phone')) AS `phone`
            FROM `players` %s
        ]]):format(identifier and "WHERE `citizenid` = ?" or "")

        return sql, params
    end

    return nil, params
end

return Functions.getCharactersQuery