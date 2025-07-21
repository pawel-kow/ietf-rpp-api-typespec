import "@typespec/http";
import "../../models/domain.tsp";
import "../../models/common.tsp";
import "./entitycollections/main.tsp";
import "./entitycollections/transferrable.tsp";
import "./entitycollections/deleteable.tsp";
import "./entitycollections/renewable.tsp";

using TypeSpec.Http;
using rpp.interfaces.generic.entitycollections;

namespace rpp {
    @tag("Domains")
    @route("/domains")
    @useAuth(BasicAuth)
    interface domains 
        extends EntityCollection<rpp.domain.Domain, rpp.domain.Domain, rpp.domain.DomainMinimal>, EntityCollectionTransferrable<rpp.domain.DomainTransfer, rpp.common.TransferAck, rpp.common.TransferNack, rpp.domain.DomainTransfer>,
            EntityCollectionRenewable<rpp.domain.DomainRenewal, rpp.domain.DomainRenewal>,
            EntityCollectionDeleteable<rpp.domain.Domain, rpp.domain.DomainDeletion> {
    }
}