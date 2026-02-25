use "net"
use http = "../_corral/github_com_ponylang_http/http"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"

actor OtlpMetricExporter is otel_sdk.MetricExporter
  """
  Exports metrics to an OTLP HTTP/JSON endpoint. Encodes `MetricData` using
  `OtlpMetricEncoder` and POSTs the resulting JSON to the configured metrics
  path.
  """
  let _config: OtlpConfig
  let _resource: otel_api.Resource
  let _auth: TCPConnectAuth
  var _is_shutdown: Bool = false

  new create(
    auth: TCPConnectAuth,
    config: OtlpConfig = OtlpConfig,
    resource: otel_api.Resource = otel_api.Resource)
  =>
    _config = config
    _resource = resource
    _auth = auth

  be export_metrics(
    metrics: Array[otel_sdk.MetricData val] val,
    callback: {(otel_sdk.ExportResult)} val)
  =>
    if _is_shutdown then
      callback(otel_sdk.ExportFailure)
      return
    end

    if metrics.size() == 0 then
      callback(otel_sdk.ExportSuccess)
      return
    end

    let json_body = OtlpMetricEncoder.encode_metrics(metrics, _resource)
    let url_str: String val = recover val
      let s = String
      s.append(_config.endpoint)
      s.append(_config.metrics_path)
      s
    end

    try
      let url = http.URL.build(consume url_str)?
      let handler_factory = _OtlpHandlerFactory(callback)
      var client = http.HTTPClient(_auth, handler_factory)
      let request = http.Payload.request("POST", url)
      request("Content-Type") = "application/json"
      for (key, value) in _config.headers.values() do
        request(key) = value
      end
      request.add_chunk(json_body)
      client(consume request)?
    else
      callback(otel_sdk.ExportFailure)
    end

  be shutdown(callback: {(Bool)} val) =>
    _is_shutdown = true
    callback(true)
