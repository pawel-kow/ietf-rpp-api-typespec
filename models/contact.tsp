import "@typespec/json-schema";
using TypeSpec.JsonSchema;
using rpp.common;

namespace rpp.contact {
    @doc("Parameters specific to the transfer of a domain.")
    @jsonSchema
    model ContactTransfer {
        @doc("The date on which the transfer will be automatically proceeding if not approved or rejected earlier.")
        @visibility(Lifecycle.Read, Lifecycle.Query) autoAckDate?: utcDateTime;

        @doc("The date on which the transfer will be automatically cancelled if not approved or rejected earlier.")
        @visibility(Lifecycle.Read, Lifecycle.Query) autoNackDate?: utcDateTime;

        @doc("The current status of the transfer process, indicating its state.")
        @visibility(Lifecycle.Read, Lifecycle.Query) status?: TransferStatus;
    }

    enum ContactType {
        PERSON,
        ORG
    }

    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    model Contact {
        id: string;
        name?: string;
        organisationName?: string;
        contactType: ContactType;
        email?: string[];
        phone?: string[];
        fax?: string[];
        address?: {
            street?: string[];
            city?: string;
            stateProvince?: string;
            postalCode?: string;
            country?: string;
        };
        ...rpp.common.TransferableProvisioninigObj;
    }

    @jsonSchema
    model ContactDeletion {
    }
}