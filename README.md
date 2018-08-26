# doc.lua

Super simple documentation generator. It just scans the Lua source code and looks for comments of the form:
```lua
-- @tag
```
Certain tags create a new section (`class`, `function`, `module`, `table`) and other tags specify fields for that section.

All section tags take a single argument that names the section:
```lua
-- @function mod.class:method
```

The field tags are:
* `@param <name> <description text>`: Function arguments for `@function`, constructor argument for `@class`.
* `@field <name> <description text>`: Fields for `@table` and member variables for `@class`.
* `@return <description text>`: Only for `@function`.
* `@desc <text>`: Universal. Multiple `@desc` will be joined with newlines inbetween.
* `@usage <code>`: Universal. Will also be joined like `@desc`, but will be included as code in the Markdown output.
* `@see <name>`: Universal. If you want to reference multiple other sections, use multiple lines/tags.

You may also omit the tag name in which case it will simply repeat the last used tag (esp. useful for `@desc` and `@usage`)

When you have prepared your source code, simply execute `lua doc.lua source.lua doc.md` to generate the Markdown for a source file.

An full example with generated output can be found in my ECS library [naw](https://github.com/pfirsich/naw).

A smaller usage example:
```lua
-- @module foo
-- @desc Some module with things.
local foo = {}

-- @class foo.DoThingResult
-- @field values Values related to the thing that was done.
local DoThingResult = class()

-- [...]

-- @function foo.doThing
-- @desc Does the thing.
-- @param a The a parameter.
-- @param b The b parameter.
-- @return Returns `foo.DoThingResult` with the results that were calculated when the thing was done.
-- @usage local a, b = getABForThing()
-- @usage local res = foo.doThing()
-- @see foo.doThingResult
function foo.doThing(a, b)
    -- [...]
    return DoThingResult(magic)
end
```
