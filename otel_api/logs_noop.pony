actor NoopLoggerProvider is LoggerProvider
  """
  A no-op `LoggerProvider` that always returns `NoopLogger`. Used as the
  default when no SDK is configured.
  """
  be get_logger(name: String, callback: {(Logger val)} val,
    version: String = "", schema_url: String = "")
  =>
    callback(NoopLogger)

  be shutdown(callback: {(Bool)} val) =>
    callback(true)


class val NoopLogger is Logger
  """
  A no-op `Logger` that silently discards all emitted log records.
  """
  fun val emit(
    body: LogBody = None,
    severity_number: U8 = 0,
    severity_text: String = "",
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end,
    timestamp: U64 = 0,
    observed_timestamp: U64 = 0,
    context: Context = Context)
  =>
    None
