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
    interface EntityCollection<InputT, OutputT> {

        // Check as HEAD - right now problematic
        //@head op Check(...RequestHeaders, ...InputT) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // One and the same operation for Create and Check with Expect header
        //@overload(Create) // this does not work as in https://typespec.io/docs/standard-library/built-in-decorators/
        @post op Create(...RequestHeaders, ...InputT, @header Expect?: "100-continue") : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_409_500;

        // Info
        @route("/{id}")
        @get op Get(...RequestHeaders, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // Update
        //@route("/{id}")
        //@patch op Update(...RequestHeaders, ...InputT, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;
    }
}