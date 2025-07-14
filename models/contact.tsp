import "@typespec/json-schema";
using TypeSpec.JsonSchema;

namespace rpp.contact {
    @jsonSchema
    model Contact {
        id: string;
        name?: string;
        email?: string;
        phone?: string;
        fax?: string;
        address?: {
            street: string[];
            city: string;
            stateProvince?: string;
            postalCode?: string;
            country: string;
        };
        ...rpp.common.ProvisioningObj;
    }
}