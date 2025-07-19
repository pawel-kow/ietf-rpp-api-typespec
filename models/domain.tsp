import "@typespec/json-schema";
import "./host.tsp";
import "./common.tsp";
import "./examples/domain.tsp";

using TypeSpec.JsonSchema;
using rpp.domain.examples;
using rpp.common;

namespace rpp.domain {
    @doc("Enumeration of contact types for a domain registration.")
    enum ContactType {
        @doc("The registrant of the domain.")
        registrant,
        @doc("The administrative contact for the domain.")
        admin,
        @doc("The technical contact for the domain.")
        tech,
        @doc("The billing contact for the domain.")
        billing
    }

    @doc("Represents a reference to a contact, specifying its identifier and roles.")
    model ContactReference {
        @doc("The unique identifier for the contact, typically a handle or ID.")
        value: string;
        @doc("An array of roles that the contact fulfills for the domain.")
        type: ContactType[];
    }

    @doc("Represents the DNSSEC data for a domain, used to secure DNS lookups.")
    model DnsSec {
        @doc("The key tag value of the DS record, as specified in RFC 4034.")
        keyTag: string;
        @doc("The algorithm used to create the DS record, as specified in RFC 4034.")
        algorithm: string;
        @doc("The digest type of the DS record, as specified in RFC 4034.")
        digestType: string;
        @doc("The digest value of the DS record in hexadecimal format.")
        digest: string;
    }

    @doc("Represents a nameserver defined by its attributes, for hosts not managed within the registry.")
    model NSHostAttr {
        @doc("An array of host attributes, including the hostname and optional IP addresses.")
        hostAttr: rpp.host.HostInfoAttr[];
    }

    @doc("A union representing a nameserver, which can be specified either as a registered host object or by its attributes for external hosts.")
    @TypeSpec.JsonSchema.oneOf
    @TypeSpec.OpenAPI.oneOf
    union NS {
        @doc("A reference to a host object already registered in the registry.")
        rpp.host.NSHostObj;
        @doc("A set of host attributes for a nameserver not registered in the registry.")
        NSHostAttr;
    }

    @doc("Parameters specific to the creation of a domain.")
    model DomainCreation {
        @doc("The initial registration period for the domain. The allowed unit (e.g., years, months) and range are defined by the registry policy.")
        period?: duration;
    }

    @doc("Parameters specific to the renewal of a domain.")
    model DomainRenewal {
        @doc("The period for which the domain registration should be extended. The allowed unit and range are defined by the registry policy.")
        period?: duration;
    }

    @doc("Parameters specific to the transfer of a domain.")
    @jsonSchema
    model DomainTransfer {
        @doc("The registration period to be added to the domain upon a successful transfer. The allowed unit and range are defined by the registry policy.")
        period?: duration;

        @doc("The date on which the transfer will be automatically proceeding if not approved or rejected earlier.")
        @visibility(Lifecycle.Read, Lifecycle.Query) auto_ack_date?: utcDateTime;

        @doc("The date on which the transfer will be automatically cancelled if not approved or rejected earlier.")
        @visibility(Lifecycle.Read, Lifecycle.Query) auto_nack_date?: utcDateTime;

        @doc("The current status of the transfer process, indicating its state.")
        @visibility(Lifecycle.Read, Lifecycle.Query) status?: TransferStatus;

        @visibility(Lifecycle.Read, Lifecycle.Query) approval?: TransferAck;

        @visibility(Lifecycle.Read, Lifecycle.Query) rejection?: TransferNack;
    }

    @doc("Parameters specific to the deletion of a domain.")
    @jsonSchema
    model DomainDeletion {
        @doc("The date on which the domain is scheduled to be purged from the registry database following deletion.")
        purgeDate?: utcDateTime
    }

    @doc("The core model representing a domain name and its associated properties and operations, as defined in RFC 5731.")
    @jsonSchema
    @example(domainExampleHostObj, #{ title: "Host object domain registration", description: "Register a domain with two nameservers" })
    @example(domainExampleHostAttr, #{ title: "Host attribute domain registration", description: "Register a domain with two nameservers" })
    @example(domainExamplePeriods, #{ title: "Periods domain registration", description: "Register a domain with a 2 years period" })
    @mediaTypeHint("application/rpp+json")
    model Domain {
        @doc("The fully qualified name of the domain.")
        name: string;
        @doc("A container for parameters related to specific domain life-cycle processes.")
        "processes"?: {
            @doc("Parameters for the domain creation process.")
            creation?: DomainCreation;
            @doc("Parameters for the domain renewal process.")
            renewal?: DomainRenewal;
            @doc("Parameters for the domain transfer process.")
            transfer?: DomainTransfer;
        };
        @doc("Nameservers can be specified either as host objects or host attributes. Host objects are used for nameservers that are registered in the registry, while host attributes are used for nameservers that are not registered in the registry but are associated with the domain.")
        ns?: NS;
        @doc("An array of contacts associated with the domain, each with one or more roles.")
        contacts?: ContactReference[];
        @doc("An array of DNSSEC data associated with the domain. This is required to sign the domain in DNS.")
        dnsSEC? : DnsSec[];
        ...rpp.common.TransferableProvisioninigObj;
    }
}
