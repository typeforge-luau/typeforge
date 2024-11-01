# Typeforge
90+ utility user-defined type functions for luau.

Requires the following fflags to be enabled:
```json
{
    "LuauTypeSolverRelease": "647",
    "LuauSolverV2": "true",
    "LuauUserDefinedTypeFunctionsSyntax2": "true",
    "LuauUserDefinedTypeFunction2": "true"
}
```

- - -

# Documentation below








<details>
<summary>Core Types</summary>


## Pick
Outputs the inputted type but only with specificied components/properties.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to pick components/properties from. |
| toPick | any | The union of types (or a singleton/primitive) to be picked. |

```luau
type TypeResult = Pick<"hello" & "world" & "foo" & "bar", "world" | "bar">

-- type TypeResult = "bar" & "world"
```


## Omit
Outputs the inputted type but with specificied components/properties removed.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to omit components/properties from. |
| toOmit | any | The union of types (or a singleton/primitive) to be omitted. |

```luau
type TypeResult = Omit<"hello" | "world" | "foo" | "bar", "world" | "bar">

-- type TypeResult = "foo" | "hello"
```


## Clean
Removes duplicate components from unions and intersections including inside table keys, values and indexers.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to clean. |

```luau
type TypeResult = Clean<{
    age: number | number,
    [boolean]: boolean | boolean
}>

--[[
type TypeResult = {
    [boolean]: boolean,
    age: number
}
]]
```

## Flatten
Recursively flattens intersections, unions and intersections of tables into one consolidated type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to flatten. |

```luau
type TypeResult = Flatten<({ hello: "world" } & ({ foo: "bar" } | { lol: "kek" }))>

--[[
type TypeResult = {
    foo: "bar",
    hello: "world"
} | {
    hello: "world",
    lol: "kek"
}
]]
```


## Equals
Outputs `true` if the two inputted types are identical.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first type to compare. |
| inputB | any | The second type to compare. |

```luau
type TypeResult = Equals<{ Kind: "Customer" }, { Kind: "Employee" }>

-- type TypeResult = false
```


## Overlap
Outputs the properties/components which exist in both `inputA` and `inputB`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first type. |
| inputB | any | The second type. |

```luau
type TypeResult = Overlap<"hello" & "world" & "foo", "lol" & "foo" & "world">

-- type TypeResult = "foo" & "world"
```


## Diff
Outputs the properties/components which only exist in `inputA`, and which only exist in `inputB`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first type. |
| inputB | any | The second type. |

```luau
type TypeResult = Diff<"hello" | "world", "hello" | "foo">

-- type TypeResult = "foo" | "world"
```


## ToCamel
Converts a type to camel case (camelCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to convert to camel case. |

```luau
type TypeResult = ToCamel<{ Name: string, Age: number }>

-- type TypeResult = { age: number, name: string }
```


## ToPascal
Converts a type to pascal case (PascalCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to convert to pascal case. |

```luau
type TypeResult = ToPascal<"hello" & "world">

-- type TypeResult = "Hello" & "World"
```


## ToUpper
Converts a type to upper case (UPPERCASE).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to convert to upper case. |

```luau
type TypeResult = ToUpper<"Foo" | "Bar" | "lol">

-- type TypeResult = "BAR" | "FOO" | "LOL"
```


## ToLower
Converts a type to lower case (lowercase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to convert to lower case. |

```luau
type TypeResult = ToLower<{ HELLO: "world", FOO: "BAR" }>

--[[
type TypeResult = {
    foo: "BAR",
    hello: "world"
}
]]
```


</details>








<details>
<summary>Table Types</summary>

## TablePick
Outputs the inputted table but only with specified properties.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to pick properties from. |
| toPick | any | The union of types or a singleton/primitive to be picked. |

```luau
type TypeResult = TablePick<{
    name: string,
    age: number,
    [string | number]: "fooBar"
}, "name" | string>

--[[
type TypeResult = {
    [string]: "fooBar",
    name: string
}
]]
```


## TableOmit
Outputs the inputted table but with specified properties omitted.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to omit properties from. |
| toPick | any | The union of types (or a singleton/primitive) to be omitted. |

```luau
type TypeResult = TableOmit<{
    name: string,
    age: number
}, "age">

--[[
type TypeResult = {
    name: string
}
]]
```


## TableFlatten
Flattens intersections of tables into one consolidated type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to flatten. |

```luau
type TypeResult = TableFlatten<
    { Name: string, Age: number } &
    { Kind: "Employee" }
>

--[[
type TypeResult = {
    Age: number,
    Kind: "Employee",
    Name: string
}
]]
```


## TableClean
Removes duplicate components from unions and intersections inside of table keys, values and indexers.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to clean. |

```luau
type TypeResult = TableClean<{ Name: string | string, Age: number }>

-- type TypeResult = { Age: number, Name: string }
```


## TableEquals
Outputs true if the two inputted tables are identical.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | { [any]: any } | The first table to compare. |
| inputB | { [any]: any } | The second table to compare. |

```luau
type TypeResult = TableEquals<{ Name: "Bob" }, { Name: "Bob" }>

-- type TypeResult = true
```


## TableDiff
Outputs a table of properties which only appear in inputA, and which only appear in inputB.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | { [any]: any } | The first table. |
| inputB | { [any]: any } | The second table. |

```luau
type TypeResult = TableDiff<
    { Hello: "World", Foo: "Bar" },
    { Hello: "World", Baz: "Biz" }
>

--[[
type TypeResult = {
    Baz: "Biz",
    Foo: "Bar"
}
]]
```


## TableOverlap
Outputs a table of properties which only appear in both inputA and inputB.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | { [any]: any } | The first table. |
| inputB | { [any]: any } | The second table. |

```luau
type TypeResult = TableOverlap<
    { Hello: "World", Foo: "Bar" },
    { Hello: "World", Baz: "Biz" }
>

-- type TypeResult = { Hello: "World" }
```


## Either
Returns a union of the two inputted tables, where keys of the first table are added to the second table (if not already) but with a falsy value and vice virsa.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | { [any]: any } | The first table. |
| inputB | { [any]: any } | The second table. |

```luau
type TypeResult = Either<
    { Success: true, Data: string },
    { Success: false }
>

--[[
type TypeResult = {
    Data: (false | never)?,
    Success: false
} | {
    Data: string,
    Success: true
}
]]
```


## Partial
Makes all of the properties in a table optional.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to make partial. |

```luau
type TypeResult = Partial<{ hello: "world", foo: "bar" }>

--[[
type TypeResult = {
    foo: "bar"?,
    hello: "world"?
}
]]
```


## ReadOnly
Makes all of the properties in a table read only.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to make read only. |

```luau
type TypeResult = ReadOnly<{ hello: "world", foo: "bar" }>

--[[
type TypeResult = {
    read foo: "bar",
    read hello: "world"
}
]]
```


## ReadWrite
Makes all of the properties of a table readable and writable (mutable).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to make mutable. |

```luau
type TypeResult = ReadWrite<{ read hello: "world", read foo: "bar" }>

--[[
type TypeResult = {
    foo: "bar",
    hello: "world"
}
]]
```


## ValueOf
Outputs all values of a table as a union of types (or a singleton/primitive).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to get values of. |

```luau
type TypeResult = ValueOf<{ hello: "world", foo: "bar" }>

-- type TypeResult = "bar" | "world"
```


## RemoveIndexer
Removes the indexer from a table type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| tble | { [any]: any } | The table to remove the indexer from. |

```luau
type TypeResult = TableRemoveIndexer<{  hello: "world", [number]: number }>

-- type TypeResult = { hello: "world" }
```


## SetIndexer
Sets the indexer for a table type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to set the indexer for. |
| keyType | any | The key type for the new indexer. |
| value | any | The value for the new indexer. |

```luau
type TypeResult = TableSetIndexer<{ foo: "bar", [number]: number }, string, "hello world">

--[[
type TypeResult = {
    [string]: "hello world",
    foo: "bar"
}
]]
```


## TableToCamel
Converts all string literal keys in a table to be camel case (camelCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to convert to camel case. |

```luau
type TypeResult = TableToCamel<{ Name: string, Age: number }>

--[[
type TypeResult = {
    age: number,
    name: string
}
]]
```


## TableToPascal
Converts all string literal keys in a table to be pascal case (PascalCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to convert to pascal case. |

```luau
type TypeResult = TableToPascal<{ name: string, age: number }>

--[[
type TypeResult = {
    Age: number,
    Name: string
}
]]
```


## TableToUpper
Converts all string literal keys in a table to be upper case (PascalCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to convert to upper case. |

```luau
type TypeResult = TableToUpper<{ name: string, age: number }>

--[[
type TypeResult = {
    AGE: number,
    NAME: string
}
]]
```


## TableToLower
Converts all string literal keys in a table to be lower case (lowercase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to convert to lower case. |

```luau
type TypeResult = TableToLower<{ NaMe: string, AgE: number }>

--[[
type TypeResult = {
    age: number,
    name: string
}
]]
```


## GetMetatable
Gets the metatable for a table.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to get the metatable for. |

```luau
type TypeResult = GetMetatable<SetMetatable<{ foo: "bar" }, { get: () -> string }>>

-- type TypeResult = { get: () -> string }
```


## SetMetatable
Sets the metatable for a table.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [any]: any } | The table to set the metatable for. |
| metatable | { [any]: any } | The metatable to set. |

```luau
type MyMetatable = { get: () -> string, __index: MyMetatable }
type TypeResult = SetMetatable<{ foo: "bar" }, MyMetatable>

--[[
{
    @metatable t1, 
    {
        foo: "bar"
    }
} where t1 = {
    __index: t1,
    get: () -> string
}
]]
```

</details>








<details>
<summary>Union Types</summary>


## UnionPick
Outputs the inputted union or singleton/primitive but only with specified components.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union or singleton/primitive to pick components from. |
| toPick | any | The union of types (or a singleton/primitive) to be picked. |

```luau
type TypeResult = UnionPick<
    "hello" | string | "world",
    "world"
>

-- type TypeResult = "world"
```


## UnionOmit
Outputs the inputted union or singleton/primitive but with specified components omitted.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union or singleton/primitive to omit properties from. |
| toOmit | any | The union of types (or a singleton/primitive) to be omitted. |

```luau
type TypeResult = UnionOmit<
    "hello" | string | "world",
    "world"
>

-- type TypeResult = "hello" | string
```


## UnionClean
Removes duplicate types from a union (or a singleton/primitive).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union of types (or a singleton/primitive) to be cleaned. |

```luau
type TypeResult = UnionClean<"hello" | string | "world" | string | "foo" | "hello">

-- type TypeResult = "foo" | "hello" | "world" | string
```


## UnionFlatten
Recursively flattens nested unions into one union, semantics are preserved.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union of types (or a singleton/primitive) to be flattened. |

```luau
type TypeResult = UnionFlatten<"foo" | ("hello" | ("world" | "lol"))>

-- type TypeResult = "foo" | "hello" | "lol" | "world"
```


## UnionEquals
Outputs true if the two inputted unions (or a singleton/primitive) are identical.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first union to compare. |
| inputB | any | The second union to compare. |

```luau
type TypeResult = UnionEquals<"hello" | "lol", "hello" | "kek">

-- type TypeResult = false
```


## UnionDiff
Outputs a union of components which only appear in `inputA`, and which only appear in `inputB`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first union. |
| inputB | any | The second union. |

```luau
type TypeResult = UnionDiff<"hello" | "foo", "hello" | "bar">

-- type TypeResult = "bar" | "foo"
```


## UnionOverlap
Outputs a union of components which only appear in both `inputA` and `inputB`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first union. |
| inputB | any | The second union. |

```luau
type TypeResult = UnionOverlap<"hello" | "foo", "hello" | "bar">

-- type TypeResult = "hello"
```

</details>








<details>
<summary>Intersection Types</summary>


## IntersectionPick
Outputs the inputted intersection or singleton/primitive but only with specified components.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The intersection or singleton/primitive to pick components from. |
| toPick | any | The union of types (or a singleton/primitive) to be picked. |

```luau
type TypeResult = IntersectionPick<
    "hello" & string & "world",
    "world"
>

-- type TypeResult = "world"
```


## IntersectionOmit
Outputs the inputted intersection or singleton/primitive but with specified components omitted.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The intersection or singleton/primitive to omit properties from. |
| toOmit | any | The intersection of types (or a singleton/primitive) to be omitted. |

```luau
type TypeResult = IntersectionOmit<
    "hello" & string & "world",
    "world"
>

-- type TypeResult = "hello" & string
```


## IntersectionClean
Removes duplicate types from a intersection (or a singleton/primitive).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The intersection of types (or a singleton/primitive) to be cleaned. |

```luau
type TypeResult = IntersectionClean<"hello" & string & "world" & string & "foo" & "hello">

-- type TypeResult = "foo" & "hello" & "world" & string
```


## IntersectionFlatten
Recursively flattens nested intersections into one intersection, semantics are preserved.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The intersection of types (or a singleton/primitive) to be flattened. |

```luau
type TypeResult = IntersectionFlatten<"foo" & ("hello" & ("world" & "lol"))>

-- type TypeResult = "foo" & "hello" & "lol" & "world"
```


## IntersectionEquals
Outputs true if the two inputted intersections (or a singleton/primitive) are identical.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first intersection to compare. |
| inputB | any | The second intersection to compare. |

```luau
type TypeResult = IntersectionEquals<"hello" & "lol", "hello" & "kek">

-- type TypeResult = false
```


## IntersectionDiff
Outputs an intersection of components which only appear in `inputA`, and which only appear in `inputB`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first intersection. |
| inputB | any | The second intersection. |

```luau
type TypeResult = IntersectionDiff<"hello" & "foo", "hello" & "bar">

-- type TypeResult = "bar" & "foo"
```


## IntersectionOverlap
Outputs an intersection of components which only appear in both `inputA` and `inputB`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | any | The first intersection. |
| inputB | any | The second intersection. |

```luau
type TypeResult = IntersectionOverlap<"hello" & "foo", "hello" & "bar">

-- type TypeResult = "hello"
```

</details>








<details>
<summary>Function Types</summary>


## FunctionClean
Removes duplicate types from a functions arguments and return types.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | (...any) -> ...any | The function to be cleaned. |

```luau
type TypeResult = FunctionClean<(number, string | string | boolean) -> any | any>

-- type TypeResult = (number, boolean | string) -> any
```


## FunctionFlatten
Recursively flattens the arguments and parameters of a function so that intersections, unions and intersections of tables are flattened into one consolidated type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | (...any) -> ...any | The function to be flattened. |

```luau
type TypeResult = FunctionClean<(string | (number | boolean)) -> (any & (boolean & number))>

-- type TypeResult = (boolean | number | string) -> any & boolean & number
```


## FunctionEquals
Outputs true if the two inputted functions have identical arguments and return types.

| Name | Type | Description |
| ---- | ---- | ----------- |
| inputA | (...any) -> ...any | The first function to compare. |
| inputB | (...any) -> ...any | The second function to compare. |

```luau
type TypeResult = FunctionEquals<(string) -> number, (number) -> string>

-- type TypeResult = false
```


## Args
Outputs the arguments of a function.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | (...any) -> ...any | The function to get arguments for. |

```luau
type TypeResult = Args<(number, string, boolean) -> any>

--[[
type TypeResult = {
    1: number,
    2: string,
    3: boolean
}
]]
```


## SetArgs
Sets the arguments for an existing function type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | (...any) -> ...any | The function to set arguments for. |
| args | { [`{number}`]: any, Tail: any } | The new arguments for the function. |

```luau
type MyFunction = () -> { name: string, age: number }
type TypeResult = SetArgs<MyFunction, { ["1"]: string, Tail: any }>

--[[
type TypeResult = (string, ...any) -> {
    age: number,
    name: string
}
]]
```


## Returns
Outputs the return types of a function.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | (...any) -> ...any | The function to get return types for. |

```luau
type TypeResult = Returns<() -> (string, number)>

--[[
type TypeResult = {
    1: string,
    2: number
}
]]
```


## SetReturns
Sets the return types for a function.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | (...any) -> ...any | The function to set return types for. |
| returns | { [`{number}`]: any, Tail: any } | The new return types for the function. |

```luau
type MyFunction = (string) -> boolean
type TypeResult = SetReturns<MyFunction, { ["1"]: number }>

-- type TypeResult = (string) -> number
```


## Function
Builds a function type using a table for the arguments and the return types.

| Name | Type | Description |
| ---- | ---- | ----------- |
| args | { [`{number}`]: any, Tail: any } | The arguments for the function. |
| returns | { [`{number}`]: any, Tail: any } | The new return types for the function. |

```luau
type TypeResult = Function<
    { ["1"]: string, ["2"]: number },
    { ["1"]: boolean, Tail: string }
>

-- type TypeResult = (string, number) -> (boolean, ...string)
```


</details>








<details>
<summary>String Types</summary>


## StringToCamel
Converts a string literal (or string literals within a union/intersection) to camel case (camelCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to convert to camel case. |

```luau
type TypeResult = StringToCamel<"HelloWorld">

-- type TypeResult = "helloWorld"
```


## StringToPascal
Converts a string literal (or string literals within a union/intersection) to pascal case (PascalCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to convert to pascal case. |

```luau
type TypeResult = StringToPascal<"helloWorld">

-- type TypeResult = "HelloWorld"
```


## StringToLower
Converts a string literal (or string literals within a union/intersection) to lower case (lowercase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to convert to lower case. |

```luau
type TypeResult = StringToLower<"helloWorld">

-- type TypeResult = "helloworld"
```


## StringToUpper
Converts a string literal (or string literals within a union/intersection) to upper case (UPPERCASE).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to convert to upper case. |

```luau
type TypeResult = StringToUpper<"helloWorld">

-- type TypeResult = "HELLOWORLD"
```


## StringReplace
Replaces part(s) of a string literal (or string literals within a union/intersection) with another using a pattern.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to replace in. |
| replace | string | The string pattern to replace. |
| replaceWith | string | The replacement string. |

```luau
type TypeResult = StringReplace<"wolf", "f$", "ves">

-- type TypeResult = "wolves"
```


## StringJoin
Joins a table of strings together.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | { [`{number}`]: string } | The string table to join together. |


```luau
type TypeResult = StringJoin<{ ["1"]: "Hello", ["2"]: " world!" }>

-- type TypeResult = "Hello world!"
```


## StringSplit
Splits a string literal (or string literals within a union/intersection) at every occurance of a specific string.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to split. |
| splitAt | string | The string to split at. |


```luau
type TypeResult = StringSplit<"Hello, world!", ",">

--[[
type TypeResult = {
    1: "Hello",
    2: " world!"
}
]]
```


## StringAt
Returns the character of a string at a specific index.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string table to join together. |
| at | `{number}` | The stringified position to get character at. |


```luau
type TypeResult = StringAt<"hello", "2">

-- type TypeResult = "e"
```


## StringLength
Gets the length of a string (returns as a stringified integer as luau doesn't currently support integer literals).

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to get the length of. |


```luau
type TypeResult = StringLength<"hello">

-- type TypeResult = "5"
```


## StringIsLiteral
Returns true if the string is a string literal.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | string | The string to test to see if its a string literal. |

```luau
type TypeResult = StringIsLiteral<"Hello">

-- type TypeResult = true
```


</details>








<details>
<summary>Boolean Operation Types</summary>

## Not
If a truthy type is inputted then it outputs `false`, and if a falsy type is inputted then it outputs `true`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union/singleton you wish to perform a `Not` operation on. |

```luau
type TypeResult = Not<true>

-- type TypeResult = false
```


## And
If all types of the union (or singleton/primitive) are truthy then it outputs `true`, but if at least one of the types of the (or singleton/primitive) are falsely then it outputs `false`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union/singleton you wish to perform an `And` operation on. |

```luau
type TypeResult = And<true | false>

-- type TypeResult = false
```


## Or
If at least one of the types of the union (or singleton/primitive) are truthy then it outputs `true`, but if all of the types of the union (or singleton/primitive) are falsely then it outputs `false`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union/singleton you wish to perform an `Or` operation on. |

```luau
type TypeResult = Or<true | false>

-- type TypeResult = true
```

</details>








<details>
<summary>Logical Operation Types</summary>

## Extends
Returns true if all of the input types extends at least one of the output types.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to test. |
| extends | any | The type to test if `input` extends.

```luau
type CustomerSchema = { name: string, age: number, kind: "Customer" }

type TypeResult = Extends<{ name: "Bob", age: number, kind: "Employee" }, CustomerSchema>
-- This does not extend `CustomerSchema` as `kind` is not the string literal `"Customer"`.

-- type TypeResult = false
```


## Compare
Returns true if `input` has the same type or subtype (via vanilla luau subtyping) to `compareTo`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to compare. |
| compareTo | any | The type to compare to. |

```luau
type CustomerSchema = { name: string, age: number, kind: "Customer" }

type TypeResult = Compare<{ name: "Bob", age: number, kind: "Employee" }, CustomerSchema>

-- type TypeResult = true
```


## Condition
If `input` is a truthy type then it outputs `ifTruthy`, if else then it outputs `ifFalsy`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type for the condition. |
| ifTruthy | any | The type to output if `input` is truthy. |
| ifFalsy | any | The type to output if `input` is falsy. |

```luau
type TypeResult = Condition<
    StringIsLiteral<"Bob">,
    "Is String Literal",
    "Is Not String Literal"
>

-- type TypeResult = "Is String Literal"
```


</details>








<details>
<summary>Miscellaneous Types</summary>


## Expect
Throws a type error if the first type does not equal the second.

| Name | Type | Description |
| ---- | ---- | ----------- |
| expect | any | The type to be compared. |
| toBe | any | The type you want to compare `expect` to. |

```luau
type TypeResult = Expect<true, false>

-- TypeError: 'Expect' type function errored at runtime: [string "Expect"]:872: expection error!
```


## Inspect
Returns the inputted type but with unions and intersections turned into arrays so they can be inspected better.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The type to be inspected. |

```luau
type TypeResult = Expect<true, false>

-- TypeError: 'Expect' type function errored at runtime: [string "Expect"]:872: expection error!
```

</details>