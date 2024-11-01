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
    _safeIs(assert(input, toAssert), `Expected the type argument \`{argName}\` to be of type \`{toAssert}\``)
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

type function _safeValue(input: any)
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
    for idx = #arr, 1, -1 do
        if not Equals(arr[idx], toOmit):value() then continue end
        table.remove(arr, idx)
        break
    end
end

type function _arrayOmitExtends(arr: { any }, toOmit: any)
    for idx = #arr, 1, -1 do
        if not Extends(arr[idx], toOmit):value() then continue end
        table.remove(arr, idx)
    end
end

type function _arrayPick(key: any, inputComponents: { any }, output: { any })
    for _, comp in inputComponents do
        if not Equals(comp, key):value() then continue end
        table.insert(output, comp)
        break
    end
end

type function _arrayPickExtends(key: any, inputComponents: { any }, output: { any })
    for _, comp in inputComponents do
        if not Extends(comp, key):value() then continue end
        table.insert(output, comp)
    end
end

type function _arraySingletonsToValues(input: any)
    for idx, comp in input do input[idx] = _safeValue(comp) end
    return input
end

type function _arrayValuesToSingletons(input: any)
    for idx, comp in input do input[idx] = _valueToSingleton(comp) end
    return input
end

type function _arrayHasType(input: { any }, t: any)
    for _, value in input do
        if Equals(value, t):value() then return true end
    end
    return false
end


type function _unionToArray(input: any)
    if not _safeIs(input, "union") then return { input } end
    return input:components()
end


type function _tableSetProperty(input: { [any]: any }, key: any, read: any, write: any)
    input:setreadproperty(key, read)
    -- The `write == read` comparison is to ensure that the property is not
    -- unnecessarily separated into 2 different read write properties.
    if write then input:setwriteproperty(key, if (read and write) and Equals(write, read) then read else write) end
end

type function _tableMap(input: { any }, fn: (item: any, idx: number) -> ...any)
    local output = table.create(#input)
    for idx, item in input do output[idx] = fn(item, idx) end
    return output
end

type function _tableFindWriteValue(input: { [any]: any }, writeKey: any)
    writeKey = _safeValue(writeKey)

    for key, value in input:properties() do
        if _safeValue(key) == writeKey then return value.write end
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

type function _toRequired(input: any)
    return UnionOmit(input, types.singleton(nil))
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
    -- We need to copy `inputA` as we may mutate it later.
    inputA = types.copy(inputA)
    local inputBProps = inputB:properties()

    local nilSingleton = types.singleton(nil)

    -- Iterates over all of the partial keys from inputB and if they don't exist in 
    -- inputA then they are explicitly inserted with the singleton value of nil.
    for key, value in PickPartial(inputB):properties() do
        if not inputA:readproperty(key) then
            inputA:setreadproperty(key, nilSingleton)
        end

        if not inputA:writeproperty(key) then
            inputA:setwriteproperty(key, nilSingleton)
        end
    end

    if _propsLength(inputA:properties()) ~= _propsLength(inputBProps) then return false end

    for key, value in inputBProps do
        local inputBRead, inputBWrite = value.read, value.write
        local inputARead, inputAWrite = inputA:readproperty(key), inputA:writeproperty(key)

        if (inputARead and not inputBRead) or (inputBRead and not inputARead) then return false end
        if (inputAWrite and not inputBWrite) or (inputBWrite and not inputAWrite) then return false end

        if inputARead and inputBRead then
            if not Extends(inputARead, inputBRead):value() then return false end
        end

        if inputAWrite and inputBWrite then
            if not Extends(inputAWrite, inputBWrite):value() then return false end
        end
    end

    return true
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
        if _safeIs(input, "table") then TablePick(input, toOmit)
        elseif _safeIs(input, "union") then UnionPick(input, toOmit)
        elseif _safeIs(input, "intersection") then IntersectionPick(input, toOmit)
        else input
end


--[=[
    Outputs the inputted type but only with components which extends the specified types.

    @param input any -- The type to pick components/properties from.
    @param toPick any -- The union of types (or a singleton/primitive) to pick from.
]=]
type function PickExtends(input: { [any]: any }, toOmit: any)
    return
        if _safeIs(input, "table") then TablePickExtends(input, toOmit)
        elseif _safeIs(input, "union") then UnionPickExtends(input, toOmit)
        elseif _safeIs(input, "intersection") then IntersectionPickExtends(input, toOmit)
        else input
end


--[=[
    Outputs the inputted type but with specificied components/properties removed.

    @param input any -- The type to omit components/properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omit from.
]=]
type function Omit(input: { [any]: any }, toOmit: any)
    return
        if _safeIs(input, "table") then TableOmit(input, toOmit)
        elseif _safeIs(input, "intersection") then IntersectionOmit(input, toOmit)
        else UnionOmit(input, toOmit)
end


--[=[
    Outputs the inputted type but without components which extends the specified types.

    @param input any -- The type to omit components/properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function OmitExtends(input: { [any]: any }, toOmit: any)
    return
        if _safeIs(input, "table") then TableOmitExtends(input, toOmit)
        elseif _safeIs(input, "intersection") then IntersectionOmitExtends(input, toOmit)
        else UnionOmitExtends(input, toOmit)
end


--[=[
    Removes duplicate components from unions and intersections including inside table keys, values and indexers.

    @param input any -- The type to clean.
]=]
type function Clean(input: { [any]: any })
    input = Flatten(input)

    return
        if _safeIs(input, "table") then TableClean(input)
        elseif _safeIs(input, "union") then UnionClean(input)
        elseif _safeIs(input, "intersection") then IntersectionClean(input)
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
        if _safeIs(inputA, "table") and _safeIs(inputB, "table") then return TableEquals(inputA, inputB) end
        if _safeIs(inputA, "union") and _safeIs(inputB, "union") then return UnionEquals(inputA, inputB) end
        if _safeIs(inputA, "intersection") and _safeIs(inputB, "intersection") then return IntersectionEquals(inputA, inputB) end
        if _safeIs(inputA, "function") and _safeIs(inputB, "function") then return FunctionEquals(inputA, inputB) end
    end

    return types.singleton(_safeValue(inputA) == _safeValue(inputB))
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


--[=[
    Returns true if the inputted type is empty.

    @param input any -- The type to test emptiness for.
]=]
type function IsEmpty(input: { [any]: any } | string)
    if _safeIs(input, "table") then return TableIsEmpty(input)
    else return StringIsEmpty(input) end
end


--[=[
    Outputs a union of the inputted type and a nil singleton type.

    @param input any -- The type to make nilable.
]=]
type function Nilable(input: any)
    local nilSingleton = types.singleton(nil)

    -- Returns the inputted type if it already nilable.
    if Extends(nilSingleton, input):value() then return input end

    if _safeIs(input, "union") then
        return _arrayToUnion(input:components(), nilSingleton)
    else
        return types.unionof(input, nilSingleton)
    end
end


--[=[
    Outputs a union of the inputted type but with nil singleton types removed.

    @param input any -- The type to make non-nilable.
]=]
type function NonNilable(input: any)
    return UnionOmit(input, types.singleton(nil))
end


--[=[
    Outputs true if the inputted type is nilable.

    @param input any -- The type to test to see if it is nilable.
]=]
type function IsNilable(input: any)
    return Extends(types.singleton(nil), input)
end


--[=[
    Outputs true if the inputted type is non-nilable.

    @param input any -- The type to test to see if it is non-nilable.
]=]
type function IsNonNilable(input: any)
    return Not(Extends(types.singleton(nil), input))
end
-------------------------------------------------------------------------------------------------------


--> Table ---------------------------------------------------------------------------------------------
--[=[
    Outputs the inputted table but only with specified properties.

    @param input { [any]: any } -- The table to pick properties from.
    @param toPick any -- The union of types or a singleton/primitive to be picked.
]=]
type function TablePick(input: { [any]: any }, toPick: any)
    if _safeIs(input, "union") then
        return _arrayToUnion(_tableMap(UnionFlatten(input):components(), function(comp) return TablePick(comp, toPick) end))
    end
    if _safeIs(input, "intersection") then
        return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), function(comp) return TablePick(comp, toPick) end))
    end
    _assertIs(input, "input", "table")

    input = TableFlatten(input)
    local output = types.newtable()

    local function pickKey(key: any)
        if not _safeIs(key, "singleton") then return end
        _tableSetProperty(output, key, input:readproperty(key), input:writeproperty(key))
    end

    if _safeIs(toPick, "union") then
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
    Outputs the inputted table but only with properties whos keys extends the specified types.

    @param input { [any]: any } -- The table to pick properties from.
    @param toPick any -- The union of types or a singleton/primitive to pick from.
]=]
type function TablePickExtends(input: { [any]: any }, toPick: any)
    if _safeIs(input, "union") then
        return _arrayToUnion(_tableMap(UnionFlatten(input):components(), function(comp) return TablePick(comp, toPick) end))
    end
    if _safeIs(input, "intersection") then
        return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), function(comp) return TablePick(comp, toPick) end))
    end
    _assertIs(input, "input", "table")

    input = TableFlatten(input)
    local output = types.newtable()

    local function pickKey(keyToPick: any)
        for key, value in input:properties() do
            if Extends(key, keyToPick):value() then
                _tableSetProperty(output, key, value.read, value.write)

                -- Removes the key from the flattened (and cloned) input so that it can't be picked more than once.
                input:setproperty(key, types.singleton(nil))
            end
        end
    end

    if _safeIs(toPick, "union") then
        for _,keyToPick in toPick:components() do pickKey(keyToPick) end
    else
        pickKey(toPick)
    end

    local indexer = input:indexer()
    if indexer then
        output:setindexer(UnionPickExtends(indexer.index, toPick), indexer.writeresult)
    end

    return output
end


--[=[
    Outputs the inputted table but with specified properties omitted.

    @param input { [any]: any } -- The table to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function TableOmit(input: { [any]: any }, toOmit: any)
    if _safeIs(input, "union") then
        return _arrayToUnion(_tableMap(UnionFlatten(input):components(), function(comp) return TableOmit(comp, toOmit) end))
    end
    if _safeIs(input, "intersection") then
        return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), function(comp) return TableOmit(comp, toOmit) end))
    end
    _assertIs(input, "input", "table")
    
    local output = TableFlatten(input)

    local function omitKey(key: any)
        if _safeIs(key, "singleton") then output:setproperty(key, nil) end
    end

    if _safeIs(toOmit, "union") then
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
    Outputs the inputted table but without components which extends the specified types.

    @param input { [any]: any } -- The table to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to omit from.
]=]
type function TableOmitExtends(input: { [any]: any }, toOmit: any)
    if _safeIs(input, "union") then
        return _arrayToUnion(_tableMap(UnionFlatten(input):components(), function(comp) return TableOmit(comp, toOmit) end))
    end
    if _safeIs(input, "intersection") then
        return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), function(comp) return TableOmit(comp, toOmit) end))
    end
    _assertIs(input, "input", "table")
    
    local output = TableFlatten(input)

    local function omitKey(keyToPick: any)
        for key, value in input:properties() do
            if Extends(key, keyToPick):value() then
                output:setproperty(key, nil)
            end
        end
    end

    if _safeIs(toOmit, "union") then
        for _,keyToOmit in toOmit:components() do omitKey(keyToOmit) end
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
    if _safeIs(input, "table") then return input end
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), TableFlatten)) end
    if not _safeIs(input, "intersection") then return input end

    local output = types.newtable()
    local options, extra = {}, {}
    local outputIndexer

    for _,comp in input:components() do
        if _safeIs(comp, "intersection") then comp = TableFlatten(comp) end

        if _safeIs(comp, "union") then
            _tableInsertMany(options, comp:components()) 
            continue
        
        elseif _safeIs(comp, "intersection") then
            _tableInsertMany(extra, comp:components())
            continue

        elseif not _safeIs(comp, "table") then
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
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), TableClean)) end
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), TableClean)) end
    if not _safeIs(input, "table") then return input end

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
    if not _safeIs(inputA, "table") or not _safeIs(inputB, "table") then return types.singleton(false) end

    local inputAPropsLength, inputBPropsLength = _tablePropsLength(inputA), _tablePropsLength(inputB)
    -- If they don't have the same amount of properties then we know they are not equal.
    if inputAPropsLength ~= inputBPropsLength then return types.singleton(false) end

    for key, value in inputA:properties() do
        local inputARead, inputAWrite = value.read, value.write
        local inputBRead, inputBWrite = inputB:readproperty(key), inputB:writeproperty(key)

        if Equals(inputARead, inputBRead):value() and Equals(inputAWrite, inputBWrite):value() then continue end
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

    for key, value in inputAProps do
        local inputARead, inputAWrite = value.read, value.write
        local inputBRead, inputBWrite = inputB:readproperty(key), inputB:writeproperty(key)

        local maybeRead = if inputARead and not inputBRead then inputARead else nil
        local maybeWrite = if inputAWrite and not inputBWrite then inputAWrite else nil
        _tableSetProperty(output, key, maybeRead, maybeWrite)
    end

    for key, value in inputBProps do
        local inputBRead, inputBWrite = value.read, value.write
        local inputARead, inputAWrite = inputA:readproperty(key), inputA:writeproperty(key)

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

    for key, value in inputAProps do
        local inputARead, inputAWrite = value.read, value.write
        local inputBRead, inputBWrite = inputB:readproperty(key), inputB:writeproperty(key)

        local maybeRead = if Equals(inputARead, inputBRead):value() then inputARead else nil
        local maybeWrite = if Equals(inputAWrite, inputBWrite):value() then inputAWrite else nil
        _tableSetProperty(output, key, maybeRead, maybeWrite)
    end

    for key, value in inputBProps do
        local inputBRead, inputBWrite = value.read, value.write
        local inputARead, inputAWrite = inputA:readproperty(key), inputA:writeproperty(key)

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
    Outputs a type where another type needs to have at least one of the properties from the input type in order to satify it.

    @param input { [any]: any } -- The table type input.
]=]
type function TableAtLeast(input: { [any]: any })
    local keysArr = _unionToArray(_keyof(input))
    local output = table.create(#keysArr)

    local inputPartial = Partial(input)

    for idx, chosenKey in keysArr do

        local subOutput = types.copy(inputPartial)
        _tableSetProperty(subOutput, chosenKey, _toRequired(subOutput:readproperty(chosenKey)),  _toRequired(subOutput:writeproperty(chosenKey)))
        output[idx] = subOutput
    end

    return _arrayToUnion(output)
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
    Picks all the partial keys from a table.

    @param input { [any]: any } -- The table to pick partial keys from.
]=]
type function PickPartial(input: { [any]: any })
    local output = types.newtable()
    local nilSingleton = types.singleton(nil)

    for key, value in input:properties() do
        local read, write = value.read, value.write
        if (read and write) and Equals(read, write) then read = write end

        if Extends(nilSingleton, read):value() then output:setreadproperty(key, read) end
        if Extends(nilSingleton, write):value() then output:setwriteproperty(key, write) end
    end

    local indexer = input:indexer()
    if indexer then
        local indexerValue = indexer.writeresult or indexer.readresult
        if Extends(indexerValue, nilSingleton) then
            output:setindexer(indexer.index, indexer.writeresult or indexer.readresult)
        end
    end

    return output
end


--[=[
    Makes all of the properties in a table required.

    @param input { [any]: any } -- The table to make required.
]=]
type function Required(input: { [any]: any })
    input = TableFlatten(input)
    _assertIs(input, "input", "table")

    local output = types.newtable()

    for key, value in input:properties() do
        _tableSetProperty(output, key, _toRequired(value.read), _toRequired(value.write))
    end

    local indexer = input:indexer()
    if indexer then
        output:setindexer(indexer.index, _toRequired(indexer.writeresult or indexer.readresult))
    end

    return output
end


--[=[
    Picks all the required keys from a table.

    @param input { [any]: any } -- The table to pick required keys from.
]=]
type function PickRequired(input: { [any]: any })
    local output = types.newtable()
    local nilSingleton = types.singleton(nil)

    for key, value in input:properties() do
        local read, write = value.read, value.write
        if (read and write) and Equals(read, write) then read = write end

        if not Extends(nilSingleton, read):value() then output:setreadproperty(key, read) end
        if not Extends(nilSingleton, write):value() then output:setwriteproperty(key, write) end
    end

    local indexer = input:indexer()
    if indexer then
        local indexerValue = indexer.writeresult or indexer.readresult
        if Extends(indexerValue, nilSingleton) then
            output:setindexer(indexer.index, indexer.writeresult or indexer.readresult)
        end
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
            _safeIs(read, "table") and TableToCamel(read) or read,
            _safeIs(write, "table") and TableToCamel(write) or write
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
            _safeIs(read, "table") and TableToPascal(read) or read,
            _safeIs(write, "table") and TableToPascal(write) or write
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
            _safeIs(read, "table") and TableToUpper(read) or read,
            _safeIs(write, "table") and TableToUpper(write) or write
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
            _safeIs(read, "table") and TableToLower(read) or read,
            _safeIs(write, "table") and TableToLower(write) or write
        )
    end

    return output
end


--[=[
    Returns true if the table is empty.

    @param input { [any]: any } -- The table to test emptiness for.
]=]
type function TableIsEmpty(input: { [any]: any })
    return types.singleton(_tableIsEmpty(input))
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
    local inputComponents = _safeIs(input, "union") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }
    local output = {}

    if _safeIs(toPick, "union") then
        for _,comp in toPick:components() do _arrayPick(_safeValue(comp), inputComponents, output) end
        
    else _arrayPick(_safeValue(toPick), inputComponents, output) end

    return _arrayToUnion(_arrayValuesToSingletons(output))
end


--[=[
    Outputs the inputted union or singleton/primitive but only with components which extends the specified types.

    @param union any -- The union or singleton/primitive to pick components from.
    @param toPick any -- The union of types (or a singleton/primitive) to pick from.
]=]
type function UnionPickExtends(input: any, toPick: any)
    input, toPick = UnionFlatten(input), Clean(Flatten(toPick))
    local inputComponents = _safeIs(input, "union") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }
    local output = {}

    if _safeIs(toPick, "union") then
        for _,comp in toPick:components() do _arrayPickExtends(_safeValue(comp), inputComponents, output) end
        
    else _arrayPickExtends(_safeValue(toPick), inputComponents, output) end

    return _arrayToUnion(_arrayValuesToSingletons(output))
end


--[=[
    Outputs the inputted union or singleton/primitive but with specified components omitted.

    @param input any -- The union or singleton/primitive to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function UnionOmit(input: any, toOmit: any)
    input = UnionFlatten(input)
    local outputComponents = _safeIs(input, "union") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }

    if _safeIs(toOmit, "union") then
        for _,comp in toOmit:components() do
            _arrayOmit(outputComponents, _safeValue(comp))
        end

    else _arrayOmit(outputComponents, _safeValue(toOmit)) end

    return _arrayToUnion(_arrayValuesToSingletons(outputComponents))
end


--[=[
    Outputs the inputted union or singleton/primitive but without components which extends the specified types.

    @param input any -- The union or singleton/primitive to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to omit from.
]=]
type function UnionOmitExtends(input: any, toOmit: any)
    input = UnionFlatten(input)
    local outputComponents = _safeIs(input, "union") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }

    if _safeIs(toOmit, "union") then
        for _,comp in toOmit:components() do
            _arrayOmitExtends(outputComponents, _safeValue(comp))
        end

    else _arrayOmitExtends(outputComponents, _safeValue(toOmit)) end

    return _arrayToUnion(_arrayValuesToSingletons(outputComponents))
end


--[=[
    Removes duplicate types from a union (or a singleton/primitive).

    @param input any -- The union of types (or a singleton/primitive) to be cleaned.
]=]
type function UnionClean(input: any)
    input = UnionFlatten(input)
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(input:components(), UnionClean)) end
    if not _safeIs(input, "union") then return input end

    local output = {}

    local function maybeInsertIntoCleaned(comp: any)
        comp = _safeValue(comp)

        for _,value in output do
            if Equals(value, comp):value() then return end
        end
        
        table.insert(output, comp)
    end

    for idx,comp in input:components() do
        comp = UnionClean(comp)

        if _safeIs(comp, "union") then
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
    if _safeIs(input, "union") then
        local output = {}

        for _,comp in input:components() do
            if _safeIs(comp, "union") or _safeIs(comp, "intersection") then
                local compOutput = UnionFlatten(comp)
                if _safeIs(compOutput, "union") then
                    _tableInsertMany(output, compOutput:components())
                else
                    table.insert(output, compOutput)
                end
                
            else table.insert(output, comp) end
        end

        return _arrayToUnion(output)

    elseif _safeIs(input, "intersection") then
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
    if _safeIs(inputA, "intersection") and _safeIs(inputB, "union") then return types.singleton(false) end
    if _safeIs(inputB, "intersection") and _safeIs(inputA, "union") then return types.singleton(false) end

    local inputAComponentsLength = _safeIs(inputA, "union") and #inputA:components() or 1
    local inputBComponentsLength = _safeIs(inputB, "union") and #inputB:components() or 1
    if inputAComponentsLength ~= inputBComponentsLength then return types.singleton(false) end

    inputA, inputB = UnionClean(UnionFlatten(inputA)), UnionClean(UnionFlatten(inputB))
    local inputAComponents = _safeIs(inputA, "union") and inputA:components() or { inputA }
    local inputBComponents = _safeIs(inputB, "union") and inputB:components() or { inputB }

    local matches = 0
    for _,compA in inputAComponents do
        for _,compB in inputBComponents do
            if Equals(compA, compB):value() then matches += 1 end
        end
    end

    return types.singleton(if #inputAComponents == matches and #inputBComponents == matches then true else false)
end


--[=[
    Outputs a union of components which only appear in `inputA`, and which only appear in `inputB`.

    @param inputA any -- The first union.
    @param inputB any -- the second union.
]=]
type function UnionDiff(inputA: any, inputB: any)
    local inputAComponents = _safeIs(inputA, "union") and inputA:components() or { inputA }
    local inputBComponents = _safeIs(inputB, "union") and inputB:components() or { inputB }

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
    local inputAComponents = _safeIs(inputA, "union") and inputA:components() or { inputA }
    local inputBComponents = _safeIs(inputB, "union") and inputB:components() or { inputB }

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
    local inputComponents = _safeIs(input, "intersection") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }
    local output = {}

    if _safeIs(toPick, "intersection") then
        for _,comp in toPick:components() do _arrayPick(_safeValue(comp), inputComponents, output) end
        
    else _arrayPick(_safeValue(toPick), inputComponents, output) end

    return _arrayToIntersection(_arrayValuesToSingletons(output))
end


--[=[
    Outputs the inputted intersection or singleton/primitive but only with components which extends the specified types.

    @param input any -- The intersection or singleton/primitive to pick components from.
    @param toPick any -- The union of types (or a singleton/primitive) to pick from.
]=]
type function IntersectionPickExtends(input: any, toPick: any)
    input = IntersectionFlatten(input)
    local inputComponents = _safeIs(input, "intersection") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }
    local output = {}

    if _safeIs(toPick, "intersection") then
        for _,comp in toPick:components() do _arrayPickExtends(_safeValue(comp), inputComponents, output) end
        
    else _arrayPickExtends(_safeValue(toPick), inputComponents, output) end

    return _arrayToIntersection(_arrayValuesToSingletons(output))
end


--[=[
    Outputs the inputted intersection or singleton/primitive but with specified components omitted.

    @param input any -- The intersection or singleton/primitive to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to be omitted.
]=]
type function IntersectionOmit(input: any, toOmit: any)
    input = IntersectionFlatten(input)
    local outputComponents = _safeIs(input, "intersection") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }

    if _safeIs(toOmit, "union") then
        for _,comp in toOmit:components() do
            _arrayOmit(outputComponents, _safeValue(comp))
        end
    else
        _arrayOmit(outputComponents, _safeValue(toOmit))
    end

    return _arrayToIntersection(_arrayValuesToSingletons(outputComponents))
end


--[=[
    Outputs the inputted intersection or singleton/primitive but without components which extends the specified types.

    @param input any -- The intersection or singleton/primitive to omit properties from.
    @param toOmit any -- The union of types (or a singleton/primitive) to omit from.
]=]
type function IntersectionOmitExtends(input: any, toOmit: any)
    input = IntersectionFlatten(input)
    local outputComponents = _safeIs(input, "intersection") and _arraySingletonsToValues(input:components()) or { _safeValue(input) }

    if _safeIs(toOmit, "union") then
        for _,comp in toOmit:components() do
            _arrayOmitExtends(outputComponents, _safeValue(comp))
        end
    else
        _arrayOmitExtends(outputComponents, _safeValue(toOmit))
    end

    return _arrayToIntersection(_arrayValuesToSingletons(outputComponents))
end


--[=[
    Removes duplicate types from a intersection (or a singleton/primitive).

    @param input any -- The intersection of types (or a singleton/primitive) to be cleaned.
]=]
type function IntersectionClean(input: any)
    input = IntersectionFlatten(input)
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(input:components(), IntersectionClean)) end
    if not _safeIs(input, "intersection") then return input end

    local output = {}

    local function maybeInsertIntoCleaned(comp: any)
        comp = _safeValue(comp)
        
        for _,value in output do
            if Equals(value, comp):value() then return end
        end

        table.insert(output, comp)
    end

    for idx,comp in input:components() do
        comp = IntersectionClean(comp)

        if _safeIs(comp, "intersection") then
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
    if _safeIs(input, "intersection") then
        local output = {}

        for _,comp in input:components() do
            if _safeIs(comp, "intersection") or _safeIs(comp, "union") then
                local compOutput = IntersectionFlatten(comp)
                if _safeIs(compOutput, "intersection") then
                    _tableInsertMany(output, compOutput:components())
                else
                    table.insert(output, compOutput)
                end
                
            else table.insert(output, comp) end
        end

        return _arrayToIntersection(output)

    elseif _safeIs(input, "union") then
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
    if _safeIs(inputA, "union") and _safeIs(inputB, "intersection") then return types.singleton(false) end
    if _safeIs(inputB, "union") and _safeIs(inputA, "intersection") then return types.singleton(false) end

    local inputAComponentsLength = _safeIs(inputA, "intersection") and #inputA:components() or 1
    local inputBComponentsLength = _safeIs(inputB, "intersection") and #inputB:components() or 1
    if inputAComponentsLength ~= inputBComponentsLength then return types.singleton(false) end

    inputA, inputB = IntersectionClean(IntersectionFlatten(inputA)), IntersectionClean(IntersectionFlatten(inputB))
    local inputAComponents = _safeIs(inputA, "intersection") and inputA:components() or { inputA }
    local inputBComponents = _safeIs(inputB, "intersection") and inputB:components() or { inputB }

    local matches = 0
    for _,compA in inputAComponents do

        for _,compB in inputBComponents do
            if Equals(compA, compB):value() then matches += 1 end
        end

    end

    return types.singleton(if #inputAComponents == matches and #inputBComponents == matches then true else false)
end


--[=[
    Outputs an intersection of components which only appear in `inputA`, and which only appear in `inputB`.

    @param inputA any-- The first intersection.
    @param inputB any -- the second intersection.
]=]
type function IntersectionDiff(inputA: any, inputB: any)
    local inputAComponents = _safeIs(inputA, "intersection") and inputA:components() or { inputA }
    local inputBComponents = _safeIs(inputB, "intersection") and inputB:components() or { inputB }

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
    local inputAComponents = _safeIs(inputA, "intersection") and inputA:components() or { inputA }
    local inputBComponents = _safeIs(inputB, "intersection") and inputB:components() or { inputB }

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


--> Negation ------------------------------------------------------------------------------------------
type function Negate(input: any)
    return types.negationof(input)
end

type function Unnegate(input: any)
    return _safeIs(input, "negation") and input:inner() or input
end
-------------------------------------------------------------------------------------------------------


--> Function ------------------------------------------------------------------------------------------
--[=[
    Removes duplicate types from a functions arguments and return types.

    @param input any -- The function to be cleaned.
]=]
type function FunctionClean(input: (...any) -> ...any)
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), FunctionClean)) end
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), FunctionClean)) end
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
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(UnionFlatten(input):components(), FunctionFlatten)) end
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(IntersectionFlatten(input):components(), FunctionFlatten)) end
    if not _safeIs(input, "function") then return input end

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
    local function funcSectEquals(itemA: any, itemB: any)
        if (itemA and not itemB) or (itemB and not itemA) then return false end
        if not itemA and not itemB then return true end

        if #itemA ~= #itemB then return false end

        for idx, comp in itemA do
            if not Equals(comp, itemB[idx]):value() then return false end
        end

        return true
    end

    local argsA, argsB = inputA:parameters(), inputB:parameters()
    local returnsA, returnsB = inputA:returns(), inputB:returns()

    -- Returns true only if both the function arguments and return types are equal.
    return types.singleton(
        -- Checks if arguments are equal.
        funcSectEquals(argsA and argsA.head, argsB and argsB.head) and 
        Equals(argsA and argsA.tail, argsB and argsB.tail):value() and

        -- Checks if the return types are equal.
        funcSectEquals(returnsA and returnsA.head, returnsB and returnsB.head) and
        Equals(returnsA and returnsA.tail, returnsB and returnsB.tail):value()
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
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(input:components(), StringToCamel)) end
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToCamel)) end

    input = _safeValue(input)
    if typeof(input) ~= "string" then return input end

    return _toCamel(input)
end


--[=[
    Converts a string literal (or string literals within a union/intersection) to pascal case (PascalCase).

    @param input string -- The string to convert to pascal case.
]=]
type function StringToPascal(input: string)
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(input:components(), StringToPascal)) end
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToPascal)) end

    input = _safeValue(input)
    if typeof(input) ~= "string" then return input end

    return _toPascal(input)
end


--[=[
    Converts a string literal (or string literals within a union/intersection) to upper case (UPPERCASE).

    @param input string -- The string to convert to upper case.
]=]
type function StringToUpper(input: string)
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(input:components(), StringToUpper)) end
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToUpper)) end

    input = _safeValue(input)
    if typeof(input) ~= "string" then return input end

    return _toUpper(input)
end


--[=[
    Converts a string literal (or string literals within a union/intersection) to lower case (lowercase).

    @param input string -- The string to convert to lower case.
]=]
type function StringToLower(input: string)
    if _safeIs(input, "union") then return _arrayToUnion(_tableMap(input:components(), StringToLower)) end
    if _safeIs(input, "intersection") then return _arrayToIntersection(_tableMap(input:components(), StringToLower)) end

    input = _safeValue(input)
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
    if _safeIs(input, "union") then
        return _arrayToUnion(_tableMap(input:components(), function(comp) return StringReplace(comp, pattern, replacement) end))
    end
    if _safeIs(input, "intersection") then
        return _arrayToIntersection(_tableMap(input:components(), function(comp) return StringReplace(comp, pattern, replacement) end))
    end

    _assertIs(input, "string")
    _assertIs(pattern, "string")
    _assertIs(replacement, "string")

    input, pattern, replacement = _safeValue(input), _safeValue(pattern), _safeValue(replacement)

    return types.singleton(string.gsub(input, pattern, replacement))
end


--[=[
    Joins a table of strings together.

    @param input { [`{number}`]: string } -- The string table to join together.
]=]
type function StringJoin(input: { [any]: string })
    _assertIs(input, "string")

    local inputArr = {}

    for key, value in input:properties() do
        local idx = tonumber(key:value())
        if not idx then continue end
        inputArr[idx] = value.write or value.read
    end

    local output = ""

    for _,value in inputArr do
        value = _safeValue(value)
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
    if _safeIs(input, "union") then
        return _arrayToUnion(_tableMap(input:components(), function(comp) return StringSplit(comp, splitAt) end))
    end
    if _safeIs(input, "intersection") then
        return _arrayToIntersection(_tableMap(input:components(), function(comp) return StringSplit(comp, splitAt) end))
    end

    _assertIs(input, "input", "string")
    _assertIs(splitAt, "splitAt", "string")

    input, splitAt = _safeValue(input), _safeValue(splitAt)

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
    _assertIs(input, "input", "string")

    at = tonumber(_safeValue(at))
    assert(typeof(at) == "number", "The type argument `at` could not be turned into a number!")

    return types.singleton(string.sub(_safeValue(input), at, at))
end


--[=[
    Gets the length of a string (returns as a stringified integer as luau doesn't currently support integer literals).

    @param input string -- The string to get the length of.
]=]
type function StringLength(input: string)
    _assertIs(input, "input", "string")

    return types.singleton(tostring(#_safeValue(input)))
end


--[=[
    Outputs true if the input string is of the required length.

    @param input string -- The string to test the length of.
    @param length `{number}` -- The expected length of the string.
]=]
type function StringIsLength(input: string, length: number)
    _assertIs(input, "input", "string")

    return types.singleton(#_safeValue(input) == tonumber(_safeValue(length)))
end


--[=[
    Outputs true if the string is empty.

    @param input string -- The string to test emptiness for.
]=]
type function StringIsEmpty(input: string)
    _assertIs(input, "input", "string")

    return types.singleton(_safeValue(input) == "")
end


--[=[
    Returns true if the string is a string literal.

    @param input string -- The string to test to see if its a string literal.
]=]
type function StringIsLiteral(input: string)
    _assertIs(input, "input", "string")

    return types.singleton(if typeof(_safeValue(input)) == "string" then true else false)
end
-------------------------------------------------------------------------------------------------------


--> Boolean Operation ---------------------------------------------------------------------------------
--[=[
    If a truthy type is inputted then it outputs `false`, and if a falsy type is inputted then it outputs `true`.

    @param input any -- The type you wish to perform a `Not` operation on.
]=]
type function Not(input: any)
    if _safeIs(input, "never") or _safeIs(input, "unknown") then
        return types.singleton(false)

    elseif _safeIs(input, "singleton") then
        return types.singleton(not input:value())

    elseif _safeIs(input, "union") then
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
    if _safeIs(input, "never") or _safeIs(input, "unknown") then
        return types.singleton(false)

    elseif _safeIs(input, "singleton") then
        return types.singleton(input:value() and true or false)
    
    elseif _safeIs(input, "union") then
        for _,comp in input:components() do
            if _safeIs(comp, "never") or _safeIs(comp, "unknown") or (not comp:value()) then return types.singleton(false) end
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
    if _safeIs(input, "never") or _safeIs(input, "unknown") then
        return types.singleton(false)

    elseif _safeIs(input, "singleton") then
        return types.singleton(input:value() and true or false)
    
    elseif _safeIs(input, "union") then
        for _,comp in input:components() do
            if _safeIs(comp, "never") or _safeIs(comp, "unknown") then continue end
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

            if Equals(inputItem, extendsItem):value() then return true end
        end

        return false
    end

    local doesExtend
    if _safeIs(extends, "union") or _safeIs(extends, "intersection") then
        local extendsComponents = _arraySingletonsToValues(extends:components())
        doesExtend = function(item: any)
            for _,comp in extendsComponents do
                if doesExtendBase(_safeValue(item), comp) then return true end
            end
            return false
        end

    else
        doesExtend = function(item: any) return doesExtendBase(_safeValue(item), _safeValue(extends)) end
    end


    if _safeIs(input, "union") or _safeIs(input, "intersection") then
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
        typeof(_safeValue(input)) == typeof(_safeValue(compareTo)) or 
        (input == compareTo))
end


--[=[
    If `input` is a truthy type then it outputs `ifTruthy`, if else then it outputs `ifFalsy`.

    @param input any -- The type for the condition.
    @param ifTruthy any -- The type to output if `input` is truthy.
    @param ifFalsy any -- The type to output if `input` is falsey.
]=]
type function Condition(input: any, ifTruthy: any, ifFalsy: any)
    return if _safeValue(input) then ifTruthy else ifFalsy
end
-------------------------------------------------------------------------------------------------------


--> Miscellaneous -------------------------------------------------------------------------------------
--[=[
    Throws a type error if the first type does not equal the second.

    @param expect any -- The type to be compared.
    @param toBe any -- The type you want to compare `expect` to.
]=]
type function Expect(expect: any, toBe: any)
    if not Equals(expect, toBe):value() then
        return error("expection error!")
    end

    return expect
end


--[=[
    Returns the inputted type but with unions and intersections turned into arrays so they can be inspected better.

    @param input any -- The type to be inspected.
]=]
type function Inspect(input: any)
    local isUnion, isIntersection = _safeIs(input, "union"), _safeIs(input, "intersection")
    if not isUnion and not isIntersection then return input end

    local output = types.newtable({
        [types.singleton("Kind")] =  types.singleton(if isUnion then "Union" else "Intersection")
    })

    for idx, comp in input:components() do
        output:setproperty(
            types.singleton(`{idx}`),
            if _safeIs(comp, "union") or _safeIs(comp, "intersection") then Inspect(comp) else comp
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

-- Test G: Picking a property from an intersection of two tables.
type TablePick_TestG = Expect<
    TablePick<{ hello: "world" } & { foo: "bar" }, "hello">,
    { hello: "world" } & { }
>

-- Test H: Picking 2 properties from an intersection of two tables where each component to be picked exists in a different table.
type TablePick_TestH = Expect<
    TablePick<{ hello: "world" } & { foo: "bar" }, "hello" | "foo">,
    { hello: "world" } & { foo: "bar" }
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

-- Test F: Omitting a property and indexer of the same string literal.
type TableOmit_TestF = Expect<
    TableOmit<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    SetIndexer<{ Name: string }, string | "hello" | "lol", any>
>

-- Test G: Omitting a property from an intersection of two tables.
type TableOmit_TestG = Expect<
    TableOmit<{ hello: "world" } & { foo: "bar" }, "hello">,
    { } & { foo: "bar" }
>

-- Test H: Omitting 2 properties from an intersection of two tables where each component to be omitted exists in a different table.
type TableOmit_TestH = Expect<
    TableOmit<{ hello: "world" } & { foo: "bar" }, "hello" | "foo">,
    {  } & { }
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


-- UnionClean -----------------------------------------
-- Cleans an intersection of unions.
type UnionClean_TestA = Expect<
    UnionClean<(("hello" | "hello" | "lol") & ("bob" | "hai" | "hai"))>,
    (("hello" | "lol") & ("bob" | "hai"))
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


--> Intersection --------------------------------------------------------------------------------------
type IntersectionFlatten_TestA = Expect<
    IntersectionClean<(("hello" & "hello" & "lol") | ("bob" & "hai" & "hai"))>,
    (("hello" & "lol") | ("bob" & "hai"))
>
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

-- TestU: Tests to see if a table with properties extends a table with properties taken from that first table.
type Extends_TestU = Expect<Extends<{ hello: "world", foo: "bar" }, { hello: "world" }>, true>

-- TestV: Tests to see if a union of a table with properties and string extends a table with properties taken from that first table.
type Extends_TestV = Expect<Extends<{ hello: "world", foo: "bar" } | string, { hello: "world" }>, false>

-- TestW: Tests to see if a table with properties extends a table with properties taken from that first table as well as extra properties.
type Extends_TestW = Expect<Extends<{ hello: "world" }, { hello: "world", foo: "bar" }>, false>

-- TestX: Tests to see if a union of a table with properties and string extends
-- a table with properties taken from that first table as well as extra properties.
type Extends_TestX = Expect<Extends<{ hello: "world" } | string, { hello: "world", foo: "bar" }>, false>

-- TestY: Tests to see if a table with properties extends a union of a table with properties taken from that first table and string.
type Extends_TestY = Expect<Extends<{ hello: "world", foo: "bar" }, { hello: "world" } | string>, true>

-- TestZ: Tests to see if a table with property whos value is a string literal
-- extends a table with the same property but with a different string literal.
type Extends_TestZ = Expect<Extends<{ kind: "Customer" }, { kind: "Employee" }>, false>

-- TestAA: Tests to see if a table with property whos value is a
-- string literal extends a table with the same property.
type Extends_TestAA = Expect<Extends<{ kind: "Customer" }, { kind: "Customer" }>, true>

-- TestAB: Tests to see if a table extends a table with a nil property.
type Extends_TestAB = Expect<Extends<{ }, { foo: nil }>, true>

-- TestAC: Tests to see if a table extends a table with a nillable property.
type Extends_TestAC = Expect<Extends<{ }, { foo: string? }>, true>

-- TestAD: Tests to see if a table with a nilable property extends a table with the same nillable property
type Extends_TestAD = Expect<Extends<{ foo: string? }, { foo: string? }>, true>

-- TestAE: Tests to see if a table with a nilable property extends a table with the same nillable property but with different value.
type Extends_TestAE = Expect<Extends<{ foo: string? }, { foo: number? }>, false>

-- TestAF: Tests to see if a non-empty table extends an empty table.
type Extends_TestAF = Expect<Extends<{ foo: string }, { }>, true>

-- TestAG: Tests to see if an empty table extends a non-empty table.
type Extends_TestAG = Expect<Extends<{ }, { foo: string }>, false>

-- TestAH: Tests to see if a table with a string literal prop extends table with a nilable string primative prop.
type Extends_TestAH = Expect<Extends<{ hello: "hello" }, { hello: string? }>, true>

-- TestAI: Tests to see if a table with a nilable string literal prop extends table with a string primative prop.
type Extends_TestAI = Expect<Extends<{ hello: "hello"? }, { hello: string }>, false>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------

