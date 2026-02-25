primitive ExportSuccess
  """
  Indicates an export operation completed successfully.
  """
  fun string(): String iso^ => "Success".clone()

primitive ExportFailure
  """
  Indicates an export operation failed.
  """
  fun string(): String iso^ => "Failure".clone()

// The outcome of an export operation.
type ExportResult is (ExportSuccess | ExportFailure)


trait tag SpanExporter
  """
  Receives batches of ReadOnlySpan vals and exports them to a backend.
  Implemented as an actor for async I/O.
  """
  be export_spans(
    spans: Array[ReadOnlySpan val] val,
    callback: {(ExportResult)} val)
    """
    Exports a batch of completed spans. Calls the callback with the result
    when the export is finished.
    """

  be shutdown(callback: {(Bool)} val)
    """
    Shuts down the exporter. The callback receives `true` on success.
    """
