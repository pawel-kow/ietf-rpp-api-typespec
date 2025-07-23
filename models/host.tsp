import "@typespec/json-schema";
import "./common.tsp";

using TypeSpec.JsonSchema;

namespace rpp.host {

    @doc("Nameserver of a domain, either a EPP-style hostAttr or a reference of a hostObj by name. Host objects are used for nameservers that are registered in the registry, while host attributes are used for nameservers that are not registered in the registry but are associated with the domain.")
    model NS {
        ns?: DomainEPPHostAttr | DomainHostObj ;
    }

    @doc("EPP-stype hostAttr")
    model DomainEPPHostAttr {
        hostAttr: EPPHost[]
    }

    model DomainHostObj {
        @doc("Host object described in EPP-style (rpp.host.EPPHost).")
        hostObj: HostName[];
    }

    model HostName {
        name: string;
    }

    model HostAddress {
        addr?: {
            "ipv4"?: string[];
            "ipv6"?: string[];
        };
    }

    @doc("Host object described either EPP-style (rpp.host.EPPHost).")
    model EPPHost {
        ...HostName;
        ...HostAddress
    }

    @doc("Host object described either EPP-style (rpp.host.EPPHost).")
    model DNSHost {
        ...HostName;
    }

    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    @doc("Host object described either EPP-style (rpp.host.EPPHost).")
    model Host {
        ...EPPHost;
        ...rpp.common.ProvisioningObj;
    }
}
