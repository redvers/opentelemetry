trait tag LogRecordExporter
  be export_logs(logs: Array[LogRecordData val] val,
    callback: {(ExportResult)} val)
  be shutdown(callback: {(Bool)} val)
