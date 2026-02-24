use otel_api = "../otel_api"

class val TracerProviderConfig
  """
  Configuration for SdkTracerProvider.
  """
  let resource: otel_api.Resource
  let sampler: Sampler
  let id_generator: IdGenerator
  let span_limits: SpanLimits

  new val create(
    resource': otel_api.Resource = otel_api.Resource,
    sampler': Sampler = AlwaysOnSampler,
    id_generator': IdGenerator = RandomIdGenerator,
    span_limits': SpanLimits = SpanLimits)
  =>
    resource = resource'
    sampler = sampler'
    id_generator = id_generator'
    span_limits = span_limits'
