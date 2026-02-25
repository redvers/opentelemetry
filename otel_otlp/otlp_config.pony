class val OtlpConfig
  """
  Configuration for the OTLP HTTP/JSON exporters. Defaults to
  `http://localhost:4318` with standard signal paths (`/v1/traces`,
  `/v1/metrics`, `/v1/logs`) and a 10-second timeout. Custom headers can be
  supplied for authentication.
  """
  let endpoint: String
  let traces_path: String
  let metrics_path: String
  let logs_path: String
  let timeout_ms: U64
  let headers: Array[(String, String)] val

  new val create(
    endpoint': String = "http://localhost:4318",
    traces_path': String = "/v1/traces",
    metrics_path': String = "/v1/metrics",
    logs_path': String = "/v1/logs",
    timeout_ms': U64 = 10000,
    headers': Array[(String, String)] val =
      recover val Array[(String, String)] end)
  =>
    endpoint = endpoint'
    traces_path = traces_path'
    metrics_path = metrics_path'
    logs_path = logs_path'
    timeout_ms = timeout_ms'
    headers = headers'
