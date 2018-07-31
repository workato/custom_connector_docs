{
  title: "Paypal",

  connection: {
    fields: [
      {
        name: "environment",
        optional: false,
        control_type: :select,
        pick_list: [
          ["Production", "paypal.com"],
          ["Sandbox", "sandbox.paypal.com"]
        ]
      },
      {
        name: "client_id",
        label: "Client ID",
        optional: false
      },
      {
        name: "client_secret",
        label: "Client secret",
        optional: false,
        control_type: :password
      }
    ],

    authorization: {
      type: "custom_auth",

      authorization_url: lambda do |connection|
        scopes = ["openid","https://uri.paypal.com/services/subscriptions",
          "https://api.paypal.com/v1/payments/.*"].join(" ")
        params = {
          response_type: "code",
          client_id: "#{connection['client_id']}",
          scope: scopes
        }.to_param
        "https://www.#{connection['environment']}/signin/authorize?" + params
      end,
      acquire: lambda do |connection|
        hash = "#{connection['client_id']}:#{connection['client_secret']}".
          encode_base64
        {
          access_token: (post("https://api.#{connection['environment']}/"\
              "v1/oauth2/token").
              headers(Accept: "application/json",
                "Accept-Language": "en_US",
                Authorization: "Basic #{hash}").
              payload(grant_type: "client_credentials").
              request_format_www_form_urlencoded)["access_token"]
        }
      end,
      refresh_on: 401,
      apply: lambda do |connection|
        headers(Authorization: "Bearer #{connection['access_token']}")
      end
    },

    base_uri: lambda do |connection|
      "https://api.#{connection['environment']}"
    end
  },

  object_definitions: {
    invoice: {
      fields: lambda do
        [
          { name: "id", label: "ID" },
          { name: "number", label: "Invoice number" },
          { name: "status" },
          { name: "merchant_info", type: :object,
            label: "Merchant information",
            properties: [
              { name: "first_name", type: :string },
              { name: "last_name", type: :string },
              { name: "business_name", type: :string,
                label: "Business name" },
              { name: "email", type: :string,
                control_type: :text, label: "Email" },
              { name: "phone", type: :object, properties: [
                { name: "country_code", type: :string,
                  label: "Country code" },
                { name: "national_number",
                  label: "Phone number", control_type: :phone }
              ]},
              { name: "fax", type: :object, properties: [
                { name: "country_code", type: :string,
                  label: "Country code" },
                { name: "national_number", label: "Phone number",
                  control_type: :phone }
              ]},
              { name: "address", type: :object, properties: [
                { name: "line1", label: "Address line 1" },
                { name: "line2", label: "Address line 2" },
                { name: "city" },
                { name: "state" },
                { name: "postal_code" },
                { name: "country_code" },
                { name: "phone", control_type: :phone }
              ]},
              { name: "website", type: :string },
              { name: "tax_id", type: :string,
                label: "Tax ID" },
              { name: "additional_info", type: :string,
                label: "Additional information" }
            ]},
          { name: "billing_info", type: :array, of: :object,
            label: "Billing information",
            properties: [
              { name: "phone", type: :object, properties: [
                { name: "country_code", type: :string,
                  label: "Country code" },
                { name: "national_number",
                  label: "Phone number", control_type: :phone }
              ]},
              { name: "first_name" },
              { name: "last_name" },
              { name: "email", control_type: :email },
              { name: "business_name" },
              { name: "address", type: :object, properties: [
                { name: "line1", label: "Address line 1" },
                { name: "line2", label: "Address line 2" },
                { name: "city" },
                { name: "state" },
                { name: "postal_code" },
                { name: "country_code" },
                { name: "phone", control_type: :phone }
              ]},
              { name: "additional_info", type: :string,
                label: "Additional information" }
            ]},
          { name: "shipping_info", type: :object,
            label: "Shipping information",
            properties: [
              { name: "first_name" },
              { name: "last_name" },
              { name: "business_name" },
              { name: "address", type: :object, properties: [
                { name: "line1", label: "Address line 1" },
                { name: "line2", label: "Address line 2" },
                { name: "city" },
                { name: "state" },
                { name: "postal_code" },
                { name: "country_code" },
                { name: "phone", control_type: :phone }
              ]}
            ]},
          { name: "cc_info", type: :array, of: :object,
            label: "CC addressee",
            properties: [
              { name: "email", control_type: :email }
            ]},
          { name: "items", type: :array, of: :object, properties: [
            { name: "name" },
            { name: "description", type: :string,
              control_type: "text-area" },
            { name: "quantity", type: :integer, control_type: :number },
            { name: "unit_price", type: :object, properties: [
              { name: "currency" },
              { name: "value", type: :string,
                control_type: :number }
            ]},
            { name: "tax", type: :object, control_type: :text,
              properties: [
                { name: "name" },
                { name: "percent", type: :integer, control_type: :number,
                  hint: "The tax rate. Value is from 0 to 100. Supports up to "\
                    "five decimal places." },
                { name: "amount", type: :object,
                  hint: "The calculated tax amount. (Read Only)",
                  properties: [
                    { name: "currency" },
                    { name: "value", type: :string, control_type: :number }
                  ]}
              ]},
            { name: "date", hint: "The date when the item or service was "\
                "provided in yyyy-MM-dd z." },
            { name: "discount", type: :object, properties: [
              { name: "percent", type: :integer,
                control_type: :number,
                hint: "The discount as a percentage value. Value is from " \
                  "0 to 100. Supports up to five decimal places." },
              { name: "amount", type: :object, hint: "The invoice level "\
                  "discount amount. Value is from 0 to 1000000. Supports up to"\
                  " two decimal places.",
                properties: [
                  { name: "currency" },
                  { name: "value", type: :string, control_type: :number }
                ]}
            ]},
            { name: "unit_of_measure", type: "select",
              pick_list: "units", toggle_hint: "Select from list",
              toggle_field: { name: "unit_of_measure",
                label: "Unit of Measure",
                type: :string, control_type: :text,
                toggle_hint: "Use custom value",
                hint: "Possible values: QUANTITY, HOURS, AMOUNT" }
            }
          ]},
          { name: "invoice_date", label: "Invoice date",
            hint: "The invoice date as specificed by the sender"\
              " e.g. yyyy-MM-dd z" },
          { name: "payment_term", type: :object, properties: [
            { name: "term_type", control_type: :select,
              pick_lists: :payment_terms },
            { name: "due_date", type: :string, control_type: :date,
              hint: "The date when the invoice payment is due" }
          ]},
          { name: "reference" },
          { name: "discount", type: :object,
            hint: "The invoice level discount, as a percent or an "\
              "amount value.",
            properties: [
              { name: "percent", type: :integer,
                control_type: :number,
                hint: "The discount as a percentage value from 0 to 100. " \
                  "Supports up to five decimal places." },
              { name: "amount", type: :object,
                hint: "The invoice level discount amount. Value is "\
                  "from 0 to 1000000. Supports up to two decimal places.",
                properties: [
                  { name: "currency" },
                  { name: "value", type: :string,
                    control_type: :number }
                ]}
            ]},
          { name: "shipping_cost", type: :object,
            properties: [
              { name: "amount", type: :object,
                hint: "The invoice level discount amount. Value is"\
                  " from 0 to 1000000. Supports up to two decimal places.",
                properties: [
                  { name: "currency" },
                  { name: "value", type: :string,
                    control_type: :number }
                ]},
              { name: "tax", type: :object, properties: [
                { name: "name" },
                { name: "percent", type: :number, control_type: :number,
                  hint: "The tax rate. Value is from 0 to 100. "\
                    "Supports up to five decimal places." },
                { name: "amount", type: :object,
                  hint: "The calculated tax amount. (Read Only)",
                  properties: [
                    { name: "currency" },
                    { name: "value", type: :string,
                      control_type: :number }
                  ]}
              ]}
            ]},
          { name: "custom", type: :object,
            hint: "Custom amount to apply to an invoice. If label is " \
              "included, you must include a custom amount.",
            label: "Custom amount", properties: [
              { name: "label" },
              { name: "amount", type: :object,
                hint: "The calculated tax amount. (Read Only)",
                properties: [
                  { name: "currency", type: :string },
                  { name: "value", type: :string, control_type: :number,
                    hint: "Value is from -1000000 to 1000000" }
                ]}
            ]},
          { name: "allow_partial_payment", type: :boolean },
          { name: "minimum_amount_due", type: :object,
            hint: "The minimum amount allowed for a partial payment. " \
              "Valid only if allow partial payment is <code>true</code>.",
            properties: [
              { name: "currency" },
              { name: "value", type: :string,
                control_type: :number }
            ]},
          { name: "tax_calculated_after_discount",
            type: :boolean,
            hint: "Indicates whether the tax is calculated before or " \
              "after a discount. false if calculated before discount, true if " \
              "calculated after discount" },
          { name: "tax_inclusive", type: :boolean,
            hint: "Indicates whether the unit price includes tax." },
          { name: "terms", type: :string, control_type: "text-area" },
          { name: "note", type: :string, control_type: "text-area" },
          { name: "merchant_memo" },
          { name: "logo_url", type: :string,
            control_type: :url },
          { name: "total_amount", type: :object,
            hint: "Total amount of the invoice. ",
            properties: [
              { name: "currency" },
              { name: "value", type: :string,
                control_type: :number }
            ]
          },
          { name: "payments", type: :object,
            hint: "Payment details for the invoice. ",
            properties: [
              { name: "type", type: "select",
                pick_list: "payment_type", toggle_hint: "Select from list",
                toggle_field: { name: "type",
                  label: "Type",
                  type: :string, control_type: :text,
                  toggle_hint: "Use custom value",
                  hint: "Payment type. Possible values: PAYPAL, EXTERNAL" }
              },
              { name: "transaction_id",
                hint: "Required for PAYPAL payment type" },
              { name: "transaction_type", type: "select",
                pick_list: "transaction_type", toggle_hint: "Select from list",
                toggle_field: { name: "transaction_type",
                  label: "Transaction type",
                  type: :string, control_type: :text,
                  toggle_hint: "Use custom value",
                  hint: "Transaction type. Possible values: " \
                    "SALE, AUTHORIZATION, CAPTURE" } },
              { name: "date", hint: "The date when the item or service was "\
                  "provided in yyyy-MM-dd z." },
              { name: "method", type: "select", label: "Payment method",
                pick_list: "payment_method", toggle_hint: "Select from list",
                toggle_field: { name: "method",
                  label: "Payment method",
                  type: :string, control_type: :text,
                  toggle_hint: "Use custom value",
                  hint: "Transaction type. Possible values: " \
                    "BANK_TRANSFER, CASH, CHECK, CREDIT_CARD," \
                    " DEBIT_CARD, PAYPAL, WIRE_TRANSFER, OTHER" } },
              { name: "note" },
              { name: "amount", type: :object,
                hint: "Payment amount to record. If left blank, total " \
                  "invoice amount is considered paid.",
                properties: [
                  { name: "currency" },
                  { name: "value", type: :string,
                    control_type: :number }
                ]
              },
            ]
          },
          { name: "refunds", type: :object,
            hint: "Refund details for the invoice. ",
            properties: [
              { name: "type", type: "select",
                pick_list: "payment_type", toggle_hint: "Select from list",
                toggle_field: { name: "type",
                  label: "Type",
                  type: :string, control_type: :text,
                  toggle_hint: "Use custom value",
                  hint: "Payment type. Possible values: PAYPAL, EXTERNAL" }
              },
              { name: "transaction_id",
                hint: "Required for PAYPAL payment type" },
              { name: "date", hint: "The date when the item or service was "\
                  "provided in yyyy-MM-dd z." },
              { name: "note" },
              { name: "amount", type: :object,
                hint: "Payment amount to record. If left blank, total " \
                  "invoice amount is considered paid.",
                properties: [
                  { name: "currency" },
                  { name: "value", type: :string,
                    control_type: :number }
                ]
              },
            ]
          },
          { name: "allow_tip", type: :boolean },
          { name: "template_id",
            hint: "Default: <code>PayPal system template</code>." },
          { name: "metadata", type: :object, properties: [
            { name: "created_date" },
            { name: "created_by" },
            { name: "cancelled_date" },
            { name: "cancelled_by" },
            { name: "last_updated_date" },
            { name: "last_updated_by" },
            { name: "first_sent_date" },
            { name: "last_sent_date" },
            { name: "last_sent_by" },
            { name: "payer_view_url" }
          ]},
          { name: "paid_amount", type: :object, properties: [
            { name: "paypal", type: :object, properties: [
              { name: "currency" },
              { name: "value", type: :string, control_type: :number }
            ]},
            { name: "other", type: :object, properties: [
              { name: "currency" },
              { name: "value", type: :string, control_type: :number }
            ]},
          ]},
          { name: "refunded_amount", type: :object, properties: [
            { name: "paypal", type: :object, properties: [
              { name: "currency" },
              { name: "value", type: :string, control_type: :number }
            ]},
            { name: "other", type: :object, properties: [
              { name: "currency" },
              { name: "value", type: :string, control_type: :number }
            ]},
          ]},
          { name: "attachments", type: :array, of: :object, properties: [
            { name: "name" },
            { name: "url", control_type: :url }
          ]},
          { name: "links", type: :array, of: :object, properties: [
            { name: "href", control_type: :url },
            { name: "rel" },
            { name: "method", control_type: :select, pick_list: "methods" }
          ]}
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("/v1/oauth2/token/userinfo").params(schema: "openid")
  end,

  actions: {
    search_invoices: {
      description: 'Search <span class="provider">Invoices</span> in
<span class="provider">PayPal</span>',
      title_hint: "Search Invoices in PayPal",
      help: "Returns invoices that match all criteria.",

      input_fields: lambda do
        [
          { name: "email", control_type: :email },
          { name: "recipient_first_name" },
          { name:  "recipient_last_name" },
          { name: "recipient_business_name" },
          { name: "number", label: "Invoice number",
            hint: "Any part of the invoice number." },
          { name: "status", control_type: "select",
            pick_list: "status_list", label: "Invoice status",
            toggle_hint: "Select from list",
            toggle_field: { name: "status",
              type: :string, control_type: "text",
              label: "Invoice Status",
              toggle_hint: "Use custom value",
              hint: "For possible values, Refer https://"\
                "developer.paypal.com/docs/api/invoicing/#"\
                "invoices_search for status column " } },
          { name: "lower_total_amount",
            hint: "The lower limit of the total amount. " \
              "Value must be greater than 0" },
          { name: "upper_total_amount",
            hint: "The upper limit of total amount." },
          { name: "start_invoice_date",
            type: :date,
            hint: "The start date for the invoice e.g. yyyy-MM-dd z." },
          { name: "end_invoice_date",
            type: :date,
            hint: "The end date for the invoice e.g. yyyy-MM-dd z." },
          { name: "start_due_date", type: :date,
            hint: "The start due date for the invoice, e.g. yyyy-MM-dd z." },
          { name: "end_due_date", type: :date,
            hint: "The end due date for the invoice, e.g. yyyy-MM-dd z." },
          { name: "start_payment_date", type: :date,
            hint: "The start payment date for the invoice," \
              " e.g. yyyy-MM-dd z." },
          { name: "end_payment_date", type: :date,
            hint: "The end payment date for the invoice, e.g. yyyy-MM-dd z." },
          { name: "start_creation_date", type: :date,
            hint: "The start creation date for the invoice," \
              " e.g. yyyy-MM-dd z." },
          { name: "end_creation_date", type: :date,
            hint: "The end creation date for the invoice," \
              " e.g. yyyy-MM-dd z." },
          { name: "total_count_required", type: :boolean,
            control_type: :checkbox,
            hint: "Indicates whether the response should show the total count. " },
          { name: "archived", type: :boolean,
            label: "Archived", control_type: :checkbox,
            hint: "<code>Yes</code> - only archived, <code>No</code> "\
              "- unarchived only, <code>If left blank</code> - lists all invoices." }
        ]
      end,

      execute: lambda do |_connection, input|
        date_fields = ["start_invoice_date", "end_invoice_date", "start_due_date", "end_due_date",
          "start_payment_date", "end_payment_date", "start_creation_date", "end_creation_date"]
        payload = input.map do |key, value|
          if date_fields.include?(key)
            if !value.blank?
              date_time = value.to_time.strftime("%Y-%m-%d %Z")
              { key => date_time }
            else
              { key => value }
            end
          elsif key.include?("status")
            { key => [value] }
          else
            { key => value }
          end
        end.inject(:merge)


        invoices = post("/v1/invoicing/search", payload)["invoices"]
        {
          invoices: invoices
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "invoices", type: :array, of: :object,
            properties: object_definitions["invoice"] }
        ]
      end,

      sample_output: lambda do
        [
          post("/v1/invoicing/search").
            payload(page: 0, page_size: 1).dig(0, "invoices") || {}
        ]
      end
    },

    get_invoice_by_id: {
      description: "Get <span class='provider'>invoice</span> details from " \
        "<span class='provider'>PayPal</span>",
      title_hint: "Get invoice in PayPal",
      hint: "Fetch the invoice details for the given Invoice ID",

      input_fields: lambda do
        [
          { name: "invoice_id", label: "Invoice ID", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/invoicing/invoices/#{input['invoice_id']}")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["invoice"]
      end,

      sample_output: lambda do
        [
          post("/v1/invoicing/search").
            payload(page: 0, page_size: 1).dig("invoices", 0) || {}
        ]
      end
    }
  },

  triggers: {
    new_invoice: {
      title: "New <span class='provider'>invoice</span> in"\
        "<span class='provider'>PayPal</span>",
      title_hint: "New invoice in PayPal",
      hint: "Trigger will poll based on user plan",

      input_fields: lambda do
        []
      end,

      webhook_subscribe: lambda do |webhook_url, _connection, input, recipe_id|
        post("/v1/notifications/webhooks").
          payload(url: webhook_url,
            event_types: [{ name: "INVOICING.INVOICE.CREATED" }])
      end,

      webhook_notification: lambda do |_input, payload|
        payload["resource"]
      end,

      webhook_unsubscribe: lambda do |webhook, connection|
        delete("/v1/notifications/webhooks/#{webhook['id']}")
      end,

      dedup: lambda do |invoice|
        invoice["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["invoice"]
      end,

      sample_output: lambda do
        post("/v1/invoicing/search").
          payload(page: 0, page_size: 1).dig(0, "invoices") || {}
      end
    }
  },

  pick_lists: {

    status_list: lambda do
      [
        ["Draft", "DRAFT"],
        ["Sent", "SENT"],
        ["Paid","PAID"],
        ["Mark as Paid", "MARKED_AS_PAID"],
        ["Cancelled", "CANCELLED"],
        ["Refunded", "REFUNDED"],
        ["Partially Refunded", "PARTIALLY_REFUNDED"],
        ["Mark as Refunded", "MARKED_AS_REFUNDED"],
        ["Unpaid", "UNPAID"],
        ["Payment Pending", "PAYMENT_PENDING"]
      ]
    end,

    units: lambda do
      [
        ["Quantity", "QUANTITY"],
        ["Hours", "HOURS"],
        ["Amount", "AMOUNT"]
      ]
    end,

    payment_type: lambda do
      [
        ["Paypal", "PAYPAL"],
        ["External", "EXTERNAL"]
      ]
    end,

    transaction_type: lambda do
      [
        ["Sale", "SALE"],
        ["Authorization", "AUTHORIZATION"],
        ["Capture", "CAPTURE"]
      ]
    end,

    methods: lambda do
      [
        ["Get","GET"],
        ["Post", "POST"],
        ["Put", "PUT"],
        ["Delete", "DELETE"],
        ["Head", "HEAD"],
        ["Connect", "CONNECT"],
        ["Options", "OPTIONS"],
        ["Patch", "PATCH"]
      ]
    end
  },
}
