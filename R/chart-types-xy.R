# Line and scatter charts share numeric, time, scale and selection handling.

# Reduce a long line to a bounded set of indices while preserving each run's
# first, last, minimum and maximum observations in each chunk.
reduce_line_indices <- function(values, run, limit) {
  if (length(values) <= limit) return(seq_along(values))
  ends <- c(which(diff(run) != 0L), length(run))
  starts <- c(1L, ends[-length(ends)] + 1L)
  pieces <- vector("list", length(starts))
  for (r in seq_along(starts)) {
    lo <- starts[[r]]; hi <- ends[[r]]; n <- hi - lo + 1L
    chunk_count <- max(1L, floor(limit * n / length(values) / 4L))
    chunk <- ceiling(n / chunk_count)
    starts_chunk <- seq.int(lo, hi, by = chunk)
    pieces[[r]] <- unlist(lapply(starts_chunk, function(first) {
      ix <- seq.int(first, min(hi, first + chunk - 1L))
      c(ix[[1L]], ix[[length(ix)]], ix[[which.min(values[ix])]],
        ix[[which.max(values[ix])]])
    }), use.names = FALSE)
  }
  sort(unique(unlist(pieces, use.names = FALSE)))
}

nav_linear <- function(ids) {
  function(key, selected) {
    n <- length(ids)
    if (!n) return(NULL)
    pos <- match(selected, ids)
    if (is.na(pos)) pos <- which.min(abs(ids - selected))
    new <- if (key %in% c("left", "up", "k")) max(1L, pos - 1L)
      else if (key %in% c("right", "down", "j")) min(n, pos + 1L)
      else if (key == "home") 1L
      else if (key == "end") n
      else return(NULL)
    ids[[new]]
  }
}

handle_xy <- function(spec, W, H, resolved) {
  type <- spec$type
  mode <- resolved$mode
  res <- mode_resolution(mode)
  glyphs <- axis_glyphs(resolved$text)
  d <- spec$data
  if (!length(d$x)) {
    frame <- plain_frame(spec, W, H)
    return(empty_plan(spec, frame, glyphs, list(note_item(frame, "(no finite data)"))))
  }

  xs <- d$xscale %||% scale_linear
  ys <- d$yscale %||% scale_linear
  tx <- scale_forward(xs, d$x)
  ty <- scale_forward(ys, d$y)
  xdom <- range(tx)
  ydom <- range(ty)
  frame <- chart_frame(spec, W, H, res, ydom, xdom, "numeric", xscale = xs, yscale = ys)
  if (!frame$ok) return(empty_plan(spec, frame, glyphs))
  surf <- surface_new(frame$plot[["cols"]], frame$plot[["rows"]], mode)
  hd <- surf$hd; wd <- surf$wd
  jx <- dot_from_unit(unit_values(tx, xdom[[1L]], xdom[[2L]]), wd)
  iy <- dot_row_from_unit(unit_values(ty, ydom[[1L]], ydom[[2L]]), hd)
  n <- length(d$x)
  keep <- if (identical(type, "scatter")) {
    reduce_scatter_cells(jx, iy, wd)
  } else {
    limit <- max(4L, wd * 4L)
    if (n > limit) reduce_line_indices(ty, d$run, limit) else seq_len(n)
  }

  ops <- list()
  add <- function(i, j, kind) {
    ops[[length(ops) + 1L]] <<- new_op(dots_idx(i, j, hd, wd), mark_of(kind))
  }
  if (identical(type, "line")) {
    line <- raster_polyline(iy[keep], jx[keep], d$run[keep])
    add(line$i, line$j, K_STROKE)
    if (identical(mode, "ascii")) add(iy[keep], jx[keep], K_POINT)
  } else {
    add(iy[keep], jx[keep], K_POINT)
  }
  surf$m <- apply_ops(surf$m, ops)

  ids <- d$source[keep]
  stamp <- function(selected) {
    p <- findInterval(selected, d$source)
    if (p < 1L || d$source[[p]] != selected) return(NULL)
    list(ops = list(new_op(dots_idx(iy[[p]], jx[[p]], hd, wd), mark_of(K_SELECTED))),
         marker = NULL)
  }
  hit <- function(row, col, selected) {
    p <- hit_plot_cell(frame, row, col)
    if (is.null(p)) return(NULL)
    kx <- (jx[keep] - 0.5) / surf$sx
    ky <- (iy[keep] - 0.5) / surf$sy
    if (identical(type, "line")) {
      near <- hit_distance2(p, kx, ky)
      on_line <- min(near) <= hit_radius^2
      n_keep <- length(kx)
      if (!on_line && n_keep > 1L) {
        run <- d$run[keep]
        adjacent <- which(run[-1L] == run[-n_keep])
        if (length(adjacent)) {
          on_line <- min(hit_segment_distance2(
            p[["col"]] - 0.5, p[["row"]] - 0.5, kx[adjacent], ky[adjacent],
            kx[adjacent + 1L], ky[adjacent + 1L]
          )) <= hit_radius^2
        }
      }
      k <- if (on_line) which.min(near) else integer()
    } else {
      d2 <- hit_distance2(p, kx, ky)
      nearest <- which.min(d2)
      k <- if (d2[[nearest]] <= hit_radius^2) nearest else integer()
    }
    if (length(k)) ids[[k]] else NULL
  }
  plan <- surface_plan(spec, frame, glyphs, list(), surf, stamp, ids,
                       nav = nav_linear(ids), positions = keep, hit = hit)
  refs <- spec$refs
  point_text <- d$point_labels
  has_points <- !is.null(point_text) && any(!is.na(point_text[keep]))
  plot0 <- if (has_points || (!is.null(refs) && any(!is.na(c(refs$hlabel, refs$vlabel))))) {
    plan$plot(NA_integer_)
  } else NULL
  plan$refs <- ref_cells(refs, xs, ys, xdom, ydom, surf, glyphs, mode, plot0)
  if (has_points) {
    prow <- (iy[keep] - 1L) %/% surf$sy + 1L
    pcol <- (jx[keep] - 1L) %/% surf$sx + 1L
    occupied <- if (!is.null(plan$refs) && length(plan$refs$idx)) plan$refs$idx else NULL
    text <- point_text[keep]
    shown <- !is.na(text)
    text[shown] <- clean_text(text[shown])
    plan$refs <- with_label_units(
      plan$refs,
      point_label_units(text, prow, pcol, plot0, surf$rows, surf$cols, glyphs,
                        occupied = occupied)
    )
  }
  plan
}
