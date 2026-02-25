trait tag LogRecordExporter
  """
  Receives batches of `LogRecordData` vals and exports them to a backend.
  Implemented as an actor for async I/O.
  """
  be export_logs(logs: Array[LogRecordData val] val,
    callback: {(ExportResult)} val)
    """
    Exports a batch of log records. Calls the callback with the result when
    the export is finished.
    """
  be shutdown(callback: {(Bool)} val)
    """
    Shuts down the exporter. The callback receives `true` on success.
    """
