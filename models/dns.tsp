
namespace rpp.dns {

    @doc("DNS configuration of an object")
    model DNS {
      dns?: {
        records: DnsRecord[];
        controls?: DnsControls;
      }
    }

    @doc("DNS resource record, as specified in RFC 1035. RDATA is added depending on type")
    model DnsRecord {
      name: string;
      type: string;
      rdata: RDataNS | RDataA | RDataAAAA | RDataDS | RDataDNSKEY | RDataMX | RDataTXT
    }

    @doc("RDATA for NS record, as specified in RFC 1035")
    model RDataNS extends DnsRecord {
      nsdname: string
    }

    @doc("RDATA for A record, as specified in RFC 1035")
    model RDataA extends DnsRecord {
      @doc("IPv4 address")
      address: int32
    }

    @doc("RDATA for AAAA record, as specified in RFC 3596")
    model RDataAAAA extends DnsRecord {
      @doc("IPv6 address")
      address: int32
    }

    @doc("RDATA for DS record, as specified in RFC 4034")
    model RDataDS extends DnsRecord {
      @doc("The key tag value of the DS record, as specified in RFC 4034.")
      keyTag: int32,
      @doc("The algorithm used to create the DS record, as specified in RFC 4034.")
      algorithm: int32,
      @doc("The digest type of the DS record, as specified in RFC 4034.")
      digestType: int32,
      @doc("The digest value of the DS record in hexadecimal format.")
      digest: string
    }

    @doc("RDATA for DNSKEY record, as specified in RFC 4034")
    model RDataDNSKEY extends DnsRecord {
      flags: int32,
      protocol: int32,
      algorithm: int32,
      publicKey: string,
    }

    @doc("RDATA for MX record, as specified in RFC 1035")
    model RDataMX extends DnsRecord {
      preference: string,
      exchange: string
    }

    @doc("RDATA for TXT record, as specified in RFC 1035")
    model RDataTXT extends DnsRecord {
      txtData: string
    }

    @doc("Operational control for DNS")
    model DnsControls {
      ttl?: {
        a?: int32,
        aaaa?: int32,
        dnskey?: int32,
        ds?: int32,
        ns?: int32,
        mx?: int32,
        txt?: int32
      },
      maximumSignatureLifetime?: int32
    }

}
