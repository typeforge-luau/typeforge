--!strict

local t = require("@self")

type function set_indexer(input: typeof(types.newtable()), index: type, result: type)
    input:setindexer(index, result)
    return input
end

--> Table ---------------------------------------------------------------------------------------------
-- PickTableByKeys -----------------------------------
-- Test A: Picking 1 string literal property from a table.
type TablePick_TestA = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    { Name: string }
>

-- Test B: Picking multiple string literal properties from a table.
type TablePick_TestB = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    { Name: string, Age: number }
>

-- Test C: Picking 1 indexer component from a table.
-- HOW TO FIX: add a separate function for handling indexers in table_type_filter helper.
type TablePick_TestC = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    set_indexer<{}, "hello", any>
>

-- Test D: Picking multiple indexer components from a table.
-- HOW TO FIX: add a separate function for handling indexers in table_type_filter helper.
type TablePick_TestD = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    set_indexer<{}, "hello" | string, any>
>

-- Test E: Picking multiple indexer components and properties from a table.
-- HOW TO FIX: add a separate function for handling indexers in table_type_filter helper.
type TablePick_TestE = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    set_indexer<{ Name: string, Age: number }, "hello" | string, any>
>


-- Test F: Picking a property and indexer of the same string literal.
type TablePick_TestF = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    set_indexer<{ Age: number }, "Age", any>
>

-- Test G: Picking a property from an intersection of two tables.
type TablePick_TestG = t.Expect<
    t.PickTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello">,
    { hello: "world" } & { }
>

-- Test H: Picking 2 properties from an intersection of two tables where each component to be picked exists in a different table.
type TablePick_TestH = t.Expect<
    t.PickTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello" | "foo">,
    { hello: "world" } & { foo: "bar" }
>
------------------------------------------------------