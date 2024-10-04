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
Typeforge = "cameronpcampbell/typeforge@0.0.0"
```

2. Install wally dependencies.
```
wally install
```

3. Import typeforge into your project (replace `@0.0.0` with the version number you installed).
```luau
local Typeforge = require(Packages._Index["cameronpcampbell_typeforge@0.0.0"]["typeforge"])
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
<summary>Dictionary Types</summary>

## DictionaryPick
Outputs an dictionary with specific properties from an existing dictionary.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to pick properties from. |
| toPick | any | A union/singeleton of keys to be picked. |

```luau
type TypeResult = DictionaryPick<{
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


## DictionaryOmit
Outputs a copy of the input dictionary but with specified properties omitted.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to omit properties from. |
| toPick | any | A union/singeleton of keys to be omitted. |

```luau
type TypeResult = DictionaryOmit<{
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
Makes all of the properties of a dictionary optional.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to make partial. |

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
Makes all of the properties of a dictionary read only.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to make read only. |

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
Makes all of the properties of a dictionary readable and writable (mutable).

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to make mutable. |

```luau
type TypeResult = ReadWrite<{ read hello: "world", read foo: "bar" }>

--[[
type TypeResult = {
    foo: "bar",
    hello: "world"
}
]]
```


## DictionaryFlatten
Useful for combining an intersection of dictionaries into one dictionary. All non-dictionary elements of the intersection will be omitted from the output type.
NOTE: This type function is not recursive.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to flatten. |

```luau
type TypeResult = DictionaryFlatten<{ hello: "world" } & { foo: "bar" }>

--[[
type TypeResult = {
    foo: "bar",
    hello: "world"
}
]]
```


## ValueOf
Outputs all values of a dictionary as a union/singleton.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to get values of. |

```luau
type TypeResult = ValueOf<{ hello: "world", foo: "bar" }>
-- type TypeResult = "bar" | "world"
```


## DictionaryToCamel
Converts all keys in a dictionary to be camel case (camelCase).
NOTE: This type function is not recursive.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to convert to camel case. |

```luau
type TypeResult = DictionaryToCamel<{ Name: string, Age: number }>

--[[
type TypeResult = {
    age: number,
    name: string
}
]]
```


## DictionaryToPascal
Converts all keys in a dictionary to be pascal case (PascalCase).
NOTE: This type function is not recursive.

| Name | Type | Description |
| ---- | ---- | ----------- |
| dict | { [any]: any } | The dictionary to convert to pascal case. |

```luau
type TypeResult = DictionaryToPascal<{ name: string, age: number }>

--[[
type TypeResult = {
    Age: number,
    Name: string
}
]]
```
</details>


<details>
<summary>Table Types</summary>

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
<summary>Miscellaneous Types</summary>

## Expect
Throws a type error if the first type does not equal the second.

NOTE: This type treats all string literals inside of tables as being of the same type.

| Name | Type | Description |
| ---- | ---- | ----------- |
| expect | any | The type to be compared. |
| toBe | any | The type you want to compare `expect` to. |

```luau
type TypeResult = Expect<true, false>

-- TypeError: 'Expect' type function errored at runtime: [string "Expect"]:872: expection error!
```

</details>





