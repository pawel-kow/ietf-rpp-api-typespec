import "@typespec/json-schema";

using TypeSpec.JsonSchema;

/**
 * TypeSpec model of the JSContact Card object (version 2.0, [RFC9982]) as
 * profiled for RPP by draft-wullink-rpp-json §5.2.8.
 *
 * The following constraints cannot be expressed in JSON Schema / TypeSpec
 * and MUST be enforced by implementations:
 * - addresses[*].countryCode MUST be a valid two-character ISO 3166-1
 *   alpha-2 code when present.
 * - localizations MUST be fully expanded; nested PatchObject-style keys
 *   (e.g., "addresses/addr/full") are NOT allowed.
 * - When phones[*].features is absent, the number MUST be treated as a
 *   voice number.
 */
namespace rpp.external.jscontact {
    @doc("Kind of entity the Card represents.")
    enum CardKind {
        individual,
        org,
    }

    @doc("Kind of a name component.")
    enum NameComponentKind {
        given,
        surname,
    }

    @doc("Kind of an address component.")
    enum AddressComponentKind {
        name,
        locality,
        region,
        postcode,
        country,
    }

    @doc("A single component of a Card's name, such as a given name or surname.")
    model NameComponent {
        kind: NameComponentKind;
        value: string;
    }

    @doc("The name of the entity represented by the Card.")
    model Name {
        full?: string;
        components?: NameComponent[];
    }

    @doc("An organization the Card's entity is associated with.")
    model Organization {
        name?: string;
    }

    @doc("A single component of a Card's address, such as locality or postcode.")
    model AddressComponent {
        kind: AddressComponentKind;
        value: string;
    }

    @doc("A postal address for the Card's entity.")
    model Address {
        full?: string;

        @doc("A two-character ISO 3166-1 alpha-2 country code, when present.")
        @pattern("^[A-Z]{2}$")
        countryCode?: string;

        components?: AddressComponent[];
    }

    @doc("Feature flags for a phone number, e.g. voice, fax, text.")
    model PhoneFeatures {
        ...Record<boolean>;
    }

    @doc("A phone number for the Card's entity.")
    model Phone {
        number: string;

        @doc("Absent means the number MUST be treated as a voice number.")
        features?: PhoneFeatures;
    }

    @doc("An email address for the Card's entity.")
    model EmailAddress {
        @format("email")
        address: string;
    }

    @doc("A link related to the Card's entity.")
    model Link {
        @format("uri")
        uri: string;

        kind?: "contact";
    }

    @doc("""
        JSContact Card object (version 2.0), per the RPP JSContact Profile
        (draft-wullink-rpp-json §5.2.8).
        """)
    @jsonSchema
    @mediaTypeHint("application/rpp+json")
    model Card {
        `@type`: "Card";
        version: "2.0";
        kind?: CardKind;
        language?: string;
        name?: Name;
        organizations?: Record<Organization>;
        addresses?: Record<Address>;
        phones?: Record<Phone>;
        emails?: Record<EmailAddress>;
        links?: Record<Link>;
        localizations?: Record<unknown>;
    }
}
