{
  title: "Stripe SDK",

  connection: {
    fields: [
      {
        name: "api_key",
        control_type: "password",
        optional: false,
        label: "API Key",
        hint: "Get your API key <a href='https://dashboard.stripe.com/" \
          "account/apikeys' target='_blank'>here</a>"
      },
      {
        name: "api_version",
        optional: true
      }
    ],

    authorization: {
      type: "basic_auth",

      credentials: lambda do |connection|
        user(connection["api_key"])
        if connection["api_version"].present?
          headers("Stripe-Version" => connection["api_version"])
        end
      end
    },

    base_uri: lambda do
      "https://api.stripe.com"
    end
  },

  object_definitions: {
    customer: {
      fields: lambda do
        [
          { name: "id" },
          { name: "account_balance", type: "integer" },
          { name: "created", type: "integer" },
          { name: "currency" },
          { name: "default_source" },
          { name: "delinquent", type: "boolean" },
          { name: "description" },
          { name: "email" },
          { name: "discount", type: "object", properties: [
            { name: "customer" },
            { name: "subscription" },
            { name: "start", type: "integer" },
            { name: "end", type: "integer" },
            { name: "coupon", type: "object", properties: [
              { name: "id" },
              { name: "name" },
              { name: "amount_off", type: "integer" },
              { name: "percent_off", type: "integer" },
              { name: "created", type: "integer" },
              { name: "currency" },
              { name: "duration" },
              { name: "duration_in_months", type: "integer" },
              { name: "max_redemptions", type: "integer" },
              { name: "livemode", type: "boolean" },
              { name: "redeem_by", type: "integer" },
              { name: "times_redeemed", type: "integer" },
              { name: "valid", type: "boolean" },
            ] }
          ] },
          { name: "sources", type: "object", properties: [
            { name: "data", type: "array", of: "object", properties: [
              { name: "id" },
              { name: "name" },
              { name: "brand" },
              { name: "last4" },
              { name: "dynamic_last4" },
              { name: "exp_month" },
              { name: "exp_year" },
              { name: "country", label: "Card Country" },
              { name: "address_line1" },
              { name: "address_line2" },
              { name: "address_city" },
              { name: "address_state" },
              { name: "address_zip" },
              { name: "address_country" },
              { name: "cvc_check" },
              { name: "address_line1_check" },
              { name: "address_zip_check" },
              { name: "fingerprint" },
              { name: "funding" },
              { name: "tokenization_method" }
            ] }
          ] },
          { name: "subscriptions", type: "object", properties: [
            { name: "data", type: "array", of: "object", properties: [
              { name: "id" },
              { name: "status" },
              { name: "customer" },
              { name: "created", type: "integer" },
              { name: "canceled_at", type: "integer" },
              { name: "trial_start", type: "integer" },
              { name: "trial_end", type: "integer" },
              { name: "current_period_start", type: "integer" },
              { name: "current_period_end", type: "integer" },
              { name: "start", type: "integer" },
              { name: "ended_at", type: "integer" },
              { name: "cancel_at_period_end", type: "boolean" },
              { name: "quantity", type: "integer" },
              { name: "livemode", type: "boolean" },
              { name: "application_fee_percent", type: "number" },
              { name: "tax_percent", type: "number" },
              { name: "plan", type: "object", properties: [
                { name: "id" },
                { name: "name" },
                { name: "amount", type: "integer" },
                { name: "created", type: "integer" },
                { name: "currency" },
                { name: "interval" },
                { name: "inteval_count", type: "integer" },
                { name: "livemode", type: "boolean" },
                { name: "statement_descriptor" },
                { name: "trial_period_days", type: "integer" }
              ] },
              { name: "discount", type: "object", properties: [
                { name: "customer" },
                { name: "subscription" },
                { name: "start", type: "integer" },
                { name: "end", type: "integer" },
                { name: "coupon", type: "object", properties: [
                  { name: "id" },
                  { name: "name" },
                  { name: "amount_off", type: "integer" },
                  { name: "percent_off", type: "integer" },
                  { name: "created", type: "integer" },
                  { name: "currency" },
                  { name: "duration" },
                  { name: "duration_in_months", type: "integer" },
                  { name: "max_redemptions", type: "integer" },
                  { name: "livemode", type: "boolean" },
                  { name: "redeem_by", type: "integer" },
                  { name: "times_redeemed", type: "integer" },
                  { name: "valid", type: "boolean" },
                ] }
              ] },
              { name: "items", type: "object", properties: [
                { name: "data", type: "array", of: "object", properties: [
                  { name: "id" },
                  { name: "created", type: "integer" },
                  { name: "quantity", type: "integer" },
                  { name: "plan", type: "object", properties: [
                    { name: "id" },
                    { name: "name" },
                    { name: "amount", type: "integer" },
                    { name: "created", type: "integer" },
                    { name: "currency" },
                    { name: "interval" },
                    { name: "inteval_count", type: "integer" },
                    { name: "livemode", type: "boolean" },
                    { name: "statement_descriptor" },
                    { name: "trial_period_days", type: "integer" }
                  ] }
                ] }
              ] }
            ] }
          ] }
        ]
      end
    },

    refund: {
      fields: lambda do
        [
          { name: "id" },
          { name: "amount", type: "integer" },
          { name: "balance_transaction" },
          { name: "charge" },
          { name: "created", type: "integer" },
          { name: "currency" },
          { name: "reason" },
          { name: "receipt_number" },
          { name: "status" }
        ]
      end
    },

    charge: {
      fields: lambda do
        [
          { name: "id" },
          { name: "amount", type: "integer" },
          { name: "amount_refunded", type: "integer" },
          { name: "application" },
          { name: "application_fee", type: "integer" },
          { name: "balance_transaction" },
          { name: "captured", type: "boolean" },
          { name: "created", type: "integer" },
          { name: "currency" },
          { name: "customer" },
          { name: "description" },
          { name: "failure_code" },
          { name: "failure_message" },
          { name: "invoice" },
          { name: "order" },
          { name: "transfer" },
          { name: "paid", type: "boolean" },
          { name: "refunded", type: "boolean" },
          { name: "receipt_email", control_type: "email" },
          { name: "receipt_number" },
          { name: "refunds", type: "object", properties: [
            { name: "data", type: "array", of: "object", properties: [
              { name: "id" },
              { name: "amount", type: "integer" },
              { name: "balance_transaction" },
              { name: "charge" },
              { name: "created", type: "integer" },
              { name: "currency" },
              { name: "reason" },
              { name: "receipt_number" },
              { name: "status" }
            ] },
          ] },
          { name: "review" },
          { name: "status" }
        ]
      end
    },

    payout: {
      fields: lambda do
        [
          { name: "id" },
          { name: "amount", type: "integer" },
          { name: "arrival_date", type: "integer" },
          { name: "balance_transaction" },
          { name: "created", type: "integer" },
          { name: "currency" },
          { name: "description" },
          { name: "destination" },
          { name: "failure_balance_transaction" },
          { name: "failure_code" },
          { name: "livemode", type: "boolean" },
          { name: "method" },
          { name: "source_type" },
          { name: "statement_descriptor" },
          { name: "status" },
          { name: "type" }
        ]
      end
    },

    balance_transaction: {
      fields: lambda do
        [
          { name: "id" },
          { name: "amount", type: "integer" },
          { name: "available_on", type: "integer" },
          { name: "created", type: "integer" },
          { name: "currency" },
          { name: "description" },
          { name: "fee", type: "integer" },
          { name: "fee_details", type: "array", of: "object", properties: [
            { name: "amount", type: "integer" },
            { name: "currency" },
            { name: "description" },
            { name: "type" }
          ] },
          { name: "source" },
          { name: "status" },
          { name: "type" }
        ]
      end
    },

    plan: {
      fields: lambda do
        [
          { name: "id" },
          { name: "name" },
          { name: "amount", type: "integer" },
          { name: "created", type: "integer" },
          { name: "currency" },
          { name: "interval" },
          { name: "inteval_count", type: "integer" },
          { name: "livemode", type: "boolean" },
          { name: "statement_descriptor" },
          { name: "trial_period_days", type: "integer" }
        ]
      end
    },

    subscription: {
      fields: lambda do |_object_definitions|
        [
          { name: "id" },
          { name: "status" },
          { name: "customer" },
          { name: "created", type: "integer" },
          { name: "canceled_at", type: "integer" },
          { name: "trial_start", type: "integer" },
          { name: "trial_end", type: "integer" },
          { name: "current_period_start", type: "integer" },
          { name: "current_period_end", type: "integer" },
          { name: "start", type: "integer" },
          { name: "ended_at", type: "integer" },
          { name: "cancel_at_period_end", type: "boolean" },
          { name: "quantity", type: "integer" },
          { name: "livemode", type: "boolean" },
          { name: "application_fee_percent", type: "number" },
          { name: "tax_percent", type: "number" },
          { name: "plan", type: "object", properties: [
            { name: "id" },
            { name: "name" },
            { name: "amount", type: "integer" },
            { name: "created", type: "integer" },
            { name: "currency" },
            { name: "interval" },
            { name: "inteval_count", type: "integer" },
            { name: "livemode", type: "boolean" },
            { name: "statement_descriptor" },
            { name: "trial_period_days", type: "integer" }
          ] },
          { name: "discount", type: "object", properties: [
            { name: "customer" },
            { name: "subscription" },
            { name: "start", type: "integer" },
            { name: "end", type: "integer" },
            { name: "coupon", type: "object", properties: [
              { name: "id" },
              { name: "name" },
              { name: "amount_off", type: "integer" },
              { name: "percent_off", type: "integer" },
              { name: "created", type: "integer" },
              { name: "currency" },
              { name: "duration" },
              { name: "duration_in_months", type: "integer" },
              { name: "max_redemptions", type: "integer" },
              { name: "livemode", type: "boolean" },
              { name: "redeem_by", type: "integer" },
              { name: "times_redeemed", type: "integer" },
              { name: "valid", type: "boolean" },
            ] }
          ] },
          { name: "items", type: "object", properties: [
            { name: "data", type: "array", of: "object", properties: [
              { name: "id" },
              { name: "created", type: "integer" },
              { name: "quantity", type: "integer" },
              { name: "plan", type: "object", properties: [
                { name: "id" },
                { name: "name" },
                { name: "amount", type: "integer" },
                { name: "created", type: "integer" },
                { name: "currency" },
                { name: "interval" },
                { name: "inteval_count", type: "integer" },
                { name: "livemode", type: "boolean" },
                { name: "statement_descriptor" },
                { name: "trial_period_days", type: "integer" }
              ] }
            ] }
          ] }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("/v1/customers?limit=1")
  end,

  actions: {
    get_subscription: {
      description: "Get <span class='provider'>subscription</span> details " \
        "in <span class='provider'>Stripe</span>",

      input_fields: lambda do
        [
          {
            name: "id",
            label: "Subscription ID",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/subscriptions/#{input['id']}")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["subscription"]
      end,

      sample_output: lambda do |_connection|
        {
          "object": "list",
          "url": "/v1/invoices",
          "has_more": false,
          "data": [
            {
              "id": "in_19yTU92eZvKYlo2C7uDjvu6v",
              "object": "invoice",
              "amount_due": 999,
              "amount_paid": 999,
              "amount_remaining": 0,
              "application_fee": null,
              "attempt_count": 1,
              "attempted": true,
              "auto_advance": false,
              "billing": "charge_automatically",
              "billing_reason": null,
              "charge": "ch_19yUQN2eZvKYlo2CQf7aWpSX",
              "closed": true,
              "currency": "usd",
              "customer": "cus_DR1bI6Py9kM9IJ",
              "date": 1489789429,
              "description": null,
              "discount": null,
              "due_date": null,
              "ending_balance": 0,
              "forgiven": false,
              "hosted_invoice_url": "https://pay.stripe.com/invoice/" \
                "invst_a7KV10HpLw2QxrihgVyuOkOjMZ",
              "invoice_pdf": "https://pay.stripe.com/invoice/" \
                "invst_a7KV10HpLw2QxrihgVyuOkOjMZ/pdf",
              "lines": {
                "data": [
                  {
                    "id": "sli_3a8cd7c5388060",
                    "object": "line_item",
                    "amount": 999,
                    "currency": "usd",
                    "description": "1 × Bronze Performance (at $9.99 / month)",
                    "discountable": true,
                    "livemode": false,
                    "metadata": {
                    },
                    "period": {
                      "end": 1537196881,
                      "start": 1534518481
                    },
                    "plan": {
                      "id": "bronze-performance-150",
                      "object": "plan",
                      "active": true,
                      "aggregate_usage": null,
                      "amount": 999,
                      "billing_scheme": "per_unit",
                      "created": 1534516028,
                      "currency": "usd",
                      "interval": "month",
                      "interval_count": 1,
                      "livemode": false,
                      "metadata": {
                      },
                      "nickname": null,
                      "product": "prod_DR0w5agmWtM5hQ",
                      "tiers": null,
                      "tiers_mode": null,
                      "transform_usage": null,
                      "trial_period_days": null,
                      "usage_type": "licensed"
                    },
                    "proration": false,
                    "quantity": 1,
                    "subscription": "sub_DR1bFiLWKqdODT",
                    "subscription_item": "si_DR1bl2XOwOlwWK",
                    "type": "subscription"
                  }
                ],
                "has_more": false,
                "object": "list",
                "url": "/v1/invoices/in_19yTU92eZvKYlo2C7uDjvu6v/lines"
              },
              "livemode": false,
              "metadata": {
              },
              "next_payment_attempt": null,
              "number": "EF0A41E-0001",
              "paid": true,
              "period_end": 1489789420,
              "period_start": 1487370220,
              "receipt_number": "2277-9887",
              "starting_balance": 0,
              "statement_descriptor": null,
              "subscription": "sub_9lNL2lSXI8nYEQ",
              "subtotal": 999,
              "tax": null,
              "tax_percent": null,
              "total": 999,
              "webhooks_delivered_at": 1489789437
            }
          ]
        }
      end
    },

    search_subscriptions: {
      description: "Search <span class='provider'>subscriptions</span> in " \
        "<span class='provider'>Stripe</span>",

      input_fields: lambda do
        [
          {
            name: "customer",
            label: "Customer ID",
            optional: true,
            sticky: true
          },
          {
            name: "starting_after",
            label: "Starting After",
            hint: "If you make a search request and receive 100 objects, you " \
              "can specify the ID of last charge here to fetch the next page " \
              "of the list",
            optional: true
          },
          {
            name: "ending_before",
            label: "Ending Before",
            hint: "If you make a search request and receive 100 objects, you " \
              "can specify the ID of last charge here to fetch the previous " \
              "page of the list",
            optional: true
          },
          {
            name: "status",
            label: "Status",
            hint: "The status of the subscriptions to retrieve. One of: " \
              "trialing, active, past_due, unpaid, canceled, or all.",
            type: "string",
            control_type: "select",
            pick_list: "statuses",
            optional: true,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "status",
              label: "Status",
              type: "string",
              control_type: "text",
              optional: true,
              toggle_hint: "Use custom value",
              hint: "The status of the subscriptions to retrieve. One of: " \
                "trialing, active, past_due, unpaid, canceled, or all."
            },
            sticky: true
          }
        ]
      end,

      execute: lambda do |_connection, input|
        param = input.reject { |k, v| v.blank? || k == "status" }
        if param.length > 0
          get("/v1/subscriptions",
              limit: 100,
              status: (input["status"] || "all")).
            params(param)
        else
          get("/v1/subscriptions",
              limit: 100,
              status: (input["status"] || "all"))
        end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "data", type: "array", of: "object",
            properties: object_definitions["subscription"] }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "object": "list",
          "url": "/v1/invoices",
          "has_more": false,
          "data": [
            {
              "id": "in_19yTU92eZvKYlo2C7uDjvu6v",
              "object": "invoice",
              "amount_due": 999,
              "amount_paid": 999,
              "amount_remaining": 0,
              "application_fee": null,
              "attempt_count": 1,
              "attempted": true,
              "auto_advance": false,
              "billing": "charge_automatically",
              "billing_reason": null,
              "charge": "ch_19yUQN2eZvKYlo2CQf7aWpSX",
              "closed": true,
              "currency": "usd",
              "customer": "cus_DR1bI6Py9kM9IJ",
              "date": 1489789429,
              "description": null,
              "discount": null,
              "due_date": null,
              "ending_balance": 0,
              "forgiven": false,
              "hosted_invoice_url": "https://pay.stripe.com/invoice/" \
                "invst_a7KV10HpLw2QxrihgVyuOkOjMZ",
              "invoice_pdf": "https://pay.stripe.com/invoice/" \
                "invst_a7KV10HpLw2QxrihgVyuOkOjMZ/pdf",
              "lines": {
                "data": [
                  {
                    "id": "sli_3a8cd7c5388060",
                    "object": "line_item",
                    "amount": 999,
                    "currency": "usd",
                    "description": "1 × Bronze Performance (at $9.99 / month)",
                    "discountable": true,
                    "livemode": false,
                    "metadata": {
                    },
                    "period": {
                      "end": 1537196881,
                      "start": 1534518481
                    },
                    "plan": {
                      "id": "bronze-performance-150",
                      "object": "plan",
                      "active": true,
                      "aggregate_usage": null,
                      "amount": 999,
                      "billing_scheme": "per_unit",
                      "created": 1534516028,
                      "currency": "usd",
                      "interval": "month",
                      "interval_count": 1,
                      "livemode": false,
                      "metadata": {
                      },
                      "nickname": null,
                      "product": "prod_DR0w5agmWtM5hQ",
                      "tiers": null,
                      "tiers_mode": null,
                      "transform_usage": null,
                      "trial_period_days": null,
                      "usage_type": "licensed"
                    },
                    "proration": false,
                    "quantity": 1,
                    "subscription": "sub_DR1bFiLWKqdODT",
                    "subscription_item": "si_DR1bl2XOwOlwWK",
                    "type": "subscription"
                  }
                ],
                "has_more": false,
                "object": "list",
                "url": "/v1/invoices/in_19yTU92eZvKYlo2C7uDjvu6v/lines"
              },
              "livemode": false,
              "metadata": {
              },
              "next_payment_attempt": null,
              "number": "EF0A41E-0001",
              "paid": true,
              "period_end": 1489789420,
              "period_start": 1487370220,
              "receipt_number": "2277-9887",
              "starting_balance": 0,
              "statement_descriptor": null,
              "subscription": "sub_9lNL2lSXI8nYEQ",
              "subtotal": 999,
              "tax": null,
              "tax_percent": null,
              "total": 999,
              "webhooks_delivered_at": 1489789437
            }
          ]
        }
      end
    },

    get_customer: {
      description: "Get <span class='provider'>customer</span> details in " \
        "<span class='provider'>Stripe</span>",

      input_fields: lambda do
        [
          {
            name: "id",
            label: "Customer ID",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/customers/#{input['id']}")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["customer"]
      end,

      sample_output: lambda do |_connection|
        {
          "id": "cus_DR1bI6Py9kM9IJ",
          "object": "customer",
          "account_balance": 0,
          "created": 1534518440,
          "currency": "usd",
          "default_source": null,
          "delinquent": false,
          "description": null,
          "discount": null,
          "email": null,
          "invoice_prefix": "1DE9A54",
          "livemode": false,
          "metadata": {
          },
          "shipping": null,
          "sources": {
            "object": "list",
            "data": [],
            "has_more": false,
            "total_count": 0,
            "url": "/v1/customers/cus_DR1bI6Py9kM9IJ/sources"
          },
          "subscriptions": {
            "object": "list",
            "data": [],
            "has_more": false,
            "total_count": 0,
            "url": "/v1/customers/cus_DR1bI6Py9kM9IJ/subscriptions"
          }
        }
      end
    },

    get_charge: {
      description: "Get <span class='provider'>charges</span> details in " \
        "<span class='provider'>Stripe</span>",

      input_fields: lambda do
        [
          {
            name: "id",
            label: "Charge ID",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/charges/#{input['id']}")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["charge"]
      end,

      sample_output: lambda do |_connection|
        {
          "id": "ch_1D09Xq2eZvKYlo2CbaXwGbN2",
          "object": "charge",
          "amount": 999,
          "amount_refunded": 0,
          "application": null,
          "application_fee": null,
          "balance_transaction": "txn_19XJJ02eZvKYlo2ClwuJ1rbA",
          "captured": true,
          "created": 1534518442,
          "currency": "usd",
          "customer": "cus_BEHCMmqoDCb53o",
          "description": null,
          "destination": null,
          "dispute": null,
          "failure_code": null,
          "failure_message": null,
          "fraud_details": {
          },
          "invoice": "in_1D08bT2eZvKYlo2Cgi630AjX",
          "livemode": false,
          "metadata": {
          },
          "on_behalf_of": null,
          "order": null,
          "outcome": {
            "network_status": "approved_by_network",
            "reason": null,
            "risk_level": "normal",
            "seller_message": "Payment complete.",
            "type": "authorized"
          },
          "paid": true,
          "receipt_email": null,
          "receipt_number": null,
          "refunded": false,
          "refunds": {
            "object": "list",
            "data": [],
            "has_more": false,
            "total_count": 0,
            "url": "/v1/charges/ch_1D09Xq2eZvKYlo2CbaXwGbN2/refunds"
          },
          "review": null,
          "shipping": null,
          "source": {
            "id": "card_1AroeG2eZvKYlo2CZzvnBtQk",
            "object": "card",
            "address_city": null,
            "address_country": null,
            "address_line1": null,
            "address_line1_check": null,
            "address_line2": null,
            "address_state": null,
            "address_zip": null,
            "address_zip_check": null,
            "brand": "Visa",
            "country": "US",
            "customer": "cus_BEHCMmqoDCb53o",
            "cvc_check": null,
            "dynamic_last4": null,
            "exp_month": 8,
            "exp_year": 2019,
            "fingerprint": "Xt5EWLLDS7FJjR1c",
            "funding": "credit",
            "last4": "4242",
            "metadata": {
            },
            "name": null,
            "tokenization_method": null
          },
          "source_transfer": null,
          "statement_descriptor": null,
          "status": "succeeded",
          "transfer_group": null
        }
      end
    },

    get_related_balance_transactions: {
      description: "Get related <span class='provider'>balance transactions" \
        "</span> in <span class='provider'>Stripe</span>",

      input_fields: lambda do
        [
          {
            name: "payout",
            label: "Payout ID",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/balance/history?limit=100").
          params(input)
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "data", type: "array",
            properties: object_definitions["balance_transaction"] }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "id": "txn_19XJJ02eZvKYlo2ClwuJ1rbA",
          "object": "balance_transaction",
          "amount": 999,
          "available_on": 1483920000,
          "created": 1483315442,
          "currency": "usd",
          "description": null,
          "exchange_rate": null,
          "fee": 59,
          "fee_details": [
            {
              "amount": 59,
              "application": null,
              "currency": "usd",
              "description": "Stripe processing fees",
              "type": "stripe_fee"
            }
          ],
          "net": 940,
          "source": "ch_19XJJ02eZvKYlo2CHfSUsSpl",
          "status": "pending",
          "type": "charge"
        }
      end
    },

    get_refund: {
      description: "Get <span class='provider'>refund</span> details in " \
        "<span class='provider'>Stripe</span>",

      input_fields: lambda do
        [
          {
            name: "id",
            label: "Refund ID",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/refunds/#{input['id']}")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["refund"]
      end,

      sample_output: lambda do |_connection|
        {
          "id": "re_1D09Mk2eZvKYlo2Co37xa3KO",
          "object": "refund",
          "amount": 1273,
          "balance_transaction": "txn_1D09Ml2eZvKYlo2CK3PbrNtp",
          "charge": "ch_1D09MW2eZvKYlo2CoUru4XAR",
          "created": 1534517754,
          "currency": "usd",
          "metadata": {
          },
          "reason": null,
          "receipt_number": null,
          "status": "succeeded"
        }
      end
    }
  },

  triggers: {
    new_customer: {
      description: "New <span class='provider'>customer</span> in " \
        "<span class='provider'>Stripe</span>",

      type: "paging_desc",

      input_fields: lambda do
        [
          {
            name: "since",
            label: "Created after",
            type: "date_time",
            control_type: "date_time",
            hint: "Retrieve customers created after this date. Leave blank " \
              "to retrieve all customers",
            optional: true,
            sticky: true
          }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        starting_after = next_page

        if starting_after.present?
          response = get("/v1/customers?limit=100").
                       params(starting_after: starting_after)
        else
          if input["since"].present?
            param = {
              created: {
                gt: input["since"].to_i
              }
            }
          end

          response = get("/v1/customers?limit=100", param)
        end

        customers_list = response["data"]

        {
          events: customers_list,
          next_page: response["has_more"] ? customers_list.last["id"] : nil
        }
      end,

      document_id: lambda do |response|
        response["id"]
      end,

      sort_by: lambda do |response|
        response["created"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["customer"]
      end,

      sample_output: lambda do |_connection|
        get("/v1/customers?limit=1")["data"]
      end
    },

    new_refund: {
      description: "New <span class='provider'>refund</span> in " \
        "<span class='provider'>Stripe</span>",

      type: "paging_desc",

      input_fields: lambda do
        [
          {
            name: "since",
            label: "Created after",
            type: "date_time",
            control_type: "date_time",
            hint: "Retrieve refunds created after this date. Leave blank to " \
              "retrieve all refunds",
            optional: true,
            sticky: true
          }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        ending_before = next_page

        if ending_before.present?
          response = get("/v1/refunds?limit=100").
                       params(starting_after: ending_before)
        else
          if input["since"].present?
            param = {
              created: {
                gt: input["since"].to_i
              }
            }
          end
          response = get("/v1/refunds?limit=100", param)
        end

        refunds = response["data"]

        {
          events: refunds,
          next_page: response["has_more"] ? refunds.last["id"] : nil
        }
      end,

      document_id: lambda do |response|
        response["id"]
      end,

      sort_by: lambda do |response|
        response["created"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["refund"]
      end,

      sample_output: lambda do |_connection|
        get("/v1/refunds?limit=1")["data"]
      end
    },

    new_charge: {
      description: "New <span class='provider'>charges</span> in " \
        "<span class='provider'>Stripe</span>",

      type: "paging_desc",

      input_fields: lambda do
        [
          {
            name: "since",
            label: "Created after",
            type: "date_time",
            control_type: "date_time",
            hint: "Retrieve charges created after this date. Leave blank to " \
              "retrieve all charges",
            optional: true,
            sticky: true
          }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        ending_before = next_page

        if ending_before.present?
          response = get("/v1/charges?limit=100").
                       params(starting_after: ending_before)
        else
          if input["since"].present?
            param = {
              created: {
                gt: input["since"].to_i
              }
            }
          end
          response = get("/v1/charges?limit=100", param)
        end

        charges = response["data"]

        {
          events: charges,
          next_page: response["has_more"] ? charges.last["id"] : nil
        }
      end,

      document_id: lambda do |response|
        response["id"]
      end,

      sort_by: lambda do |response|
        response["created"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["charge"]
      end,

      sample_output: lambda do |_connection|
        get("/v1/charges?limit=1")["data"]
      end
    },

    new_payout: {
      description: "New <span class='provider'>payout</span> in " \
        "<span class='provider'>Stripe</span>",

      type: "paging_desc",

      input_fields: lambda do
        [
          {
            name: "since",
            label: "Created after",
            type: "date_time",
            control_type: "date_time",
            hint: "Retrieve payouts created after this date. Leave blank to " \
              "retrieve all payouts",
            optional: true,
            sticky: true
          }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        ending_before = next_page

        if ending_before.present?
          response = get("/v1/payouts?limit=100").
                       params(starting_after: ending_before)
        else
          if input["since"].present?
            param = {
              created: {
                gt: input["since"].to_i
              }
            }
          end
          response = get("/v1/payouts?limit=100", param)
        end

        payouts = response["data"]

        {
          events: payouts,
          next_page: response["has_more"] ? payouts.last["id"] : nil
        }
      end,

      document_id: lambda do |response|
        response["id"]
      end,

      sort_by: lambda do |response|
        response["created"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["payout"]
      end,

      sample_output: lambda do |_connection|
        get("/v1/payouts?limit=1")["data"]
      end
    },

    new_balance_transaction: {
      description: "New <span class='provider'>balance transaction</span> in " \
        "<span class='provider'>Stripe</span>",

      type: "paging_desc",

      input_fields: lambda do
        [
          {
            name: "since",
            label: "Created after",
            type: "date_time",
            control_type: "date_time",
            hint: "Retrieve balance transactions created after this date. " \
              "Leave blank to retrieve all balance transactions",
            optional: true,
            sticky: true
          }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        ending_before = next_page

        if ending_before.present?
          response = get("/v1/balance/history?limit=100").
                       params(starting_after: ending_before)
        else
          if input["since"].present?
            param = {
              created: {
                gt: input["since"].to_i
              }
            }
          end
          response = get("/v1/balance/history?limit=100", param)
        end

        balance_transaction = response["data"]

        {
          events: balance_transaction,
          next_page: response["has_more"] ? balance_transaction.last["id"] : nil
        }
      end,

      document_id: lambda do |response|
        response["id"]
      end,

      sort_by: lambda do |response|
        response["created"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["balance_transaction"]
      end,

      sample_output: lambda do |_connection|
        get("/v1/balance/history?limit=1")["data"]
      end
    }
  },

  pick_lists: {
    statuses: lambda do
      [
        %w[All all],
        %w[Trialing trialing],
        %w[Active active],
        %w[Past\ Due past_due],
        %w[Unpaid unpaid],
        %w[Canceled canceled]
      ]
    end
  }
}
