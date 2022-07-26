# JsonToCG4

A small sample project that shows how to use the [CodeGen4](https://github.com/remobjects/CodeGen4) library. 

Not intended for real-life use as is but more of a test case for CG4, the sample shows how to process a template `.json` file to generate code that can then, in theory, be used to load and access any `.json` file matching the same format, and access its content in a strongly-typed way.

The code uses [Elements RTL](https://github.com/remobjects/rtl2)'s `JsonDocument` class to load a provided `.json` file, and then generates CodeGen4 type definitions and infrastructre to represent gthe structir elof that file. From the generated CG4 model, source code can be negerats for any language. 

For convenience, the generated code for the provided json.json` test-case is already included as part of the oprject as well (in `Test.pas`), along with dummy code in `Main()` to exercise it.
