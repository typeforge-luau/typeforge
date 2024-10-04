--!strict


local T = require(script.Parent.Parent.Typeforge)


-- TablePick -----------------------------------------
-- Test A: Picking 1 string literal property from a table.
type TablePick_TestA = T.Expect<
    T.TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    { Name: string }
>

-- Test B: Picking multiple string literal properties from a table.
type TablePick_TestB = T.Expect<
    T.TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    { Name: string, Age: number }
>

-- Test C: Picking 1 indexer component from a table.
type TablePick_TestC = T.Expect<
    T.TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    T.TableSetIndexer<{}, "hello", any>
>

-- Test D: Picking multiple indexer components from a table.
type TablePick_TestD = T.Expect<
    T.TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    T.TableSetIndexer<{}, "hello" | string, any>
>

-- Test E: Picking multiple indexer components and properties from a table.
type TablePick_TestE = T.Expect<
    T.TablePick<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    T.TableSetIndexer<{ Name: string, Age: number }, "hello" | string, any>
>


-- Test F: Picking a property and indexer of the same string literal.
type TablePick_TestF = T.Expect<
    T.TablePick<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    T.TableSetIndexer<{ Age: number }, "Age", any>
>
------------------------------------------------------


-- TableOmit -----------------------------------------
-- Test A: Omitting 1 string literal property from a table.
type TableOmit_TestA = T.Expect<
    T.TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name">,
    T.TableSetIndexer<{ Age: number }, string | "hello" | "lol", any>
>

-- Test B: Omitting multiple string literal properties from a table.
type TableOmit_TestB = T.Expect<
    T.TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "Name" | "Age">,
    T.TableSetIndexer<{ }, string | "hello" | "lol", any>
>

-- Test C: Omitting 1 indexer component from a table.
type TableOmit_TestC = T.Expect<
    T.TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello">,
    T.TableSetIndexer<{ Name: string, Age: number }, string | "lol", any>
>

-- Test D: Omitting multiple indexer components from a table.
type TableOmit_TestD = T.Expect<
    T.TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string>,
    T.TableSetIndexer<{ Name: string, Age: number }, "lol", any>
>

-- Test E: Omitting multiple indexer components and properties from a table.
type TableOmit_TestE = T.Expect<
    T.TableOmit<{ [string | "hello" | "lol"]: any, Name: string, Age: number }, "hello" | string | "Name" | "Age">,
    T.TableSetIndexer<{}, "lol", any>
>

-- Test F: Picking a property and indexer of the same string literal.
type TableOmit_TestF = T.Expect<
    T.TableOmit<{ [string | "hello" | "lol" | "Age"]: any, Name: string, Age: number }, "Age">,
    T.TableSetIndexer<{ Name: string }, string | "hello" | "lol", any>
>
------------------------------------------------------


-- Partial -------------------------------------------
-- Test A: Making a table partial without an indexer partial.
type Partial_TestA = T.Expect<
    T.Partial<{ Name: string, Age: number }>,
    { Name: string?, Age: number? }
>

-- Test B: Making a table partial with an indexer partial.
type Partial_TestB = T.Expect<
    T.Partial<{ Name: string, Age: number, [string]: any }>,
    { Name: string?, Age: number?, [string]: any? }
>
------------------------------------------------------


-- ReadOnly ------------------------------------------
-- Test A: Making a table read only.
type ReadOnly_TestA = T.Expect<
    T.ReadOnly<{ Name: string, Age: number }>,
    { read Name: string, read Age: number }
>

-- Test B: Making a table with an indexer read only.
-- TODO: Once luau supports read-only indexers then uncomment the `read` statements.
type ReadOnly_TestB = T.Expect<
    T.ReadOnly<{ Name: string, Age: number, [string]: any }>,
    { read Name: string, read Age: number, --[[read]] [string]: any }
>
------------------------------------------------------


-- ReadWrite -----------------------------------------
-- Test A: Making a table read-write.
type ReadWrite_TestA = T.Expect<
    T.ReadWrite<{ Name: string, Age: number }>,
    { Name: string, Age: number }
>

-- Test B: Making a table with an indexer read-write.
-- TODO: Once luau supports read-only indexers then uncomment the `read` statements.
type ReadWrite_TestB = T.Expect<
    T.ReadWrite<{ read Name: string, read Age: number, --[[read]] [string]: any }>,
    { Name: string, Age: number, [string]: any }
>
------------------------------------------------------


-- TableFlatten --------------------------------------
-- Test A: Flattening 1 table.
type TableFlatten_TestA = T.Expect<
    T.TableFlatten<{ Name: string }>,
    { Name: string }
>

-- Test B: Flattening an intersection of 3 dictionaries.
type TableFlatten_TestB = T.Expect<
    T.TableFlatten<{ Name: string } & { Age: string } & { Id: number }>,
    { Name: string, Age: string, Id: number }
>

-- Test C: Flattening an intersection of dictionaries where 1 of them has an indexer with only one component.
type TableFlatten_TestC = T.Expect<
    T.TableFlatten<{ Name: string } & { [string]: any }>,
    { Name: string, [string]: any }
>

-- Test D: Flattening an intersection of dictionaries where 1 of them has an indexer with multiple components.
type TableFlatten_TestD = T.Expect<
    T.TableFlatten<{ Name: string } & { [string | "hello" | number | "foo"]: any }>,
    { Name: string, [string | "hello" | number | "foo"]: any }
>

-- Test E: Flattening an intersection of dictionaries where both of them have the same indexer.
type TableFlatten_TestE = T.Expect<
    T.TableFlatten<{ Name: string, [string]: number } & { [string]: number }>,
    { Name: string, [string]: number }
>

-- Test F: Flattening an intersection of dictionaries where both of them have 2 unique indexers
-- (neither of their index's contain overlapping types, and neither of their result's contain overlapping types).
-- TODO: Add an edge case to `Expect` for comparing tables as the 2 tables below throw an error despite being identical.
--[[type TableFlatten_TestF = T.Expect<
    T.TableFlatten<{ Name: string, [string | "first"]: number } & { [number | "second"]: any }>,
    { Name: string, [string | number | "first" | "second"]: number | any }
>]]

-- Test G: Flattening an intersection of dictionaries where both of them have 2 indexers which overlap.
-- TODO: Add an edge case to `Expect` for comparing tables as the 2 tables below throw an error despite being identical.
--[[type TableFlatten_TestG = T.Expect<
    T.TableFlatten<{ Name: string, [string | "first"]: number } & { [number | "second" | number]: any | number }>,
    { Name: string, [string | number | "first" | "second"]: number | any }
>]]
------------------------------------------------------


-- ValueOf -------------------------------------------
-- Test A: Gets values of a table with no literal values of different types.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestA = T.Expect<
    T.ValueOf<{ Name: string, Age: number }>,
    number | string
>]]

-- Test B: Gets values of a table with no literal values of the same type.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestB = T.Expect<
    T.ValueOf<{ Name: string, Age: string }>,
    string
>]]

-- Test C: Gets values of a table with literal values.
type ValueOf_TestC = T.Expect<
    T.ValueOf<{ Name: "Bob", Age: "54" }>,
    "54" | "Bob"
>

-- Test D: Gets values of a table with indexer with no literal values.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestD = T.Expect<
    T.ValueOf<{ Name: string, Age: number, [string]: boolean }>,
    string | number | boolean
>]]

-- Test E: Gets values of a table with indexer with literal values.
type ValueOf_TestE = T.Expect<
    T.ValueOf<{ Name: "Bob", Age: "54", [string]: "false" }>,
    "54" | "Bob" | "false"
>

-- Test F: Gets values of a table with indexer - a mix of literal and none-literal values.
-- TODO: Add an edge case to `Expect` for comparing unions with none-literal components as the
-- 2 unions below throw an error despite being identical.
--[[type ValueOf_TestF = T.Expect<
    T.ValueOf<{ Name: "Bob", Age: number, [string]: "false" }>,
    "Bob" | "false" | number
>]]
------------------------------------------------------


-- TableToCamel --------------------------------------
-- Test A: Converts a table with no indexer to camel case.
type TableToCamel_TestA = T.Expect<
    T.TableToCamel<{ Name: string, Age: number }>,
    { name: string, age: number }
>

-- Test B: Converts a table with a string non-literal indexer to camel case.
type TableToCamel_TestB = T.Expect<
    T.TableToCamel<{ Name: string, Age: number, [string]: number }>,
    { name: string, age: number, [string]: number }
>

-- Test C: Converts a table with a string literal indexer to camel case.
type TableToCamel_TestC = T.Expect<
    T.TableToCamel<{ Name: string, Age: number, [string | "Id"]: number }>,
    { name: string, age: number, [string | "id"]: number }
>
------------------------------------------------------


-- TableToPascal -------------------------------------
-- Test A: Converts a table with no indexer to pascal case.
type TableToPascal_TestA = T.Expect<
    T.TableToPascal<{ name: string, age: number }>,
    { Name: string, Age: number }
>

-- Test B: Converts a table with a string non-literal indexer to pascal case.
type TableToPascal_TestB = T.Expect<
    T.TableToPascal<{ name: string, age: number, [string]: number }>,
    { Name: string, Age: number, [string]: number }
>

-- Test C: Converts a table with a string literal indexer to pascal case.
type TableToPascal_TestC = T.Expect<
    T.TableToPascal<{ name: string, age: number, [string | "id"]: number }>,
    { Name: string, Age: number, [string | "Id"]: number }
>
------------------------------------------------------


-- TableRemoveIndexer --------------------------------
-- TestA: Removes indexer from table.
type TableRemoveIndexer_TestA = T.Expect<T.TableRemoveIndexer<{ [string]: number }>, {}>
------------------------------------------------------


-- TableSetIndexer -----------------------------------
-- TestA: Sets indexer for a table.
type TableSetIndexer_TestA = T.Expect<T.TableSetIndexer<{ }, string, number>, { [string]: number }>
------------------------------------------------------


-- TableAddIndexerKey --------------------------------
-- TestA: Adds a key to the indexer of an empty table.
type TableAddIndexerKey_TestA = T.Expect<T.TableAddIndexerKey<{ }, string>, { [string]: nil }>


-- TestB: Adds a key to the existing indexer of a table.
-- TODO: Add an edge case to `Expect` for comparing tables as the 2 tables below throw an error despite being identical.
--type TableAddIndexerKey_TestB = T.Expect<T.TableAddIndexerKey<{ [number]: boolean }, string>, { [string | number]: boolean }>
------------------------------------------------------