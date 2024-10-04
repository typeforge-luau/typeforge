--!strict


local T = require(script.Parent.Parent.Typeforge)


-- StringToPascal -------------------------------------
-- TestA: Converts string literal to pascal case.
type StringToPascal_TestA = T.Expect<T.StringToPascal<"name">, "Name"> 

-- TestB: Converts invalid type to pascal case.
type StringToPascal_TestB = T.Expect<T.StringToPascal<boolean>, boolean> 
-------------------------------------------------------


-- StringToCamel --------------------------------------
-- TestA: Converts string literal to camel case.
type StringToCamel_TestA = T.Expect<T.StringToCamel<"Name">, "name"> 

-- TestB: Converts invalid type to camel case.
type StringToCamel_TestB = T.Expect<T.StringToCamel<boolean>, boolean> 
-------------------------------------------------------


-- StringToUpper --------------------------------------
-- TestA: Converts string literal to upper case.
type StringToUpper_TestA = T.Expect<T.StringToUpper<"Name">, "NAME"> 

-- TestB: Converts invalid type to upper case.
type StringToUpper_TestB = T.Expect<T.StringToUpper<boolean>, boolean> 
-------------------------------------------------------


-- StringToLower --------------------------------------
-- TestA: Converts string literal to lower case.
type StringToLower_TestA = T.Expect<T.StringToLower<"Name">, "name"> 

-- TestB: Converts invalid type to lower case.
type StringToLower_TestB = T.Expect<T.StringToLower<boolean>, boolean> 
-------------------------------------------------------


-- StringReplace --------------------------------------
-- TestA: Replaces string.
type StringReplace_TestA = T.Expect<T.StringReplace<"Wolf", "f$", "ves">, "Wolves"> 

-- TestB: Tries to replace invalid types.
type StringReplace_TestB = T.Expect<T.StringReplace<boolean, string, number>, boolean> 
-------------------------------------------------------


-- StringIsLiteral ------------------------------------
-- TestA: Tests to see if a string literal is a string literal.
type StringIsLiteral_TestA = T.Expect<T.StringIsLiteral<"Hello">, true> 

-- TestB: Tests to see if a string non-literal is a string literal.
type StringIsLiteral_TestB = T.Expect<T.StringIsLiteral<string>, false>

-- TestC: Tests to see if an invalid type is a string literal.
type StringIsLiteral_TestC = T.Expect<T.StringIsLiteral<boolean>, false> 
-------------------------------------------------------



