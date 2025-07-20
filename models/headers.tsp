import "@typespec/http";

using TypeSpec.Http;

namespace rpp.headers {
    union PreferHeaderRepresentation {
        @doc("Return minimal representation of the resource. Default if not specified.")
        minimal: "return=minimal";
        @doc("Return full representation of the resource.")
        full: "return=representation";
    }

    model RequestHeadersMinimal {
        @doc("RPP-Cltrid header is used to identify the client request. It MUST be a unique identifier for each request.")
        @header "RPP-Cltrid"?: string;
    }

    model RequestHeaders extends RequestHeadersMinimal {
        @doc("Prefer header to indicate the desired representation of the response.")
        @header "Prefer"?: PreferHeaderRepresentation = PreferHeaderRepresentation.minimal;
        @doc("RPP-Authorization header must be in the format 'AuthInfo AuthInfo=[authinfo]; Roid=[roid]' (Roid optional) or just '[method] [authinfo]'")
        @pattern("^(AuthInfo AuthInfo=([a-zA-Z0-9=]+)(?:;\\s*Roid=(\\S+))?)$|(.+\\s+.*)", "RPP-Authorization header must be in the format 'AuthInfo AuthInfo=<authinfo>; Roid=<roid>' or just '<method> <authinfo>'")
        @header "RPP-Authorization"?: string;
    }

    model ResponseHeaders {
        @header "RPP-Cltrid"?: string;
        @header "RPP-Svtrid"?: string;
        @header "RPP-Code": string;
    }
}