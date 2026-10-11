local columns = {}

-- Optional columns depend on which resources a server installed, so check them once before querying
-- Needs the calling resource to load @oxmysql/lib/MySQL.lua, and reports false without it
---@param tableName string
---@param columnName string
---@return boolean exists
function Functions.hasDatabaseColumn(tableName, columnName)
    if (not MySQL) then return false end

    local key = tableName .. "." .. columnName
    if (columns[key] == nil) then
        local query = [[
            SELECT
                COUNT(*)
            FROM
                information_schema.COLUMNS
            WHERE
                TABLE_SCHEMA = DATABASE()
                AND TABLE_NAME = ?
                AND COLUMN_NAME = ?
        ]]

        columns[key] = (MySQL.scalar.await(query, {tableName, columnName}) or 0) > 0
    end

    return columns[key]
end

return Functions.hasDatabaseColumn