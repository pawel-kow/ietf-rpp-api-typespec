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

    model Host extends HostInfoAttr {
        ...rpp.common.ProvisioningObj;
    }
}