import "@typespec/http";
import "../../models/contact.tsp";
import "./generic.tsp";

using TypeSpec.Http;
using rpp.interfaces.generic;

namespace rpp {
    @tag("Hosts")
    @route("/hosts")
    @useAuth(BasicAuth)
    interface hosts extends EntityCollection<rpp.host.Host, rpp.host.Host> {
    }
}