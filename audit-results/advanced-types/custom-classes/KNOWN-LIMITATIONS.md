# Known Limitations

- There is deliberately no public termr type-handler/plugin registry. Extensions use their ordinary S3, pillar and vctrs methods.
- Custom S3 and S4 classes remain read-only unless they are valid vctrs vectors with a stable, directed character-to-prototype cast. A plain `format()` or `vec_cast()` method alone does not enable editing.
- The empty cast probe checks whether the method supports the direction and prototype shape. It cannot prove the semantics of every future string; each actual value is validated again, and the class method remains responsible for its parsing contract.
- R class methods are executable package code and cannot be sandboxed. Errors and invalid results cannot mutate the DataTable value through termr's edit path, but arbitrary external side effects inside a formatter/cast method are outside termr's control.
- Classes whose `vec_restore()` changes attributes during slicing or assignment may remain viewable but read-only or may reject edits. This is safer than silently accepting data-dependent metadata changes.
- When pillar is installed, a class-specific pillar method is preferred. A failing method yields a compact safe label instead of trying the same formatter again; custom package authors should keep pillar methods total for the inputs they support.
- Custom sorting and missing filters rely on the class's standard comparison/`is.na()` behavior. Errors or invalid missing masks are handled conservatively; no class-specific sorting semantics are invented.
