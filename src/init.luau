--!strict
--!nolint LocalShadow

--> Helpers ----------------------------------------------------------------------------
type function assert_is_msg(input: type, input_type: string, label: string, is: string)
    local error_msg_start = `\n'{label}' should be of type {is}`

    local error_msg_end =
        if is_primitive(input_type) then `but is instead of type '{input_type}'!`
        else `but is instead of type '{input_type}': {stringify_preview(input)}`

    return `{error_msg_start} {error_msg_end}`
end

-- Asserts if the input is of the required types - with a nice formatted error message.
type function assert_is(input: type, label: string, input_tag: string, ...: string)
    local input_type = if input_tag == "singleton" then type(input:value()) else input_tag

    if select("#", ...) == 1 then
        local is = ...
        if input_type ~= is then
            assert_is_msg(input, input_type, label, `'{is}'`)
        end

    else
        local allowed_types = table.pack(...)

        local assert_failed = false
        for _, allowed_type in allowed_types do
            if input_type ~= allowed_type then
                assert_failed = true
                break
            end
        end

        if assert_failed then
            local allowed_types_len = #allowed_types
            local allowed_types_str = `'{allowed_types[1]}'`
            for idx = 2, allowed_types_len - 1 do
                allowed_types_str ..= `, '{allowed_types[idx]}'`
            end
            allowed_types_str ..= ` or '{allowed_types[allowed_types_len]}'`

            error(assert_is_msg(input, label, input_type, allowed_types_str))
        end
    end
end

type function is_primitive(input_tag: string)
    return
        input_tag == "unknown" or
        input_tag == "never" or
        input_tag == "any" or
        input_tag == "boolean" or
        input_tag == "number" or
        input_tag == "string"
end

type function unions_and_intersections_flatten(
    input: typeof(types.unionof()) | typeof(types.intersectionof())
)
    local input_tag = input.tag

    if input_tag == "union" or input_tag == "intersection" then
        local components = input:components()

        for idx = #components, 1, -1 do
            local component = components[idx]
            local component_tag = component.tag
            if component_tag ~= "union" and component_tag ~= "intersection" then continue end

            local component = unions_and_intersections_flatten(component)
            if component.tag == input_tag then
                local sub_components = component:components()

                components[idx] = sub_components[1]
                for idx = 2, #sub_components do
                    table.insert(components, sub_components[idx])
                end

            else
                components[idx] = component
            end
        end

        return (if input_tag == "union" then union_from_components(components) else intersection_from_components(components)) or types.never

    else
        return input
    end
end

type function unions_and_intersections_clean(
    input: typeof(types.unionof()) | typeof(types.intersectionof()),
    hashset: typeof(types.newtable()),
    non_hashsettable: { [number]: type },

    input_tag: string,
    input_tag_other: string,
    input_builder: (components: { [number]: type }) -> (typeof(types.unionof()) | typeof(types.intersectionof())),

    other_input_tag: string,
    other_input_tag_other: string,
    other_input_builder: (components: { [number]: type }) -> (typeof(types.unionof()) | typeof(types.intersectionof()))
)   
    local input_len = #input
    for idx = input_len, 1, -1 do
        local component = input[idx]
        local component_tag = component.tag
        
        if component.tag == input_tag then
            local cleaned = input_builder(unions_and_intersections_clean(
                component:components(), hashset, non_hashsettable,
                input_tag, input_tag_other, input_builder,
                other_input_tag, other_input_tag_other, other_input_builder
            ))

            if cleaned == nil then
                input_len = table_swap_remove(input, input_len, idx)
            else
                input[idx] = cleaned
            end

        elseif component_tag == input_tag_other then
            local cleaned = other_input_builder(unions_and_intersections_clean(
                component:components(), types.newtable(), {},
                other_input_tag, other_input_tag_other, other_input_builder,
                input_tag, input_tag_other, input_builder
            ))

            if cleaned == nil then
                input_len = table_swap_remove(input, input_len, idx)
            else
                input[idx] = cleaned
            end

        else
            if hashset_has_type(hashset, non_hashsettable, component) then
                input_len = table_swap_remove(input, input_len, idx)
            else
                hashset_insert(hashset, non_hashsettable, component)
            end
        end
    end

    return input
end

type function non_optional(input: type, nil_singleton: typeof(types.singleton(nil)))
    local input_tag = input.tag

    if input_tag == "union" or input_tag == "intersection" then
        for _, component in input:components() do
            if component ~= nil_singleton then return component end
        end
    
        return nil_singleton

    else
        return input
    end
end

type function is_optional(input: type, nil_singleton: typeof(types.singleton(nil)))
    local input_tag = input.tag

    if input_tag == "union" or input_tag == "intersection" then
        local components = input:components()
        for idx = #components, 1, -1 do
            local component = components[idx]
            if component == nil_singleton then return true end
        end

        return false
    
    else
        return input ~= nil_singleton
    end
end

type function is_required(input: type, nil_singleton: typeof(types.singleton(nil)))
    local input_tag = input.tag

    if input_tag == "union" or input_tag == "intersection" then
        local components = input:components()
        for idx = #components, 1, -1 do
            local component = components[idx]
            if component == nil_singleton then return false end
        end

        return true
    
    else
        return input == nil_singleton
    end
end
----------------------------------------------------------------------------------------

--> Pretty Print Helpers ---------------------------------------------------------------
type function stringify_preview(input: type)
    return `\n> {string.gsub(Stringify(input), "\n", "\n> ")}`
end

type function stringify_table_type(input: typeof(types.singleton(nil)), nestedness: number)
    local properties = input:properties()
    local indexer = input:indexer()

    if table_type_is_empty(properties, indexer) then return "{}" end

    local next_nestedness = nestedness + 1

    local outer_padding = string.rep("   ", nestedness - 1)
    local padding = outer_padding .. "    "

    local stringified = `{outer_padding}\{`

    for key, value in properties do
        local key_value = if key.tag == "singleton" then key:value() else input

        local stringifiedkey =
            if type(key_value) == "string" then key_value
            else `[{stringify_main(key, next_nestedness)}]`

        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            stringified ..= `\n{padding}{stringifiedkey}: {stringify_main(value_read, next_nestedness)}`

        else
            if value_read then
                stringified ..= `\n{padding}read {stringifiedkey}: {stringify_main(value_read, next_nestedness)}`
            end
            if value_write then
                stringified ..= `\n{padding}read {stringifiedkey}: {stringify_main(value_write, next_nestedness)}`
            end
        end
    end

    -- TODO: add support for read and write indexers when available.
    if indexer then
        local indexer_index = indexer.index
        local indexer_index_value = if indexer_index.tag == "singleton" then indexer_index:value() else input

        local stringified_indexer_index =
            if type(indexer_index_value) == "string" then indexer_index_value
            else `[{stringify_main(indexer_index, next_nestedness)}]`

        stringified ..= `\n{padding}{stringified_indexer_index}: {stringify_main(indexer.readresult, next_nestedness)}`
    end

    return stringified .. `\n{outer_padding}}`
end

type function stringify_components(
    components: { [number]: type },
    concatenator: string
)
    for idx, component in components do
        local component_tag = component.tag

        if component_tag == "union" then
            components[idx] = `({stringify_components(component:components(), " | ")})` :: any

        elseif component_tag == "intersection" then
            components[idx] = `({stringify_components(component:components(), " & ")})` :: any

        else
            components[idx] = stringify_main(component, 1)
        end
    end

    return table.concat(components, concatenator)
end

type function stringify_function(input: typeof(types.newfunction()))
    local args = input:parameters()
    local args_head, args_tail = args.head, args.tail

    local stringified_args: string
    if args_head then
        stringified_args = ""

        local args_head_len = #args_head
        for idx = 1, args_head_len - 1 do
            stringified_args ..= `{Stringify(args_head[idx])}, `
        end
        stringified_args ..= `{Stringify(args_head[args_head_len])}`

        if args_tail then
            local args_tail_tag = args_tail.tag
            if args_tail_tag == "union" or args_tail_tag == "intersection" then
                stringified_args ..= `, ...({Stringify(args_tail)}))`
            else
                stringified_args ..= `, ...{Stringify(args_tail)})`
            end
        end
    elseif args_tail then
        local args_tail_tag = args_tail.tag
        if args_tail_tag == "union" or args_tail_tag == "intersection" then
            stringified_args = `...({Stringify(args_tail)})`
        else
            stringified_args = `...{Stringify(args_tail)}`
        end
    end

    local returns = input:returns()
    local returns_head, returns_tail = returns.head, returns.tail

    local returns_head_len: number
    local stringified_returns: string
    if returns_head then
        stringified_returns = ""

        returns_head_len = #returns_head
        for idx = 1, returns_head_len - 1 do
            stringified_returns ..= `{Stringify(returns_head[idx])}, `
        end
        stringified_returns ..= `{Stringify(returns_head[returns_head_len])}`

        if returns_tail then
            local returns_tail_tag = returns_tail.tag
            if returns_tail_tag == "union" or returns_tail_tag == "intersection" then
                stringified_returns ..= `, ...({Stringify(returns_tail)}))`
            else
                stringified_returns ..= `, ...{Stringify(returns_tail)})`
            end
        end

    elseif returns_tail then
        local returns_tail_tag = returns_tail.tag
        if returns_tail_tag == "union" or returns_tail_tag == "intersection" then
            stringified_returns = `...({Stringify(returns_tail)})`
        else
            stringified_returns = `...{Stringify(returns_tail)}`
        end
    end

    local stringified_returns = 
        if returns_tail or (returns_head and returns_head_len >= 2) then `({stringified_returns})`
        else stringified_returns

    return `({stringified_args}) -> {stringified_returns}`
end

type function stringify_main(input: type, nestedness: number)
    local input_tag = input.tag

    if input_tag == "negation" then
        local input_inner = input:inner()
        local input_inner_tag = input_inner.tag
        return
            if (
                input_inner_tag == "union" or input_inner_tag == "intersection"
            ) then `~({stringify_main(input:inner(), nestedness)})`
            else `~{stringify_main(input:inner(), nestedness)}`
    end

    if input_tag == "union" then return stringify_components(input:components(), " | ")
    elseif input_tag == "intersection" then return stringify_components(input:components(), " & ")
    elseif input_tag == "table" then return stringify_table_type(input, 1)
    elseif input_tag == "function" then return stringify_function(input)
    elseif input_tag == "unknown" then return "unknown"
    elseif input_tag == "never" then return "never"
    elseif input_tag == "any" then return "any"
    elseif input_tag == "boolean" then return "boolean"
    elseif input_tag == "number" then return "number"
    elseif input_tag == "string" then return "string" end

    local input = if input_tag == "singleton" then input:value() else input
    local input_type = type(input)
    
    return
        if input_type == "string" then `"{input}"`
        else tostring(input) 
end
----------------------------------------------------------------------------------------


--> Hashset Helpers --------------------------------------------------------------------
type function hashset_can_insert(input: type)
    return input.tag == "singleton"
end

type function hashset_insert(
    hashset: typeof(types.newtable()),
    non_hashsettable: { [number]: type },
    input: type
)   
    if hashset_can_insert(input) then
        hashset:setproperty(input, types.never)
    
    else
        table.insert(non_hashsettable, input)
    end
end

type function hashset_has_type(
    hashset: typeof(types.newtable()),
    non_hashsettable: { [number]: type },
    input: type
)
    if hashset_can_insert(input) then
        return if hashset:readproperty(input) then true else false

    else
        for _, component in non_hashsettable do
            if input == component then return true end
        end

        return false
    end
end

type function hashset_from_components(input: { [number]: type })
    -- Only singletons can be can be stored in a hashset. Other types 
    -- will be returned in an array-like table (non_hashsettable).
    local hashset, non_hashsettable = types.newtable(), {}

    for _, value in input do
        hashset_insert(hashset, non_hashsettable, value)
    end

    return hashset, non_hashsettable
end
----------------------------------------------------------------------------------------

--> Components Helpers -----------------------------------------------------------------
type function components_filter(
    input: { [number]: type },
    as: "union" | "intersection",
    as_builder: (components: { [number]: type }) -> (typeof(types.unionof()) | typeof(types.intersectionof())),
    callback: (component: type) -> boolean
)
    local input_len = #input

    for idx = input_len, 1, -1 do
        local component = input[idx]

        if component.tag == as then
            local filtered = as_builder(components_filter(component:components(), as, as_builder, callback))

            if filtered == nil then
                input_len = table_swap_remove(input, input_len, idx)
            else
                input[idx] = filtered
            end

        else
            if not callback(component) then continue end

            input_len = table_swap_remove(input, input_len, idx)
        end
    end

    return input
end

type function components_flatten(
    input: { [number]: type },
    as: "union" | "intersection"
)
    for idx = #input, 1, -1 do
        local component = input[idx]
        if component.tag ~= as then continue end

        local component = components_flatten(component:components(), as)

        input[idx] = component[1]
        for idx = 2, #component do
            table.insert(input, component[idx])
        end
    end

    return input
end

type function components_map(
    input: { [number]: type }, 
    callback: (value: type, idx: number) -> any
)
    for idx, value in input do
        input[idx] = callback(value, idx)
    end
    return input
end

type function components_clean(
    input: { [number]: type },
    as: "union" | "intersection",
    as_builder: (components: { [number]: type }) -> (typeof(types.unionof()) | typeof(types.intersectionof())),
    hashset: typeof(types.newtable()),
    non_hashsettable: { [number]: type }
)   
    local input_len = #input
    for idx = input_len, 1, -1 do
        local component = input[idx]
        
        if component.tag == as then
            local cleaned = as_builder(components_clean(component:components(), as, as_builder, hashset, non_hashsettable))

            if cleaned == nil then
                input_len = table_swap_remove(input, input_len, idx)
            else
                input[idx] = cleaned
            end

        else
            if hashset_has_type(hashset, non_hashsettable, component) then
                input_len = table_swap_remove(input, input_len, idx)
            else
                hashset_insert(hashset, non_hashsettable, component)
            end
        end
    end

    return input
end

type function components_contains(input: { [number]: type }, callback: (component: type) -> boolean)
    for _, component in input do
        if not callback(component) then continue end
        return true
    end

    return false
end

type function components_contains_table(input: { [number]: type })
    return components_contains(input, function(component)
        return component.tag == "table"
    end)
end
----------------------------------------------------------------------------------------

--> Union Helpers ----------------------------------------------------------------------
type function union_from_components(input: { [number]: type })
    local input_len = #input
    return if input_len == 0 then nil elseif input_len == 1 then input[1] else types.unionof(table.unpack(input))
end

type function union_filter(input: type, callback: (component: type) -> boolean)
    if input.tag == "union" then
        return union_from_components(components_filter(input:components(), "union", union_from_components, callback))
    else
        return if callback(input) then nil else input
    end
end
----------------------------------------------------------------------------------------

--> Intersection Helpers ---------------------------------------------------------------
type function intersection_from_components(input: { [number]: type })
    local input_len = #input
    return if input_len == 0 then nil elseif input_len == 1 then input[1] else types.intersectionof(table.unpack(input))
end

type function intersection_filter(input: type, callback: (component: type) -> boolean)
    if input.tag == "intersection" then
        return intersection_from_components(components_filter(input:components(), "intersection", intersection_from_components, callback))
    else
        return if callback(input) then nil else input
    end
end
----------------------------------------------------------------------------------------

--> Table Helpers ----------------------------------------------------------------------
type function table_swap_remove(input: { [any]: any }, input_len: number, idx: number)
    -- Last item, we can just remove from
    -- the end of the input table.
    if idx == input_len then
        table.remove(input, idx)

    -- Swap remove optimisation.
    else
        input[idx] = table.remove(input)
    end

    return input_len - 1
end

type function table_type_is_empty(properties: { [any]: any }, indexer: type)
    if indexer then return false end

    for _ in properties do return false end
    return true
end

-- Currently there is no way to remove an indexer from
-- a table type. So we resort to a hacky workaround of
-- creating a new table type and copying all information
-- from the input table type except the indexer.
type function table_type_remove_indexer_hacky_fix(input: typeof(types.newtable()))
    local output = types.newtable()

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write
        if value_read == value_write then
            output:setproperty(key, value_read)

        else
            output:setreadproperty(key, value_read)
            output:setwriteproperty(key, value_write)
        end
    end

    return output
end

-- Currently there is no way to remove a read indexer from
-- a table type. So we resort to a hacky workaround of
-- creating a new table type and copying all information
-- from the input table type except the read indexer.
type function table_type_remove_read_indexer_hacky_fix(input: typeof(types.newtable()))
    local output = types.newtable()

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write
        if value_read == value_write then
            output:setproperty(key, value_read)

        else
            output:setreadproperty(key, value_read)
            output:setwriteproperty(key, value_write)
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_write_result = indexer.writeresult
        if indexer_write_result then
            output:setwriteindexer(indexer.index, indexer_write_result)
        end
    end

    return output
end

-- Currently there is no way to remove a write indexer from
-- a table type. So we resort to a hacky workaround of
-- creating a new table type and copying all information
-- from the input table type except the write indexer.
type function table_type_remove_write_indexer_hacky_fix(input: typeof(types.newtable()))
    local output = types.newtable()

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write
        if value_read == value_write then
            output:setproperty(key, value_read)

        else
            output:setreadproperty(key, value_read)
            output:setwriteproperty(key, value_write)
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_read_result = indexer.readresult
        if indexer_read_result then
            output:setreadindexer(indexer.index, indexer_read_result)
        end
    end

    return output
end

type function table_type_filter(
    input: typeof(types.newtable()),
    callback: (key: type, value: type?) -> boolean
)
    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        -- If the read and write values are identical then we only
        -- need to perform the filter check on one of them.
        if value_read == value_write then
            -- Either the read or write value could've been used here.
            if callback(key, value_read) then
                input:setproperty(key, nil)
            end

        else
            if callback(key, value_read) then
                input:setreadproperty(key, nil)

            elseif callback(key, value_write) then
                input:setwriteproperty(key, nil)
            end
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_index = indexer.index
        local indexer_read_result, indexer_write_result = indexer.readresult, indexer.writeresult

        -- If the read and write indexers are identical then we only
        -- need to perform the filter check on one of them.
        if indexer_read_result == indexer_write_result then
            if callback(indexer_index, indexer_read_result) then
                input = table_type_remove_indexer_hacky_fix(input)
                --input:setindexer(indexer_index, nil)
            end

        else
            if callback(indexer_index, indexer_read_result) then
                input = table_type_remove_read_indexer_hacky_fix(input)
                -- [[input:setreadindexer(indexer_index, nil)
            end

            if callback(indexer_index, indexer_write_result) then
                return table_type_remove_write_indexer_hacky_fix(input)
                --input:setwriteindexer(indexer_index, nil)
            end
        end
    end

    return input
end
----------------------------------------------------------------------------------------

--> Core Types -------------------------------------------------------------------------
--[=[
    Returns a subset of a type without specified components / properties.

    @param input any -- The type to omit from.
    @param to_omit any -- The components / properties to omit.
]=]
export type function Omit(input: type, to_omit: type)
    local tag = input.tag

    return
        if tag == "table" then
            OmitTableByKeys(input, to_omit)

        elseif tag == "intersection" then
            if components_contains_table(input:components()) then
                OmitTableByKeys(input, to_omit)
            else
                PickIntersection(input, to_omit)

        else OmitUnion(input, to_omit)
end

--[=[
    Returns a subset of a type with only specified components / properties.

    @param input any -- The type to pick from.
    @param to_pick any -- The components / properties to pick.
]=]
export type function Pick(input: type, to_pick: type)
    local tag = input.tag

    return
        if tag == "table" then
            PickTable(input, to_pick)

        elseif tag == "intersection" then
            if components_contains_table(input:components()) then
                PickTableByKeys(input, to_pick)
            else
                PickIntersection(input, to_pick)

        else PickUnion(input, to_pick)
end

--[=[
    Combines a nested union or intersection into one union / intersection.
    Combines an intersection of tables into one consolidated table whilst preserving semantics.

    @param input any -- The type to flatten.
]=]
export type function Flatten(input: type)
    return FlattenTable(unions_and_intersections_flatten(input))
end

--[=[
    Removes duplicate components / properties from a type.

    @param input any -- The type to clean.
]=]
export type function Clean(input: type)
    local tag = input.tag

    return
        if tag == "table" then CleanTable(input)

        elseif tag == "union" then
            union_from_components(unions_and_intersections_clean(
                input:components(), types.newtable(), {},
                tag, "intersection", union_from_components,
                "intersection", tag, intersection_from_components
            ))

        elseif tag == "intersection" then
            if components_contains_table(input:components()) then
                CleanTable(input)

            else
                intersection_from_components(unions_and_intersections_clean(
                    input:components(), types.newtable(), {},
                    tag, "union", intersection_from_components,
                    "union", tag, union_from_components
                ))

        else input
end
----------------------------------------------------------------------------------------


--> Union Types ------------------------------------------------------------------------
--[=[
    Returns a subset of a union without specified components.

    @param input any -- The union to omit from.
    @param to_omit any -- The components to omit.
]=]
export type function OmitUnion(input: type, to_omit: type)
    if to_omit.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_omit:components())

        return union_filter(input, function(component): boolean
            return hashset_has_type(hashset, non_hashsettable, component)
        end) or types.never

    else
        return union_filter(input, function(component)
            return component == to_omit
        end) or types.never
    end
end

--[=[
    Returns a subset of a union with only specified components.

    @param input any -- The union to pick from.
    @param to_pick any -- The components to pick.
]=]
export type function PickUnion(input: type, to_pick: type)
    if to_pick.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_pick:components())

        return union_filter(input, function(component): boolean
            return hashset_has_type(hashset, non_hashsettable, component)
        end) or types.never

    else
        return union_filter(input, function(component)
            return component ~= to_pick
        end) or types.never
    end
end

--[=[
    Combines nested unions into one union.

    @param input any -- The union to flatten.
]=]
export type function FlattenUnion(input: type)
    if input.tag == "union" then
        return union_from_components(components_flatten(input:components(), "union")) or types.never
    else
        return input
    end
end

--[=[
    Removes duplicate types from a union.

    @param input any -- The union to clean.
]=]
export type function CleanUnion(input: type)
    if input.tag == "union" then
        return union_from_components(
            components_clean(input:components(), "union", union_from_components, types.newtable(), {})
        ) or types.never

    else
        return input
    end
end
----------------------------------------------------------------------------------------

--> Intersection Types -----------------------------------------------------------------
--[=[
    Returns a subset of an intersection without specified components.

    @param input any -- The intersection to omit from.
    @param to_omit any -- The components to omit.
]=]
export type function OmitIntersection(input: type, to_omit: type)
    if input.tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return OmitIntersection(component, to_omit)
        end))

    elseif to_omit.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_omit:components())

        return intersection_filter(input, function(component): boolean
            return hashset_has_type(hashset, non_hashsettable, component)
        end) or types.never

    else
        return intersection_filter(input, function(component)
            return component == to_omit
        end) or types.never
    end
end

--[=[
    Returns a subset of an intersection with only specified components.

    @param input any -- The intersection to pick from.
    @param to_pick any -- The components to pick.
]=]
export type function PickIntersection(input: type, to_pick: type)
    if input.tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return PickIntersection(component, to_pick)
        end))

    elseif to_pick.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_pick:components())

        return intersection_filter(input, function(component): boolean
            return hashset_has_type(hashset, non_hashsettable, component)
        end) or types.never

    else
        return intersection_filter(input, function(component)
            return component ~= to_pick
        end) or types.never
    end
end

--[=[
    Combines nested intersections into one intersection.

    @param input any -- The intersection to flatten.
]=]
export type function FlattenIntersection(input: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), FlattenIntersection)) or types.never

    elseif input.tag == "intersection" then
        return intersection_from_components(components_flatten(input:components(), "intersection")) or types.never
    else
        return input
    end
end


--[=[
    Removes duplicate types from an intersection.

    @param input any -- The intersection to clean.
]=]
export type function CleanIntersection(input: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), CleanIntersection)) or types.never

    elseif input.tag == "intersection" then
        return intersection_from_components(
            components_clean(input:components(), "intersection", intersection_from_components, types.newtable(), {})
        ) or types.never

    else
        return input
    end
end
----------------------------------------------------------------------------------------

--> Table Types ------------------------------------------------------------------------
--[=[
    Returns a subset of a table without properties whose keys or values contain the specified components.

    @param input { [any]: type } -- The table to omit from.
    @param to_omit any -- The keys or values of the properties to omit.
]=]
export type function OmitTable(input: typeof(types.newtable()), to_omit: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return OmitTable(component, to_omit)
        end)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), function(component)
            return OmitTable(component, to_omit)
        end)) or types.never
    end

    assert_is(input, "input", input.tag, "table")

    if to_omit.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_omit:components())

        return table_type_filter(input, function(key, value): boolean
            local key_tag = key.tag
            local key_is_union_or_intersection = key_tag == "union" or key_tag == "intersection"

            local value_tag = value.tag
            local value_is_union_or_intersection = value_tag == "union" or value_tag == "intersection"

            if (not key_is_union_or_intersection) and (not value_is_union_or_intersection) then
                if hashset_has_type(hashset, non_hashsettable, key) then return true end
                if hashset_has_type(hashset, non_hashsettable, value) then return true end

                for _, component in non_hashsettable do
                    if key == component or value == component then return true end
                end

            else
                if key_is_union_or_intersection then
                    for _, component_a in key:components() do
                        for _, component_b in non_hashsettable do
                            if component_a == component_b then return true end
                        end
                    end
    
                else
                    if hashset_has_type(hashset, non_hashsettable, key) then return true end
                end

                if value_is_union_or_intersection then
                    for _, component_a in value:components() do
                        for _, component_b in non_hashsettable do
                            if component_a == component_b then return true end
                        end
                    end
    
                else
                    if hashset_has_type(hashset, non_hashsettable, value) then return true end
                end
            end

            return false
        end)

    else
        return table_type_filter(input, function(key, value)
            local key_tag = key.tag
            if key_tag == "union" or key_tag == "intersection" then
                for _, component in key:components() do
                    if component == to_omit then return true end
                end

            else
                if key == to_omit then return true end
            end

            local value_tag = value.tag
            if value_tag == "union" or value_tag == "intersection" then
                for _, component in value:components() do
                    if component == to_omit then return true end
                end

            else
                if value == to_omit then return true end
            end

            return false
        end)
    end
end

--[=[
    Returns a subset of a table without properties whose keys contain the specified components.

    @param input { [any]: type } -- The table to omit from.
    @param to_omit any -- The values of the properties to omit.
]=]
export type function OmitTableByKeys(input: typeof(types.newtable()), to_omit: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return OmitTableByKeys(component, to_omit)
        end)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), function(component)
            return OmitTableByKeys(component, to_omit)
        end)) or types.never
    end

    assert_is(input, "input", input.tag, "table")

    if to_omit.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_omit:components())

        return table_type_filter(input, function(key): boolean
            local key_tag = key.tag

            if key_tag == "union" or key_tag == "intersection" then
                for _, component_a in key:components() do
                    for _, component_b in non_hashsettable do
                        if component_a == component_b then return true end
                    end
                end

            else
                if hashset_has_type(hashset, non_hashsettable, key) then return true end
            end

            return false
        end)

    else
        return table_type_filter(input, function(key)
            local key_tag = key.tag
            if key_tag == "union" or key_tag == "intersection" then
                for _, component in key:components() do
                    if component == to_omit then return true end
                end

            else
                if key == to_omit then return true end
            end

            return false
        end)
    end
end

--[=[
    Returns a subset of a table without properties whose values contain the specified components.

    @param input { [any]: type } -- The table to omit from.
    @param to_omit any -- The values of the properties to omit.
]=]
export type function OmitTableByValues(input: typeof(types.newtable()), to_omit: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return OmitTableByValues(component, to_omit)
        end)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), function(component)
            return OmitTableByValues(component, to_omit)
        end)) or types.never
    end

    assert_is(input, "input", input.tag, "table")

    if to_omit.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_omit:components())

        return table_type_filter(input, function(_, value): boolean
            local value_tag = value.tag

            if value_tag == "union" or value_tag == "intersection" then
                for _, component_a in value:components() do
                    for _, component_b in non_hashsettable do
                        if component_a == component_b then return true end
                    end
                end

            else
                if hashset_has_type(hashset, non_hashsettable, value) then return true end
            end

            return false
        end)

    else
        return table_type_filter(input, function(_, value)
            local value_tag = value.tag
            if value_tag == "union" or value_tag == "intersection" then
                for _, component in value:components() do
                    if component == to_omit then return true end
                end

            else
                if value == to_omit then return true end
            end

            return false
        end)
    end
end

--[=[
    Returns a subset of a table with only properties whose keys or values contain the specified components.

    @param input { [any]: type } -- The table to pick from.
    @param to_pick any -- The keys or values of the properties to pick.
]=]
export type function PickTable(input: typeof(types.newtable()), to_pick: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return PickTable(component, to_pick)
        end)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), function(component)
            return PickTable(component, to_pick)
        end)) or types.never
    end

    assert_is(input, "input", input.tag, "table")

    if to_pick.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_pick:components())

        return table_type_filter(input, function(key, value): boolean
            local key_tag = key.tag
            local key_is_union_or_intersection = key_tag == "union" or key_tag == "intersection"

            local value_tag = value.tag
            local value_is_union_or_intersection = value_tag == "union" or value_tag == "intersection"

            if (not key_is_union_or_intersection) and (not value_is_union_or_intersection) then
                if hashset_has_type(hashset, non_hashsettable, key) then return false end
                if hashset_has_type(hashset, non_hashsettable, value) then return false end

                for _, component in non_hashsettable do
                    if key == component or value == component then return false end
                end

            else
                if key_is_union_or_intersection then
                    for _, component_a in key:components() do
                        for _, component_b in non_hashsettable do
                            if component_a == component_b then return false end
                        end
                    end
    
                else
                    if hashset_has_type(hashset, non_hashsettable, key) then return false end
                end

                if value_is_union_or_intersection then
                    for _, component_a in value:components() do
                        for _, component_b in non_hashsettable do
                            if component_a == component_b then return false end
                        end
                    end
    
                else
                    if hashset_has_type(hashset, non_hashsettable, value) then return false end
                end
            end

            return true
        end)

    else
        return table_type_filter(input, function(key, value)
            local key_tag = key.tag
            if key_tag == "union" or key_tag == "intersection" then
                for _, component in key:components() do
                    if component == to_pick then return false end
                end

            else
                if key == to_pick then return false end
            end

            local value_tag = value.tag
            if value_tag == "union" or value_tag == "intersection" then
                for _, component in value:components() do
                    if component == to_pick then return false end
                end

            else
                if value == to_pick then return false end
            end

            return true
        end)
    end
end

--[=[
    Returns a subset of a table with only properties whose keys contain the specified components.

    @param input { [any]: type } -- The table to pick from.
    @param to_pick any -- The keys of the properties to pick.
]=]
export type function PickTableByKeys(input: typeof(types.newtable()), to_pick: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return PickTableByKeys(component, to_pick)
        end)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), function(component)
            return PickTableByKeys(component, to_pick)
        end)) or types.never
    end

    assert_is(input, "input", input.tag, "table")

    if to_pick.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_pick:components())

        return table_type_filter(input, function(key): boolean
            local key_tag = key.tag

            if key_tag == "union" or key_tag == "intersection" then
                for _, component_a in key:components() do
                    for _, component_b in non_hashsettable do
                        if component_a == component_b then return false end
                    end
                end

            else
                if hashset_has_type(hashset, non_hashsettable, key) then return false end
            end

            return true
        end)

    else
        return table_type_filter(input, function(key)
            local key_tag = key.tag
            if key_tag == "union" or key_tag == "intersection" then
                for _, component in key:components() do
                    if component == to_pick then return false end
                end

            else
                if key == to_pick then return false end
            end

            return true
        end)
    end
end

--[=[
    Returns a subset of a table with only properties whose values contain the specified components.

    @param input { [any]: type } -- The table to pick from.
    @param to_pick any -- The values of the properties to pick.
]=]
export type function PickTableByValues(input: typeof(types.newtable()), to_pick: type)
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), function(component)
            return PickTableByValues(component, to_pick)
        end)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), function(component)
            return PickTableByValues(component, to_pick)
        end)) or types.never
    end

    assert_is(input, "input", input.tag, "table")

    if to_pick.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(to_pick:components())

        return table_type_filter(input, function(_, value): boolean
            local value_tag = value.tag

            if value_tag == "union" or value_tag == "intersection" then
                for _, component_a in value:components() do
                    for _, component_b in non_hashsettable do
                        if component_a == component_b then return false end
                    end
                end

            else
                if hashset_has_type(hashset, non_hashsettable, value) then return false end
            end

            return true
        end)

    else
        return table_type_filter(input, function(_, value)
            local value_tag = value.tag
            if value_tag == "union" or value_tag == "intersection" then
                for _, component in value:components() do
                    if component == to_pick then return false end
                end

            else
                if value == to_pick then return false end
            end

            return true
        end)
    end
end

--[=[
    Combines an intersection of tables into one consolidated table whilst preserving semantics.

    @param input { [any]: type } -- The table to flatten.
]=]
export type function FlattenTable(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "table" then return input end
    if input_tag == "union" then return union_from_components(components_map(input:components(), FlattenTable)) or types.never end
    if input_tag ~= "intersection" then return input end

    local components = input:components()

    local output
    local extra = {}

    -- Finds the initial table in the intersection
    local start_idx: number
    for idx, component in components do
        if component.tag == "table" then
            output = component :: typeof(types.newtable())
            start_idx = idx + 1
            break

        else
            table.insert(extra, component)
        end
    end

    if not output then return intersection_from_components(extra) or types.never end

    local output_indexer = output:indexer()
    -- TODO: add support for read and write indexers when available.
    --[[local output_read_indexer = output:readindexer()
    local output_write_indexer = output:writeindexer()]]

    for idx = start_idx, #components do
        local component = components[idx]
        if component.tag == "table" then
            for key, value in component:properties() do
                local value_read, value_write = value.read, value.write

                local can_add_read_to_output = not output:readproperty(key)
                local can_add_write_to_output = not output:writeproperty(key)

                if can_add_read_to_output and can_add_write_to_output then
                    if value_read == value_write then
                        output:setproperty(key, value_read)
                    else
                        output:setreadproperty(key, value_read)
                        output:setwriteproperty(key, value_write)
                    end
                
                elseif can_add_read_to_output then
                    output:setreadproperty(key, value_read)

                elseif can_add_write_to_output then
                    output:setwriteproperty(key, value_write)
                end

                if not output_indexer then
                    local component_indexer = component:indexer()
                    if component_indexer then
                        output:setindexer(component_indexer.index, component_indexer.readresult)
                        output_indexer = component_indexer
                    end
                end
                -- TODO: add support for read and write indexers when available.
                --[[if not output_read_indexer then
                    local component_read_indexer = component:readindexer()
                    if component_read_indexer then
                        output:setreadindexer(component_read_indexer.index, component_read_indexer.result)
                        output_read_indexer = component_read_indexer
                    end
                end
                if not output_write_indexer then
                    local component_write_indexer = component:writeindexer()
                    if component_write_indexer then
                        output:setwriteindexer(component_write_indexer.index, component_write_indexer.result)
                        output_write_indexer = component_write_indexer
                    end
                end]]
            end

        else
            table.insert(extra, component)
        end
    end

    if #extra ~= 0 then
        table.insert(extra, output)
        return intersection_from_components(extra) or types.never

    else
        return output
    end
end

--[=[
    Removes duplicate types from union and intersection keys and values in the specified table.

    @param input { [any]: type } -- The table to clean.
]=]
export type function CleanTable(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), CleanTable)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), CleanTable)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        local cleaned_key = Clean(key)

        if cleaned_key ~= key then
            input:setproperty(key, nil)
        end

        if value_read == value_write then
            input:setproperty(cleaned_key, Clean(value_read))

        else
            input:setreadproperty(cleaned_key, Clean(value_read))
            input:setwriteproperty(cleaned_key, Clean(value_write))
        end
    end

    -- TODO: add support for read and write indexers when available.
    local indexer = input:indexer()
    if indexer then
        local indexer_read_result = indexer.readresult
        if indexer_read_result then
            input:setindexer(Clean(indexer.index), Clean(indexer_read_result))
        end
    end

    return input
end

--[=[
    Removes duplicate types from union and intersection keys in the specified table.

    @param input { [any]: type } -- The table to clean.
]=]
export type function CleanTableKeys(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), CleanTableKeys)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), CleanTableKeys)) or types.never
    end

    for key, value in input:properties() do
        local cleaned_key = Clean(key)

        if cleaned_key ~= key then
            input:setproperty(key, nil)
        end
    end

    -- TODO: add support for read and write indexers when available.
    local indexer = input:indexer()
    if indexer then
        local indexer_read_result = indexer.readresult
        if indexer_read_result then
            input:setindexer(Clean(indexer.index), indexer_read_result)
        end
    end

    return input
end

--[=[
    Removes duplicate types from union and intersection values in the specified table.

    @param input { [any]: type } -- The table to clean.
]=]
export type function CleanTableValues(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), CleanTableValues)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), CleanTableValues)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            input:setproperty(key, Clean(value_read))

        else
            input:setreadproperty(key, Clean(value_read))
            input:setwriteproperty(key, Clean(value_write))
        end
    end

    -- TODO: add support for read and write indexers when available.
    local indexer = input:indexer()
    if indexer then
        local indexer_read_result = indexer.readresult
        if indexer_read_result then
            input:setindexer(indexer.index, Clean(indexer_read_result))
        end
    end

    return input
end

--[=[
    Makes every property in a table optional.

    @param input { [any]: type } -- The table to make partial.
]=]
type function Partial(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), Partial)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), Partial)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            input:setproperty(key, types.optional(value_read :: type))

        else
            if value_read then
                input:setreadproperty(key, types.optional(value_read))
            end

            if value_write then
                input:setwriteproperty(key, types.optional(value_write))
            end
        end
    end

    -- TODO: add support for read and write indexers when available.
    local indexer = input:indexer()
    if indexer then
        local indexer_read_result = indexer.readresult
        if indexer_read_result then
            input:setindexer(indexer.index, types.optional(indexer_read_result))
        end
    end

    return input
end

--[=[
    Makes every property in a table required.

    @param input { [any]: type } -- The table to make required.
]=]
type function Required(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), Required)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), Required)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    local nil_singleton = types.singleton("nil")

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            input:setproperty(key, non_optional(value_read, nil_singleton))

        else
            if value_read then
                input:setreadproperty(key, non_optional(value_read, nil_singleton))
            end

            if value_write then
                input:setwriteproperty(key, non_optional(value_write, nil_singleton))
            end
        end
    end

    -- TODO: add support for read and write indexers when available.
    local indexer = input:indexer()
    if indexer then
        local indexer_read_result = indexer.readresult
        if indexer_read_result then
            input:setindexer(indexer.index, types.optional(indexer_read_result))
        end
    end

    return input
end

--[=[
    Makes every property in a table read only.

    @param input { [any]: type } -- The table to make read only.
]=]
type function ReadOnly(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), ReadOnly)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), ReadOnly)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    for key, value in input:properties() do
        if value.write then
            input:setwriteproperty(key, nil)
        end
    end

    -- TODO: add support for read and write indexers when available.

    return input
end

--[=[
    Makes every property in a table read / write.

    @param input { [any]: type } -- The table to make read / write.
]=]
type function ReadWrite(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), ReadWrite)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), ReadWrite)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        if value_read and not value_write then
            input:setproperty(key, value_read)

        elseif value_write and not value_read then
            input:setproperty(key, value_write)
        end
    end

    -- TODO: add support for read and write indexers when available.

    return input
end
----------------------------------------------------------------------------------------

--> Function Types ---------------------------------------------------------------------
type function FlattenFunction(input: typeof(types.newfunction()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), FlattenFunction)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), FlattenFunction)) or types.never
    end

    assert_is(input, "input", input_tag, "function")

    local input_args = input:parameters()
    local input_args_head, input_args_tail = input_args.head, input_args.tail

    if input_args_head then
        for idx, arg in input_args_head do
            input_args_head[idx] = Flatten(arg)
        end
    end

    if input_args_tail then
        input_args_tail = Flatten(input_args_tail)
    end

    local input_returns = input:returns()
    local input_returns_head, input_returns_tail = input_returns.head, input_returns.tail

    if input_returns_head then
        for idx, returns_item in input_returns_head do
            input_returns_head[idx] = Flatten(returns_item)
        end
    end

    if input_returns_tail then
        input_returns_tail = Flatten(input_returns_tail)
    end

    return types.newfunction(
        { head = input_args_head, tail = input_args_tail },
        { head = input_returns_head, tail = input_returns_tail },
        input:generics()
    )
end

type function CleanFunction(input: typeof(types.newfunction()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), CleanFunction)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), CleanFunction)) or types.never
    end

    assert_is(input, "input", input_tag, "function")

    local input_args = input:parameters()
    local input_args_head, input_args_tail = input_args.head, input_args.tail

    if input_args_head then
        for idx, arg in input_args_head do
            input_args_head[idx] = Clean(arg)
        end
    end

    if input_args_tail then
        input_args_tail = Clean(input_args_tail)
    end

    local input_returns = input:returns()
    local input_returns_head, input_returns_tail = input_returns.head, input_returns.tail

    if input_returns_head then
        for idx, returns_item in input_returns_head do
            input_returns_head[idx] = Clean(returns_item)
        end
    end

    if input_returns_tail then
        input_returns_tail = Clean(input_returns_tail)
    end

    return types.newfunction(
        { head = input_args_head, tail = input_args_tail },
        { head = input_returns_head, tail = input_returns_tail },
        input:generics()
    )
end

type function Args(input: typeof(types.newfunction()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), Args)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), Args)) or types.never
    end

    assert_is(input, "input", input_tag, "function")

    local input_args = input:parameters()
    local input_args_head, input_args_tail = input_args.head, input_args.tail

    local output = types.newtable()

    if input_args_head then
        for idx, arg in input_args_head do
            output:setproperty(types.singleton(`{idx}`), arg)
        end
    end

    if input_args_tail then
        output:setproperty(types.singleton(`tail`), input_args_tail)
    end

    return output
end

type function Returns(input: typeof(types.newfunction()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), Returns)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), Returns)) or types.never
    end

    assert_is(input, "input", input_tag, "function")

    local input_returns = input:returns()
    local input_returns_head, input_returns_tail = input_returns.head, input_returns.tail

    local output = types.newtable()

    if input_returns_head then
        for idx, arg in input_returns_head do
            output:setproperty(types.singleton(`{idx}`), arg)
        end
    end

    if input_returns_tail then
        output:setproperty(types.singleton(`tail`), input_returns_tail)
    end

    return output
end
----------------------------------------------------------------------------------------

--> Miscellaneous Types ----------------------------------------------------------------
--[=[
    returns the inputted type but with unions and intersections turned into arrays so they can be inspected better.

    @param input any -- The type to be inspected.
]=]
export type function Inspect(input: type)
    local input_tag = input.tag

    if input_tag == "singleton" or is_primitive(input_tag) then return input end

    local output = types.newtable({
        [types.singleton("kind")] = types.singleton(input_tag)
    })

    for idx, component in input:components() do
        local component_tag = component.tag

        output:setproperty(
            types.singleton(`{idx}`),
            if component_tag == "union" or component_tag == "intersection" then Inspect(component) else component
        )
    end

    return output
end

--[=[
    Throws a type error if the first type does not equal the second.

    @param expect any -- The type to be compared.
    @param toBe any -- The type you want to compare `expect` to.
]=]
export type function Expect(type_a: type, type_b: type)
    if type_a ~= type_b then
        local type_a_tag, type_b_tag = type_a.tag, type_b.tag

        local type_a_name = if type_a_tag == "singleton" then type(type_a:value()) else type_a_tag
        local type_b_name = if type_b_tag == "singleton" then type(type_b:value()) else type_b_tag

        local error_msg_start = `\nExpected the {type_b_name} type below:{stringify_preview(type_b)}\n\n`
        local error_msg_end = `But Got this {type_a_name} type instead:{stringify_preview(type_a)}`

        error(`{error_msg_start}{error_msg_end}`)
    end

    return type_a
end

type function Stringify(input: type)
    return stringify_main(input, 1)
end

export type function print(input: type)
    print(Stringify(input))
end
----------------------------------------------------------------------------------------

return nil

--[[
    MIT License

    Copyright (c) 2025 Cameron P Campbell

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
