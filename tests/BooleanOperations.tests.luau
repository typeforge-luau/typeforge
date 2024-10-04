--!strict


local T = require(script.Parent.Parent.Typeforge)


-- Not -----------------------------------------------
-- Test A: A Not operation of `true`.
type Not_TestA = T.Expect<T.Not<true>, false>

-- Test B: A Not operation of a truthy literal.
type Not_TestB = T.Expect<T.Not<"i am a truthy literal">, false>

-- Test C: A Not operation of `true` and `false`.
type Not_TestC = T.Expect<T.Not<true | false>, false | true>

-- Test D: A Not operation of `false` and a truthy literal.
type Not_TestD = T.Expect<T.Not<false | "i am a truthy literal">, true | false>
------------------------------------------------------


-- And -----------------------------------------------
-- Test A: An And Operation of `true` and `true`.
type And_TestA = T.Expect<T.And<true | true>, true>

-- Test B: An And Operation of `true` and a truthy string literal.
type And_TestB = T.Expect<T.And<true | "i am a truthy literal">, true>

-- Test C: An And Operation of 2 truthy string literal.
type And_TestC = T.Expect<T.And<"i am a truthy literal" | "i am a truthy literal">, true>

-- Test D: An And Operation of `false` and `false`.
type And_TestD = T.Expect<T.And<false | false>, false>

-- Test E: An And Operation of `true` and `false`.
type And_TestE = T.Expect<T.And<true | false>, false>

-- Test F: An And Operation of `false` and a truthy string literal.
type And_TestF = T.Expect<T.And<false | "i am a truthy literal">, false>

-- Test G: An And Operation of `true`.
type And_TestG = T.Expect<T.And<true>, true>

-- Test H: An And Operation of `false`.
type And_TestH = T.Expect<T.And<false>, false>

-- Test I: An And Operation of a truthy string literal.
type And_TestI = T.Expect<T.And<"i am a truthy literal">, true>
------------------------------------------------------


-- Or ------------------------------------------------
-- Test A: An Or Operation of `true` and `true`.
type Or_TestA = T.Expect<T.Or<true | true>, true>

-- Test B: An Or Operation of `true` and a truthy string literal.
type Or_TestB = T.Expect<T.Or<true | "i am a truthy literal">, true>

-- Test C: An Or Operation of 2 truthy string literal.
type Or_TestC = T.Expect<T.Or<"i am a truthy literal" | "i am a truthy literal">, true>

-- Test D: An Or Operation of `false` and `false`.
type Or_TestD = T.Expect<T.Or<false | false>, false>

-- Test E: An Or Operation of `true` and `false`.
type Or_TestE = T.Expect<T.Or<true | false>, true>

-- Test F: An Or Operation of `false` and a truthy string literal.
type Or_TestF = T.Expect<T.Or<false | "i am a truthy literal">, true>

-- Test G: An Or Operation of `true`.
type Or_TestG = T.Expect<T.Or<true>, true>

-- Test H: An Or Operation of `false`.
type Or_TestH = T.Expect<T.Or<false>, false>

-- Test I: An Or Operation of a truthy string literal.
type Or_TestI = T.Expect<T.Or<"i am a truthy literal">, true>
------------------------------------------------------