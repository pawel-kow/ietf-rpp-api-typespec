
import "@typespec/json-schema";

using TypeSpec.JsonSchema;

namespace rpp.common {
    @doc("Parameters specific to the transfer of a domain.")
    @jsonSchema
    model TransferAck {
        @doc("Reason for the transfer approval, if applicable.")
        reason: string;
    }

    @doc("Parameters specific to the transfer of a domain.")
    @jsonSchema
    model TransferNack {
        @doc("Reason for the transfer approval, if applicable.")
        reason: string;
    }

    enum TransferStatus {
        @doc("The transfer is pending approval.")
        pending,
        @doc("The transfer has been approved.")
        approved,
        @doc("The transfer has been rejected.")
        rejected,
        @doc("The transfer has been cancelled.")
        cancelled,
        @doc("The transfer has been completed successfully.")
        completed
    };

    model ProvisioningObj {
        authInfo: {
            pw?: string;
            hash?: string;
        };
        @visibility(Lifecycle.Read, Lifecycle.Query) status?: string[];
        @visibility(Lifecycle.Read, Lifecycle.Query) crDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) exDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) upDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) trDate?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) clID?: string;
        @visibility(Lifecycle.Read, Lifecycle.Query) crID?: string;
    }
}