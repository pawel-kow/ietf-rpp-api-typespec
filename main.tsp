import "@typespec/http";
import "@typespec/openapi3";
import "@typespec/json-schema";

using TypeSpec.Http;
using TypeSpec.JsonSchema;
using TypeSpec.OpenAPI;

const domainExampleHostObj = #{
    name: "example.com",
    registrant: #["registrant-id"],
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
    registrant: #["registrant-id"],
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
    registrant: #["registrant-id"],
    authInfo: #{
        pw: "password"
    }
};

@doc("RPP Testbed server")
@server("https://localhost:8000", "Local RPP Testbed server")
@service(#{title: "RPP Testbed", version: "1.0.0"})
namespace rpp {

//    @route("/")
//    @get op Hello() : HelloResponse;
    @tag("Domains")
    @route("/domains")
    interface domains extends EntityCollection<Domain, Domain>, EntityCollectionTransferrable<DomainRenew, DomainRenew> {
    }

    @tag("Contacts")
    @route("/contacts")
    interface contacts extends EntityCollection<ContactReference, ContactReference> {
    }

    @route("/hosts")
    interface hosts extends EntityCollection<Host, Host> {
    }

    @route("/messages")
    interface Messages {
        @get op PollRequest() : Message[];

        @route("/{id}")
        @delete op AckPoll(id: string) : Message;
    }

    interface EntityCollection<InputT, OutputT> {

        // Check
        @head op Check(...InputT) : OutputT;

        // Check
        //@overload(Create) // this does not work as in https://typespec.io/docs/standard-library/built-in-decorators/
        @post op Create(...InputT, @header Expect?: "100-continue") : OutputT;

        // Delete
        @route("/{id}")
        @delete op Delete(id: string) : OutputT;

        // Info
        @route("/{id}")
        @get op Get(id: string) : OutputT;

        // Renew
        @route("/{id}/renewals")
        @post op Renew(id: string) : OutputT;

        // Update
        @route("/{id}")
        @patch op Update(...InputT, id: string) : OutputT;
    }

    interface EntityCollectionTransferrable<InputT, OutputT> {
        // Transfer Request
        @route("/{id}/transfer")
        @put op TransferRequest(...InputT, id: string) : OutputT;

        // Transfer Query
        @route("/{id}/transfer")
        @get op TransferQuery(id: string) : OutputT;

        // Cancel
        @route("/{id}/transfer")
        @delete op TransferCancel(id: string) : OutputT;

        // Approve
        @route("/{id}/transfer/approval")
        @put op TransferApprove(id: string) : OutputT;

        // Reject
        @route("/{id}/transfer/rejection")
        @put op TransferReject(id: string) : OutputT;
    }

    @jsonSchema
    @example(domainExampleHostObj, #{ title: "Host object domain registration", description: "Register a domain with two nameservers" })
    @example(domainExampleHostAttr, #{ title: "Host attribute domain registration", description: "Register a domain with two nameservers" })
    @example(domainExamplePeriods, #{ title: "Periods domain registration", description: "Register a domain with a 2 years period" })
    model Domain {
        name: string;
        processes?: {
            creation?: DomainCreation;
            renewal?: DomainRenewal;
        };
        registrant?: string[];
        authInfo?: {
            pw?: string;
            hash?: string;
        };
        ns?: NS;
        contacts?: ContactReference[];
        dnsSEC? : DnsSec[];
      }

      model DomainCreation {
        period: duration;
      }

      model DomainRenewal {
        period: duration;
      }

      @jsonSchema
      model DomainRenew {
        duration?: duration;
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