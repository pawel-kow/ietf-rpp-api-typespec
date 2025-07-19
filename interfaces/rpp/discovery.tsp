import "@typespec/http";
import "../../models/discovery.tsp";
import "../../models/headers.tsp";
import "../../models/errors.tsp";
import "./generic.tsp";

using TypeSpec.Http;
using rpp.headers;
using rpp.errors;
using rpp.discovery;

namespace rpp {
    @tag("Discovery")
    @route("/hello")
    @get op Hello(...RequestHeaders) : {...ResponseHeaders, ...HelloResponse} | ErrorResponse400_401_500;
}