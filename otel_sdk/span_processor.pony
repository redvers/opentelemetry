trait tag SpanProcessor
  """
  Receives span lifecycle events. Called by SdkTracerProvider when
  spans start and finish.
  """
  be on_start(span: ReadOnlySpan val)

  be on_end(span: ReadOnlySpan val)

  be shutdown(callback: {(Bool)} val)

  be force_flush(callback: {(Bool)} val)
