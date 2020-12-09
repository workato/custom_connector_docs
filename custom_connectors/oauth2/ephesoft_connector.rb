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
          }
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
      title: 'New complete Semantik invoice',
      description: 'Triggers when a Semantik invoice is completed',
      webhook_subscribe: lambda do |webhook_url, connection, input, recipe_id|
        payload = {
          "AmountDue": "$AmountDue",
          "DocumentId": "$DocumentId",
          "DueDate": "$DueDate",
          "FileName": "$FileName",
          "InvoiceDate": "$InvoiceDate",
          "InvoiceNumber": "$InvoiceNumber",
          "OrderDate": "$OrderDate",
          "PdfUrl": "$PdfUrl",
          "PONumber": "$PONumber",
          "ShipDate": "$ShipDate",
          "ShipFreight": "$ShipFreight",
          "SubTotal": "$SubTotal",
          "TableUrl": "$TableUrl",
          "TaxAmount": "$TaxAmount",
          "TaxId": "$TaxId",
          "TaxRate": "$TaxRate",
          "TenantId": "$TenantId",
          "Terms": "$Terms",
          "TotalAmount": "$TotalAmount",
          "Vendor": {
            "VendorAddress": {
              "VendorStreetAddress": "$Vendor:StreetAddress",
              "VendorPOBox": "$Vendor:POBox",
              "VendorLocality": "$Vendor:Locality",
              "VendorRegion": "$Vendor:Region",
              "VendorPostalCode": "$Vendor:PostalCode",
              "VedorCountry": "$Vendor:Country"
            },
            "VendorCustom1": "$Vendor:Custom1",
            "VendorCustom2": "$Vendor:Custom2",
            "VendorCustom3": "$Vendor:Custom3",
            "VendorCustom4": "$Vendor:Custom4",
            "VendorCustom5": "$Vendor:Custom5",
            "VendorCustomerID": "$Vendor:CustomerID",
            "VendorIBAN": "$Vendor:IBAN",
            "VendorID": "$Vendor:VendorID",
            "VendorMatched": "$Vendor:Matched",
            "VendorName": "$Vendor:Name",
            "VendorStatus": "$Vendor:Status",
            "VendorSWIFT": "$Vendor:SWIFT",
            "VendorTelephone": "$Vendor:Telephone"
          }
        }
        post("https://api.us.ephesoft.io/v1/settings/integrations/configurations",
          integrationName: "Workato Recipe #{recipe_id}",
          integrationType: "webhook",
          enabled: true,
          settings: {
            targetUrl: webhook_url,
            encoding: "application/json",
            payload: payload.to_json.to_s
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
          DocumentId: '00000000-0000-0000-0000-000000000000',
          DueDate: '2020-04-15',
          FileName: 'Kord-Invoice9291873611.pdf',
          InvoiceDate: '2020-03-29',
          InvoiceNumber: '9291873611',
          OrderDate: '2020-03-29',
          PdfUrl: 'https://semantik.us.ephesoft.io/assets/samples/webhookTestInvoice.pdf',
          PONumber: '8762943181',
          ShipDate: '2020-04-10',
          ShipFreight: '123.45',
          SubTotal: '3358',
          TableUrl: 'https://semantik.us.ephesoft.io/assets/samples/webhookTestInvoiceTable.json',
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
          { name: "AmountDue", type: "string"},
          { name: "CustomerId", type: "string"},
          { name: "DocumentId", type: "string"},
          { name: "DueDate", type: "string"},
          { name: "FileName", type: "string"},
          { name: "InvoiceDate", type: "string"},
          { name: "InvoiceNumber", type: "string"},
          { name: "OrderDate", type: "string"},
          { name: "PdfUrl", type: "string"},
          { name: "PONumber", type: "string"},
          { name: "ShipDate", type: "string"},
          { name: "ShipFreight", type: "string"},
          { name: "SubTotal", type: "string"},
          { name: "TableUrl", type: "string"},
          { name: "TaxAmount", type: "string"},
          { name: "TaxId", type: "string"},
          { name: "TaxRate", type: "string"},
          { name: "TenantId", type: "string"},
          { name: "Terms", type: "string"},
          { name: "TotalAmount", type: "string"},
          {
            name: "Vendor",
            type: :object,
            properties: [
              {
                name: "VendorAddress",
                type: :object,
                properties: [
                  { name: "VendorStreetAddress", type: "string"},
                  { name: "VendorPOBox", type: "string"},
                  { name: "VendorLocality", type: "string"},
                  { name: "VendorRegion", type: "string"},
                  { name: "VendorPostalCode", type: "string"},
                  { name: "VendorCountry", type: "string"}
                ]
              },
              { name: "VendorCustom1", type: "string"},
              { name: "VendorCustom2", type: "string"},
              { name: "VendorCustom3", type: "string"},
              { name: "VendorCustom4", type: "string"},
              { name: "VendorCustom5", type: "string"},
              { name: "VendorIBAN", type: "string"},
              { name: "VendorCustomerID", type: "string"},
              { name: "VendorID", type: "string"},
              { name: "VendorMatched", type: "string"},
              { name: "VendorName", type: "string"},
              { name: "VendorStatus", type: "string"},
              { name: "VendorSWIFT", type: "string"},
              { name: "VendorTelephone", type: "string"}
            ]
          }
        ]
      end
    }
  },
  picklists: {},
  methods: {},
}