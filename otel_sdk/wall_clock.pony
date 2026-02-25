use "time"

primitive _WallClock
  fun nanos(): U64 =>
    (let sec, let nsec) = Time.now()
    ((sec.u64() * 1_000_000_000) + nsec.u64())
