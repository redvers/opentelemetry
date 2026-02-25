use "pony_test"
use "pony_check"
use "random"
use "time"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"


primitive _PropBytes
  """Convert numeric types to byte arrays for ID construction."""

  fun u128_to_trace_id_bytes(n: U128): Array[U8] val =>
    recover val
      let b = Array[U8](16)
      b.push_u128(n)
      b
    end

  fun u64_to_span_id_bytes(n: U64): Array[U8] val =>
    recover val
      let b = Array[U8](8)
      b.push_u64(n)
      b
    end


class iso _TestPropTraceIdHex is UnitTest
  fun name(): String => "Property/trace_id_hex"

  fun apply(h: TestHelper) ? =>
    PonyCheck.for_all[U128](
      recover Generators.u128() end, h)(
      {(n, ph) =>
        let bytes = _PropBytes.u128_to_trace_id_bytes(n)
        let hex = otel_api.TraceId(bytes).hex()
        ph.assert_eq[USize](32, hex.size(), "TraceId hex must be 32 chars")
        for c in hex.values() do
          ph.assert_true(
            ((c >= '0') and (c <= '9')) or ((c >= 'a') and (c <= 'f')),
            "TraceId hex char must be lowercase hex")
        end
      })?

    PonyCheck.for_all[U64](
      recover Generators.u64() end, h)(
      {(n, ph) =>
        let bytes = _PropBytes.u64_to_span_id_bytes(n)
        let hex = otel_api.SpanId(bytes).hex()
        ph.assert_eq[USize](16, hex.size(), "SpanId hex must be 16 chars")
        for c in hex.values() do
          ph.assert_true(
            ((c >= '0') and (c <= '9')) or ((c >= 'a') and (c <= 'f')),
            "SpanId hex char must be lowercase hex")
        end
      })?


class iso _TestPropIdValidity is UnitTest
  fun name(): String => "Property/id_validity"

  fun apply(h: TestHelper) ? =>
    PonyCheck.for_all[U128](
      recover Generators.u128() end, h)(
      {(n, ph) =>
        let bytes = _PropBytes.u128_to_trace_id_bytes(n)
        let id = otel_api.TraceId(bytes)
        ph.assert_eq[Bool](n != 0, id.is_valid(),
          "is_valid() must be true iff at least one byte is non-zero")
      })?


class iso _TestPropIdEquality is UnitTest
  fun name(): String => "Property/id_equality"

  fun apply(h: TestHelper) ? =>
    PonyCheck.for_all2[U128, U128](
      recover Generators.u128() end,
      recover Generators.u128() end,
      h)(
      {(n1, n2, ph) =>
        let a = otel_api.TraceId(_PropBytes.u128_to_trace_id_bytes(n1))
        let b = otel_api.TraceId(_PropBytes.u128_to_trace_id_bytes(n2))
        ph.assert_eq[Bool](a.eq(b), not a.ne(b),
          "eq and ne must be complements")
        ph.assert_true(a.eq(a), "TraceId must equal itself")
      })?


class iso _TestPropIsSampled is UnitTest
  fun name(): String => "Property/is_sampled"

  fun apply(h: TestHelper) ? =>
    PonyCheck.for_all[U8](
      recover Generators.u8() end, h)(
      {(flags, ph) =>
        let sc = otel_api.SpanContext(
          otel_api.TraceId.generate(),
          otel_api.SpanId.generate(),
          flags)
        ph.assert_eq[Bool]((flags and 0x01) == 0x01, sc.is_sampled(),
          "is_sampled must reflect bit 0 of trace_flags")
      })?


class iso _TestPropAlwaysOnSampler is UnitTest
  fun name(): String => "Property/always_on_sampler"

  fun apply(h: TestHelper) ? =>
    let sampler: otel_sdk.AlwaysOnSampler val = otel_sdk.AlwaysOnSampler
    PonyCheck.for_all2[U128, String](
      recover Generators.u128() end,
      recover Generators.ascii_printable(1, 50) end,
      h)(
      {(n, span_name, ph)(sampler) =>
        let trace_id = otel_api.TraceId(_PropBytes.u128_to_trace_id_bytes(n))
        let result = sampler.should_sample(
          otel_api.Context, trace_id, span_name, otel_api.SpanKindInternal)
        match result.decision
        | otel_sdk.SamplingDecisionRecordAndSample => None
        else
          ph.fail("AlwaysOnSampler must return RecordAndSample")
        end
      })?


class iso _TestPropAlwaysOffSampler is UnitTest
  fun name(): String => "Property/always_off_sampler"

  fun apply(h: TestHelper) ? =>
    let sampler: otel_sdk.AlwaysOffSampler val = otel_sdk.AlwaysOffSampler
    PonyCheck.for_all2[U128, String](
      recover Generators.u128() end,
      recover Generators.ascii_printable(1, 50) end,
      h)(
      {(n, span_name, ph)(sampler) =>
        let trace_id = otel_api.TraceId(_PropBytes.u128_to_trace_id_bytes(n))
        let result = sampler.should_sample(
          otel_api.Context, trace_id, span_name, otel_api.SpanKindInternal)
        match result.decision
        | otel_sdk.SamplingDecisionDrop => None
        else
          ph.fail("AlwaysOffSampler must return Drop")
        end
      })?


class iso _TestPropRatioSamplerDeterminism is UnitTest
  fun name(): String => "Property/ratio_sampler_determinism"

  fun apply(h: TestHelper) ? =>
    let sampler: otel_sdk.TraceIdRatioSampler val =
      otel_sdk.TraceIdRatioSampler(0.5)
    let ctx: otel_api.Context val = otel_api.Context
    PonyCheck.for_all[U128](
      recover Generators.u128() end, h)(
      {(n, ph)(sampler, ctx) =>
        let trace_id = otel_api.TraceId(_PropBytes.u128_to_trace_id_bytes(n))
        let r1 = sampler.should_sample(ctx, trace_id, "test",
          otel_api.SpanKindInternal)
        let r2 = sampler.should_sample(ctx, trace_id, "test",
          otel_api.SpanKindInternal)
        let d1 = match r1.decision
          | otel_sdk.SamplingDecisionRecordAndSample => true
          else false
          end
        let d2 = match r2.decision
          | otel_sdk.SamplingDecisionRecordAndSample => true
          else false
          end
        ph.assert_eq[Bool](d1, d2,
          "Same TraceId must produce the same sampling decision")
      })?


class iso _TestPropCounterLinearity is UnitTest
  fun name(): String => "Property/counter_linearity"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    (let s, let ns) = Time.now()
    let values: Array[F64] val = recover val
      let rand = Rand(s.u64(), ns.u64())
      let count = rand.int[USize](20) + 5
      let vals = Array[F64](count)
      var i: USize = 0
      while i < count do
        vals.push(rand.int[U32](10000).f64() / 100.0)
        i = i + 1
      end
      vals
    end

    var expected_sum: F64 = 0
    for v in values.values() do
      expected_sum = expected_sum + v
    end

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h
    let exp = expected_sum

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh,
      values, exp) =>
      let counter = meter.counter("prop_requests", "Total", "1")
      for v in values.values() do
        counter.add(v)
      end

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh,
        exp) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            try
              let actual = points(0)?.value
              let diff = (actual - exp).abs()
              hh.assert_true(diff < 0.001,
                "Counter sum " + actual.string() +
                " should equal " + exp.string())
            else
              hh.fail("Could not read data point")
            end
          else
            hh.fail("Expected NumberDataPoint array")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)


class iso _TestPropGaugeLastValue is UnitTest
  fun name(): String => "Property/gauge_last_value"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    (let s, let ns) = Time.now()
    let values: Array[F64] val = recover val
      let rand = Rand(s.u64(), ns.u64())
      let count = rand.int[USize](10) + 3
      let vals = Array[F64](count)
      var i: USize = 0
      while i < count do
        vals.push(rand.int[U32](10000).f64() / 100.0)
        i = i + 1
      end
      vals
    end

    let last: F64 = try values(values.size() - 1)? else 0.0 end

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh,
      values, last) =>
      let g = meter.gauge("prop_temperature", "", "celsius")
      for v in values.values() do
        g.record(v)
      end

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh,
        last) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            try
              hh.assert_eq[F64](last, points(0)?.value,
                "Gauge should report last recorded value")
            else
              hh.fail("Could not read data point")
            end
          else
            hh.fail("Expected NumberDataPoint array")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)


class iso _TestPropAttributePermutation is UnitTest
  fun name(): String => "Property/attribute_permutation"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    (let s, let ns) = Time.now()
    let rand = Rand(s.u64(), ns.u64())
    let r1 = rand.int[U32](99999)
    let r2 = rand.int[U32](99999)
    let r3 = rand.int[U32](99999)

    let attrs_fwd: otel_api.Attributes = recover val
      let a = Array[(String, otel_api.AttributeValue)]
      a.push(("key_" + r1.string(), "v1"))
      a.push(("key_" + r2.string(), "v2"))
      a.push(("key_" + r3.string(), "v3"))
      a
    end
    let attrs_rev: otel_api.Attributes = recover val
      let a = Array[(String, otel_api.AttributeValue)]
      a.push(("key_" + r3.string(), "v3"))
      a.push(("key_" + r2.string(), "v2"))
      a.push(("key_" + r1.string(), "v1"))
      a
    end

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh,
      attrs_fwd, attrs_rev) =>
      let counter = meter.counter("prop_requests")
      counter.add(I64(5), attrs_fwd)
      counter.add(I64(3), attrs_rev)

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            hh.assert_eq[USize](1, points.size(),
              "Same attributes in different order should produce one data point")
            try
              hh.assert_eq[F64](8.0, points(0)?.value,
                "Sum should be 8.0 (both adds merged)")
            else
              hh.fail("Could not read data point")
            end
          else
            hh.fail("Expected NumberDataPoint array")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)
