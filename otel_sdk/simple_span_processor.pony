actor SimpleSpanProcessor is SpanProcessor
  """
  Exports each span immediately when it finishes.
  Suitable for development/testing; not recommended for production.
  """
  let _exporter: SpanExporter
  var _is_shutdown: Bool = false

  new create(exporter: SpanExporter) =>
    _exporter = exporter

  be on_start(span: ReadOnlySpan val) =>
    None

  be on_end(span: ReadOnlySpan val) =>
    if _is_shutdown then return end
    let batch = recover val [span] end
    _exporter.export_spans(batch, {(result: ExportResult) => None } val)

  be shutdown(callback: {(Bool)} val) =>
    _is_shutdown = true
    _exporter.shutdown(callback)

  be force_flush(callback: {(Bool)} val) =>
    callback(true)
