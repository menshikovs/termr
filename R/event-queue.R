# First-in first-out queue of pending events.
EventQueue <- R6::R6Class(
  "EventQueue",
  public = list(
    initialize = function() private$items <- new.env(hash = TRUE, parent = emptyenv()),

    push = function(event) {
      if (is.null(event)) return(invisible(self))
      if (private$count == private$capacity) private$grow()
      private$items[[as.character(private$tail)]] <- event
      private$tail <- if (private$tail == private$capacity) 1L else private$tail + 1L
      private$count <- private$count + 1L
      invisible(self)
    },

    pop = function() {
      if (!private$count) return(NULL)
      key <- as.character(private$head)
      item <- private$items[[key]]
      rm(list = key, envir = private$items)
      private$head <- if (private$head == private$capacity) 1L else private$head + 1L
      private$count <- private$count - 1L
      if (!private$count) {
        # Drop a burst's expanded hash table once drained. Small queues reuse
        # their storage, avoiding a new environment for each ordinary event.
        if (private$capacity > 64L) private$items <- new.env(hash = TRUE, parent = emptyenv())
        private$capacity <- 64L
        private$head <- private$tail <- 1L
      }
      item
    },

    size = function() private$count,

    is_empty = function() self$size() == 0L,

    clear = function() {
      private$items <- new.env(hash = TRUE, parent = emptyenv())
      private$head <- private$tail <- 1L
      private$count <- 0L
      private$capacity <- 64L
      invisible(self)
    }
  ),
  private = list(
    items = NULL, head = 1L, tail = 1L, count = 0L, capacity = 64L,
    grow = function() {
      if (private$capacity == .Machine$integer.max) stop("Too many pending events.", call. = FALSE)
      capacity <- as.integer(min(as.double(private$capacity) * 2, .Machine$integer.max))
      items <- new.env(hash = TRUE, parent = emptyenv())
      index <- private$head
      for (i in seq_len(private$count)) {
        items[[as.character(i)]] <- private$items[[as.character(index)]]
        index <- if (index == private$capacity) 1L else index + 1L
      }
      private$items <- items
      private$capacity <- capacity
      private$head <- 1L
      private$tail <- private$count + 1L
      invisible()
    }
  )
)
