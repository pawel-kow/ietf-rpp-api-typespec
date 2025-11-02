import "@typespec/http";
import "../../models/domain.tsp";
import "../../models/common.tsp";
import "./entitycollections/main.tsp";
import "./entitycollections/transferrable.tsp";
import "./entitycollections/deleteable.tsp";
import "./entitycollections/renewable.tsp";

using TypeSpec.Http;
using rpp.interfaces.generic.entitycollections;
using rpp.domain;

namespace rpp {
    @tag("Domains")
    @route("/domains")
    @useAuth(BasicAuth)
    interface domains 
        extends EntityCollection<Domain, Domain, DomainUpdateModel, DomainMinimal>, 
            EntityCollectionTransferrable<DomainTransfer, rpp.common.TransferAck, rpp.common.TransferNack, DomainTransfer>,
            EntityCollectionRenewable<DomainRenewal, DomainRenewal>,
            EntityCollectionDeleteable<Domain, DomainDeletion> {
    }
}