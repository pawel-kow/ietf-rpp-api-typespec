import "@typespec/http";
import "@typespec/openapi3";

using TypeSpec.Http;

@service()
namespace rpp {

    @route("/")
    @get op Hello() : HelloResponse;

    @route("/contacts")
    interface contacts extends EntityCollection<ContactReference> {
    }

    @route("/domains")
    interface domains extends EntityCollection<Domain>, EntityCollectionTransferrable<Domain> {
    }

    @route("/hosts")
    interface hosts extends EntityCollection<Host> {
    }

    @route("/messages")
    interface Messages {
        @get op PollRequest() : Message[];

        @route("/{id}")
        @delete op AckPoll(id: string) : Message;
    }

    interface EntityCollection<T> {

        // Check
        @head op Check(entity: T) : T;

        // Create
        @post op Create(entity: T) : T;

        // Delete
        @route("/{id}")
        @delete op Delete(id: string) : T;

        // Info
        @route("/{id}")
        @get op Get(id: string) : T;

        // Renew
        @route("/{id}/renewals")
        @post op Renew(id: string) : T[];

        // Update
        @route("/{id}")
        @patch op Update(id: string, entity: T) : T;

        @route("/{id}/extension/{value}")
        @get op GetExtension(id: string, value: string) : OkResponse;

        @route("/{id}/extension/{value}")
        @patch op UpdateExtension(id: string, value: string, entity: {}) : OkResponse;

    }

    interface EntityCollectionTransferrable<T> {
        // Transfer Request
        @route("/{id}/transfer")
        @put op TransferRequest(id: string) : T[];

        // Transfer Query
        @route("/{id}/transfer")
        @get op TransferQuery(id: string) : T;

        // Cancel
        @route("/{id}/transfer")
        @delete op TransferCancel(id: string) : T;

        // Approve
        @route("/{id}/transfer/approval")
        @put op TransferApprove(id: string) : T;

        // Reject
        @route("/{id}/transfer/rejection")
        @put op TransferReject(id: string) : T;
    }

    model Domain {
        name: string;
        duration?: duration;
        registrant: Registrant[];
        authInfo: {
            pw: string;
            hash: string;
        };
        ns: {
            hostObj: HostInfo[];
            hostAttr: HostInfo[];
        };
        contacts: ContactReference[];
        dnsSEC : DnsSec[];
      }

    model HostInfo {
        name: string;
        addr: {
            "ipv4": string[];
            "ipv6": string[];
        };
    }

    model Registrant {
        id: string;
        name: string;
    }

    model DnsSec {
        keyTag: string;
        algorithm: string;
        digestType: string;
        digest: string;
    }

    model ContactReference {
        value: Contact;
        type: ContactType[];
    }

    model Contact {
        id: string;
        name: string;
        address: string;
    }

    enum ContactType {
        registrant,
        admin,
        tech,
        billing
    }

    model Message {

    }

    model Host {
        id: string;
        name: string;
        domain: Domain;
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