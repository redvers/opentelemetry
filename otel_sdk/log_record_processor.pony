trait tag LogRecordProcessor
  be on_emit(log: LogRecordData val)
  be shutdown(callback: {(Bool)} val)
  be force_flush(callback: {(Bool)} val)
