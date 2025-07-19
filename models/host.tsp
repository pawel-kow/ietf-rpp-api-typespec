import "@typespec/json-schema";
import "./common.tsp";

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

    model NSHostObj {
        hostObj: HostInfoObj[];
    }

    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    model Host extends HostInfoAttr {
        ...rpp.common.ProvisioningObj;
    }
}