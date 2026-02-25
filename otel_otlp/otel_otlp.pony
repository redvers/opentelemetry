"""
# otel_otlp

OTLP HTTP/JSON exporters for all three telemetry signals. Encodes telemetry
data into the OpenTelemetry Protocol JSON format and sends it to a collector
endpoint via HTTP POST.

Depends on `ponylang/http` for HTTP transport and `ponylang/json` for JSON
encoding.

## Key types

- `OtlpConfig` — endpoint URL, signal paths, timeout, and custom headers
- `OtlpSpanExporter` — implements `SpanExporter`, sends trace data
- `OtlpMetricExporter` — implements `MetricExporter`, sends metric data
- `OtlpLogExporter` — implements `LogRecordExporter`, sends log data
- `OtlpJsonEncoder` — stateless primitive that encodes spans to OTLP JSON
- `OtlpMetricEncoder` — stateless primitive that encodes metrics to OTLP JSON
- `OtlpLogEncoder` — stateless primitive that encodes logs to OTLP JSON

## Example

```pony
use "net"
use otel_sdk = "otel_sdk"
use otel_otlp = "otel_otlp"

actor Main
  new create(env: Env) =>
    let auth = TCPConnectAuth(env.root)
    let config = otel_otlp.OtlpConfig(
      where endpoint' = "http://localhost:4318",
            timeout_ms' = 5000)
    let exporter = otel_otlp.OtlpSpanExporter(auth, config)
    let processor = otel_sdk.SimpleSpanProcessor(exporter)
```
"""
