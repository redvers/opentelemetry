primitive ExportSuccess
  fun string(): String iso^ => "Success".clone()

primitive ExportFailure
  fun string(): String iso^ => "Failure".clone()

type ExportResult is (ExportSuccess | ExportFailure)


trait tag SpanExporter
  """
  Receives batches of ReadOnlySpan vals and exports them to a backend.
  Implemented as an actor for async I/O.
  """
  be export_spans(
    spans: Array[ReadOnlySpan val] val,
    callback: {(ExportResult)} val)

  be shutdown(callback: {(Bool)} val)
