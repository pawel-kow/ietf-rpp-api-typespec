import "@typespec/json-schema";
import "./host.tsp";
import "./common.tsp";
import "./examples/domain.tsp";

using TypeSpec.JsonSchema;
using rpp.domain.examples;

namespace rpp.domain {
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
        ns?: NS;
        contacts?: ContactReference[];
        dnsSEC? : DnsSec[];
        ...rpp.common.ProvisioningObj;
    }
}