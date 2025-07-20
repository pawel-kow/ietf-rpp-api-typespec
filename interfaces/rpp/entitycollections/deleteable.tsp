import "@typespec/http";
import "@typespec/openapi3";
import "@typespec/openapi";
import "@typespec/json-schema";
import "../../../models/headers.tsp";
import "../../../models/errors.tsp";

using TypeSpec.Http;
using rpp.headers;
using rpp.errors;

namespace rpp.interfaces.generic.entitycollections {
    interface EntityCollectionDeleteable<ItemOutputT, ProcessOutputT> {
        // Delete
        @route("/{id}")
        @delete op Delete(id: string) : {...ResponseHeaders, ...ItemOutputT} | ErrorResponse400_401_404_500;
    }
}