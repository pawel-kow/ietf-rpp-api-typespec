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
    interface EntityCollectionTransferrable<InputT, AckInputT, NackInoutT, OutputT> {
        // Transfer Request
        @route("/{id}/processes/transfer")
        @post op TransferRequest(...InputT, id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // Transfer Query
        @route("/{id}/processes/transfer/latest")
        @get op TransferQuery(id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // Cancel
        @route("/{id}/processes/transfer/latest")
        @delete op TransferCancel(id: string) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // Approve
        @route("/{id}/processes/transfer/latest/approval")
        @put op TransferApprove(id: string, ...AckInputT) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;

        // Reject
        @route("/{id}/processes/transfer/latest/rejection")
        @put op TransferReject(id: string, ...AckInputT) : {...ResponseHeaders, ...OutputT} | ErrorResponse400_401_404_500;
    }
}