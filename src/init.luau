--!strict
--!nolint LocalShadow

--> Helpers ----------------------------------------------------------------------------
type function handle_negation<T>(input: type, callback: (input: type, input_tag: string) -> T)
    local input_tag = input.tag

    if input_tag == "negation" then
        local input_inner = input:inner()
        return types.negationof(callback(input_inner, input_inner.tag))

    else
        return callback(input, input_tag)
    end
end

type function innermost_tag(input: type)
    local input_tag = input.tag
    return if input_tag == "negation" then input:inner().tag else input_tag
end

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

-- The equality operator `==` is really strict with unions and intersections,
-- where the order of their components needs to be the same.
type function sort_type(input: type)
    local input_tag = input.tag

    if input_tag == "union" or input_tag == "intersection" then
        local components = input:components()

        table.sort(components, function(a: type, b: type): boolean
            local a_tag, b_tag = a.tag, b.tag

            return 
                if a_tag ~= b_tag then a_tag < b_tag
                elseif a_tag == "table" or a_tag == "union" or a_tag == "intersection" then stringify(a) > stringify(b)
                elseif a_tag ~= "singleton" then false
                else (a:value() :: any) < (b:value() :: any)
        end)

        for idx, component in components do
            components[idx] = sort_type(component)
        end

        return (if input_tag == "union" then union_from_components else intersection_from_components)(components)

    elseif input_tag == "function" then
        local params = input:parameters()
        local params_head, params_tail = params.head, params.tail

        if params_head then
            for idx, value in params_head do
                params_head[idx] = sort_type(value)
            end
        end

        if params_tail then
            params_tail = sort_type(params_tail)
        end

        local returns = input:returns()
        local returns_head, returns_tail = returns.head, returns.tail

        if returns_head then
            for idx, value in returns_head do
                returns_head[idx] = sort_type(value)
            end
        end

        if returns_tail then
            returns_tail = sort_type(returns_tail)
        end

        return types.newfunction(
            { head = params_head, tail = params_tail },
            { head = returns_head, tail = returns_tail }
        )


    elseif input_tag == "table" then
        for key, value in input:properties() do
            local value_read, value_write = value.read, value.write

            if value_read == value_write then
                input:setproperty(key, sort_type(value_read))
            else
                if value_read then
                    input:setreadproperty(key, sort_type(value_read))
                end
                if value_write then
                    input:setwriteproperty(key, sort_type(value_write))
                end
            end
        end

        -- TODO: add support for read and write indexers when available.
        local indexer = input:indexer()
        if indexer then
            input:setindexer(sort_type(indexer.index), sort_type(indexer.readresult))
        end

        return input

    elseif input_tag == "negation" then
        return types.negationof(sort_type(input:inner()))

    else
        return input
    end
end
----------------------------------------------------------------------------------------

--> Stringify Helpers ------------------------------------------------------------------
type function stringify_preview(input: type)
    return `\n> {string.gsub(stringify(input), "\n", "\n> ")}`
end

type function stringify_table(
    input: typeof(types.singleton(nil)), nestedness: number,
    pre_padding: string?, post_padding: string?
)
    local properties = input:properties()
    local indexer = input:indexer()

    if table_value_is_empty(properties, indexer) then return "{ }" end

    local next_nestedness = nestedness + 1

    local outer_padding = string.rep("   ", nestedness - 1)
    local padding = outer_padding .. "    "

    local stringified = `{pre_padding or outer_padding}\{`

    -- Sorts the table keys so its stringified representation 
    -- to ensure stringification is deterministic.
    local keys = {}
    for key in properties do table.insert(keys, key) end
    table.sort(keys, function(a, b) return tostring(a) > tostring(b) end)

    for _, key in keys do
        local value = properties[key]

        local key_value = if key.tag == "singleton" then key:value() else input

        local stringified_key =
            if type(key_value) == "string" then key_value
            else `[{stringify_main(key, next_nestedness, "", padding)}]`

        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            stringified ..= `\n{padding}{stringified_key}: {stringify_main(value_read, next_nestedness)}`

        else
            if value_read then
                stringified ..= `\n{padding}read {stringified_key}: {stringify_main(value_read, next_nestedness)}`
            end
            if value_write then
                stringified ..= `\n{padding}write {stringified_key}: {stringify_main(value_write, next_nestedness)}`
            end
        end
    end

    -- TODO: add support for read and write indexers when available.
    if indexer then
        local indexer_index = indexer.index
        local indexer_index_value = if indexer_index.tag == "singleton" then indexer_index:value() else input

        local stringified_indexer_index =
            if type(indexer_index_value) == "string" then indexer_index_value
            else `[{stringify_main(indexer_index, next_nestedness, "", padding)}]`

        stringified ..= `\n{padding}{stringified_indexer_index}: {stringify_main(indexer.readresult, next_nestedness)}`
    end

    return stringified .. `\n{post_padding or outer_padding}}`
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
    local params = input:parameters()
    local params_head, params_tail = params.head, params.tail

    local stringified_params: string
    if params_head then
        stringified_params = ""

        local params_head_len = #params_head
        for idx = 1, params_head_len - 1 do
            stringified_params ..= `{stringify(params_head[idx])}, `
        end
        stringified_params ..= `{stringify(params_head[params_head_len])}`

        if params_tail then
            local params_tail_tag = params_tail.tag
            if params_tail_tag == "union" or params_tail_tag == "intersection" then
                stringified_params ..= `, ...({stringify(params_tail)}))`
            else
                stringified_params ..= `, ...{stringify(params_tail)})`
            end
        end
    elseif params_tail then
        local params_tail_tag = params_tail.tag
        if params_tail_tag == "union" or params_tail_tag == "intersection" then
            stringified_params = `...({stringify(params_tail)})`
        else
            stringified_params = `...{stringify(params_tail)}`
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
            stringified_returns ..= `{stringify(returns_head[idx])}, `
        end
        stringified_returns ..= `{stringify(returns_head[returns_head_len])}`

        if returns_tail then
            local returns_tail_tag = returns_tail.tag
            if returns_tail_tag == "union" or returns_tail_tag == "intersection" then
                stringified_returns ..= `, ...({stringify(returns_tail)}))`
            else
                stringified_returns ..= `, ...{stringify(returns_tail)})`
            end
        end

    elseif returns_tail then
        local returns_tail_tag = returns_tail.tag
        if returns_tail_tag == "union" or returns_tail_tag == "intersection" then
            stringified_returns = `...({stringify(returns_tail)})`
        else
            stringified_returns = `...{stringify(returns_tail)}`
        end
    end

    local stringified_returns = 
        if returns_tail or (returns_head and returns_head_len >= 2) then `({stringified_returns})`
        else stringified_returns

    return `({stringified_params}) -> {stringified_returns}`
end

type function stringify_main(
    input: type, nestedness: number,
    pre_padding: string?, post_padding: string?
)
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
    elseif input_tag == "table" then return stringify_table(input, nestedness, pre_padding, post_padding)
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

type function stringify(input: type)
    return stringify_main(input, 1)
end
----------------------------------------------------------------------------------------


--> Hashset Helpers --------------------------------------------------------------------
type function hashset_can_insert(input_tag: string)
    return input_tag == "singleton"
end

type function hashset_insert(
    hashset: typeof(types.newtable()),
    non_hashsettable: { [number]: type },
    input: type,
    input_tag: string
)   
    if hashset_can_insert(input_tag) then
        hashset:setproperty(input, types.never)
    
    else
        table.insert(non_hashsettable, input)
    end
end

type function hashset_has_type(
    hashset: typeof(types.newtable()),
    non_hashsettable: { [number]: type },
    input: type,
    input_tag: string
)
    if hashset_can_insert(input_tag) then
        return if hashset:readproperty(input) then true else false

    else
        for _, component in non_hashsettable do
            if input == component then return true end
        end

        return false
    end
end

type function hashset_from_components(input: { [number]: type })
    local hashset = types.newtable()

    local input_len = #input

    for idx = input_len, 1, -1 do
        local component = input[idx]

        if hashset_can_insert(component.tag) then
            hashset:setproperty(component, types.never)
            input_len = table_value_swap_remove(input, input_len, idx)
        end
    end

    -- The input table should now only contain the 
    -- components that could not be inserted into the hashset.
    return hashset, input
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
                input_len = table_value_swap_remove(input, input_len, idx)
            else
                input[idx] = filtered
            end

        else
            if not callback(component) then continue end

            input_len = table_value_swap_remove(input, input_len, idx)
        end
    end

    return input
end

type function components_flatten(
    input: { [number]: type },
    as: "union" | "intersection",
    as_builder: (components: { [number]: type }) -> (typeof(types.unionof()) | typeof(types.intersectionof()))
)
    for idx = #input, 1, -1 do
        local component = input[idx]
        local component_tag = component.tag

        if component_tag == "negation" then
            component = component:inner()
            if component.tag ~= as then continue end

            local component = types.negationof(as_builder(components_flatten(component:components(), as)))
            input[idx] = component

        elseif component_tag == as then
            local component = components_flatten(component:components(), as)
            input[idx] = component[1]
            for idx = 2, #component do
                table.insert(input, component[idx])
            end
        end
    end

    return input
end

type function components_map(
    input: { [number]: type }, 
    callback: (value: type, ...any) -> any,
    ...: any
)
    for idx, value in input do
        input[idx] = callback(value, ...)
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
        local component_tag = component.tag
        
        if component_tag == as then
            local cleaned = as_builder(components_clean(component:components(), as, as_builder, hashset, non_hashsettable))

            if cleaned == nil then
                input_len = table_value_swap_remove(input, input_len, idx)
            else
                input[idx] = cleaned
            end
            
            continue

        elseif component_tag == "negation" then
            local inner = component:inner()

            if inner.tag == as then
                local cleaned = as_builder(components_clean(inner:components(), as, as_builder, hashset, non_hashsettable))

                if cleaned == nil then
                    input_len = table_value_swap_remove(input, input_len, idx)
                else
                    input[idx] = types.negationof(cleaned)
                end
                
                continue
            end
        end

        if hashset_has_type(hashset, non_hashsettable, component, component_tag) then
            input_len = table_value_swap_remove(input, input_len, idx)
        else
            hashset_insert(hashset, non_hashsettable, component, component_tag)
        end
    end

    return input
end

type function components_clean_unions_and_intersections(
    input: { [number]: type },
    hashset: typeof(types.newtable()),
    non_hashsettable: { [number]: type },

    input_tag: string,
    input_tag_other: string,

    input_builder: (components: { [number]: type }) -> (typeof(types.unionof()) | typeof(types.intersectionof())),
    input_builder_other: (components: { [number]: type }) -> (typeof(types.unionof()) | typeof(types.intersectionof()))
)   
    local input_len = #input
    for idx = input_len, 1, -1 do
        local component = input[idx]
        local component_tag = component.tag
        
        if component_tag == input_tag then
            local cleaned = input_builder(components_clean_unions_and_intersections(
                component:components(), hashset, non_hashsettable,
                input_tag, input_tag_other, input_builder, input_builder_other
            ))

            if cleaned == nil then
                input_len = table_value_swap_remove(input, input_len, idx)
            else
                input[idx] = cleaned
            end

        elseif component_tag == input_tag_other then
            local cleaned = input_builder_other(components_clean_unions_and_intersections(
                component:components(), types.newtable(), {},
                input_tag_other, input_tag, input_builder_other, input_builder
            ))

            if cleaned == nil then
                input_len = table_value_swap_remove(input, input_len, idx)
            else
                input[idx] = cleaned
            end

        else
            if hashset_has_type(hashset, non_hashsettable, component, component_tag) then
                input_len = table_value_swap_remove(input, input_len, idx)
            else
                hashset_insert(hashset, non_hashsettable, component, component_tag)
            end
        end
    end

    return input
end

type function components_find_type(input: { [number]: type }, tag: string): (type?, number?)
    for idx, component in input do
        if component.tag ~= tag then continue end
        return component, idx
    end

    return nil, nil
end
----------------------------------------------------------------------------------------

--> Union Helpers ----------------------------------------------------------------------
type function union_from_components(input: { [number]: type })
    local input_len = #input
    return if input_len == 0 then nil elseif input_len == 1 then input[1] else types.unionof(table.unpack(input))
end

type function union_filter(input: type, input_tag: string, callback: (component: type) -> boolean)
    if input_tag == "union" then
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

type function intersection_filter(input: type, input_tag: string, callback: (component: type) -> boolean)
    if input_tag == "intersection" then
        return intersection_from_components(components_filter(input:components(), "intersection", intersection_from_components, callback))
    else
        return if callback(input) then nil else input
    end
end
----------------------------------------------------------------------------------------

--> Table Helpers ----------------------------------------------------------------------
type function table_value_swap_remove(input: { [any]: any }, input_len: number, idx: number)
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

type function table_value_is_empty(properties: { [any]: any }, indexer: type)
    if indexer then return false end

    for _ in properties do return false end
    return true
end

type function table_flatten_with(
    input: typeof(types.newtable()),
    with: typeof(types.newtable()),
    can_add_read_indexer: boolean,
    can_add_write_indexer: boolean
)
    for key, value in with:properties() do
        local can_add_read_property = not input:readproperty(key)
        local can_add_write_property = not input:writeproperty(key)

        if can_add_read_property and can_add_write_property then
            local value_read, value_write = value.read, value.write

            if value_read == value_write then
                input:setproperty(key, value_read)
            else
                if value_read then
                    input:setreadproperty(key, value_read)
                end

                if value_write then
                    input:setwriteproperty(key, value_write)
                end
            end

        else
            if can_add_read_property then
                local value_read = value.read
                if value_read then
                    input:setreadproperty(key, value_read)
                end
            end

            if can_add_write_property then
                local value_write = value.write
                if value_write then
                    input:setreadproperty(key, value_write)
                end
            end
        end
    end

    local indexer = with:indexer()
    if indexer then
        if can_add_read_indexer and can_add_write_indexer then
            local indexer_read, indexer_write = indexer.readresult, indexer.writeresult
            
            if indexer_read == indexer_write then
                input:setindexer(indexer.index, indexer_read)

            else
                if indexer_read and indexer_write then
                    local indexer_index = indexer.index
                    input:setreadindexer(indexer_index, indexer_read)
                    input:setwriteindexer(indexer_index, indexer_write)
                    can_add_read_indexer, can_add_write_indexer = false, false
                    
                elseif indexer_read then
                    input:setreadindexer(indexer.index, indexer_read)
                    can_add_read_indexer = false

                elseif indexer_write then
                    input:setwriteindexer(indexer.index, indexer_write)
                    can_add_write_indexer = false
                end
            end

        else
            if can_add_read_indexer then
                local indexer_read = indexer.readresult
                if indexer_read then
                    input:setreadindexer(indexer.index, indexer_read)
                    can_add_read_indexer = false
                end

            elseif can_add_write_indexer then
                local indexer_write = indexer.writeresult
                if indexer_write then
                    input:setwriteindexer(indexer.index, indexer_write)
                    can_add_write_indexer = false
                end
            end
        end
    end

    return can_add_read_indexer, can_add_write_indexer
end

-- Currently there is no way to remove an indexer from
-- a table type. So we resort to a hacky workaround of
-- creating a new table type and copying all information
-- from the input table type except the indexer.
type function table_remove_indexer_hacky_fix(input: typeof(types.newtable()))
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
type function table_remove_read_indexer_hacky_fix(input: typeof(types.newtable()))
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
        local indexer_write = indexer.writeresult
        if indexer_write then
            output:setwriteindexer(indexer.index, indexer_write)
        end
    end

    return output
end

-- Currently there is no way to remove a write indexer from
-- a table type. So we resort to a hacky workaround of
-- creating a new table type and copying all information
-- from the input table type except the write indexer.
type function table_remove_write_indexer_hacky_fix(input: typeof(types.newtable()))
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
        local indexer_read = indexer.readresult
        if indexer_read then
            output:setreadindexer(indexer.index, indexer_read)
        end
    end

    return output
end

type function table_set_indexer_or_remove(
    input: typeof(types.newtable()),
    index: type, result: type?
)
    if not result then return table_remove_indexer_hacky_fix(input)
    else input:setindexer(index, result) end
    return input
end

type function table_set_read_indexer_or_remove(
    input: typeof(types.newtable()),
    index: type, result: type?
)
    if not result then return table_remove_read_indexer_hacky_fix(input)
    else input:setreadindexer(index, result) end
    return input
end

type function table_set_write_indexer_or_remove(
    input: typeof(types.newtable()),
    index: type, result: type?
)
    if not result then return table_remove_write_indexer_hacky_fix(input)
    else input:setwriteindexer(index, result) end
    return input
end

type function table_filter_process_value(
    input: typeof(types.newtable()),
    key: type,
    value: type,
    value_callback: (value: type) -> boolean,
    setter_method: (input: typeof(types.newtable()), key: type, value: type?) -> nil
)
    local value_tag = (value :: type).tag
    if value_tag == "union" then
        local value = union_from_components(components_filter(value:components(), "union", union_from_components, value_callback))
        setter_method(input, key, value)

    elseif value_tag == "intersection" then
        local value = intersection_from_components(
            components_filter(value:components(), "intersection", intersection_from_components, value_callback)
        )
        setter_method(input, key, value)

    elseif value_callback(value :: type) then
        setter_method(input, key, nil)
    end
end

type function table_filter_process_indexer_result(
    input: typeof(types.newtable()),
    key: type,
    value: type,
    value_callback: (value: type) -> boolean,
    setter_method: (input: typeof(types.newtable()), key: type, value: type?) -> nil,
    key_updated: boolean
)
    local value_tag = (value :: type).tag
    if value_tag == "union" then
        local value = union_from_components(components_filter(value:components(), "union", union_from_components, value_callback))
        -- We need to set the input here in case a new table is
        -- returned as part of hacky table indexer removal.
        input = setter_method(input, key, value) or input

    elseif value_tag == "intersection" then
        local value = intersection_from_components(
            components_filter(value:components(), "intersection", intersection_from_components, value_callback)
        )
        -- We need to set the input here in case a new table is
        -- returned as part of hacky table indexer removal.
        input = setter_method(input, key, value) or input

    elseif value_callback(value :: type) then
        -- We need to set the input here in case a new table is
        -- returned as part of hacky table indexer removal.
        input = setter_method(input, key, nil) or input

    elseif key_updated then
        -- We need to set the input here in case a new table is
        -- returned as part of hacky table indexer removal.
        input = setter_method(input, key, value) or input
    end

    -- We need to return the input here in case a new table is
    -- returned as part of hacky table indexer removal.
    return input
end

type function table_filter_by_keys(
    input: typeof(types.newtable()),
    callback: (input: type) -> boolean
)
    for key, value in input:properties() do
        if callback(key) then
            input:setproperty(key, nil)
            continue
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_index = indexer.index

        local indexer_index_tag = (indexer_index :: type).tag
        if indexer_index_tag == "union" then
            local filtered_indexer_index = union_from_components(
                components_filter(indexer_index:components(), "union", union_from_components, callback)
            )

            if filtered_indexer_index == nil then
                return table_remove_indexer_hacky_fix(input)
            else
                -- TODO: add support for read and write indexers when available.
                input:setindexer(filtered_indexer_index, indexer.readresult)
                --input:setreadindexer(filtered_indexer_index, indexer.readresult)
                --input:setwriteindexer(filtered_indexer_index, indexer.writeresult)
            end

        elseif indexer_index_tag == "intersection" then
            local filtered_indexer_index = intersection_from_components(
                components_filter(indexer_index:components(), "intersection", intersection_from_components, callback)
            )

            if filtered_indexer_index == nil then
                return table_remove_indexer_hacky_fix(input)
            else
                input:setreadindexer(filtered_indexer_index, indexer.readresult)
                input:setwriteindexer(filtered_indexer_index, indexer.writeresult)
            end
        end
    end

    return input
end

type function table_filter_by_values(
    input: typeof(types.newtable()),
    callback: (key: type) -> boolean
)
    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write
        -- If the read and write values are identical then we only
        -- need to perform the filter check on one of them.
        if value_read == value_write then
            table_filter_process_value(input, key, value_read, callback, input.setproperty)

        else
            table_filter_process_value(input, key, value_read, callback, input.setreadproperty)
            table_filter_process_value(input, key, value_write, callback, input.setwriteproperty)
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_index = indexer.index

        local indexer_read, indexer_write = indexer.readresult, indexer.writeresult

        -- If the read and write values are identical then we only
        -- need to perform the filter check on one of them.
        if indexer_read == indexer_write then
            input = table_filter_process_indexer_result(
                input, indexer_index, indexer_read, callback,
                table_set_indexer_or_remove, false
            )

        else
            input = table_filter_process_indexer_result(
                input, indexer_index, indexer_read, callback,
                table_set_read_indexer_or_remove, false
            )
            input = table_filter_process_indexer_result(
                input, indexer_index, indexer_write, callback,
                table_set_write_indexer_or_remove, false
            )
        end
    end

    return input
end

type function table_map_values_deep(
    input: typeof(types.newtable()),
    callback: (input: type) -> type?
)
    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            input:setproperty(key, callback(
                if (value_read :: type).tag == "table" then table_map_values_deep(value_read, callback)
                else value_read :: type
            ))

        else
            if value_read then
                input:setreadproperty(key, callback(
                    if value_read.tag == "table" then table_map_values_deep(value_read, callback)
                    else value_read
                ))
            end

            if value_write then
                input:setwriteproperty(key, callback(
                    if value_write.tag == "table" then table_map_values_deep(value_write, callback)
                    else value_write
                ))
            end
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_index = indexer.index
        local indexer_read, indexer_write = indexer.readresult, indexer.writeresult

        if indexer_read == indexer_write then
            table_set_indexer_or_remove(input, indexer_index, callback(
                if (indexer_read :: type).tag == "table" then table_map_values_deep(indexer_read, callback)
                else indexer_read :: type
            ))

        else
            if indexer_read then
                table_set_read_indexer_or_remove(input, indexer_index, callback(
                    if indexer_read.tag == "table" then table_map_values_deep(indexer_read, callback)
                    else indexer_read
                ))
            end

            if indexer_write then
                table_set_read_indexer_or_remove(input, indexer_index, callback(
                    if indexer_write.tag == "table" then table_map_values_deep(indexer_write, callback)
                    else indexer_write
                ))
            end
        end
    end

    return input
end

type function table_map_values_shallow(
    input: typeof(types.newtable()),
    callback: (input: type) -> type?
)
    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            input:setproperty(key, callback(value_read :: type))

        else
            if value_read then
                input:setreadproperty(key, callback(value_read))
            end

            if value_write then
                input:setwriteproperty(key, callback(value_write))
            end
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_index = indexer.index
        local indexer_read, indexer_write = indexer.readresult, indexer.writeresult

        if indexer_read == indexer_write then
            table_set_indexer_or_remove(input, indexer_index, callback(indexer_read))

        else
            if indexer_read then
                table_set_read_indexer_or_remove(input, indexer_index, callback(indexer_read
                ))
            end

            if indexer_write then
                table_set_read_indexer_or_remove(input, indexer_index, callback(indexer_write))
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

    @example
    type Result = Omit<
        "hello" | "world" | "foo" | "bar",
        "world" | "bar"
    >

    -- type Result = "foo" | "hello"
]=]
export type function Omit(input: type, to_omit: type)
    local input_tag = innermost_tag(input)

    return
        if input_tag == "table" then
            OmitTableByKeys(input, to_omit)

        elseif input_tag == "intersection" then
            if components_find_type(input:components(), "table") then
                OmitTableByKeys(input, to_omit)
            else
                OmitIntersection(input, to_omit)

        else
            if components_find_type(input:components(), "table") then
                OmitTableByKeys(input, to_omit)
            else
                OmitUnion(input, to_omit)
end

--[=[
    Returns a subset of a type with only specified components / properties.

    @param input any -- The type to pick from.
    @param to_pick any -- The components / properties to pick.

    @example
    type Result = Pick<
        "hello" & "world" & "foo" & "bar",
        "world" | "bar"
    >

    -- type Result = "bar" & "world"
]=]
export type function Pick(input: type, to_pick: type)
    local input_tag = innermost_tag(input)

    return
        if input_tag == "table" then
            PickTableByKeys(input, to_pick)

        elseif input_tag == "intersection" then
            if components_find_type(input:components(), "table") then
                PickTableByKeys(input, to_pick)
            else
                PickIntersection(input, to_pick)

        else
            if components_find_type(input:components(), "table") then
                PickTableByKeys(input, to_pick)
            else
                PickUnion(input, to_pick)
end

--[=[
    Combines a nested union or intersection into one union / intersection.
    Combines an intersection of tables into one consolidated table whilst preserving semantics.

    @param input any -- The type to flatten.

    @example
    type Result = Flatten<({ hello: "world" } & ({ foo: "bar" } | { lol: "kek" }))>

    --[[
        type Result = {
            foo: "bar",
            hello: "world"
        } | {
            hello: "world",
            lol: "kek"
        }
    ]]
]=]
export type function Flatten(input: type)
    return handle_negation(input, function(input: type)
        return FlattenFunction(FlattenTable(unions_and_intersections_flatten(input)))
    end)
end

--[=[
    Removes duplicate components / properties from a type.

    @param input any -- The type to clean.

    @example
    type Result = Clean<{
        age: number | number,
        [boolean]: boolean | boolean
    }>

    --[[
        type Result = {
            [boolean]: boolean,
            age: number
        }
    ]]  
]=]
export type function Clean(input: type)
    return handle_negation(input, function(input: type, input_tag: string)
        local is_union = input_tag == "union"
        local is_not_union = not is_union
        local is_intersection = is_not_union and input_tag == "intersection"

        if is_not_union and (not is_intersection) and input_tag ~= "table" and input_tag ~= "function" then
            return input
        end

        return CleanTable(CleanFunction(
            if is_union then
                union_from_components(components_clean_unions_and_intersections(
                    input:components(), types.newtable(), { },
                    input_tag, "intersection", union_from_components, intersection_from_components
                ))

            elseif is_intersection then
                intersection_from_components(components_clean_unions_and_intersections(
                    input:components(), types.newtable(), { },
                    input_tag, "union", intersection_from_components, union_from_components
                ))

            else input
        ))
    end)
end
----------------------------------------------------------------------------------------

--> Union Types ------------------------------------------------------------------------
--[=[
    Returns a subset of a union without specified components.

    @param input any -- The union to omit from.
    @param to_omit any -- The components to omit.

    @example
    type Result = OmitUnion<
        "hello" | string | "world",
        "world"
    >

    -- type Result = "hello" | string
]=]
export type function OmitUnion(input: type, to_omit: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "intersection" then
            return intersection_from_components(components_map(input:components(), OmitUnion, to_omit))
        end
        
        if to_omit.tag == "union" then
            local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_omit):components())
    
            return union_filter(input, input_tag, function(component): boolean
                return hashset_has_type(hashset, non_hashsettable, component, component.tag)
            end) or types.never
    
        else
            return union_filter(input, input_tag, function(component)
                return component == to_omit
            end) or types.never
        end
    end)
end

--[=[
    Returns a subset of a union with only specified components.

    @param input any -- The union to pick from.
    @param to_pick any -- The components to pick.

    @example
    type Result = PickUnion<
        "hello" | string | "world",
        "world"
    >

    -- type Result = "world"
]=]
export type function PickUnion(input: type, to_pick: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "intersection" then
            return intersection_from_components(components_map(input:components(), PickUnion, to_pick))
        end
    
        if to_pick.tag == "union" then
            local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_pick):components())
    
            return union_filter(input, input_tag, function(component): boolean
                return not hashset_has_type(hashset, non_hashsettable, component, component.tag)
            end) or types.never
    
        else
            return union_filter(input, input_tag, function(component)
                return component ~= to_pick
            end) or types.never
        end
    end)
end

--[=[
    Recursively combines nested unions into one union.

    @param input any -- The union to flatten.

    @example
    type Result = FlattenUnion<"foo" | ("hello" | ("world" | "lol"))>

    -- type Result = "foo" | "hello" | "lol" | "world"
]=]
export type function FlattenUnion(input: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "intersection" then
            return intersection_from_components(components_map(input:components(), FlattenUnion))
        end
    
        if input_tag == "union" then
            return union_from_components(components_flatten(input:components(), "union", union_from_components)) or types.never
        else
            return input
        end
    end)
end

--[=[
    Removes duplicate types from a union.

    @param input any -- The union to clean.

    @example
    type Result = CleanUnion<"hello" | string | "world" | string | "foo" | "hello">

    -- type Result = "foo" | "hello" | "world" | string
]=]
export type function CleanUnion(input: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "intersection" then
            return intersection_from_components(components_map(input:components(), CleanUnion))
        end
    
        if input_tag == "union" then
            return union_from_components(
                components_clean(input:components(), "union", union_from_components, types.newtable(), { })
            ) or types.never
    
        else
            return input
        end
    end)
end
----------------------------------------------------------------------------------------

--> Intersection Types -----------------------------------------------------------------
--[=[
    Returns a subset of an intersection without specified components.

    @param input any -- The intersection to omit from.
    @param to_omit any -- The components to omit.

    @example
    type Result = OmitIntersection<
        "hello" & string & "world",
        "world"
    >

    -- type Result = "hello" & string
]=]
export type function OmitIntersection(input: type, to_omit: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "union" then
            return union_from_components(components_map(input:components(), OmitIntersection, to_omit))
        end
    
        if to_omit.tag == "union" then
            local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_omit):components())
    
            return intersection_filter(input, input_tag, function(component): boolean
                return hashset_has_type(hashset, non_hashsettable, component, component.tag)
            end) or types.never
    
        else
            return intersection_filter(input, input_tag, function(component)
                return component == to_omit
            end) or types.never
        end
    end)
end

--[=[
    Returns a subset of an intersection with only specified components.

    @param input any -- The intersection to pick from.
    @param to_pick any -- The components to pick.

    @example
    type Result = PickIntersection<
        "hello" & string & "world",
        "world"
    >

    -- type Result = "world"
]=]
export type function PickIntersection(input: type, to_pick: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "union" then
            return union_from_components(components_map(input:components(), PickIntersection, to_pick))
        end
    
        assert_is(input, "input", input_tag, "intersection")
    
        if to_pick.tag == "union" then
            local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_pick):components())
    
            return intersection_filter(input, input_tag, function(component): boolean
                return not hashset_has_type(hashset, non_hashsettable, component, component.tag)
            end) or types.never
    
        else
            return intersection_filter(input, input_tag, function(component)
                return component ~= to_pick
            end) or types.never
        end
    end)
end

--[=[
    Combines nested intersections into one intersection.

    @param input any -- The intersection to flatten.

    @example
    type Result = FlattenIntersection<"foo" & ("hello" & ("world" & "lol"))>

    -- type Result = "foo" & "hello" & "lol" & "world"
]=]
export type function FlattenIntersection(input: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "union" then
            return union_from_components(components_map(input:components(), FlattenIntersection)) or types.never
        end
    
        assert_is(input, "input", input_tag, "intersection")
    
        if input_tag == "intersection" then
            return intersection_from_components(
                components_flatten(input:components(), "intersection", intersection_from_components)
            ) or types.never
        else
            return input
        end
    end)
end

--[=[
    Removes duplicate types from an intersection.

    @param input any -- The intersection to clean.

    @example
    type Result = CleanIntersection<"hello" & string & "world" & string & "foo" & "hello">

    -- type Result = "foo" & "hello" & "world" & string
]=]
export type function CleanIntersection(input: type)
    return handle_negation(input, function(input: type, input_tag: string)
        if input_tag == "union" then
            return union_from_components(components_map(input:components(), CleanIntersection)) or types.never
        end
    
        assert_is(input, "input", input_tag, "intersection")
    
        if input_tag == "intersection" then
            return intersection_from_components(
                components_clean(input:components(), "intersection", intersection_from_components, types.newtable(), { })
            ) or types.never
    
        else
            return input
        end
    end)
end
----------------------------------------------------------------------------------------

--> Table Types ------------------------------------------------------------------------
--[=[
    Returns a subset of a table without properties whose keys contain the specified components.

    @param input { [any]: type } -- The table to omit from.
    @param to_omit any -- The values of the properties to omit.

    @example
    type Result = OmitTableByKeys<{ hello: string, foo: "bar", bar: number }, "hello" | "foo">

    -- type Result = type Result = { bar: number }
]=]
export type function OmitTableByKeys(input: typeof(types.newtable()), to_omit: type)
    local input_tag = input.tag

    if input_tag == "union" then
        return union_from_components(components_map(input:components(), OmitTableByKeys, to_omit)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), OmitTableByKeys, to_omit)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    if to_omit.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_omit):components())

        return table_filter_by_keys(input, function(component: type)
            return if hashset_has_type(hashset, non_hashsettable, component, component.tag) then true else false
        end)

    else
        return table_filter_by_keys(input, function(component: type)
            return component == to_omit
        end)
    end
end

--[=[
    Returns a subset of a table without properties whose values contain the specified components.

    @param input { [any]: type } -- The table to omit from.
    @param to_omit any -- The values of the properties to omit.

    @example
    type Result = OmitTableByValues<{ hello: string, foo: "bar", bar: number }, "bar" | string>

    -- type Result = type Result = { bar: number }
]=]
export type function OmitTableByValues(input: typeof(types.newtable()), to_omit: type)
    local input_tag = input.tag

    if input_tag == "union" then
        return union_from_components(components_map(input:components(), OmitTableByValues, to_omit)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), OmitTableByValues, to_omit)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    if to_omit.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_omit):components())

        return table_filter_by_values(input, function(component: type)
            return if hashset_has_type(hashset, non_hashsettable, component, component.tag) then true else false
        end)

    else
        return table_filter_by_values(input, function(component: type)
            return component == to_omit
        end)
    end
end

--[=[
    Returns a subset of a table with only properties whose keys contain the specified components.

    @param input { [any]: type } -- The table to pick from.
    @param to_pick any -- The keys of the properties to pick.

    @example
    type Result = PickTableByKeys<{ hello: string, foo: "bar", bar: number }, "hello" | "foo">

    -- type Result = type Result = { foo: "bar", hello: string }
]=]
export type function PickTableByKeys(input: typeof(types.newtable()), to_pick: type)
    local input_tag = input.tag

    if input_tag == "union" then
        return union_from_components(components_map(input:components(), PickTableByKeys, to_pick)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), PickTableByKeys, to_pick)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    if to_pick.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_pick):components())

        return table_filter_by_keys(input, function(component: type)
            return if not hashset_has_type(hashset, non_hashsettable, component, component.tag) then true else false
        end)

    else
        return table_filter_by_keys(input, function(component: type)
            return component ~= to_pick
        end)
    end
end

--[=[
    Returns a subset of a table with only properties whose values contain the specified components.

    @param input { [any]: type } -- The table to pick from.
    @param to_pick any -- The values of the properties to pick.

    @example
    type Result = PickTableByValues<{ hello: string, foo: "bar", bar: number }, "bar" | string>

    -- type Result = type Result = { foo: "bar", hello: string }
]=]
export type function PickTableByValues(input: typeof(types.newtable()), to_pick: type)
    local input_tag = input.tag

    if input_tag == "union" then
        return union_from_components(components_map(input:components(), PickTableByValues, to_pick)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), PickTableByValues, to_pick)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    if to_pick.tag == "union" then
        local hashset, non_hashsettable = hashset_from_components(FlattenUnion(to_pick):components())

        return table_filter_by_values(input, function(component: type)
            return if not hashset_has_type(hashset, non_hashsettable, component, component.tag) then true else false
        end)

    else
        return table_filter_by_values(input, function(component: type)
            return component ~= to_pick
        end)
    end
end

--[=[
    Combines an intersection of tables into one consolidated table whilst preserving semantics.

    @param input { [any]: type } -- The table to flatten.

    @example
    type Result = FlattenTable<
        { name: string, salary: number } &
        { kind: "employee" }
    >

    --[[
        type Result = {
            name: string,
            salary: number,
            kind: "employee"
        }
    ]]
]=]
export type function FlattenTable(input: type)
    local input_tag = input.tag
    if input_tag == "table" then return input end
    if input_tag == "union" then return union_from_components(components_map(input:components(), FlattenTable)) or types.never end
    if input_tag ~= "intersection" then return input end

    local components = components_map(input:components(), FlattenTable)

    local output: typeof(types.newtable()), output_idx: number
    local can_add_read_indexer, can_add_write_indexer

    local output_union_components = {}
    local output_non_table_intersection_components = {}
   
    for idx, component in components do
        local component_tag = component.tag

        if component_tag == "union" then
            for _, sub_component in Flatten(component):components() do
                table.insert(
                    output_union_components,
                    sub_component
                )
            end

        elseif component_tag == "intersection" then
            local sub_components = Flatten(component):components()
            local sub_output_idx
            for sub_idx, sub_component in sub_components do
                if sub_component.tag == "table" then
                    output = sub_component :: typeof(types.newtable())
                    can_add_read_indexer = not output:readindexer()
                    can_add_write_indexer = not output:writeindexer()

                    sub_output_idx = sub_idx
                    output_idx = idx
                    break
                end

                table.insert(output_non_table_intersection_components, sub_component :: type)
            end

            if sub_output_idx then
                for sub_idx = sub_output_idx + 1, #sub_components do
                    local sub_component = sub_components[sub_idx]
                    if sub_component.tag == "table" then
                        can_add_read_indexer, can_add_write_indexer = table_flatten_with(
                            output, sub_component, can_add_read_indexer, can_add_write_indexer
                        )
                    else
                        table.insert(output_non_table_intersection_components, sub_component :: type)
                    end
                end
                break
            end

        elseif component_tag == "table" then
            output = component
            can_add_read_indexer = not output:readindexer()
            can_add_write_indexer = not output:writeindexer()

            output_idx = idx
            break
            
        else
            table.insert(output_non_table_intersection_components, component)
        end
    end

    if not output then return intersection_from_components(components) end

    local components_len = #components
    for idx = components_len, output_idx + 1, -1 do
        local component = components[idx]
        local component_tag = component.tag

        if component_tag == "union" then
            for _, sub_component in Flatten(component):components() do
                table.insert(
                    output_union_components,
                    sub_component
                )
            end

        elseif component_tag == "intersection" then
            for _, sub_component in Flatten(component):components() do
                if sub_component.tag == "table" then
                    can_add_read_indexer, can_add_write_indexer = table_flatten_with(
                        output, sub_component, can_add_read_indexer, can_add_write_indexer
                    )
                else
                    table.insert(output_non_table_intersection_components, sub_component :: type)
                end
            end
        
        elseif component_tag == "table" then
            can_add_read_indexer, can_add_write_indexer = table_flatten_with(
                output, component, can_add_read_indexer, can_add_write_indexer
            )
            
        else
            table.insert(output_non_table_intersection_components, component)
        end
    end

    if #output_union_components ~= 0 then
        output = union_from_components(components_map(output_union_components, function(component)
            if component.tag == "table" then
                local output_copy = types.copy(output)
                table_flatten_with(output_copy, component, can_add_read_indexer, can_add_write_indexer)
                return output_copy
            else
                return types.intersectionof(output, component)
            end
        end))
    end

    if #output_non_table_intersection_components ~= 0 then
        local output_components = output_non_table_intersection_components
        table.insert(output_non_table_intersection_components, output :: type)

        output = intersection_from_components(output_components)
    end

    return output
end


--[=[
    Removes duplicate types from union and intersection keys and values in the specified table.

    @param input { [any]: type } -- The table to clean.

    @example
    type Result = TableClean<{ name: string | string, salary: number }>

    -- type Result = { name: string, salary: number }
]=]
export type function CleanTable(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), CleanTable)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), CleanTable)) or types.never
    end

    if input_tag ~= "table" then return input end

    for key, value in input:properties() do
        local value_read, value_write = value.read, value.write

        if value_read == value_write then
            input:setproperty(key, Clean(value_read))

        else
            if value_read then
                input:setreadproperty(key, Clean(value_read))
            end

            if value_write then
                input:setwriteproperty(key, Clean(value_write))
            end
        end
    end

    local indexer = input:indexer()
    if indexer then
        local indexer_read, indexer_write = indexer.readresult, indexer.writeresult

        if indexer_read and indexer_write then
            local cleaned_indexer_index = Clean(indexer.index)

            if indexer_read == indexer_write then
                input:setindexer(cleaned_indexer_index, Clean(indexer_read))
            
            else
                input:setreadindexer(cleaned_indexer_index, Clean(indexer_read))
                input:setwriteindexer(cleaned_indexer_index, Clean(indexer_write))
            end

        else
            if indexer_read then
                input:setreadindexer(Clean(indexer.index), Clean(indexer_read))

            elseif indexer_write then
                input:setwriteindexer(Clean(indexer.index), Clean(indexer_write))
            end
        end
    end

    return input
end

--[=[
    Makes every property in a table optional.

    @param input { [any]: type } -- The table to make partial.

    @example
    type Result = Partial<{ hello: "world", foo: "bar" }>

    -- type Result = { foo: "bar"?, hello: "world"? }
]=]
export type function Partial(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), Partial)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), Partial)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    return table_map_values_shallow(input, function(value)
        return types.optional(value)
    end)
end

--[=[
    Makes every property in a table required.

    @param input { [any]: type } -- The table to make required.

    @example
    type Result = Required<{ hello: "world"?, foo: "bar"? }>

    -- type Result = { foo: "bar", hello: "world" }
]=]
export type function Required(input: typeof(types.newtable()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), Required)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), Required)) or types.never
    end

    assert_is(input, "input", input_tag, "table")

    local nil_singleton = types.singleton("nil")

    return table_map_values_shallow(input, function(value)
        return non_optional(value, nil_singleton)
    end)
end

--[=[
    Makes every property in a table read only.

    @param input { [any]: type } -- The table to make read only.

    @example
    type Result = ReadOnly<{ hello: "world", foo: "bar" }>

    -- type Result = { read foo: "bar", read hello: "world" }
]=]
export type function ReadOnly(input: typeof(types.newtable()))
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

    @example
    type Result = ReadWrite<{ read hello: "world", foo: "bar" }>

    -- type Result = { foo: "bar", hello: "world" }
]=]
export type function ReadWrite(input: typeof(types.newtable()))
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
--[=[
    Flattens unions, intersections and tables inside function parameter and return types.

    @param input (...any) -> (...any) -- The function to flatten.

    @example
    type Result = FlattenFunction<(string | (number | boolean)) -> (any & (boolean & number))>

    -- type Result = (boolean | number | string) -> any & boolean & number
]=]
export type function FlattenFunction(input: typeof(types.newfunction()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), FlattenFunction)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), FlattenFunction)) or types.never
    end

    if input_tag ~= "function" then return input end

    local input_params = input:parameters()
    local input_params_head, input_params_tail = input_params.head, input_params.tail

    if input_params_head then
        for idx, param in input_params_head do
            input_params_head[idx] = Flatten(param)
        end
    end

    if input_params_tail then
        input_params_tail = Flatten(input_params_tail)
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
        { head = input_params_head, tail = input_params_tail },
        { head = input_returns_head, tail = input_returns_tail },
        input:generics()
    )
end

--[=[
    Removes duplicate components / properties from function param and return types.

    @param input (...any) -> (...any) -- The function to clean.

    @example
    type Result = CleanFunction<(number, string | string | boolean) -> any | any>

    -- type Result = (number, boolean | string) -> any
]=]
export type function CleanFunction(input: typeof(types.newfunction()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), CleanFunction)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), CleanFunction)) or types.never
    end

    if input_tag ~= "function" then return input end

    local input_params = input:parameters()
    local input_params_head, input_params_tail = input_params.head, input_params.tail

    if input_params_head then
        for idx, param in input_params_head do
            input_params_head[idx] = Clean(param)
        end
    end

    if input_params_tail then
        input_params_tail = Clean(input_params_tail)
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
        { head = input_params_head, tail = input_params_tail },
        { head = input_returns_head, tail = input_returns_tail },
        input:generics()
    )
end

--[=[
    Gets the parameters for a function.

    @param input (...any) -> (...any) -- The function to get params for.

    @example
    type Result = Params<(number, string, boolean, ...{ any }) -> any>

    --[[
        type Result = {
            1: number,
            2: string,
            3: boolean,
            tail: {any}
        }
    ]]
]=]
export type function Params(input: typeof(types.newfunction()))
    local input_tag = input.tag
    if input_tag == "union" then
        return union_from_components(components_map(input:components(), Params)) or types.never

    elseif input_tag == "intersection" then
        return intersection_from_components(components_map(input:components(), Params)) or types.never
    end

    assert_is(input, "input", input_tag, "function")

    local input_params = input:parameters()
    local input_params_head, input_params_tail = input_params.head, input_params.tail

    local output = types.newtable()

    if input_params_head then
        for idx, param in input_params_head do
            output:setproperty(types.singleton(`{idx}`), param)
        end
    end

    if input_params_tail then
        output:setproperty(types.singleton("tail"), input_params_tail)
    end

    return output
end

--[=[
    Gets the return types for a function.

    @param input (...any) -> (...any) -- The function to get return types for.

    @example
    type Result = Returns<() -> (string, number)>

    -- type Result = { 1: string, 2: number }
]=]
export type function Returns(input: typeof(types.newfunction()))
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
        for idx, param in input_returns_head do
            output:setproperty(types.singleton(`{idx}`), param)
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
    returns the inputted type but with unions, intersections and negations turned into tables so they can be inspected / debugged better.

    @param input any -- The type to be inspected.

    @example
    type Result = Inspect<"hello" | ("world" & string)>

    --[[
        type Result = {
            1: "hello",
            2: {
                1: "world",
                2: string,
                kind: "intersection"
            },
            kind: "union"
        }
    ]]
]=]
export type function Inspect(input: type)
    local input_tag = input.tag

    if input_tag == "negation" then
        return types.newtable({
            [types.singleton("1")] = Inspect(input:inner()),
            [types.singleton("kind")] = types.singleton("negation")
        })

    elseif input_tag == "table" or input_tag == "singleton" or is_primitive(input_tag) then
        return input

    else
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
end

--[=[
    Throws a type error if the first type does not equal the second.

    @param expect any -- The type to be compared.
    @param toBe any -- The type you want to compare `expect` to.

    @example
    type test = Expect<
        { foo: "bar" } & { hello: "world" },
        (string, boolean) -> ...any
    >

    --[[
        TypeError: 'Expect' type function errored at runtime: [string "Expect"]:2295: 
        Expected the function type below:
        > (string, boolean) -> (...any)

        But Got this intersection type instead:
        > {
        >     foo: "bar"
        > } & {
        >     hello: "world"
        > }
    ]]
]=]
export type function Expect(expect: type, to_be: type)
    if sort_type(expect) ~= sort_type(to_be) then
        local expect_tag, to_be_tag = expect.tag, to_be.tag

        local expect_name = if expect_tag == "singleton" then type(expect:value()) else expect_tag
        local to_be_name = if to_be_tag == "singleton" then type(to_be:value()) else to_be_tag

        local error_msg_start = `\nExpected the {to_be_name} type below:{stringify_preview(to_be)}\n\n`
        local error_msg_end = `But Got this {expect_name} type instead:{stringify_preview(expect)}`

        error(`{error_msg_start}{error_msg_end}`)
    end

    return expect
end

--[=[
    Negates a type.
    TEMPORARY: This type function will be removed once luau gets negation syntax (see `negation-types` RFC).

    @param input any -- The type to stringify.

    @example
    type Result = Negate<string>

    -- type Result = ~string
]=]
export type function Negate(input: type)
    return types.negationof(input)
end
----------------------------------------------------------------------------------------

return nil

--[[
    MIT License

    Copyright (c) 2025 Cameron P Campbell

    Permission is hereby granted, free of chparame, to any person obtaining a copy
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