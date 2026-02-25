use "pony_test"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"

class iso _TestAlwaysOnSampler is UnitTest
  fun name(): String => "Sampler/always_on"

  fun apply(h: TestHelper) =>
    let sampler: otel_sdk.AlwaysOnSampler val = otel_sdk.AlwaysOnSampler
    let ctx = otel_api.Context
    let trace_id = otel_api.TraceId.generate()
    let result = sampler.should_sample(ctx, trace_id, "test", otel_api.SpanKindInternal)
    h.assert_is[otel_sdk.SamplingDecision](
      result.decision, otel_sdk.SamplingDecisionRecordAndSample,
      "AlwaysOnSampler should return RecordAndSample")


class iso _TestAlwaysOffSampler is UnitTest
  fun name(): String => "Sampler/always_off"

  fun apply(h: TestHelper) =>
    let sampler: otel_sdk.AlwaysOffSampler val = otel_sdk.AlwaysOffSampler
    let ctx = otel_api.Context
    let trace_id = otel_api.TraceId.generate()
    let result = sampler.should_sample(ctx, trace_id, "test", otel_api.SpanKindInternal)
    h.assert_is[otel_sdk.SamplingDecision](
      result.decision, otel_sdk.SamplingDecisionDrop,
      "AlwaysOffSampler should return Drop")


class iso _TestTraceIdRatioSampler is UnitTest
  fun name(): String => "Sampler/trace_id_ratio"

  fun apply(h: TestHelper) =>
    // Ratio of 0 should always drop
    let zero_sampler: otel_sdk.TraceIdRatioSampler val = otel_sdk.TraceIdRatioSampler(0.0)
    let ctx = otel_api.Context
    var dropped: USize = 0
    var i: USize = 0
    while i < 100 do
      let tid = otel_api.TraceId.generate()
      let result = zero_sampler.should_sample(ctx, tid, "test",
        otel_api.SpanKindInternal)
      match result.decision
      | otel_sdk.SamplingDecisionDrop => dropped = dropped + 1
      end
      i = i + 1
    end
    h.assert_eq[USize](100, dropped, "Ratio 0.0 should drop all spans")

    // Ratio of 1 should always sample
    let one_sampler: otel_sdk.TraceIdRatioSampler val = otel_sdk.TraceIdRatioSampler(1.0)
    var sampled: USize = 0
    i = 0
    while i < 100 do
      let tid = otel_api.TraceId.generate()
      let result = one_sampler.should_sample(ctx, tid, "test",
        otel_api.SpanKindInternal)
      match result.decision
      | otel_sdk.SamplingDecisionRecordAndSample => sampled = sampled + 1
      end
      i = i + 1
    end
    h.assert_eq[USize](100, sampled, "Ratio 1.0 should sample all spans")


class iso _TestTraceIdRatioSamplerMidrange is UnitTest
  fun name(): String => "Sampler/trace_id_ratio_midrange"

  fun apply(h: TestHelper) =>
    let sampler: otel_sdk.TraceIdRatioSampler val =
      otel_sdk.TraceIdRatioSampler(0.5)
    let ctx = otel_api.Context
    var sampled: USize = 0
    var i: USize = 0
    while i < 1000 do
      let tid = otel_api.TraceId.generate()
      let result = sampler.should_sample(ctx, tid, "test",
        otel_api.SpanKindInternal)
      match result.decision
      | otel_sdk.SamplingDecisionRecordAndSample => sampled = sampled + 1
      end
      i = i + 1
    end
    h.assert_true((sampled >= 350) and (sampled <= 650),
      "Ratio 0.5 over 1000 traces should sample between 350 and 650, got " +
        sampled.string())
