test_that("sf geometry columns have compact bounded formatting and metadata", {
  skip_if_not_installed("sf")

  point <- sf::st_sfc(sf::st_point(c(10, 20)), sf::st_point(), crs = 4326)
  table <- data_table(sf::st_sf(id = 1:2, geometry = point), show_types = TRUE)
  info <- table$column_info()
  geometry <- info[info$name == "geometry", , drop = FALSE]

  expect_identical(class(table$data), c("sf", "data.frame"))
  expect_s3_class(table$data, "sf")
  expect_identical(table$data$geometry, point)
  expect_identical(table_format_values(point), c("POINT (10 20)", "POINT EMPTY"))
  expect_identical(geometry$geometry_type, "POINT")
  expect_identical(geometry$dimensions, "XY")
  expect_identical(geometry$crs, "EPSG:4326")
  expect_identical(as.numeric(geometry$geometry_bbox[[1L]]), as.numeric(sf::st_bbox(point)))
  expect_identical(geometry$editable, FALSE)
  expect_identical(geometry$sortable, FALSE)

  pilot <- test_app(app(table), width = 44, height = 7)
  on.exit(pilot$stop(), add = TRUE)
  screen <- paste(pilot$screen_text(), collapse = "\n")
  expect_match(screen, "sfc|POINT")
  expect_match(screen, "EPSG:4326")
  expect_match(screen, "POINT (10 20)", fixed = TRUE)
})

test_that("browse_data exposes cached column metadata and a per-feature geometry inspector", {
  skip_if_not_installed("sf")

  geometry <- sf::st_sfc(sf::st_point(c(10, 20)), crs = 4326)
  data <- sf::st_sf(id = 1L, geometry = geometry)
  summary <- column_summary(geometry, "geometry", geometry_active = TRUE)
  expect_identical(summary[["Geometry type"]], "POINT")
  expect_identical(summary$CRS, "EPSG:4326")
  expect_identical(summary[["Geometry role"]], "Active")
  expect_match(summary[["Bounding box"]], "xmin 10")

  pilot <- test_app(data_browser(data), width = 100, height = 28)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("enter")
  screen <- paste(pilot$screen_text(), collapse = "\n")
  expect_match(screen, "geometry Type")
  expect_match(screen, "geometry CRS")
  expect_match(screen, "geometry Bounding box")
  expect_match(screen, "geometry WKT preview")
})

test_that("sfg geometry families use bounded structural summaries", {
  skip_if_not_installed("sf")

  line <- sf::st_linestring(rbind(c(0, 0), c(1, 1), c(2, 2)))
  polygon <- sf::st_polygon(list(
    rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 0)),
    rbind(c(.2, .2), c(.3, .2), c(.2, .3), c(.2, .2))
  ))
  multiline <- sf::st_multilinestring(list(rbind(c(0, 0), c(1, 1)), rbind(c(2, 2), c(3, 3))))
  multipolygon <- sf::st_multipolygon(list(
    list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 0))),
    list(rbind(c(2, 2), c(3, 2), c(3, 3), c(2, 2)))
  ))
  collection <- sf::st_geometrycollection(list(
    sf::st_point(c(1, 2)), sf::st_linestring(rbind(c(0, 0), c(1, 1)))
  ))
  geometries <- sf::st_sfc(
    sf::st_multipoint(rbind(c(1, 2), c(3, 4))), line, polygon, multiline,
    multipolygon, collection, crs = sf::NA_crs_
  )
  shown <- table_format_values(geometries, width = 40L)

  expect_match(shown[[1L]], "^MULTIPOINT \\[2 points\\]")
  expect_match(shown[[2L]], "^LINESTRING \\[3 coordinates\\]")
  expect_match(shown[[3L]], "^POLYGON \\[2 rings\\]")
  expect_match(shown[[4L]], "^MULTILINESTRING \\[2 lines\\]")
  expect_match(shown[[5L]], "^MULTIPOLYGON \\[2 polygons\\]")
  expect_match(shown[[6L]], "^GEOMETRYCOLLECTION \\[2 geometries\\]")
  expect_true(all(str_width(shown) <= 40L))
  expect_false(any(grepl("LINESTRING \\(", shown, fixed = FALSE)))

  detail <- table_geometry_details(geometries[[2L]])
  expect_identical(detail$Type, "LINESTRING")
  expect_identical(detail$Dimensions, "XY")
  expect_identical(detail$Empty, "No")
  expect_identical(detail$Coordinates, 3L)
  expect_true(nchar(detail$`WKT preview`) <= 120L)
})

test_that("geometry formatting covers Z/M dimensions, empty and missing CRS", {
  skip_if_not_installed("sf")

  xyz <- sf::st_sfc(sf::st_point(c(1, 2, 3)), crs = sf::NA_crs_)
  xym <- sf::st_sfc(sf::st_point(c(1, 2, 3), dim = "XYM"), crs = sf::NA_crs_)
  xyzm <- sf::st_sfc(sf::st_point(c(1, 2, 3, 4), dim = "XYZM"), crs = sf::NA_crs_)
  empty <- sf::st_sfc(sf::st_geometrycollection(list()), crs = sf::NA_crs_)
  missing_as_empty <- sf::st_sfc(NA, crs = 4326)
  mixed <- sf::st_sfc(sf::st_point(c(1, 2)), sf::st_linestring(rbind(c(0, 0), c(1, 1))), crs = sf::NA_crs_)

  expect_identical(table_geometry_metadata(xyz)$dimensions, "XYZ")
  expect_identical(table_geometry_metadata(xym)$dimensions, "XYM")
  expect_identical(table_geometry_metadata(xyzm)$dimensions, "XYZM")
  expect_identical(table_format_values(empty), "GEOMETRYCOLLECTION EMPTY")
  expect_identical(table_geometry_metadata(mixed)$geometry_type, "GEOMETRY")
  expect_identical(table_geometry_metadata(mixed)$crs_label, "NA CRS")
  expect_identical(table_format_values(missing_as_empty), "GEOMETRYCOLLECTION EMPTY")
  expect_false(any(table_missing_mask(missing_as_empty)))
})

test_that("sf attribute edits preserve geometry, CRS, active column and row associations", {
  skip_if_not_installed("sf")

  geometry <- sf::st_sfc(
    sf::st_point(c(30, 3)), sf::st_point(c(10, 1)), sf::st_point(c(20, 2)),
    crs = 4326
  )
  source <- sf::st_sf(
    name = c("c", "a", "b"), amount = c(3, 1, 2),
    state = factor(c("old", "new", "old"), levels = c("new", "old")),
    day = as.Date(c("2024-03-03", "2024-03-01", "2024-03-02")),
    geom = geometry, sf_column_name = "geom", agr = c(name = "identity", amount = "constant")
  )
  original <- source
  original_geometry <- sf::st_geometry(source)
  original_crs <- sf::st_crs(source)
  original_agr <- attr(source, "agr", exact = TRUE)
  table <- data_table(source, editable = TRUE)

  table$set_cell(1L, "name", "changed")
  table$set_cell(2L, "amount", "12.25")
  table$set_cell(3L, "state", "new")
  table$set_cell(1L, "day", "2024-04-03")
  table$sort("amount")
  expect_identical(table$view, c(3L, 1L, 2L))
  expect_identical(table$data$geom, original_geometry)
  expect_identical(sf::st_crs(table$data), original_crs)
  expect_identical(attr(table$data, "sf_column", exact = TRUE), "geom")
  expect_identical(attr(table$data, "agr", exact = TRUE), original_agr)
  expect_s3_class(table$data, "sf")
  expect_identical(table$data$name, c("changed", "a", "b"))
  expect_identical(table$data$amount, c(3, 12.25, 2))
  expect_identical(table$data$state, factor(c("old", "new", "new"), levels = c("new", "old")))
  expect_identical(table$data$day[[1L]], as.Date("2024-04-03"))
  expect_identical(table$data$amount[table$view], c(2, 3, 12.25))
  expect_identical(source, original)

  before <- table$data
  expect_error(table$set_cell(1L, "geom", "POINT (0 0)"), "read-only")
  expect_error(table$sort("geom"), "Sorting is not supported")
  expect_identical(table$data, before)

  table$filter(c(1L, 3L))
  expect_identical(table$view, c(3L, 1L))
  table$filter_columns(list(name = table_filter("contains", "changed")))
  expect_identical(table$view, 1L)
  expect_identical(table$data$geom, original_geometry)
})

test_that("sf table creation and row details support empty and multiple geometry columns", {
  skip_if_not_installed("sf")

  empty <- sf::st_sf(
    id = integer(), geom = sf::st_sfc(crs = 4326),
    sf_column_name = "geom"
  )
  empty_table <- data_table(empty)
  expect_s3_class(empty_table$data, "sf")
  expect_identical(empty_table$row_count, 0L)
  expect_identical(empty_table$column_info()$geometry_type[[2L]], "GEOMETRY")

  first <- sf::st_sfc(sf::st_point(c(1, 2)), crs = 4326)
  second <- sf::st_sfc(sf::st_point(c(3, 4)), crs = 3857)
  multi <- sf::st_sf(id = 1L, first = first, second = second, sf_column_name = "second")
  multi_table <- data_table(multi)
  info <- multi_table$column_info()
  expect_identical(info$geometry_type[info$name %in% c("first", "second")], c("POINT", "POINT"))
  expect_identical(info$geometry_active[info$name %in% c("first", "second")], c(FALSE, TRUE))
  expect_identical(multi_table$data, multi)

  details <- table_geometry_details(sf::st_geometry(multi)[1L])
  expect_identical(details$CRS, "EPSG:3857")
  expect_match(details$`WKT preview`, "POINT")
})

test_that("SFG list-columns are summarized without becoming editable or sortable", {
  skip_if_not_installed("sf")

  values <- I(list(sf::st_point(c(1, 2)), sf::st_point(), sf::st_linestring(rbind(c(0, 0), c(1, 1)))))
  data <- data.frame(id = 1:3, shape = values)
  table <- data_table(data, editable = TRUE)

  expect_identical(table$column_info()$type[[2L]], "list<sfg>")
  expect_identical(table$column_info()$editable[[2L]], FALSE)
  expect_identical(table$column_info()$sortable[[2L]], FALSE)
  expect_identical(table_format_values(data$shape), c("POINT (1 2)", "POINT EMPTY", "LINESTRING [2 coordinates]"))
  expect_error(table$set_cell(1L, "shape", "POINT (2 3)"), "read-only")
  expect_error(table$sort("shape"), "Sorting is not supported")

  with_missing <- I(list(sf::st_point(c(1, 2)), NULL, sf::st_point(c(3, 4))))
  missing_table <- data_table(data.frame(shape = with_missing))
  expect_identical(table_format_values(missing_table$data$shape)[[2L]], "<missing geometry>")
  expect_true(table_missing_mask(missing_table$data$shape)[[2L]])
})

test_that("large geometry summaries and Unicode attributes remain bounded", {
  skip_if_not_installed("sf")

  coordinates <- cbind(seq_len(10000L), -seq_len(10000L))
  line <- sf::st_linestring(coordinates)
  geometry <- sf::st_sfc(line, crs = 4326)
  summary <- table_format_values(geometry, width = 32L)
  details <- table_geometry_details(geometry)
  expect_identical(summary, "LINESTRING [10000 coordinates]")
  expect_true(str_width(summary) <= 32L)
  expect_match(details[["WKT preview"]], "omitted: 10,000 coordinates")
  expect_true(nchar(details[["WKT preview"]]) <= 120L)

  data <- sf::st_sf(city = "M\u00fcnchen \u4e16\u754c", geometry = sf::st_sfc(sf::st_point(c(1, 2)), crs = 4326))
  table <- data_table(data)
  expect_identical(table_format_values(table$data$city), "M\u00fcnchen \u4e16\u754c")
  expect_identical(table$data$geometry, sf::st_geometry(data))
})

test_that("seeded valid-geometry fuzzing stays bounded and does not mutate input", {
  skip_if_not_installed("sf")

  set.seed(20525)
  make_geometry <- function() {
    n <- sample.int(6L, 1L) + 3L
    coordinates <- matrix(stats::runif(n * 2L, -100, 100), ncol = 2L)
    ring <- rbind(coordinates, coordinates[1L, , drop = FALSE])
    kind <- sample(c(
      "POINT", "MULTIPOINT", "LINESTRING", "POLYGON",
      "MULTILINESTRING", "MULTIPOLYGON", "GEOMETRYCOLLECTION"
    ), 1L)
    switch(
      kind,
      POINT = sf::st_point(coordinates[1L, ]),
      MULTIPOINT = sf::st_multipoint(coordinates),
      LINESTRING = sf::st_linestring(coordinates),
      POLYGON = sf::st_polygon(list(ring)),
      MULTILINESTRING = sf::st_multilinestring(list(coordinates[seq_len(2L), , drop = FALSE],
                                                      coordinates[seq.int(3L, n), , drop = FALSE])),
      MULTIPOLYGON = sf::st_multipolygon(list(list(ring))),
      GEOMETRYCOLLECTION = sf::st_geometrycollection(list(
        sf::st_point(coordinates[1L, ]),
        sf::st_linestring(coordinates[seq_len(2L), , drop = FALSE])
      ))
    )
  }

  values <- lapply(seq_len(40L), function(i) make_geometry())
  geometry <- sf::st_sfc(values, crs = 4326)
  original <- geometry
  formatted <- table_format_values(geometry, width = 40L)
  details <- lapply(geometry[seq_len(10L)], table_geometry_details)

  expect_length(formatted, 40L)
  expect_true(all(str_width(formatted) <= 40L))
  expect_false(any(grepl("[[:cntrl:]]", formatted)))
  expect_true(all(vapply(details, function(value) nchar(value[["WKT preview"]]) <= 120L, TRUE)))
  expect_identical(geometry, original)
})

test_that("sf geometries and attribute rows remain aligned under seeded operations", {
  skip_if_not_installed("sf")

  set.seed(20261030)
  n <- 80L
  ids <- seq_len(n)
  geometry <- sf::st_sfc(lapply(ids, function(i) sf::st_point(c(i, -i))), crs = 4326)
  source <- sf::st_sf(id = ids, score = sample.int(n), geometry = geometry)
  table <- data_table(source, editable = TRUE)
  expected_id <- ids

  for (iteration in seq_len(30L)) {
    table$sort("score")
    expect_identical(table$data$geometry, geometry)
    expect_identical(table$data[table$view, , drop = FALSE]$id, as.integer(expected_id[order(source$score)]))
    selected <- sample.int(n, 10L)
    table$filter(selected)
    expected_rows <- selected[order(source$score[selected])]
    expect_identical(table$data$geometry[table$view], geometry[expected_rows])
    table$filter(NULL)
    row <- sample.int(n, 1L)
    old_geometry <- table$data$geometry[[row]]
    table$set_cell(row, "id", as.character(n + iteration))
    expected_id[[row]] <- n + iteration
    expect_identical(table$data$geometry[[row]], old_geometry)
    expect_identical(table$data$score, source$score)
  }
})


