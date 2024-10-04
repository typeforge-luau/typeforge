--!strict


local T = require(script.Parent.Parent.Typeforge)


-- Arguments ------------------------------------------
-- Test A: Function with no arguments.
type Arguments_TestA = T.Expect<
  T.Arguments<() -> any>,
  {}
>

-- Test B: Function with arguments.
type Arguments_TestB = T.Expect<
  T.Arguments<(string, number) -> any>,
  {
    ["1"]: string,
    ["2"]: number
  }
>

-- Test C: Function with arguments and a variadic tail.
type Arguments_TestC = T.Expect<
  T.Arguments<(string, number, ...boolean) -> any>,
  {
    ["1"]: string,
    ["2"]: number,
    Tail: boolean
  }
>

-- Test D: Function with only a variadic tail.
type Arguments_TestD = T.Expect<
  T.Arguments<(...boolean) -> any>,
  {
    Tail: boolean
  }
>
-------------------------------------------------------


-- SetArguments ---------------------------------------
-- Test A: Setting arguments for function with no arguments.
type SetArguments_TestA = T.Expect<
  T.SetArguments<
    () -> any,
    {
      ["1"]: string,
      ["2"]: number
    }
  >,
  (string, number) -> any
>

-- Test B: Setting arguments for function with arguments.
type SetArguments_TestB = T.Expect<
  T.SetArguments<
    (boolean, "world") -> any,
    {
      ["1"]: string,
      ["2"]: number
    }
  >,
  (string, number) -> any
>

-- Test C: Setting arguments and a variadic tail.
type SetArguments_TestC = T.Expect<
  T.SetArguments<
    () -> any,
    {
      ["1"]: string,
      ["2"]: number,
      Tail: boolean
    }
  >,
  (string, number, ...boolean) -> any
>

-- Test D: Setting only a variadic tail.
type SetArguments_TestD = T.Expect<
  T.SetArguments<
    () -> any,
    {
      Tail: number
    }
  >,
  (...number) -> any
>
-------------------------------------------------------


-- Returns --------------------------------------------
-- Test A: Function with return types.
type Returns_TestA = T.Expect<
  T.Returns<() -> (string, number)>,
  {
    ["1"]: string,
    ["2"]: number
  }
>

-- Test B: Function with return types and a variadic tail.
type Returns_TestB = T.Expect<
  T.Returns<() -> (string, number, ...boolean)>,
  {
    ["1"]: string,
    ["2"]: number,
    ["Tail"]: boolean
  }
>

-- Test C: Function with only a variadic tail.
type Returns_TestC = T.Expect<
  T.Returns<() -> ...boolean>,
  {
    ["Tail"]: boolean
  }
>
-------------------------------------------------------