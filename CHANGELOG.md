# v3.0.3
## Features
- `Negate` now prevents nested negations — if the input is already negated, it returns as-is.
- Added tests for `Inspect` and `Negate`.

## Fixes
- Fixed `assert_is` (now `assert_tag`): swapped error message arguments and inverted logic for multi-type checks.
- Fixed `table_flatten_with` setting a read property instead of a write property.
- Fixed `table_map_values_deep` and `table_map_values_shallow` using read indexer removal instead of write indexer removal for write indexers.
- Fixed `partial_core` checking `input.tag` instead of `value.tag` in its callback.
- Fixed `Inspect` crashing on function types by passing them through instead of calling `:components()`.
- Fixed `DeepRequired` docstring example not matching its input.

## Improvements
- Replaced `assert_is_msg` and `assert_is` with a simpler `assert_tag(input, expected)` API that computes the tag internally.
- Removed redundant `input_tag` parameter from `union_filter`, `intersection_filter`, `hashset_insert`, and `hashset_has_type`.
- Simplified redundant `value_read == value_write` branching in `ValueOf`.

# v3.0.2
## Features
- Added a `ValueOf` type function for getting all the value types of a table.

# v3.0.1
## Fixes
- Fixes issues with assertions not properly throwing an error in certain scenarios.

# v3.0.0
## Features
- Now documenting changes via a changelog.

## Fixes
- Fixed type errors.
