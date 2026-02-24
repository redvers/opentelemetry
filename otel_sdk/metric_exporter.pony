trait tag MetricExporter
  be export_metrics(
    metrics: Array[MetricData val] val,
    callback: {(ExportResult)} val)

  be shutdown(callback: {(Bool)} val)
