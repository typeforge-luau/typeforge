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


--> Helper Type Functions -----------------------------------------------------------------------------
type function _assertIs(input: any, argName: string, toAssert: string)
    assert(input:is(toAssert), `Expected the type argument \`{argName}\` to be of type \`{toAssert}\``)
end

type function _assertIsMessage(argName: string, toAssert: string)
    return `Expected the type argument \`{argName}\` to be of type \`{toAssert}\``
end


type function _safeIs(input: any, isType: any)
    if typeof(input) ~= "userdata" then return false end

    local is = input.is
    if not is then return false end
    return is(input, isType)
end

type function _singletonToValue(input: any)
    if _safeIs(input, "singleton") then return input:value() end
    return input
end

type function _typeToValue(input: any)
    return
        if input == types.string then "string"
        elseif input == types.number then "number"
        elseif input == types.boolean then "boolean"
        else input
end

type function _valueToSingleton(input: any)
    if typeof(input) == "userdata" and (input.is and input.value) then return input end
    return types.singleton(input)
end


type function _arrayToUnion(arr: { any })
    local arrLength = #arr
    return if arrLength == 0 then types.never elseif arrLength == 1 then arr[1] else types.unionof(table.unpack(arr))
end

type function _arrayToIntersection(arr: { any })
    local arrLength = #arr
    return if arrLength == 0 then types.never elseif arrLength == 1 then arr[1] else types.intersectionof(table.unpack(arr))
end

type function _arrayOmit(arr: { any }, toOmit: any)
    local found = table.find(arr, toOmit)
    if found then table.remove(arr, found) end
    return arr
end

type function _arraySingletonsToValues(input: any)
    for idx, comp in input do input[idx] = _singletonToValue(comp) end
    return input
end

type function _arrayValuesToSingletons(input: any)
    for idx, comp in input do input[idx] = _valueToSingleton(comp) end
    return input
end

type function _arrayHasType(input: { any }, t: any)
    for _, value in input do
        if _singletonToValue(Equals(value, t)) then return true end
    end
    return false
end


type function _tableSetProperty(input: { [any]: any }, key: any, read: any, write: any)
    input:setreadproperty(key, read)
    -- The `write == read` comparison is to ensure that the property is not
    -- unnecessarily separated into 2 different read write properties.
    if write then input:setwriteproperty(key, write == read and read or write) end
end

type function _tableMap(input: { any }, fn: (item: any, idx: number) -> ...any)
    local output = table.create(#input)
    for idx, item in input do output[idx] = fn(item, idx) end
    return output
end

type function _tableFindWriteValue(input: { [any]: any }, writeKey: any)
    writeKey = _singletonToValue(writeKey)

    for key, value in input:properties() do
        if _singletonToValue(key) == writeKey then return value.write end
    end
end

type function _tableIsEmpty(input: { [any]: any })
    for _ in input:properties() do return false end
    return true
end

type function _tableInsertMany(input: { [any]: any }, toInsert: { any })
    for _,value in toInsert do table.insert(input, value) end
end

type function _tablePropsLength(input: { [any]: any })
    local length = 0
    for _ in input:properties() do length += 1 end
    return length
end


type function _combineToUnion(one: any?, two: any?)
    if one == types.never then one = nil end
    if two == types.never then two = nil end

    if not one and not two then return types.never end
    if one and not two then return one end
    if two and not one then return two end

    return types.unionof(one, two)
end

type function _combineToIntersection(one: any?, two: any?)
    if one == types.never then one = nil end
    if two == types.never then two = nil end

    if not one and not two then return types.never end
    if one and not two then return one end
    if two and not one then return two end

    return types.intersectionof(one, two)
end


type function _toPartial(input: any)
    return _combineToUnion(input, types.singleton(nil))
end


type function _keyof(input: { [any]: any })
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = {}
    for key in TableFlatten(input):properties() do table.insert(output, key) end
    return _arrayToUnion(output)
end


type function _propsLength(input: { [any]: any })
    local length = 0
    for _ in input do length += 1 end
    return length
end

type function _tableExtendsTable(inputA: { [any]: any }, inputB: { [any]: any })
    local inputAProps, inputBProps = inputA:properties(), inputB:properties()

    if _propsLength(inputAProps) ~= _propsLength(inputBProps) then return false end

    -- since `:writeproperty` throws an error instead of returning nil if it doesn't exist
    -- we need to use this workaround.
    local inputBReadProps, inputBWriteProps = types.newtable(), types.newtable()
    for key, value in inputBProps do
        if value.read then inputBReadProps:setproperty(key, value.read) end
        if value.write then inputBWriteProps:setproperty(key, value.write) end
    end

    for key, value in inputAProps do
        local inputARead, inputAWrite = value.read, value.write
        local inputBRead, inputBWrite = inputBReadProps:writeproperty(key), inputBWriteProps:writeproperty(key)

        if (inputARead and not inputBRead) or (inputBRead and not inputARead) then return false end
        if (inputAWrite and not inputBWrite) or (inputBWrite and not inputAWrite) then return false end


        if inputARead and inputBRead then
            if not _singletonToValue(Extends(inputARead, inputBRead)) then return false end
        end

        if inputAWrite and inputBWrite then
            if not _singletonToValue(Extends(inputAWrite, inputBWrite)) then return false end
        end
    end

    return true
end

-- since `:writeproperty` throws an error instead of returning nil if it doesn't exist
-- we need to use this workaround.
type function _tableGetWriteProps(props: { [any]: any })
    local writeProps = types.newtable()

    for key, value in props do
        local write = value.write
        if write then writeProps:setwriteproperty(key, write) end
    end

    return writeProps
end


type function _toCamel(input: string)
    return types.singleton(string.lower(string.sub(input, 1, 1))..string.sub(input, 2, -1))
end

type function _toPascal(input: string)
    return types.singleton(string.upper(string.sub(input, 1, 1))..string.sub(input, 2, -1))
end

type function _toUpper(input: string)
    return types.singleton(string.upper(input))
end

type function _toLower(input: string)
    return types.singleton(string.lower(input))
end
-------------------------------------------------------------------------------------------------------



--> Core ----------------------------------------------------------------------------------------------
--[=[
    Outputs the inputted type but only with specificied components/properties.

    @param input any -- The type to pick components/properties from.
    @param toPick any -- The union of types (or a singleton/primitive) to be picked.
]=]
type function Pick(input: { [any]: any }, toOmit: any)
    return
        if input:is("table") then TablePick(input, toOmit)
        elseif input:is("union") then UnionPick(input, toOmit)
        elseif input:is("intersection") then IntersectionPick(input, toOmit)
        else input
end


--[=[
    Outputs the inputted type but with specificied components/properties removed.

    @param input any -- The type to omit components/properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function Omit(input: { [any]: any }, toOmit: any)
    return
        if input:is("table") then TableOmit(input, toOmit)
        elseif input:is("intersection") then IntersectionOmit(input, toOmit)
        else UnionOmit(input, toOmit)
end


--[=[
    Removes duplicate components from unions and intersections including inside table keys, values and indexers.

    @param input any -- The type to clean.
]=]
type function Clean(input: { [any]: any })
    input = Flatten(input)

    return
        if input:is("table") then TableClean(input)
        elseif input:is("union") then UnionClean(input)
        elseif input:is("intersection") then IntersectionClean(input)
        else input
end


--[=[
    Recursively flattens intersections, unions and intersections of tables into one consolidated type.

    @param input any -- The type to flatten.
]=]
type function Flatten(input: { [any]: any })
    return TableFlatten(FunctionFlatten(IntersectionFlatten(UnionFlatten(input))))
end


--[=[
    Outputs `true` if the two inputted types are identical.

    @param inputA any -- The first type to compare.
    @param inputB any -- The second type to compare.
]=]
type function Equals(inputA: any, inputB: any)
    if not inputA and not inputB then return types.singleton(true) end
    if inputA and not inputB then return types.singleton(false) end
    if inputB and not inputA then return types.singleton(false) end

    if (typeof(inputA) == "userdata" and typeof(inputB) == "userdata") and (inputA.is and inputB.is) then
        if inputA:is("table") and inputB:is("table") then return TableEquals(inputA, inputB) end
        if inputA:is("union") and inputB:is("union") then return UnionEquals(inputA, inputB) end
        if inputA:is("intersection") and inputB:is("intersection") then return IntersectionEquals(inputA, inputB) end
        if inputA:is("function") and inputB:is("function") then return FunctionEquals(inputA, inputB) end
    end

    return types.singleton(_singletonToValue(inputA) == _singletonToValue(inputB))
end
  

--[=[
    Outputs the properties/components which exist in both `inputA` and `inputB`.

    @param inputA any -- The first type.
    @param inputB any -- the second type.
]=]
type function Overlap(inputA: any, inputB: any)
    if _safeIs(inputA, "table") then return TableOverlap(inputA, inputB) end
    if _safeIs(inputA, "union") then return UnionOverlap(inputA, inputB) end
    if _safeIs(inputA, "intersection") then return IntersectionOverlap(inputA, inputB) end
end


--[=[
    Outputs the properties/components which only exist in `inputA`, and which only exist in `inputB`.

    @param inputA any -- The first type.
    @param inputB any -- the second type.
]=]
type function Diff(inputA: any, inputB: any)
    if _safeIs(inputA, "table") and _safeIs(inputB, "table") then return TableDiff(inputA, inputB) end
    if _safeIs(inputA, "union") then return UnionDiff(inputA, inputB) end
    if _safeIs(inputA, "intersection") then return IntersectionDiff(inputA, inputB) end
end


--[=[
    Converts a type to camel case (camelCase).

    @param input any -- The type to convert to camel case.
]=]
type function ToCamel(input: any)
    return if _safeIs(input, "table") then TableToCamel(input) else StringToCamel(input)
end


--[=[
    Converts a type to pascal case (PascalCase).

    @param input any -- The type to convert to pascal case.
]=]
type function ToPascal(input: any)
    return if _safeIs(input, "table") then TableToPascal(input) else StringToPascal(input)
end


--[=[
    Converts a type to upper case (UPPERCASE).

    @param input any -- The type to convert to upper case.
]=]
type function ToUpper(input: any)
    return if _safeIs(input, "table") then TableToUpper(input) else StringToUpper(input)
end


--[=[
    Converts a type to lower case (lowercase).

    @param input any -- The type to convert to lower case.
]=]
type function ToLower(input: any)
    return if _safeIs(input, "table") then TableToLower(input) else StringToLower(input)
end
-------------------------------------------------------------------------------------------------------


--> Table ---------------------------------------------------------------------------------------------
--[=[
    Outputs the inputted table but only with specified properties.

    @param input { [any]: any } -- The table to pick properties from.
    @param toPick any -- The union of types or a singleton/primitive to be picked.
]=]
type function TablePick(input: { [any]: any }, toPick: any)
    if input:is("union") then
        return _arrayToUnion(_tableMap(UnionFlatten(input):components(), function(comp) return TablePick(comp, toPick) end))
    end
    if input:is("intersection") then
        return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), function(comp) return TablePick(comp, toPick) end))
    end
    _assertIs(input, "input", "table")
    input = TableFlatten(input)

    -- since `:writeproperty` throws an error instead of returning nil if it doesn't exist
    -- we need to use this workaround.
    local readProps, writeProps = types.newtable({}), types.newtable({})
    for key, value in input:properties() do
        if value.read then readProps:setwriteproperty(key, value.read) end
        if value.write then writeProps:setwriteproperty(key, value.write) end
    end

    local output = types.newtable()

    local function pickKey(key: any)
        if not key:is("singleton") then return end
        _tableSetProperty(output, key, readProps:writeproperty(key), writeProps:writeproperty(key))
    end

    if toPick:is("union") then
        for _,key in toPick:components() do pickKey(key) end
    else
        pickKey(toPick)
    end

    local indexer = input:indexer()
    if indexer then
        output:setindexer(UnionPick(indexer.index, toPick), indexer.writeresult)
    end

    return output
end


--[=[
    Outputs the inputted table but with specified properties omitted.

    @param input { [any]: any } -- The table to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function TableOmit(input: { [any]: any }, toOmit: any)
    if input:is("union") then
        return _arrayToUnion(_tableMap(UnionFlatten(input):components(), function(comp) return TableOmit(comp, toOmit) end))
    end
    if input:is("intersection") then
        return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), function(comp) return TableOmit(comp, toOmit) end))
    end
    _assertIs(input, "input", "table")
    local output = TableFlatten(input)

    local function omitKey(key: any)
        if key:is("singleton") then output:setproperty(key, nil) end
    end

    if toOmit:is("union") then
        for _,key in toOmit:components() do omitKey(key) end
    else
        omitKey(toOmit)
    end

    local indexer = input:indexer()
    if indexer then
        output:setindexer(UnionOmit(indexer.index, toOmit), indexer.writeresult)
    end

    return output
end


--[=[
    Flattens intersections of tables into one consolidated type.

    @param input { [any]: any } -- The table to flatten.
]=]
type function TableFlatten(input: any)
    if input:is("table") then return input end
    if input:is("union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), TableFlatten)) end
    if not input:is("intersection") then return input end

    local output = types.newtable()
    local options, extra = {}, {}
    local outputIndexer

    for _,comp in input:components() do
        if comp:is("intersection") then comp = TableFlatten(comp) end

        if comp:is("union") then
            _tableInsertMany(options, comp:components()) 
            continue
        
        elseif comp:is("intersection") then
            _tableInsertMany(extra, comp:components())
            continue

        elseif not comp:is("table") then
            table.insert(extra, comp)
            continue
        end

        -- Adds keys from the component into the output.
        -- TODO: check read and write properties of output separately.
        for key,value in comp:properties() do
            if output:readproperty(key) then continue end
            _tableSetProperty(output, key, value.read, value.write)
        end

        if not outputIndexer then
            local compIndexer = comp:indexer()
            if compIndexer then outputIndexer = compIndexer end
        end
    end

    if outputIndexer then
        output:setindexer(outputIndexer.index, outputIndexer.writeresult or outputIndexer.readresult)
    end

    return Omit(_combineToIntersection(
        if #options ~= 0 then
            _arrayToUnion(_tableMap(options, function(option)
                return TableFlatten(_combineToIntersection(output, option))
            end))

        else output, 

        _arrayToIntersection(extra)
    ), types.newtable())
end

--[=[
    Removes duplicate components from unions and intersections inside of table keys, values and indexers.

    @param input { [any]: any } -- The table to clean.
]=]
type function TableClean(input: { [any]: any })
    if input:is("union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), TableClean)) end
    if input:is("intersection") then return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), TableClean)) end
    if not input:is("table") then return input end

    local output = types.newtable()

    for key, value in input:properties() do
        _tableSetProperty(output, key, Clean(value.read), Clean(value.write))
    end

    local indexer = input:indexer()
    if indexer then
        output:setindexer(Clean(indexer.index), Clean(indexer.writeresult or indexer.readresult))
    end

    return output
end


--[=[
    Outputs true if the two inputted tables are identical.

    @param inputA { [any]: any } -- The first table to compare.
    @param inputB { [any]: any } -- The second table to compare.
]=]
type function TableEquals(inputA: { [any]: any }, inputB: { [any]: any })
    if not inputA:is("table") or not inputB:is("table") then return types.singleton(false) end

    local inputAPropsLength, inputBPropsLength = _tablePropsLength(inputA), _tablePropsLength(inputB)
    -- If they don't have the same amount of properties then we know they are not equal.
    if inputAPropsLength ~= inputBPropsLength then return types.singleton(false) end

    -- since `:writeproperty` throws an error instead of returning nil
    -- if it doesn't exist we need to use this workaround.
    local inputBReadProps, inputBWriteProps = types.newtable(), types.newtable()
    for key, value in inputB:properties() do
        if value.read then inputBReadProps:setwriteproperty(key, value.read) end
        if value.write then inputBWriteProps:setwriteproperty(key, value.write) end
    end

    for key, value in inputA:properties() do
        local inputARead, inputAWrite = value.read, value.write
        local inputBRead, inputBWrite = inputBReadProps:writeproperty(key), inputBWriteProps:writeproperty(key)

        if _singletonToValue(Equals(inputARead, inputBRead)) and _singletonToValue(Equals(inputAWrite, inputBWrite)) then continue end
        return types.singleton(false)
    end

    return types.singleton(true)
end


--[=[
    Outputs a table of properties which only appear in inputA, and which only appear in inputB.

    @param inputA { [any]: any } -- The first table.
    @param inputB { [any]: any } -- the second table.
]=]
type function TableDiff(inputA: { [any]: any }, inputB: { [any]: any })
    local output = types.newtable()

    local inputAProps, inputBProps = inputA:properties(), inputB:properties()
    local inputAWriteProps, inputBWriteProps = _tableGetWriteProps(inputAProps), _tableGetWriteProps(inputBProps)

    for key, value in inputAProps do
        local inputARead, inputAWrite = value.read, value.write
        local inputBRead, inputBWrite = inputB:readproperty(key), inputBWriteProps:writeproperty(key)

        local maybeRead = if inputARead and not inputBRead then inputARead else nil
        local maybeWrite = if inputAWrite and not inputBWrite then inputAWrite else nil
        _tableSetProperty(output, key, maybeRead, maybeWrite)
    end

    for key, value in inputBProps do
        local inputBRead, inputBWrite = value.read, value.write
        local inputARead, inputAWrite = inputA:readproperty(key), inputAWriteProps:writeproperty(key)

        local maybeRead = if inputBRead and not inputARead then inputBRead else nil
        local maybeWrite = if inputBWrite and not inputAWrite then inputBWrite else nil
        _tableSetProperty(output, key, maybeRead, maybeWrite)
    end

    return output
end


--[=[
    Outputs a table of properties which only appear in both inputA and inputB.

    @param inputA { [any]: any } -- The first table.
    @param inputB { [any]: any } -- the second table.
]=]
type function TableOverlap(inputA: { [any]: any }, inputB: { [any]: any })
    local output = types.newtable()

    local inputAProps, inputBProps = inputA:properties(), inputB:properties()
    local inputAWriteProps, inputBWriteProps = _tableGetWriteProps(inputAProps), _tableGetWriteProps(inputBProps)

    for key, value in inputAProps do
        local inputARead, inputAWrite = value.read, value.write
        local inputBRead, inputBWrite = inputB:readproperty(key), inputBWriteProps:writeproperty(key)

        local maybeRead = if Equals(inputARead, inputBRead):value() then inputARead else nil
        local maybeWrite = if Equals(inputAWrite, inputBWrite):value() then inputAWrite else nil
        _tableSetProperty(output, key, maybeRead, maybeWrite)
    end

    for key, value in inputBProps do
        local inputBRead, inputBWrite = value.read, value.write
        local inputARead, inputAWrite = inputA:readproperty(key), inputAWriteProps:writeproperty(key)

        local maybeRead = if Equals(inputBRead, inputARead):value() then inputBRead else nil
        local maybeWrite = if Equals(inputBWrite, inputAWrite):value() then inputBWrite else nil
        _tableSetProperty(output, key, maybeRead, maybeWrite)
    end

    return output
end


--[=[
    Returns a union of the two inputted tables, where keys of the first table are added to the second table (if not already) but with a falsy value and vice virsa.

    @param inputA { [any]: any } -- The first table.
    @param inputA { [any]: any } -- The second table.
]=]
type function Either(inputA: { [any]: any }, inputB: { [any]: any })
    _assertIs(inputA, "inputA", "table")
    _assertIs(inputB, "inputB", "table")

    local falsy = types.unionof(types.singleton(false), types.singleton(nil), types.never)
    local outputA, outputB = types.copy(inputA), types.copy(inputB)

    for key, value in inputB:properties() do
        if inputA:readproperty(key) then continue end
        _tableSetProperty(outputA, key, falsy, falsy)
    end

    for key, value in inputA:properties() do
        if inputB:readproperty(key) then continue end
        _tableSetProperty(outputB, key, falsy, falsy)
    end

    return types.unionof(outputA, outputB)
end


--[=[
    Makes all of the properties in a table optional.

    @param input { [any]: any } -- The table to make partial.
]=]
type function Partial(input: { [any]: any })
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = types.newtable()

    for key, value in input:properties() do
        _tableSetProperty(output, key, _toPartial(value.read), _toPartial(value.write))
    end

    local indexer = input:indexer()
    if indexer then
        output:setindexer(indexer.index, _toPartial(indexer.writeresult or indexer.readresult))
    end

    return output
end


--[=[
    Makes all of the properties in a table read only.

    @param input { [any]: any } -- The table to make read only.
]=]
type function ReadOnly(input: { [any]: any })
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = types.newtable()

    for key, value in input:properties() do
        output:setreadproperty(key, value.read or value.write)
    end

    local indexer = input:indexer()
    if indexer then
        -- TODO: make indexer read only once luau supports doing so.
        output:setindexer(indexer.index, indexer.writeresult or indexer.readresult)
    end

    return output
end


--[=[
    Makes all of the properties of a table readable and writable (mutable).

    @param input { [any]: any } -- The table to make mutable.
]=]
type function ReadWrite(input: { [any]: any })
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = types.newtable()

    for key, value in input:properties() do
        local read = value.read
        _tableSetProperty(output, key, value.read, value.write or read)
    end

    local indexer = input:indexer()
    if indexer then
        output:setindexer(indexer.index, indexer.writeresult or indexer.readresult)
    end

    return output
end


--[=[
    Outputs all values of a table as a union of types (or a singleton/primitive).

    @param input { [any]: any } -- The table to get values of.
]=]
type function ValueOf(input: { [any]: any })
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = {}

    for _,value in TableFlatten(input):properties() do
        local read, write = value.read, value.write
        table.insert(output, read)
        if write then table.insert(output, read == write and read or write) end
    end

    local indexer = input:indexer()
    if indexer then
        table.insert(output, indexer.writeresult or indexer.readresult)
    end

    return UnionClean(_arrayToUnion(output))
end


--[=[
    Removes the indexer from a table type.

    @param input { [any]: any } -- The table to remove the indexer from.
]=]
type function RemoveIndexer(input: { [any]: any })
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = types.copy(input)
    output:setindexer(types.never, types.never)
    return output
end


--[=[
    Sets the indexer for a table type.

    @param input { [any]: any } -- The table to set the indexer for.
    @param keyType any -- The key type for the new indexer.
    @param value any -- The value for the new indexer.
]=]
type function SetIndexer(input: { [any]: any }, keyType: any, value: any)
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = types.copy(input)
    output:setindexer(keyType, value)
    return output
end


--[=[
    Converts all string literal keys in a table to be camel case (camelCase).

    @param input { [any]: any } -- The table to convert to camel case.
]=]
type function TableToCamel(input: { [any]: any })
    local output = types.newtable()

    for key, value in input:properties() do
        local read, write = value.read, value.write

        _tableSetProperty(
            output, StringToCamel(key),
            read:is("table") and TableToCamel(read) or read,
            write:is("table") and TableToCamel(write) or write
        )
    end

    return output
end


--[=[
    Converts all string literal keys in a table to be pascal case (PascalCase).

    @param input { [any]: any } -- The table to convert to pascal case.
]=]
type function TableToPascal(input: { [any]: any })
    local output = types.newtable()

    for key, value in input:properties() do
        local read, write = value.read, value.write

        _tableSetProperty(
            output, StringToPascal(key),
            read:is("table") and TableToPascal(read) or read,
            write:is("table") and TableToPascal(write) or write
        )
    end

    return output
end


--[=[
    Converts all string literal keys in a table to be upper case (UPPERCASE).

    @param input { [any]: any } -- The table to convert to upper case.
]=]
type function TableToUpper(input: { [any]: any })
    local output = types.newtable()

    for key, value in input:properties() do
        local read, write = value.read, value.write

        _tableSetProperty(
            output, StringToUpper(key),
            read:is("table") and TableToUpper(read) or read,
            write:is("table") and TableToUpper(write) or write
        )
    end

    return output
end


--[=[
    Converts all string literal keys in a table to be lower case (lowercase).

    @param input { [any]: any } -- The table to convert to lower case.
]=]
type function TableToLower(input: { [any]: any })
    local output = types.newtable()

    for key, value in input:properties() do
        local read, write = value.read, value.write

        _tableSetProperty(
            output, StringToLower(key),
            read:is("table") and TableToLower(read) or read,
            write:is("table") and TableToLower(write) or write
        )
    end

    return output
end


--[=[
    Gets the metatable for a table.

    @param input { [any]: any } -- The table to get the metatable for.
]=]
type function GetMetatable(input: { any })
    _assertIs(input, "input", "table")

    local metaTable = input:metatable()
  
    -- Makes the output type tidier.
    local __index = types.singleton("__index")
    if metaTable:readproperty(__index) == metaTable then
        metaTable:setproperty(__index, metaTable)
    end
  
    return metaTable
end


--[=[
    Sets the metatable for a table.

    @param input { [any]: any } -- The table to set the metatable for.
    @param metatable { [any]: any } -- The metatable to set.
]=]
type function SetMetatable(input: { [any]: any }, metatable: { [any]: any })
    _assertIs(input, "input", "table")
    _assertIs(metatable, "metatable", "table")

    -- Makes the output type tidier.
    local __index = types.singleton("__index")
    if metatable:readproperty(__index) == metatable then
        metatable:setproperty(__index, metatable)
    end
  
    input:setmetatable(metatable)
    return input
end
-------------------------------------------------------------------------------------------------------


--> Union ---------------------------------------------------------------------------------------------
--[=[
    Outputs the inputted union or singleton/primitive but only with specified components.

    @param union any -- The union or singleton/primitive to pick components from.
    @param toPick any -- The union of types (or a singleton/primitive) to be picked.
]=]
type function UnionPick(input: any, toPick: any)
    input = UnionFlatten(input)
    local unionComponents = input:is("union") and _arraySingletonsToValues(input:components()) or { _singletonToValue(input) }
    local output = {}

    local function pickKey(key: any)
        if table.find(unionComponents, key) and not table.find(output, key) then
            table.insert(output, key)
        end
    end

    if toPick:is("union") then
        for _,comp in toPick:components() do pickKey(_singletonToValue(comp)) end
        
    else pickKey(_singletonToValue(toPick)) end

    return _arrayToUnion(_arrayValuesToSingletons(output))
end


--[=[
    Outputs the inputted union or singleton/primitive but with specified components omitted.

    @param input any -- The union or singleton/primitive to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function UnionOmit(input: any, toOmit: any)
    input = UnionFlatten(input)
    local outputComponents = input:is("union") and _arraySingletonsToValues(input:components()) or { _singletonToValue(input) }

    if toOmit:is("union") then
        for _,comp in toOmit:components() do
            _arrayOmit(outputComponents, _singletonToValue(comp))
        end

    else _arrayOmit(outputComponents, _singletonToValue(toOmit)) end

    return _arrayToUnion(_arrayValuesToSingletons(outputComponents))
end


--[=[
    Removes duplicate types from a union (or a singleton/primitive).

    @param input any -- The union of types (or a singleton/primitive) to be cleaned.
]=]
type function UnionClean(input: any)
    input = UnionFlatten(input)
    if not input:is("union") then return input end

    local output = {}

    local function maybeInsertIntoCleaned(comp: any)
        comp = _singletonToValue(comp)

        for _,value in output do
            if _singletonToValue(Equals(value, comp)) then return end
        end
        
        table.insert(output, comp)
    end

    for idx,comp in input:components() do
        comp = UnionClean(comp)

        if comp:is("union") then
            for idx, subComp in comp:components() do
                maybeInsertIntoCleaned(subComp)
            end

        else
            maybeInsertIntoCleaned(comp)
        end
    end

    return _arrayToUnion(_arrayValuesToSingletons(output))
end


--[=[
    Recursively flattens nested unions into one union, semantics are preserved.

    @param union any -- The union of types (or a singleton/primitive) to be flattened.
]=]
type function UnionFlatten(input: any)
    if input:is("union") then
        local output = {}

        for _,comp in input:components() do
            if comp:is("union") or comp:is("intersection") then
                local compOutput = UnionFlatten(comp)
                if compOutput:is("union") then
                    _tableInsertMany(output, compOutput:components())
                else
                    table.insert(output, compOutput)
                end
                
            else table.insert(output, comp) end
        end

        return _arrayToUnion(output)

    elseif input:is("intersection") then
        return _arrayToIntersection(_tableMap(input:components(), UnionFlatten))
    end

    return input
end


--[=[
    Outputs true if the two inputted unions (or a singleton/primitive) are identical.

    @param inputA any -- The first union to compare.
    @param inputB any -- the second union to compare.
]=]
type function UnionEquals(inputA: any, inputB: any)
    if inputA:is("intersection") and inputB:is("union") then return types.singleton(false) end
    if inputB:is("intersection") and inputA:is("union") then return types.singleton(false) end

    local inputAComponentsLength = inputA:is("union") and #inputA:components() or 1
    local inputBComponentsLength = inputB:is("union") and #inputB:components() or 1
    if inputAComponentsLength ~= inputBComponentsLength then return types.singleton(false) end

    inputA, inputB = UnionClean(UnionFlatten(inputA)), UnionClean(UnionFlatten(inputB))
    local inputAComponents = inputA:is("union") and inputA:components() or { inputA }
    local inputBComponents = inputB:is("union") and inputB:components() or { inputB }

    local matches = 0
    for _,compA in inputAComponents do

        for _,compB in inputBComponents do
            if _singletonToValue(Equals(compA, compB)) then matches += 1 end
        end

    end

    return types.singleton(#inputAComponents == matches and true or false)
end


--[=[
    Outputs a union of components which only appear in `inputA`, and which only appear in `inputB`.

    @param inputA any -- The first union.
    @param inputB any -- the second union.
]=]
type function UnionDiff(inputA: any, inputB: any)
    local inputAComponents = inputA:is("union") and inputA:components() or { inputA }
    local inputBComponents = inputB:is("union") and inputB:components() or { inputB }

    local output = {}

    for _,comp in inputAComponents do
        if _arrayHasType(inputBComponents, comp) then continue end
        table.insert(output, comp)
    end

    for _,comp in inputBComponents do
        if _arrayHasType(inputAComponents, comp) then continue end
        table.insert(output, comp)
    end

    return _arrayToUnion(output)
end


--[=[
    Outputs a union of components which only appear in both `inputA` and `inputB`.

    @param inputA any -- The first union.
    @param inputB any -- the second union.
]=]
type function UnionOverlap(inputA: any, inputB: any)
    local inputAComponents = inputA:is("union") and inputA:components() or { inputA }
    local inputBComponents = inputB:is("union") and inputB:components() or { inputB }

    local output = {}

    for _,comp in inputAComponents do
        if _arrayHasType(inputBComponents, comp) then
            table.insert(output, comp)
        end
    end

    for _,comp in inputBComponents do
        if _arrayHasType(inputAComponents, comp) then
            table.insert(output, comp)
        end
    end

    return UnionClean(_arrayToUnion(output))
end
-------------------------------------------------------------------------------------------------------


--> Intersection --------------------------------------------------------------------------------------
--[=[
    Outputs the inputted intersection or singleton/primitive but only with specified components.

    @param input any -- The intersection or singleton/primitive to pick components from.
    @param toPick any -- The union of types (or a singleton/primitive) to be picked.
]=]
type function IntersectionPick(input: any, toPick: any)
    input = IntersectionFlatten(input)
    local outputComponents = input:is("intersection") and _arraySingletonsToValues(input:components()) or { _singletonToValue(input) }
    local output = {}

    local function pickKey(key: any)
        if table.find(outputComponents, key) and not table.find(output, key) then
            table.insert(output, key)
        end
    end

    if toPick:is("union") then
        for _,comp in toPick:components() do pickKey(_singletonToValue(comp)) end
        
    else pickKey(_singletonToValue(toPick)) end

    return _arrayToIntersection(_arrayValuesToSingletons(output))
end


--[=[
    Outputs the inputted intersection or singleton/primitive but with specified components omitted.

    @param input any -- The intersection or singleton/primitive to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function IntersectionOmit(input: any, toOmit: any)
    input = IntersectionFlatten(input)
    local outputComponents = input:is("intersection") and _arraySingletonsToValues(input:components()) or { _singletonToValue(input) }

    if toOmit:is("union") then
        for _,comp in toOmit:components() do
            _arrayOmit(outputComponents, _singletonToValue(comp))
        end
    else
        _arrayOmit(outputComponents, _singletonToValue(toOmit))
    end

    return _arrayToIntersection(_arrayValuesToSingletons(outputComponents))
end


--[=[
    Removes duplicate types from a intersection (or a singleton/primitive).

    @param input any -- The intersection of types (or a singleton/primitive) to be cleaned.
]=]
type function IntersectionClean(input: any)
    input = IntersectionFlatten(input)
    if not input:is("intersection") then return input end

    local output = {}

    local function maybeInsertIntoCleaned(comp: any)
        comp = _singletonToValue(comp)
        
        for _,value in output do
            if _singletonToValue(Equals(value, comp)) then return end
        end

        table.insert(output, comp)
    end

    for idx,comp in input:components() do
        comp = IntersectionClean(comp)

        if comp:is("intersection") then
            for idx, subComp in comp:components() do
                maybeInsertIntoCleaned(subComp)
            end

        else
            maybeInsertIntoCleaned(comp)
        end
    end

    return _arrayToIntersection(_arrayValuesToSingletons(output))
end


--[=[
    Recursively flattens nested intersections into one union, semantics are preserved.

    @param union any -- The intersection of types (or a singleton/primitive) to be flattened.
]=]
type function IntersectionFlatten(input: any)
    if input:is("intersection") then
        local output = {}

        for _,comp in input:components() do
            if comp:is("intersection") or comp:is("union") then
                local compOutput = IntersectionFlatten(comp)
                if compOutput:is("intersection") then
                    _tableInsertMany(output, compOutput:components())
                else
                    table.insert(output, compOutput)
                end
                
            else table.insert(output, comp) end
        end

        return _arrayToIntersection(output)

    elseif input:is("union") then
        return _arrayToUnion(_tableMap(input:components(), IntersectionFlatten))
    end

    return input
end


--[=[
    Outputs true if the two inputted intersections are identical.

    @param inputA any -- The first table to compare.
    @param inputB any -- the second table to compare.
]=]
type function IntersectionEquals(inputA: any, inputB: any)
    if inputA:is("union") and inputB:is("intersection") then return types.singleton(false) end
    if inputB:is("union") and inputA:is("intersection") then return types.singleton(false) end

    local inputAComponentsLength = inputA:is("intersection") and #inputA:components() or 1
    local inputBComponentsLength = inputB:is("intersection") and #inputB:components() or 1
    if inputAComponentsLength ~= inputBComponentsLength then return types.singleton(false) end

    inputA, inputB = IntersectionClean(IntersectionFlatten(inputA)), IntersectionClean(IntersectionFlatten(inputB))
    local inputAComponents = inputA:is("intersection") and inputA:components() or { inputA }
    local inputBComponents = inputB:is("intersection") and inputB:components() or { inputB }

    local matches = 0
    for _,compA in inputAComponents do

        for _,compB in inputBComponents do
            if _singletonToValue(Equals(compA, compB)) then matches += 1 end
        end

    end

    return types.singleton(#inputAComponents == matches and true or false)
end


--[=[
    Outputs an intersection of components which only appear in `inputA`, and which only appear in `inputB`.

    @param inputA any-- The first intersection.
    @param inputB any -- the second intersection.
]=]
type function IntersectionDiff(inputA: any, inputB: any)
    local inputAComponents = inputA:is("intersection") and inputA:components() or { inputA }
    local inputBComponents = inputB:is("intersection") and inputB:components() or { inputB }

    local output = {}

    for _,comp in inputAComponents do
        if _arrayHasType(inputBComponents, comp) then continue end
        table.insert(output, comp)
    end

    for _,comp in inputBComponents do
        if _arrayHasType(inputAComponents, comp) then continue end
        table.insert(output, comp)
    end

    return _arrayToIntersection(output)
end


--[=[
    Outputs an intersection of components which only appear in both `inputA` and `inputB`.

    @param inputA any -- The first intersection.
    @param inputB any -- the second intersection.
]=]
type function IntersectionOverlap(inputA: any, inputB: any)
    local inputAComponents = inputA:is("intersection") and inputA:components() or { inputA }
    local inputBComponents = inputB:is("intersection") and inputB:components() or { inputB }

    local output = {}

    for _,comp in inputAComponents do
        if _arrayHasType(inputBComponents, comp) then
            table.insert(output, comp)
        end
    end

    for _,comp in inputBComponents do
        if _arrayHasType(inputAComponents, comp) then
            table.insert(output, comp)
        end
    end

    return IntersectionClean(_arrayToIntersection(output))
end
-------------------------------------------------------------------------------------------------------


--> Function ------------------------------------------------------------------------------------------
--[=[
    Removes duplicate types from a functions arguments and return types.

    @param input any -- The function to be cleaned.
]=]
type function FunctionClean(input: (...any) -> ...any)
    if input:is("union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), FunctionClean)) end
    if input:is("intersection") then return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), FunctionClean)) end
    _assertIs(input, "input", "function")

    local function clean(item: any)
        local head, tail = item.head, item.tail
        local output = {}

        if head then
            local outputHead = {}

            for _,comp in head do
                table.insert(outputHead, Clean(comp))
            end

            output.head = outputHead
        end

        if tail then
            local outputTail = {}

            for _,comp in tail do
                table.insert(outputTail, Clean(comp))
            end

            output.tail = outputTail
        end

        return output
    end

    return types.newfunction(clean(input:parameters()), clean(input:returns()))
end


--[=[
    Recursively flattens the arguments and parameters of a function so that intersections, unions and intersections of tables are flattened into one consolidated type.

    @param input (...any) -> ...any -- The function to be flattened.
]=]
type function FunctionFlatten(input: (...any) -> ...any)
    if input:is("union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), FunctionFlatten)) end
    if input:is("intersection") then return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), FunctionFlatten)) end
    if not input:is("function") then return input end

    local function flatten(item: any)
        local head, tail = item.head, item.tail
        local output = {}

        if head then
            local outputHead = {}

            for _,comp in head do
                table.insert(outputHead, Flatten(comp))
            end

            output.head = outputHead
        end

        if tail then
            local outputTail = {}

            for _,comp in tail do
                table.insert(outputTail, Flatten(comp))
            end

            output.tail = outputTail
        end

        return output
    end

    return types.newfunction(flatten(input:parameters()), flatten(input:returns()))
end


--[=[
    Outputs true if the two inputted functions have identical arguments and return types.

    @param inputA (...any) -> ...any -- The first function to compare.
    @param inputB (...any) -> ...any -- the second function to compare.
]=]
type function FunctionEquals(inputA: (...any) -> ...any, inputB: (...any) -> ...any)
    local function equals(itemA: any, itemB: any)
        if (itemA and not itemB) or (itemB and not itemA) then return false end
        if not itemA and not itemB then return true end

        if #itemA ~= #itemB then return false end

        for idx, comp in itemA do
            if not _singletonToValue(Equals(comp, itemB[idx])) then return false end
        end

        return true
    end

    local argsA, argsB = inputA:parameters(), inputB:parameters()
    local returnsA, returnsB = inputA:returns(), inputB:returns()

    return types.singleton(
        equals(argsA and argsA.head, argsB and argsB.head) and 
        _singletonToValue(Equals(argsA and argsA.tail, argsB and argsB.tail)) and
        equals(returnsA and returnsA.head, returnsB and returnsB.head) and
        _singletonToValue(Equals(returnsA and returnsA.tail, returnsB and returnsB.tail))
    )
end


--[=[
    Outputs the arguments of a function.

    @param input (...any) -> ...any -- The function to get arguments for.
]=]
type function Args(input: (...any) -> ...any)
    _assertIs(input, "input", "function")
    
    local args = input:parameters()
    local argsHead, argsTail = args.head, args.tail

    local output = types.newtable()

    if argsHead then
        for idx,arg in argsHead do
            output:setproperty(types.singleton(tostring(idx)), arg)
        end
    end

    if argsTail then
        output:setproperty(types.singleton("Tail"), argsTail)
    end

    return output
end


--[=[
    Sets the arguments for an existing function type.

    @param input (...any) -> ...any -- The function to set arguments for.
    @param args { [`{number}`]: any, Tail: any } -- The new arguments for the function.
]=]
type function SetArgs(input: (...any) -> ...any, args: { [any]: any, Tail: any })
    _assertIs(input, "input", "function")
    _assertIs(args, "args", "table")

    local argsArray = {}
    for key, value in args:properties() do
        local idx = tonumber(key:value())
        if not idx then continue end
        argsArray[idx] = value.write or value.read
    end
    local argsTail = args:readproperty(types.singleton("Tail"))
    
    local output = types.copy(input)
    output:setparameters(argsArray, argsTail)
    return output
end


--[=[
    Outputs the return types of a function.

    @param input (...any) -> ...any -- The function to get return types for.
]=]
type function Returns(input: (...any) -> ...any)
    _assertIs(input, "input", "function")

    local returns = input:returns()
    local returnsHead, returnsTail = returns.head, returns.tail

    local output = types.newtable()

    if returnsHead then
        for idx,arg in returnsHead do
            output:setproperty(types.singleton(tostring(idx)), arg)
        end
    end

    if returnsTail then
        output:setproperty(types.singleton("Tail"), returnsTail)
    end

    return output
end


--[=[
    Sets the return types for a function.

    @param input (...any) -> ...any -- The function to set return types for.
    @param returns { [`{number}`]: any, Tail: any } -- The new return types for the function.
]=]
type function SetReturns(input: (...any) -> ...any, returns: { [any]: any, Tail: any })
    _assertIs(input, "input", "function")

    local returnsArray = {}
    for key, value in returns:properties() do
        local idx = tonumber(key:value())
        if not idx then continue end
        returnsArray[idx] = value.write or value.read
    end

    local returnsTail = returns:readproperty(types.singleton("Tail"))
    local output = types.copy(input)
    output:setreturns(returnsArray, returnsTail)

    return output
end


--[=[
    Builds a function type using a table for the arguments and the return types.

    @param args { [`{number}`]: any, Tail: any } -- The arguments for the function.
    @param returns { [`{number}`]: any, Tail: any } -- The return types for the function.
]=]
type function Function(args: { [any]: any, Tail: any }, returns: { [any]: any, Tail: any })
    local argsHead = {}
    for key, value in args:properties() do
        local idx = tonumber(key:value())
        if not idx then continue end
        argsHead[idx] = value.write or value.read
    end

    local returnsHead = {}
    for key, value in returns:properties() do
        local idx = tonumber(key:value())
        if not idx then continue end
        returnsHead[idx] = value.write or value.read
    end

    return types.newfunction(
        { head = argsHead, tail = args:readproperty(types.singleton("Tail")) },
        { head = returnsHead, tail = returns:readproperty(types.singleton("Tail")) }
    )
end
-------------------------------------------------------------------------------------------------------


--> String --------------------------------------------------------------------------------------------
--[=[
    Converts a string literal (or string literals within a union/intersection) to camel case (camelCase).

    @param input string -- The string to convert to camel case.
]=]
type function StringToCamel(input: string)
    if input:is("union") then return _arrayToUnion(_tableMap(input:components(), StringToCamel)) end
    if input:is("intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToCamel)) end

    input = _singletonToValue(input)
    if typeof(input) ~= "string" then return input end

    return _toCamel(input)
end


--[=[
    Converts a string literal (or string literals within a union/intersection) to pascal case (PascalCase).

    @param input string -- The string to convert to pascal case.
]=]
type function StringToPascal(input: string)
    if input:is("union") then return _arrayToUnion(_tableMap(input:components(), StringToPascal)) end
    if input:is("intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToPascal)) end

    input = _singletonToValue(input)
    if typeof(input) ~= "string" then return input end

    return _toPascal(input)
end


--[=[
    Converts a string literal (or string literals within a union/intersection) to upper case (UPPERCASE).

    @param input string -- The string to convert to upper case.
]=]
type function StringToUpper(input: string)
    if input:is("union") then return _arrayToUnion(_tableMap(input:components(), StringToUpper)) end
    if input:is("intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToUpper)) end

    input = _singletonToValue(input)
    if typeof(input) ~= "string" then return input end

    return _toUpper(input)
end


--[=[
    Converts a string literal (or string literals within a union/intersection) to lower case (lowercase).

    @param input string -- The string to convert to lower case.
]=]
type function StringToLower(input: string)
    if input:is("union") then return _arrayToUnion(_tableMap(input:components(), StringToLower)) end
    if input:is("intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToLower)) end

    input = _singletonToValue(input)
    if typeof(input) ~= "string" then return input end

    return _toLower(input)
end


--[=[
    Replaces part(s) of a string literal (or string literals within a union/intersection) with another using a pattern.

    @param input string -- The string to replace in.
    @param pattern string -- The string pattern to replace.
    @param replacement string -- The replacement string.
]=]
type function StringReplace(input: string, pattern: string, replacement: string)
    if input:is("union") then
        return _arrayToUnion(_tableMap(input:components(), function(comp) return StringReplace(comp, pattern, replacement) end))
    end
    if input:is("intersection") then
        return _arrayToIntersection(_tableMap(input:components(), function(comp) return StringReplace(comp, pattern, replacement) end))
    end

    input, pattern, replacement = _singletonToValue(input), _singletonToValue(pattern), _singletonToValue(replacement)
    assert(typeof(input) == "string", _assertIsMessage("input", "string"))
    assert(typeof(pattern) == "string", _assertIsMessage("pattern", "string"))
    assert(typeof(replacement) == "string", _assertIsMessage("replacement", "string"))

    return types.singleton(string.gsub(input, pattern, replacement))
end


--[=[
    Joins a table of strings together.

    @param input { [`{number}`]: string } -- The string table to join together.
]=]
type function StringJoin(input: { [any]: string })
    local inputArr = {}

    for key, value in input:properties() do
        local idx = tonumber(key:value())
        if not idx then continue end
        inputArr[idx] = value.write or value.read
    end

    local output = ""

    for _,value in inputArr do
        value = _singletonToValue(value)
        if typeof(value) ~= "string" then continue end
        output ..= value
    end

    return types.singleton(output)
end


--[=[
    Splits a string literal (or string literals within a union/intersection) at every occurance of a specific string.

    @param input string -- The string to split.
    @param splitAt string -- The string to split at.
]=]
type function StringSplit(input: string, splitAt: string)
    if input:is("union") then
        return _arrayToUnion(_tableMap(input:components(), function(comp) return StringSplit(comp, splitAt) end))
    end
    if input:is("intersection") then
        return _arrayToIntersection(_tableMap(input:components(), function(comp) return StringSplit(comp, splitAt) end))
    end

    input, splitAt = _singletonToValue(input), _singletonToValue(splitAt)
    assert(typeof(input) == "string", _assertIsMessage("input", "string"))
    assert(typeof(splitAt) == "string", _assertIsMessage("splitAt", "string"))

    local split = string.split(input, splitAt)

    local output = types.newtable()
    for idx,value in split do
        output:setproperty(types.singleton(tostring(idx)), types.singleton(value))
    end

    return output
end


--[=[
    Returns the character of a string at a specific index.

    @param input string -- The string to get character at.
    @param at `{number}` -- The position to get character at.
]=]
type function StringAt(input: string, at: string)
    at = tonumber(_singletonToValue(at))
    assert(typeof(at) == "number", "The type argument `at` could not be turned into a number!")

    return types.singleton(string.sub(_singletonToValue(input), at, at))
end


--[=[
    Gets the length of a string (returns as a stringified integer as luau doesn't currently support integer literals).

    @param input string -- The string to get the length of.
]=]
type function StringLength(input: string)
    return types.singleton(tostring(#_singletonToValue(input)))
end


--[=[
    Returns true if the string is a string literal.

    @param input string -- The string to test to see if its a string literal.
]=]
type function StringIsLiteral(input: string)
    return types.singleton(if typeof(_singletonToValue(input)) == "string" then true else false)
end
-------------------------------------------------------------------------------------------------------


--> Boolean Operation ---------------------------------------------------------------------------------
--[=[
    If a truthy type is inputted then it outputs `false`, and if a falsy type is inputted then it outputs `true`.

    @param input any -- The type you wish to perform a `Not` operation on.
]=]
type function Not(input: any)
    if input:is("never") or input:is("unknown") then
        return types.singleton(false)

    elseif input:is("singleton") then
        return types.singleton(not input:value())

    elseif input:is("union") then
        local output

        for _,comp in input:components() do
            local invertedComp = types.singleton(not comp:value())
            if not output then output = invertedComp
            else output = types.unionof(output, invertedComp) end
        end

        return output
    end

    return types.never
end


--[=[
    If all types of the union (or singleton/primitive) are truthy then it outputs `true`, but if at least one of the types of the (or singleton/primitive) are falsely then it outputs `false`.

    @param input any -- The type you wish to perform an `And` operation on.
]=]
type function And(input: any)
    if input:is("never") or input:is("unknown") then
        return types.singleton(false)

    elseif input:is("singleton") then
        return types.singleton(input:value() and true or false)
    
    elseif input:is("union") then
        for _,comp in input:components() do
            if comp:is("never") or comp:is("unknown") or (not comp:value()) then return types.singleton(false) end
        end

        return types.singleton(true)
    end

    return types.never
end


--[=[
    If at least one of the types of the union (or singleton/primitive) are truthy then it outputs `true`, but if all of the types of the union (or singleton/primitive) are falsely then it outputs `false`.

    @param input any -- The union/singleton you wish to perform an `Or` operation on.
]=]
type function Or(input: any)
    if input:is("never") or input:is("unknown") then
        return types.singleton(false)

    elseif input:is("singleton") then
        return types.singleton(input:value() and true or false)
    
    elseif input:is("union") then
        for _,comp in input:components() do
            if comp:is("never") or comp:is("unknown") then continue end
            if comp:value() then return types.singleton(true) end
        end

        return types.singleton(false)
    end

    return types.never
end
-------------------------------------------------------------------------------------------------------


--> Logical Operation ---------------------------------------------------------------------------------
--[=[
    Returns true if all of the input types extends at least one of the output types.

    @param input any -- The type to test.
    @param extends any -- the type to test if `input` extends.
]=]
type function Extends(input: any, extends: any)
    input, extends = Clean(Flatten(input)), Clean(Flatten(extends))

    local function doesExtendBase(inputItem: any, extendsItem: any)

        if _safeIs(inputItem, "table") and _safeIs(extendsItem, "table") then
            if _tableExtendsTable(TablePick(inputItem, _keyof(extendsItem)), extendsItem) then return true end

        else
            if inputItem == extendsItem then return true end

            if typeof(inputItem) == _typeToValue(extendsItem) then return true end

            if _singletonToValue(Equals(inputItem, extendsItem)) then return true end
        end

        return false
    end

    local doesExtend
    if extends:is("union") or extends:is("intersection") then
        local extendsComponents = _arraySingletonsToValues(extends:components())
        doesExtend = function(item: any)
            for _,comp in extendsComponents do
                if doesExtendBase(_singletonToValue(item), comp) then return true end
            end
            return false
        end

    else
        doesExtend = function(item: any) return doesExtendBase(_singletonToValue(item), _singletonToValue(extends)) end
    end


    if input:is("union") or input:is("intersection") then
        for _,comp in input:components() do
            if not doesExtend(comp) then return types.singleton(false) end
        end
        return types.singleton(true)

    else return types.singleton(doesExtend(input)) end
end


--[=[
    Returns true if `input` has the same type or subtype (via vanilla luau subtyping) to `toCompare`.

    @param input any -- The type to compare.
    @param toCompare any -- The type to compare to.
]=]
type function Compare(input: any, compareTo: any)
    return types.singleton(
        typeof(_singletonToValue(input)) == typeof(_singletonToValue(compareTo)) or 
        (input == compareTo))
end


--[=[
    If `input` is a truthy type then it outputs `ifTruthy`, if else then it outputs `ifFalsy`.

    @param input any -- The type for the condition.
    @param ifTruthy any -- The type to output if `input` is truthy.
    @param ifFalsy any -- The type to output if `input` is falsey.
]=]
type function Condition(input: any, ifTruthy: any, ifFalsy: any)
    return if _singletonToValue(input) then ifTruthy else ifFalsy
end
-------------------------------------------------------------------------------------------------------


--> Miscellaneous -------------------------------------------------------------------------------------
--[=[
    Throws a type error if the first type does not equal the second.

    @param expect any -- The type to be compared.
    @param toBe any -- The type you want to compare `expect` to.
]=]
type function Expect(expect: any, toBe: any)
    if not _singletonToValue(Equals(expect, toBe)) then
        return error("expection error!")
    end

    return expect
end


--[=[
    Returns the inputted type but with unions and intersections turned into arrays so they can be inspected better.

    @param input any -- The type to be inspected.
]=]
type function Inspect(input: any)
    local isUnion, isIntersection = input:is("union"), input:is("intersection")
    if not isUnion and not isIntersection then return input end

    local output = types.newtable({
        [types.singleton("Kind")] =  types.singleton(if isUnion then "Union" else "Intersection")
    })

    for idx, comp in input:components() do
        output:setproperty(
            types.singleton(`{idx}`),
            if comp:is("union") or comp:is("intersection") then Inspect(comp) else comp
        )
    end

    return output
end
-------------------------------------------------------------------------------------------------------









-------------------------------------------------------------------------------------------------------
--> TESTS ---------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------









--> Table ---------------------------------------------------------------------------------------------
-- TablePick -----------------------------------------
-- Test A: Picking 1 string literal property from a table.
type TablePick_TestA = Expect<
    TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    { Name: string }
>

-- Test B: Picking multiple string literal properties from a table.
type TablePick_TestB = Expect<
    TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    { Name: string, Age: number }
>

-- Test C: Picking 1 indexer component from a table.
type TablePick_TestC = Expect<
    TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    SetIndexer<{}, "hello", any>
>

-- Test D: Picking multiple indexer components from a table.
type TablePick_TestD = Expect<
    TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    SetIndexer<{}, "hello" | string, any>
>

-- Test E: Picking multiple indexer components and properties from a table.
type TablePick_TestE = Expect<
    TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    SetIndexer<{ Name: string, Age: number }, "hello" | string, any>
>


-- Test F: Picking a property and indexer of the same string literal.
type TablePick_TestF = Expect<
    TablePick<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    SetIndexer<{ Age: number }, "Age", any>
>
------------------------------------------------------


-- TableOmit -----------------------------------------
-- Test A: Omitting 1 string literal property from a table.
type TableOmit_TestA = Expect<
    TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    SetIndexer<{ Age: number }, string | "hello" | "lol", any>
>

-- Test B: Omitting multiple string literal properties from a table.
type TableOmit_TestB = Expect<
    TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    SetIndexer<{ }, string | "hello" | "lol", any>
>

-- Test C: Omitting 1 indexer component from a table.
type TableOmit_TestC = Expect<
    TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    SetIndexer<{ Name: string, Age: number }, string | "lol", any>
>

-- Test D: Omitting multiple indexer components from a table.
type TableOmit_TestD = Expect<
    TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    SetIndexer<{ Name: string, Age: number }, "lol", any>
>

-- Test E: Omitting multiple indexer components and properties from a table.
type TableOmit_TestE = Expect<
    TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    SetIndexer<{}, "lol", any>
>

-- Test F: Picking a property and indexer of the same string literal.
type TableOmit_TestF = Expect<
    TableOmit<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    SetIndexer<{ Name: string }, string | "hello" | "lol", any>
>
------------------------------------------------------


-- TableFlatten --------------------------------------
-- TestA: Flattening 1 table.
type TableFlatten_TestA = Expect<
    TableFlatten<{ hello: "world", foo: "bar", baz: "bix" }>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestB: Flattening 1 table and a non-table type.
type TableFlatten_TestB = Expect<
    TableFlatten<{ hello: "world", foo: "bar", baz: "bix" } & string>,
    { hello: "world", foo: "bar", baz: "bix" } & string
>

-- TestC: Flattening 1 table with a union of non-table types.
type TableFlatten_TestC = Expect<
    TableFlatten<{ hello: "world", foo: "bar", baz: "bix" } & (string | number)>,
    (({ hello: "world", foo: "bar", baz: "bix" } & string) | ({ hello: "world", foo: "bar", baz: "bix" } & number))
>

-- TestD: Flattening 1 table with a nested union of non-table types.
type TableFlatten_TestD = Expect<
    Flatten<TableFlatten<{ hello: "world", foo: "bar", baz: "bix" } & (string | (number | boolean))>>,
    (({ hello: "world", foo: "bar", baz: "bix" } & string) | 
    ({ hello: "world", foo: "bar", baz: "bix" } & number) |
    ({ hello: "world", foo: "bar", baz: "bix" } & boolean))
>

-- TestE: Flattening an intersection of multiple tables where each table has no overlap.
type TableFlatten_TestE = Expect<
    TableFlatten<{ hello: "world", foo: "bar" } & { baz: "bix" }>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestF: Flattening an intersection of multiple tables which overlap.
type TableFlatten_TestF = Expect<
    TableFlatten<{ hello: "world", foo: "bar" } & { hello: "second", baz: "bix" }>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestG: Flattening an intersection of a table and an intersection of two tables.
type TableFlatten_TestG = Expect<
    TableFlatten<{ hello: "world" } & ({ foo: "bar" } & { baz: "bix" })>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestH: Flattening a union of two tables with no overlap.
type TableFlatten_TestH = Expect<
    TableFlatten<{ hello: "world" } | { foo: "bar" }>,
    { hello: "world" } | { foo: "bar" }
>

-- TestI: Flattening a union of two tables which overlap (should be the same as if they didn't overlap).
type TableFlatten_TestI = Expect<
    TableFlatten<{ hello: "world", foo: "bar" } | { foo: "bar" }>,
    { hello: "world", foo: "bar" } | { foo: "bar" }
>

-- TestJ: Flattening a union of an intersection of two tables with one table.
type TableFlatten_TestJ = Expect<
    TableFlatten<(({ hello: "world" } & { foo: "bar" }) | { baz: "bix" })>,
    { hello: "world", foo: "bar" } | { baz: "bix" }
>

-- TestK: Flattening a union of an intersection of two tables with two tables.
type TableFlatten_TestK = Expect<
    TableFlatten<(({ hello: "world" } & { foo: "bar" }) | { baz: "bix" } | { lol: "kek" })>,
    { hello: "world", foo: "bar" } | { baz: "bix" } | { lol: "kek" }
>

-- TestL: Flattening a union of an intersection of two tables with nested tables.
type TableFlatten_TestL = Expect<
    TableFlatten<(({ hello: "world" } & { foo: "bar" }) | ({ baz: "bix" } | ({ lol: "kek" } | { right: "wrong" })))>,
    Flatten<(({ hello: "world", foo: "bar" }) | ({ baz: "bix" } | ({ lol: "kek" } | { right: "wrong" })))>
>

-- TestM: Flattening a intersection of an intersection of two tables with one table.
type TableFlatten_TestM = Expect<
    TableFlatten<(({ hello: "world" } & { foo: "bar" }) & { baz: "bix" })>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestN: Flattening a intersection of an intersection of two tables with two tables.
type TableFlatten_TestN = Expect<
    TableFlatten<(({ hello: "world" } & { foo: "bar" }) & { baz: "bix" } & { lol: "kek" })>,
    { hello: "world", foo: "bar", baz: "bix", lol: "kek" }
>

-- TestO: Flattening a intersection of an union of two tables with two tables.
type TableFlatten_TestO = Expect<
    TableFlatten<(({ hello: "world" } | { foo: "bar" }) & { baz: "bix" } & { lol: "kek" })>,
    { baz: "bix", lol: "kek", hello: "world" } | { baz: "bix", lol: "kek", foo: "bar" }
>

-- TestP: Flattening a intersection of an union of a table and a non-table type with a table.
type TableFlatten_TestP = Expect<
    TableFlatten<(({ hello: "world" } | string) & { foo: "bar" })>,
    { foo: "bar", hello: "world" } | ({ foo: "bar" } & string)
>

-- TestQ: Flattening a intersection of an intersection of a table and a non-table type with a table.
type TableFlatten_TestQ = Expect<
    Flatten<TableFlatten<(({ hello: "world" } & string) & { foo: "bar" })>>,
    Flatten<({ hello: "world" } & ({ foo: "bar" } & string))>
>

-- TestR: Flattening a intersection of an union of two tables with a table.
type TableFlatten_TestR = Expect<
    TableFlatten<(({ hello: "world" } | { baz: "bix" }) & { foo: "bar" })>,
    { foo: "bar", hello: "world" } | { foo: "bar", baz: "bix" }
>

-- TestS: Flattening a intersection of an intersection of two tables with a table.
type TableFlatten_TestS = Expect<
    TableFlatten<(({ hello: "world" } & { baz: "bix" }) & { foo: "bar" })>,
    { hello: "world", baz: "bix", foo: "bar" }
>

-- Test T: Flattening an intersection of two tables where the first one has an indexer.
type TableFlatten_TestT = Expect<
    TableFlatten<{ [string]: any } & { Name: string }>,
    { Name: string, [string]: any }
>

-- Test U: Flattening an intersection of two tables where the second one has an indexer.
type TableFlatten_TestU = Expect<
    TableFlatten<{ Name: string } & { [string]: any }>,
    { Name: string, [string]: any }
>
------------------------------------------------------


-- Partial -------------------------------------------
-- Test A: Making a table partial without an indexer partial.
type Partial_TestA = Expect<
    Partial<{ Name: string, Age: number }>,
    { Name: string?, Age: number? }
>

-- Test B: Making a table partial with an indexer partial.
type Partial_TestB = Expect<
    Partial<{ Name: string, Age: number, [string]: any }>,
    { Name: string?, Age: number?, [string]: any? }
>
------------------------------------------------------


-- ReadOnly ------------------------------------------
-- Test A: Making a table read only.
type ReadOnly_TestA = Expect<
    ReadOnly<{ Name: string, Age: number }>,
    { read Name: string, read Age: number }
>

-- Test B: Making a table with an indexer read only.
-- TODO: Once luau supports read-only indexers then uncomment the `read` statements.
type ReadOnly_TestB = Expect<
    ReadOnly<{ Name: string, Age: number, [string]: any }>,
    { read Name: string, read Age: number, --[[read]] [string]: any }
>
------------------------------------------------------


-- ReadWrite -----------------------------------------
-- Test A: Making a table read-write.
type ReadWrite_TestA = Expect<
    ReadWrite<{ Name: string, Age: number }>,
    { Name: string, Age: number }
>

-- Test B: Making a table with an indexer read-write.
-- TODO: Once luau supports read-only indexers then uncomment the `read` statements.
type ReadWrite_TestB = Expect<
    ReadWrite<{ read Name: string, read Age: number, --[[read]] [string]: any }>,
    { Name: string, Age: number, [string]: any }
>
------------------------------------------------------


-- ValueOf -------------------------------------------
-- Test A: Gets values of a table with no literal values of different types.
type ValueOf_TestA = Expect<
    ValueOf<{ Name: string, Age: number }>,
    number | string
>

-- Test B: Gets values of a table with no literal values of the same type.
type ValueOf_TestB = Expect<
    ValueOf<{ Name: string, Age: string }>,
    string
>

-- Test C: Gets values of a table with literal values.
type ValueOf_TestC = Expect<
    ValueOf<{ Name: "Bob", Age: "54" }>,
    "54" | "Bob"
>

-- Test D: Gets values of a table with indexer with no literal values.
type ValueOf_TestD = Expect<
    ValueOf<{ Name: string, Age: number, [string]: boolean }>,
    string | number | boolean
>


-- Test E: Gets values of a table with indexer with literal values.
type ValueOf_TestE = Expect<
    ValueOf<{ Name: "Bob", Age: "54", [string]: "false" }>,
    "54" | "Bob" | "false"
>

-- Test F: Gets values of a table with indexer - a mix of literal and none-literal values.
type ValueOf_TestF = Expect<
    ValueOf<{ Name: "Bob", Age: number, [string]: "false" }>,
    "Bob" | "false" | number
>
------------------------------------------------------


-- RemoveIndexer -------------------------------------
-- TestA: Removes indexer from table.
type RemoveIndexer_TestA = Expect<RemoveIndexer<{ [string]: number }>, {}>
------------------------------------------------------


-- SetIndexer ----------------------------------------
-- TestA: Sets indexer for a table.
type SetIndexer_TestA = Expect<SetIndexer<{ }, string, number>, { [string]: number }>
------------------------------------------------------


-- TableToCamel --------------------------------------
-- Test A: Converts a table with no indexer to camel case.
type TableToCamel_TestA = Expect<
    TableToCamel<{ Name: string, Age: number }>,
    { name: string, age: number }
>

-- Test B: Converts a table with a string non-literal indexer to camel case.
type TableToCamel_TestB = Expect<
    TableToCamel<{ Name: string, Age: number, [string]: number }>,
    { name: string, age: number, [string]: number }
>

-- Test C: Converts a table with a string literal indexer to camel case.
type TableToCamel_TestC = Expect<
    TableToCamel<{ Name: string, Age: number, [string | "Id"]: number }>,
    { name: string, age: number, [string | "id"]: number }
>
------------------------------------------------------


-- TableToPascal -------------------------------------
-- Test A: Converts a table with no indexer to pascal case.
type TableToPascal_TestA = Expect<
    TableToPascal<{ name: string, age: number }>,
    { Name: string, Age: number }
>

-- Test B: Converts a table with a string non-literal indexer to pascal case.
type TableToPascal_TestB = Expect<
    TableToPascal<{ name: string, age: number, [string]: number }>,
    { Name: string, Age: number, [string]: number }
>

-- Test C: Converts a table with a string literal indexer to pascal case.
type TableToPascal_TestC = Expect<
    TableToPascal<{ name: string, age: number, [string | "id"]: number }>,
    { Name: string, Age: number, [string | "Id"]: number }
>
------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> Union ---------------------------------------------------------------------------------------------
-- UnionPick ------------------------------------------
-- TestA: Pick one non-literal type from a union.
type UnionPick_TestA = Expect<
    UnionPick<string | number | "foo" | "bar", string>,
    string
>

-- TestB: Pick multiple non-literal types from a union.
type UnionPick_TestB = Expect<
    UnionPick<string | number | "foo" | "bar", string | number>,
    string | number
>

-- TestC: Picks 1 literal type from a union.
type UnionPick_TestC = Expect<
    UnionPick<string | number | "foo" | "bar", "foo">,
    "foo"
>

-- TestD: Picks multiple literal types from a union.
type UnionPick_TestD = Expect<
    UnionPick<string | number | "foo" | "bar", "foo" | "bar">,
    "foo" | "bar"
>
-------------------------------------------------------


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
type UnionFlatten_TestA = Expect<
    UnionFlatten<((string | "foo") | (number | "bar"))>,
    string | "foo" | number | "bar"
>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> Function Types ------------------------------------------------------------------------------------
-- Args -----------------------------------------------
-- Test A: Function with no arguments.
type Args_TestA = Expect<Args<() -> any>, {}>

-- Test B: Function with arguments.
type Args_TestB = Expect<Args<(string, number) -> any>, {
    ["1"]: string,
    ["2"]: number
}>

-- Test C: Function with arguments and a variadic tail.
type Args_TestC = Expect<Args<(string, number, ...boolean) -> any>, {
    ["1"]: string,
    ["2"]: number,
    Tail: boolean
}>

-- Test D: Function with only a variadic tail.
type Args_TestD = Expect<Args<(...boolean) -> any>, {
    Tail: boolean
}>
-------------------------------------------------------


-- SetArgs --------------------------------------------
-- Test A: Setting arguments for function with no arguments.
type SetArgs_TestA = Expect<SetArgs<() -> any, {
    ["1"]: string,
    ["2"]: number
}>, (string, number) -> any>

-- Test B: Setting arguments for function with arguments.
type SetArgs_TestB = Expect<SetArgs<(boolean, "world") -> any, {
    ["1"]: string,
    ["2"]: number
}>, (string, number) -> any>

-- Test C: Setting arguments and a variadic tail.
type SetArgs_TestC = Expect<SetArgs<() -> any, {
    ["1"]: string,
    ["2"]: number,
    Tail: boolean
}>, (string, number, ...boolean) -> any>

-- Test D: Setting only a variadic tail.
type SetArgs_TestD = Expect<SetArgs<() -> any, {
    Tail: number
}>, (...number) -> any>
-------------------------------------------------------


-- Returns --------------------------------------------
-- Test A: Function with return types.
type Returns_TestA = Expect<
    Returns<() -> (string, number)>,
    {
        ["1"]: string,
        ["2"]: number
    }
>

-- Test B: Function with return types and a variadic tail.
type Returns_TestB = Expect<
    Returns<() -> (string, number, ...boolean)>,
    {
        ["1"]: string,
        ["2"]: number,
        ["Tail"]: boolean
    }
>

-- Test C: Function with only a variadic tail.
type Returns_TestC = Expect<
    Returns<() -> ...boolean>,
    {
        ["Tail"]: boolean
    }
>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> String Types --------------------------------------------------------------------------------------
-- StringToCamel --------------------------------------
-- TestA: Converts string literal to camel case.
type StringToCamel_TestA = Expect<StringToCamel<"Name">, "name"> 

-- TestB: Converts invalid type to camel case.
type StringToCamel_TestB = Expect<StringToCamel<boolean>, boolean> 
-------------------------------------------------------


-- StringToPascal -------------------------------------
-- TestA: Converts string literal to pascal case.
type StringToPascal_TestA = Expect<StringToPascal<"name">, "Name"> 

-- TestB: Converts invalid type to pascal case.
type StringToPascal_TestB = Expect<StringToPascal<boolean>, boolean> 
-------------------------------------------------------


-- StringToLower --------------------------------------
-- TestA: Converts string literal to lower case.
type StringToLower_TestA = Expect<StringToLower<"Name">, "name"> 

-- TestB: Converts invalid type to lower case.
type StringToLower_TestB = Expect<StringToLower<boolean>, boolean> 
-------------------------------------------------------


-- StringToUpper --------------------------------------
-- TestA: Converts string literal to upper case.
type StringToUpper_TestA = Expect<StringToUpper<"Name">, "NAME"> 

-- TestB: Converts invalid type to upper case.
type StringToUpper_TestB = Expect<StringToUpper<boolean>, boolean> 
-------------------------------------------------------


-- StringReplace --------------------------------------
-- TestA: Replaces string.
type StringReplace_TestA = Expect<StringReplace<"Wolf", "f$", "ves">, "Wolves"> 
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


--> Boolean Operation Types ---------------------------------------------------------------------------
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


--> Logical Operation Types ---------------------------------------------------------------------------
-- Extends --------------------------------------------
-- TestA: Tests to see if string extends string.
type Extends_TestA = Expect<Extends<string, string>, true>

-- TestB: Tests to see if a string literal extends string.
type Extends_TestB = Expect<Extends<"hello", string>, true>

-- TestC: Tests to see if string extends a string literal.
type Extends_TestC = Expect<Extends<string, "hello">, false>

-- TestD: Tests to see if a table with properties extends an empty table.
type Extends_TestD = Expect<Extends<{ hello: "world" }, {}>, true>

-- TestE: Tests to see if an empty table extends a table with properties.
type Extends_TestE = Expect<Extends<{}, { hello: "world" }>, false>

-- TestF: Tests to see if a union of string and string extends string.
type Extends_TestF = Expect<Extends<string | string, string>, true>

-- TestG: Tests to see if string extends a union of string and string.
type Extends_TestG = Expect<Extends<string, string | string>, true>

-- TestH: Tests to see if a union of two string literals extends string.
type Extends_TestH = Expect<Extends<"hello" | "world", string>, true>

-- TestI: Tests to see if string extends a union of two string literals.
type Extends_TestI = Expect<Extends<string, "hello" | "world">, false>

-- TestJ: Tests to see if string extends a union of string and boolean.
type Extends_TestJ = Expect<Extends<string, string | boolean>, true>

-- TestK: Tests to see if a union of string and boolean extends string.
type Extends_TestK = Expect<Extends<string | boolean, string>, false>

-- TestL: Tests to see if string extends never.
type Extends_TestL = Expect<Extends<string, never>, false>

-- TestM: Tests to see if never extends string.
type Extends_TestM = Expect<Extends<never, string>, false>

-- TestN: Tests to see if any extends string.
type Extends_TestN = Expect<Extends<any, string>, false>

-- TestO: Tests to see if any extends string | number
type Extends_TestO = Expect<Extends<any, string | number>, false>

-- TestP: Tests to see if a string literal extends a union of any and true
type Extends_TestP = Expect<Extends<"hello", any | true>, false>

-- TestQ: Tests to see if a string literal extends the same string literal.
type Extends_TestQ = Expect<Extends<"hello", "hello">, true>

-- TestR: Tests to see if a string literal extends a different string literal.
type Extends_TestR = Expect<Extends<"hello", "world">, false>

-- TestS: Tests to see if a union of a table with properties and string extends an empty table.
type Extends_TestS = Expect<Extends<{ hello: "world" } | string, {}>, false>

-- TestT: Tests to see if a union of a table with properties and string extends a union of an empty table and a string.
type Extends_TestT = Expect<Extends<{ hello: "world" } | string, {} | string>, true>

-- TestT: Tests to see if a table with properties extends a table with properties taken from that first table.
type Extends_TestU = Expect<Extends<{ hello: "world", foo: "bar" }, { hello: "world" }>, true>

-- TestV: Tests to see if a table with properties extends a table with properties taken from that first table.
type Extends_TestV = Expect<Extends<{ hello: "world", foo: "bar" }, { hello: "world" }>, true>

-- TestW: Tests to see if a union of a table with properties and string extends a table with properties taken from that first table.
type Extends_TestW = Expect<Extends<{ hello: "world", foo: "bar" } | string, { hello: "world" }>, false>

-- TestX: Tests to see if a table with properties extends a table with properties taken from that first table as well as extra properties.
type Extends_TestX = Expect<Extends<{ hello: "world" }, { hello: "world", foo: "bar" }>, false>

-- TestY: Tests to see if a union of a table with properties and string extends
-- a table with properties taken from that first table as well as extra properties.
type Extends_TestY = Expect<Extends<{ hello: "world" } | string, { hello: "world", foo: "bar" }>, false>


-- TestZ: Tests to see if a table with properties extends a union of a table with properties taken from that first table and string.
type Extends_TestZ = Expect<Extends<{ hello: "world", foo: "bar" }, { hello: "world" } | string>, true>


-- TestZA: Tests to see if a table with property whos value is a string literal
-- extends a table with the same property but with a different string literal.
type Extends_TestZA = Expect<Extends<{ kind: "Customer" }, { kind: "Employee" }>, false>
-------------------------------------------------------

-- TestZB: Tests to see if a table with property whos value is a
-- string literal extends a table with the same property.
type Extends_TestZB = Expect<Extends<{ kind: "Customer" }, { kind: "Customer" }>, true>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------