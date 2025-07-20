import "@typespec/http";
import "../../models/contact.tsp";
import "./entitycollections/main.tsp";

using TypeSpec.Http;
using rpp.interfaces.generic.entitycollections;

namespace rpp {
    @tag("Hosts")
    @route("/hosts")
    @useAuth(BasicAuth)
    interface hosts extends EntityCollection<rpp.host.Host, rpp.host.Host> {
    }
}