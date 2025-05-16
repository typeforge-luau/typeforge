--!strict

local t = require("@self")

type function set_indexer(input: typeof(types.newtable()), index: type, result: type)
    input:setindexer(index, result)
    return input
end

--> Core ----------------------------------------------------------------------------------------------
-- Omit -----------------------------------------------
-- Test A: Omits a union.
type Omit_TestA = t.Expect<
    t.Omit<string | number | "foo" | "bar", string>,
    number | "foo" | "bar"
>

-- Test B: Omits an intersection.
type Omit_TestB = t.Expect<
    t.Omit<string & number & "foo" & "bar", string>,
    number & "foo" & "bar"
>

-- Test C: Omits a table.
type Omit_TestC = t.Expect<
    t.Omit<{ hello: "world", foo: "bar" }, "foo">,
    { hello: "world" }
>

-- Test D: Omits a union of tables.
type Omit_TestD = t.Expect<
    t.Omit<{ hello: "world", foo: "bar" } | { lol: "kek", one: "two" }, "one" | "hello">,
    { foo: "bar" } | { lol: "kek" }
>

-- Test E: Omits an intersection of tables.
type Omit_TestE = t.Expect<
    t.Omit<{ hello: "world", foo: "bar" } & { lol: "kek", one: "two" }, "one" | "hello">,
    { foo: "bar" } & { lol: "kek" }
>
-------------------------------------------------------

-- Pick -----------------------------------------------
-- Test A: Picks a union.
type Pick_TestA = t.Expect<
    t.Pick<string | number | "foo" | "bar", string>,
    string
>

-- Test B: Picks an intersection.
type Pick_TestB = t.Expect<
    t.Pick<string & number & "foo" & "bar", string>,
    string
>

-- Test C: Picks a table.
type Pick_TestC = t.Expect<
    t.Pick<{ hello: "world", foo: "bar" }, "foo">,
    { foo: "bar" }
>

-- Test D: Picks a union of tables.
type Pick_TestD = t.Expect<
    t.Pick<{ hello: "world", foo: "bar" } | { lol: "kek", one: "two" }, "one" | "hello">,
    { hello: "world" } | { one: "two" }
>

-- Test E: Picks an intersection of tables.
type Pick_TestE = t.Expect<
    t.Pick<{ hello: "world", foo: "bar" } & { lol: "kek", one: "two" }, "one" | "hello">,
    { hello: "world" } & { one: "two" }
>
-------------------------------------------------------

-- Flatten --------------------------------------------
-- Test A: Flattens a union.
type Flatten_TestA = t.Expect<
    t.Flatten<"foo" | ("bar" | ("baz" | "lol" | "kek"))>,
    "foo" | "bar" | "baz" | "lol" | "kek"
>

-- Test B: Flattens an intersection.
type Flatten_TestB = t.Expect<
    t.Flatten<"foo" & ("bar" & ("baz" & "lol" & "kek"))>,
    "foo" & "bar" & "baz" & "lol" & "kek"
>

-- Test C: Flattens a function.
type Flatten_TestC = t.Expect<
    t.Flatten<("hello" | ("world" | "hey")) -> ()>,
    ("hello" | "world" | "hey") -> ()
>

-- Test D: Flattens a table.
type Flatten_TestD = t.Expect<
    t.Flatten<{ hello: "world" } & { foo: "bar" }>,
    { hello: "world", foo: "bar" }
>

-- Test E: Flattens a union of tables.
type Flatten_TestE = t.Expect<
    t.Flatten<{ hello: "foo" } | { world: "bar" }>,
    { hello: "foo" } | { world: "bar" }
>

-- Test F: Flattens an intersection of tables.
type Flatten_TestF = t.Expect<
    t.Flatten<{ hello: "foo" } & { world: "bar" }>,
    { hello: "foo", world: "bar" }
>
-------------------------------------------------------

-- Clean ----------------------------------------------
-- Test A: Cleans a union.
type Clean_TestA = t.Expect<
    t.Clean<"foo" | "bar" | "foo" | "kek" | "bar" | "lol" | "one">,
    "foo" | "bar" | "kek" | "lol" | "one"
>

-- Test B: Clean an intersection.
type Clean_TestB = t.Expect<
   t.Clean<"foo" & "bar" & "foo" & "kek" & "bar" & "lol" & "one">,
    "foo" & "bar" & "kek" & "lol" & "one"
>

-- Test C: Cleans a function.
type Clean_TestC = t.Expect<
    t.Clean<("foo" | "bar" | "foo" | "kek" | "bar" | "lol" | "one") -> ()>,
    ("foo" | "bar" | "kek" | "lol" | "one") -> ()
>

-- Test D: Cleans a table.
type Clean_TestD = t.Expect<
    t.Clean<{ hello: "foo" | "bar" | "foo" | "kek" | "bar" | "lol" | "one" }>,
    { hello: "foo" | "bar" | "kek" | "lol" | "one" }
>

-- Test E: Cleans a union of tables.
type Clean_TestE = t.Expect<
    t.Clean<{ hello: "foo" | "bar" | "foo" } | { foo: "kek" | "bar" | "lol" | "bar" }>,
    { hello: "foo" | "bar" } | { foo: "kek" | "bar" | "lol" }
>

-- Test F: Cleans an intersection of tables.
type Clean_TestF = t.Expect<
    t.Clean<{ hello: "foo" | "bar" | "foo" } & { foo: "kek" | "bar" | "lol" | "bar" }>,
    { hello: "foo" | "bar" } & { foo: "kek" | "bar" | "lol" }
>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------

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

-- Test F: Omits types from a negated union.
type OmitUnion_TestF = t.Expect<
    t.OmitUnion<t.Negate<string | number | "foo" | "bar">, string>,
    t.Negate<number | "foo" | "bar">
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

-- Test E: Picks an intersection of unions.
type PickUnion_TestE = t.Expect<
    t.PickUnion<("hello" | "world") & ("foo" | "bar"), "world" | "bar">,
    "world" & "bar"
>

-- Test F: Picks types from a negated union.
type PickUnion_TestF = t.Expect<
    t.PickUnion<t.Negate<string | number | "foo" | "bar">, string | "bar">,
    t.Negate<string | "bar">
>
-------------------------------------------------------

-- FlattenUnion ---------------------------------------
-- Test A: Flattens a union of unions.
type FlattenUnion_TestA = t.Expect<
    t.FlattenUnion<(string | "foo") | (number | "bar")>,
    string | "foo" | number | "bar"
>

-- Test B: Flattens a nested union.
type FlattenUnion_TestB = t.Expect<
    t.FlattenUnion<"hello" | ("lol" | ("kek" | "food"))>,
    "hello" | "lol" | "kek" | "food"
>

-- Test C: Flattens an intersection of nested unions.
type FlattenUnion_TestC = t.Expect<
    t.FlattenUnion<(string | ("foo" | "lol")) & (number | ("bar" | "world"))>,
    (string | "foo" | "lol") & (number | "bar" | "world")
>

-- Test D: Flattens a negated union.
type FlattenUnion_TestD = t.Expect<
    t.FlattenUnion<t.Negate<(string | "foo") | (number | "bar")>>,
    t.Negate<string | "foo" | number | "bar">
>

-- Test E: Flattens a union between a type and a negated type.
type FlattenUnion_TestE = t.Expect<
    t.FlattenUnion<string | "foo" | t.Negate<number | ("bar" | "baz")>>,
    string | "foo" | t.Negate<number | "bar" | "baz">
>
-------------------------------------------------------

-- CleanUnion -----------------------------------------
-- Test A: Cleans a union.
type CleanUnion_TestA = t.Expect<
    t.CleanUnion<"hello" | "hello" | "lol">,
    "hello" | "lol"
>

-- Test B: Cleans a nested union.
type CleanUnion_TestB = t.Expect<
    t.CleanUnion<"hello" | "hello" | ("lol" | ("kek" | "kek" | "food"))>,
    "hello" | ("lol" | ("kek" | "food"))
>

-- Test C: Cleans an intersection of unions.
type CleanUnion_TestC = t.Expect<
    t.CleanUnion<("hello" | "hello" | "lol") & ("bob" | "hai" | "hai")>,
    ("hello" | "lol") & ("bob" | "hai")
>

-- Test D: Cleans a negated union.
type CleanUnion_TestD = t.Expect<
    t.CleanUnion<t.Negate<(string | "foo") | (string | "bar")>>,
    t.Negate<"foo" | (string | "bar")>
>

-- Test E: Cleans a union between a type and a negated type.
type CleanUnion_TestE = t.Expect<
    t.CleanUnion<string | "foo" | t.Negate<string | ("bar" | "baz")>>,
    "foo" | t.Negate<string | ("bar" | "baz")>
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

-- Test F: Omits types from a negated intersection.
type OmitIntersection_TestF = t.Expect<
    t.OmitIntersection<t.Negate<string & number & "foo" & "bar">, string>,
    t.Negate<number & "foo" & "bar">
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

-- Test E: Picks a union of intersections.
type PickIntersection_TestE = t.Expect<
    t.PickIntersection<("hello" & "world") | ("foo" & "bar"), "world" | "bar">,
    "world" | "bar"
>

-- Test F: Picks types from a negated intersection.
type PickIntersection_TestF = t.Expect<
    t.PickIntersection<t.Negate<string & number & "foo" & "bar">, string | "bar">,
    t.Negate<string & "bar">
>
-------------------------------------------------------

-- FlattenIntersection --------------------------------
-- Test A: Flattens an intersection of intersections.
type FlattenIntersection_TestA = t.Expect<
    t.FlattenIntersection<((string & "foo") & (number & "bar"))>,
    string & "foo" & number & "bar"
>

-- Test B: Flattens a nested intersection.
type FlattenIntersection_TestB = t.Expect<
    t.FlattenIntersection<"hello" & ("lol" & ("kek" & "food"))>,
    "hello" & "lol" & "kek" & "food"
>

-- Test C: Flattens a union of nested intersections.
type FlattenIntersection_TestC = t.Expect<
    t.FlattenIntersection<(string & ("foo" & "lol")) | (number & ("bar" & "world"))>,
    (string & "foo" & "lol") | (number & "bar" & "world")
>

-- Test D: Flattens a negated intersection.
type FlattenIntersection_TestD = t.Expect<
    t.FlattenIntersection<t.Negate<(string & "foo") & (number & "bar")>>,
    t.Negate<string & "foo" & number & "bar">
>

-- Test E: Flattens an intersection between a type and a negated type.
type FlattenIntersection_TestE = t.Expect<
    t.FlattenIntersection<string & "foo" & t.Negate<number & ("bar" & "baz")>>,
    string & "foo" & t.Negate<number & "bar" & "baz">
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

-- Test C: Cleans a union of intersections.
type CleanIntersection_TestC = t.Expect<
    t.CleanIntersection<("hello" & "hello" & "lol") | ("bob" & "hai" & "hai")>,
    ("hello" & "lol") | ("bob" & "hai")
>

-- Test D: Cleans a negated intersection.
type CleanIntersection_TestD = t.Expect<
    t.CleanIntersection<t.Negate<(string & "foo") & (string & "bar")>>,
    t.Negate<"foo" & (string & "bar")>
>

-- Test E: Cleans an intersection between a type and a negated type.
type CleanIntersection_TestE = t.Expect<
    t.CleanIntersection<string & "foo" & t.Negate<string & ("bar" & "baz")>>,
    "foo" & t.Negate<string & ("bar" & "baz")>
>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------


--> Table ---------------------------------------------------------------------------------------------
-- OmitTableByKeys ------------------------------------
-- Test A: Omitting one property which has a specific string literal key from a table.
type OmitTableByKeys_TestA = t.Expect<
    t.OmitTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    { [string | "hello" | "lol"]: any, Age: number }
>

-- Test B: Omitting multiple properties which have specific string literal keys from a table.
type OmitTableByKeys_TestB = t.Expect<
    t.OmitTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    { [string | "hello" | "lol"]: any }
>

-- Test C: Omitting 1 indexer index component from a table.
type OmitTableByKeys_TestC = t.Expect<
    t.OmitTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    set_indexer<{ Name: string, Age: number }, string | "lol", any>
>

-- Test D: Omitting multiple indexer index components from a table.
type OmitTableByKeys_TestD = t.Expect<
    t.OmitTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    set_indexer<{ Name: string, Age: number }, "lol", any>
>

-- Test E: Omitting multiple indexer index components and properties from a table.
type OmitTableByKeys_TestE = t.Expect<
    t.OmitTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    set_indexer<{ }, "lol", any>
>

-- Test F: Omitting a property and indexer which both have the same string literal key / index.
type OmitTableByKeys_TestF = t.Expect<
    t.OmitTableByKeys<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    set_indexer<{ Name: string }, string | "hello" | "lol", any>
>

-- Test G: Picking a property from an intersection of tables.
type OmitTableByKeys_TestG = t.Expect<
    t.OmitTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello">,
    { } & { foo: "bar" }
>

-- Test H: Omitting two properties from an intersection of tables where each component to be picked exists in a different table.
type OmitTableByKeys_TestH = t.Expect<
    t.OmitTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello" | "foo">,
    { } & { }
>
-------------------------------------------------------

-- OmitTableByValues ----------------------------------
-- Test A: Omitting one property which has a specific primitive value from a table.
type OmitTableByValues_TestA = t.Expect<
    t.OmitTableByValues<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, string>,
    { [string | "hello" | "lol"]: any, Age: number }
>

-- Test B: Omitting multiple properties which have specific string literal value from a table.
type OmitTableByValues_TestB = t.Expect<
    t.OmitTableByValues<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, string | number>,
    { [string | "hello" | "lol"]: any }
>

-- Test C: Omitting one indexer result component from a table.
type OmitTableByValues_TestC = t.Expect<
    t.OmitTableByValues<{ [any]: string | "hello" | "lol", Name: string, Age: number }, "hello">,
    { [any]: string | "lol", Name: string, Age: number }
>

-- Test D: Omitting multiple indexer result components from a table.
type OmitTableByValues_TestD = t.Expect<
    t.OmitTableByValues<{ [any]: string | "hello" | "lol", Name: string, Age: number }, "hello" | "lol">,
    { [any]: string, Name: string, Age: number }
>

-- Test E: Omitting multiple indexer result components and properties from a table.
type OmitTableByValues_TestE = t.Expect<
    t.OmitTableByValues<{ [any]: string | "hello" | "lol", Name: string, Age: number }, "hello" | string | number>,
    { [any]: "lol" }
>

-- Test F: Omitting a property and indexer which both have the same value / result.
type OmitTableByValues_TestF = t.Expect<
    t.OmitTableByValues<{ [any]: string | "hello" | "lol" | "Age", field: "Age" }, "Age">,
    { [any]: string | "hello" | "lol" }
>

-- Test G: Omitting a property by value from an intersection of tables.
type OmitTableByValues_TestG = t.Expect<
    t.OmitTableByValues<{ hello: "world" } & { foo: "bar" }, "world">,
    { } & { foo: "bar" }
>

-- Test H: Omitting 2 properties by values from an intersection of tables where each component to be picked exists in a different table.
type OmitTableByValues_TestH = t.Expect<
    t.OmitTableByValues<{ hello: "world" } & { foo: "bar" }, "world" | "bar">,
    { } & { }
>
-------------------------------------------------------

-- PickTableByKeys ------------------------------------
-- Test A: Picking one property which has a specific string literal key from a table.
type PickTableByKeys_TestA = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    { Name: string }
>

-- Test B: Picking multiple properties which have specific string literal keys from a table.
type PickTableByKeys_TestB = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    { Name: string, Age: number }
>

-- Test C: Picking 1 indexer index component from a table.
type PickTableByKeys_TestC = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    set_indexer<{ }, "hello", any>
>

-- Test D: Picking multiple indexer index components from a table.
type PickTableByKeys_TestD = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    set_indexer<{ }, "hello" | string, any>
>

-- Test E: Picking multiple indexer index components and properties from a table.
type PickTableByKeys_TestE = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    set_indexer<{ Name: string, Age: number }, "hello" | string, any>
>

-- Test F: Picking a property and indexer which both have the same string literal key / index.
type PickTableByKeys_TestF = t.Expect<
    t.PickTableByKeys<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    set_indexer<{ Age: number }, "Age", any>
>

-- Test G: Picking a property from an intersection of tables.
type PickTableByKeys_TestG = t.Expect<
    t.PickTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello">,
    { hello: "world" } & { }
>

-- Test H: Picking 2 properties from an intersection of tables where each component to be picked exists in a different table.
type PickTableByKeys_TestH = t.Expect<
    t.PickTableByKeys<{ hello: "world" } & { foo: "bar" }, "hello" | "foo">,
    { hello: "world" } & { foo: "bar" }
>
-------------------------------------------------------

-- PickTableByValues ----------------------------------
-- Test A: Picking one property which has a specific primitive value from a table.
type PickTableByValues_TestA = t.Expect<
    t.PickTableByValues<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, string>,
    { Name: string }
>

-- Test B: Picking multiple properties which have specific string literal value from a table.
type PickTableByValues_TestB = t.Expect<
    t.PickTableByValues<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, string | number>,
    { Name: string, Age: number }
>

-- Test C: Picking 1 indexer result component from a table.
type PickTableByValues_TestC = t.Expect<
    t.PickTableByValues<{ [any]: string | "hello" | "lol", Name: string, Age: number }, "hello">,
    set_indexer<{ }, any, "hello">
>

-- Test D: Picking multiple indexer result components from a table.
type PickTableByValues_TestD = t.Expect<
    t.PickTableByValues<{ [any]: string | "hello" | "lol", Name: string, Age: number }, "hello" | "lol">,
    set_indexer<{ }, any, "hello" | "lol">
>

-- Test E: Picking multiple indexer result components and properties from a table.
type PickTableByValues_TestE = t.Expect<
    t.PickTableByValues<{ [any]: string | "hello" | "lol", Name: string, Age: number }, "hello" | string | number>,
    set_indexer<{ Name: string, Age: number }, any, "hello" | string>
>

-- Test F: Picking a property and indexer which both have the same value / result.
type PickTableByValues_TestF = t.Expect<
    t.PickTableByValues<{ [any]: string | "hello" | "lol" | "Age", field: "Age" }, "Age">,
    set_indexer<{ field: "Age" }, any, "Age">
>

-- Test G: Picking a property by value from an intersection of tables.
type PickTableByValues_TestG = t.Expect<
    t.PickTableByValues<{ hello: "world" } & { foo: "bar" }, "world">,
    { hello: "world" } & { }
>

-- Test H: Picking 2 properties by values from an intersection of tables where each component to be picked exists in a different table.
type PickTableByValues_TestH = t.Expect<
    t.PickTableByValues<{ hello: "world" } & { foo: "bar" }, "world" | "bar">,
    { hello: "world" } & { foo: "bar" }
>
-------------------------------------------------------

-- FlattenTable ---------------------------------------
-- TestA: Flattening 1 table.
type FlattenTable_TestA = t.Expect<
    t.FlattenTable<{ hello: "world", foo: "bar", baz: "bix" }>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestB: Flattening 1 table and a non-table type.
type FlattenTable_TestB = t.Expect<
    t.FlattenTable<{ hello: "world", foo: "bar", baz: "bix" } & string>,
    { hello: "world", foo: "bar", baz: "bix" } & string
>

-- TestC: Flattening 1 table with a union of non-table types.
type FlattenTable_TestC = t.Expect<
    t.FlattenTable<{ hello: "world", foo: "bar", baz: "bix" } & (string | number)>,
    ({ hello: "world", foo: "bar", baz: "bix" } & string) |
    ({ hello: "world", foo: "bar", baz: "bix" } & number)
>

-- TestD: Flattening 1 table with a nested union of non-table types.
type FlattenTable_TestD = t.Expect<
    t.FlattenTable<{ hello: "world", foo: "bar", baz: "bix" } & (string | (number | boolean))>,
    ({ hello: "world", foo: "bar", baz: "bix" } & string) |
    ({ hello: "world", foo: "bar", baz: "bix" } & number) |
    ({ hello: "world", foo: "bar", baz: "bix" } & boolean)
>

-- TestE: Flattening an intersection of multiple tables where each table has no overlap.
type FlattenTable_TestE = t.Expect<
    t.FlattenTable<{ hello: "world", foo: "bar" } & { baz: "bix" }>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestF: Flattening an intersection of multiple tables which overlap.
type FlattenTable_TestF = t.Expect<
    t.FlattenTable<{ hello: "world", foo: "bar" } & { hello: "second", baz: "bix" }>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestG: Flattening an intersection of a table and an intersection of tables.
type FlattenTable_TestG = t.Expect<
    t.FlattenTable<{ hello: "world" } & ({ foo: "bar" } & { baz: "bix" })>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestH: Flattening a union of tables with no overlap.
type FlattenTable_TestH = t.Expect<
    t.FlattenTable<{ hello: "world" } | { foo: "bar" }>,
    { hello: "world" } | { foo: "bar" }
>

-- TestI: Flattening a union of tables which overlap (should be the same as if they didn't overlap).
type FlattenTable_TestI = t.Expect<
    t.FlattenTable<{ hello: "world", foo: "bar" } | { foo: "bar" }>,
    { hello: "world", foo: "bar" } | { foo: "bar" }
>

-- TestJ: Flattening a union of an intersection of tables with one table.
type FlattenTable_TestJ = t.Expect<
    t.FlattenTable<(({ hello: "world" } & { foo: "bar" }) | { baz: "bix" })>,
    { hello: "world", foo: "bar" } | { baz: "bix" }
>

-- TestK: Flattening a union of an intersection of tables with two tables.
type FlattenTable_TestK = t.Expect<
    t.FlattenTable<(({ hello: "world" } & { foo: "bar" }) | { baz: "bix" } | { lol: "kek" })>,
    { hello: "world", foo: "bar" } | { baz: "bix" } | { lol: "kek" }
>

-- TestL: Flattening a union of an intersection of tables with nested tables.
type FlattenTable_TestL = t.Expect<
    t.FlattenTable<(({ hello: "world" } & { foo: "bar" }) | ({ baz: "bix" } | ({ lol: "kek" } | { right: "wrong" })))>,
    (({ hello: "world", foo: "bar" }) | ({ baz: "bix" } | ({ lol: "kek" } | { right: "wrong" })))
>

-- TestM: Flattening a intersection of an intersection of tables with one table.
type FlattenTable_TestM = t.Expect<
    t.FlattenTable<(({ hello: "world" } & { foo: "bar" }) & { baz: "bix" })>,
    { hello: "world", foo: "bar", baz: "bix" }
>

-- TestN: Flattening a intersection of an intersection of tables with two tables.
type FlattenTable_TestN = t.Expect<
    t.FlattenTable<(({ hello: "world" } & { foo: "bar" }) & { baz: "bix" } & { lol: "kek" })>,
    { hello: "world", foo: "bar", baz: "bix", lol: "kek" }
>

-- TestO: Flattening a intersection of an union of tables with two tables.
type FlattenTable_TestO = t.Expect<
    t.FlattenTable<(({ hello: "world" } | { foo: "bar" }) & { baz: "bix" } & { lol: "kek" })>,
    { baz: "bix", lol: "kek", hello: "world" } | { baz: "bix", lol: "kek", foo: "bar" }
>

-- TestP: Flattening a intersection of an union of a table and a non-table type with a table.
type FlattenTable_TestP = t.Expect<
    t.FlattenTable<(({ hello: "world" } | string) & { foo: "bar" })>,
    { foo: "bar", hello: "world" } | ({ foo: "bar" } & string)
>

-- TestQ: Flattening a intersection of an intersection of a table and a non-table type with a table.
type FlattenTable_TestQ = t.Expect<
    t.FlattenTable<(({ hello: "world" } & string) & { foo: "bar" })>,
    ({ hello: "world", foo: "bar" }) & string
>

-- TestR: Flattening a intersection of an union of tables with a table.
type FlattenTable_TestR = t.Expect<
    t.FlattenTable<(({ hello: "world" } | { baz: "bix" }) & { foo: "bar" })>,
    { foo: "bar", hello: "world" } | { foo: "bar", baz: "bix" }
>

-- TestS: Flattening a intersection of an intersection of tables with a table.
type FlattenTable_TestS = t.Expect<
    t.FlattenTable<(({ hello: "world" } & { baz: "bix" }) & { foo: "bar" })>,
    { hello: "world", baz: "bix", foo: "bar" }
>

-- Test T: Flattening an intersection of tables where the first one has an indexer.
type FlattenTable_TestT = t.Expect<
    t.FlattenTable<{ [string]: any } & { Name: string }>,
    { Name: string, [string]: any }
>

-- Test U: Flattening an intersection of tables where the second one has an indexer.
type FlattenTable_TestU = t.Expect<
    t.FlattenTable<{ Name: string } & { [string]: any }>,
    { Name: string, [string]: any }
>
-------------------------------------------------------

-- CleanTable -----------------------------------------
-- Test A: Cleaning a union property value.
type CleanTable_TestA = t.Expect<
    t.CleanTable<{ hello: "world" | "hey" | "hey" }>,
    { hello: "world" | "hey" }
>

-- Test B: Cleaning a union indexer index.
type CleanTable_TestB = t.Expect<
    t.CleanTable<{ ["world" | "hey" | "hey"]: any }>,
    { ["world" | "hey"]: any }
>

-- Test C: Cleaning a union indexer result.
type CleanTable_TestC = t.Expect<
    t.CleanTable<{ [any]: "world" | "hey" | "hey" }>,
    { [any]: "world" | "hey" }
>

-- Test D: Cleaning a union indexer index and result.
type CleanTable_TestD = t.Expect<
    t.CleanTable<{ ["world" | "hey" | "hey"]: "world" | "hey" | "hey" }>,
    { ["world" | "hey"]: "world" | "hey" }
>

-- Test E: Cleaning a intersection property value.
type CleanTable_TestE = t.Expect<
    t.CleanTable<{ hello: "world" & "hey" & "hey" }>,
    { hello: "world" & "hey" }
>

-- Test F: Cleaning a intersection indexer index.
type CleanTable_TestF = t.Expect<
    t.CleanTable<{ ["world" & "hey" & "hey"]: any }>,
    { ["world" & "hey"]: any }
>

-- Test G: Cleaning a intersection indexer result.
type CleanTable_TestG = t.Expect<
    t.CleanTable<{ [any]: "world" & "hey" & "hey" }>,
    { [any]: "world" & "hey" }
>

-- Test H: Cleaning a intersection indexer index and result.
type CleanTable_TestH = t.Expect<
    t.CleanTable<{ ["world" & "hey" & "hey"]: "world" & "hey" & "hey" }>,
    { ["world" & "hey"]: "world" & "hey" }
>

-- Test I: Cleaning a nested table.
type CleanTable_TestI = t.Expect<
    t.CleanTable<{
        [{
            [any]: "world" | "hey" | "hey"
        }]: {
            [any]: "world" & "hey" & "hey"
        }
    }>,
    {
        [{
            [any]: "world" | "hey"
        }]: {
            [any]: "world" & "hey"
        }
    }
>

-- Test J: Cleaning a union of tables.
type CleanTable_TestJ = t.Expect<
    t.CleanTable<{ hello: "world" & "world" & "hey" } | { foo: "bar" & "baz" & "bar" }>,
    { hello: "world" & "hey" } | { foo: "bar" & "baz" }
>

-- Test K: Cleaning an intersection of tables.
type CleanTable_TestK = t.Expect<
    t.CleanTable<{ hello: "world" & "world" & "hey" } & { foo: "bar" & "baz" & "bar" }>,
    { hello: "world" & "hey" } & { foo: "bar" & "baz" }
>

-- Test L: Cleaning a table with negated types.
type CleanTable_TestL = t.Expect<
    t.CleanTable<{
        [t.Negate<"world" & "hey" & "hey">]: t.Negate<"world" | "hey" | "hey">,
        hello: t.Negate<"world" & "world">
    }>,
    {
        [t.Negate<"world" & "hey">]: t.Negate<"world" | "hey">,
        hello: t.Negate<"world">
    }
>
-------------------------------------------------------

-- Partial --------------------------------------------
-- Test A: Makes a table partial.
type Partial_TestA = t.Expect<
    t.Partial<{ hello: "world", foo: "bar" }>,
    { hello: "world"?, foo: "bar"? }
>

-- Test B: Makes a table (whose indexer is a table) partial.
-- (index should not be affected by Partial).
type Partial_TestB = t.Expect<
    t.Partial<{ [{ hello: "world" }]: "foo" }>,
    { [{ hello: "world" }]: "foo"? }
>

-- Test C: Makes a nested table partial,
-- (nested tables should not be affected by Partial).
type Partial_TestC = t.Expect<
    t.Partial<{ [{ hello: "world" }]: { hello: "world" } }>,
    { [{ hello: "world" }]: { hello: "world" }? }
>

-- Test D: Makes a union of tables partial.
type Partial_TestD = t.Expect<
    t.Partial<{ hello: "world" } | { foo: "bar" }>,
    { hello: "world"? } | { foo: "bar"? }
>

-- Test E: Makes an intersection of tables partial.
type Partial_TestE = t.Expect<
    t.Partial<{ hello: "world" } & { foo: "bar" }>,
    { hello: "world"? } & { foo: "bar"? }
>
-------------------------------------------------------

-- Required -------------------------------------------
-- Test A: Makes a table required.
type Required_TestA = t.Expect<
    t.Required<{ hello: "world"?, foo: "bar"? }>,
    { hello: "world", foo: "bar" }
>

-- Test B: Makes a table (whose indexer is a table) required.
-- (index should not be affected by Required).
type Required_TestB = t.Expect<
    t.Required<{ [{ hello: "world"? }]: "foo"? }>,
    { [{ hello: "world"? }]: "foo" }
>

-- Test C: Makes a nested table required,
-- (nested tables should not be affected by Required).
type Required_TestC = t.Expect<
    t.Required<{ [{ hello: "world"? }]: { hello: "world"? }? }>,
    { [{ hello: "world"? }]: { hello: "world"? } }
>

-- Test D: Makes a union of tables required.
type Required_TestD = t.Expect<
    t.Required<{ hello: "world"? } | { foo: "bar"? }>,
    { hello: "world" } | { foo: "bar" }
>

-- Test E: Makes an intersection of tables required.
type Required_TestE = t.Expect<
    t.Required<{ hello: "world"? } & { foo: "bar"? }>,
    { hello: "world" } & { foo: "bar" }
>
-------------------------------------------------------

-- ReadOnly -------------------------------------------
-- Test A: Makes a table read only.
type ReadOnly_TestA = t.Expect<
    t.ReadOnly<{ hello: "world", foo: "bar" }>,
    { read hello: "world", read foo: "bar" }
>

-- Test B: Makes a table (whose indexer is a table) read only.
-- (index should not be affected by ReadOnly).
-- TODO: read only indexers aren't supported yet.
--[[type ReadOnly_TestB = t.Expect<
    t.ReadOnly<{ [{ hello: "world" }]: "foo" }>,
    { read [{ hello: "world" }]: "foo" }
>]]

-- Test C: Makes a nested table read only,
-- (nested tables should not be affected by ReadOnly).
type ReadOnly_TestC = t.Expect<
    t.ReadOnly<{ hello: { hello: "world" } }>,
    { read hello: { hello: "world" } }
>

-- Test D: Makes a union of tables read only.
type ReadOnly_TestD = t.Expect<
    t.ReadOnly<{ hello: "world" } | { foo: "bar" }>,
    { read hello: "world" } | { read foo: "bar" }
>

-- Test E: Makes an intersection of tables read only.
type ReadOnly_TestE = t.Expect<
    t.ReadOnly<{ hello: "world" } & { foo: "bar" }>,
    { read hello: "world" } & { read foo: "bar" }
>
-------------------------------------------------------

-- ReadWrite -------------------------------------------
-- Test A: Makes a table readable and writable.
type ReadWrite_TestA = t.Expect<
    t.ReadWrite<{ read hello: "world", foo: "bar" }>,
    { hello: "world", foo: "bar" }
>

-- Test B: Makes a table (whose indexer is a table) readable and writable.
-- (index should not be affected by ReadWrite).
-- TODO: read only indexers aren't supported yet.
--[[type ReadWrite_TestB = t.Expect<
    t.ReadWrite<{ read [{ hello: "world" }]: "foo" }>,
    { [{ hello: "world" }]: "foo" }
>]]

-- Test C: Makes a nested table readable and writable,
-- (nested tables should not be affected by ReadWrite).
type ReadWrite_TestC = t.Expect<
    t.ReadWrite<{ read hello: { read hello: "world" } }>,
    { hello: { read hello: "world" } }
>

-- Test D: Makes a union of tables readable and writable.
type ReadWrite_TestD = t.Expect<
    t.ReadWrite<{ read hello: "world" } | { read foo: "bar" }>,
    { hello: "world" } | { foo: "bar" }
>

-- Test E: Makes an intersection of tables readable and writable.
type ReadWrite_TestE = t.Expect<
    t.ReadWrite<{ read hello: "world" } & { read foo: "bar" }>,
    { hello: "world" } & { foo: "bar" }
>
-------------------------------------------------------
-------------------------------------------------------------------------------------------------------

--> Function ------------------------------------------------------------------------------------------
-- FlattenFunction -------------------------------------
-- Test A: Flattens an empty function.
type FlattenFunction_TestA = t.Expect<
    t.FlattenFunction<() -> ()>,
    () -> ()
>

-- Test B: Flattens a function with only parameters.
type FlattenFunction_TestB = t.Expect<
    t.FlattenFunction<("hello" | ("world" | "foo"), "foo" & ("kek" & "bar"), ...("hello" | ("world" | "hey"))) -> ()>,
    ("hello" | "world" | "foo", "foo" & "kek" & "bar", ...("hello" | "world" | "hey")) -> ()
>

-- Test C: Flattens a function with only return types.
type FlattenFunction_TestC = t.Expect<
    t.FlattenFunction<() -> ("hello" | ("world" | "foo"), "foo" & ("kek" & "bar"), ...("hello" | ("world" | "hey")))>,
    () -> ("hello" | "world" | "foo", "foo" & "kek" & "bar", ...("hello" | "world" | "hey"))
>

-- Test D: Flattens a union between two functions.
type FlattenFunction_TestD = t.Expect<
    t.FlattenFunction<("hello" | ("world" | "hey")) -> () | () -> ("hello" | ("world" | "hey"))>,
    ("hello" | "world" | "hey") -> () | () -> ("hello" | "world" | "hey")
>

-- Test E: Flattens an intersection between two functions.
type FlattenFunction_TestE = t.Expect<
    t.FlattenFunction<("hello" | ("world" | "hey")) -> () & () -> ("hello" | ("world" | "hey"))>,
    ("hello" | "world" | "hey") -> () & () -> ("hello" | "world" | "hey")
>
-------------------------------------------------------

-- CleanFunction --------------------------------------
-- Test A: Cleans an empty function.
type CleanFunction_TestA = t.Expect<
    t.CleanFunction<() -> ()>,
    () -> ()
>

-- Test B: Cleans a function with only parameters.
type CleanFunction_TestB = t.Expect<
    t.CleanFunction<("hello" | "hello" | "world", "foo" | "bar" | "foo", ...("hello" | "world" | "world")) -> ()>,
    ("hello" | "world", "foo" | "bar", ...("hello" | "world")) -> ()
>

-- Test C: Cleans a function with only return types.
type CleanFunction_TestC = t.Expect<
    t.CleanFunction<() -> ("hello" | "hello" | "world", "foo" | "bar" | "foo", ...("hello" | "world" | "world"))>,
    () -> ("hello" | "world", "foo" | "bar", ...("hello" | "world"))
>

-- Test D: Cleans a union between two functions.
type CleanFunction_TestD = t.Expect<
    t.CleanFunction<("hello" | "hello" | "world") -> () | () -> ("hello" | "hello" | "world")>,
    ("hello" | "world") -> () | () -> ("hello" | "world")
>

-- Test E: Cleans an intersection between two functions.
type CleanFunction_TestE = t.Expect<
    t.CleanFunction<("hello" | "hello" | "world") -> () & () -> ("hello" | "hello" | "world")>,
    ("hello" | "world") -> () & () -> ("hello" | "world")
>
--------------------------------------------------------

-- Params ----------------------------------------------
-- Test A: Gets parameters for an empty function.
type Params_TestA = t.Expect<
    t.Params<() -> ()>,
    {}
>

-- Test B: Gets parameters for a function.
type Params_TestB = t.Expect<
    t.Params<("hello", "world", ...number) -> ()>,
    {
        ["1"]: "hello", ["2"]: "world", tail: number
    }
>

-- Test C: Gets parameters for a union of functions.
type Params_TestC = t.Expect<
    t.Params<("hello", "world", ...number) -> () | ("foo", "bar", ...string) -> ()>,
    {
        ["1"]: "hello", ["2"]: "world", tail: number
    } | {
        ["1"]: "foo", ["2"]: "bar", tail: string
    }
>

-- Test D: Gets parameters for an intersection of functions.
type Params_TestD = t.Expect<
    t.Params<("hello", "world", ...number) -> () & ("foo", "bar", ...string) -> ()>,
    {
        ["1"]: "hello", ["2"]: "world", tail: number
    } & {
        ["1"]: "foo", ["2"]: "bar", tail: string
    }
>
--------------------------------------------------------

-- Returns ---------------------------------------------
-- Test A: Gets return types for an empty function.
type Returns_TestA = t.Expect<
    t.Returns<() -> ()>,
    {}
>

-- Test B: Gets return types for a function.
type Returns_TestB = t.Expect<
    t.Returns<() -> ("hello", "world", ...number)>,
    {
        ["1"]: "hello", ["2"]: "world", tail: number
    }
>

-- Test C: Gets return types for a union of functions.
type Returns_TestC = t.Expect<
    t.Returns<() -> ("hello", "world", ...number) | () -> ("foo", "bar", ...string)>,
    {
        ["1"]: "hello", ["2"]: "world", tail: number
    } | {
        ["1"]: "foo", ["2"]: "bar", tail: string
    }
>

-- Test D: Gets return types for an intersection of functions.
type Returns_TestD = t.Expect<
    t.Returns<() -> ("hello", "world", ...number) & () -> ("foo", "bar", ...string)>,
    {
        ["1"]: "hello", ["2"]: "world", tail: number
    } & {
        ["1"]: "foo", ["2"]: "bar", tail: string
    }
>
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------

type ThisTestWillFail = Expect<true, false>