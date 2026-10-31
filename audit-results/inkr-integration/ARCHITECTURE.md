# Architecture

The inkr bridge is an adapter at termr's existing `Widget$computed_style()`
hook. It does not add a renderer, layout engine, framebuffer path, native code
or a second stylesheet parser.

```text
widget tree -> termr default styles -> RTCSS -> inkr computed properties
            -> inline style -> inline state style -> resolve_style()
            -> termr strong-focus / monochrome border treatment
            -> layout -> paint -> ScreenBuffer -> ANSI renderer
```

The bridge compiles a source string, local file or public inkr AST before
replacing the active sheet. It accepts public compiled stylesheet objects.
For a cache miss, it builds an `ink_element` parent path from widget type, id,
classes, pseudo states and parents, then calls `ink_compute()`. It maps only
properties with explicit provenance or inherited values whose ancestor path
contains an explicit declaration. Registry defaults therefore do not blanket
termr defaults or themes.

`ink_explain()` backs both `App$explain_inkr_style()` and the inkr section of
`inspect_widget()`. Style resolution remains data-only; all painting and
terminal color capability handling stay in termr.
