import "@typespec/http";
import "../../models/message.tsp";
import "../../models/headers.tsp";
import "../../models/errors.tsp";

using TypeSpec.Http;
using rpp.headers;
using rpp.errors;

namespace rpp {
    @tag("Poll messages")
    @route("/messages")
    @useAuth(BasicAuth)
    interface Messages {
        @get op PollRequest(...RequestHeaders) : {...ResponseHeaders, ...rpp.message.PollQueueMessage} | ErrorResponse400_401_409_500;

        @route("/{id}")
        @delete op AckPoll(id: string, ...RequestHeaders): {...ResponseHeaders, ...rpp.message.PollMessageAckResponse} | ErrorResponse400_401_404_500;
    }
}