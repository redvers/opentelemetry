"""
# otel_sdk

Concrete SDK implementations of the `otel_api` traits. Provides the machinery
to record, process, and export telemetry data for all three signals.

## Key types

### Tracing
- `SdkTracerProvider` — actor that manages span processors and produces
  `SdkTracer` instances
- `TracerProviderConfig` — groups `Resource`, `Sampler`, `IdGenerator`, and
  `SpanLimits` for provider construction
- `SdkTracer` — creates `SdkSpan` instances, applies sampling decisions
- `SdkSpan` — mutable span that freezes into a `ReadOnlySpan` on `finish()`
- `SimpleSpanProcessor` / `BatchSpanProcessor` — forward finished spans to a
  `SpanExporter`
- `AlwaysOnSampler`, `AlwaysOffSampler`, `TraceIdRatioSampler` — sampling
  strategies

### Metrics
- `SdkMeterProvider` — actor that accumulates measurements and produces
  `MetricData` snapshots via `collect()`
- `SdkCounter`, `SdkUpDownCounter`, `SdkHistogram`, `SdkGauge` — synchronous
  instrument implementations
- `PeriodicMetricReader` — timer-driven reader that collects and exports metrics

### Logs
- `SdkLoggerProvider` — actor that manages log record processors
- `SdkLogger` — builds `LogRecordData` and routes it through processors
- `SimpleLogRecordProcessor` / `BatchLogRecordProcessor` — forward log records
  to a `LogRecordExporter`

## Example

```pony
use "net"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"
use otel_otlp = "otel_otlp"

actor Main
  new create(env: Env) =>
    let auth = TCPConnectAuth(env.root)
    let exporter = otel_otlp.OtlpSpanExporter(auth)
    let processor = otel_sdk.BatchSpanProcessor(exporter)
    let config = otel_sdk.TracerProviderConfig(
      where sampler' = otel_sdk.AlwaysOnSampler)
    let provider = otel_sdk.SdkTracerProvider(config,
      recover val [processor] end)

    provider.get_tracer("my-service",
      {(tracer: otel_api.Tracer val) =>
        (let span, let ctx) = tracer.start_span("handle-request")
        span.set_attribute("http.method", "GET")
        span.finish()
      })
```
"""
