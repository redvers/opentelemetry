use "time"

primitive _WallClock
  """
  Returns the current wall-clock time as nanoseconds since the Unix epoch.
  """
  fun nanos(): U64 =>
    (let sec, let nsec) = Time.now()
    ((sec.u64() * 1_000_000_000) + nsec.u64())
