import "@typespec/json-schema";
import "./host.tsp";
import "./common.tsp";
using TypeSpec.JsonSchema;


namespace rpp.domain {

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

    enum ContactType {
        registrant,
        admin,
        tech,
        billing
    }

    model ContactReference {
        value: string;
        type: ContactType[];
    }

    model DnsSec {
        keyTag: string;
        algorithm: string;
        digestType: string;
        digest: string;
    }

    model NSHostAttr {
        hostAttr: rpp.host.HostInfoAttr[];
    }

    @TypeSpec.JsonSchema.oneOf
    @TypeSpec.OpenAPI.oneOf
    union NS {
        rpp.host.NSHostObj;
        NSHostAttr;
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

    model foo {
        bar?: string;
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
            transfer?: DomainTransfer;
        };
        authInfo: {
            pw?: string;
            hash?: string;
        };
        ns?: NS;
        contacts?: ContactReference[];
        dnsSEC? : DnsSec[];
        ...rpp.common.ProvisioningObj;
    }
}