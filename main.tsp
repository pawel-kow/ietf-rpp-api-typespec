import "@typespec/http";
import "@typespec/openapi3";
import "@typespec/openapi";
import "@typespec/json-schema";
import "./models/domain.tsp";
import "./models/contact.tsp";
import "./models/message.tsp";
import "./models/headers.tsp";
import "./models/host.tsp";
import "./models/errors.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;
using rpp.headers;
using rpp.errors;

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
    @tag("Discovery")
    @route("/hello")
    @get op Hello(...RequestHeaders) : {...ResponseHeaders, ...HelloResponse} | ErrorResponse400_401_500;

    @tag("Domains")
    @route("/domains")
    @useAuth(BasicAuth)
    interface domains extends EntityCollection<rpp.domain.Domain, rpp.domain.Domain>, EntityCollectionTransferrable<rpp.domain.DomainTransfer, rpp.domain.DomainTransfer>,
    EntityCollectionRenewable<rpp.domain.DomainRenewal, rpp.domain.DomainRenewal>,
    EntityCollectionDeleteable<rpp.domain.Domain, rpp.domain.DomainDeletion> {
    }

    @tag("Contacts")
    @route("/contacts")
    @useAuth(BasicAuth)
    interface contacts extends EntityCollection<rpp.contact.Contact, rpp.contact.Contact> {
    }

    @tag("Hosts")
    @route("/hosts")
    @useAuth(BasicAuth)
    interface hosts extends EntityCollection<rpp.host.Host, rpp.host.Host> {
    }

    @tag("Poll messages")
    @route("/messages")
    @useAuth(BasicAuth)
    interface Messages {
        @get op PollRequest(...RequestHeaders) : {...ResponseHeaders, ...rpp.message.Message} | ErrorResponse400_401_409_500;

        @route("/{id}")
        @delete op AckPoll(id: string, ...RequestHeaders): {...ResponseHeaders} | ErrorResponse400_401_404_500;
    }

    interface EntityCollection<InputT, OutputT> {

        // Check as HEAD - right now problematic
        //@head op Check(...RequestHeaders, ...InputT) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // One and the same operation for Create and Check with Expect header
        //@overload(Create) // this does not work as in https://typespec.io/docs/standard-library/built-in-decorators/
        @post op Create(...RequestHeaders, ...InputT, @header Expect?: "100-continue") : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_409_500;

        // Info
        @route("/{id}")
        @get op Get(...RequestHeaders, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // Update
        //@route("/{id}")
        //@patch op Update(...RequestHeaders, ...InputT, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;
    }

    interface EntityCollectionTransferrable<InputT, OutputT> {
        // Transfer Request
        @route("/{id}/processes/transfer")
        @put op TransferRequest(...InputT, id: string) : OutputT;

        // Transfer Query
        @route("/{id}/processes/transfer")
        @get op TransferQuery(id: string) : OutputT;

        // Cancel
        @route("/{id}/processes/transfer")
        @delete op TransferCancel(id: string) : OutputT;

        // Approve
        @route("/{id}/processes/transfer/approval")
        @put op TransferApprove(id: string) : OutputT;

        // Reject
        @route("/{id}/processes/transfer/rejection")
        @put op TransferReject(id: string) : OutputT;
    }

    interface EntityCollectionRenewable<InputT, OutputT> {
        // Transfer Request
        @route("/{id}/processes/renewal")
        @put op RenewalRequest(...InputT, id: string) : OutputT;

        // Transfer Query
        @route("/{id}/processes/renewal")
        @get op RenewalQuery(id: string) : OutputT;

        // Cancel
        @route("/{id}/processes/renewal")
        @delete op RenewalCancel(id: string) : OutputT;
    }

    interface EntityCollectionDeleteable<ItemOutputT, ProcessOutputT> {
        // Delete
        @route("/{id}")
        @delete op Delete(id: string) : ItemOutputT;

        // Delete Query
        @route("/{id}/processes/deletion")
        @get op DeletionQuery(id: string) : ProcessOutputT;
    }

    model HelloResponse {
        svID: string;
        svDate: string;
        svcMenu: {
            version: string;
            lang: string[];
        };
        dcp: {
            access: {
                all: string;
            };
            statement: {
                purpose: {
                    admin: string;
                    prov: string;
                };
                recipient: {
                    ours: string;
                    public: string;
                };
                retention: {
                    stated: string;
                };
            };
        };
    }

}