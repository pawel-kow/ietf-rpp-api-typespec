import "@typespec/http";
import "@typespec/openapi3";
import "@typespec/openapi";
import "@typespec/json-schema";
import "../../../models/headers.tsp";
import "../../../models/errors.tsp";
import "../../../models/common.tsp";

using TypeSpec.Http;
using rpp.headers;
using rpp.errors;

namespace rpp.interfaces.generic.entitycollections {
    interface EntityCollection<InputT, OutputT, OutputTMinimal = OutputT> {

        @post op Create(...RequestHeaders, ...InputT) : {...ResponseHeaders, ...OutputT} | {...ResponseHeaders, ...OutputTMinimal} | ErrorResponse400_401_409_500;

        // Info
        @route("/{id}")
        @get op Get(...RequestHeaders, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // Check as HEAD/GET
        @route("/{id}/availability")
        @head op CheckFast(...RequestHeadersMinimal, id: string) : {@statusCode _: 200, ...ResponseHeaders} | ErrorResponse400_401_404_500;

        // Check as GET
        @route("/{id}/availability")
        @get op Check(...RequestHeadersMinimal, id: string) : {@statusCode _: 200, ...rpp.common.CheckResponse, ...ResponseHeaders} | ErrorResponse400_401_404_500;


        // Update
        //@route("/{id}")
        //@patch op Update(...RequestHeaders, ...InputT, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;
    }
}