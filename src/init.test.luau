--!strict

local t = require("@self")

type function set_indexer(input: typeof(types.newtable()), index: type, result: type)
    input:setindexer(index, result)
    return input
end

--> Union ---------------------------------------------------------------------------------------------
-- OmitUnion ------------------------------------------
-- Test A: Omits one non-literal type from a union.
type OmitUnion_TestA = t.Expect<
    t.OmitUnion<string | number | "foo" | "bar", string>,
    number | "foo" | "bar"
>

-- Test B: Omits multiple non-literal types from a union.
type OmitUnion_TestB = t.Expect<
    t.OmitUnion<string | number | "foo" | "bar", string | number>,
    "foo" | "bar"
>

-- Test C: Omits 1 literal type from a union.
type OmitUnion_TestC = t.Expect<
    t.OmitUnion<string | number | "foo" | "bar", "foo">,
    string | number | "bar"
>

-- Test D: Omits multiple literal types from a union.
type OmitUnion_TestD = t.Expect<
    t.OmitUnion<string | number | "foo" | "bar", "foo" | "bar">,
    string | number
>

-- Test E: Omits an intersection of unions.
type OmitUnion_TestE = t.Expect<
    t.OmitUnion<("hello" | "world") & ("foo" | "bar"), "world">,
    "hello" & ("foo" | "bar")
>
-------------------------------------------------------


-- PickUnion ------------------------------------------
-- Test A: Pick one non-literal type from a union.
type PickUnion_TestA = t.Expect<
    t.PickUnion<string | number | "foo" | "bar", string>,
    string
>

-- Test B: Pick multiple non-literal types from a union.
type PickUnion_TestB = t.Expect<
    t.PickUnion<string | number | "foo" | "bar", string | number>,
    string | number
>

-- Test C: Picks 1 literal type from a union.
type PickUnion_TestC = t.Expect<
    t.PickUnion<string | number | "foo" | "bar", "foo">,
    "foo"
>

-- Test D: Picks multiple literal types from a union.
type PickUnion_TestD = t.Expect<
    t.PickUnion<string | number | "foo" | "bar", "foo" | "bar">,
    "foo" | "bar"
>
-------------------------------------------------------


-- FlattenUnion ---------------------------------------
-- Test  A: Flattens a union of two unions.
type FlattenUnion_TestA = t.Expect<
    t.FlattenUnion<((string | "foo") | (number | "bar"))>,
    string | "foo" | number | "bar"
>

-- Test  B: Flattens a nested union.
type FlattenUnion_TestB = t.Expect<
    t.FlattenUnion<"hello" | ("lol" | ("kek" | "food"))>,
    "hello" | "lol" | "kek" | "food"
>
-------------------------------------------------------


-- CleanUnion -----------------------------------------
-- Test  A: Cleans a union.
type CleanUnion_TestA = t.Expect<
    t.CleanUnion<"hello" | "hello" | "lol">,
    "hello" | "lol"
>

-- Test  B: Cleans a nested union.
type CleanUnion_TestB = t.Expect<
    t.CleanUnion<"hello" | "hello" | ("lol" | ("kek" | "kek" | "food"))>,
    "hello" | ("lol" | ("kek" | "food"))
>

-- Test  C: Cleans an intersection of unions.
type CleanUnion_TestC = t.Expect<
    t.CleanUnion<("hello" | "hello" | "lol") & ("bob" | "hai" | "hai")>,
    ("hello" | "lol") & ("bob" | "hai")
>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> Intersection --------------------------------------------------------------------------------------
-- OmitIntersection -----------------------------------
-- Test A: Omits one non-literal type from an intersection.
type OmitIntersection_TestA = t.Expect<
    t.OmitIntersection<string & number & "foo" & "bar", string>,
    number & "foo" & "bar"
>

-- Test B: Omits multiple non-literal types from an intersection.
type OmitIntersection_TestB = t.Expect<
    t.OmitIntersection<string & number & "foo" & "bar", string | number>,
    "foo" & "bar"
>

-- Test C: Omits 1 literal type from an intersection.
type OmitIntersection_TestC = t.Expect<
    t.OmitIntersection<string & number & "foo" & "bar", "foo">,
    string & number & "bar"
>

-- Test D: Omits multiple literal types from an intersection.
type OmitIntersection_TestD = t.Expect<
    t.OmitIntersection<string & number & "foo" & "bar", "foo" | "bar">,
    string & number
>

-- Test E: Omits a union of intersections.
type OmitIntersection_TestE = t.Expect<
    t.OmitIntersection<("hello" & "world") | ("foo" & "bar"), "world">,
    "hello" | ("foo" & "bar")
>
-------------------------------------------------------


-- PickIntersection -----------------------------------
-- Test A: Pick one non-literal type from an intersection.
type PickIntersection_TestA = t.Expect<
    t.PickIntersection<string & number & "foo" & "bar", string>,
    string
>

-- Test B: Pick multiple non-literal types from an intersection.
type PickIntersection_TestB = t.Expect<
    t.PickIntersection<string & number & "foo" & "bar", string | number>,
    string & number
>

-- Test C: Picks 1 literal type from an intersection.
type PickIntersection_TestC = t.Expect<
    t.PickIntersection<string & number & "foo" & "bar", "foo">,
    "foo"
>

-- Test D: Picks multiple literal types from an intersection.
type PickIntersection_TestD = t.Expect<
    t.PickIntersection<string & number & "foo" & "bar", "foo" | "bar">,
    "foo"&  "bar"
>
-------------------------------------------------------


-- FlattenIntersection --------------------------------
-- Test A: Flattens an intersection of two intersections.
type FlattenIntersection_TestA = t.Expect<
    t.FlattenIntersection<((string & "foo") & (number & "bar"))>,
    string & "foo" & number & "bar"
>

-- Test B: Flattens a nested intersection.
type FlattenIntersection_TestB = t.Expect<
    t.FlattenIntersection<"hello" & ("lol" & ("kek" & "food"))>,
    "hello" & "lol" & "kek" & "food"
>
-------------------------------------------------------


-- CleanIntersection ----------------------------------
-- Test A: Cleans an intersection.
type CleanIntersection_TestA = t.Expect<
    t.CleanIntersection<"hello" & "hello" & "lol">,
    "hello" & "lol"
>

-- Test B: Cleans a nested intersection.
type CleanIntersection_TestB = t.Expect<
    t.CleanIntersection<"hello" & "hello" & ("lol" & ("kek" & "kek" & "food"))>,
    "hello" & ("lol" & ("kek" & "food"))
>

-- Test  C: Cleans a union of intersections.
type CleanCleanIntersection_TestC = t.Expect<
    t.CleanIntersection<("hello" & "hello" & "lol") | ("bob" & "hai" & "hai")>,
    ("hello" & "lol") | ("bob" & "hai")
>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------

--> Table ---------------------------------------------------------------------------------------------
-- PickTableByKeys -----------------------------------
-- Test A: Picking 1 string literal property from a table.
type PickTableByKeys_TestA = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    { Name: string }
>

-- Test B: Picking multiple string literal properties from a table.
type PickTableByKeys_TestB = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    { Name: string, Age: number }
>

-- Test C: Picking 1 indexer component from a table.
type PickTableByKeys_TestC = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    set_indexer<{}, "hello", any>
>

-- Test D: Picking multiple indexer components from a table.
type PickTableByKeys_TestD = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    set_indexer<{}, "hello" | string, any>
>

-- Test E: Picking multiple indexer components and properties from a table.
type PickTableByKeys_TestE = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    set_indexer<{ Name: string, Age: number }, "hello" | string, any>
>


-- Test F: Picking a property and indexer of the same string literal.
type PickTableByKeys_TestF = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    set_indexer<{ Age: number }, "Age", any>
>

-- Test G: Picking a property from an intersection of two tables.
type PickTableByKeys_TestG = t.Expect<
    t.PickTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello">,
    { hello: "world" } & { }
>

-- Test H: Picking 2 properties from an intersection of two tables where each component to be picked exists in a different table.
type PickTableByKeys_TestH = t.Expect<
    t.PickTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello" | "foo">,
    { hello: "world" } & { foo: "bar" }
>
------------------------------------------------------