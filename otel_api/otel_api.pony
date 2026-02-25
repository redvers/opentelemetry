"""
# otel_api

Zero-dependency API package for OpenTelemetry in Pony. Defines traits and types
for the three telemetry signals — tracing, metrics, and logs — without pulling
in any SDK or exporter dependencies.

Application code instruments against these traits. At runtime, an SDK package
such as `otel_sdk` provides concrete implementations; without one, the noop
implementations in this package silently discard all telemetry.

## Key types

### Tracing
- `TracerProvider` — entry point for obtaining `Tracer` instances
- `Tracer` — creates `Span` instances
- `Span` — records a unit of work with attributes, events, and status
- `SpanContext` — immutable identity (trace ID, span ID, flags) carried across
  actors via `Context`

### Metrics
- `MeterProvider` — entry point for obtaining `Meter` instances
- `Meter` — creates instrument instances
- `Counter`, `UpDownCounter`, `Histogram`, `Gauge` — synchronous instruments

### Logs
- `LoggerProvider` — entry point for obtaining `Logger` instances
- `Logger` — emits log records with severity, body, and trace correlation

## Example

```pony
actor Main
  new create(env: Env) =>
    let provider: TracerProvider = NoopTracerProvider
    provider.get_tracer("my-library",
      {(tracer: Tracer val) =>
        (let span, let ctx) = tracer.start_span("do-work")
        span.set_attribute("key", "value")
        span.finish()
      })
```
"""
