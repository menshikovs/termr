# Optional bridge to the standalone inkr stylesheet engine. All calls go
# through exported functions so termr remains usable when inkr is absent.

inkr_call <- function(name, ...) {
  if (!requireNamespace("inkr", quietly = TRUE)) {
    stop("Install the optional package 'inkr' to use inkr stylesheets.", call. = FALSE)
  }
  getExportedValue("inkr", name)(...)
}

prepare_inkr_stylesheet <- function(sheet) {
  if (!requireNamespace("inkr", quietly = TRUE)) {
    stop("Install the optional package 'inkr' to use inkr stylesheets.", call. = FALSE)
  }
  if (inherits(sheet, "ink_compiled_stylesheet")) return(validate_inkr_stylesheet(sheet))
  if (inherits(sheet, "ink_stylesheet_ast")) {
    return(validate_inkr_stylesheet(inkr_call("ink_compile", sheet)))
  }
  if (!is.character(sheet) || length(sheet) != 1L || is.na(sheet)) {
    stop("`sheet` must be inkr stylesheet text, an existing file path, an inkr AST, or a compiled inkr stylesheet.", call. = FALSE)
  }
  if (grepl("^https?://", sheet, ignore.case = TRUE)) {
    stop("Remote inkr stylesheets are not supported; use stylesheet text or a local file.", call. = FALSE)
  }
  if (file.exists(sheet)) {
    ast <- inkr_call("ink_read", sheet)
  } else {
    # Stylesheet text may contain slashes in comments/strings. Braced input is
    # source even when it includes path-like fragments.
    looks_like_source <- grepl("[{}]", sheet)
    looks_like_path <- nzchar(trimws(sheet)) && !looks_like_source && (
      grepl("[/\\\\]", sheet) || grepl("^[A-Za-z]:", sheet) ||
        grepl("\\.[[:alnum:]]+$", sheet)
    )
    if (looks_like_path) {
      stop(sprintf("inkr stylesheet file does not exist: %s", sheet), call. = FALSE)
    }
    ast <- inkr_call("ink_parse", sheet, source = "<termr inkr stylesheet>")
  }
  validate_inkr_stylesheet(inkr_call("ink_compile", ast))
}

validate_inkr_stylesheet <- function(sheet) {
  probe <- inkr_call("ink_element", type = "TermrValidationProbe")
  inkr_call("ink_compute", sheet, probe)
  sheet
}

inkr_element_for_widget <- function(widget, states = NULL) {
  active <- states %||% widget$pseudo_states() %||% character()
  cached <- widget_cache_get(widget, "inkr_element")
  if (!is.null(cached) && identical(cached$states, active)) return(cached$element)
  parent <- widget$parent
  element <- inkr_call(
    "ink_element", type = widget$type, id = widget$id,
    classes = widget$classes, states = active,
    parent = if (!is.null(parent)) inkr_element_for_widget(parent) else NULL
  )
  widget_cache_set(widget, "inkr_element", list(states = active, element = element))
  element
}

inkr_path_key_for_widget <- function(widget, states = NULL) {
  active <- states %||% widget$pseudo_states() %||% character()
  cached <- widget_cache_get(widget, "inkr_path_key")
  if (!is.null(cached) && identical(cached$states, active)) return(cached$key)
  node <- paste(widget$type, widget$id %||% "",
    paste(widget$classes, collapse = "\035"), paste(active, collapse = "\035"), sep = "\034")
  parent <- widget$parent
  key <- if (is.null(parent)) node else paste(inkr_path_key_for_widget(parent), node, sep = "\036")
  widget_cache_set(widget, "inkr_path_key", list(states = active, key = key))
  key
}

inkr_clear_widget_caches <- function(app) {
  inkr_reset_style_cache(app)
  private <- app$.__enclos_env__$private
  screens <- if (is.null(private$.screens)) list() else private$.screens$screens()
  roots <- c(screens, if (!is.null(private$.toasts)) list(private$.toasts))
  for (root in roots) {
    for (widget in root$walk()) {
      widget_state <- widget_private(widget)
      if (is.list(widget_state$.cache)) {
        widget_state$.cache$inkr_explicit <- NULL
        widget_state$.cache$inkr_element <- NULL
        widget_state$.cache$inkr_path_key <- NULL
      }
    }
  }
  invisible()
}

inkr_reset_style_cache <- function(app) {
  private <- app$.__enclos_env__$private
  private$.inkr_cache <- new.env(hash = TRUE, parent = emptyenv())
  private$.inkr_cache_order <- character(4096L)
  private$.inkr_cache_next <- 1L
  invisible()
}

inkr_release_widget_tree <- function(widget) {
  for (node in widget$walk()) {
    private <- widget_private(node)
    if (is.list(private$.cache)) {
      private$.cache$inkr_explicit <- NULL
      private$.cache$inkr_element <- NULL
      private$.cache$inkr_path_key <- NULL
    }
  }
  invisible()
}

inkr_style_for_widget <- function(app, widget, states = widget$pseudo_states()) {
  private <- app$.__enclos_env__$private
  if (is.null(private$.inkr_stylesheet)) return(NULL)
  # These widget-local entries use the existing style epoch, so ancestor,
  # focus, class and tree changes invalidate them with computed styles.
  key <- paste(private$.inkr_generation, inkr_path_key_for_widget(widget, states), sep = "\034")
  if (exists(key, envir = private$.inkr_cache, inherits = FALSE)) {
    cached <- get(key, envir = private$.inkr_cache, inherits = FALSE)
    widget_cache_set(widget, "inkr_explicit", cached$explicit)
    return(cached$style)
  }

  computed <- inkr_call(
    "ink_compute", private$.inkr_stylesheet,
    inkr_element_for_widget(widget, states)
  )
  path <- rev(c(list(widget), widget$ancestors()))
  explicit_ancestors <- lapply(path[-length(path)], function(node) {
    flags <- widget_cache_get(node, "inkr_explicit")
    if (is.null(flags)) {
      ancestor_style <- inkr_call(
        "ink_compute", private$.inkr_stylesheet, inkr_element_for_widget(node)
      )
      flags <- inkr_explicit_flags(ancestor_style)
      widget_cache_set(node, "inkr_explicit", flags)
    }
    flags
  })
  explicit <- inkr_explicit_flags(computed)
  widget_cache_set(widget, "inkr_explicit", explicit)
  properties <- c("color", "background", "text-style", "padding", "margin", "border", "width", "height")
  props <- list()
  for (property in properties) {
    provenance <- computed$provenance[[property]]
    explicit_here <- !is.null(provenance$rule_index)
    inherited_from_rule <- identical(provenance$origin, "inherited") &&
      any(vapply(explicit_ancestors, function(flags) isTRUE(flags[[property]]), logical(1)))
    if (!explicit_here && !inherited_from_rule) next
    value <- computed$values[[property]]
    switch(property,
      color = props["foreground"] <- list(inkr_color_for_termr(value, property)),
      background = props["background"] <- list(inkr_color_for_termr(value, property)),
      `text-style` = {
        flags <- value$flags
        for (flag in c("bold", "dim", "italic", "underline", "reverse", "strike")) {
          props[flag] <- list(flag %in% flags)
        }
      },
      padding = props["padding"] <- list(unname(value$values)),
      margin = props["margin"] <- list(unname(value$values)),
      border = {
        props["border"] <- list(value$style)
        if (!is.null(value$color)) props["border_color"] <- list(inkr_color_for_termr(value$color, property))
      },
      width = props["width"] <- list(if (identical(value$kind, "auto")) "auto" else value$cells),
      height = props["height"] <- list(if (identical(value$kind, "auto")) "auto" else value$cells)
    )
  }

  adapted <- NULL
  if (length(props)) {
    transparent <- names(props)[vapply(props, is.null, logical(1))]
    non_null <- props[!vapply(props, is.null, logical(1))]
    adapted <- if (length(non_null)) do.call(style, non_null) else style()
    # Keep explicit transparent values as named NULL entries. They clear a lower
    # cascade layer while letting the framebuffer retain the surface beneath.
    for (name in transparent) adapted$props[name] <- list(NULL)
  }
  inkr_store_style_cache(private, key, list(style = adapted, explicit = explicit))
  adapted
}

inkr_signature_key <- function(generation, signature) {
  # The elements' type/id/class/state tokens are validated identifiers and
  # cannot contain these control separators. Avoid serializing and hex-encoding
  # the same short path for every widget in a wide tree.
  nodes <- vapply(signature, function(node) {
    paste(
      node$type, node$id %||% "",
      paste(node$classes, collapse = "\035"),
      paste(node$states, collapse = "\035"),
      sep = "\034"
    )
  }, character(1))
  paste(generation, paste(nodes, collapse = "\036"), sep = "\034")
}

inkr_store_style_cache <- function(private, key, value) {
  capacity <- length(private$.inkr_cache_order)
  slot <- private$.inkr_cache_next
  evicted <- private$.inkr_cache_order[[slot]]
  if (nzchar(evicted) && exists(evicted, envir = private$.inkr_cache, inherits = FALSE)) {
    rm(list = evicted, envir = private$.inkr_cache)
  }
  assign(key, value, envir = private$.inkr_cache)
  private$.inkr_cache_order[[slot]] <- key
  private$.inkr_cache_next <- if (slot >= capacity) 1L else slot + 1L
  invisible(value)
}

inkr_explicit_flags <- function(computed) {
  vapply(computed$provenance, function(origin) !is.null(origin$rule_index), logical(1))
}

inkr_color_for_termr <- function(color, property) {
  value <- format(color)
  if (grepl("^#([[:xdigit:]]{4}|[[:xdigit:]]{8})$", value)) {
    stop(sprintf(
      "inkr %s uses alpha transparency, which termr's framebuffer cannot represent; use an opaque color.",
      property
    ), call. = FALSE)
  }
  if (identical(value, "transparent")) return(NULL)
  normalize_color(value)
}
