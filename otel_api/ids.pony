use "format"
use "random"
use "time"

class val TraceId
  """
  128-bit trace identifier. All-zero is invalid (represents no trace).
  """
  let _bytes: Array[U8] val

  new val create(bytes': Array[U8] val) =>
    """
    Creates a `TraceId` from a 16-byte array. If the array is not exactly 16
    bytes, an all-zero (invalid) ID is used instead.
    """
    _bytes = if bytes'.size() == 16 then bytes' else
      recover val Array[U8].init(0, 16) end
    end

  new val generate() =>
    """
    Generates a random `TraceId` using the stdlib `Rand` PRNG seeded from
    wall-clock time.
    """
    _bytes = recover val
      (let s, let ns) = Time.now()
      let rand = Rand(s.u64(), ns.u64())
      let buf = Array[U8](16)
      buf.push_u64(rand.u64())
      buf.push_u64(rand.u64())
      buf
    end

  new val invalid() =>
    """
    Creates an all-zero `TraceId` representing the absence of a trace.
    """
    _bytes = recover val Array[U8].init(0, 16) end

  fun val bytes(): Array[U8] val =>
    """
    Returns the raw 16-byte representation.
    """
    _bytes

  fun val is_valid(): Bool =>
    """
    Returns `true` if any byte is non-zero.
    """
    try
      var i: USize = 0
      while i < 16 do
        if _bytes(i)? != 0 then return true end
        i = i + 1
      end
    end
    false

  fun val hex(): String =>
    """
    Returns the 32-character lowercase hex encoding.
    """
    let s = recover iso String(32) end
    try
      var i: USize = 0
      while i < 16 do
        s.append(Format.int[U8](_bytes(i)?
          where fmt = FormatHexSmallBare, width = 2, fill = '0'))
        i = i + 1
      end
    end
    consume s

  fun val eq(other: TraceId): Bool =>
    """
    Byte-wise equality comparison.
    """
    try
      var i: USize = 0
      while i < 16 do
        if _bytes(i)? != other._bytes(i)? then return false end
        i = i + 1
      end
      true
    else
      false
    end

  fun val ne(other: TraceId): Bool => not eq(other)

  fun val string(): String iso^ => hex().clone()


class val SpanId
  """
  64-bit span identifier. All-zero is invalid (represents no span).
  """
  let _bytes: Array[U8] val

  new val create(bytes': Array[U8] val) =>
    """
    Creates a `SpanId` from an 8-byte array. If the array is not exactly 8
    bytes, an all-zero (invalid) ID is used instead.
    """
    _bytes = if bytes'.size() == 8 then bytes' else
      recover val Array[U8].init(0, 8) end
    end

  new val generate() =>
    """
    Generates a random `SpanId` using the stdlib `Rand` PRNG seeded from
    wall-clock time.
    """
    _bytes = recover val
      (let s, let ns) = Time.now()
      let rand = Rand(s.u64(), ns.u64())
      let buf = Array[U8](8)
      buf.push_u64(rand.u64())
      buf
    end

  new val invalid() =>
    """
    Creates an all-zero `SpanId` representing the absence of a span.
    """
    _bytes = recover val Array[U8].init(0, 8) end

  fun val bytes(): Array[U8] val =>
    """
    Returns the raw 8-byte representation.
    """
    _bytes

  fun val is_valid(): Bool =>
    """
    Returns `true` if any byte is non-zero.
    """
    try
      var i: USize = 0
      while i < 8 do
        if _bytes(i)? != 0 then return true end
        i = i + 1
      end
    end
    false

  fun val hex(): String =>
    """
    Returns the 16-character lowercase hex encoding.
    """
    let s = recover iso String(16) end
    try
      var i: USize = 0
      while i < 8 do
        s.append(Format.int[U8](_bytes(i)?
          where fmt = FormatHexSmallBare, width = 2, fill = '0'))
        i = i + 1
      end
    end
    consume s

  fun val eq(other: SpanId): Bool =>
    """
    Byte-wise equality comparison.
    """
    try
      var i: USize = 0
      while i < 8 do
        if _bytes(i)? != other._bytes(i)? then return false end
        i = i + 1
      end
      true
    else
      false
    end

  fun val ne(other: SpanId): Bool => not eq(other)

  fun val string(): String iso^ => hex().clone()


class val SpanContext
  """
  Immutable context for a span: trace ID, span ID, trace flags, and trace state.
  """
  let trace_id: TraceId
  let span_id: SpanId
  let trace_flags: U8
  let trace_state: String
  let is_remote: Bool

  new val create(
    trace_id': TraceId,
    span_id': SpanId,
    trace_flags': U8 = 0x01,
    trace_state': String = "",
    is_remote': Bool = false)
  =>
    """
    Creates a `SpanContext` with the given identifiers. The `trace_flags`
    defaults to sampled (0x01). Set `is_remote` to `true` for contexts
    extracted from incoming requests.
    """
    trace_id = trace_id'
    span_id = span_id'
    trace_flags = trace_flags'
    trace_state = trace_state'
    is_remote = is_remote'

  new val invalid() =>
    """
    Creates an invalid `SpanContext` with zeroed IDs and no flags.
    """
    trace_id = TraceId.invalid()
    span_id = SpanId.invalid()
    trace_flags = 0
    trace_state = ""
    is_remote = false

  fun val is_valid(): Bool =>
    """
    Returns `true` when both the trace ID and span ID are non-zero.
    """
    trace_id.is_valid() and span_id.is_valid()

  fun val is_sampled(): Bool =>
    """
    Returns `true` when the sampled bit (0x01) is set in `trace_flags`.
    """
    (trace_flags and 0x01) == 0x01


primitive TraceFlags
  """
  Constants for the W3C trace flags byte.
  """
  fun sampled(): U8 => 0x01
