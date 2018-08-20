{
  title: "ChartMogul",

  connection: {
    fields: [
      {
        name: "account_token",
        label: "Account Token",
        control_type: "text"
      },
      {
        name: "secret_key",
        label: "Secret Key",
        control_type: "password"
      }
    ],

    authorization: {
      type: "custom_auth",

      credentials: lambda do |connection|
        user(connection["account_token"])
        password(connection["secret_key"])
        headers("User-Agent" => "application/json")
      end
    },

    base_uri: lambda do
      "https://api.chartmogul.com"
    end
  },

  test: lambda do |_connection|
    get("/v1/ping")
  end,

  object_definitions: {
    customer: {
      fields: lambda do
        [
          { name: "id", type: "integer", control_type: "number" },
          { name: "uuid", label: "Customer UUID" },
          { name: "external_id", label: "External ID", optional: true,
            hint: "The unique external identifier for this customer" },
          { name: "name", hint: "Name of the customer for display purposes." },
          { name: "email", control_type: "email" },
          { name: "status" },
          { name: "customer-since", type: "date_time",
            control_type: "date_time" },
          { name: "attributes", type: "object", properties: [
            { name: "tags", type: "array", of: "string" },
            { name: "stripe", type: "object", properties: [
              { name: "uid", type: "integer", control_type: "number" },
              { name: "coupon", type: "boolean", control_type: "checkbox" },
            ] },
            { name: "clearbit", type: "object", properties: [
              { name: "id" },
              { name: "name" },
              { name: "legalName" },
              { name: "domain", type: "string", control_type: "url" },
              { name: "url", type: "string", control_type: "url" },
              { name: "metrics", type: "object", properties: [
                  { name: "raised", type: "integer", control_type: "number" },
                  { name: "employees", type: "integer",
                    control_type: "number" },
                  { name: "googleRank", type: "integer",
                    control_type: "number" },
                  { name: "alexaGlobalRank", type: "integer",
                    control_type: "number" },
                  { name: "marketCap", type: "integer", control_type: "number" }
              ] },
              { name: "category", type: "object", properties: [
                { name: "sector" },
                { name: "industryGroup" },
                { name: "industry" },
                { name: "subIndustry" }
              ] }
            ] },
            { name: "custom", type: "object", properties: [
              { name: "CAC", type: "integer", control_type: "number" },
              { name: "utmCampaign" },
              { name: "convertedAt" },
              { name: "pro", type: "boolean", control_type: "checkbox" },
              { name: "salesRep" }
            ] }
          ] },
          { name: "address", type: "object", properties: [
            { name: "address_zip" },
            { name: "city" },
            { name: "state" },
            { name: "country" }
          ] },
          {
            name: "data_source_uuid",
            label: "Data Source",
            hint: "The data source that this customer belongs to",
            control_type: "select",
            pick_list: "data_sources",
            optional: true
          },
          {
            name: "data_source_uuids",
            label: "Data Source UUIDs",
            hint: "An array containing the ChartMogul UUIDs of all data " \
              "sources that contribute data to this customer. " \
              "This is most relevant for merged customers.",
            type: "array",
            of: "string"
          },
          { name: "external_ids", type: "array", of: "string",
            label: "External IDs", optional: true,
            hint: "An array containing the unique external identifiers of all" \
              " customer records that have been merged into this customer" },
          { name: "company" },
          { name: "country",
            hint: "Country code of customer's location, e.g. US,UK,AU." },
          { name: "state",
            hint: "State code of customer's location, e.g. TX,CA,ON." },
          { name: "city", hint: "City of the customer's location." },
          { name: "zip", hint: "Zip code of the customer's location." },
          { name: "lead_created_at" },
          { name: "free_trial_started_at" },
          { name: "mrr", label: "Customer MRR", type: "number" },
          { name: "arr", label: "Customer ARR", type: "number" },
          { name: "billing-system-url", control_type: "url" },
          { name: "chartmogul-url", control_type: "url" },
          { name: "billing-system-type" },
          { name: "currency" },
          { name: "currency-sign" }
        ]
      end
    },

    plan: {
      fields: lambda do
        [
          { name: "uuid", label: "Plan UUID" },
          { name: "name", hint: "Display name of the plan." },
          { name: "data_source_uuid", label: "Data Source",
            hint: "The data source that this plan belongs to",
            control_type: "select", pick_list: "data_sources", optional: true },
          { name: "external_id", optional: true,
            hint: "Typically an identifier from your internal system." },
          { name: "interval_count", type: "integer", control_type: "number",
            hint: "The frequency of billing interval. Accepts integers " \
              "greater than 0. eg. 6 for a half-yearly plan." },
          {
            name: "interval_unit",
            hint: "The unit of billing interval. One of day, month, or " \
              "year. eg. month for the above half-yearly plan.",
            control_type: "select",
            pick_list: [
              %w[Day day],
              %w[Month month],
              %w[Year year]
            ]
          }
        ]
      end
    },

    subscription: {
      fields: lambda do
        [
          { name: "uuid", label: "Subscription UUID" },
          { name: "external_id", label: "External ID" },
          { name: "customer_uuid", label: "Customer UUID" },
          { name: "plan_uuid", label: "Plan UUID" },
          { name: "data_source_uuid", label: "Data Source UUID" },
          { name: "cancellation_dates", type: "array", of: "date_time",
            properties: [] }
        ]
      end
    },

    mrr: {
      fields: lambda do
        [
          { name: "date", type: "date", label: "Date Ending" },
          { name: "mrr", label: "MRR", type: "integer" },
          { name: "mrr-new-business", label: "New Business MRR",
            type: "integer" },
          { name: "mrr-expansion", label: "Expansion MRR", type: "integer" },
          { name: "mrr-contraction", label: "Contraction MRR",
            type: "integer" },
          { name: "mrr-reactivation", label: "Reactivation MRR",
            type: "integer" },
          { name: "mrr-churn", label: "Churn MRR", type: "integer" }
        ]
      end
    },

    customer_count: {
      fields: lambda do
        [
          { name: "date", type: "date" },
          { name: "customers", type: "integer" }
        ]
      end
    },

    customer_churn_count: {
      fields: lambda do
        [
          { name: "date", type: "date" },
          { name: "customers-churn-rate", type: "number" }
        ]
      end
    },

    invoice: {
      fields: lambda do |_object_definitions|
        [
          { name: "uuid", label: "Invoice UUID" },
          { name: "external_id",
            hint: "A unique identifier specified by you for the invoice." },
          { name: "date", type: "date_time",
            hint: "The date on which this invoice was raised." },
          { name: "due_date", type: "date_time",
            hint: "The date within which this invoice must be paid." },
          { name: "currency",
            hint: "The 3-letter currency code of the currency in which " \
              "this invoice is being billed, e.g. USD, EUR, GBP." },
          { name: "line_items", type: "array", of: "object", properties: [
            { name: "uuid", label: "Item UUID" },
            { name: "external_id" },
            { name: "type" },
            { name: "subscription_uuid" },
            { name: "plan_uuid" },
            { name: "prorated", type: "boolean" },
            { name: "service_period_start", type: "date_time" },
            { name: "service_period_end", type: "date_time" },
            { name: "amount_in_cents", type: "integer", label: "Amount" },
            { name: "quantity", type: "integer" },
            { name: "discount_code" },
            { name: "discount_amount_in_cents", type: "integer",
              label: "Discount Amount" },
            { name: "tax_amount_in_cents", type: "integer",
              label: "Tax Amount" },
            { name: "account_code" }
          ] },
          { name: "transactions", type: "array", of: "object", properties: [
            { name: "uuid", label: "Transaction UUID" },
            { name: "external_id" },
            { name: "type", control_type: "select", pick_list: [
              %w[Payment payment],
              %w[Refund refund]
            ] },
            { name: "date", type: "date_time" },
            { name: "result", control_type: "select", pick_list: [
              %w[Successful successful],
              %w[Failed failed]
            ] }
          ] }
        ]
      end
    },

    transaction: {
      fields: lambda do
        [
          { name: "uuid", label: "Transaction UUID" },
          { name: "external_id", sticky: true,
            hint: "A unique identifier specified by you for the transaction. " \
              "Typically an identifier from your internal system." },
          { name: "type", optional: false, hint: "Either payment or refund" },
          { name: "date",
            optional: false,
            type: "date_time",
            control_type: "date_time",
            hint: "The timestamp of when the transaction was attempted." },
          { name: "result", optional: false,
            hint: "Either successful or failed" }
        ]
      end
    }
  },

  methods: {
    invoice_output: lambda do
      {
        "customer_uuid": "cus_f466e33d-ff2b-4a11-8f85-417eb02157a7",
        "invoices": [
          {
            "uuid": "inv_565c73b2-85b9-49c9-a25e-2b7df6a677c9",
            "external_id": "INV0001",
            "date": "2015-11-01T00:00:00.000Z",
            "due_date": "2015-11-15T00:00:00.000Z",
            "currency": "USD",
            "line_items": [
              {
                "uuid": "li_d72e6843-5793-41d0-bfdf-0269514c9c56",
                "external_id": "null",
                "type": "subscription",
                "subscription_uuid": "sub_e6bc5407-e258-4de0-bb43-61faaf062035",
                "subscription_external_id": "sub_0001",
                "plan_uuid": "pl_eed05d54-75b4-431b-adb2-eb6b9e543206",
                "prorated": false,
                "service_period_start": "2015-11-01T00:00:00.000Z",
                "service_period_end": "2015-12-01T00:00:00.000Z",
                "amount_in_cents": 5000,
                "quantity": 1,
                "discount_code": "PSO86",
                "discount_amount_in_cents": 1000,
                "tax_amount_in_cents": 900,
                "transaction_fees_in_cents": 200,
                "account_code": "null"
              },
              {
                "uuid": "li_0cc8c112-beac-416d-af11-f35744ca4e83",
                "external_id": "null",
                "type": "one_time",
                "description": "Setup Fees",
                "amount_in_cents": 2500,
                "quantity": 1,
                "discount_code": "PSO86",
                "discount_amount_in_cents": 500,
                "tax_amount_in_cents": 450,
                "transaction_fees_in_cents": 0,
                "account_code": "null"
              }
            ],
            "transactions": [
              {
                "uuid": "tr_879d560a-1bec-41bb-986e-665e38a2f7bc",
                "external_id": "null",
                "type": "payment",
                "date": "2015-11-05T00:14:23.000Z",
                "result": "successful"
              }
            ]
          }
        ],
        "current_page": 1,
        "total_pages": 1
      }
    end,

    customer_output: lambda do
      {
        "id": 25647,
        "uuid": "cus_de305d54-75b4-431b-adb2-eb6b9e546012",
        "external_id": "34916129",
        "name": "Example Company",
        "email": "bob@examplecompany.com",
        "status": "Active",
        "customer-since": "2015-06-09T13:16:00-04:00",
        "attributes": {
          "tags": ["engage", "unit loss", "discountable"],
          "stripe": {
            "uid": 7,
            "coupon": true
          },
          "clearbit": {
            "id": "027b0d40-016c-40ea-8925-a076fa640992",
            "name": "Acme",
            "legalName": "Acme Inc.",
            "domain": "acme.com",
            "url": "http://acme.com",
            "metrics": {
              "raised": 1502450000,
              "employees": 1000,
              "googleRank": 7,
              "alexaGlobalRank": 2319,
              "marketCap": "null"
            },
            "category": {
              "sector": "Information Technology",
              "industryGroup": "Software and Services",
              "industry": "Software",
              "subIndustry": "Application Software"
            }
          },
          "custom": {
            "CAC": 213,
            "utmCampaign": "social media 1",
            "convertedAt": "2015-09-08 00:00:00",
            "pro": false,
            "salesRep": "Gabi"
          }
        },
        "address": {
          "address_zip": "0185128",
          "city": "Nowhereville",
          "state": "Alaska",
          "country": "US"
        },
        "data_source_uuid": "ds_fef05d54-47b4-431b-aed2-eb6b9e545430",
        "data_source_uuids": ["ds_fef05d54-47b4-431b-aed2-eb6b9e545430"],
        "external_ids": ["34916129"],
        "company": "",
        "country": "US",
        "state": "Alaska",
        "city": "Nowhereville",
        "zip": "0185128",
        "lead_created_at": "null",
        "free_trial_started_at": "null",
        "mrr": 3000,
        "arr": 36000,
        "billing-system-url": "https:\/\/dashboard.stripe.com\/customers\/cus_4Z2ZpyJFuQ0XMb",
        "chartmogul-url": "https:\/\/app.chartmogul.com\/#customers\/25647-Example_Company",
        "billing-system-type": "Stripe",
        "currency": "USD",
        "currency-sign": "$"
      }
    end,

    format_api_input_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call("format_api_input_field_names", array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call("format_api_input_field_names", value)
          { key.gsub("_hypen_", "-") => value }
        end.inject(:merge)
      else
        input
      end
    end,

    format_api_output_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call("format_api_output_field_names",  array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call("format_api_output_field_names", value)
          { key.gsub("-", "_hypen_") => value }
        end.inject(:merge)
      else
        input
      end
    end,

    format_schema_field_names: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call("format_schema_field_names",
                                    field[:properties])
        end
        field[:name] = field[:name].gsub("-", "_hypen_")
        field
      end
    end
  },

  actions: {
    get_invoices_by_customer: {
      description: "Get <span class='provider'>invoices</span> by customer " \
        "in <span class='provider'>ChartMogul</span>",

      input_fields: lambda do
        [
          {
            name: "customer_uuid",
            label: "Customer UUID",
            optional: false,
            hint: "The ChartMogul UUID of the Customer whose invoices " \
              "are requested."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/import/customers/#{input['customer_uuid']}/invoices")
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "customer_uuid" },
          {
            name: "invoices",
            type: "array",
            of: "object",
            properties: object_definitions["invoice"]
          }
        ]
      end,

      sample_output: lambda do |_connection|
        call(:invoice_output)
      end
    },

    create_invoice: {
      description: "Create <span class='provider'>invoice</span> with line " \
        "items in <span class='provider'>ChartMogul</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["invoice"].
          required("external_id", "date", "currency").
          ignored("uuid", "line_items", "transactions").
          concat(
            [
              {
                name: "customer_uuid",
                hint: "The ChartMogul UUID of the Customer that these " \
                  "invoices belong to.",
                optional: false
              },
              {
                name: "line_items",
                type: "array",
                of: "object",
                hint: "List of invoice line items",
                properties: [
                  {
                    name: "external_id",
                    label: "External ID",
                    hint: "A unique identifier specified by you for the line " \
                      "item. Typically an identifier from your internal " \
                      "system.",
                    sticky: true
                  },
                  {
                    name: "type",
                    optional: false,
                    hint: "One of either subscription or one_time."
                  },
                  {
                    name: "subscription_external_id",
                    label: "Subscription External ID",
                    hint: "A reference identifier for the subscription in " \
                      "your system."
                  },
                  {
                    name: "plan_uuid",
                    label: "Plan UUID",
                    hint: "The ChartMogul UUID of the plan for which this " \
                      "subscription is being charged."
                  },
                  {
                    name: "prorated",
                    type: "boolean"
                  },
                  {
                    name: "service_period_start",
                    label: "Service Period Start",
                    type: "date_time",
                    hint: "The start of the service period for which this " \
                      "subscription is being charged."
                  },
                  {
                    name: "service_period_end",
                    label: "Service Period End",
                    type: "date_time",
                    hint: "The end of the service period for which this " \
                      "subscription is being charged."
                  },
                  {
                    name: "cancelled_at",
                    label: "Cancelled At",
                    type: "date_time",
                    hint: "If this subscription has been cancelled, the time " \
                      "of cancellation."
                  },
                  {
                    name: "amount_in_cents",
                    type: "number",
                    label: "Amount",
                    optional: false,
                    hint: "The line item's amount, in dollars, for the " \
                      "specified quantity and service period after discounts " \
                      "and taxes."
                  },
                  {
                    name: "quantity",
                    type: "integer",
                    hint: "The quantity of this line item being billed. " \
                      "Defaults to 1.",
                    sticky: true
                  },
                  {
                    name: "discount_code",
                    hint: "If a discount has been applied to this line item, " \
                      "then an optional reference code to identify the " \
                      "discount."
                  },
                  {
                    name: "discount_amount_in_cents",
                    type: "number",
                    label: "Discount Amount",
                    hint: "If any discount has been applied to this line item" \
                      ", then the discount amount in dollars. Defaults to 0."
                  },
                  {
                    name: "tax_amount_in_cents",
                    type: "number",
                    label: "Tax Amount",
                    hint: "The tax that has been applied to this line item, " \
                      "in dollars. Defaults to 0."
                  },
                  {
                    name: "account_code"
                  },
                  {
                    name: "description",
                    hint: "A short description of the non-recurring item " \
                      "being charged to the customer. Used if line item is " \
                      "One-Time"
                  }
                ]
              }
            ]
          )
      end,

      execute: lambda do |_connection, input|
        input["date"] = input["date"].to_time.iso8601
        input["currency"] = input["currency"].to_currency_code

        if input["due_date"].present?
          input["due_date"] = input["due_date"].to_time.iso8601
        end

        input["line_items"] = input["line_items"].each do |object|
          object.each do |key, value|
            if key.include?("_in_cents") && value.present?
              # Transform dollar values to cents as required by API
              object[key] = (value.to_f * 100).to_i
            elsif (key.include?("service_period") && value.present?) ||
              (key == "cancelled_at" && value.present?)
              # Transform date values to ISO 8601
              object[key] = value.to_time.iso8601
            elsif key == "quantity" && value.present?
              object[key] = value.to_i
            end
          end
        end

        post("/v1/import/customers/#{input['customer_uuid']}/invoices").
          payload(
            # API requires an array of invoices
            invoices: [input]
          )["invoices"].first
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "customer_uuid" },
          {
            name: "invoices",
            type: "array",
            of: "object",
            properties: object_definitions["invoice"]
          }
        ]
      end,

      sample_output: lambda do |_connection|
        call(:invoice_output)
      end
    },

    create_transaction: {
      description: "Create <span class='provider'>transaction</span> in " \
        "<span class='provider'>ChartMogul</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["transaction"].
          required("date").
          ignored("uuid").
          concat(
            [
              {
                name: "invoice_uuid",
                label: "Invoice UUID",
                hint: "The ChartMogul UUID of the invoice to tag this " \
                  "transaction to.",
                optional: false
              }
            ]
          )
      end,

      execute: lambda do |_connection, input|
        request = input.reject { |key, _value| key == "invoice_uuid" }
        post("/v1/import/invoices/#{input['invoice_uuid']}/transactions").
          payload(request)
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "customer_uuid" },
          {
            name: "invoices",
            type: "array",
            of: "object",
            properties: object_definitions["invoice"]
          }
        ]
      end,

      sample_output: lambda do |_connection|
        call(:invoice_output)
      end
    },

    get_customer: {
      description: "Get <span class='provider'>customer</span> in " \
        "<span class='provider'>ChartMogul</span>",

      input_fields: lambda do |object_definitions|
        [
          name: "customer_uuid", optional: false, label: "Customer UUID",
          hint: "The ChartMogul UUID of the customer you are retrieving."
        ]
      end,

      execute: lambda do |_connection, input|
        response = get("/v1/customers/#{input['customer_uuid']}")
        if response.present?
          response.each do |k, v|
            if k == "mrr"
              response[k] = (v.to_f / 100)
            elsif k == "arr"
              response[k] = (v.to_f / 100)
            end
          end
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["customer"]
      end,

      sample_output: lambda do |_connection|
        call(:customer_output)
      end
    },

    create_customer: {
      description: "Create <span class='provider'>customer</span> in " \
        "<span class='provider'>ChartMogul</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["customer"].
          required("external_id", "name").
          ignored("uuid", "mrr", "arr", "chartmogul_url", "status", "currency").
          concat(
            [
              { name: "lead_created_at", type: "timestamp",
                hint: "Time at which this customer was established as a " \
                  "lead." },
              { name: "free_trial_started_at", type: "date_time",
                hint: "Time at which this customer started a free trial of " \
                  "your product or service. This is expected to be the same " \
                  "as, or after the lead created at value." }
            ]
          )
      end,

      execute: lambda do |_connection, input|
        request = input.each do |k, v|
          if k == "country"
            input[k] = v.to_country_alpha2
          elsif k == "state"
            input[k] = v.to_state_code
          end
        end

        post("/v1/customers", request)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["customer"]
      end,

      sample_output: lambda do |_connection|
        call(:customer_output)
      end
    },

    update_customer: {
      description: "Update <span class='provider'>customer</span> in " \
        "<span class='provider'>ChartMogul</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["customer"].
          required("uuid").
          ignored("mrr", "arr", "chartmogul_url", "status", "currency").
          concat(
            [
              { name: "lead_created_at", type: "timestamp",
                hint: "Time at which this customer was established as a " \
                  "lead." },
              { name: "free_trial_started_at", type: "date_time",
                hint: "Time at which this customer started a free trial of " \
                  "your product or service. This is expected to be the same " \
                  "as, or after the lead created at value." }
            ]
          )
      end,

      execute: lambda do |_connection, input|
        request = input.each do |k, v|
          if k == "country"
            input[k] = v.to_country_alpha2
          elsif k == "state"
            input[k] = v.to_state_code
          end
        end

        patch("/v1/customers/#{input['uuid']}", request)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["customer"]
      end,

      sample_output: lambda do |_connection|
        call(:customer_output)
      end
    },

    search_plans: {
      description: "Search <span class='provider'>plans</span> in " \
        "<span class='provider'>ChartMogul</span>",
      help: "Returns a maximum of 100 records.",

      input_fields: lambda do |object_definitions|
        object_definitions["plan"].
          only("external_id", "data_source_uuid").
          concat(
            [
              { name: "system",
                hint: "An optional filter parameter, for the billing system " \
                  "that the plan belongs to. Possible values: Stripe, " \
                  "Recurly, Chargify, or Import API" }
            ]
          )
      end,

      execute: lambda do |_connection, input|
        {
          plans: get("/v1/plans", input).params(per_page: 100)["plans"]
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "plans", type: "array", of: "object",
            properties: object_definitions["plan"] }
        ]
      end,

      sample_output: lambda do |_connection|
        get("/v1/plans", per_page: 1) || {}
      end
    },

    create_plan: {
      description: "Create <span class='provider'>plan</span> in " \
        "<span class='provider'>ChartMogul</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["plan"].
          required("name", "interval_count").
          ignored("uuid").
          concat([{ name: "interval", hint: "One of day, month or year" }])
      end,

      execute: lambda do |_connection, input|
        input["interval_unit"] ||= input["interval"]
        input = input.reject { |k, _v| k == "interval" }
        input["interval_count"] = input["interval_count"].to_i

        post("/v1/plans", input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["plan"]
      end,

      sample_output: lambda do |_connection|
        get("/v1/plans", per_page: 1)["plans"].first || {}
      end
    },

    get_subscriptions_by_customer: {
      description: "Get <span class='provider'>subscriptions</span> by " \
        "customer in <span class='provider'>ChartMogul</span>",

      input_fields: lambda do
        [
          {
            name: "customer_uuid",
            label: "Customer UUID",
            optional: false,
            hint: "The ChartMogul UUID of the customer whose subscriptions " \
              "are requested."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/import/customers/#{input['customer_uuid']}/subscriptions")
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "customer_uuid", label: "Customer UUID" },
          {
            name: "subscriptions",
            type: "array",
            of: "object",
            properties: object_definitions["subscription"].
                          only("uuid", "external_id", "plan_uuid",
                               "data_source_uuid", "cancellation_dates")
          }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "customer_uuid": "cus_f466e33d-ff2b-4a11-8f85-417eb02157a7",
          "subscriptions":[
            {
              "uuid": "sub_e6bc5407-e258-4de0-bb43-61faaf062035",
              "external_id": "sub_0001",
              "plan_uuid": "pl_eed05d54-75b4-431b-adb2-eb6b9e543206",
              "data_source_uuid": "ds_fef05d54-47b4-431b-aed2-eb6b9e545430",
              "cancellation_dates":[]
            }
          ]
        }
      end
    },

    cancel_customer_subscription: {
      description: "Cancel a <span class='provider'>subscription</span> in " \
        "<span class='provider'>ChartMogul</span>",

      input_fields: lambda do
        [
          {
            name: "subscription_uuid",
            label: "Subscription UUID",
            hint: "The ChartMogul UUID of the subscription that needs to be " \
              "cancelled.",
            optional: false
          },
          {
            name: "cancelled_at",
            label: "Cancelled At",
            type: "date_time",
            control_type: "date_time",
            hint: "The time at which the subscription was cancelled."
          },
          {
            name: "cancellation_dates",
            label: "Cancellation Dates",
            type: "string",
            control_type: "text",
            hint: "Comma separated string of cancellation dates for this " \
              "subscription."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        params = input.reject { |k, _v| k == "subscription_uuid" }
        if input["cancelled_at"].present?
          params = params.reject { |k, _v| k == "cancellation_dates" }
        elsif input["cancellation_dates"].present?
          params = params.reject { |k, _v| k == "cancelled_at" }
          dates = []
          input["cancellation_dates"].split(",").each do |value|
            dates << value.to_time.iso8601
          end
          params["cancellation_dates"] = dates
        else
          params = ""
        end

        patch("/v1/import/subscriptions/#{input['subscription_uuid']}", params)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["subscription"]
      end,

      sample_output: lambda do |_connection|
        {
          "uuid": "sub_e6bc5407-e258-4de0-bb43-61faaf062035",
          "external_id": "sub_0001",
          "customer_uuid": "cus_f466e33d-ff2b-4a11-8f85-417eb02157a7",
          "plan_uuid": "pl_eed05d54-75b4-431b-adb2-eb6b9e543206",
          "cancellation_dates": ["2016-01-15T00:00:00.000Z"],
          "data_source_uuid": "ds_fef05d54-47b4-431b-aed2-eb6b9e545430"
        }
      end
    },

    get_mrr: {
      title: "Get MRR",
      subtitle: "Get Monthly Recurring Revenue (MRR)",
      description: "Get <span class='provider'>MRR</span> in " \
        "<span class='provider'>ChartMogul</span>",

      input_fields: lambda do
        [
          {
            name: "start_date",
            type: "date",
            control_type: "date",
            optional: false
          },
          {
            name: "end_date",
            type: "date",
            control_type: "date",
            optional: false
          },
          {
            name: "interval",
            control_type: "select",
            pick_list: "intervals",
            hint: "Analysis period, e.g. Quarter returns MRR by quarter"
          }
        ]
      end,

      execute: lambda do |_connection, input|
        request = {
          "start-date" => input["start_date"].to_date.iso8601,
          "end-date" => input["end_date"].to_date.iso8601
        }

        if input["interval"].present?
          request["interval"] = input["interval"]
        end

        response = get("/v1/metrics/mrr", request)

        output = {
          "entries" => response["entries"],
          "summary" => {
            "current" => response["summary"]["current"],
            "previous" => response["summary"]["previous"],
            "percentage_change" => response["summary"]["percentage-change"]
          }
        }

        output
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "entries",
            type: "array",
            of: "object",
            properties: object_definitions["mrr"]
          },
          {
            name: "summary",
            type: "object",
            properties: [
              { name: "current", type: "integer" },
              { name: "previous", type: "integer" },
              { name: "percentage_change", type: "number" }
            ]
          }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "entries":[
            {
              "date":"2015-01-03",
              "mrr":30000,
              "mrr-new-business":10000,
              "mrr-expansion":15000,
              "mrr-contraction":0,
              "mrr-churn":0,
              "mrr-reactivation":0
            }
          ],
          "summary":{
            "current":43145000,
            "previous":43145000,
            "percentage-change":0.0
          }
        }
      end
    },

    get_customer_count: {
      description: "Get <span class='provider'>number of customers</span> " \
        "in <span class='provider'>ChartMogul</span>",

      input_fields: lambda do
        [
          { name: "start_date", type: "date", optional: false },
          { name: "end_date", type: "date", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/metrics/customer-count").
          params(
            "start-date": input["start_date"].to_date.iso8601,
            "end-date": input["end_date"].to_date.iso8601
          )
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "entries",
            type: "array",
            of: "object",
            properties: object_definitions["customer_count"]
          },
          {
            name: "summary",
            type: "object",
            properties: [
              { name: "current", type: "integer" },
              { name: "previous", type: "integer" },
              { name: "percentage", type: "number" }
            ]
          }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "entries":[
            {
              "date":"2015-07-31",
              "customers":382
            }
          ],
          "summary":{
            "current":382,
            "previous":379,
            "percentage-change":0.8
          }
        }
      end
    },

    get_customer_churn_count: {
      description: "Get <span class='provider'>number of customer churns" \
        "</span> in <span class='provider'>ChartMogul</span>",

      input_fields: lambda do
        [
          { name: "start_date", type: "date", optional: false },
          { name: "end_date", type: "date", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/metrics/customer-churn-rate").
          params(
            "start-date": input["start_date"].to_date.iso8601,
            "end-date": input["end_date"].to_date.iso8601
          )
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "entries",
            type: "array",
            of: "object",
            properties: object_definitions["customer_churn_count"]
          },
          {
            name: "summary",
            type: "object",
            properties: [
              { name: "current", type: "number" },
              { name: "previous", type: "number" },
              { name: "percentage", type: "number" }
            ]
          }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "entries":[
            {
              "date":"2015-01-31",
              "customer-churn-rate":9.8
            }
          ],
          "summary":{
            "current":9.8,
            "previous":8.5,
            "percentage-change":2
          }
        }
      end
    }
  },

  pick_lists: {
    data_sources: lambda do |_connection|
      get("/v1/import/data_sources")["data_sources"].
        pluck("name", "uuid")
    end,

    intervals: lambda do
      [
        %w[Day day],
        %w[Week week],
        %w[Month month],
        %w[Quarter quarter]
      ]
    end
  }
}
