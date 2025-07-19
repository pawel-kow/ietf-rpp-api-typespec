import "@typespec/http";

using TypeSpec.Http;

namespace rpp.headers {
    model RequestHeaders {
        @header "RPP-Cltrid"?: string;
    }

    model ResponseHeaders {
        @header "RPP-Cltrid"?: string;
        @header "RPP-Svtrid"?: string;
        @header "RPP-Code": string;
    }
}