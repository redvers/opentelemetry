actor SimpleLogRecordProcessor is LogRecordProcessor
  let _exporter: LogRecordExporter
  var _is_shutdown: Bool = false

  new create(exporter: LogRecordExporter) =>
    _exporter = exporter

  be on_emit(log: LogRecordData val) =>
    if _is_shutdown then return end
    let batch = recover val [log] end
    _exporter.export_logs(batch, {(result: ExportResult) => None })

  be shutdown(callback: {(Bool)} val) =>
    _is_shutdown = true
    _exporter.shutdown(callback)

  be force_flush(callback: {(Bool)} val) =>
    callback(true)
