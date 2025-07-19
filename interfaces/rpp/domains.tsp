import "@typespec/http";
import "../../models/domain.tsp";
import "./generic.tsp";

using TypeSpec.Http;
using rpp.interfaces.generic;

namespace rpp {
    @tag("Domains")
    @route("/domains")
    @useAuth(BasicAuth)
    interface domains 
        extends EntityCollection<rpp.domain.Domain, rpp.domain.Domain>, EntityCollectionTransferrable<rpp.domain.DomainTransfer, rpp.domain.DomainTransfer>,
            EntityCollectionRenewable<rpp.domain.DomainRenewal, rpp.domain.DomainRenewal>,
            EntityCollectionDeleteable<rpp.domain.Domain, rpp.domain.DomainDeletion> {
    }
}