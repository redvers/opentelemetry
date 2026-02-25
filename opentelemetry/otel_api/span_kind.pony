primitive SpanKindInternal
  """
  Default span kind for internal operations with no remote parent or child.
  """
  fun string(): String iso^ => "Internal".clone()
  fun value(): U32 => 0

primitive SpanKindServer
  """
  Indicates the span covers server-side handling of a remote request.
  """
  fun string(): String iso^ => "Server".clone()
  fun value(): U32 => 1

primitive SpanKindClient
  """
  Indicates the span describes a request to a remote service.
  """
  fun string(): String iso^ => "Client".clone()
  fun value(): U32 => 2

primitive SpanKindProducer
  """
  Indicates the span describes the producer side of a message exchange.
  """
  fun string(): String iso^ => "Producer".clone()
  fun value(): U32 => 3

primitive SpanKindConsumer
  """
  Indicates the span describes the consumer side of a message exchange.
  """
  fun string(): String iso^ => "Consumer".clone()
  fun value(): U32 => 4

// Union of all span kind primitives. Describes the relationship between a span,
// its parent, and its children in a distributed trace.
type SpanKind is
  ( SpanKindInternal
  | SpanKindServer
  | SpanKindClient
  | SpanKindProducer
  | SpanKindConsumer )
