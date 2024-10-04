# Typeforge
20+ utility user-defined type functions for luau.

Requires the following fflags to be enabled:
```json
{
    "LuauTypeSolverRelease": "645",
    "LuauSolverV2": "true",
    "LuauUserDefinedTypeFunctionsSyntax": "true",
    "LuauUserDefinedTypeFunction": "true"
}
```


<details>
<summary>Wally Installation Instructions</summary>

1. Add typeforge to your wally dependencies.
```
Typeforge = "cameronpcampbell/typeforge@0.1.0"
```

2. Install wally dependencies.
```
wally install
```

3. Import typeforge into your project (replace `@0.1.0` with the version number you installed).
```luau
local T = require(Packages._Index["cameronpcampbell_typeforge@0.1.0"]["typeforge"])
```

</details>


- - -

# Documentation below

<details>
<summary>Boolean Operation Types</summary>

## Not
If a truthy type is inputted then it outputs `false`, and if a falsey type is inputted then it outputs `true`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union/singleton you wish to perform a `Not` operation on. |

```luau
type TypeResult = Not<true>

-- type TypeResult = false
```


## And
If all types of the union/singleton are truthy then it outputs `true`, but if at least one of the types of the union/singleton are falsely then it outputs `false`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union/singleton you wish to perform an `And` operation on. |

```luau
type TypeResult = And<true | false>

-- type TypeResult = false
```


## Or
If at least one of the types of the union/singleton are truthy then it outputs `true`, but if all of the types of the union/singleton are falsely then it outputs `false`.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The union/singleton you wish to perform an `Or` operation on. |

```luau
type TypeResult = Or<true | false>

-- type TypeResult = true
```

</details>


<details>
<summary>Table Types</summary>

## TablePick
Outputs an table with specific properties from an existing table.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to pick properties from. |
| toPick | any | A union/singeleton of keys to be picked. |

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
Outputs a copy of the input table but with specified properties omitted.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to omit properties from. |
| toPick | any | A union/singeleton of keys to be omitted. |

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


## Partial
Makes all of the properties of a table optional.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to make partial. |

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
Makes all of the properties of a table read only.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to make read only. |

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
| table | { [any]: any } | The table to make mutable. |

```luau
type TypeResult = ReadWrite<{ read hello: "world", read foo: "bar" }>

--[[
type TypeResult = {
    foo: "bar",
    hello: "world"
}
]]
```


## TableFlatten
Useful for combining an intersection of tableionaries into one table. All non-table elements of the intersection will be omitted from the output type.
NOTE: This type function is not recursive.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to flatten. |

```luau
type TypeResult = TableFlatten<{ hello: "world" } & { foo: "bar" }>

--[[
type TypeResult = {
    foo: "bar",
    hello: "world"
}
]]
```


## ValueOf
Outputs all values of a table as a union/singleton.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to get values of. |

```luau
type TypeResult = ValueOf<{ hello: "world", foo: "bar" }>
-- type TypeResult = "bar" | "world"
```


## TableToCamel
Converts all string literal keys in a table to be camel case (camelCase).
NOTE: This type function is not recursive.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to convert to camel case. |

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
NOTE: This type function is not recursive.

| Name | Type | Description |
| ---- | ---- | ----------- |
| table | { [any]: any } | The table to convert to pascal case. |

```luau
type TypeResult = TableToPascal<{ name: string, age: number }>

--[[
type TypeResult = {
    Age: number,
    Name: string
}
]]
```


## TableRemoveIndexer
Removes the indexer from a table type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| tble | { [any]: any } | The table to remove the indexer from. |

```luau
type TypeResult = TableRemoveIndexer<{ [number]: number }>

-- type TypeResult = {  }
```


## TableSetIndexer
Sets the indexer for a table type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| tble | { [any]: any } | The table to remove the indexer from. |
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


## TableAddIndexerKey
Adds a key to a tables indexer - makes the indexer a union if not already.

| Name | Type | Description |
| ---- | ---- | ----------- |
| tble | { [any]: any } | The table to set the indexer for. |
| keyType | any | The new key type to add to the indexer. |

```luau
type TypeResult = TableAddIndexerKey<{ foo: "bar", [number]: number }, string>

--[[
type TypeResult = {
    [number | string]: number,
    foo: "bar"
}
]]
```

</details>


<details>
<summary>Union Types</summary>

## UnionOmit
Outputs a copy of the input union but with specified components omitted.

| Name | Type | Description |
| ---- | ---- | ----------- |
| union | any | The union to omit properties from. |
| toOmit | any | A union/singeleton of components to be omitted. |

```luau
type TypeResult = UnionOmit<
    "hello" | string | "world",
    "world"
>

-- type TypeResult = "hello" | string
```


## UnionPick
Outputs a copy of the input union but only with specified components.

| Name | Type | Description |
| ---- | ---- | ----------- |
| union | any | The union to pick components from. |
| toPick | any | A union/singeleton of components to be picked. |

```luau
type TypeResult = UnionPick<
    "hello" | string | "world",
    "world"
>

-- type TypeResult = string | "world"
```


## UnionFlatten
Useful for combining an intersection of unions/singletons into one union.
NOTE: This type function is not recursive.

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | any | The unions/singletons to flatten. |

```luau
type TypeResult = UnionFlatten<"foo" & ("hello" | "world")>

-- type TypeResult = "foo" | "hello" | "world"
```

</details>


<details>
<summary>String Types</summary>

## StringToCamel
Converts a string to camel case (camelCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to convert to camel case. |

```luau
type TypeResult = StringToCamel<"HelloWorld">

-- type TypeResult = "helloWorld"
```


## StringToPascal
Converts a string to pascal case (PascalCase).

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to convert to pascal case. |

```luau
type TypeResult = StringToPascal<"helloWorld">

-- type TypeResult = "HelloWorld"
```


## StringToLower
Converts a string to lower case.

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to convert to lower case. |

```luau
type TypeResult = StringToLower<"helloWorld">

-- type TypeResult = "helloworld"
```


## StringToUpper
Converts a string to upper case.

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to convert to upper case. |

```luau
type TypeResult = StringToUpper<"helloWorld">

-- type TypeResult = "HELLOWORLD"
```


## StringReplace
Replaces part of a string with another string.

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to replace in. |
| replace | string | The string pattern to replace. |
| replaceWith | string | The replacement string. |

```luau
type TypeResult = StringReplace<"wolf", "f$", "ves">

-- type TypeResult = "wolves"
```

## StringIsLiteral
Returns true if the string is a string literal.

| Name | Type | Description |
| ---- | ---- | ----------- |
| str | string | The string to test to see if its a string literal. |

```luau
type TypeResult = StringIsLiteral<"Hello">

-- type TypeResult = true
```

</details>


<details>
<summary>Function Types</summary>

## Arguments
Outputs the arguments of a function.

| Name | Type | Description |
| ---- | ---- | ----------- |
| fn | (...any) -> ...any | The function to get arguments for. |

```luau
type TypeResult = Arguments<(string, number, ...boolean) -> any>

--[[
type TypeResult = {
    1: string,
    2: number,
    Tail: boolean
}
]]
```


## SetArguments
Sets the arguments for a function.

| Name | Type | Description |
| ---- | ---- | ----------- |
| fn | (...any) -> ...any | The function to set arguments for. |
| args | { [`{number}`]: any, Tail: any } | The new args for the function. |

```luau
type TypeResult = SetArguments<
    () -> (),
    { ["1"]: string, ["2"]: boolean, Tail: number }
>

-- type TypeResult = (string, boolean, ...number) -> ()
```


## Returns
Outputs the return types of a function.

| Name | Type | Description |
| ---- | ---- | ----------- |
| fn | (...any) -> ...any | The function to get return types for. |

```luau
type TypeResult = Returns<() -> (boolean, ... number)>


--[[
type TypeResult = {
    1: boolean,
    Tail: number
}
]]
```


## SetReturns
Sets the return types for a function.

| Name | Type | Description |
| ---- | ---- | ----------- |
| fn | (...any) -> ...any | The function to set return types for. |
| returns | { [`{number}`]: any, Tail: any } | The new return types for the function. |

```luau
type TypeResult = SetReturns<
    () -> (),
    { ["1"]: boolean, ["2"]: number, Tail: string }
>

-- type TypeResult = () -> (boolean, number, ...string)
```

</details>


<details>
<summary>Miscellaneous Types</summary>

## Expect
Throws a type error if the first type does not equal the second.

NOTE: This type treats all string literals inside of tables, unions and intersections as being of the same type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| expect | any | The type to be compared. |
| toBe | any | The type you want to compare `expect` to. |

```luau
type TypeResult = Expect<true, false>

-- TypeError: 'Expect' type function errored at runtime: [string "Expect"]:872: expection error!
```

</details>





