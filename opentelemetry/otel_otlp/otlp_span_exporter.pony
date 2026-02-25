use "net"
use http = "../../_corral/github_com_ponylang_http/http"
use otel_sdk = "../otel_sdk"

actor OtlpSpanExporter is otel_sdk.SpanExporter
  """
  Exports spans to an OTLP HTTP/JSON endpoint. Encodes batches of
  `ReadOnlySpan` vals using `OtlpJsonEncoder` and POSTs the resulting JSON to
  the configured traces path.
  """
  let _config: OtlpConfig
  let _auth: TCPConnectAuth
  var _is_shutdown: Bool = false

  new create(auth: TCPConnectAuth, config: OtlpConfig = OtlpConfig) =>
    _config = config
    _auth = auth

  be export_spans(
    spans: Array[otel_sdk.ReadOnlySpan val] val,
    callback: {(otel_sdk.ExportResult)} val)
  =>
    if _is_shutdown then
      callback(otel_sdk.ExportFailure)
      return
    end

    if spans.size() == 0 then
      callback(otel_sdk.ExportSuccess)
      return
    end

    let json_body = OtlpJsonEncoder.encode_spans(spans)
    let url_str: String val = recover val
      let s = String
      s.append(_config.endpoint)
      s.append(_config.traces_path)
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


class val _OtlpHandlerFactory is http.HandlerFactory
  let _callback: {(otel_sdk.ExportResult)} val

  new val create(callback: {(otel_sdk.ExportResult)} val) =>
    _callback = callback

  fun apply(session: http.HTTPSession): http.HTTPHandler ref^ =>
    _OtlpResponseHandler(_callback)


class ref _OtlpResponseHandler is http.HTTPHandler
  let _callback: {(otel_sdk.ExportResult)} val
  var _status: U16 = 0
  var _done: Bool = false

  new ref create(callback: {(otel_sdk.ExportResult)} val) =>
    _callback = callback

  fun ref apply(payload: http.Payload val): Any =>
    _status = payload.status

  fun ref _complete(result: otel_sdk.ExportResult) =>
    if _done then return end
    _done = true
    _callback(result)

  fun ref finished() =>
    if (_status >= 200) and (_status < 300) then
      _complete(otel_sdk.ExportSuccess)
    else
      _complete(otel_sdk.ExportFailure)
    end

  fun ref cancelled() =>
    _complete(otel_sdk.ExportFailure)

  fun ref failed(reason: http.HTTPFailureReason) =>
    _complete(otel_sdk.ExportFailure)
