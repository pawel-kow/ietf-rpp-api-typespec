import "@typespec/json-schema";
using TypeSpec.JsonSchema;

namespace rpp.contact {
    enum ContactType {
        PERSON,
        ORG
    }

    @jsonSchema
    model Contact {
        id: string;
        name?: string;
        organisation_name?: string;
        contact_type: ContactType;
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
        ...rpp.common.ProvisioningObj;
    }
}