trait tag SpanProcessor
  """
  Receives span lifecycle events. Called by SdkTracerProvider when
  spans start and finish.
  """
  be on_start(span: ReadOnlySpan val)
    """
    Called when a span starts. Receives an immutable snapshot of the span's
    initial state.
    """

  be on_end(span: ReadOnlySpan val)
    """
    Called when a span finishes. Receives the completed `ReadOnlySpan` for
    processing and export.
    """

  be shutdown(callback: {(Bool)} val)
    """
    Shuts down the processor. The callback receives `true` on success.
    """

  be force_flush(callback: {(Bool)} val)
    """
    Forces the processor to export any buffered spans immediately.
    """
