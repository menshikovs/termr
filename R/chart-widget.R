# The only integration layer that depends on Widget's documented subclass
# contract. It uses the public mount(), arrange_children(), child_clip(),
# paint(), render_lines(), invalidate(), on_key(), on_click(), focus() and
# post_message() methods and the documented MouseEvent fields.
# All drawing is done by plans (R/plan.R); the widget supplies the content
# size, caches the composed cells, and routes keys.
#
# Selection-only repaint (docs/selection-repaint.md). termr repaints the
# region of whatever widget asks for it, and a leaf widget's region is the
# whole chart. A ChartWidget therefore owns one empty child, the
# SelectionRegion, that is laid out over exactly the cells the selection
# changes. Moving the selection invalidates that child only, so termr's dirty
# rectangles are the child's old and new regions. The chart itself paints just
# the part of its cells that lies inside the `area` termr hands to paint(), so
# a cursor move re-emits a few segments instead of the whole frame. The child
# draws nothing: all cells always come from the chart, so no overlay
# transparency is involved.

# Draws nothing. Its region marks where the selection currently is.
SelectionRegion <- R6::R6Class(
  "SelectionRegion",
  inherit = Widget,
  public = list(
    initialize = function() {
      super$initialize(style = chart_style(width = 1, height = 1))
      self$focusable <- FALSE
    },
    render_lines = function(width = NA_integer_) list()
  )
)

ChartWidget <- R6::R6Class(
  "ChartWidget",
  inherit = Widget,
  public = list(
    initialize = function(spec, id = NULL, classes = NULL, style = NULL,
                          interactive = TRUE) {
      private$.spec <- spec
      private$.interactive <- interactive
      private$.selected <- if (interactive) chart_initial_selection(spec) else NA_integer_
      private$.paint_size <- NULL
      default <- chart_style(width = "1fr", height = "1fr", wrap = "none")
      super$initialize(id = id, classes = classes, style = style %||% default)
      self$focusable <- interactive
      private$.region <- SelectionRegion$new()
      self$mount(private$.region)
    },
    # Replace the data in this chart widget and repaint it in place. The
    # required argument names depend on the chart type: x/y, labels/values,
    # x, or z. Constructor options remain in effect.
    update_data = function(...) {
      updated <- replace_chart_data(private$.spec, list(...))
      private$.spec <- updated
      private$.selected <- if (private$.interactive) chart_initial_selection(updated) else NA_integer_
      private$clear_cache()
      private$.region$invalidate()
      self$invalidate()
      invisible(self)
    },
    # Subscribe a line/scatter chart to a local or remote termr stream. The
    # stream retains its own history; this widget keeps only its bounded view.
    bind_stream = function(stream, x, y, max_points = 600L) {
      if (!private$.spec$type %in% c("line", "scatter")) {
        stop("`bind_stream()` is supported for line and scatter charts.", call. = FALSE)
      }
      if (!is.list(stream) || !is.function(stream$history) ||
          !is.function(stream$subscribe) || !is.function(stream$is_closed)) {
        stop("`stream` must provide history(), subscribe(), and is_closed().", call. = FALSE)
      }
      check_function(x, "x")
      check_function(y, "y")
      max_points <- stream_point_limit(max_points)
      if (!identical(stream$is_closed(), FALSE)) stop("`stream` must be open.", call. = FALSE)

      events <- stream$history()
      if (!is.list(events)) stop("`stream$history()` must return a list.", call. = FALSE)
      history <- chart_stream_collect(utils::tail(events, max_points), x, y, max_points,
                                      private$.spec$data$x[integer()],
                                      private$.spec$data$y[integer()])
      updated <- replace_chart_data(private$.spec, list(x = history$x, y = history$y))

      # termr streams do not replay in subscribe(); history was snapshotted
      # above and subsequent events arrive in registration order.
      state <- new.env(parent = emptyenv())
      state$x <- history$x
      state$y <- history$y
      state$source_id <- history$source_id
      state$sequence <- history$sequence
      state$active <- TRUE
      state$flush_scheduled <- FALSE
      state$pending_render <- FALSE
      state$next_publish <- -Inf
      state$flush_count <- 0L
      state$queue <- chart_stream_queue_new(max_points)
      callback <- function(event) private$consume_stream_event(event, x, y, max_points, state)
      subscription <- stream$subscribe(callback)
      if (!is.list(subscription) || !is.function(subscription$unsubscribe)) {
        stop("`stream$subscribe()` must return a handle with unsubscribe().", call. = FALSE)
      }
      subscribed <- FALSE
      on.exit(if (!subscribed) try(subscription$unsubscribe(), silent = TRUE), add = TRUE)

      previous <- private$.stream_subscription
      if (!is.null(previous)) private$clear_stream_binding()
      private$.spec <- updated
      private$.selected <- if (private$.interactive) chart_initial_selection(updated) else NA_integer_
      private$clear_cache()
      private$.region$invalidate()
      self$invalidate()
      private$.stream_source <- stream
      private$.stream_subscription <- subscription
      private$.stream_state <- state
      private$.stream_error <- NULL
      private$register_stream_cleanup()
      subscribed <- TRUE
      invisible(self)
    },
    # Stop following the current source and leave the chart's last data in
    # place. The stream itself remains open for its other subscribers.
    unbind_stream = function() {
      private$clear_stream_binding()
      invisible(self)
    },
    # App shutdown walks mounted widgets and calls this documented lifecycle
    # hook before releasing its driver. Chart-owned stream callbacks are not
    # app bindings, so release them here as well as on ordinary unmount.
    on_app_shutdown = function() {
      private$clear_stream_binding()
      invisible(self)
    },
    render = function() span(fallback_label(private$.spec)),
    # Lines of the whole frame, or (during paint) of the part of it termr is
    # repainting. Rows outside that part are empty.
    render_lines = function(width = NA_integer_) {
      if (!is.null(private$.pending)) return(private$.pending)
      size <- private$.paint_size
      if (is.null(size)) {
        # Layout measurement should not scan a potentially million-row source.
        return(list(list()))
      }
      private$full_lines(size)
    },
    arrange_children = function(children, inner, st) {
      # The content size is known here, before any paint: plan the chart and
      # place the (empty) selection child over the cells the selection changes.
      size <- c(max(0L, as.integer(inner$width)), max(0L, as.integer(inner$height)))
      private$.paint_size <- size
      private$.origin <- c(as.integer(inner$x), as.integer(inner$y))
      box <- private$selection_box(size)
      r <- inner
      if (is.null(box)) {
        r$width <- 0L; r$height <- 0L
      } else {
        r$x <- inner$x + box[["col"]] - 1L; r$y <- inner$y + box[["row"]] - 1L
        r$width <- box[["cols"]]; r$height <- box[["rows"]]
      }
      rep(list(r), length(children))
    },
    paint = function(buffer, area, st) {
      # child_clip() is documented to return the content clip for this paint.
      inner <- self$child_clip(st)
      size <- c(max(0L, as.integer(inner$width)), max(0L, as.integer(inner$height)))
      private$.paint_size <- size
      private$.pending <- private$area_lines(size, inner, area)
      on.exit(private$.pending <- NULL, add = TRUE)
      super$paint(buffer, area, st)
    },
    on_key = function(event) {
      if (!private$.interactive || anyNA(private$.selected)) return(invisible(FALSE))
      size <- private$.paint_size
      if (is.null(size)) size <- c(80L, 24L)
      plan <- private$ensure_plan(size)
      key <- event$key
      old <- private$.selected
      if (key == "enter") {
        payload <- private$payload(old, plan)
        self$post_message(chart_event_name(private$.spec, "selected"), payload)
        self$post_message(chart_event_name(private$.spec, "activated"), payload)
        event$stop()
        return(invisible(TRUE))
      }
      if (is.null(plan$nav)) return(invisible(FALSE))
      new <- plan$nav(key, old)
      if (is.null(new)) return(invisible(FALSE))
      private$select(new, plan)
      event$stop()
      invisible(TRUE)
    },
    # A left click selects the item drawn under the pointer through the same
    # path as the keyboard. On a different item the cursor moves and
    # `cursor_changed` is posted (nothing else). A click on the item that is
    # already current posts `selected`, so the mouse alone can select;
    # `activated` stays with Enter, which still posts `selected` then
    # `activated`. A click that resolves to no item (axes, labels, margins,
    # empty space) changes nothing, posts nothing and does not move focus. The
    # click's screen position is converted to a content cell with the origin
    # recorded at layout time, so it is correct whether the target was the
    # chart or the empty selection child laid over it.
    on_click = function(event) {
      if (!private$.interactive || !identical(event$button, "left")) return(invisible(FALSE))
      size <- private$.paint_size
      origin <- private$.origin
      if (is.null(size) || is.null(origin) || anyNA(private$.selected)) return(invisible(FALSE))
      plan <- private$ensure_plan(size)
      event$stop()
      if (is.null(plan$hit)) return(invisible(TRUE))
      row <- as.integer(event$screen_y) - origin[[2L]] + 1L
      col <- as.integer(event$screen_x) - origin[[1L]] + 1L
      if (row < 1L || col < 1L || row > size[[2L]] || col > size[[1L]]) return(invisible(TRUE))
      new <- plan$hit(row, col, private$.selected)
      if (is.null(new)) return(invisible(TRUE))
      if (!isTRUE(self$focused)) self$focus()
      if (!private$select(new, plan)) {
        self$post_message(chart_event_name(private$.spec, "selected"),
                          private$payload(private$.selected, plan))
      }
      invisible(TRUE)
    }
  ),
  active = list(
    selected_index = function(value) {
      if (!missing(value)) stop("`selected_index` is read-only.", call. = FALSE)
      private$.selected
    },
    stream_error = function(value) {
      if (!missing(value)) stop("`stream_error` is read-only.", call. = FALSE)
      private$.stream_error
    }
  ),
  private = list(
    .spec = NULL, .interactive = FALSE, .selected = NA_integer_,
    .paint_size = NULL, .plan = NULL, .plan_size = NULL, .region = NULL,
    .pending = NULL, .origin = NULL,
    .stream_source = NULL, .stream_subscription = NULL, .stream_state = NULL,
    .stream_error = NULL, .stream_cleanup_registered = FALSE,
    .none_cells = NULL,                       # cells with nothing selected
    .cells = NULL, .cells_key = NULL,         # cells for the current selection
    .lines = NULL, .lines_key = NULL,         # whole-frame lines
    # The one selection-update path (keys and clicks): move the cursor and, if
    # it moved, repaint only the selection child and announce the new item.
    select = function(new, plan) {
      old <- private$.selected
      if (identical(unname(as.integer(new)), unname(as.integer(old)))) return(invisible(FALSE))
      private$.selected <- new
      # Re-lay out the selection child (its region moves) and repaint it:
      # termr repaints its old and new region, not the whole chart.
      private$.region$invalidate()
      self$post_message(chart_event_name(private$.spec, "cursor_changed"),
                        private$payload(new, plan))
      invisible(TRUE)
    },
    # The plan for a size is rebuilt only when the size changes.
    ensure_plan = function(size) {
      if (is.null(private$.plan) || !identical(private$.plan_size, size)) {
        private$clear_cache()
        private$.plan <- chart_plan(private$.spec, size[[1L]], size[[2L]])
        private$.plan_size <- size
      }
      private$.plan
    },
    clear_cache = function() {
      private$.plan <- NULL; private$.plan_size <- NULL
      private$.none_cells <- NULL
      private$.cells <- NULL; private$.cells_key <- NULL
      private$.lines <- NULL; private$.lines_key <- NULL
      invisible(NULL)
    },
    # Composed cells for the current selection; the selection stamp is the
    # only thing recomputed when the selection changes.
    selection_cells = function(size) {
      plan <- private$ensure_plan(size)
      key <- private$.selected
      if (is.null(private$.cells) || !identical(private$.cells_key, key)) {
        private$.cells <- plan_cells(plan, key)
        private$.cells_key <- key
      }
      private$.cells
    },
    # Cells where the current selection differs from no selection, as
    # c(row, col, rows, cols) in content coordinates; NULL when none differ.
    selection_box = function(size) {
      if (!private$.interactive || anyNA(private$.selected) || any(size == 0L)) return(NULL)
      plan <- private$ensure_plan(size)
      if (is.null(private$.none_cells)) private$.none_cells <- plan_cells(plan, NA_integer_)
      cells_diff_box(private$.none_cells, private$selection_cells(size))
    },
    full_lines = function(size) {
      key <- list(size, private$.selected)
      if (!identical(key, private$.lines_key)) {
        plan <- private$ensure_plan(size)
        cells <- private$selection_cells(size)
        private$.lines <- if (plan$W == 0L || plan$H == 0L) list() else compact_lines(cells$glyph, cells$mark)
        private$.lines_key <- key
      }
      private$.lines
    },
    # Lines for the cells of `area` (screen coordinates); other rows are empty
    # and the columns left of the area are one blank spacer segment.
    area_lines = function(size, inner, area) {
      plan <- private$ensure_plan(size)
      if (plan$W == 0L || plan$H == 0L) return(list())
      r0 <- max(1L, area$y - inner$y + 1L)
      r1 <- min(size[[2L]], area$y + area$height - inner$y)
      c0 <- max(1L, area$x - inner$x + 1L)
      c1 <- min(size[[1L]], area$x + area$width - inner$x)
      if (r0 > r1 || c0 > c1) return(list())
      if (r0 == 1L && r1 == size[[2L]] && c0 == 1L && c1 == size[[1L]]) {
        return(private$full_lines(size))
      }
      cells <- private$selection_cells(size)
      rows <- r0:r1
      part <- compact_lines(cells$glyph, cells$mark, rows = rows, cols = c(c0, c1))
      if (c0 > 1L) {
        spacer <- segment_template(0L)
        spacer$text <- strrep(" ", c0 - 1L)
        part <- lapply(part, function(line) c(list(spacer), line))
      }
      out <- vector("list", r1)
      for (i in seq_len(r1)) out[[i]] <- list()
      out[rows] <- part
      out
    },
    payload = function(id, plan) chart_event_payload(private$.spec, id, plan),
    consume_stream_event = function(event, x, y, max_points, state) {
      if (!isTRUE(state$active)) return(invisible(NULL))
      app <- self$app
      if (!is.null(app)) {
        chart_stream_queue_push(state$queue, event)
        if (state$flush_scheduled) return(invisible(NULL))
        state$flush_scheduled <- TRUE
        scheduled <- tryCatch({
          app$call_later(function(app) {
            private$flush_stream_queue(x, y, max_points, state)
          })
          TRUE
        }, error = function(e) FALSE)
        if (scheduled) return(invisible(NULL))
        state$flush_scheduled <- FALSE
        batch <- chart_stream_queue_drain(state$queue)
        private$apply_stream_batch(batch$events, batch$dropped, x, y, max_points, state)
        return(invisible(NULL))
      }
      private$apply_stream_batch(list(event), FALSE, x, y, max_points, state)
      invisible(NULL)
    },
    flush_stream_queue = function(x, y, max_points, state) {
      if (!isTRUE(state$active)) {
        state$flush_scheduled <- FALSE
        return(invisible(NULL))
      }
      state$flush_count <- state$flush_count + 1L
      batch <- chart_stream_queue_drain(state$queue, limit = 16L)
      app <- self$app
      clock <- if (is.null(app)) now_seconds else app$.__enclos_env__$private$clock
      # Keep a continuously non-empty queue fresh without repainting every
      # 1 ms processing chunk. A finite burst still publishes its final view.
      publish <- !state$queue$size || clock() >= state$next_publish
      private$apply_stream_batch(batch$events, batch$dropped, x, y, max_points, state,
                                 render = publish)
      if (publish) state$next_publish <- clock() + 1 / 60
      if (isTRUE(state$active) && state$queue$size) {
        # Let the app paint between chunks so a large burst cannot monopolize
        # one event-loop turn. Widget timers are cancelled with the app.
        scheduled <- tryCatch({
          self$set_timeout(0.001, function(widget, app) {
            private$flush_stream_queue(x, y, max_points, state)
          })
          TRUE
        }, error = function(e) FALSE)
        if (scheduled) return(invisible(NULL))
        # The widget may have been detached between dispatch and scheduling.
        # Finish the already queued work synchronously rather than strand it.
        remaining <- chart_stream_queue_drain(state$queue)
        private$apply_stream_batch(remaining$events, remaining$dropped,
                                   x, y, max_points, state, render = TRUE)
      }
      state$flush_scheduled <- FALSE
      invisible(NULL)
    },
    apply_stream_batch = function(events, dropped, x, y, max_points, state,
                                  render = TRUE) {
      if (!isTRUE(state$active)) return(invisible(NULL))
      working <- list(x = state$x, y = state$y,
                      source_id = state$source_id, sequence = state$sequence)
      changed <- FALSE
      for (i in seq_along(events)) {
        event <- events[[i]]
        if (i == 1L && isTRUE(dropped)) event <- chart_stream_mark_gap(event)
        tryCatch({
          working <- chart_stream_next(working, event, x, y, max_points)
          changed <- TRUE
          private$set_stream_error(NULL)
        }, error = function(e) private$set_stream_error(conditionMessage(e)))
      }
      if (changed) {
        state$x <- working$x; state$y <- working$y
        state$source_id <- working$source_id; state$sequence <- working$sequence
        state$pending_render <- TRUE
      }
      if (!render || !isTRUE(state$pending_render)) return(invisible(NULL))
      tryCatch({
        self$update_data(x = state$x, y = state$y)
        state$pending_render <- FALSE
      }, error = function(e) private$set_stream_error(conditionMessage(e)))
      invisible(NULL)
    },
    set_stream_error = function(message) {
      changed <- !identical(private$.stream_error, message)
      private$.stream_error <- message
      if (changed && !is.null(message)) {
        self$post_message("chart.stream.error", list(message = message))
      }
      invisible(NULL)
    },
    clear_stream_binding = function() {
      subscription <- private$.stream_subscription
      state <- private$.stream_state
      private$.stream_subscription <- NULL
      private$.stream_source <- NULL
      private$.stream_state <- NULL
      if (!is.null(state)) {
        state$active <- FALSE
        state$queue$items <- list()
        state$queue$head <- 1L
        state$queue$size <- 0L
        state$queue$dropped <- FALSE
        state$flush_scheduled <- FALSE
        state$pending_render <- FALSE
      }
      if (!is.null(subscription)) try(subscription$unsubscribe(), silent = TRUE)
      invisible(NULL)
    },
    register_stream_cleanup = function() {
      if (private$.stream_cleanup_registered) return(invisible(NULL))
      cleanup <- list(dispose = function() {
        private$clear_stream_binding()
        private$.stream_cleanup_registered <- FALSE
        invisible(NULL)
      })
      wp <- widget_private(self)
      wp$.reactive_bindings <- c(wp$.reactive_bindings, list(cleanup))
      private$.stream_cleanup_registered <- TRUE
      invisible(NULL)
    }
  )
)
