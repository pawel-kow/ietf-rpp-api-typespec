import "@typespec/http";
import "@typespec/json-schema";
import "./headers.tsp";

using TypeSpec.Http;
using TypeSpec.JsonSchema;
using rpp.headers;

namespace rpp.errors {
    @jsonSchema
    @mediaTypeHint("application/problem+json")
    model ErrorResponse {
        title: string;
        detail: string;
        type: string;
        status: string;
        instance: string;
    }

    model ErrorResponse400 extends ErrorResponse {
        @statusCode _: 400;
        ...ResponseHeaders;
    }

    model ErrorResponse401 extends ErrorResponse {
        @statusCode _: 401;
    }


    model ErrorResponse409 extends ErrorResponse {
        @statusCode _: 409;
        ...ResponseHeaders;
    }

    model ErrorResponse404 extends ErrorResponse {
        @statusCode _: 404;
        ...ResponseHeaders;
    }

    model ErrorResponse500 extends ErrorResponse {
        @statusCode _: 500;
        ...ResponseHeaders;
    }

    alias ErrorResponse200_400_401_404_500_noContent_availability = 
        {  
            @doc("Resource is taken and not available for creation")
            @statusCode _: 200;
           ...ResponseHeaders;
        } 
        | {
            @doc("Wrong request format or missing required parameters")
            @statusCode _: 400;
            ...ResponseHeaders;
        } 
        | {
            @doc("Authentication is required to query the resurce availability")
            @statusCode _: 401;
            ...ResponseHeaders;
        } 
        | { 
            @doc("Resource is available for creation")
            @statusCode _: 404;
            ...ResponseHeaders;
        } 
        | {
            @doc("Error occurred while processing the request")
            @statusCode _: 500;
            ...ResponseHeaders;
        };
 
    alias ErrorResponse400_401_404_500 = ErrorResponse400 | ErrorResponse401 | ErrorResponse404 | ErrorResponse500;

    alias ErrorResponse400_401_409_500 = ErrorResponse400 | ErrorResponse401 | ErrorResponse409 | ErrorResponse500;

    alias ErrorResponse400_401_500 = ErrorResponse400 | ErrorResponse401 | ErrorResponse500;

    alias ErrorResponse400_401_404_409_500 = ErrorResponse400 | ErrorResponse401 | ErrorResponse404 | ErrorResponse409 | ErrorResponse500;
}