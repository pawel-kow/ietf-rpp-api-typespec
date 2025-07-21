import "@typespec/json-schema";
import "./common.tsp";
import "./dns.tsp";

using TypeSpec.JsonSchema;

namespace rpp.host {

    model HostInfoObj {
        name: string;
    }

    model HostInfoAttr extends HostInfoObj {
        addr?: {
            "ipv4"?: string[];
            "ipv6"?: string[];
        };
    }

    model HostAttr {
        ...HostInfoAttr;
        ...rpp.dns.DNS
    }

    model NSHostObj {
        hostObj: HostInfoObj[] | DNSHostObj[];
    }

    @doc("A host object using the DNS object")
    model DNSHostObj {
        name: string;
        ...rpp.dns.DNS
    }

    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    model Host extends HostAttr {
        ...rpp.common.ProvisioningObj;
    }
}
