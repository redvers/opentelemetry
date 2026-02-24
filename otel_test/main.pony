use "pony_test"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"
use otel_otlp = "../otel_otlp"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestTraceIdGenerate)
    test(_TestTraceIdHex)
    test(_TestTraceIdInvalid)
    test(_TestSpanIdGenerate)
    test(_TestSpanIdHex)
    test(_TestSpanIdInvalid)
    test(_TestSpanContextValid)
    test(_TestSpanContextInvalid)
    test(_TestSpanContextSampled)
    test(_TestContextImmutability)
    test(_TestContextWithEntry)
    test(_TestResourceMerge)
    test(_TestSpanStatusDescription)
    test(_TestAlwaysOnSampler)
    test(_TestAlwaysOffSampler)
    test(_TestTraceIdRatioSampler)
    test(_TestSdkSpanFinish)
    test(_TestSdkSpanDoubleFinish)
    test(_TestSdkSpanAttributes)
    test(_TestSdkSpanEvents)
    test(_TestSdkSpanStatusPrecedence)
    test(_TestOtlpJsonEncoderBasic)
