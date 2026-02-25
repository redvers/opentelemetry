use "pony_test"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"


class iso _TestCounterAdd is UnitTest
  fun name(): String => "Metrics/counter_add"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let counter = meter.counter("requests", "Total requests", "1")
      counter.add(I64(5))
      counter.add(I64(3))
      counter.add(F64(2.5))

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        hh.assert_eq[USize](1, metrics.size(), "Should have 1 metric")
        try
          let m = metrics(0)?
          hh.assert_eq[String]("requests", m.name)
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            hh.assert_eq[USize](1, points.size(), "Should have 1 data point")
            try
              hh.assert_eq[F64](10.5, points(0)?.value,
                "Sum should be 10.5")
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


class iso _TestUpDownCounterAdd is UnitTest
  fun name(): String => "Metrics/up_down_counter_add"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let counter = meter.up_down_counter("active_connections")
      counter.add(I64(10))
      counter.add(I64(-3))
      counter.add(I64(1))

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            try
              hh.assert_eq[F64](8, points(0)?.value,
                "Net sum should be 8")
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


class iso _TestHistogramRecord is UnitTest
  fun name(): String => "Metrics/histogram_record"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let hist = meter.histogram("request_duration", "", "ms")
      hist.record(F64(1.5))
      hist.record(F64(25.0))
      hist.record(F64(100.0))
      hist.record(F64(3.0))

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.HistogramDataPoint val] val =>
            try
              let p = points(0)?
              hh.assert_eq[U64](4, p.count, "Count should be 4")
              hh.assert_eq[F64](129.5, p.sum, "Sum should be 129.5")
              hh.assert_eq[F64](1.5, p.min_val, "Min should be 1.5")
              hh.assert_eq[F64](100.0, p.max_val, "Max should be 100.0")
              // Default bounds: [0;5;10;25;50;75;100;250;500;750;1000] = 11 bounds, 12 buckets
              hh.assert_eq[USize](12, p.bucket_counts.size(),
                "Should have 12 bucket counts (11 bounds + 1)")
              // Verify total count across buckets equals record count
              var bucket_total: U64 = 0
              for bc in p.bucket_counts.values() do
                bucket_total = bucket_total + bc
              end
              hh.assert_eq[U64](4, bucket_total,
                "Sum of bucket counts should equal record count")
            else
              hh.fail("Could not read histogram data point")
            end
          else
            hh.fail("Expected HistogramDataPoint array")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)


class iso _TestGaugeRecord is UnitTest
  fun name(): String => "Metrics/gauge_record"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let g = meter.gauge("temperature", "", "celsius")
      g.record(F64(20.0))
      g.record(F64(22.5))
      g.record(F64(19.0))

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            try
              hh.assert_eq[F64](19.0, points(0)?.value,
                "Gauge should report last value (19.0)")
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


class iso _TestCounterAttributes is UnitTest
  fun name(): String => "Metrics/counter_attributes"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.get_meter("test", {(meter: otel_api.Meter val)(provider, hh) =>
      let counter = meter.counter("requests")

      let attrs_a: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("method", "GET"))
        a
      end
      let attrs_b: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("method", "POST"))
        a
      end

      counter.add(I64(5), attrs_a)
      counter.add(I64(3), attrs_a)
      counter.add(I64(10), attrs_b)

      provider.collect({(metrics: Array[otel_sdk.MetricData val] val)(hh) =>
        try
          let m = metrics(0)?
          match m.data
          | let points: Array[otel_sdk.NumberDataPoint val] val =>
            hh.assert_eq[USize](2, points.size(),
              "Different attribute sets should produce separate data points")
          else
            hh.fail("Expected NumberDataPoint array")
          end
        else
          hh.fail("Could not read metric")
        end
        hh.complete(true)
      } val)
    } val)


class iso _TestNoopCounter is UnitTest
  fun name(): String => "Metrics/noop_counter"

  fun apply(h: TestHelper) =>
    let counter: otel_api.Counter val = otel_api.NoopCounter
    // Should not crash
    counter.add(I64(5))
    counter.add(F64(2.5))
    let attrs: otel_api.Attributes = recover val
      let a = Array[(String, otel_api.AttributeValue)]
      a.push(("key", "value"))
      a
    end
    counter.add(I64(1), attrs)


class iso _TestMeterProviderShutdown is UnitTest
  fun name(): String => "Metrics/meter_provider_shutdown"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkMeterProvider
    let hh: TestHelper = h

    provider.shutdown({(ok: Bool)(hh) =>
      hh.assert_true(ok, "Shutdown should succeed")
      hh.complete(true)
    } val)
