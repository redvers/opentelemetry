use "pony_test"
use json = "../_corral/github_com_ponylang_json/json"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"
use otel_otlp = "../otel_otlp"


class iso _TestOtlpMetricEncoderSum is UnitTest
  fun name(): String => "OtlpMetricEncoder/sum"

  fun apply(h: TestHelper) ? =>
    let points: Array[otel_sdk.NumberDataPoint val] val = recover val
      [otel_sdk.NumberDataPoint(
        recover val Array[(String, otel_api.AttributeValue)] end,
        1000, 2000, 42.5)]
    end

    let metric = otel_sdk.MetricData(
      "http.requests",
      "Total HTTP requests",
      "1",
      otel_api.InstrumentKindCounter,
      points)

    let metrics: Array[otel_sdk.MetricData val] val = recover val
      [metric]
    end

    let json_str = otel_otlp.OtlpMetricEncoder.encode_metrics(metrics)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    match doc.data
    | let root: json.JsonObject =>
      match try root.data("resourceMetrics")? end
      | let rm_arr: json.JsonArray =>
        h.assert_eq[USize](1, rm_arr.data.size())

        match try rm_arr.data(0)? end
        | let rm_obj: json.JsonObject =>
          match try rm_obj.data("scopeMetrics")? end
          | let sm_arr: json.JsonArray =>
            match try sm_arr.data(0)? end
            | let sm_obj: json.JsonObject =>
              match try sm_obj.data("metrics")? end
              | let m_arr: json.JsonArray =>
                h.assert_eq[USize](1, m_arr.data.size())

                match try m_arr.data(0)? end
                | let m_obj: json.JsonObject =>
                  match try m_obj.data("name")? end
                  | let n: String =>
                    h.assert_eq[String]("http.requests", n)
                  else h.fail("name should be a string")
                  end

                  match try m_obj.data("sum")? end
                  | let sum_obj: json.JsonObject =>
                    match try sum_obj.data("isMonotonic")? end
                    | let mono: Bool =>
                      h.assert_true(mono,
                        "Counter sum should be monotonic")
                    else h.fail("isMonotonic should be bool")
                    end

                    match try sum_obj.data("dataPoints")? end
                    | let dp_arr: json.JsonArray =>
                      h.assert_eq[USize](1, dp_arr.data.size())

                      match try dp_arr.data(0)? end
                      | let dp_obj: json.JsonObject =>
                        match try dp_obj.data("asDouble")? end
                        | let v: F64 =>
                          h.assert_eq[F64](42.5, v)
                        else h.fail("asDouble should be F64")
                        end
                      else h.fail("Expected data point object")
                      end
                    else h.fail("Expected dataPoints array")
                    end
                  else h.fail("Expected sum object")
                  end
                else h.fail("Expected metric object")
                end
              else h.fail("Expected metrics array")
              end
            else h.fail("Expected scopeMetrics object")
            end
          else h.fail("Expected scopeMetrics array")
          end
        else h.fail("Expected resourceMetrics object")
        end
      else h.fail("Expected resourceMetrics array")
      end
    else h.fail("Expected top-level JSON object")
    end


class iso _TestOtlpMetricEncoderHistogram is UnitTest
  fun name(): String => "OtlpMetricEncoder/histogram"

  fun apply(h: TestHelper) ? =>
    let bounds: Array[F64] val = recover val [10; 50; 100] end
    let bucket_counts: Array[U64] val = recover val [U64(2); 1; 1; 0] end

    let points: Array[otel_sdk.HistogramDataPoint val] val = recover val
      [otel_sdk.HistogramDataPoint(
        recover val Array[(String, otel_api.AttributeValue)] end,
        1000, 2000,
        4, 129.5,
        bucket_counts, bounds,
        1.5, 100.0)]
    end

    let metric = otel_sdk.MetricData(
      "request.duration",
      "Request duration",
      "ms",
      otel_api.InstrumentKindHistogram,
      points)

    let metrics: Array[otel_sdk.MetricData val] val = recover val
      [metric]
    end

    let json_str = otel_otlp.OtlpMetricEncoder.encode_metrics(metrics)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    match doc.data
    | let root: json.JsonObject =>
      match try root.data("resourceMetrics")? end
      | let rm_arr: json.JsonArray =>
        match try rm_arr.data(0)? end
        | let rm_obj: json.JsonObject =>
          match try rm_obj.data("scopeMetrics")? end
          | let sm_arr: json.JsonArray =>
            match try sm_arr.data(0)? end
            | let sm_obj: json.JsonObject =>
              match try sm_obj.data("metrics")? end
              | let m_arr: json.JsonArray =>
                match try m_arr.data(0)? end
                | let m_obj: json.JsonObject =>
                  match try m_obj.data("histogram")? end
                  | let hist_obj: json.JsonObject =>
                    match try hist_obj.data("dataPoints")? end
                    | let dp_arr: json.JsonArray =>
                      h.assert_eq[USize](1, dp_arr.data.size())

                      match try dp_arr.data(0)? end
                      | let dp_obj: json.JsonObject =>
                        match try dp_obj.data("count")? end
                        | let c: String =>
                          h.assert_eq[String]("4", c, "Count should be 4")
                        else h.fail("count should be String")
                        end

                        match try dp_obj.data("sum")? end
                        | let s: F64 =>
                          h.assert_eq[F64](129.5, s, "Sum should be 129.5")
                        else h.fail("sum should be F64")
                        end

                        match try dp_obj.data("bucketCounts")? end
                        | let bc_arr: json.JsonArray =>
                          h.assert_eq[USize](4, bc_arr.data.size(),
                            "Should have 4 bucket counts")
                        else h.fail("Expected bucketCounts array")
                        end

                        match try dp_obj.data("explicitBounds")? end
                        | let eb_arr: json.JsonArray =>
                          h.assert_eq[USize](3, eb_arr.data.size(),
                            "Should have 3 bounds")
                        else h.fail("Expected explicitBounds array")
                        end
                      else h.fail("Expected data point object")
                      end
                    else h.fail("Expected dataPoints array")
                    end
                  else h.fail("Expected histogram object")
                  end
                else h.fail("Expected metric object")
                end
              else h.fail("Expected metrics array")
              end
            else h.fail("Expected scopeMetrics object")
            end
          else h.fail("Expected scopeMetrics array")
          end
        else h.fail("Expected resourceMetrics object")
        end
      else h.fail("Expected resourceMetrics array")
      end
    else h.fail("Expected top-level JSON object")
    end


class iso _TestOtlpMetricEncoderGauge is UnitTest
  fun name(): String => "OtlpMetricEncoder/gauge"

  fun apply(h: TestHelper) ? =>
    let points: Array[otel_sdk.NumberDataPoint val] val = recover val
      [otel_sdk.NumberDataPoint(
        recover val Array[(String, otel_api.AttributeValue)] end,
        1000, 2000, 19.0)]
    end

    let metric = otel_sdk.MetricData(
      "temperature",
      "Current temperature",
      "celsius",
      otel_api.InstrumentKindGauge,
      points)

    let metrics: Array[otel_sdk.MetricData val] val = recover val
      [metric]
    end

    let json_str = otel_otlp.OtlpMetricEncoder.encode_metrics(metrics)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    match doc.data
    | let root: json.JsonObject =>
      match try root.data("resourceMetrics")? end
      | let rm_arr: json.JsonArray =>
        match try rm_arr.data(0)? end
        | let rm_obj: json.JsonObject =>
          match try rm_obj.data("scopeMetrics")? end
          | let sm_arr: json.JsonArray =>
            match try sm_arr.data(0)? end
            | let sm_obj: json.JsonObject =>
              match try sm_obj.data("metrics")? end
              | let m_arr: json.JsonArray =>
                match try m_arr.data(0)? end
                | let m_obj: json.JsonObject =>
                  match try m_obj.data("gauge")? end
                  | let gauge_obj: json.JsonObject =>
                    match try gauge_obj.data("dataPoints")? end
                    | let dp_arr: json.JsonArray =>
                      h.assert_eq[USize](1, dp_arr.data.size())

                      match try dp_arr.data(0)? end
                      | let dp_obj: json.JsonObject =>
                        match try dp_obj.data("asDouble")? end
                        | let v: F64 =>
                          h.assert_eq[F64](19.0, v,
                            "Gauge should be 19.0")
                        else h.fail("asDouble should be F64")
                        end
                      else h.fail("Expected data point object")
                      end
                    else h.fail("Expected dataPoints array")
                    end
                  else h.fail("Expected gauge object")
                  end
                else h.fail("Expected metric object")
                end
              else h.fail("Expected metrics array")
              end
            else h.fail("Expected scopeMetrics object")
            end
          else h.fail("Expected scopeMetrics array")
          end
        else h.fail("Expected resourceMetrics object")
        end
      else h.fail("Expected resourceMetrics array")
      end
    else h.fail("Expected top-level JSON object")
    end
