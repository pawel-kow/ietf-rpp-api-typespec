import "@typespec/http";

using TypeSpec.Http;

namespace rpp.headers {
    model RequestHeaders {
        @header "RPP-cltrid"?: string;
    }

    model ResponseHeaders {
        @header "RPP-cltrid"?: string;
        @header "RPP-svtrid"?: string;
    }
}