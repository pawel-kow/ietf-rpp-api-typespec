import "@typespec/json-schema";
using TypeSpec.JsonSchema;
using TypeSpec.Http;
using rpp.headers;

namespace rpp.message {
    model PollHeaders {
        @header "RPP-msgq-cnt": string;
        @header "RPP-msgq-date": string;
    }

    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    model PollQueueMessage {
        ...PollHeaders;
        id: string;
        msg: string;
        trnData: {};
    }

    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    model PollMessageAckResponse {
        @statusCode _: 200;
        id: string;
        ...PollHeaders;
    }
}