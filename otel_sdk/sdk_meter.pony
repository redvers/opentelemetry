use otel_api = "../otel_api"

class val SdkMeter is otel_api.Meter
  """
  SDK implementation of `Meter`. Creates SDK instrument instances that record
  measurements through the owning `SdkMeterProvider`. Stateless (val) — holds
  a tag reference to the provider actor and the instrumentation scope identity.
  """
  let _provider: SdkMeterProvider tag
  let _name: String
  let _version: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    version': String = "")
  =>
    _provider = provider
    _name = name'
    _version = version'

  fun val counter(name: String, description: String = "",
    unit: String = ""): otel_api.Counter val
  =>
    SdkCounter(_provider, name, description, unit, _name, _version)

  fun val up_down_counter(name: String, description: String = "",
    unit: String = ""): otel_api.UpDownCounter val
  =>
    SdkUpDownCounter(_provider, name, description, unit, _name, _version)

  fun val histogram(name: String, description: String = "",
    unit: String = ""): otel_api.Histogram val
  =>
    SdkHistogram(_provider, name, description, unit, _name, _version)

  fun val gauge(name: String, description: String = "",
    unit: String = ""): otel_api.Gauge val
  =>
    SdkGauge(_provider, name, description, unit, _name, _version)
