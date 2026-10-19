# Create a key event

Mostly useful in tests: see
[`test_app()`](https://menshikovs.github.io/termr/reference/test_app.md)
for simulating key presses.

## Usage

``` r
key_event(key)
```

## Arguments

- key:

  Key name such as `"a"`, `"enter"`, `"ctrl+c"` or `"shift+tab"`.

## Value

A `KeyEvent`.

## Examples

``` r
key_event("ctrl+c")
#> <KeyEvent key ctrl+c>
```
