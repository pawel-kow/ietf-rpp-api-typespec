import "./resources/domain-name/model.tsp";
import "./resources/domain-name/update/input.tsp";

import "@typespec/openapi3";
import "@typespec/openapi";
import "@typespec/http";

import "../interfaces/rpp/entitycollections/main.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

using rpp.interfaces.generic.entitycollections;


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
    @tag("Domains")
    @route("/domains")
    @useAuth(BasicAuth)
    interface domains 
        extends EntityCollection<rpp.gen.domainName.Model, rpp.gen.domainName.Model, rpp.gen.domainName.update.input> {
    }
}