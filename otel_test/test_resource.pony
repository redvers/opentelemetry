use "pony_test"
use otel_api = "../otel_api"

class iso _TestResourceMerge is UnitTest
  fun name(): String => "Resource/merge"

  fun apply(h: TestHelper) =>
    let r1 = otel_api.Resource(
      recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("service.name", "svc1"))
        a.push(("host.name", "host1"))
        a
      end)

    let r2 = otel_api.Resource(
      recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("service.name", "svc2"))
        a.push(("region", "us-east"))
        a
      end)

    let merged = r1.merge(r2)
    let attrs = merged.attributes()

    // r2's service.name should win
    h.assert_eq[USize](3, attrs.size(),
      "Merged should have 3 attributes (host.name, service.name, region)")

    var found_svc = false
    for (k, v) in attrs.values() do
      if k == "service.name" then
        match v
        | let s: String => h.assert_eq[String]("svc2", s,
            "r2's service.name should take precedence")
          found_svc = true
        end
      end
    end
    h.assert_true(found_svc, "service.name should be present in merged")
