trait tag MetricExporter
  """
  Receives batches of `MetricData` vals and exports them to a backend.
  Implemented as an actor for async I/O.
  """
  be export_metrics(
    metrics: Array[MetricData val] val,
    callback: {(ExportResult)} val)
    """
    Exports a batch of metric data. Calls the callback with the result when
    the export is finished.
    """

  be shutdown(callback: {(Bool)} val)
    """
    Shuts down the exporter. The callback receives `true` on success.
    """
