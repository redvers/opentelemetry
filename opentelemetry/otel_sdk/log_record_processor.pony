trait tag LogRecordProcessor
  """
  Receives log record lifecycle events. Called by `SdkLoggerProvider` when
  logs are emitted.
  """
  be on_emit(log: LogRecordData val)
    """
    Called when a log record is emitted. Receives an immutable `LogRecordData`
    for processing and export.
    """
  be shutdown(callback: {(Bool)} val)
    """
    Shuts down the processor. The callback receives `true` on success.
    """
  be force_flush(callback: {(Bool)} val)
    """
    Forces the processor to export any buffered log records immediately.
    """
