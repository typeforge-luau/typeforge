--!strict


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


--> Dictionary ----------------------------------------------------------------------------------------
--[=[
    Outputs a copy of the input dictionary but only with specified properties.

    @param dict { [any]: any } -- The dictionary to pick properties from.
    @param toPick any -- A union/singeleton of properties to be picked.
]=]
type function _DictionaryPick(dict: { [any]: any }, toPick: any)
    -- since `:writeproperty` throws an error instead of returning nil if it doesn't exist
    -- we need to use this workaround.
    local dictReadProps, dictWriteProps = types.newtable({}), types.newtable({})
    for key, value in dict:properties() do
        if value.read then dictReadProps:setwriteproperty(key, value.read) end
        if value.write then dictWriteProps:setwriteproperty(key, value.write) end
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

    local dictIndexer, newDictIndexer = dict:indexer()
    local dictIndexerIndex = dictIndexer and dictIndexer.index
    local dictIndexerIndexComponents =
        dictIndexer and componentsStringLiteralsToValues(dictIndexerIndex:is("union") and dictIndexerIndex:components() or { dictIndexerIndex })

    local picked = types.newtable()

    local function pickKeyFromProperties(key: any)
        if key:is("singleton") then
            local read, write = dictReadProps:writeproperty(key), dictWriteProps:writeproperty(key)
            picked:setreadproperty(key, read)
            -- The `write == read` comparison is to ensure that the property is not
            -- unnecessarily separated into 2 different read write properties.
            if write then picked:setwriteproperty(key, write == read and read or write) end
        end
    end

    local function pickKeyFromIndexer(key: any)
        if table.find(dictIndexerIndexComponents, keyAsStringLiteral(key) or key) then
            if newDictIndexer == nil then newDictIndexer = key
            else newDictIndexer = types.unionof(newDictIndexer, key) end
        end
    end

    local pickKey = dictIndexer and function(key: any) pickKeyFromProperties(key); pickKeyFromIndexer(key) end or pickKeyFromProperties

    if toPick:is("union") then
        for _,key in toPick:components() do pickKey(key) end
    else
        pickKey(toPick)
    end

    if newDictIndexer then
        local dictIndexerResult = dictIndexer.writeresult or dictIndexer.readresult

        picked:setindexer(newDictIndexer, dictIndexerResult)
    end

    return picked
end

export type DictionaryPick<Dict, ToPick> = _DictionaryPick<Dict, ToPick>


--[=[
    Outputs a copy of the input dictionary but with specified properties omitted.

    @param dict { [any]: any } -- The dictionary to omit properties from.
    @param toOmit any -- A union/singeleton of keys to be omitted.
]=]
type function _DictionaryOmit(dict: { [any]: any }, toOmit: any)
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

    local dictIndexer = dict:indexer()
    local dictIndexerIndex = dictIndexer and dictIndexer.index
    local dictIndexerIndexComponents =
        dictIndexer and componentsStringLiteralsToValues(dictIndexerIndex:is("union") and dictIndexerIndex:components() or { dictIndexerIndex })

    local function omitKeyFromProperties(key: any)
        if key:is("singleton") then
            dict:setproperty(key, nil)
        end
    end

    local function omitKeyFromIndexer(key: any)
        local found = table.find(dictIndexerIndexComponents, keyAsStringLiteralValue(key) or key)
        if found then table.remove(dictIndexerIndexComponents, found) end
    end

    local omitKey = dictIndexer and function(key: any) omitKeyFromProperties(key); omitKeyFromIndexer(key) end or omitKeyFromProperties

    if toOmit:is("union") then
        for _,key in toOmit:components() do omitKey(key) end
    else
        omitKey(toOmit)
    end

    if dictIndexer then
        componentsStringLiteralsToTypes(dictIndexerIndexComponents)

        dict:setindexer(
            if #dictIndexerIndexComponents == 1 then
                dictIndexerIndexComponents[1]
            else
                types.unionof(table.unpack(dictIndexerIndexComponents)),
            dictIndexer["writeresult"] or dictIndexer["readresult"]
        )
    end

    return dict
end

export type DictionaryOmit<Dict, ToOmit> = _DictionaryOmit<Dict, ToOmit>


--[=[
    Makes all of the properties of a dictionary optional.

    @param dict { [any]: any } -- The dictionary to make partial.
]=]
type function _Partial(dict: { [any]: any })
    local function toPartial(t) return types.unionof(t, types.singleton(nil)) end

    local partial = types.newtable({})

    for key, value in dict:properties() do
        local read, write = value.read, value.write
        local readPartial = toPartial(read)

        partial:setreadproperty(key, readPartial)
        -- The `write == read` comparison is to ensure that the property is not
        -- unnecessarily separated into 2 different read write properties.
        if write then partial:setwriteproperty(key, write == read and readPartial or toPartial(write)) end
    end

    -- Adds a partial version of the indexer to the partial table.
    local indexer = dict:indexer()
    if indexer then
        local indexerResult = indexer.writeresult or indexer.readresult
        partial:setindexer(indexer["index"], toPartial(indexerResult))
    end

    return partial
end

export type Partial<Dict> = _Partial<Dict>


-- TODO: Make indexers read only once luau supports doing so.
--[=[
    Makes all of the properties of a dictionary read only.

    @param dict { [any]: any } -- The dictionary to make read only.
]=]
type function _ReadOnly(dict: { [any]: any })
    local readOnly = types.newtable({})

    for key, value in dict:properties() do
        readOnly:setreadproperty(key, value.read)
    end

    -- Adds the indexer to the read-only table.
    local indexer = dict:indexer()
    local indexerResult = indexer and (indexer["writeresult"] or indexer["readresult"])
    if indexerResult then readOnly:setindexer(indexer["index"], indexerResult) end

    return readOnly
end

export type ReadOnly<Dict> = _ReadOnly<Dict>


--[=[
    Makes all of the properties of a dictionary readable and writable (mutable).

    @param dict { [any]: any } -- The dictionary to make mutable.
]=]
type function _ReadWrite(dict: { [any]: any })
    local readWrite = types.newtable({})

    for key, value in dict:properties() do
            local read, write = value.read, value.write
            local newValue = write or read -- Prioritises the `write` property over the `read`.

            readWrite:setwriteproperty(key, newValue)
            readWrite:setreadproperty(key, newValue)
    end

     -- Adds the indexer to the read-write table.
     local indexer = dict:indexer()
     local indexerResult = indexer and (indexer["writeresult"] or indexer["readresult"])
     if indexerResult then readWrite:setindexer(indexer["index"], indexerResult) end


    return readWrite
end

export type ReadWrite<Dict> = _ReadWrite<Dict>


--[=[
    Useful for combining an intersection of dictionaries into one dictionary. All non-dictionary elements of the intersection will be omitted from the output type.
    NOTE: This type function is not recursive.

    @param dict { [any]: any } -- The dictionary to flatten.
]=]
type function _DictionaryFlatten(dict: { [any]: any })
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

    if dict:is("table") then return dict

    elseif dict:is("intersection") then
        local flattened = types.newtable({})
        local flattenedIndexerIndex, flattenedIndexerReadResult, flattenedIndexerWriteResult = {}, {}, {}

        for compKey, compValue in dict:components() do
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

export type DictionaryFlatten<Dict> = _DictionaryFlatten<Dict>


--[=[
    Outputs all values of a dictionary as a union/singleton.

    @param dict { [any]: any } -- The dictionary to get values of.
]=]
type function _ValueOf(dict: { [any]: any })
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

    for _,value in dict:properties() do
        local read, write = ifStringLiteralThenToValue(value.read), ifStringLiteralThenToValue(value.write)
        if not arrayHasType(values, read) then table.insert(values, read) end
        if not arrayHasType(values, write) then table.insert(values, write) end
    end

    local indexer = dict:indexer()
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

export type ValueOf<Dict> = _ValueOf<Dict>


--[=[
    Converts all keys in a dictionary to be camel case (camelCase).
    NOTE: This type function is not recursive.

    @param dict { [any]: any } -- The dictionary to convert to camel case.
]=]
type function _DictionaryToCamel(dict: { [any]: any })
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

    for key, value in dict:properties() do
        local key = types.value(key)
        if type(key) ~= "string" then continue end

        local keyToCamel = toCamel(key)
        local read, write = value.read, value.write

        camel:setreadproperty(keyToCamel, read)
        -- The `write == read` comparison is to ensure that the property is not
        -- unnecessarily separated into 2 different read write properties.
        if write then camel:setwriteproperty(keyToCamel, write == read and read or write) end
    end

    local indexer = dict:indexer()

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

export type DictionaryToCamel<Dict> = _DictionaryToCamel<Dict>


--[=[
    Converts all keys in a dictionary to be pascal case (PascalCase).
    NOTE: This type function is not recursive.

    @param dict { [any]: any } -- The dictionary to convert to pascal case.
]=]
type function _DictionaryToPascal(dict: { [any]: any })
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

    for key, value in dict:properties() do
        local key = types.value(key)
        if type(key) ~= "string" then continue end

        local keyToPascal = toPascal(key)
        local read, write = value.read, value.write

        pascal:setreadproperty(keyToPascal, read)
        -- The `write == read` comparison is to ensure that the property is not
        -- unnecessarily separated into 2 different read write properties.
        if write then pascal:setwriteproperty(keyToPascal, write == read and read or write) end
    end

    local indexer = dict:indexer()

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

export type DictionaryToPascal<Dict> = _DictionaryToPascal<Dict>
-------------------------------------------------------------------------------------------------------


--> Table ---------------------------------------------------------------------------------------------
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
    Outputs a copy of the input union but with specified components omitted.

    @param union any -- The union to omit properties from.
    @param toOmit any -- A union/singeleton of components to be omitted.
]=]
type function _UnionOmit(union: { [any]: any }, toOmit: any)
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


--> Miscellaneous -------------------------------------------------------------------------------------
--[=[
    Throws a type error if the first type does not equal the second.
    NOTE: This type treats all string literals inside of tables as being of the same type.

    @param expect any -- The type to be compared.
    @param toBe any -- The type you want to compare `expect` to.
]=]
type function _Expect<A, B>(expect: A, toBe: B)
    local toBeAsValue = toBe:is("singleton") and types.value(toBe) or nil
    local expectAsValue = expect:is("singleton") and types.value(expect) or nil

    local toBeAsValueType, expectAsValueType = type(toBeAsValue), type(expectAsValue)

    if (
        (toBeAsValueType == "boolean" or expectAsValueType == "boolean") or
        (toBeAsValueType == "string" or expectAsValueType == "string")
    ) then
        if toBeAsValue ~= expectAsValue then return error("expection error!") end

    else
        if expect ~= toBe then return error("expection error!") end
    end

    return expect
end

export type Expect<Exp, ToBe> = _Expect<Exp, ToBe>
-------------------------------------------------------------------------------------------------------






-------------------------------------------------------------------------------------------------------
--> TESTS ---------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------






--> Boolean Operations --------------------------------------------------------------------------------
-- Not -----------------------------------------------
-- Test A: A Not operation of `true`.
type Not_TestA = Expect<Not<true>, false>

-- Test B: A Not operation of a truthy literal.
type Not_TestB = Expect<Not<"i am a truthy literal">, false>

-- Test C: A Not operation of `true` and `false`.
type Not_TestC = Expect<Not<true | false>, false | true>

-- Test D: A Not operation of `false` and a truthy literal.
type Not_TestD = Expect<Not<false | "i am a truthy literal">, true | false>
------------------------------------------------------


-- And -----------------------------------------------
-- Test A: An And Operation of `true` and `true`.
type And_TestA = Expect<And<true | true>, true>

-- Test B: An And Operation of `true` and a truthy string literal.
type And_TestB = Expect<And<true | "i am a truthy literal">, true>

-- Test C: An And Operation of 2 truthy string literal.
type And_TestC = Expect<And<"i am a truthy literal" | "i am a truthy literal">, true>

-- Test D: An And Operation of `false` and `false`.
type And_TestD = Expect<And<false | false>, false>

-- Test E: An And Operation of `true` and `false`.
type And_TestE = Expect<And<true | false>, false>

-- Test F: An And Operation of `false` and a truthy string literal.
type And_TestF = Expect<And<false | "i am a truthy literal">, false>

-- Test G: An And Operation of `true`.
type And_TestG = Expect<And<true>, true>

-- Test H: An And Operation of `false`.
type And_TestH = Expect<And<false>, false>

-- Test I: An And Operation of a truthy string literal.
type And_TestI = Expect<And<"i am a truthy literal">, true>
------------------------------------------------------


-- Or ------------------------------------------------
-- Test A: An Or Operation of `true` and `true`.
type Or_TestA = Expect<Or<true | true>, true>

-- Test B: An Or Operation of `true` and a truthy string literal.
type Or_TestB = Expect<Or<true | "i am a truthy literal">, true>

-- Test C: An Or Operation of 2 truthy string literal.
type Or_TestC = Expect<Or<"i am a truthy literal" | "i am a truthy literal">, true>

-- Test D: An Or Operation of `false` and `false`.
type Or_TestD = Expect<Or<false | false>, false>

-- Test E: An Or Operation of `true` and `false`.
type Or_TestE = Expect<Or<true | false>, true>

-- Test F: An Or Operation of `false` and a truthy string literal.
type Or_TestF = Expect<Or<false | "i am a truthy literal">, true>

-- Test G: An Or Operation of `true`.
type Or_TestG = Expect<Or<true>, true>

-- Test H: An Or Operation of `false`.
type Or_TestH = Expect<Or<false>, false>

-- Test I: An Or Operation of a truthy string literal.
type Or_TestI = Expect<Or<"i am a truthy literal">, true>
------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> Dictionary ----------------------------------------------------------------------------------------
-- DictionaryPick ------------------------------------------
-- Test A: Picking 1 string literal property from a dictionary.
type DictionaryPick_TestA = Expect<
DictionaryPick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    { Name: string }
>

-- Test B: Picking multiple string literal properties from a dictionary.
type DictionaryPick_TestB = Expect<
    DictionaryPick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    { Name: string, Age: number }
>

-- Test C: Picking 1 indexer component from a dictionary.
type DictionaryPick_TestC = Expect<
    DictionaryPick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    TableSetIndexer<{}, "hello", any>
>

-- Test D: Picking multiple indexer components from a dictionary.
type DictionaryPick_TestD = Expect<
    DictionaryPick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    TableSetIndexer<{}, "hello" | string, any>
>

-- Test E: Picking multiple indexer components and properties from a dictionary.
type DictionaryPick_TestE = Expect<
    DictionaryPick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    TableSetIndexer<{ Name: string, Age: number }, "hello" | string, any>
>


-- Test F: Picking a property and indexer of the same string literal.
type DictionaryPick_TestF = Expect<
    DictionaryPick<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    TableSetIndexer<{ Age: number }, "Age", any>
>
------------------------------------------------------


-- DictionaryOmit ------------------------------------------
-- Test A: Omitting 1 string literal property from a dictionary.
type DictionaryOmit_TestA = Expect<
    DictionaryOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    TableSetIndexer<{ Age: number }, string | "hello" | "lol", any>
>

-- Test B: Omitting multiple string literal properties from a dictionary.
type DictionaryOmit_TestB = Expect<
    DictionaryOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    TableSetIndexer<{ }, string | "hello" | "lol", any>
>

-- Test C: Omitting 1 indexer component from a dictionary.
type DictionaryOmit_TestC = Expect<
    DictionaryOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    TableSetIndexer<{ Name: string, Age: number }, string | "lol", any>
>

-- Test D: Omitting multiple indexer components from a dictionary.
type DictionaryOmit_TestD = Expect<
    DictionaryOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    TableSetIndexer<{ Name: string, Age: number }, "lol", any>
>

-- Test E: Omitting multiple indexer components and properties from a dictionary.
type DictionaryOmit_TestE = Expect<
    DictionaryOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    TableSetIndexer<{}, "lol", any>
>

-- Test F: Picking a property and indexer of the same string literal.
type DictionaryOmit_TestF = Expect<
    DictionaryOmit<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    TableSetIndexer<{ Name: string }, string | "hello" | "lol", any>
>
------------------------------------------------------


-- Partial -------------------------------------------
-- Test A: Making a dictionary partial without an indexer partial.
type Partial_TestA = Expect<
    Partial<{ Name: string, Age: number }>,
    { Name: string?, Age: number? }
>

-- Test B: Making a dictionary partial with an indexer partial.
type Partial_TestB = Expect<
    Partial<{ Name: string, Age: number, [string]: any }>,
    { Name: string?, Age: number?, [string]: any? }
>
------------------------------------------------------


-- ReadOnly ------------------------------------------
-- Test A: Making a dictionary read only.
type ReadOnly_TestA = Expect<
    ReadOnly<{ Name: string, Age: number }>,
    { read Name: string, read Age: number }
>

-- Test B: Making a dictionary with an indexer read only.
-- TODO: Once luau supports read-only indexers then uncomment the `read` statements.
type ReadOnly_TestB = Expect<
    ReadOnly<{ Name: string, Age: number, [string]: any }>,
    { read Name: string, read Age: number, --[[read]] [string]: any }
>
------------------------------------------------------


-- ReadWrite ------------------------------------------
-- Test A: Making a dictionary read-write.
type ReadWrite_TestA = Expect<
    ReadWrite<{ Name: string, Age: number }>,
    { Name: string, Age: number }
>

-- Test B: Making a dictionary with an indexer read-write.
-- TODO: Once luau supports read-only indexers then uncomment the `read` statements.
type ReadWrite_TestB = Expect<
    ReadWrite<{ read Name: string, read Age: number, --[[read]] [string]: any }>,
    { Name: string, Age: number, [string]: any }
>
------------------------------------------------------


-- DictionaryFlatten ---------------------------------------
-- Test A: Flattening 1 dictionary.
type DictionaryFlatten_TestA = Expect<
    DictionaryFlatten<{ Name: string }>,
    { Name: string }
>

-- Test B: Flattening an intersection of 3 dictionaries.
type DictionaryFlatten_TestB = Expect<
    DictionaryFlatten<{ Name: string } & { Age: string } & { Id: number }>,
    { Name: string, Age: string, Id: number }
>

-- Test C: Flattening an intersection of dictionaries where 1 of them has an indexer with only one component.
type DictionaryFlatten_TestC = Expect<
    DictionaryFlatten<{ Name: string } & { [string]: any }>,
    { Name: string, [string]: any }
>

-- Test D: Flattening an intersection of dictionaries where 1 of them has an indexer with multiple components.
type DictionaryFlatten_TestD = Expect<
    DictionaryFlatten<{ Name: string } & { [string | "hello" | number | "foo"]: any }>,
    { Name: string, [string | "hello" | number | "foo"]: any }
>

-- Test E: Flattening an intersection of dictionaries where both of them have the same indexer.
type DictionaryFlatten_TestE = Expect<
    DictionaryFlatten<{ Name: string, [string]: number } & { [string]: number }>,
    { Name: string, [string]: number }
>

-- Test F: Flattening an intersection of dictionaries where both of them have 2 unique indexers
-- (neither of their index's contain overlapping types, and neither of their result's contain overlapping types).
-- TODO: Add an edge case to `Expect` for comparing tables as the 2 tables below throw an error despite being identical.
--[[type DictionaryFlatten_TestF = Expect<
    DictionaryFlatten<{ Name: string, [string | "first"]: number } & { [number | "second"]: any }>,
    { Name: string, [string | number | "first" | "second"]: number | any }
>]]

-- Test G: Flattening an intersection of dictionaries where both of them have 2 indexers which overlap.
-- TODO: Add an edge case to `Expect` for comparing tables as the 2 tables below throw an error despite being identical.
--[[type DictionaryFlatten_TestG = Expect<
    DictionaryFlatten<{ Name: string, [string | "first"]: number } & { [number | "second" | number]: any | number }>,
    { Name: string, [string | number | "first" | "second"]: number | any }
>]]
------------------------------------------------------


-- ValueOf -------------------------------------------
-- Test A: Gets values of a dictionary with no literal values of different types.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestA = Expect<
    ValueOf<{ Name: string, Age: number }>,
    number | string
>]]

-- Test B: Gets values of a dictionary with no literal values of the same type.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestB = Expect<
    ValueOf<{ Name: string, Age: string }>,
    string
>]]

-- Test C: Gets values of a dictionary with literal values.
type ValueOf_TestC = Expect<
    ValueOf<{ Name: "Bob", Age: "54" }>,
    "54" | "Bob"
>

-- Test D: Gets values of a dictionary with indexer with no literal values.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestD = Expect<
    ValueOf<{ Name: string, Age: number, [string]: boolean }>,
    string | number | boolean
>]]

-- Test E: Gets values of a dictionary with indexer with literal values.
type ValueOf_TestE = Expect<
    ValueOf<{ Name: "Bob", Age: "54", [string]: "false" }>,
    "54" | "Bob" | "false"
>

-- Test F: Gets values of a dictionary with indexer - a mix of literal and none-literal values.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestF = Expect<
    ValueOf<{ Name: "Bob", Age: number, [string]: "false" }>,
    "Bob" | "false" | number
>]]
------------------------------------------------------


-- DictionaryToCamel ---------------------------------------
-- Test A: Converts a table with no indexer to camel case.
type DictionaryToCamel_TestA = Expect<
    DictionaryToCamel<{ Name: string, Age: number }>,
    { name: string, age: number }
>

-- Test B: Converts a table with a string non-literal indexer to camel case.
type DictionaryToCamel_TestB = Expect<
    DictionaryToCamel<{ Name: string, Age: number, [string]: number }>,
    { name: string, age: number, [string]: number }
>

-- Test C: Converts a table with a string literal indexer to camel case.
type DictionaryToCamel_TestC = Expect<
    DictionaryToCamel<{ Name: string, Age: number, [string | "Id"]: number }>,
    { name: string, age: number, [string | "id"]: number }
>
------------------------------------------------------


-- DictionaryToPascal ---------------------------------------
-- Test A: Converts a table with no indexer to pascal case.
type DictionaryToPascal_TestA = Expect<
    DictionaryToPascal<{ name: string, age: number }>,
    { Name: string, Age: number }
>

-- Test B: Converts a table with a string non-literal indexer to pascal case.
type DictionaryToPascal_TestB = Expect<
    DictionaryToPascal<{ name: string, age: number, [string]: number }>,
    { Name: string, Age: number, [string]: number }
>

-- Test C: Converts a table with a string literal indexer to pascal case.
type DictionaryToPascal_TestC = Expect<
    DictionaryToPascal<{ name: string, age: number, [string | "id"]: number }>,
    { Name: string, Age: number, [string | "Id"]: number }
>
------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> Table ---------------------------------------------------------------------------------------------
-- TableRemoveIndexer --------------------------------
-- TestA: Removes indexer from table.
type TableRemoveIndexer_TestA = Expect<TableRemoveIndexer<{ [string]: number }>, {}>
------------------------------------------------------


-- TableSetIndexer -----------------------------------
-- TestA: Sets indexer for a table.
type TableSetIndexer_TestA = Expect<TableSetIndexer<{ }, string, number>, { [string]: number }>
------------------------------------------------------


-- TableAddIndexerKey --------------------------------
-- TestA: Adds a key to the indexer of an empty table.
type TableAddIndexerKey_TestA = Expect<TableAddIndexerKey<{ }, string>, { [string]: nil }>


-- TestB: Adds a key to the existing indexer of a table.
-- TODO: Add an edge case to `Expect` for comparing tables as the 2 tables below throw an error despite being identical.
--type TableAddIndexerKey_TestB = Expect<TableAddIndexerKey<{ [number]: boolean }, string>, { [string | number]: boolean }>
------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> Union ---------------------------------------------------------------------------------------------
-- UnionOmit ------------------------------------------
-- TestA: Omits one non-literal type from a union.
type UnionOmit_TestA = Expect<
    UnionOmit<string | number | "foo" | "bar", string>,
    number | "foo" | "bar"
>

-- TestB: Omits multiple non-literal types from a union.
type UnionOmit_TestB = Expect<
    UnionOmit<string | number | "foo" | "bar", string | number>,
    "foo" | "bar"
>

-- TestC: Omits 1 literal type from a union.
type UnionOmit_TestC = Expect<
    UnionOmit<string | number | "foo" | "bar", "foo">,
    string | number | "bar"
>

-- TestD: Omits multiple literal types from a union.
type UnionOmit_TestD = Expect<
    UnionOmit<string | number | "foo" | "bar", "foo" | "bar">,
    string | number
>
-------------------------------------------------------


-- UnionFlatten ---------------------------------------
-- TestA: Flattens a union.
-- TODO: Add an edge case to `Expect` for comparing unions as the 2 tables below throw an error despite being identical.
--[[type UnionFlatten_TestA = Expect<
UnionFlatten<((string | "foo") & (number | "bar"))>,
    string | "foo" | number | "bar"
>]]
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> String --------------------------------------------------------------------------------------------
-- StringToPascal -------------------------------------
-- TestA: Converts string literal to pascal case.
type StringToPascal_TestA = Expect<StringToPascal<"name">, "Name"> 

-- TestB: Converts invalid type to pascal case.
type StringToPascal_TestB = Expect<StringToPascal<boolean>, boolean> 
-------------------------------------------------------


-- StringToCamel --------------------------------------
-- TestA: Converts string literal to camel case.
type StringToCamel_TestA = Expect<StringToCamel<"Name">, "name"> 

-- TestB: Converts invalid type to camel case.
type StringToCamel_TestB = Expect<StringToCamel<boolean>, boolean> 
-------------------------------------------------------


-- StringReplace --------------------------------------
-- TestA: Replaces string.
type StringReplace_TestA = Expect<StringReplace<"Wolf", "f$", "ves">, "Wolves"> 

-- TestB: Tries to replace invalid types.
type StringReplace_TestB = Expect<StringReplace<boolean, string, number>, boolean> 
-------------------------------------------------------


-- StringIsLiteral ------------------------------------
-- TestA: Tests to see if a string literal is a string literal.
type StringIsLiteral_TestA = Expect<StringIsLiteral<"Hello">, true> 

-- TestB: Tests to see if a string non-literal is a string literal.
type StringIsLiteral_TestB = Expect<StringIsLiteral<string>, false>

-- TestC: Tests to see if an invalid type is a string literal.
type StringIsLiteral_TestC = Expect<StringIsLiteral<boolean>, false> 
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------


return nil