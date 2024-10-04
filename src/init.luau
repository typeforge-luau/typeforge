--!strict


--[[

MIT License

Copyright (c) 2024 Cameron Campbell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]


--> Boolean Operations --------------------------------------------------------------------------------
--[=[
    If a truthy type is inputted then it outputs `false`, and if a falsey type is inputted then it outputs `true`.

    @param input any -- The union/singleton you wish to perform a `Not` operation on.
]=]
type function _Not(input: any)
    if input:is("never") or input:is("unknown") then
        return types.singleton(false)

    elseif input:is("singleton") then
        return types.singleton(not types.value(input))

    elseif input:is("union") then
        local output

        for _,comp in input:components() do
            local invertedComp = types.singleton(not types.value(comp))
            if not output then output = invertedComp
            else output = types.unionof(output, invertedComp) end
        end

        return output
    end

    return types.never
end

export type Not<Input> = _Not<Input>


--[=[
    If all types of the union/singleton are truthy then it outputs `true`, but if at least one of the types of the union/singleton are falsely then it outputs `false`.

    @param input any -- The union/singleton you wish to perform an `And` operation on.
]=]
type function _And(input: any)
    if input:is("never") or input:is("unknown") then
        return types.singleton(false)

    elseif input:is("singleton") then
        return types.singleton(types.value(input) and true or false)
    
    elseif input:is("union") then
        for _,comp in input:components() do
            if comp:is("never") or comp:is("unknown") or (not types.value(comp)) then return types.singleton(false) end
        end

        return types.singleton(true)
    end

    return types.never
end

export type And<Input> = _And<Input>


--[=[
    If at least one of the types of the union/singleton are truthy then it outputs `true`, but if all of the types of the union/singleton are falsely then it outputs `false`.

    @param input any -- The union/singleton you wish to perform an `Or` operation on.
]=]
type function _Or(input: any)
    if input:is("never") or input:is("unknown") then
        return types.singleton(false)

    elseif input:is("singleton") then
        return types.singleton(types.value(input) and true or false)
    
    elseif input:is("union") then
        for _,comp in input:components() do
            if comp:is("never") or comp:is("unknown") then continue end
            if types.value(comp) then return types.singleton(true) end
        end

        return types.singleton(false)
    end

    return types.never
end

export type Or<Input> = _Or<Input>
-------------------------------------------------------------------------------------------------------


--> Table ---------------------------------------------------------------------------------------------
--[=[
    Outputs a copy of the input table but only with specified properties.

    @param tble { [any]: any } -- The table to pick properties from.
    @param toPick any -- A union/singeleton of properties to be picked.
]=]
type function _TablePick(tble: { [any]: any }, toPick: any)
    -- since `:writeproperty` throws an error instead of returning nil if it doesn't exist
    -- we need to use this workaround.
    local readProps, writeProps = types.newtable({}), types.newtable({})
    for key, value in tble:properties() do
        if value.read then readProps:setwriteproperty(key, value.read) end
        if value.write then writeProps:setwriteproperty(key, value.write) end
    end

    local function keyAsStringLiteral(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else false
        end
        return false
    end

    -- Currently two different string literal types are equal to each other.
    -- So we need to turn all string literal types into values.
    local function componentsStringLiteralsToValues(components)
        for idx,comp in components do
            local asStringLiteral = keyAsStringLiteral(comp)
            if asStringLiteral then components[idx] = asStringLiteral end
        end

        return components
    end

    local indexer, newIndexer = tble:indexer()
    local indexerIndex = indexer and indexer.index
    local indexerIndexComponents =
        indexer and componentsStringLiteralsToValues(indexerIndex:is("union") and indexerIndex:components() or { indexerIndex })

    local picked = types.newtable()

    local function pickKeyFromProperties(key: any)
        if key:is("singleton") then
            local read, write = readProps:writeproperty(key), writeProps:writeproperty(key)
            picked:setreadproperty(key, read)
            -- The `write == read` comparison is to ensure that the property is not
            -- unnecessarily separated into 2 different read write properties.
            if write then picked:setwriteproperty(key, write == read and read or write) end
        end
    end

    local function pickKeyFromIndexer(key: any)
        if table.find(indexerIndexComponents, keyAsStringLiteral(key) or key) then
            if newIndexer == nil then newIndexer = key
            else newIndexer = types.unionof(newIndexer, key) end
        end
    end

    local pickKey = indexer and function(key: any) pickKeyFromProperties(key); pickKeyFromIndexer(key) end or pickKeyFromProperties

    if toPick:is("union") then
        for _,key in toPick:components() do pickKey(key) end
    else
        pickKey(toPick)
    end

    if newIndexer then
        picked:setindexer(newIndexer, indexer.writeresult or indexer.readresult)
    end

    return picked
end

export type TablePick<Tble, ToPick> = _TablePick<Tble, ToPick>


--[=[
    Outputs a copy of the input table but with specified properties omitted.

    @param tble { [any]: any } -- The table to omit properties from.
    @param toOmit any -- A union/singeleton of keys to be omitted.
]=]
type function _TableOmit(tble: { [any]: any }, toOmit: any)
    -- We need to convert all string literals to values since all string literal types are equal.
    local function keyAsStringLiteralValue(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else false
        end
        return false
    end

    -- Currently two different string literal types are equal to each other.
    -- So we need to turn all string literal types into values.
    local function componentsStringLiteralsToValues(components)
        for idx,comp in components do
            local asStringLiteral = keyAsStringLiteralValue(comp)
            if asStringLiteral then components[idx] = asStringLiteral end
        end

        return components
    end

    local function componentsStringLiteralsToTypes(components)
        for idx,comp in components do
            if type(comp) == "string" then components[idx] = types.singleton(comp) end
        end
        return components
    end

    local indexer = tble:indexer()
    local indexerIndex = indexer and indexer.index
    local indexerIndexComponents =
        indexer and componentsStringLiteralsToValues(indexerIndex:is("union") and indexerIndex:components() or { indexerIndex })

    local function omitKeyFromProperties(key: any)
        if key:is("singleton") then
            tble:setproperty(key, nil)
        end
    end

    local function omitKeyFromIndexer(key: any)
        local found = table.find(indexerIndexComponents, keyAsStringLiteralValue(key) or key)
        if found then table.remove(indexerIndexComponents, found) end
    end

    local omitKey = indexer and function(key: any) omitKeyFromProperties(key); omitKeyFromIndexer(key) end or omitKeyFromProperties

    if toOmit:is("union") then
        for _,key in toOmit:components() do omitKey(key) end
    else
        omitKey(toOmit)
    end

    if indexer then
        componentsStringLiteralsToTypes(indexerIndexComponents)

        tble:setindexer(
            if #indexerIndexComponents == 1 then
                indexerIndexComponents[1]
            else
                types.unionof(table.unpack(indexerIndexComponents)),
            indexer["writeresult"] or indexer["readresult"]
        )
    end

    return tble
end

export type TableOmit<Tble, ToOmit> = _TableOmit<Tble, ToOmit>


--[=[
    Makes all of the properties of a table optional.

    @param table { [any]: any } -- The table to make partial.
]=]
type function _Partial(tble: { [any]: any })
    local function toPartial(t) return types.unionof(t, types.singleton(nil)) end

    local partial = types.newtable({})

    for key, value in tble:properties() do
        local read, write = value.read, value.write
        local readPartial = toPartial(read)

        partial:setreadproperty(key, readPartial)
        -- The `write == read` comparison is to ensure that the property is not
        -- unnecessarily separated into 2 different read write properties.
        if write then partial:setwriteproperty(key, write == read and readPartial or toPartial(write)) end
    end

    -- Adds a partial version of the indexer to the partial table.
    local indexer = tble:indexer()
    if indexer then
        local indexerResult = indexer.writeresult or indexer.readresult
        partial:setindexer(indexer["index"], toPartial(indexerResult))
    end

    return partial
end

export type Partial<Tble> = _Partial<Tble>


-- TODO: Make indexers read only once luau supports doing so.
--[=[
    Makes all of the properties of a table read only.

    @param tble { [any]: any } -- The table to make read only.
]=]
type function _ReadOnly(tble: { [any]: any })
    local readOnly = types.newtable({})

    for key, value in tble:properties() do
        readOnly:setreadproperty(key, value.read)
    end

    -- Adds the indexer to the read-only table.
    local indexer = tble:indexer()
    local indexerResult = indexer and (indexer["writeresult"] or indexer["readresult"])
    if indexerResult then readOnly:setindexer(indexer["index"], indexerResult) end

    return readOnly
end

export type ReadOnly<Tble> = _ReadOnly<Tble>


--[=[
    Makes all of the properties of a table readable and writable (mutable).

    @param tble { [any]: any } -- The table to make mutable.
]=]
type function _ReadWrite(tble: { [any]: any })
    local readWrite = types.newtable({})

    for key, value in tble:properties() do
            local read, write = value.read, value.write
            local newValue = write or read -- Prioritises the `write` property over the `read`.

            readWrite:setwriteproperty(key, newValue)
            readWrite:setreadproperty(key, newValue)
    end

     -- Adds the indexer to the read-write table.
     local indexer = tble:indexer()
     local indexerResult = indexer and (indexer["writeresult"] or indexer["readresult"])
     if indexerResult then readWrite:setindexer(indexer["index"], indexerResult) end


    return readWrite
end

export type ReadWrite<Tble> = _ReadWrite<Tble>


--[=[
    Useful for combining an intersection of tables into one table. All non-table elements of the intersection will be omitted from the output type.
    NOTE: This type function is not recursive.

    @param tble { [any]: any } -- The table to flatten.
]=]
type function _TableFlatten(tble: { [any]: any })
    if tble:is("table") then return tble end

    -- We need to convert all string literals to values since all string literal types are equal.
    local function ifStringLiteralThenToValue(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else key
        end
        return key
    end

    local function arrayHasType(arr: { any }, type: any)
        for _,t in arr do
            if t == type then return true end
        end
        return false
    end

    local function arrayToUnion(arr: { any })
        local arrLength = #arr
        return if arrLength == 0 then nil elseif arrLength == 1 then arr[1] else types.unionof(table.unpack(arr))
    end

    -- We need to convert all values to types before returning.
    local function arrayConvertValuesToTypes(arr: { any })
        for idx,value in arr do
            if type(value) == "string" then arr[idx] = types.singleton(value) end
        end
        return arr
    end

    if tble:is("intersection") then
        local flattened = types.newtable({})
        local flattenedIndexerIndex, flattenedIndexerReadResult, flattenedIndexerWriteResult = {}, {}, {}

        for compKey, compValue in tble:components() do
            if not compValue:is("table") then continue end

            local compIndexer = compValue:indexer()
            if compIndexer then
                local compIndexerIndex = ifStringLiteralThenToValue(compIndexer.index)
                local compIndexerReadResult = ifStringLiteralThenToValue(compIndexer.readresult)
                local compIndexerWriteResult = ifStringLiteralThenToValue(compIndexer.writeresult)


                -- Adds the index.
                if compIndexerIndex:is("union") then
                    for _,comp in compIndexerIndex:components() do
                        comp = ifStringLiteralThenToValue(comp)
                        if arrayHasType(flattenedIndexerIndex, comp) then continue end
                        table.insert(flattenedIndexerIndex, comp)
                    end

                elseif not arrayHasType(flattenedIndexerIndex, compIndexerIndex) then
                    table.insert(flattenedIndexerIndex, compIndexerIndex)
                end

                -- Adds the read result.
                if type(compIndexerReadResult) ~= "string" and compIndexerReadResult:is("union") then
                    for _,comp in compIndexerReadResult:components() do
                        comp = ifStringLiteralThenToValue(comp)
                        if arrayHasType(flattenedIndexerReadResult, comp) then continue end
                        table.insert(flattenedIndexerReadResult, comp)
                    end

                elseif not arrayHasType(flattenedIndexerReadResult, compIndexerReadResult) then
                    table.insert(flattenedIndexerReadResult, compIndexerReadResult)
                end

                -- Adds the write result.
                if type(compIndexerWriteResult) ~= "string" and compIndexerWriteResult:is("union") then
                    for _,comp in compIndexerWriteResult:components() do
                        comp = ifStringLiteralThenToValue(comp)
                        if arrayHasType(flattenedIndexerWriteResult, comp) then continue end
                        table.insert(flattenedIndexerWriteResult, comp)
                    end

                elseif not arrayHasType(flattenedIndexerWriteResult, compIndexerWriteResult) then
                    table.insert(flattenedIndexerWriteResult, compIndexerWriteResult)
                end
            end

            for key, value in compValue:properties() do
                local read, write = value.read, value.write

                flattened:setreadproperty(key, read)
                -- The `write == read` comparison is to ensure that the property is not
                -- unnecessarily separated into 2 different read write properties.
                if write then flattened:setwriteproperty(key, write == read and read or write) end
            end
        end

        local flattenedIndexerIndexUnion = arrayToUnion(arrayConvertValuesToTypes(flattenedIndexerIndex))
        if flattenedIndexerIndexUnion then
            --local readResultUnion = arrayToUnion(arrayConvertValuesToTypes(flattenedIndexerReadResult))
            local writeResultUnion = arrayToUnion(arrayConvertValuesToTypes(flattenedIndexerWriteResult))

            -- TODO: once luau supports read only indexers then apply the read only indexer as well.
            if writeResultUnion then 
                flattened:setindexer(flattenedIndexerIndexUnion, writeResultUnion)
            end
        end

        return flattened
    end
end

export type TableFlatten<Tble> = _TableFlatten<Tble>


--[=[
    Outputs all values of a table as a union/singleton.

    @param tble { [any]: any } -- The table to get values of.
]=]
type function _ValueOf(tble: { [any]: any })
    local function arrayHasType(arr: { any }, type: any)
        for _,t in arr do
            if t == type then return true end
        end
        return false
    end

    -- We need to convert all string literals to values since all string literal types are equal.
    local function ifStringLiteralThenToValue(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else key
        end
        return key
    end

    -- We need to convert all values to types before returning.
    local function arrayConvertValuesToTypes(arr: { any })
        for idx,value in arr do
            if type(value) == "string" then arr[idx] = types.singleton(value) end
        end
        return arr
    end

    local function arrayToUnion(arr: { any })
        local arrLength = #arr
        return if arrLength == 0 then nil elseif arrLength == 1 then arr[1] else types.unionof(table.unpack(arr))
    end

    local values = {}

    for _,value in tble:properties() do
        local read, write = ifStringLiteralThenToValue(value.read), ifStringLiteralThenToValue(value.write)
        if not arrayHasType(values, read) then table.insert(values, read) end
        if not arrayHasType(values, write) then table.insert(values, write) end
    end

    local indexer = tble:indexer()
    if indexer then
        local readResult, writeResult = ifStringLiteralThenToValue(indexer.readresult), ifStringLiteralThenToValue(indexer.writeresult)
            
        -- Adds the read result.
        if type(readResult) ~= "string" and readResult:is("union") then
            for _,comp in readResult:components() do
                comp = ifStringLiteralThenToValue(comp)
                if arrayHasType(values, comp) then continue end
                table.insert(values, comp)
            end

        elseif not arrayHasType(values, readResult) then
            table.insert(values, readResult)
        end

        -- Adds the write result.
        if type(writeResult) ~= "string" and writeResult then
            if writeResult:is("union") then
                for _,comp in writeResult:components() do
                    comp = ifStringLiteralThenToValue(comp)
                    if arrayHasType(values, comp) then continue end
                    table.insert(values, comp)
                end

            elseif not arrayHasType(values, writeResult) then
                table.insert(values, writeResult)
            end
        end
    end

    return arrayToUnion(arrayConvertValuesToTypes(values))
end

export type ValueOf<Tble> = _ValueOf<Tble>


--[=[
    Converts all string literal keys in a table to be camel case (camelCase).
    NOTE: This type function is not recursive.

    @param tble { [any]: any } -- The table to convert to camel case.
]=]
type function _TableToCamel(tble: { [any]: any })
    local function toCamel(str: string)
        return types.singleton(string.lower(string.sub(str, 1, 1))..string.sub(str, 2, -1))
    end

    local function ifStringLiteralThenToValue(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else key
        end
        return key
    end

    local function arrayToUnion(arr: { any })
        local arrLength = #arr
        return if arrLength == 0 then nil elseif arrLength == 1 then arr[1] else types.unionof(table.unpack(arr))
    end

    local camel = types.newtable()

    for key, value in tble:properties() do
        local key = types.value(key)
        if type(key) ~= "string" then continue end

        local keyToCamel = toCamel(key)
        local read, write = value.read, value.write

        camel:setreadproperty(keyToCamel, read)
        -- The `write == read` comparison is to ensure that the property is not
        -- unnecessarily separated into 2 different read write properties.
        if write then camel:setwriteproperty(keyToCamel, write == read and read or write) end
    end

    local indexer = tble:indexer()

    if indexer then
        local indexerIndex = ifStringLiteralThenToValue(indexer.index)

        -- Converts the indexers index to camel case if it is a string literal.
        if type(indexerIndex) == "string" then
            indexerIndex = toCamel(indexerIndex)

        -- Converts all of the indexers index components to camel case if they are string literals.
        elseif indexerIndex:is("union") then
            local components = indexerIndex:components()
            for idx,comp in components do
                    comp = ifStringLiteralThenToValue(comp)
                    if typeof(comp) == "string" then components[idx] = toCamel(comp) end
            end
            indexerIndex = arrayToUnion(components)
        end

        -- Adds the indexer to the toCamel table.
        -- TODO: once luau supports read-write indexers then add separate read and write indexers.
        local indexerReadResult, indexerWriteResult = indexer.readresult, indexer.writeresult
        camel:setindexer(indexerIndex, indexerWriteResult or indexerReadResult)
    end

    return camel
end

export type TableToCamel<Tble> = _TableToCamel<Tble>


--[=[
    Converts all string literal keys in a table to be pascal case (PascalCase).
    NOTE: This type function is not recursive.

    @param tble { [any]: any } -- The table to convert to pascal case.
]=]
type function _TableToPascal(tble: { [any]: any })
    local function toPascal(str: string)
        return types.singleton(string.upper(string.sub(str, 1, 1))..string.sub(str, 2, -1))
    end

    local function ifStringLiteralThenToValue(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else key
        end
        return key
    end

    local function arrayToUnion(arr: { any })
        local arrLength = #arr
        return if arrLength == 0 then nil elseif arrLength == 1 then arr[1] else types.unionof(table.unpack(arr))
    end

    local pascal = types.newtable()

    for key, value in tble:properties() do
        local key = types.value(key)
        if type(key) ~= "string" then continue end

        local keyToPascal = toPascal(key)
        local read, write = value.read, value.write

        pascal:setreadproperty(keyToPascal, read)
        -- The `write == read` comparison is to ensure that the property is not
        -- unnecessarily separated into 2 different read write properties.
        if write then pascal:setwriteproperty(keyToPascal, write == read and read or write) end
    end

    local indexer = tble:indexer()

    if indexer then
        local indexerIndex = ifStringLiteralThenToValue(indexer.index)

        -- Converts the indexers index to pascal case if it is a string literal.
        if type(indexerIndex) == "string" then
            indexerIndex = toPacal(indexerIndex)

        -- Converts all of the indexers index components to pascal case if they are string literals.
        elseif indexerIndex:is("union") then
            local components = indexerIndex:components()
            for idx,comp in components do
                comp = ifStringLiteralThenToValue(comp)
                if typeof(comp) == "string" then components[idx] = toPascal(comp) end
            end
            indexerIndex = arrayToUnion(components)
        end

        -- Adds the indexer to the toPascal table.
        -- TODO: once luau supports read-write indexers then add separate read and write indexers.
        local indexerReadResult, indexerWriteResult = indexer.readresult, indexer.writeresult
        pascal:setindexer(indexerIndex, indexerWriteResult or indexerReadResult)
    end

    return pascal
end

export type TableToPascal<Tble> = _TableToPascal<Tble>


--[=[
    Removes the indexer from a table type.

    @param tble { [any]: any } -- The table to remove the indexer from.
]=]
type function _TableRemoveIndexer(tble: { [any]: any })
    local newTble = types.newtable({})

    -- Theres no way to remove an indexer from a table type so we
    -- need to create a new table type with the same properties as
    -- the original table.
    for key, value in tble:properties() do
        local read, write = value.read, value.write

        newTble:setreadproperty(key, read)
        -- The `write == read` comparison is to ensure that the property is not
        -- unnecessarily separated into 2 different read write properties.
        if write then newTble:setwriteproperty(key, write == read and read or write) end
    end

    return newTble
end

export type TableRemoveIndexer<Tble> = _TableRemoveIndexer<Tble>


--[=[
    Sets the indexer for a table type.

    @param tble { [any]: any } -- The table to set the indexer for.
    @param keyType any -- The key type for the new indexer.
    @param value any -- The value for the new indexer.
]=]
type function _TableSetIndexer(tble: { [any]: any }, keyType: any, value: any)
    tble:setindexer(keyType, value)
    return tble
end

export type TableSetIndexer<Tble, KeyType, Value> = _TableSetIndexer<Tble, KeyType, Value>


--[=[
    Adds a key to a tables indexer. Makes the indexer a union if not already, or if no indexer exists then one is added.

    @param tble { [any]: any } -- The table to set the indexer for.
    @param keyType any -- The new key type to add to the indexer.
]=]
type function _TableAddIndexerKey(tble: { [any]: any }, keyType: any)
    local indexer = tble:indexer()

    if not indexer then
        tble:setindexer(keyType, types.singleton(nil))
    else
        tble:setindexer(types.unionof(indexer["index"], keyType), indexer["writeresult"] or indexer["readresult"])
    end

    return tble
end

export type TableAddIndexerKey<Tble, KeyType> = _TableAddIndexerKey<Tble, KeyType>
-------------------------------------------------------------------------------------------------------


--> Union ---------------------------------------------------------------------------------------------
--[=[
    Outputs a copy of the input union but only with specified components.

    @param union any -- The union to pick properties from.
    @param toOmit any -- A union/singeleton of components to be picked.
]=]
type function _UnionPick(union: any, toPick: any)
    assert(union:is("union") or union:is("singleton"), "Wrong type! Expected either a union or a singleton.")

    -- We need to convert all string literals to values since all string literal types are equal.
    local function ifStringLiteralThenToValue(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else false
        end
        return false
    end

    local function arrayConvertStringLiteralsToValues(arr: { any })
        for idx,value in arr do
            value = ifStringLiteralThenToValue(value)
            if value then arr[idx] = value end
        end
        return arr
    end

    -- We need to convert all string literal values to types before returning.
    local function arrayConvertStringLiteralsToTypes(arr: { any })
        for idx,value in arr do
            if type(value) == "string" then arr[idx] = types.singleton(value) end
        end
        return arr
    end

    local function arrayToUnion(arr: { any })
        local arrLength = #arr
        return if arrLength == 0 then types.never elseif arrLength == 1 then arr[1] else types.unionof(table.unpack(arr))
    end

    local unionComponents = arrayConvertStringLiteralsToValues(union:components())
    local picked = {}

    local function pick(key: any)
        key = ifStringLiteralThenToValue(key) or key

        -- Make sure duplicates are not picked.
        if table.find(picked, key) then return end

        if table.find(unionComponents, key) then
            table.insert(picked, key)
        end
    end

    if toPick:is("union") then
        for _,comp in toPick:components() do pick(comp) end

    else pick(toPick) end

    return arrayToUnion(arrayConvertStringLiteralsToTypes(picked))
end

export type UnionPick<Union, ToPick> = _UnionPick<Union, ToPick>


--[=[
    Outputs a copy of the input union but with specified components omitted.

    @param union any -- The union to omit properties from.
    @param toOmit any -- A union/singeleton of components to be omitted.
]=]
type function _UnionOmit(union: any, toOmit: any)
    -- We need to convert all string literals to values since all string literal types are equal.
    local function ifStringLiteralThenToValue(key: any)
        if key:is("singleton") then
            local value = types.value(key)
            return if type(value) == "string" then value else key
        end
        return key
    end
    
    -- We need to convert all values to types before returning.
    local function arrayConvertValuesToTypes(arr: { any })
        for idx,value in arr do
            if type(value) == "string" then arr[idx] = types.singleton(value) end
        end
        return arr
    end

    local function arrayToUnion(arr: { any })
        local arrLength = #arr
        return if arrLength == 0 then nil elseif arrLength == 1 then arr[1] else types.unionof(table.unpack(arr))
    end

    local unionComponents = union:components()
    for idx,comp in unionComponents do
        comp = ifStringLiteralThenToValue(comp)
        if type(comp) == "string" then unionComponents[idx] = comp end
    end

    if toOmit:is("union") then
        for _,comp in toOmit:components() do
            local found = table.find(unionComponents, ifStringLiteralThenToValue(comp))
            if found then table.remove(unionComponents, found) end
        end
    else
        local found = table.find(unionComponents, ifStringLiteralThenToValue(toOmit))
        if found then table.remove(unionComponents, found) end
    end

    return arrayToUnion(arrayConvertValuesToTypes(unionComponents))
end

export type UnionOmit<Union, ToOmit> = _UnionOmit<Union, ToOmit>


--[=[
    Useful for combining an intersection of unions/singletons into one union.
    NOTE: This type function is not recursive.

    @param input any -- The unions/singletons to prettify.
]=]
type function _UnionFlatten(input: any)
    if input:is("intersection") then
        local prettified

        local function addToPrettified(value: any)
            if not prettified then prettified = value
            else prettified = types.unionof(prettified, value) end
        end

        for _,inputValue in input:components() do
            if inputValue:is("singleton") then addToPrettified(inputValue)

            elseif inputValue:is("union") then
                for _,unionValue in inputValue:components() do
                    addToPrettified(unionValue)
                end
            end
        end

        return prettified

    else return input end
end

export type UnionFlatten<Input> = _UnionFlatten<Input>
-------------------------------------------------------------------------------------------------------


--> String --------------------------------------------------------------------------------------------
--[=[
    Converts a string to camel case (camelCase).

    @param str string -- The string to convert to camel case.
]=]
type function _StringToCamel(str: string)
    if not str:is("singleton") then return str end

    str = types.value(str)

    if type(str) ~= "string" then return str end

    return types.singleton(string.lower(string.sub(str, 1, 1))..string.sub(str, 2, -1))
end

export type StringToCamel<Str> = _StringToCamel<Str>


--[=[
    Converts a string to pascal case (PascalCase).

    @param str string -- The string to convert to pascal case.
]=]
type function _StringToPascal(str: string)
    if not str:is("singleton") then return str end

    str = types.value(str)

    if type(str) ~= "string" then return str end

    return types.singleton(string.upper(string.sub(str, 1, 1))..string.sub(str, 2, -1))
end

export type StringToPascal<Str> = _StringToPascal<Str>


--[=[
    Converts a string to upper case.

    @param str string -- The string to convert to upper case.
]=]
type function _StringToUpper(str: string)
    if not str:is("singleton") then return str end

    str = types.value(str)

    if type(str) ~= "string" then return str end

    return types.singleton(string.upper(str))
end

export type StringToUpper<Str> = _StringToUpper<Str>


--[=[
    Converts a string to lower case.

    @param str string -- The string to convert to lower case.
]=]
type function _StringToLower(str: string)
    if not str:is("singleton") then return str end

    str = types.value(str)

    if type(str) ~= "string" then return str end

    return types.singleton(string.lower(str))
end

export type StringToLower<Str> = _StringToLower<Str>


--[=[
    Replaces part of a string with another string.

    @param str string -- The string to replace in.
    @param replace string -- The string pattern to replace.
    @param replaceWith string -- The replacement string.
]=]
type function _StringReplace(str: string, replace: string, replaceWith: string)
    if not str:is("singleton") then return str end
    if not replace:is("singleton") then return str end
    if not replaceWith:is("singleton") then return str end

    str, replace, replaceWith = types.value(str), types.value(replace), types.value(replaceWith)

    if type(str) ~= "string" then return str end
    if type(replace) ~= "string" then return str end
    if type(replaceWith) ~= "string" then return str end

    return types.singleton(string.gsub(str, replace, replaceWith))
end

export type StringReplace<Str, Replace, ReplaceWith> = _StringReplace<Str, Replace, ReplaceWith>


--[=[
    Returns true if the string is a string literal.

    @param str string -- The string to test to see if its a string literal.
]=]
type function _StringIsLiteral(str: string)
    if str:is("singleton") then
        return types.singleton(if type(types.value(str)) == "string" then true else false)
    end

    return types.singleton(false)
end

export type StringIsLiteral<Str> = _StringIsLiteral<Str>
-------------------------------------------------------------------------------------------------------


--> Functions -----------------------------------------------------------------------------------------
--[=[
    Outputs the arguments of a function.

    @param fn (...any) -> ...any -- The function to get arguments for.
]=]
type function _Arguments(fn: (...any) -> ...any)
    if not fn:is("function") then return fn end
    
    local arguments = fn:parameters()
    local argumentsHead, argumentsTail = arguments.head, arguments.tail

    local argumentsType = types.newtable()

    if argumentsHead then
        for idx,arg in argumentsHead do
            argumentsType:setproperty(types.singleton(tostring(idx)), arg)
        end
    end

    if argumentsTail then
        argumentsType:setproperty(types.singleton("Tail"), argumentsTail)
    end

    return argumentsType
end

export type Arguments<Fn> = _Arguments<Fn>


--[=[
    Sets the arguments for a function.

    @param fn (...any) -> ...any -- The function to set arguments for.
    @param args { [`{number}`]: any, Tail: any } -- The new args for the function.
]=]
type function _SetArguments(fn: (...any) -> ...any, args: { [string]: any, Tail: any })
    assert(args:is("table"), "The new arguments needs to be a table!")

    local argsArray = {}
    for idx,arg in args:properties() do
        local idxNum = tonumber(types.value(idx))
        if not idxNum then continue end
        argsArray[idxNum] = arg.write or arg.read
    end

    local argsTail = args:readproperty(types.singleton("Tail"))
    fn:setparameters(argsArray, argsTail)

    return fn
end

export type SetArguments<Fn, Args> = _SetArguments<Fn, Args>


--[=[
    Outputs the return types of a function.

    @param fn (...any) -> ...any -- The function to get return types for.
]=]
type function _Returns(fn: (...any) -> ...any)
    if not fn:is("function") then return fn end

    local returns = fn:returns()
    local returnsHead, returnsTail = returns.head, returns.tail

    local returnsType = types.newtable()

    if returnsHead then
        for idx,arg in returnsHead do
            returnsType:setproperty(types.singleton(tostring(idx)), arg)
        end
    end

    if returnsTail then
        returnsType:setproperty(types.singleton("Tail"), returnsTail)
    end

    return returnsType
end

export type Returns<Fn> = _Returns<Fn>


--[=[
    Sets the return types for a function.

    @param fn (...any) -> ...any -- The function to set return types for.
    @param returns { [`{number}`]: any, Tail: any } -- The new return types for the function.
]=]
type function _SetReturns(fn: (...any) -> ...any, returns: { [string]: any, Tail: any })
    assert(returns:is("table"), "The new return type needs to be a table!")

    local returnsArray = {}
    for idx,arg in returns:properties() do
        local idxNum = tonumber(types.value(idx))
        if not idxNum then continue end
        returnsArray[idxNum] = arg.write or arg.read
    end

    local returnsTail = returns:readproperty(types.singleton("Tail"))
    fn:setreturns(returnsArray, returnsTail)

    return fn
end

export type SetReturns<Fn, Returns> = _SetReturns<Fn, Returns>
-------------------------------------------------------------------------------------------------------


--> Miscellaneous -------------------------------------------------------------------------------------
--[=[
    Throws a type error if the first type does not equal the second.
    NOTE: This type treats all string literals inside of tables as being of the same type.

    @param expect any -- The type to be compared.
    @param toBe any -- The type you want to compare `expect` to.
]=]
type function _Expect<A, B>(expect: A, toBe: B)
    local expectAsValue = expect:is("singleton") and types.value(expect) or nil
    local toBeAsValue = toBe:is("singleton") and types.value(toBe) or nil

    local toBeAsValueType, expectAsValueType = type(expectAsValue), type(toBeAsValue)

    if (
        (toBeAsValueType == "boolean" and expectAsValueType == "boolean") or
        (toBeAsValueType == "string" and expectAsValueType == "string")
    ) then
        if toBeAsValue ~= expectAsValue then return error("expection error!") end

    else
        if expect ~= toBe then return error("expection error!") end
    end

    return expect
end

export type Expect<Exp, ToBe> = _Expect<Exp, ToBe>
-------------------------------------------------------------------------------------------------------


return nil