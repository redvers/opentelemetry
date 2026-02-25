use "pony_test"
use json = "../_corral/github_com_ponylang_json/json"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"
use otel_otlp = "../otel_otlp"


class iso _TestCounterRejectsNegative is UnitTest
  fun name(): String => "Metrics/counter_rejects_negative"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let counter = meter.counter("requests")
      counter.add(I64(10))
      counter.add(I64(-5))   // Should be silently dropped
      counter.add(F64(-1.0)) // Should be silently dropped
      counter.add(I64(3))

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            try
              hh.assert_eq[F64](13.0, points(0)?.value,
                "Sum should be 13.0 (negative values dropped)")
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


class iso _TestInstrumentKindConflict is UnitTest
  fun name(): String => "Metrics/instrument_kind_conflict"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      // Create a counter named "foo"
      let counter = meter.counter("foo")
      counter.add(I64(10))

      // Create a histogram with the same name — its recordings should be
      // silently dropped because the name is already registered as a counter
      let hist = meter.histogram("foo")
      hist.record(F64(99.0))

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        hh.assert_eq[USize](1, metrics.size(), "Should have 1 metric")
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            hh.assert_eq[USize](1, points.size(),
              "Should have 1 data point (counter only)")
            try
              hh.assert_eq[F64](10.0, points(0)?.value,
                "Counter sum should be 10.0 (histogram value dropped)")
            else
              hh.fail("Could not read data point")
            end
          else
            hh.fail("Expected NumberDataPoint array (counter)")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)


class iso _TestResourceGrouping is UnitTest
  fun name(): String => "OtlpJsonEncoder/resource_grouping"

  fun apply(h: TestHelper) ? =>
    let trace_id = otel_api.TraceId.generate()
    let span_id_1 = otel_api.SpanId.generate()
    let span_id_2 = otel_api.SpanId.generate()

    // Two different resources with same (empty) schema_url
    let resource_a = otel_api.Resource(
      recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("service.name", "service-a"))
        a
      end)
    let resource_b = otel_api.Resource(
      recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("service.name", "service-b"))
        a
      end)

    let sc1 = otel_api.SpanContext(trace_id, span_id_1)
    let sc2 = otel_api.SpanContext(trace_id, span_id_2)

    let empty_attrs: otel_api.Attributes = recover val
      Array[(String, otel_api.AttributeValue)]
    end
    let empty_events: Array[otel_api.SpanEvent] val = recover val
      Array[otel_api.SpanEvent]
    end

    let ro1 = otel_sdk.ReadOnlySpan(
      "span-a", sc1, otel_api.SpanId.invalid(), otel_api.SpanKindInternal,
      1000000, 2000000,
      otel_api.SpanStatus(otel_api.SpanStatusOk),
      empty_attrs, empty_events, resource_a, "lib", "1.0")
    let ro2 = otel_sdk.ReadOnlySpan(
      "span-b", sc2, otel_api.SpanId.invalid(), otel_api.SpanKindInternal,
      1000000, 2000000,
      otel_api.SpanStatus(otel_api.SpanStatusOk),
      empty_attrs, empty_events, resource_b, "lib", "1.0")

    let spans: Array[otel_sdk.ReadOnlySpan val] val = recover val
      [ro1; ro2]
    end
    let json_str = otel_otlp.OtlpJsonEncoder.encode_spans(spans)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    match doc.data
    | let obj: json.JsonObject =>
      match try obj.data("resourceSpans")? end
      | let rs_arr: json.JsonArray =>
        h.assert_eq[USize](2, rs_arr.data.size(),
          "Different resources should produce separate resourceSpans entries")
      else h.fail("Expected resourceSpans array")
      end
    else h.fail("Expected top-level JSON object")
    end


class iso _TestAttributeOrderIndependence is UnitTest
  fun name(): String => "Metrics/attribute_order_independence"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let counter = meter.counter("requests")

      // Same attributes in different order should map to the same data point
      let attrs_ab: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("method", "GET"))
        a.push(("status", I64(200)))
        a
      end
      let attrs_ba: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("status", I64(200)))
        a.push(("method", "GET"))
        a
      end

      counter.add(I64(5), attrs_ab)
      counter.add(I64(3), attrs_ba)

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


class iso _TestAttributeSerializationArrays is UnitTest
  fun name(): String => "Metrics/attribute_serialization_arrays"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let counter = meter.counter("requests")

      let attrs_a: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        let tags_a: Array[String] val = recover val ["web"; "prod"] end
        a.push(("tags", tags_a))
        a
      end
      let attrs_b: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        let tags_b: Array[String] val = recover val ["api"; "staging"] end
        a.push(("tags", tags_b))
        a
      end

      counter.add(I64(5), attrs_a)
      counter.add(I64(10), attrs_b)

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            hh.assert_eq[USize](2, points.size(),
              "Different array attributes should produce separate data points")
          else
            hh.fail("Expected NumberDataPoint array")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)


class iso _TestAttributeSerializationDelimiters is UnitTest
  fun name(): String => "Metrics/attribute_serialization_delimiters"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let counter = meter.counter("delim_test")

      // These would collide under naive key=value serialization
      let attrs_a: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("x", "y=z"))
        a
      end
      let attrs_b: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("x=y", "z"))
        a
      end

      counter.add(I64(1), attrs_a)
      counter.add(I64(2), attrs_b)

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            hh.assert_eq[USize](2, points.size(),
              "Attributes with delimiters in keys/values must not collide")
          else
            hh.fail("Expected NumberDataPoint array")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)
