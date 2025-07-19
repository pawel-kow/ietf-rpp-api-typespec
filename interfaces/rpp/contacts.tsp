import "../../models/contact.tsp";
import "./generic.tsp";

using TypeSpec.Http;
using rpp.interfaces.generic;

namespace rpp {
    @tag("Contacts")
    @route("/contacts")
    @useAuth(BasicAuth)
    interface contacts 
        extends EntityCollection<rpp.contact.Contact, rpp.contact.Contact>, 
            EntityCollectionDeleteable<rpp.contact.Contact, rpp.contact.ContactDeletion>,
            EntityCollectionTransferrable<rpp.contact.ContactTransfer, rpp.common.TransferAck, rpp.common.TransferNack, rpp.contact.ContactTransfer> {
    }
}