{
  title: 'Ephesoft Semantik for Invoices',

  connection: {
    fields: [
      {
        name: 'client_id',
        optional: false
      },
      {
        name: 'client_secret',
        optional: false,
        control_type: 'password'
      }
    ],
    authorization: {
      type: "oauth2",
      authorization_url: lambda do |connection|
        params = {
          client_id: connection["client_id"],
          response_type: "code",
          redirect_uri: "https://www.workato.com/oauth/callback",
          scope: "admin"
        }.to_param

        "https://api.us.ephesoft.io/v1/auth/oauth2/authorize?" + params
      end,

      acquire: lambda do |connection, auth_code|
       response = post("https://api.us.ephesoft.io/v1/auth/oauth2/token").
                    payload(
                      code: auth_code,
                      grant_type: "authorization_code",
                      client_id: connection["client_id"],
                      client_secret: connection["client_secret"],
                      redirect_uri: "https://www.workato.com/oauth/callback"
                    ).
                    request_format_www_form_urlencoded
        [
          {
            access_token: response["access_token"],
            refresh_token: response["refresh_token"]
          }
        ]
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        response = post("https://api.us.ephesoft.io/v1/auth/oauth2/refresh").
                      payload(
                        grant_type: "refresh_token",
                        refresh_token: refresh_token,
                        client_id: connection["client_id"],
                        client_secret: connection["client_secret"],
                        redirect_uri: "https://www.workato.com/oauth/callback"
                      ).
                      request_format_www_form_urlencoded
        [
          { # Tokens hash
            access_token: response["access_token"],
            refresh_token: response["refresh_token"]
          },
          { instance_id: nil } # Optional. Will be merged into connection hash
        ]
      end,

      apply: lambda do |connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    }
  },
  test:
    lambda do |connection|
      get("https://api.us.ephesoft.io/v1/settings/integrations/configurations")
    end,
  actions: {
    # Future action code here
  },
  triggers: {
    new_message: {
      title: 'When a Semantik invoice has completed review',
      description: 'Triggers a flow using data from a completed Semantik invoice.',
      webhook_subscribe: lambda do |webhook_url, connection, input, recipe_id|
        post("https://api.us.ephesoft.io/v1/settings/integrations/configurations",
          integrationName: "Workato Recipe #{recipe_id}",
          integrationType: "webhook",
          enabled: true,
          settings: {
            targetUrl: webhook_url,
            encoding: "applicaiton/json",
            payload: "{\n     \"AmountDue\": \"$AmountDue\",\n     \"CustomerId\": \"$CustomerId\"\n     \"DocumentId\": \"$DocumentId\",\n     \"DueDate\": \"$DueDate\",\n     \"InvoiceDate\": \"$InvoiceDate\",\n     \"InvoiceNumber\": \"$InvoiceNumber\",\n     \"OrderDate\": \"$OrderDate\",\n     \"PdfUrl\": \"$PdfUrl\",\n     \"PONumber\": \"$PONumber\",\n     \"ShipDate\": \"$ShipDate\",\n     \"ShipFreight\": \"$ShipFreight\"\n     \"SubTotal\": \"$SubTotal\",\n     \"TableUrl\": \"$TableUrl\",\n     \"TaxAmount\": \"$TaxAmount\",\n     \"TaxId\": \"$TaxId\",\n     \"TaxRate\": \"$TaxRate\",\n     \"TenantId\": \"$TenantId\",\n     \"Terms\": \"$Terms\",\n     \"TotalAmount\": \"$TotalAmount\",\n     \"Vendor\": {\n       \"VendorID\": \"$Vendor:VendorID\",\n       \"VendorName\": \"$Vendor:Name\",\n       \"VendorAddress\": {\n         \"VendorStreetAddress\": \"$Vendor:StreetAddress\",\n         \"VendorPOBox\": \"$Vendor:POBox\",\n         \"VendorLocality\": \"$Vendor:Locality\",\n         \"VendorRegion\": \"$Vendor:Region\",\n         \"VendorPostalCode\": \"$Vendor:PostalCode\",\n         \"VendorCountry\": \"$Vendor:Country\"\n       },\n       \"VendorTelephone\": \"$Vendor:Telephone\",\n       \"VendorCustomerID\": \"$Vendor:CustomerID\",\n       \"VendorStatus\": \"$Vendor:Status\",\n       \"VendorSWIFT\": \"$Vendor:SWIFT\",\n       \"VendorIBAN\": \"$Vendor:IBAN\",\n       \"VendorCustom1\": \"$Vendor:Custom1\",\n       \"VendorCustom2\": \"$Vendor:Custom2\",\n       \"VendorCustom3\": \"$Vendor:Custom3\",\n       \"VendorCustom4\": \"$Vendor:Custom4\",\n       \"VendorCustom5\": \"$Vendor:Custom5\",\n       \"VendorMatched\": \"$Vendor:Matched\"\n     }\n}"
          }
        )
      end,

      webhook_notification: lambda do |input, payload|
        payload
      end,

      webhook_unsubscribe: lambda do |webhook|

        # Get the webhook ID to be removed
        json_output = webhook['data']
        configurationId = (json_output.scan(/configurationId"=>"([\S\s]*)", "integrationId/).dig(0))[0]

        # Delete the webhook
        delete("https://api.us.ephesoft.io/v1/settings/integrations/configurations/#{configurationId}")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["webhook_output"]
      end,
      sample_output: lambda do ||
        {
          AmountDue: '3693.80',
          CustomerId: '123',
          DocumentId: '00000000-0000-0000-0000-000000000000',
          DueDate: '2020-04-15',
          InvoiceDate: '2020-03-29',
          InvoiceNumber: '9291873611',
          OrderDate: '2020-03-29',
          PdfUrl: 'https://semantik.us.ephesoft.io/assets/samples/webhookTestInvoice.pdf',
          PONumber: '8762943181',
          ShipDate: '2020-04-10',
          ShipFreight: '123.45',
          SubTotal: '3358',
          TableUrl: 'https://semantik.us.ephesoft.io/assets/samples/webhookTestInvoiceTable.json'
          TaxAmount: '335.80',
          TaxId: '012-34-56789',
          TaxRate: '10',
          TenantId: '555e4d7e-0115-4ec4-adac-892367844222',
          Terms: 'Net 30 days',
          TotalAmount: '3693.8',
          Vendor: {
            VendorAddress: {
              VendorStreetAddress: '2775 S. 900 W.',
              VendorPOBox: '123',
              VendorLocality: 'Salt Lake City',
              VendorRegion: 'UT',
              VendorPostalCode: '84128-3227',
              VendorCountry: 'US'
            },
            VendorCustom1: 'Custom1',
            VendorCustom2: 'Custom2',
            VendorCustom3: 'Custom3',
            VendorCustom4: 'Custom4',
            VendorCustom5: 'Custom5',
            VendorIBAN: 'aa5d5efa-fcaf-4d2b-a118-a093f184a876',
            VendorCustomerID: '95bba4ab-1897-4e9d-aff1-f42ae7e5cb86',
            VendorID: '1',
            VendorMatched: 'true',
            VendorName: 'Kord Industries',
            VendorStatus: 'active',
            VendorSWIFT: '1b0f74e1-ce62-4d1d-9153-f07e88bc0a29',
            VendorTelephone: '513-101-4074'
          }
        }
      end,
      dedup: lambda do |messages|
        Time.now.to_f
      end
    }
  },
  object_definitions: {
    webhook_output: {
      fields: lambda do
        [
          { name: "AmountDue"},
          { name: "CustomerId"},
          { name: "DocumentId" },
          { name: "DueDate"},
          { name: "InvoiceDate"},
          { name: "InvoiceNumber"},
          { name: "OrderDate"},
          { name: "PdfUrl"},
          { name: "PONumber"},
          { name: "ShipDate"},
          { name: "ShipFreight"},
          { name: "SubTotal"},
          { name: "TableUrl"},
          { name: "TaxAmount"},
          { name: "TaxId"},
          { name: "TaxRate"},
          { name: "TenantId"},
          { name: "Terms"},
          { name: "TotalAmount"},
          {
            name: "Vendor",
            type: :object,
            properties: [
              {
                name: "VendorAddress",
                type: :object,
                properties: [
                  { name: "VendorStreetAddress"},
                  { name: "VendorPOBox"},
                  { name: "VendorLocality"},
                  { name: "VendorRegion"},
                  { name: "VendorPostalCode" },
                  { name: "VendorCounrty"}
                ]
              },
              { name: "VendorCustom1"},
              { name: "VendorCustom2"},
              { name: "VendorCustom3"},
              { name: "VendorCustom4"},
              { name: "VendorCustom5"},
              { name: "VendorIBAN"},
              { name: "VendorCustomerID"},
              { name: "VendorID"},
              { name: "VendorMatched"},
              { name: "VendorName"},
              { name: "VendorStatus"},
              { name: "VendorSWIFT"},
              { name: "VendorTelephone"}
            ]
          }
        ]
      end
    }
  },
  picklists: {},
  methods: {},
}