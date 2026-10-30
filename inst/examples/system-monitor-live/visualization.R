# Demo-local presentation helpers. Ordinary data.frame, ggplot2 and Plotly APIs.
monitor_extract <- function(x) list(timestamp = x$timestamp, cpu = x$metrics$cpu, ram = x$metrics$ram)

monitor_ggplots <- function(data) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Install optional package 'ggplot2'.")
  chart <- function(field, title) {
    frame <- data.frame(timestamp = data$timestamp, value = data[[field]], segment = data$segment)
    ggplot2::ggplot(frame, ggplot2::aes(x = timestamp, y = value, group = segment)) +
      ggplot2::geom_line(na.rm = TRUE) + ggplot2::geom_point(na.rm = TRUE, size = 1) +
      ggplot2::coord_cartesian(ylim = c(0, 100)) + ggplot2::labs(title = title, x = "Time (UTC)", y = "Percent") +
      ggplot2::theme_minimal()
  }
  long <- rbind(data.frame(timestamp = data$timestamp, value = data$cpu, metric = "CPU", segment = data$segment),
    data.frame(timestamp = data$timestamp, value = data$ram, metric = "RAM", segment = data$segment))
  long$group <- paste(long$metric, long$segment)
  compare <- ggplot2::ggplot(long, ggplot2::aes(x = timestamp, y = value, colour = metric, group = group)) +
    ggplot2::geom_line(na.rm = TRUE) + ggplot2::geom_point(na.rm = TRUE, size = 1) +
    ggplot2::coord_cartesian(ylim = c(0, 100)) + ggplot2::labs(x = "Time (UTC)", y = "Percent", title = "CPU and RAM") +
    ggplot2::theme_minimal()
  list(cpu = chart("cpu", "CPU usage"), ram = chart("ram", "RAM usage"), compare = compare)
}

monitor_plotly_plan <- function(previous, data, status) {
  empty <- list(type = "replace", reason = "empty", data = data, source = NULL, sequence = NA_real_, generation = status$generation)
  if (status$state == "invalid") {
    empty$data <- data[0, , drop = FALSE]; empty$reason <- "invalid"
    if (!is.null(previous) && identical(previous$reason, "invalid")) empty$type <- "noop"
    return(empty)
  }
  if (!nrow(data)) {
    if (!is.null(previous) && identical(previous$reason, "empty")) empty$type <- "noop"
    return(empty)
  }
  last <- data[nrow(data), , drop = FALSE]
  plan <- list(type = "replace", reason = "initial", data = data, source = last$source_id[[1]],
    sequence = last$sequence[[1]], generation = status$generation)
  if (is.null(previous) || previous$reason %in% c("empty", "invalid")) return(plan)
  if (!identical(previous$source, plan$source) || !identical(previous$generation, plan$generation)) {
    plan$reason <- "source"; return(plan)
  }
  if (is.finite(plan$sequence) && is.finite(previous$sequence) && plan$sequence == previous$sequence) {
    plan$type <- "noop"; plan$reason <- "unchanged"; return(plan)
  }
  if (!is.finite(previous$sequence) || !is.finite(plan$sequence)) {plan$reason <- "unknown_sequence"; return(plan)}
  newer <- data[!is.na(data$sequence) & data$sequence > previous$sequence, , drop = FALSE]
  if (!nrow(newer) || newer$sequence[[1]] != previous$sequence + 1 || any(newer$gap) ||
      any(diff(newer$sequence) != 1)) {plan$reason <- "gap"; return(plan)}
  plan$type <- "extend"; plan$reason <- "ordered"; plan$data <- newer
  plan
}

monitor_plotly_arrays <- function(data, max_points) {
  x <- list(); cpu <- list(); ram <- list(); keys <- list()
  for (i in seq_len(nrow(data))) {
    if (is.na(data$timestamp[[i]])) next
    stamp <- format(data$timestamp[[i]], "%Y-%m-%dT%H:%M:%OS3Z", tz = "UTC")
    key <- paste(data$source_id[[i]], data$sequence[[i]], sep = ":")
    if (i > 1L && data$segment[[i]] != data$segment[[i - 1L]]) {
      x <- c(x, list(stamp)); cpu <- c(cpu, list(NA_real_)); ram <- c(ram, list(NA_real_)); keys <- c(keys, list("gap"))
    }
    x <- c(x, list(stamp)); cpu <- c(cpu, list(data$cpu[[i]])); ram <- c(ram, list(data$ram[[i]])); keys <- c(keys, list(key))
  }
  list(x = list(tail(x, max_points), tail(x, max_points)),
    y = list(tail(cpu, max_points), tail(ram, max_points)),
    customdata = list(tail(keys, max_points), tail(keys, max_points)))
}

monitor_plotly_widget <- function(probe = FALSE) {
  if (!requireNamespace("plotly", quietly = TRUE)) stop("Install optional package 'plotly'.")
  cpu <- plotly::plot_ly(x = character(), y = numeric(), type = "scatter", mode = "lines",
    name = "CPU", connectgaps = FALSE, line = list(color = "#187bcd"))
  ram <- plotly::plot_ly(x = character(), y = numeric(), type = "scatter", mode = "lines",
    name = "RAM", connectgaps = FALSE, line = list(color = "#d17a16"))
  widget <- plotly::subplot(cpu, ram, nrows = 2L, shareX = TRUE, titleY = TRUE)
  widget <- plotly::layout(widget, yaxis = list(title = "CPU %", range = c(0, 100)),
    yaxis2 = list(title = "RAM %", range = c(0, 100)), xaxis = list(type = "date"),
    xaxis2 = list(type = "date", title = "Time (UTC)"), uirevision = "termr.monitor")
  # This example targets current browsers with native typed arrays. Remove
  # the redundant legacy polyfill from this owned htmlwidget's dependency
  # list; some distributions of that asset require an absent GLOBAL loader.
  widget <- plotly::plotly_build(widget)
  widget$dependencies <- Filter(function(dependency) dependency$name != "typedarray", widget$dependencies)
  # Ready handshake prevents proxy messages racing initial widget creation.
  htmlwidgets::onRender(widget, "function(el,x,ctx) {
    const state=el._termrState={ready:Date.now(),count:0,probe:ctx.probe};
    const ready = () => { if(window.Shiny) Shiny.setInputValue(el.id+'_ready', state.ready, {priority:'event'}); };
    if(ctx.probe && !window.termrPlotlyProbe)
      window.termrPlotlyProbe={methods:{extendTraces:0,restyle:0},frames:[]};
    if(!window.termrPlotlyTransport) {
      window.termrPlotlyTransport=true;
      ['extendTraces','restyle'].forEach(function(method) {
        const original=Plotly[method];
        Plotly[method]=function() {
          const args=arguments, start=performance.now();
          const graph=typeof args[0]==='string'?document.getElementById(args[0]):args[0];
          const state=graph&&graph._termrState, stats=window.termrPlotlyProbe;
          if(state&&state.probe) stats.methods[method]++;
          // Capture this message's measurement before a subsequent update can
          // change graph.data while this promise awaits the browser frame.
          const incoming=args[1]&&args[1].x&&args[1].x[0];
          const stamp=incoming&&incoming.length?Date.parse(incoming[incoming.length-1]):NaN;
          const result=original.apply(this,args);
          if(state) Promise.resolve(result).then(()=>requestAnimationFrame(()=>requestAnimationFrame(()=>{
            if(graph._termrState!==state) return;
            if(window.Shiny) Shiny.setInputValue(graph.id+'_ack',
              {ready:state.ready,count:++state.count},{priority:'event'});
            if(!state.probe) return;
            const trace=graph.data[0], n=trace.x.length;
            stats.frames.push({method:method,at:Date.now(),browserUpdateMs:performance.now()-start,
              endToEndMs:Number.isFinite(stamp)?Date.now()-stamp:null,points:n,
              lastKey:n?trace.customdata[n-1]:null});
            if(stats.frames.length>2000) stats.frames.shift();
          })));
          return result;
        };
      });
    }
    if(el._fullLayout) ready(); else el.once('plotly_afterplot', ready);
  }", data = list(probe = probe))
}

monitor_plotly_send <- function(session, output_id, plan, max_points) {
  if (plan$type == "noop") return(invisible(NULL))
  update <- monitor_plotly_arrays(plan$data, max_points)
  # Explicit session flush scheduling also works with older Plotly versions
  # whose proxy defer flag is inconsistent. No private Plotly API is used.
  session$onFlushed(function() {
    proxy <- plotly::plotlyProxy(output_id, session, deferUntilFlush = FALSE)
    if (plan$type == "extend") plotly::plotlyProxyInvoke(proxy, "extendTraces", update, list(0L, 1L), as.integer(max_points))
    else plotly::plotlyProxyInvoke(proxy, "restyle", update, list(0L, 1L))
  }, once = TRUE)
  invisible(NULL)
}
