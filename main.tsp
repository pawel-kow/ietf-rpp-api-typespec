import "@typespec/http";
import "@typespec/openapi3";
import "@typespec/json-schema";

using TypeSpec.Http;
using TypeSpec.JsonSchema;
using TypeSpec.OpenAPI;

@doc("RPP Testbed server")
@server("https://localhost:8000", "Local RPP Testbed server")
@service(#{title: "RPP Testbed", version: "1.0.0"})
namespace rpp {

    const domainExampleHostObj = #{
        name: "example.com",
        contacts: #[#{
            value: "registrant-id",
            type: #[ContactType.registrant, ContactType.admin]
        }],
        authInfo: #{
            pw: "password"
        },
        ns: #{
            hostObj: #[
                #{
                    name: "ns1.example.net"
                },
                #{
                    name: "ns2.example.net"
                }
            ]
        }
    };
    
    const domainExampleHostAttr = #{
        name: "example.com",
        contacts: #[#{
            value: "registrant-id",
            type: #[ContactType.registrant]
        }],
        authInfo: #{
            pw: "password"
        },
        ns: #{
            hostAttr: #[
                #{
                    name: "ns1.example.net",
                    addr: #{
                        ipv4: #["1.1.1.1"],
                        ipv6: #["2001:db8::1"]
                    }
                },
                #{
                    name: "ns2.example.net",
                    addr: #{
                        ipv4: #["1.1.1.1"]
                    }
                }
            ]
        }
    };
    
    const domainExamplePeriods = #{
        name: "example.com",
        processes: #{
            creation: #{
                period: duration.fromISO("P2Y")
            }
        },
        authInfo: #{
            pw: "password"
        },
        contacts: #[#{
            value: "registrant-id",
            type: #[ContactType.registrant]
        }],
    };
    

//    @route("/")
//    @get op Hello() : HelloResponse;
    @tag("Domains")
    @route("/domains")
    @useAuth(BasicAuth)
    interface domains extends EntityCollection<Domain, Domain>, EntityCollectionTransferrable<DomainTransfer, DomainTransfer>,
    EntityCollectionRenewable<DomainRenewal, DomainRenewal>,
    EntityCollectionDeleteable<Domain, DomainDeletion> {
    }

    @tag("Contacts")
    @route("/contacts")
    @useAuth(BasicAuth)
    interface contacts extends EntityCollection<ContactReference, ContactReference> {
    }

    @tag("Hosts")
    @route("/hosts")
    @useAuth(BasicAuth)
    interface hosts extends EntityCollection<Host, Host> {
    }

    @tag("Poll messages")
    @route("/messages")
    @useAuth(BasicAuth)
    interface Messages {
        @get op PollRequest() : Message[];

        @route("/{id}")
        @delete op AckPoll(id: string) : Message;
    }

    interface EntityCollection<InputT, OutputT> {

        // Check
        @head op Check(...RequestHeaders, ...InputT) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_404_500;

        // Check
        //@overload(Create) // this does not work as in https://typespec.io/docs/standard-library/built-in-decorators/
        @post op Create(...RequestHeaders, ...InputT, @header Expect?: "100-continue") : {...ResponseHeaders, ...OutputT} | ErrorResponse400_409_500;

        // Info
        @route("/{id}")
        @get op Get(...RequestHeaders, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_404_500;

        // Update
        @route("/{id}")
        @patch op Update(...RequestHeaders, ...InputT, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_404_500;
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

    model RequestHeaders {
        @header "RPP-cltrid"?: string;
    }

    model ResponseHeaders {
        @header "RPP-cltrid"?: string;
        @header "RPP-svtrid"?: string;
    }

    @jsonSchema
//    @mediaTypeHint("application/problem+json") #bug in typespec
    @mediaTypeHint("application/problem-json")
    model ErrorResponse {
        title: string;
        detail: string;
        type: string;
        status: string;
        instance: string;
    }

    model ErrorResponse400 extends ErrorResponse {
        @statusCode _: 400;
        ...ResponseHeaders;
    }

    model ErrorResponse409 extends ErrorResponse {
        @statusCode _: 409;
        ...ResponseHeaders;
    }
    model ErrorResponse404 extends ErrorResponse {
        @statusCode _: 404;
        ...ResponseHeaders;
    }

    model ErrorResponse500 extends ErrorResponse {
        @statusCode _: 500;
        ...ResponseHeaders;
    }

    alias ErrorResponse400_404_500 = ErrorResponse400 | ErrorResponse404 | ErrorResponse500;

    alias ErrorResponse400_409_500 = ErrorResponse400 | ErrorResponse409 | ErrorResponse500;

    alias ErrorResponse400_404_409_500 = ErrorResponse400 | ErrorResponse404 | ErrorResponse409 | ErrorResponse500;
    model DomainResponse {
        ...Domain;
        ...ResponseHeaders;
    }

    model DomainRequest {
        ...Domain;
        ...RequestHeaders;
    }

    @jsonSchema
    @example(domainExampleHostObj, #{ title: "Host object domain registration", description: "Register a domain with two nameservers" })
    @example(domainExampleHostAttr, #{ title: "Host attribute domain registration", description: "Register a domain with two nameservers" })
    @example(domainExamplePeriods, #{ title: "Periods domain registration", description: "Register a domain with a 2 years period" })
    model Domain {
        name: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) status?: string[];
        processes?: {
            creation?: DomainCreation;
            renewal?: DomainRenewal;
            transfer?: DomainTransfer;
        };
        authInfo: {
            pw?: string;
            hash?: string;
        };
        ns?: NS;
        contacts?: ContactReference[];
        dnsSEC? : DnsSec[];
        @visibility(Lifecycle.Read, Lifecycle.Query) crDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) exDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) upDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) trDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) clID?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) crID?: string;
    }
      model DomainCreation {
        period?: duration;
      }

      model DomainRenewal {
        period?: duration;
      }

      @jsonSchema
      model DomainTransfer {
        period?: duration;
      }

      @jsonSchema
      model DomainDeletion {
        purgeDate?: utcDateTime
      }

    model HostInfoObj {
        name: string;
    }

    model HostInfoAttr extends HostInfoObj {
        addr?: {
            "ipv4"?: string[];
            "ipv6"?: string[];
        };
    }

    model NSHostObj {
        hostObj: HostInfoObj[];
    }

    model NSHostAttr {
        hostAttr: HostInfoAttr[];
    }

    @TypeSpec.JsonSchema.oneOf
    @TypeSpec.OpenAPI.oneOf
    union NS {
        NSHostObj;
        NSHostAttr;
    }

    model Registrant {
        id: string;
    }

    model DnsSec {
        keyTag: string;
        algorithm: string;
        digestType: string;
        digest: string;
    }

    model ContactReference {
        value: string;
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

    model Host extends HostInfoAttr {
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