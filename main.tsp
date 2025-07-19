import "@typespec/openapi3";
import "@typespec/openapi";
import "@typespec/http";
import "./interfaces/rpp/generic.tsp";
import "./interfaces/rpp/domains.tsp";
import "./interfaces/rpp/contacts.tsp";
import "./interfaces/rpp/hosts.tsp";
import "./interfaces/rpp/messages.tsp";
import "./interfaces/rpp/discovery.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

@doc("RPP Testbed server")
@server("https://localhost:8000", "Local RPP Testbed server")
@info(#{
    title: "RPP Testbed",
    version: "0.0.1-dev",
    contact: #{
        name: "RPP WG",
        email: "rpp@ietf.org"
    }
})
@service
namespace rpp {
    // All interfaces in this namespace are imported from the `interfaces/rpp` directory.
}