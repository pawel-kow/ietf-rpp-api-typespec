
namespace rpp.common {
    model ProvisioningObj {
        @visibility(Lifecycle.Read, Lifecycle.Query) status?: string[];
        @visibility(Lifecycle.Read, Lifecycle.Query) crDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) exDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) upDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) trDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) clID?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) crID?: string;
    }
}