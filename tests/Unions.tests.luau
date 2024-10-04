--!strict


local T = require(script.Parent.Parent.Typeforge)


-- UnionPicks -----------------------------------------
-- TestA: Pick one non-literal type from a union.
type UnionPick_TestA = T.Expect<
    T.UnionPick<string | number | "foo" | "bar", string>,
    string
>

-- TestB: Pick multiple non-literal types from a union.
type UnionPick_TestB = T.Expect<
    T.UnionPick<string | number | "foo" | "bar", string | number>,
    string | number
>

-- TestC: Picks 1 literal type from a union.
type UnionPick_TestC = T.Expect<
    T.UnionPick<string | number | "foo" | "bar", "foo">,
    "foo"
>

-- TestD: Picks multiple literal types from a union.
type UnionPick_TestD = T.Expect<
    T.UnionPick<string | number | "foo" | "bar", "foo" | "bar">,
    "foo" | "bar"
>
-------------------------------------------------------


-- UnionOmit ------------------------------------------
-- TestA: Omits one non-literal type from a union.
type UnionOmit_TestA = T.Expect<
    T.UnionOmit<string | number | "foo" | "bar", string>,
    number | "foo" | "bar"
>

-- TestB: Omits multiple non-literal types from a union.
type UnionOmit_TestB = T.Expect<
    T.UnionOmit<string | number | "foo" | "bar", string | number>,
    "foo" | "bar"
>

-- TestC: Omits 1 literal type from a union.
type UnionOmit_TestC = T.Expect<
    T.UnionOmit<string | number | "foo" | "bar", "foo">,
    string | number | "bar"
>

-- TestD: Omits multiple literal types from a union.
type UnionOmit_TestD = T.Expect<
    T.UnionOmit<string | number | "foo" | "bar", "foo" | "bar">,
    string | number
>
-------------------------------------------------------


-- UnionFlatten ---------------------------------------
-- TestA: Flattens a union.
-- TODO: Add an edge case to `Expect` for comparing unions as the 2 tables below throw an error despite being identical.
--[[type UnionFlatten_TestA = T.Expect<
    T.UnionFlatten<((string | "foo") & (number | "bar"))>,
    string | "foo" | number | "bar"
>]]
-------------------------------------------------------