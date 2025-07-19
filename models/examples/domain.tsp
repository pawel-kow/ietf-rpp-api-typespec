import "../domain.tsp";

using rpp.domain;

namespace rpp.domain.examples {
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
}