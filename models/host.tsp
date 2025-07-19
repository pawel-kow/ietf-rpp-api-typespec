import "@typespec/json-schema";
import "./common.tsp";
import "./dns.tsp";

using TypeSpec.JsonSchema;

namespace rpp.host {

    model HostInfoObj {
        name: string;
        ...rpp.dns.DNS
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

    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    model Host extends HostInfoAttr {
        ...rpp.common.ProvisioningObj;
    }
}
