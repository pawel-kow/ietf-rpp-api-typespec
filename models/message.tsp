import "@typespec/json-schema";
using TypeSpec.JsonSchema;

namespace rpp.message {
    @jsonSchema
    model Message {
        id: string;
        subject?: string;
        body?: string;
    }
}