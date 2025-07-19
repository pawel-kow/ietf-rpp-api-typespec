namespace rpp.discovery {
   
    @mediaTypeHint("application/rpp+json")
    model HelloResponse {
        svID: string;
        svDate: string;
        svcMenu: {
            version: string;
            lang: string[];
        };
        dcp: {
            access: {
                all: string;
            };
            statement: {
                purpose: {
                    admin: string;
                    prov: string;
                };
                recipient: {
                    ours: string;
                    public: string;
                };
                retention: {
                    stated: string;
                };
            };
        };
    }
}