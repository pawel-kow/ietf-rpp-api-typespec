import "@typespec/http";
import "@typespec/openapi3";
import "@typespec/openapi";
import "@typespec/json-schema";
import "../../../models/headers.tsp";
import "../../../models/errors.tsp";

using TypeSpec.Http;
using rpp.headers;
using rpp.errors;

namespace rpp.interfaces.generic.entitycollections{
    interface EntityCollectionRenewable<InputT, OutputT> {
        // Renew Request
        @route("/{id}/processes/renewal")
        @put op RenewalRequest(...InputT, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;
    }
}