{
  title: "Coupa",

  connection: {
    fields: [
      {
        name: "host",
        control_type: "subdomain",
        url: ".com",
        hint: "Your Coupa subdomain is the subdomain portion of the URL " \
          "you visit to access your Coupa account. " \
          "eg: https://<b>YourSubDomain.coupacloud</b>.com",
        optional: false
      },
      # TODO: fix above hint; check if domain is always coupacloud.com
      {
        name: "api_key",
        label: "API key",
        control_type: "password",
        hint: "A key can be created from the “API Keys” section of the " \
          "Setup tab by an admin user. " \
          "eg: <b>https://YourSubDomain.coupacloud.com/api_keys</b>",
        optional: false
      }
    ],

    authorization: {
      type: "api_key",

      apply: lambda do |connection|
        headers("X-COUPA-API-KEY" => connection["api_key"])
      end
    },

    base_uri: ->(connection) { "https://#{connection['host']}.com" }
  },

  test: lambda do |_connection|
    get("/api/departments", return_object: "limited", limit: 1)
  end,

  methods: {
    get_all_paginated_values: lambda do |input|
      page_size = 50 # max is 50 for page_size in Coupa
      url = input["url"]
      display_value = input["display_value"]
      id_value = input["id_value"]

      list = []
      offset = 0
      more_pages = true

      while (more_pages && list.size < 950 ) do
        response = get(url,
                       return_object: "shallow",
                       offset: offset,
                       limit: page_size) || []

        list.concat(response.pluck(display_value, id_value))
        more_pages = response.size >= page_size
        offset = offset + response.size
      end
      list
    end,

    format_api_input_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call("format_api_input_field_names", array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call("format_api_input_field_names", value)
          { key.gsub("_", "-") => value }
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
          value = call("format_api_output_field_names",  value)
          { key.gsub("-", "_") => value }
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
        field[:name] = field[:name].gsub("-", "_")
        field
      end
    end
  },

  object_definitions: {
    address_create: {
      fields: lambda do |_connection, _config_fields|
        address_fields = [
          {
            name: "active",
            hint: "A yes value will make it active and available " \
              "to users. A no value will make the address inactive " \
              "making it no longer available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "attention", hint: "Address default attention line" },
          {
            name: "business_group_name",
            label: "Business group name",
            hint: "Content group name for address"
          },
          {
            name: "business_groups",
            label: "Business groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "city" },
          {
            name: "country",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Country",
              optional: false,
              control_type: "select",
              pick_list: "all_countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Country ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "created_at", label: "Created at", type: "timestamp" },
          { name: "created_by", label: "Created by", type: "integer" },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          { name: "local_tax_number", label: "Local tax number" },
          { name: "location_code" },
          { name: "name", hint: "Address 'nickname'", sticky: true },
          { name: "postal_code", label: "Postal code" },
          { name: "state", hint: "State abbreviation" },
          { name: "street1", hint: "Address line 1" },
          { name: "street2", hint: "Address line 2" },
          { name: "updated_at", label: "Updated at", type: "timestamp" },
          { name: "updated_by", label: "Updated by", type: "integer"  },
          { name: "vat_country" },
          { name: "vat_number" }
        ]
        standard_field_names = address_fields.pluck(:name)
        sample_record = get("/api/addresses",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = address_fields.concat(custom_fields || []).compact
      end
    },

    address_get: {
      fields: lambda do |_connection, _config_fields|
        address_fields = [
          {
            name: "active",
            hint: "A yes value will make it active and available " \
              "to users. A no value will make the address inactive " \
              "making it no longer available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "address_owner_type" },
          { name: "attention", hint: "Address default attention line" },
          {
            name: "business_group_name",
            label: "Business group name",
            hint: "Content group name for address"
          },
          { name: "business_groups" },
          { name: "city" },
          { name: "country" },
          { name: "country_id" },
          { name: "created_at", label: "Created at", type: "timestamp" },
          { name: "created_by", label: "Created by", type: "integer" },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          { name: "local_tax_number", label: "Local tax number" },
          { name: "location_code" },
          { name: "name", hint: "Address 'nickname'", sticky: true },
          { name: "postal_code", label: "Postal code" },
          { name: "state", hint: "State abbreviation" },
          { name: "street1", hint: "Address line 1" },
          { name: "street2", hint: "Address line 2" },
          { name: "updated_at", label: "Updated at", type: "timestamp" },
          { name: "updated_by", label: "Updated by", type: "integer"  },
          { name: "vat_country_id" },
          { name: "vat_number" }
        ]
        standard_field_names = address_fields.pluck(:name)
        sample_record = get("/api/addresses",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = address_fields.concat(custom_fields || []).compact
      end
    },

    address_update: {
      fields: lambda do |_connection, _config_fields|
        address_fields = [
          {
            name: "active",
            hint: "A yes value will make it active and available " \
              "to users. A no value will make the address inactive " \
              "making it no longer available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "attention", hint: "Address default attention line" },
          {
            name: "business_group_name",
            label: "Business group name",
            hint: "Content group name for address"
          },
          {
            name: "business_groups",
            label: "Business groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "city" },
          {
            name: "country",
            type: "object",
            properties: [{
              name: "id",
              label: "Country",
              control_type: "select",
              pick_list: "all_countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Country ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "created_at", label: "Created at", type: "timestamp" },
          { name: "created_by", label: "Created by", type: "integer" },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          { name: "local_tax_number", label: "Local tax number" },
          { name: "location_code" },
          { name: "name", hint: "Address 'nickname'", sticky: true },
          { name: "postal_code", label: "Postal code" },
          { name: "state", hint: "State abbreviation" },
          { name: "street1", hint: "Address line 1" },
          { name: "street2", hint: "Address line 2" },
          { name: "updated_at", label: "Updated at", type: "timestamp" },
          { name: "updated_by", label: "Updated by", type: "integer"  },
          {
            name: "vat_country",
            type: "object",
            properties: [{
              name: "id",
              label: "Country",
              control_type: "select",
              pick_list: "all_countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Country ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "vat_number" }
        ]
        standard_field_names = address_fields.pluck(:name)
        sample_record = get("/api/addresses",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = address_fields.concat(custom_fields || []).compact
      end
    },

    attachment: {
      fields: lambda do |_connection, config_fields|
        attachment_fields = [
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "file",
            label: "File URL",
            hint: "URL to attached file",
            control_type: "url"
          },
          { name: "id", hint: "Coupa unique identifier" },
          { name: "intent" },
          {
            name: "linked-to",
            label: "Linked to",
            hint: "link to specific feature"
          },
          { name: "text" },
          { name: "type" },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          { name: "url", label: "URL", control_type: "url" }
        ]

        standard_field_names = attachment_fields.pluck(:name)
        object_id = get("/api/#{config_fields['object']}").
                    params(return_object: "shallow", limit: 1).
                    dig(0, "id") || " "
        sample_record = get("/api/#{config_fields['object']}/#{object_id}" \
                          "/attachments",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = attachment_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    contract_create: {
      fields: lambda do |_connection, _config_fields|
        contract_fields = [
          {
            name: "consent",
            hint: "Consent",
            control_type: "select",
            pick_list: "consents",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Consent ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-owner",
            label: "Contract owner",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract owner",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract owner ID",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-terms",
            label: "Contract terms",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Contract term",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name:  "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Contract currency code",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "current-approval", label: "Current approval" },
          { name: "default-account", label: "Default account" },
          {
            name: "end-date",
            label: "End date",
            hint: "Expire Date",
            type: "timestamp"
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "is-default",
            label: "Is default",
            hint: "Default Account for Supplier Invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "legal-agreement-url",
            label: "Legal agreement url",
            hint: "Optional url for the legal agreement",
            control_type: "url"
          },
          {
            name: "length-of-notice-unit",
            label: "Length of notice unit",
            hint: "Unit of Length of Termination notice(Days/Years)",
            pick_list: "units",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Length of notice unit",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "length-of-notice-value",
            label: "Length of notice value",
            hint: "Value of Length of Termination notice"
          },
          {
            name: "max-commit",
            label: "Max commit",
            hint: "Maximum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "maximum-value",
            label: "Maximum value",
            hint: "Maximum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "min-commit",
            label: "Min commit",
            hint: "Minimum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "minimum-value",
            label: "Minimum value",
            hint: "Minimum Commit Amount",
            control_type: "number",
            type: "number"
          },
          { name: "name", hint: "Contract Name", sticky: true },
          { name: "no-of-renewals", label: "No of renewals" },
          { name: "number", hint: "Contract Number" },
          { name: "order-window-tz", label: "Order window tz" },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Payment term code on contract",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "po-message",
            label: "PO message",
            hint: "Order Windows PO Message"
          },
          {
            name: "preferred",
            hint: "Indicate preferred contract for supplier",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "quote-response-id",
            label: "Quote response ID",
            hint: "ID of Quote Response"
          },
          {
            name: "renewal-length-unit",
            label: "Renewal length unit",
            hint: "Unit of Length of Termination notice(Days/Years)",
            pick_list: "units",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Renewal length unit",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },

          {
            name: "renewal-length-value",
            label: "Renewal length value",
            hint: "Value of Renewal Length"
          },
          {
            name: "requisition-message",
            label: "Requisition message",
            hint: "Order Windows Requisition Message"
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            hint: "Savings Achieved through Contracts Pricing",
            control_type: "number",
            type: "number"
          },
          {
            name: "schedule",
            type: "object",
            properties: [
              { name: "day0" },
              { name: "day1" },
              { name: "day2" },
              { name: "day3" },
              { name: "day4" },
              { name: "day5" },
              { name: "day6" },
            ]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "start-date", label: "Start date", type: "timestamp" },
          { name: "status", hint: "Status of the Contract" },
          {
            name: "strict-invoicing-rules",
            label: "Strict invoicing rules",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "submitter",
            hint: "User who submitted the contract for approval",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract owner",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract owner ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              optional: false,
              control_type: "select",
              pick_list: "suppliers",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier-account",
            label: "Supplier account",
            hint: "Supplier Account Number"
          },
          {
            name: "supplier-invoiceable",
            label: "Supplier invoiceable",
            hint: "Supplier Can Invoice Directly",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "term-type",
            label: "Term type",
            pick_list: "term_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "term-type",
              label: "Term type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "termination-notice",
            label: "Termination notice",
            pick_list: "yes_or_no_options",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "termination-notice",
              label: "Termination notice",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "terms" },
          {
            name: "type",
            hint: "Contract type",
            pick_list: "contract_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              hint: "Contract type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-order-windows",
            label: "Use order windows",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "used-for-buying",
            label: "Used for buying",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "version", type: "integer" }
        ]
        standard_field_names = contract_fields.pluck(:name)
        sample_record = get("/api/contracts",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = contract_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    contract_get: {
      fields: lambda do |_connection, _config_fields|
        contract_fields = [
          {
            name: "consent",
            hint: "Consent",
            control_type: "select",
            pick_list: "consents",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Consent ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "contract-owner",
            label: "Contract owner",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "contract-terms",
            label: "Contract terms",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name:  "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Contract currency code",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "current-approval", label: "Current approval" },
          { name: "default-account", label: "Default account" },
          {
            name: "end-date",
            label: "End date",
            hint: "Expire Date",
            type: "timestamp"
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "is-default",
            label: "Is default",
            hint: "Default Account for Supplier Invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "legal-agreement-url",
            label: "Legal agreement url",
            hint: "Optional url for the legal agreement",
            control_type: "url"
          },
          {
            name: "length-of-notice-unit",
            label: "Length of notice unit",
            hint: "Unit of Length of Termination notice(Days/Years)",
            pick_list: "units",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Length of notice unit",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "length-of-notice-value",
            label: "Length of notice value",
            hint: "Value of Length of Termination notice"
          },
          {
            name: "max-commit",
            label: "Max commit",
            hint: "Maximum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "maximum-value",
            label: "Maximum value",
            hint: "Maximum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "min-commit",
            label: "Min commit",
            hint: "Minimum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "minimum-value",
            label: "Minimum value",
            hint: "Minimum Commit Amount",
            control_type: "number",
            type: "number"
          },
          { name: "name", hint: "Contract Name", sticky: true },
          { name: "no-of-renewals", label: "No of renewals" },
          { name: "number", hint: "Contract Number" },
          { name: "order-window-tz", label: "Order window tz" },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Payment term code on contract",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "po-message",
            label: "PO message",
            hint: "Order Windows PO Message"
          },
          {
            name: "preferred",
            hint: "Indicate preferred contract for supplier",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "quote-response-id",
            label: "Quote response ID",
            hint: "ID of Quote Response"
          },
          {
            name: "renewal-length-unit",
            label: "Renewal length unit",
            hint: "Unit of Length of Termination notice(Days/Years)",
            pick_list: "units",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Renewal length unit",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },

          {
            name: "renewal-length-value",
            label: "Renewal length value",
            hint: "Value of Renewal Length"
          },
          {
            name: "requisition-message",
            label: "Requisition message",
            hint: "Order Windows Requisition Message"
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            hint: "Savings Achieved through Contracts Pricing",
            control_type: "number",
            type: "number"
          },
          {
            name: "schedule",
            type: "object",
            properties: [
              { name: "day0" },
              { name: "day1" },
              { name: "day2" },
              { name: "day3" },
              { name: "day4" },
              { name: "day5" },
              { name: "day6" },
            ]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "start-date", label: "Start date", type: "timestamp" },
          { name: "status", hint: "Status of the Contract" },
          {
            name: "strict-invoicing-rules",
            label: "Strict invoicing rules",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "submitter",
            hint: "User who submitted the contract for approval",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "supplier",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "number" }
            ]
          },
          {
            name: "supplier-account",
            label: "Supplier account",
            hint: "Supplier Account Number"
          },
          {
            name: "supplier-invoiceable",
            label: "Supplier invoiceable",
            hint: "Supplier Can Invoice Directly",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "term-type",
            label: "Term type",
            pick_list: "term_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "term-type",
              label: "Term type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "termination-notice",
            label: "Termination notice",
            pick_list: "yes_or_no_options",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "termination-notice",
              label: "Termination notice",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "terms" },
          {
            name: "type",
            hint: "Contract type",
            pick_list: "contract_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              hint: "Contract type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-order-windows",
            label: "Use order windows",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "used-for-buying",
            label: "Used for buying",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "version", type: "integer" }
        ]
        standard_field_names = contract_fields.pluck(:name)
        sample_record = get("/api/contracts",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = contract_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    contract_update: {
      fields: lambda do |_connection, _config_fields|
        contract_fields = [
          {
            name: "consent",
            hint: "Consent",
            control_type: "select",
            pick_list: "consents",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Consent ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-owner",
            label: "Contract owner",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract owner",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract owner ID",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-terms",
            label: "Contract terms",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Contract term",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name:  "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Contract currency code",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "current-approval", label: "Current approval" },
          { name: "default-account", label: "Default account" },
          {
            name: "end-date",
            label: "End date",
            hint: "Expire Date",
            type: "timestamp"
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "is-default",
            label: "Is default",
            hint: "Default Account for Supplier Invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "legal-agreement-url",
            label: "Legal agreement url",
            hint: "Optional url for the legal agreement",
            control_type: "url"
          },
          {
            name: "length-of-notice-unit",
            label: "Length of notice unit",
            hint: "Unit of Length of Termination notice(Days/Years)",
            pick_list: "units",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Length of notice unit",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "length-of-notice-value",
            label: "Length of notice value",
            hint: "Value of Length of Termination notice"
          },
          {
            name: "max-commit",
            label: "Max commit",
            hint: "Maximum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "maximum-value",
            label: "Maximum value",
            hint: "Maximum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "min-commit",
            label: "Min commit",
            hint: "Minimum Commit Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "minimum-value",
            label: "Minimum value",
            hint: "Minimum Commit Amount",
            control_type: "number",
            type: "number"
          },
          { name: "name", hint: "Contract Name", sticky: true },
          { name: "no-of-renewals", label: "No of renewals" },
          { name: "number", hint: "Contract Number" },
          { name: "order-window-tz", label: "Order window tz" },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Payment term code on contract",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "po-message",
            label: "PO message",
            hint: "Order Windows PO Message"
          },
          {
            name: "preferred",
            hint: "Indicate preferred contract for supplier",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "quote-response-id",
            label: "Quote response ID",
            hint: "ID of Quote Response"
          },
          {
            name: "renewal-length-unit",
            label: "Renewal length unit",
            hint: "Unit of Length of Termination notice(Days/Years)",
            pick_list: "units",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "id",
              label: "Renewal length unit",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },

          {
            name: "renewal-length-value",
            label: "Renewal length value",
            hint: "Value of Renewal Length"
          },
          {
            name: "requisition-message",
            label: "Requisition message",
            hint: "Order Windows Requisition Message"
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            hint: "Savings Achieved through Contracts Pricing",
            control_type: "number",
            type: "number"
          },
          {
            name: "schedule",
            type: "object",
            properties: [
              { name: "day0" },
              { name: "day1" },
              { name: "day2" },
              { name: "day3" },
              { name: "day4" },
              { name: "day5" },
              { name: "day6" },
            ]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "start-date", label: "Start date", type: "timestamp" },
          { name: "status", hint: "Status of the Contract" },
          {
            name: "strict-invoicing-rules",
            label: "Strict invoicing rules",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "submitter",
            hint: "User who submitted the contract for approval",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract owner",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract owner ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier",
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              control_type: "select",
              pick_list: "suppliers",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier-account",
            label: "Supplier account",
            hint: "Supplier Account Number"
          },
          {
            name: "supplier-invoiceable",
            label: "Supplier invoiceable",
            hint: "Supplier Can Invoice Directly",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "term-type",
            label: "Term type",
            pick_list: "term_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "term-type",
              label: "Term type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "termination-notice",
            label: "Termination notice",
            pick_list: "yes_or_no_options",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "termination-notice",
              label: "Termination notice",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "terms" },
          {
            name: "type",
            hint: "Contract type",
            pick_list: "contract_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              hint: "Contract type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-order-windows",
            label: "Use order windows",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "used-for-buying",
            label: "Used for buying",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "version", type: "integer" }
        ]
        standard_field_names = contract_fields.pluck(:name)
        sample_record = get("/api/contracts",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = contract_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    department: {
      fields: lambda do |_connection, _config_fields|
        department_fields = [
          {
            name: "active",
            hint: "Control whether the department is active or inactive",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "id", sticky: true, type: "integer" },
          { name: "name", sticky: true },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = department_fields.pluck(:name)
        sample_record = get("/api/departments",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = department_fields.concat(custom_fields || [])

        call("format_schema_field_names", department_fields.compact)
      end
    },

    exchange_rate_create: {
      fields: lambda do |_connection, _config_fields|
        exchange_rate_fields = [
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name:  "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "from-currency",
            label: "From currency",
            hint: "Source for currency code",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              optional: false,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            control_type: "number",
            type: "integer"
          },
          { name: "rate", hint: "Exchange rate", sticky: true, type: "number" },
          {
            name: "rate-date",
            label: "Rate date",
            hint: "Effective date",
            type: "timestamp"
          },
          {
            name: "to-currency",
            label: "To currency",
            hint: "Target for currency code",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              optional: false,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = exchange_rate_fields.pluck(:name)
        sample_record = get("/api/exchange_rates",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = exchange_rate_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    exchange_rate_get: {
      fields: lambda do |_connection, _config_fields|
        exchange_rate_fields = [
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name:  "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "from-currency",
            label: "From currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            control_type: "number",
            type: "integer"
          },
          { name: "rate", hint: "Exchange rate", sticky: true, type: "number" },
          {
            name: "rate-date",
            label: "Rate date",
            hint: "Effective date",
            type: "timestamp"
          },
          {
            name: "to-currency",
            label: "To currency",
            hint: "Targer for currency code",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = exchange_rate_fields.pluck(:name)
        sample_record = get("/api/exchange_rates",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = exchange_rate_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    exchange_rate_update: {
      fields: lambda do |_connection, _config_fields|
        exchange_rate_fields = [
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name:  "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "from-currency",
            label: "From currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              hint: "Source for currency code",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            control_type: "number",
            type: "integer"
          },
          { name: "rate", hint: "Exchange rate", sticky: true, type: "number" },
          {
            name: "rate-date",
            label: "Rate date",
            hint: "Effective date",
            type: "timestamp"
          },
          {
            name: "to-currency",
            label: "To currency",
            hint: "Targer for currency code",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = exchange_rate_fields.pluck(:name)
        sample_record = get("/api/exchange_rates",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = exchange_rate_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    expense_line_create: {
      fields: lambda do |_connection, _config_fields|
        expense_line_fields = [
          {
            name: "account",
            type: "object",
            properties: [{
              name: "id",
              label: "Account",
              control_type: "select",
              pick_list: "accounts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "account-allocations",
            label: "Account allocations",
            type: "object",
            properties: [
              {
                name: "account",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Account",
                  control_type: "select",
                  pick_list: "accounts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Account ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "amount", control_type: "number", type: "number" },
              { name: "pct", control_type: "number", type: "number" },
              {
                name: "period",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Period",
                  control_type: "select",
                  pick_list: "periods",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Period ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              }
            ]
          },
          {
            name: "accounting-total",
            label: "Accounting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "accounting-total-currency",
            label: "Accounting total currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "amount", control_type: "number", type: "number" },
          {
            name: "approved-amount",
            label: "Approved amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "audit-status",
            label: "Audit status",
            control_type: "select",
            sticky: true,
            pick_list: "audit_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "audit-status",
              label: "Audit status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "custom-field-1", label: "Custom field 1" },
          { name: "custom-field-2", label: "Custom field 2" },
          { name: "custom-field-3", label: "Custom field 3" },
          { name: "custom-field-4", label: "Custom field 4" },
          { name: "custom-field-5", label: "Custom field 5" },
          { name: "custom-field-6", label: "Custom field 6" },
          { name: "custom-field-7", label: "Custom field 7" },
          { name: "custom-field-8", label: "Custom field 8" },
          { name: "custom-field-9", label: "Custom field 9" },
          { name: "custom-field-10", label: "Custom field 10" },
          { name: "custom-field-11", label: "Custom field 11" },
          { name: "custom-field-12", label: "Custom field 12" },
          { name: "custom-field-13", label: "Custom field 13" },
          { name: "custom-field-14", label: "Custom field 14" },
          { name: "custom-field-15", label: "Custom field 15" },
          { name: "custom-field-16", label: "Custom field 16" },
          { name: "custom-field-17", label: "Custom field 17" },
          { name: "custom-field-18", label: "Custom field 18" },
          { name: "custom-field-19", label: "Custom field 19" },
          { name: "custom-field-20", label: "Custom field 20" },
          { name: "description", sticky: true },
          {
            name: "divisor",
            hint: "Divisor unit",
            control_type: "number",
            type: "number"
          },
          {
            name: "end-date",
            label: "End date",
            hint: "Divisor end date",
            type: "timestamp"
          },
          {
            name: "exchange-rate",
            label: "Exchange rate",
            control_type: "number",
            type: "number"
          },
          {
            name: "expense-artifacts",
            label: "Expense artifacts",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-attendee",
            label: "Expense attendee",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-category",
            label: "Expense category",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Expense category",
              optional: false,
              control_type: "select",
              pick_list: "expense_categories",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Expense category ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "expense-category-custom-field-1",
            label: "Expense category custom field 1"
          },
          {
            name: "expense-category-custom-field-2",
            label: "Expense category custom field 2"
          },
          {
            name: "expense-category-custom-field-3",
            label: "Expense category custom field 3"
          },
          {
            name: "expense-category-custom-field-4",
            label: "Expense category custom field 4"
          },
          {
            name: "expense-category-custom-field-5",
            label: "Expense category custom field 5"
          },
          {
            name: "expense-category-custom-field-6",
            label: "Expense category custom field 6"
          },
          {
            name: "expense-category-custom-field-7",
            label: "Expense category custom field 7"
          },
          {
            name: "expense-category-custom-field-8",
            label: "Expense category custom field 8"
          },
          {
            name: "expense-category-custom-field-9",
            label: "Expense category custom field 9"
          },
          {
            name: "expense-category-custom-field-10",
            label: "Expense category custom field 10"
          },
          { name: "expense-date", label: "Expense date", type: "timestamp" },
          {
            name: "expense-line-imported-data",
            label: "Expense line imported data",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-mileage",
            label: "Expense line mileage",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-per-diem",
            label: "Expense line per diem",
            hint: "Expense per diem data",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-preapproval",
            label: "Expense line preapproval",
            hint: "Applied expense preapproval",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-taxes",
            label: "Expense line taxes",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-report-id",
            label: "Expense report ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "expensed-by",
            label: "Expensed by",
            hint: "Expensed by user",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "external-src-data",
            label: "External src data",
            hint: "External source data"
          },
          {
            name: "external-src-name",
            label: "External src name", hint: "External source name"
          },
          {
            name: "external-src-ref",
            label: "External src ref",
            hint: "External source reference",
            sticky: true
          },
          {
            name: "foreign-currency",
            label: "Foreign currency",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              optional: false,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "foreign-currency-amount",
            label: "Foreign currency amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "foreign-currency-id",
            label: "Foreign currency ID",
            type: "integer"
          },
          {
            name: "frugality",
            hint: "Frugality rating",
            pick_list: "frugalities",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "frugality",
              hint: "Frugality rating",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "integration",
            hint: "Corp card integration name",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "itemized-expense-lines",
            label: "Itemized expense lines",
            hint: "Itemized expense line"
          },
          {
            name: "line-number",
            label: "Line number",
            hint: "Expense line number",
            type: "integer"
          },
          { name: "merchant" },
          { name: "order-line-id", label: "Order line ID", type: "integer" },
          {
            name: "over-limit",
            label: "Over limit",
            hint: "Over limit flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "parent-expense-line-id",
            label: "Parent expense line ID",
            type: "integer"
          },
          {
            name: "parent-external-src-data",
            label: "Parent external src data",
            hint: "Parent External Source Data"
          },
          {
            name: "parent-external-src-name",
            label: "Parent external src name",
            hint: "Parent External Source Name"
          },
          {
            name: "parent-external-src-ref",
            label: "Parent external src ref",
            hint: "Parent External Source Ref"
          },
          {
            name: "period",
            type: "object",
            properties: [{
              name: "id",
              label: "Period",
              control_type: "select",
              pick_list: "periods",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Period ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "reason" },
          {
            name: "receipt-total-amount",
            label: "Receipt total amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "receipt-total-currency-id",
            label: "Receipt total currency ID",
            type: "integer"
          },
          {
            name: "reporting-total",
            label: "Reporting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "requires-receipt",
            label: "Requires receipt",
            hint: "Requires receipt flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "start-date",
            label: "Start date",
            hint: "Divisor start date",
            type: "timestamp"
          },
          { name: "status", hint: "Transaction status" },
          {
            name: "suggested-exchange-rate",
            label: "Suggested exchange rate",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "type" },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = expense_line_fields.pluck(:name)
        sample_record = get("/api/expense_lines",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = expense_line_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    expense_line_get: {
      fields: lambda do |_connection, _config_fields|
        expense_line_fields = [
          {
            name: "account",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "account-allocations",
            label: "Account allocations",
            type: "array",
            of: "object",
            properties: [
              {
                name: "account",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "code" }
                ]
              },
              { name: "amount", control_type: "number", type: "number" },
              {
                name: "created-at",
                label: "Created at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "created-by",
                label: "Created by",
                hint: "User who created",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              { name: "id", hint: "Coupa unique identifier", type: "integer" },
              { name: "pct", control_type: "number", type: "number" },
              {
                name: "period",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "name" }
                ]
              },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format " \
                 "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                hint: "User who updated",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              }
            ]
          },
          {
            name: "accounting-total",
            label: "Accounting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "accounting-total-currency",
            label: "Accounting total currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "amount", control_type: "number", type: "number" },
          {
            name: "approved-amount",
            label: "Approved amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "audit-status",
            label: "Audit status",
            control_type: "select",
            sticky: true,
            pick_list: "audit_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "audit-status",
              label: "Audit status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "custom-field-1", label: "Custom field 1" },
          { name: "custom-field-2", label: "Custom field 2" },
          { name: "custom-field-3", label: "Custom field 3" },
          { name: "custom-field-4", label: "Custom field 4" },
          { name: "custom-field-5", label: "Custom field 5" },
          { name: "custom-field-6", label: "Custom field 6" },
          { name: "custom-field-7", label: "Custom field 7" },
          { name: "custom-field-8", label: "Custom field 8" },
          { name: "custom-field-9", label: "Custom field 9" },
          { name: "custom-field-10", label: "Custom field 10" },
          { name: "custom-field-11", label: "Custom field 11" },
          { name: "custom-field-12", label: "Custom field 12" },
          { name: "custom-field-13", label: "Custom field 13" },
          { name: "custom-field-14", label: "Custom field 14" },
          { name: "custom-field-15", label: "Custom field 15" },
          { name: "custom-field-16", label: "Custom field 16" },
          { name: "custom-field-17", label: "Custom field 17" },
          { name: "custom-field-18", label: "Custom field 18" },
          { name: "custom-field-19", label: "Custom field 19" },
          { name: "custom-field-20", label: "Custom field 20" },
          { name: "description", sticky: true },
          {
            name: "divisor",
            hint: "Divisor unit",
            control_type: "number",
            type: "number"
          },
          {
            name: "end-date",
            label: "End date",
            hint: "Divisor end date",
            type: "timestamp"
          },
          {
            name: "exchange-rate",
            label: "Exchange rate",
            control_type: "number",
            type: "number"
          },
          {
            name: "expense-artifacts",
            label: "Expense artifacts",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-attendee",
            label: "Expense attendee",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-category",
            label: "Expense category",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "expense-category-custom-field-1",
            label: "Expense category custom field 1"
          },
          {
            name: "expense-category-custom-field-2",
            label: "Expense category custom field 2"
          },
          {
            name: "expense-category-custom-field-3",
            label: "Expense category custom field 3"
          },
          {
            name: "expense-category-custom-field-4",
            label: "Expense category custom field 4"
          },
          {
            name: "expense-category-custom-field-5",
            label: "Expense category custom field 5"
          },
          {
            name: "expense-category-custom-field-6",
            label: "Expense category custom field 6"
          },
          {
            name: "expense-category-custom-field-7",
            label: "Expense category custom field 7"
          },
          {
            name: "expense-category-custom-field-8",
            label: "Expense category custom field 8"
          },
          {
            name: "expense-category-custom-field-9",
            label: "Expense category custom field 9"
          },
          {
            name: "expense-category-custom-field-10",
            label: "Expense category custom field 10"
          },
          { name: "expense-date", label: "Expense date", type: "timestamp" },
          {
            name: "expense-line-imported-data",
            label: "Expense line imported data",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-mileage",
            label: "Expense line mileage",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-per-diem",
            label: "Expense line per diem",
            hint: "Expense per diem data",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-preapproval",
            label: "Expense line preapproval",
            hint: "Applied expense preapproval",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-taxes",
            label: "Expense line taxes",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-report-id",
            label: "Expense report ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "expensed-by",
            label: "Expensed by",
            hint: "Expensed by user",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "external-src-data",
            label: "External src data",
            hint: "External source data"
          },
          {
            name: "external-src-name",
            label: "External src name", hint: "External source name"
          },
          {
            name: "external-src-ref",
            label: "External src ref",
            hint: "External source reference"
          },
          {
            name: "foreign-currency",
            label: "Foreign currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "foreign-currency-amount",
            label: "Foreign currency amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "foreign-currency-id",
            label: "Foreign currency ID",
            type: "integer"
          },
          {
            name: "frugality",
            hint: "Frugality rating",
            pick_list: "frugalities",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "frugality",
              hint: "Frugality rating",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "integration",
            hint: "Corp card integration name",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "itemized-expense-lines",
            label: "Itemized expense lines",
            hint: "Itemized expense line"
          },
          {
            name: "line-number",
            label: "Line number",
            hint: "Expense line number",
            type: "integer"
          },
          { name: "merchant" },
          { name: "order-line-id", label: "Order line ID", type: "integer" },
          {
            name: "over-limit",
            label: "Over limit",
            hint: "Over limit flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "parent-expense-line-id",
            label: "Parent expense line ID",
            type: "integer"
          },
          {
            name: "parent-external-src-data",
            label: "Parent external src data",
            hint: "Parent External Source Data"
          },
          {
            name: "parent-external-src-name",
            label: "Parent external src name",
            hint: "Parent External Source Name"
          },
          {
            name: "parent-external-src-ref",
            label: "Parent external src ref",
            hint: "Parent External Source Ref"
          },
          {
            name: "period",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "reason" },
          {
            name: "receipt-total-amount",
            label: "Receipt total amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "receipt-total-currency-id",
            label: "Receipt total currency ID",
            type: "integer"
          },
          {
            name: "reporting-total",
            label: "Reporting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "requires-receipt",
            label: "Requires receipt",
            hint: "Requires receipt flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "start-date",
            label: "Start date",
            hint: "Divisor start date",
            type: "timestamp"
          },
          { name: "status", hint: "Transaction status" },
          {
            name: "suggested-exchange-rate",
            label: "Suggested exchange rate",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "type" },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = expense_line_fields.pluck(:name)
        sample_record = get("/api/expense_lines",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = expense_line_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    expense_line_update: {
      fields: lambda do |_connection, _config_fields|
        expense_line_fields = [
          {
            name: "account",
            type: "object",
            properties: [{
              name: "id",
              label: "Account",
              control_type: "select",
              pick_list: "accounts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "account-allocations",
            label: "Account allocations",
            type: "array",
            of: "object",
            properties: [
              {
                name: "account",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Account",
                  control_type: "select",
                  pick_list: "accounts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Account ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "amount", control_type: "number", type: "number" },
              {
                name: "id",
                hint: "Coupa unique identifier",
                type: "integer",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing account allocation."
              },
              { name: "pct", control_type: "number", type: "number" },
              {
                name: "period",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Period",
                  control_type: "select",
                  pick_list: "periods",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Period ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              }
            ]
          },
          {
            name: "accounting-total",
            label: "Accounting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "accounting-total-currency",
            label: "Accounting total currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "amount", control_type: "number", type: "number" },
          {
            name: "approved-amount",
            label: "Approved amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "audit-status",
            label: "Audit status",
            control_type: "select",
            sticky: true,
            pick_list: "audit_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "audit-status",
              label: "Audit status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "custom-field-1", label: "Custom field 1" },
          { name: "custom-field-2", label: "Custom field 2" },
          { name: "custom-field-3", label: "Custom field 3" },
          { name: "custom-field-4", label: "Custom field 4" },
          { name: "custom-field-5", label: "Custom field 5" },
          { name: "custom-field-6", label: "Custom field 6" },
          { name: "custom-field-7", label: "Custom field 7" },
          { name: "custom-field-8", label: "Custom field 8" },
          { name: "custom-field-9", label: "Custom field 9" },
          { name: "custom-field-10", label: "Custom field 10" },
          { name: "custom-field-11", label: "Custom field 11" },
          { name: "custom-field-12", label: "Custom field 12" },
          { name: "custom-field-13", label: "Custom field 13" },
          { name: "custom-field-14", label: "Custom field 14" },
          { name: "custom-field-15", label: "Custom field 15" },
          { name: "custom-field-16", label: "Custom field 16" },
          { name: "custom-field-17", label: "Custom field 17" },
          { name: "custom-field-18", label: "Custom field 18" },
          { name: "custom-field-19", label: "Custom field 19" },
          { name: "custom-field-20", label: "Custom field 20" },
          { name: "description", sticky: true },
          {
            name: "divisor",
            hint: "Divisor unit",
            control_type: "number",
            type: "number"
          },
          {
            name: "end-date",
            label: "End date",
            hint: "Divisor end date",
            type: "timestamp"
          },
          {
            name: "exchange-rate",
            label: "Exchange rate",
            control_type: "number",
            type: "number"
          },
          {
            name: "expense-artifacts",
            label: "Expense artifacts",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-attendee",
            label: "Expense attendee",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-category",
            label: "Expense category",
            type: "object",
            properties: [{
              name: "id",
              label: "Expense category",
              sticky: true,
              control_type: "select",
              pick_list: "expense_categories",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Expense category ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "expense-category-custom-field-1",
            label: "Expense category custom field 1"
          },
          {
            name: "expense-category-custom-field-2",
            label: "Expense category custom field 2"
          },
          {
            name: "expense-category-custom-field-3",
            label: "Expense category custom field 3"
          },
          {
            name: "expense-category-custom-field-4",
            label: "Expense category custom field 4"
          },
          {
            name: "expense-category-custom-field-5",
            label: "Expense category custom field 5"
          },
          {
            name: "expense-category-custom-field-6",
            label: "Expense category custom field 6"
          },
          {
            name: "expense-category-custom-field-7",
            label: "Expense category custom field 7"
          },
          {
            name: "expense-category-custom-field-8",
            label: "Expense category custom field 8"
          },
          {
            name: "expense-category-custom-field-9",
            label: "Expense category custom field 9"
          },
          {
            name: "expense-category-custom-field-10",
            label: "Expense category custom field 10"
          },
          { name: "expense-date", label: "Expense date", type: "timestamp" },
          {
            name: "expense-line-imported-data",
            label: "Expense line imported data",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-mileage",
            label: "Expense line mileage",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-per-diem",
            label: "Expense line per diem",
            hint: "Expense per diem data",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-preapproval",
            label: "Expense line preapproval",
            hint: "Applied expense preapproval",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-line-taxes",
            label: "Expense line taxes",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-report-id",
            label: "Expense report ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "expensed-by",
            label: "Expensed by",
            hint: "Expensed by user",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "external-src-data",
            label: "External src data",
            hint: "External source data"
          },
          {
            name: "external-src-name",
            label: "External src name", hint: "External source name"
          },
          {
            name: "external-src-ref",
            label: "External src ref",
            hint: "External source reference",
            sticky: true
          },
          {
            name: "foreign-currency",
            label: "Foreign currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              sticky: true,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "foreign-currency-amount",
            label: "Foreign currency amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "foreign-currency-id",
            label: "Foreign currency ID",
            type: "integer"
          },
          {
            name: "frugality",
            hint: "Frugality rating",
            pick_list: "frugalities",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "frugality",
              hint: "Frugality rating",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "integration",
            hint: "Corp card integration name",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "itemized-expense-lines",
            label: "Itemized expense lines",
            hint: "Itemized expense line"
          },
          {
            name: "line-number",
            label: "Line number",
            hint: "Expense line number",
            type: "integer"
          },
          { name: "merchant" },
          { name: "order-line-id", label: "Order line ID", type: "integer" },
          {
            name: "over-limit",
            label: "Over limit",
            hint: "Over limit flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "parent-expense-line-id",
            label: "Parent expense line ID",
            type: "integer"
          },
          {
            name: "parent-external-src-data",
            label: "Parent external src data",
            hint: "Parent External Source Data"
          },
          {
            name: "parent-external-src-name",
            label: "Parent external src name",
            hint: "Parent External Source Name"
          },
          {
            name: "parent-external-src-ref",
            label: "Parent external src ref",
            hint: "Parent External Source Ref"
          },
          {
            name: "period",
            type: "object",
            properties: [{
              name: "id",
              label: "Period",
              control_type: "select",
              pick_list: "periods",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Period ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "reason" },
          {
            name: "receipt-total-amount",
            label: "Receipt total amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "receipt-total-currency-id",
            label: "Receipt total currency ID",
            type: "integer"
          },
          {
            name: "reporting-total",
            label: "Reporting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "requires-receipt",
            label: "Requires receipt",
            hint: "Requires receipt flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "start-date",
            label: "Start date",
            hint: "Divisor start date",
            type: "timestamp"
          },
          { name: "status", hint: "Transaction status" },
          {
            name: "suggested-exchange-rate",
            label: "Suggested exchange rate",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "type" },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = expense_line_fields.pluck(:name)
        sample_record = get("/api/expense_lines",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = expense_line_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    expense_create: {
      fields: lambda do |_connection, _config_fields|
        expense_report_fields = [
          {
            name: "approvals",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "audit-score",
            label: "Audit score",
            hint: "Coupa's Audit Score",
            type: "integer"
          },
          {
            name: "auditor-note",
            label: "Auditor note",
            hint: "Auditor comments on expense report"
          },
          {
            name: "comments",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Comment",
              control_type: "select",
              pick_list: "comments",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Comment ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Currency code",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "events",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-lines",
            label: "Expense lines",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer", sticky: true }]
          },
          {
            name: "expense-policy-violations",
            label: "Policy violations",
            hint: "Expense policy violations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-violations",
            label: "Expense violations",
            hint: "Expense violations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expensed-by",
            label: "Expensed by",
            hint: "Expensed by user",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "external-src-name",
            label: "External source name"
          },
          {
            name: "external-src-ref",
            label: "External source reference"
          },
          {
            name: "id",
            hint: "Coupa's Expense Report ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported " \
              "in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "paid",
            hint: "Has expense report been paid?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "past-due",
            label: "Past due",
            hint: "Report has passed the due date in the format True or false",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "payment",
            type: "object",
            properties: [
              {
                name: "amount-paid",
                label: "Amount paid",
                control_type: "number",
                type: "number"
              },
              { name: "check-number", label: "Check number" },
              { name: "notes", control_type: "text-area" },
              { name: "payable-id", label: "Payable ID", type: "integer" },
              { name: "payable-type", label: "Payable type" },
              { name: "payment-date", label: "Payment date", type: "timestamp" }
            ]
          },
          {
            name: "reject-reason",
            label: "Reject reason",
            hint: "Reason why report was rejected"
          },
          {
            name: "report-due-date",
            label: "Report due date",
            hint: "Due date before which report needs to be " \
              "submitted in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "status",
            hint: "Current Expense Report Status"
          },
          {
            name: "submitted-at",
            label: "Submitted at",
            hint: "Date Expense Report was Submitted for Approval",
            type: "timestamp"
          },
          {
            name: "submitted-by",
            label: "Submitted by",
            hint: "Submitted by user",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "title", hint: "Expense Report Title" },
          {
            name: "total",
            hint: "Expense Report Total in Transactional Currency",
            control_type: "number",
            type: "number"
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = expense_report_fields.pluck(:name)
        sample_record = get("/api/expense_reports",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = expense_report_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    expense_get: {
      fields: lambda do |_connection, _config_fields|
        expense_report_fields = [
          {
            name: "approvals",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "audit-score",
            label: "Audit score",
            hint: "Coupa's Audit Score",
            type: "integer"
          },
          {
            name: "auditor-note",
            label: "Auditor note",
            hint: "Auditor comments on expense report"
          },
          {
            name: "comments",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Currency code",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "events",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-lines",
            label: "Expense lines",
            hint: "Expense lines",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "external-src-ref", label: "External source reference" }
            ]
          },
          {
            name: "expense-policy-violations",
            label: "Policy violations",
            hint: "Expense policy violations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-violations",
            label: "Expense violations",
            hint: "Expense violations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expensed-by",
            label: "Expensed by",
            hint: "Expensed by user",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "external-src-name", label: "External source name" },
          { name: "external-src-ref", label: "External source reference" },
          {
            name: "id",
            hint: "Coupa's Expense Report ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported " \
              "in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "paid",
            hint: "Has expense report been paid?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "past-due",
            label: "Past due",
            hint: "Report has passed the due date in the format True or false",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "payment",
            type: "object",
            properties: [
              {
                name: "amount-paid",
                label: "Amount paid",
                control_type: "number",
                type: "number"
              },
              { name: "created-at", label: "Created at", type: "timestamp" },
              {
                name: "created-by",
                label: "Created by",
                type: "object",
                hint: "User who created",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              {
                name: "id",
                hint: "Coupa unique identifier",
                type: "integer"
              },
              { name: "notes", control_type: "text-area" },
              { name: "payable-id", label: "Payable ID", type: "integer" },
              { name: "payable-type", label: "Payable type" },
              {
                name: "payment-date",
                label: "Payment date",
                type: "timestamp"
              },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              }
            ]
          },
          {
            name: "reject-reason",
            label: "Reject reason",
            hint: "Reason why report was rejected"
          },
          {
            name: "report-due-date",
            label: "Report due date",
            hint: "Due date before which report needs to be " \
              "submitted in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          { name: "status", hint: "Current Expense Report Status" },
          {
            name: "submitted-at",
            label: "Submitted at",
            hint: "Date Expense Report was Submitted for Approval",
            type: "timestamp"
          },
          {
            name: "submitted-by",
            label: "Submitted by",
            hint: "Submitted by user",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "title", hint: "Expense Report Title" },
          {
            name: "total",
            hint: "Expense Report Total in Transactional Currency",
            control_type: "number",
            type: "number"
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = expense_report_fields.pluck(:name)
        sample_record = get("/api/expense_reports",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = expense_report_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    expense_update: {
      fields: lambda do |_connection, _config_fields|
        expense_report_fields = [
          {
            name: "approvals",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "audit-score",
            label: "Audit score",
            hint: "Coupa's Audit Score",
            type: "integer"
          },
          {
            name: "auditor-note",
            label: "Auditor note",
            hint: "Auditor comments on expense report"
          },
          {
            name: "comments",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Comment",
              control_type: "select",
              pick_list: "comments",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Comment ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Currency code",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "events",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-lines",
            label: "Expense lines",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer", sticky: true }]
          },
          {
            name: "expense-policy-violations",
            label: "Policy violations",
            hint: "Expense policy violations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-violations",
            label: "Expense violations",
            hint: "Expense violations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expensed-by",
            label: "Expensed by",
            hint: "Expensed by user",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "external-src-name",
            label: "External source name"
          },
          {
            name: "external-src-ref",
            label: "External source reference"
          },
          {
            name: "id",
            hint: "Coupa's Expense Report ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported " \
              "in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "paid",
            hint: "Has expense report been paid?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "past-due",
            label: "Past due",
            hint: "Report has passed the due date in the format True or false",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "payment",
            type: "object",
            properties: [
              {
                name: "amount-paid",
                label: "Amount paid",
                control_type: "number",
                type: "number"
              },
              { name: "check-number", label: "Check number" },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing payment.",
                type: "integer"
              },
              { name: "notes", control_type: "text-area" },
              { name: "payable-id", label: "Payable ID", type: "integer" },
              { name: "payable-type", label: "Payable type" },
              { name: "payment-date", label: "Payment date", type: "timestamp" }
            ]
          },
          {
            name: "reject-reason",
            label: "Reject reason",
            hint: "Reason why report was rejected"
          },
          {
            name: "report-due-date",
            label: "Report due date",
            hint: "Due date before which report needs to be " \
              "submitted in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "status",
            hint: "Current Expense Report Status"
          },
          {
            name: "submitted-at",
            label: "Submitted at",
            hint: "Date Expense Report was Submitted for Approval",
            type: "timestamp"
          },
          {
            name: "submitted-by",
            label: "Submitted by",
            hint: "Submitted by user",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "title", hint: "Expense Report Title" },
          {
            name: "total",
            hint: "Expense Report Total in Transactional Currency",
            control_type: "number",
            type: "number"
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = expense_report_fields.pluck(:name)
        sample_record = get("/api/expense_reports",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = expense_report_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    inventory_transaction_create: {
      fields: lambda do |_connection, _config_fields|
        inventory_transaction_fields = [
          {
            name: "account",
            hint: "Receipt Account Code",
            type: "object",
            properties: [{
              name: "id",
              label: "Account",
              control_type: "select",
              pick_list: "accounts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "account-allocations",
            label: "Account allocations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "asn-header",
            label: "ASN header",
            control_type: "select",
            pick_list: "asn_headers",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "asn-header",
              label: "ASN header",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "asn-line",
            label: "ASN line",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "asset-tags",
            label: "Asset tags",
            hint: "Semi Colon separated list of Asset Tag Identifiers",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "barcode" },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "from-warehouse",
            label: "From warehouse",
            type: "object",
            properties: [{
              name: "id",
              label: "Warehouse",
              control_type: "select",
              pick_list: "warehouses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Warehouse ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "from-warehouse-location",
            label: "From warehouse location",
            hint: "Coupa's Internal From-Warehouse-Location ID",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "id",
            hint: "Coupa's Internal Inventory Transaction ID",
            type: "integer",
            sticky: true
          },
          {
            name: "inspection-code",
            label: "Inspection code",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "item",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Item",
              optional: false,
              control_type: "select",
              pick_list: "items",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Item ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported " \
              "in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "match-reference",
            label: "Match reference",
            hint: "Three-way match attribute to connect with Receipt and " \
              "Invoice Line"
          },
          {
            name: "order-line",
            label: "Order line",
            optional: false,
            type: "object",
            properties: [{name: "id", optional: false, type: "integer"}]
          },
          {
            name: "price",
            hint: "Item Price",
            control_type: "number",
            type: "number"
          },
          {
            name: "quantity",
            hint: "Receipt Quantity",
            control_type: "number",
            type: "number"
          },
          {
            name: "receipt",
            of: "object",
            properties: [{
              name: "id",
              label: "Receipt",
              control_type: "select",
              pick_list: "roles",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Receipt ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "receipts-batch-id",
            label: "Receipts batch ID",
            type: "integer"
          },
          {
            name: "received-weight",
            label: "Received weight",
            hint: "Inventory Transaction Received Weight",
            control_type: "number",
            type: "number"
          },
          {
            name: "receiving-form-response",
            label: "Received form response",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              {
                name: "is_internal",
                control_type: "checkbox",
                type: "boolean"
              },
              { name: "prompt" },
              {
                name: "responses",
                type: "array",
                properties: [{ name: "id", type: "integer" }]
              }
            ]
          },
          { name: "rfid-tag", label: "RFID tag" },
          {
            name: "status",
            hint: "Inventory Transaction Status",
            sticky: true
          },
          {
            name: "to-warehouse",
            label: "To warehouse",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Warehouse",
              optional: false,
              control_type: "select",
              pick_list: "warehouses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Warehouse ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "to-warehouse-location",
            label: "To warehouse location",
            hint: "Coupa's Internal To-Warehouse-Location ID",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              optional: false,
              type: "integer"
            }]
          },
          {
            name: "total",
            hint: "Receipt total",
            control_type: "number",
            type: "number"
          },
          {
            name: "transaction-date",
            label: "Transaction date",
            hint: "Actual date of transaction",
            type: "timestamp"
          },
          {
            name: "type",
            hint: "Inventory Transaction Type",
            control_type: "select",
            pick_list: "inventory_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "Type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "uom",
            label: "Unit of measure",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = inventory_transaction_fields.pluck(:name)
        sample_record = get("/api/inventory_transactions",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = inventory_transaction_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    inventory_transaction_get: {
      fields: lambda do |_connection, _config_fields|
        inventory_transaction_fields = [
          {
            name: "account",
            hint: "Receipt Account Code",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "account-allocations",
            label: "Account allocations",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "asn-header",
            label: "ASN header",
            control_type: "select",
            pick_list: "asn_headers",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "asn-header",
              label: "ASN header",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "asn-line",
            label: "ASN line",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "asset-tags",
            label: "Asset tags",
            hint: "Semi Colon separated list of Asset Tag Identifiers",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "barcode" },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "from-warehouse",
            label: "From warehouse",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "from-warehouse-location",
            label: "From warehouse location",
            hint: "Coupa's Internal From-Warehouse-Location ID",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "id",
            hint: "Coupa's Internal Inventory Transaction ID",
            type: "integer",
            sticky: true
          },
          {
            name: "inspection-code",
            label: "Inspection code",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "item",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "item-number" },
              { name: "name" }
            ]
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported " \
              "in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "match-reference",
            label: "Match reference",
            hint: "Three-way match attribute to connect with Receipt and " \
              "Invoice Line"
          },
          {
            name: "order-line",
            label: "Order line",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "price",
            hint: "Item Price",
            control_type: "number",
            type: "number"
          },
          {
            name: "quantity",
            hint: "Receipt Quantity",
            control_type: "number",
            type: "number"
          },
          {
            name: "receipt",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "receipts-batch-id",
            label: "Receipts batch ID",
            type: "integer"
          },
          {
            name: "received-weight",
            label: "Received weight",
            hint: "Inventory Transaction Received Weight",
            control_type: "number",
            type: "number"
          },
          {
            name: "receiving-form-response",
            label: "Received form response",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              {
                name: "is_internal",
                control_type: "checkbox",
                type: "boolean"
              },
              { name: "prompt" },
              {
                name: "responses",
                type: "array",
                properties: [{ name: "id", type: "integer" }]
              }
            ]
          },
          { name: "rfid-tag", label: "RFID tag" },
          {
            name: "status",
            hint: "Inventory Transaction Status",
            sticky: true
          },
          {
            name: "to-warehouse",
            label: "To warehouse",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "to-warehouse-location",
            label: "To warehouse location",
            hint: "Coupa's Internal To-Warehouse-Location ID",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "total",
            hint: "Receipt total",
            control_type: "number",
            type: "number"
          },
          {
            name: "transaction-date",
            label: "Transaction date",
            hint: "Actual date of transaction",
            type: "timestamp"
          },
          {
            name: "type",
            hint: "Inventory Transaction Type",
            control_type: "select",
            pick_list: "inventory_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "Type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "uom",
            label: "Unit of measure",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" },
              { name: "name" }
            ]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = inventory_transaction_fields.pluck(:name)
        sample_record = get("/api/inventory_transactions",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = inventory_transaction_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    invoice_create: {
      fields: lambda do |_connection, config_fields|
        invoice_fields = [
          {
            name: "account-type",
            label: "Account type",
            type: "object",
            properties: [{
              name: "id",
              label: "Account type",
              control_type: "select",
              pick_list: "account_types",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account type ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "advance-payment-received-amount",
            label: "Advance payment received amount",
            hint: "Amount of advance payment received",
            control_type: "number",
            type: "number"
          },
          {
            name: "approvals",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "bill-to-address",
            label: "Bill to address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "buyer-tax-registration",
            label: "Buyer tax registration",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "cash-accounting-scheme-reference",
            label: "Cash accounting scheme reference",
            hint: "Note if using cash accounting scheme",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "comments", content_type: "text-area" },
          {
            name: "compliant",
            hint: "Invoice compliance indicator",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "confirmation", content_type: "text-area" },
          {
            name: "contract",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract",
              control_type: "select",
              pick_list: "contracts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "credit-note-differences-with-original-invoice",
            label: "Credit note differences with original invoice",
            control_type: "number",
            type: "number"
          },
          {
            name: "credit-reason",
            label: "Credit reason",
            hint: "The reason of creating the credit",
            control_type: "text-area"
          },
          {
            name: "currency",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              optional: false,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "customs-declaration-date",
            label: "Customs declaration date",
            type: "timestamp"
          },
          {
            name: "customs-declaration-number",
            label: "Customs declaration number"
          },
          {
            name: "customs-office",
            label: "Customs office",
            control_type: "text-area"
          },
          {
            name: "destination-country",
            label: "Destination country",
            hint: "Country of destination used for compliance"
          },
          {
            name: "discount-amount",
            label: "Discount amount",
            hint: "Discount Amount provided by supplier",
            control_type: "number",
            type: "number"
          },
          {
            name: "discount-due-date",
            label: "Discount due date",
            hint: "Discount Due Date calculated based on the " \
              "discount payment terms",
            type: "timestamp"
          },
          {
            name: "discount-percent",
            label: "Discount percent",
            hint: "Discount %",
            control_type: "number",
            type: "number"
          },
          {
            name: "dispute-reason",
            label: "Dispute reason",
            hint: "Dispute reason",
            type: "object",
            properties: [
              { name: "code" },
              { name: "description" }
            ]
          },
          {
            name: "early-payment-provisions",
            label: "Early payment provisions",
            hint: "Early payment incentives",
            control_type: "text-area"
          },
          {
            name: "exchange-rate",
            label: "Exchange rate",
            control_type: "number",
            type: "number"
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "failed-tolerances",
            label: "Failed tolerances",
            hint: "Failed tolerances",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "folio-number", label: "Folio number" },
          {
            name: "form-of-payment",
            label: "Form of payment",
            hint: "Payment form",
            control_type: "text-area"
          },
          {
            name: "gross-total",
            label: "Gross total",
            control_type: "number",
            type: "number"
          },
          {
            name: "handling-amount",
            label: "Handling amount",
            control_type: "number",
            type: "number"
          },
          { name: "id", hint: "Coupa unique identifier", type: "integer" },
          {
            name: "image-scan",
            label: "Image scan",
            hint: "Invoice Image Scan attachment filename"
          },
          {
            name: "image-scan-url",
            label: "Image scan URL",
            hint: "Invoice Image Scan URL. Must begin with " \
              "'http://' or 'https://'.",
            control_type: "url"
          },
          {
            name: "inbound-invoice",
            label: "Inbound invoice",
            hint: "Inbound invoice reference"
          },
          {
            name: "internal-note",
            label: "Internal note",
            control_type: "text-area"
          },
          {
            name: "invoice-charges",
            label: "Invoice charges",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "invoice-date", label: "Invoice date", type: "timestamp" },
          {
            name: "invoice-from-address",
            label: "Invoice from address",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "invoice-lines",
            label: "Invoice lines",
            type: "array",
            of: "object",
            properties: [
              {
                name: "account",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Account",
                  control_type: "select",
                  pick_list: "accounts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Account ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "account-allocations",
                label: "Account allocations",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "account",
                    type: "object",
                    properties: [{
                      name: "id",
                      label: "Account",
                      control_type: "select",
                      pick_list: "accounts",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "id",
                        label: "Account ID",
                        toggle_hint: "Use custom value",
                        control_type: "number",
                        type: "integer"
                      }
                    }]
                  },
                  { name: "amount", control_type: "number", type: "number" },
                  { name: "pct", control_type: "number", type: "number" },
                  {
                    name: "period",
                    type: "object",
                    properties: [{
                      name: "id",
                      label: "Period",
                      control_type: "select",
                      pick_list: "periods",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "id",
                        label: "Period ID",
                        toggle_hint: "Use custom value",
                        control_type: "number",
                        type: "integer"
                      }
                    }]
                  }
                ]
              },
              { name: "billing-note", label: "Billing note" },
              {
                name: "commodity",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Commodity",
                  control_type: "select",
                  pick_list: "commodities",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Commodity ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "contract",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Contract",
                  control_type: "select",
                  pick_list: "contracts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Contract ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "currency",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Currency",
                  control_type: "select",
                  pick_list: "currencies",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Currency ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "delivery-note-number", label: "Delivery note number" },
              { name: "description", optional: false },
              {
                name: "failed-tolerances",
                label: "Failed tolerances",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              },
              {
                name: "item",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Item",
                  control_type: "select",
                  pick_list: "items",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Item ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "line-num", label: "Line num", type: "integer" },
              { name: "line-type", label: "Line type" },
              {
                name: "match-reference",
                label: "Match reference",
                hint: "Three-way match attribute to connect with " \
                  "Receipt and ASN Line"
              },
              {
                name: "net-weight",
                label: "Net weight",
                control_type: "number",
                type: "number"
              },
              { name: "order-line-id", label: "Order line ID" },
              {
                name: "original-date-of-supply",
                label: "Original date of supply",
                type: "timestamp"
              },
              {
                name: "period",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Period",
                  control_type: "select",
                  pick_list: "periods",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Period ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "price",
                sticky: true,
                control_type: "number",
                type: "number"
              },
              {
                name: "price-per-uom",
                label: "Price per uom",
                control_type: "number",
                type: "number"
              },
              {
                name: "quantity",
                control_type: "number",
                sticky: true,
                type: "number"
              },
              { name: "source-part-num", label: "Source part num" },
              {
                name: "taggings",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "active",
                    hint: "Tagging active state",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "description",
                    hint: "Description on the Tag on an Object (Tags on " \
                      "different objects can have different descriptions)"
                  },
                  {
                    name: "tag",
                    type: "object",
                    properties: [
                      { name: "name" },
                      {
                        name: "system-tag",
                        label: "System tag",
                        control_type: "checkbox",
                        type: "boolean"
                      }
                    ]
                  }
                ]
              },
              {
                name: "tags",
                type: "array",
                of: "object",
                properties: [
                  { name: "name" },
                  {
                    name: "system-tag",
                    label: "System tag",
                    control_type: "checkbox",
                    type: "boolean"
                  }
                ]
              },
              {
                name: "tax-amount",
                label: "Tax amount",
                control_type: "number",
                type: "number"
              },
              {
                name: "tax-code",
                label: "Tax code",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Tax code",
                  control_type: "select",
                  pick_list: "tax_codes",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Tax code ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "tax-lines",
                label: "Tax lines",
                type: "array",
                of: "object",
                properties: [
                  { name: "amount", control_type: "number", type: "number" },
                  {
                    name: "base",
                    hint: "Base to Calculate Withholding",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "basis",
                    hint: "Supplier Withholding Base Suggestion",
                    control_type: "number",
                    type: "number"
                  },
                  { name: "code-id", label: "Code ID", type: "integer" },
                  { name: "description", hint: "Tax Reference" },
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                      "if you want to update existing tax line.",
                    sticky: true,
                    type: "integer"
                  },
                  { name: "rate", control_type: "number", type: "number" },
                  {
                    name: "supplier-rate",
                    label: "Supplier rate",
                    hint: "Supplier Withholding Rate Suggestion",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "tax-code",
                    label: "Tax code",
                    type: "object",
                    properties: [{
                      name: "id",
                      label: "Tax code",
                      control_type: "select",
                      pick_list: "tax_codes",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "id",
                        label: "Tax code ID",
                        toggle_hint: "Use custom value",
                        control_type: "number",
                        type: "integer"
                      }
                    }]
                  },
                  {
                    name: "tax-rate",
                    label: "Tax rate",
                    type: "object",
                    properties: [
                      {
                        name: "active",
                        hint: "Tax rate is enabled or disabled",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "country",
                        hint: "Country where the tax code is applied"
                      },
                      {
                        name: "effective-date",
                        label: "Effective date",
                        hint: "Date when tax rate is become active",
                        type: "timestamp"
                      },
                      {
                        name: "exempt",
                        hint: "Whether Tax Rate is exempt or not",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "expiration-date",
                        label: "Expiration date",
                        hint: "Date when tax rate is expiring",
                        type: "timestamp"
                      },

                      {
                        name: "id",
                        hint: "Coupa unique identifier. Use this ID only " \
                          "if you want to update existing tax rate.",
                        sticky: true,
                        type: "integer"
                      },
                      {
                        name: "percentage",
                        hint: "Tax Rate percentage",
                        control_type: "number",
                        type: "number"
                      },
                      {
                        name: "reverse-charge",
                        label: "Reverse charge",
                        hint: "Whether Tax Rate is Reverse Charge or not",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "tax-rate-type",
                        label: "Tax rate type",
                        type: "object",
                        properties: [
                          {
                            name: "country",
                            hint: "Country where the tax rate type is applied"
                          },
                          {
                            name: "description",
                            hint: "Description of the tax rate type"
                          },
                          {
                            name: "id",
                            hint: "Coupa unique identifier. Use this ID only " \
                              "if you want to update existing tax rate type.",
                            sticky: true,
                            type: "integer"
                          },
                        ]
                      }
                    ]
                  },
                  {
                    name: "tax-rate-type",
                    label: "Tax rate type",
                    type: "object",
                    properties: [
                      {
                        name: "country",
                        hint: "Country where the tax rate type is applied"
                      },
                      {
                        name: "description",
                        hint: "Description of the tax rate type"
                      }
                    ]
                  },
                  {
                    name: "taxable-amount",
                    label: "Taxable amount",
                    hint: "Amount",
                    control_type: "number",
                    type: "number"
                  },
                  { name: "type", hint: "WithholdingTaxLine or TaxLine" },
                  {
                    name: "withholding-amount",
                    label: "Withholding amount",
                    control_type: "number",
                    type: "number"
                  }
                ]
              },
              { name: "tax-location", label: "Tax location" },
              {
                name: "type",
                optional: false,
                control_type: "select",
                pick_list: "invoice_line_types",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "type",
                  label: "Type",
                  toggle_hint: "Use custom value",
                  control_type: "text",
                  type: "string"
                }
              },
              {
                name: "uom",
                label: "Unit of measure",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Unit of measure",
                  control_type: "select",
                  pick_list: "uoms",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Unit of measure ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "weight-uom",
                label: "Weight UOM",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Weight UOM",
                  control_type: "select",
                  pick_list: "uoms",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Weight UOM ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "withholding-tax-lines",
                label: "Withholding tax lines",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              }
            ]
          },
          { name: "invoice-number", label: "Invoice number" },
          {
            name: "issuance-place",
            label: "Issuance place",
            control_type: "text-area"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "late-payment-penalties",
            label: "Late payment penalties",
            control_type: "text-area"
          },
          {
            name: "legal-destination-country",
            label: "Legal destination country",
            hint: "Legal desitnation country used for compliance"
          },
          {
            name: "line-level-taxation",
            label: "Line level taxation",
            hint: "Flag indicating whether taxes are provided at line " \
              "level in this invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "lock-version-key",
            label: "Lock version key",
            type: "integer"
          },
          {
            name: "margin-scheme",
            label: "Margin scheme",
            hint: "Reason for using margin scheme",
            control_type: "text-area"
          },
          {
            name: "misc-amount",
            label: "Misc amount",
            hint: "Miscellaneous Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "net-due-date",
            label: "Net due date",
            hint: "Net Due Date calculated based on the net payment terms",
            type: "timestamp"
          },
          {
            name: "origin-country",
            label: "Origin country",
            hint: "Country of origin used for compliance"
          },
          {
            name: "origin-currency-gross",
            label: "Origin currency gross",
            hint: "Local Currency Gross",
            control_type: "number",
            type: "number"
          },
          {
            name: "origin-currency-net",
            label: "Origin currency net",
            hint: "Local Currency Net",
            control_type: "number",
            type: "number"
          },
          {
            name: "original-invoice-date",
            label: "Original invoice date",
            hint: "Original invoice date used in case of a Credit Note",
            optional: config_fields["document_type"] != "Credit Note",
            type: "timestamp"
          },
          {
            name: "original-invoice-number",
            label: "Original invoice number",
            hint: "Original invoice number used in case of a Credit Note",
            optional: config_fields["document_type"] != "Credit Note"
          },
          { name: "paid", control_type: "checkbox", type: "boolean" },
          {
            name: "payment-date",
            label: "Payment date",
            hint: "Date of payment for invoice",
            type: "timestamp"
          },
          {
            name: "payment-method",
            label: "Payment method",
            hint: "Payment Method",
            control_type: "text-area"
          },
          {
            name: "payment-notes",
            label: "Payment notes",
            hint: "Notes included with payment for invoice",
            control_type: "text-area"
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Payment term code on invoice",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "payments",
            hint: "Payments",
            type: "array",
            of: "object",
            properties: [
              {
                name: "amount-paid",
                label: "Amount paid",
                control_type: "number",
                type: "number"
              },
              { name: "check-number", label: "Check number" },
              { name: "notes", control_type: "text-area" },
              { name: "payable-id", label: "Payable ID", type: "integer" },
              { name: "payable-type", label: "Payable type" },
              { name: "payment-date", label: "Payment date", type: "timestamp" }
            ]
          },
          {
            name: "pre-payment-date",
            label: "Pre-payment date",
            type: "timestamp"
          },
          {
            name: "remit-to-address",
            label: "Remit-to address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "requested-by",
            label: "Requested by",
            hint: "Requester on the invoice",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "reverse-charge-reference",
            label: "Reverse charge reference",
            control_type: "text-area"
          },
          {
            name: "self-billing-reference",
            label: "Self billing reference",
            hint: "Self billing reference on the invoice",
            control_type: "text-area"
          },
          { name: "series", control_type: "text-area" },
          {
            name: "ship-from-address",
            label: "Ship from address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "ship-to-address",
            label: "Ship to address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "shipping-amount",
            label: "Shipping amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "status", hint: "Invoice Status" },
          {
            name: "supplier",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              optional: false,
              control_type: "select",
              pick_list: "suppliers",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier-created",
            label: "Supplier created",
            hint: "Supplier created indicator for invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "supplier-note",
            label: "Supplier note",
            hint: "Note provided by supplier",
            control_type: "text-area"
          },
          {
            name: "supplier-remit-to",
            label: "Supplier remit to",
            hint: "Supplier provided remit to address",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "supplier-tax-registration",
            label: "Supplier tax registration",
            control_type: "select",
            pick_list: "tax_registrations",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "supplier-tax-registration",
              label: "Supplier tax registration ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "supplier-total",
            label: "Supplier total",
            control_type: "number",
            type: "number"
          },
          {
            name: "taggings",
            type: "array",
            of: "object",
            properties: [
              {
                name: "active",
                hint: "Tagging active state",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "description",
                hint: "Description on the Tag on an Object (Tags on " \
                  "different objects can have different descriptions)"
              },
              {
                name: "tag",
                type: "object",
                properties: [
                  { name: "name" },
                  {
                    name: "system-tag",
                    label: "System tag",
                    control_type: "checkbox",
                    type: "boolean"
                  }
                ]
              }
            ]
          },
          {
            name: "tags",
            type: "array",
            of: "object",
            properties: [
              { name: "name" },
              {
                name: "system-tag",
                label: "System tag",
                control_type: "checkbox",
                type: "boolean"
              }
            ]
          },
          {
            name: "tax-amount",
            label: "Tax amount",
            hint: "Not used if tax is provided at line level",
            control_type: "number",
            type: "number"
          },
          {
            name: "tax-amount-engine",
            label: "Tax amount engine",
            hint: "Tax amount calculated by either Coupa Native or " \
              "External Tax Engine based on configuration",
            control_type: "number",
            type: "number"
          },
          {
            name: "tax-code",
            label: "Tax code",
            hint: "Tax code (not used if tax is provided at line level)",
            type: "object",
            properties: [{
              name: "id",
              label: "Tax code",
              control_type: "select",
              pick_list: "tax_codes",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Tax code ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "tax-lines",
            label: "Tax lines",
            hint: "Line tax code (not used if tax is provided at header level)",
            type: "array",
            of: "object",
            properties: [
              { name: "amount", control_type: "number", type: "number" },
              {
                name: "base",
                hint: "Base to Calculate Withholding",
                control_type: "number",
                type: "number"
              },
              {
                name: "basis",
                hint: "Supplier Withholding Base Suggestion",
                control_type: "number",
                type: "number"
              },
              { name: "code-id", label: "Code ID", type: "integer" },
              { name: "description", hint: "Tax Reference" },
              { name: "rate", control_type: "number", type: "number" },
              {
                name: "supplier-rate",
                label: "Supplier rate",
                hint: "Supplier Withholding Rate Suggestion",
                control_type: "number",
                type: "number"
              },
              {
                name: "tax-code",
                label: "Tax code",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Tax code",
                  control_type: "select",
                  pick_list: "tax_codes",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Tax code ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "tax-rate",
                label: "Tax rate",
                type: "object",
                properties: [
                  {
                    name: "active",
                    hint: "Tax rate is enabled or disabled",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "country",
                    hint: "Country where the tax code is applied"
                  },
                  {
                    name: "effective-date",
                    label: "Effective date",
                    hint: "Date when tax rate is become active",
                    type: "timestamp"
                  },
                  {
                    name: "exempt",
                    hint: "Whether Tax Rate is exempt or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "expiration-date",
                    label: "Expiration date",
                    hint: "Date when tax rate is expiring",
                    type: "timestamp"
                  },
                  {
                    name: "percentage",
                    hint: "Tax Rate percentage",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "reverse-charge",
                    label: "Reverse charge",
                    hint: "Whether Tax Rate is Reverse Charge or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "tax-rate-type",
                    label: "Tax rate type",
                    type: "object",
                    properties: [
                      {
                        name: "country",
                        hint: "Country where the tax rate type is applied"
                      },
                      {
                        name: "description",
                        hint: "Description of the tax rate type"
                      }
                    ]
                  }
                ]
              },
              {
                name: "tax-rate-type",
                label: "Tax rate type",
                type: "object",
                properties: [
                  {
                    name: "country",
                    hint: "Country where the tax rate type is applied"
                  },
                  {
                    name: "description",
                    hint: "Description of the tax rate type"
                  }
                ]
              },
              {
                name: "taxable-amount",
                label: "Taxable amount",
                hint: "Amount",
                control_type: "number",
                type: "number"
              },
              {
                name: "type",
                hint: "WithholdingTaxLine or TaxLine",
                control_type: "text-area"
              },
              {
                name: "withholding-amount",
                label: "Withholding amount",
                control_type: "number",
                type: "number"
              }
            ]
          },
          {
            name: "tax-rate",
            label: "Tax rate",
            type: "object",
            properties: [
              {
                name: "active",
                hint: "Tax rate is enabled or disabled",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "country",
                hint: "Country where the tax code is applied"
              },
              {
                name: "effective-date",
                label: "Effective date",
                hint: "Date when tax rate is become active",
                type: "timestamp"
              },
              {
                name: "exempt",
                hint: "Whether Tax Rate is exempt or not",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "expiration-date",
                label: "Expiration date",
                hint: "Date when tax rate is expiring",
                type: "timestamp"
              },
              {
                name: "percentage",
                hint: "Tax Rate percentage",
                control_type: "number",
                type: "number"
              },
              {
                name: "reverse-charge",
                label: "Reverse charge",
                hint: "Whether Tax Rate is Reverse Charge or not",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "tax-rate-type",
                label: "Tax rate type",
                type: "object",
                properties: [
                  {
                    name: "country",
                    hint: "Country where the tax rate type is applied",
                    type: "object",
                    properties: [{
                      name: "code",
                      label: "Country",
                      control_type: "select",
                      pick_list: "countries",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "code",
                        label: "Country code",
                        toggle_hint: "Use custom value",
                        control_type: "text",
                        type: "string"
                      }
                    }]
                  },
                  {
                    name: "description",
                    hint: "Description of the tax rate type"
                  }
                ]
              }
            ]
          },
          {
            name: "taxes-in-origin-country-currency",
            label: "Taxes in origin country currency",
            hint: "Local Currency Tax",
            control_type: "number",
            type: "number"
          },
          {
            name: "tolerance-failures",
            label: "Tolerance failures",
            control_type: "text-area"
          },
          {
            name: "total-with-taxes",
            label: "Total with taxes",
            control_type: "number",
            type: "number"
          },
          {
            name: "type-of-receipt",
            label: "Type of receipt",
            control_type: "text-area"
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-of-invoice",
            label: "Use of invoice",
            control_type: "text-area"
          }
        ]
        standard_field_names = invoice_fields.pluck(:name)
        sample_record = get("/api/invoices",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = invoice_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    invoice_get: {
      fields: lambda do |_connection, _config_fields|
        invoice_fields = [
          {
            name: "account-type",
            label: "Account type",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "advance-payment-received-amount",
            label: "Advance payment received amount",
            hint: "Amount of advance payment received",
            control_type: "number",
            type: "number"
          },
          {
            name: "approvals",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "bill-to-address",
            label: "Bill to address",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "buyer-tax-registration",
            label: "Buyer tax registration",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "cash-accounting-scheme-reference",
            label: "Cash accounting scheme reference",
            hint: "Note if using cash accounting scheme",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "comments", content_type: "text-area" },
          {
            name: "compliant",
            hint: "Invoice compliance indicator",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "confirmation", content_type: "text-area" },
          {
            name: "contract",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "credit-note-differences-with-original-invoice",
            label: "Credit note differences with original invoice",
            control_type: "number",
            type: "number"
          },
          {
            name: "credit-reason",
            label: "Credit reason",
            hint: "The reason of creating the credit",
            control_type: "text-area"
          },
          {
            name: "currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "customs-declaration-date",
            label: "Customs declaration date",
            type: "timestamp"
          },
          {
            name: "customs-declaration-number",
            label: "Customs declaration number"
          },
          {
            name: "customs-office",
            label: "Customs office",
            control_type: "text-area"
          },
          {
            name: "destination-country",
            label: "Destination country",
            hint: "Country of destination used for compliance"
          },
          {
            name: "discount-amount",
            label: "Discount amount",
            hint: "Discount Amount provided by supplier",
            control_type: "number",
            type: "number"
          },
          {
            name: "discount-due-date",
            label: "Discount due date",
            hint: "Discount Due Date calculated based on the " \
              "discount payment terms",
            type: "timestamp"
          },
          {
            name: "discount-percent",
            label: "Discount percent",
            hint: "Discount %",
            control_type: "number",
            type: "number"
          },
          {
            name: "dispute-reason",
            label: "Dispute reason",
            hint: "Dispute reason",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "document-type",
            label: "Document type",
            control_type: "select",
            pick_list: "document_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "document-type",
              label: "Document type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "early-payment-provisions",
            label: "Early payment provisions",
            hint: "Early payment incentives",
            control_type: "text-area"
          },
          {
            name: "exchange-rate",
            label: "Exchange rate",
            control_type: "number",
            type: "number"
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "failed-tolerances",
            label: "Failed tolerances",
            hint: "Failed tolerances",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "folio-number", label: "Folio number" },
          {
            name: "form-of-payment",
            label: "Form of payment",
            hint: "Payment form",
            control_type: "text-area"
          },
          {
            name: "gross-total",
            label: "Gross total",
            control_type: "number",
            type: "number"
          },
          {
            name: "handling-amount",
            label: "Handling amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true ,
            type: "integer"
          },
          {
            name: "image-scan",
            label: "Image scan",
            hint: "Invoice Image Scan attachment filename"
          },
          {
            name: "image-scan-url",
            label: "Image scan URL",
            hint: "Invoice Image Scan URL. Must begin with " \
              "'http://' or 'https://'.",
            control_type: "url"
          },
          {
            name: "inbound-invoice",
            label: "Inbound invoice",
            hint: "Inbound invoice reference"
          },
          {
            name: "internal-note",
            label: "Internal note",
            control_type: "text-area"
          },
          {
            name: "invoice-charges",
            label: "Invoice charges",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "invoice-date", label: "Invoice date", type: "timestamp" },
          {
            name: "invoice-from-address",
            label: "Invoice from address",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "invoice-lines",
            label: "Invoice lines",
            sticky: true,
            type: "array",
            of: "object",
            properties: [
              {
                name: "account",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "code" }
                ]
              },
              {
                name: "account-allocations",
                label: "Account allocations",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "account",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "code" }
                    ]
                  },
                  { name: "amount", control_type: "number", type: "number" },
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  { name: "pct", control_type: "number", type: "number" },
                  {
                    name: "period",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "name" }
                    ]
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    hint: "Automatically created by Coupa in the format "\
                     "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"

                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    hint: "User who updated",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  }
                ]
              },
              {
                name: "accounting-total",
                label: "Accounting total",
                control_type: "number",
                type: "number"
              },
              {
                name: "accounting-total-currency",
                label: "Accounting total currency",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "code" }
                ]
              },
              { name: "billing-note", label: "Billing note" },
              {
                name: "commodity",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "name" }
                ]
              },
              { name: "company-uom", label: "Company UOM" },
              {
                name: "contract",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "name" }
                ]
              },
              { name: "created-at", label: "Created at", type: "timestamp" },
              {
                name: "created-by",
                label: "Created by",
                hint: "User who created",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              {
                name: "currency",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "code" }
                ]
              },
              {
                name: "customs-declaration-number",
                label: "Customs declaration number"
              },
              {
                name: "delivery-note-number",
                label: "Delivery note number"
              },
              { name: "description", sticky: true },
              {
                name: "discount-amount",
                label: "Discount amount",
                hint: "Discount Amount provided by supplier",
                control_type: "number",
                type: "number"
              },
              {
                name: "failed-tolerances",
                label: "Failed tolerances",
                hint: "Failed tolerances",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              },
              {
                name: "handling-distribution-total",
                label: "Handling distribution total",
                control_type: "number",
                type: "number"
              },
              {
                name: "id",
                hint: "Coupa unique identifier",
                sticky: true,
                type: "integer"
              },
              {
                name: "item",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "item-number" },
                  { name: "name" }
                ]
              },
              { name: "line-num", label: "Line num", type: "integer" },
              { name: "line-type", label: "Line type" },
              {
                name: "match-reference",
                label: "Match reference",
                hint: "Three-way match attribute to connect with " \
                  "Receipt and ASN Line"
              },
              {
                name: "misc-distribution-total",
                label: "Misc distribution total",
                control_type: "number",
                type: "number"
              },
              {
                name: "net-weight",
                label: "Net weight",
                control_type: "number",
                type: "number"
              },
              {
                name: "order-header-num",
                label: "Order header num",
                type: "integer"
              },
              { name: "order-line-commodity", label: "Order line commodity" },
              {
                name: "order-line-custom-fields",
                label: "Order custom fields"
              },
              { name: "order-line-id", label: "Order line ID" },
              {
                name: "order-line-num",
                label: "Order line num",
                type: "integer"
              },
              {
                name: "order-line-source-part-num",
                label: "Order line source part num",
                hint: "Supplier part number on the respective order line",
                type: "integer"
              },
              {
                name: "original-date-of-supply",
                label: "Original date of supply",
                type: "timestamp"
              },
              {
                name: "period",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "name" }
                ]
              },
              { name: "po-number", label: "PO number", type: "integer" },
              {
                name: "price",
                sticky: true,
                control_type: "number",
                type: "number"
              },
              {
                name: "price-per-uom",
                label: "Price per uom",
                control_type: "number",
                type: "number"
              },
              { name: "property-tax-account", label: "Property tax account" },
              {
                name: "quantity",
                control_type: "number",
                sticky: true,
                type: "number"
              },
              {
                name: "shipping-distribution-total",
                label: "Shipping distribution total",
                control_type: "number",
                type: "number"
              },
              { name: "source-part-num", label: "Source part num" },
              { name: "status", hint: "transaction status" },
              {
                name: "taggings",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "active",
                    hint: "Tagging active state",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  {
                    name: "description",
                    hint: "Description on the Tag on an Object (Tags on " \
                      "different objects can have different descriptions)",
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  {
                    name: "tag",
                    type: "object",
                    properties: [
                      {
                        name: "created-at",
                        label: "Created at",
                        hint: "Automatically created by Coupa in the " \
                          "format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "created-by",
                        label: "Created by",
                        hint: "User who created",
                        type: "object",
                        properties: [
                          { name: "id", type: "integer" },
                          { name: "login" },
                          { name: "email", control_type: "email" }
                        ]
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier",
                        type: "integer"
                      },
                      { name: "name" },
                      {
                        name: "system-tag",
                        label: "System tag",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "updated-at",
                        label: "Updated at",
                        hint: "Automatically created by Coupa in the " \
                          "format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "updated-by",
                        label: "Updated by",
                        hint: "User who updated",
                        type: "object",
                        properties: [
                          { name: "id", type: "integer" },
                          { name: "login" },
                          { name: "email", control_type: "email" }
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                name: "tags",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  { name: "name" },
                  {
                    name: "system-tag",
                    label: "System tag",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    hint: "User who updated",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  }
                ]
              },
              {
                name: "tax-amount",
                label: "Tax amount",
                hint: "tax_amount",
                control_type: "number",
                type: "number"
              },
              { name: "tax-amount-engine", label: "Tax amount engine" },
              {
                name: "tax-code",
                label: "Tax code",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "name" }
                ]
              },
              { name: "tax-description", label: "Tax description" },
              {
                name: "tax-distribution-total",
                label: "Tax distribution total",
                control_type: "number",
                type: "number"
              },
              {
                name: "tax-lines",
                label: "Tax lines",
                type: "array",
                of: "object",
                properties: [
                  { name: "amount", control_type: "number", type: "number" },
                  {
                    name: "base",
                    hint: "Base to Calculate Withholding",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "basis",
                    hint: "Supplier Withholding Base Suggestion",
                    control_type: "number",
                    type: "number"
                  },
                  { name: "code" },
                  { name: "code-id", label: "Code ID", type: "integer" },
                  {
                    name: "created-at",
                    label: "Created at",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  { name: "description", hint: "Tax Reference" },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  { name: "kind-of-factor", label: "Kind of factor" },
                  { name: "nature-of-tax", label: "Nature of tax" },
                  { name: "rate", control_type: "number", type: "number" },
                  {
                    name: "supplier-rate",
                    label: "Supplier rate",
                    hint: "Supplier Withholding Rate Suggestion",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "tax-code",
                    label: "Tax code",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "name" }
                    ]
                  },
                  {
                    name: "tax-rate",
                    label: "Tax rate",
                    type: "object",
                    properties: [
                      {
                        name: "active",
                        hint: "Tax rate is enabled or disabled",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "country",
                        hint: "Country where the tax code is applied"
                      },
                      {
                        name: "created-at",
                        label: "Created at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "created-by",
                        label: "Created by",
                        hint: "User who created",
                        type: "object",
                        properties: [
                          { name: "id", type: "integer" },
                          { name: "login" },
                          { name: "email", control_type: "email" }
                        ]
                      },
                      {
                        name: "effective-date",
                        label: "Effective date",
                        hint: "Date when tax rate is become active",
                        type: "timestamp"
                      },
                      {
                        name: "exempt",
                        hint: "Whether Tax Rate is exempt or not",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "expiration-date",
                        label: "Expiration date",
                        hint: "Date when tax rate is expiring",
                        type: "timestamp"
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier",
                        type: "integer"
                      },
                      {
                        name: "percentage",
                        hint: "Tax Rate percentage",
                        control_type: "number",
                        type: "number"
                      },
                      {
                        name: "reverse-charge",
                        label: "Reverse charge",
                        hint: "Whether Tax Rate is Reverse Charge or not",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "tax-rate-type",
                        label: "Tax rate type",
                        type: "object",
                        properties: [
                          {
                            name: "country",
                            hint: "Country where the tax rate type is applied"
                          },
                          {
                            name: "created-at",
                            label: "Created at",
                            hint: "Automatically created by Coupa in " \
                              "the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                            type: "timestamp"
                          },
                          {
                            name: "created-by",
                            label: "Created by",
                            hint: "User who created",
                            type: "object",
                            properties: [
                              { name: "id", type: "integer" },
                              { name: "login" },
                              { name: "email", control_type: "email" }
                            ]
                          },
                          {
                            name: "description",
                            hint: "Description of the tax rate type"
                          },
                          {
                            name: "id",
                            hint: "Coupa unique identifier",
                            type: "integer"
                          },
                          {
                            name: "updated-at",
                            label: "Updated at",
                            hint: "Automatically created by Coupa in " \
                              "the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                            type: "timestamp"
                          },
                          {
                            name: "updated-by",
                            label: "Updated by",
                            hint: "User who updated",
                            type: "object",
                            properties: [
                              { name: "id", type: "integer" },
                              { name: "login" },
                              { name: "email", control_type: "email" }
                            ]
                          }
                        ]
                      },
                      {
                        name: "updated-at",
                        label: "Updated at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "updated-by",
                        label: "Updated by",
                        hint: "User who updated",
                        type: "object",
                        properties: [
                          { name: "id", type: "integer" },
                          { name: "login" },
                          { name: "email", control_type: "email" }
                        ]
                      }
                    ]
                  },
                  {
                    name: "tax-rate-type",
                    label: "Tax rate type",
                    type: "object",
                    properties: [
                      {
                        name: "country",
                        hint: "Country where the tax rate type is applied"
                      },
                      {
                        name: "created-at",
                        label: "Created at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "created-by",
                        label: "Created by",
                        hint: "User who created"
                      },
                      {
                        name: "description",
                        hint: "Description of the tax rate type"
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier",
                        type: "integer"
                      },
                      {
                        name: "updated-at",
                        label: "Updated at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "updated-by",
                        label: "Updated by",
                        hint: "User who updated"
                      }
                    ]
                  },
                  {
                    name: "taxable-amount",
                    label: "Taxable amount",
                    hint: "Amount",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "type",
                    hint: "WithholdingTaxLine or TaxLine",
                    control_type: "text-area"
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    type: "timestamp"
                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  {
                    name: "withholding-amount",
                    label: "Withholding amount",
                    control_type: "number",
                    type: "number"
                  }
                ]
              },
              { name: "tax-location", label: "Tax location" },
              {
                name: "tax-rate",
                label: "Tax rate",
                type: "object",
                properties: [
                  {
                    name: "active",
                    hint: "Tax rate is enabled or disabled",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "country",
                    hint: "Country where the tax code is applied"
                  },
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created"
                  },
                  {
                    name: "effective-date",
                    label: "Effective date",
                    hint: "Date when tax rate is become active",
                    type: "timestamp"
                  },
                  {
                    name: "exempt",
                    hint: "Whether Tax Rate is exempt or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "expiration-date",
                    label: "Expiration date",
                    hint: "Date when tax rate is expiring",
                    type: "timestamp"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  {
                    name: "percentage",
                    hint: "Tax Rate percentage",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "reverse-charge",
                    label: "Reverse charge",
                    hint: "Whether Tax Rate is Reverse Charge or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "tax-rate-type",
                    label: "Tax rate type",
                    type: "object",
                    properties: [
                      {
                        name: "country",
                        hint: "Country where the tax rate type is applied"
                      },
                      {
                        name: "created-at",
                        label: "Created at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "created-by",
                        label: "Created by",
                        hint: "User who created"
                      },
                      {
                        name: "description",
                        hint: "Description of the tax rate type"
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier",
                        type: "integer"
                      },
                      {
                        name: "updated-at",
                        label: "Updated at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "updated-by",
                        label: "Updated by",
                        hint: "User who updated"
                      }
                    ]
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    hint: "User who updated"
                  }
                ]
              },
              { name: "tax-supply-date", label: "Tax supply date" },
              {
                name: "total",
                control_type: "number",
                type: "number"
              },
              { name: "type" },
              { name: "unspsc", label: "UNSPSC" },
              {
                name: "uom",
                label: "Unit of measure",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "code" },
                  { name: "name" }
                ]
              },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              {
                name: "weight-uom",
                label: "Weight UOM",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "code" },
                  { name: "name" }
                ]
              },
              {
                name: "withholding-tax-lines",
                label: "Withholding tax lines",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              }
            ]
          },
          { name: "invoice-number", label: "Invoice number", sticky: true },
          {
            name: "issuance-place",
            label: "Issuance place",
            control_type: "text-area"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported " \
              "in the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "late-payment-penalties",
            label: "Late payment penalties",
            control_type: "text-area"
          },
          {
            name: "legal-destination-country",
            label: "Legal destination country",
            hint: "Legal desitnation country used for compliance"
          },
          {
            name: "line-level-taxation",
            label: "Line level taxation",
            hint: "Flag indicating whether taxes are provided " \
              "at line level in this invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "lock-version-key",
            label: "Lock version key",
            type: "integer"
          },
          {
            name: "margin-scheme",
            label: "Margin scheme",
            hint: "Reason for using margin scheme",
            control_type: "text-area"
          },
          {
            name: "misc-amount",
            label: "Misc amount",
            hint: "Miscellaneous Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "net-due-date",
            label: "Net due date",
            hint: "Net Due Date calculated based on the net payment terms",
            type: "timestamp"
          },
          {
            name: "origin-country",
            label: "Origin country",
            hint: "Country of origin used for compliance"
          },
          {
            name: "origin-currency-gross",
            label: "Origin currency gross",
            hint: "Local Currency Gross",
            control_type: "number",
            type: "number"
          },
          {
            name: "origin-currency-net",
            label: "Origin currency net",
            hint: "Local Currency Net",
            control_type: "number",
            type: "number"
          },
          {
            name: "original-invoice-date",
            label: "Original invoice date",
            hint: "Original invoice date used in case of a Credit Note",
            type: "timestamp"
          },
          {
            name: "original-invoice-number",
            label: "Original invoice number",
            hint: "Original invoice number used in case of a Credit Note",
            sticky: true
          },
          { name: "paid", control_type: "checkbox", type: "boolean" },
          {
            name: "payment-date",
            label: "Payment date",
            hint: "Date of payment for invoice",
            type: "timestamp"
          },
          {
            name: "payment-method",
            label: "Payment method",
            hint: "Payment Method",
            control_type: "text-area"
          },
          {
            name: "payment-notes",
            label: "Payment notes",
            hint: "Notes included with payment for invoice",
            control_type: "text-area"
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Payment term code on invoice",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "payments",
            type: "array",
            of: "object",
            properties: [
              {
                name: "amount-paid",
                label: "Amount paid",
                control_type: "number",
                type: "number"
              },
              { name: "created-at", label: "Created at", type: "timestamp" },
              {
                name: "created-by",
                label: "Created by",
                type: "object",
                hint: "User who created",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              {
                name: "id",
                hint: "Coupa unique identifier",
                type: "integer"
              },
              { name: "notes", control_type: "text-area" },
              {
                name: "payable-id",
                label: "Payable ID",
                type: "integer"
              },
              { name: "payable-type", label: "Payable type" },
              {
                name: "payment-date",
                label: "Payment date",
                type: "timestamp"
              },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              }
            ]
          },
          {
            name: "pre-payment-date",
            label: "Pre-payment date",
            type: "timestamp"
          },
          {
            name: "remit-to-address",
            label: "Remit-to address",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "location-code", label: "Location code" }
            ]
          },
          {
            name: "requested-by",
            label: "Requested by",
            hint: "Requester on the invoice",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "reverse-charge-reference",
            label: "Reverse charge reference",
            control_type: "text-area"
          },
          {
            name: "self-billing-reference",
            label: "Self billing reference",
            hint: "Self billing reference on the invoice",
            control_type: "text-area"
          },
          { name: "series", control_type: "text-area" },
          {
            name: "ship-from-address",
            label: "Ship from address",
            type: "object",
            properties: [
              { name: "id", type: "integer"  },
              { name: "name" },
              { name: "location-code", label: "Location code" }
            ]
          },
          {
            name: "ship-to-address",
            label: "Ship to address",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "shipping-amount",
            label: "Shipping amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "status", hint: "Invoice Status" },
          {
            name: "supplier",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "number" }
            ]
          },
          {
            name: "supplier-created",
            label: "Supplier created",
            hint: "Supplier created indicator for invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "supplier-note",
            label: "Supplier note",
            hint: "Note provided by supplier",
            control_type: "text-area"
          },
          {
            name: "supplier-remit-to",
            label: "Supplier remit to",
            hint: "Supplier provided remit to address",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "supplier-tax-registration",
            label: "Supplier tax registration",
            control_type: "select",
            pick_list: "tax_registrations",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "supplier-tax-registration",
              label: "Supplier tax registration ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "supplier-total",
            label: "Supplier total",
            control_type: "number",
            type: "number"
          },
          {
            name: "taggings",
            type: "array",
            of: "object",
            properties: [
              {
                name: "active",
                hint: "Tagging active state",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "created-at",
                label: "Created at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "created-by",
                label: "Created by",
                hint: "User who created",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              {
                name: "description",
                hint: "Description on the Tag on an Object (Tags on " \
                  "different objects can have different descriptions)",
              },
              { name: "id", hint: "Coupa unique identifier", type: "integer" },
              {
                name: "tag",
                type: "object",
                properties: [
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  { name: "name" },
                  {
                    name: "system-tag",
                    label: "System tag",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    hint: "User who updated",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  }
                ]
              }
            ]
          },
          {
            name: "tags",
            type: "array",
            of: "object",
            properties: [
              {
                name: "created-at",
                label: "Created at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "created-by",
                label: "Created by",
                hint: "User who created",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              { name: "id", hint: "Coupa unique identifier", type: "integer" },
              { name: "name" },
              {
                name: "system-tag",
                label: "System tag",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                hint: "User who updated",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              }
            ]
          },
          {
            name: "tax-amount",
            label: "Tax amount",
            hint: "Tax amount (not used if tax is provided at line level)",
            control_type: "number",
            type: "number"
          },
          {
            name: "tax-amount-engine",
            label: "Tax amount engine",
            hint: "Tax amount calculated by either Coupa Native or " \
              "External Tax Engine based on configuration",
            control_type: "number",
            type: "number"
          },
          {
            name: "tax-code",
            label: "Tax code",
            hint: "This field is not used if tax is provided at line level",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "tax-lines",
            label: "Tax lines",
            type: "array",
            of: "object",
            properties: [
              { name: "amount", control_type: "number", type: "number" },
              {
                name: "base",
                hint: "Base to Calculate Withholding",
                control_type: "number",
                type: "number"
              },
              {
                name: "basis",
                hint: "Supplier Withholding Base Suggestion",
                control_type: "number",
                type: "number"
              },
              { name: "code" },
              { name: "code-id", label: "Code ID", type: "integer" },
              { name: "created-at", label: "Created at", type: "timestamp" },
              {
                name: "created-by",
                label: "Created by",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              { name: "description", hint: "Tax Reference" },
              { name: "id", hint: "Coupa unique identifier", type: "integer" },
              { name: "kind-of-factor", label: "Kind of factor" },
              { name: "nature-of-tax", label: "Nature of tax" },
              { name: "rate", control_type: "number", type: "number" },
              {
                name: "supplier-rate",
                label: "Supplier rate",
                hint: "Supplier Withholding Rate Suggestion",
                control_type: "number",
                type: "number"
              },
              {
                name: "tax-code",
                label: "Tax code",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "name" }
                ]
              },
              {
                name: "tax-rate",
                label: "Tax rate",
                type: "object",
                properties: [
                  {
                    name: "active",
                    hint: "Tax rate is enabled or disabled",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "country",
                    hint: "Country where the tax code is applied"
                  },
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created"
                  },
                  {
                    name: "effective-date",
                    label: "Effective date",
                    hint: "Date when tax rate is become active",
                    type: "timestamp"
                  },
                  {
                    name: "exempt",
                    hint: "Whether Tax Rate is exempt or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "expiration-date",
                    label: "Expiration date",
                    hint: "Date when tax rate is expiring",
                    type: "timestamp"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  {
                    name: "percentage",
                    hint: "Tax Rate percentage",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "reverse-charge",
                    label: "Reverse charge",
                    hint: "Whether Tax Rate is Reverse Charge or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "tax-rate-type",
                    label: "Tax rate type",
                    type: "object",
                    properties: [
                      {
                        name: "country",
                        hint: "Country where the tax rate type is applied"
                      },
                      {
                        name: "created-at",
                        label: "Created at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "created-by",
                        label: "Created by",
                        hint: "User who created",
                        type: "object",
                        properties: [
                          { name: "id", type: "integer" },
                          { name: "login" },
                          { name: "email", control_type: "email" }
                        ]
                      },
                      {
                        name: "description",
                        hint: "Description of the tax rate type"
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier",
                        type: "integer"
                      },
                      {
                        name: "updated-at",
                        label: "Updated at",
                        hint: "Automatically created by Coupa in the format " \
                          "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                        type: "timestamp"
                      },
                      {
                        name: "updated-by",
                        label: "Updated by",
                        hint: "User who updated",
                        type: "object",
                        properties: [
                          { name: "id", type: "integer" },
                          { name: "login" },
                          { name: "email", control_type: "email" }
                        ]
                      }
                    ]
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    hint: "User who updated",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  }
                ]
              },
              {
                name: "tax-rate-type",
                label: "Tax rate type",
                type: "object",
                properties: [
                  {
                    name: "country",
                    hint: "Country where the tax rate type is applied"
                  },
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  {
                    name: "description",
                    hint: "Description of the tax rate type"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    hint: "User who updated",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  }
                ]
              },
              {
                name: "taxable-amount",
                label: "Taxable amount",
                hint: "Amount",
                control_type: "number",
                type: "number"
              },
              {
                name: "type",
                hint: "WithholdingTaxLine or TaxLine",
                control_type: "text-area"
              },
              { name: "updated-at", label: "Updated at", type: "timestamp" },
              {
                name: "updated-by",
                label: "Updated by",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              {
                name: "withholding-amount",
                label: "Withholding amount",
                control_type: "number",
                type: "number"
              }
            ]
          },
          {
            name: "tax-rate",
            label: "Tax rate",
            type: "object",
            properties: [
              {
                name: "active",
                hint: "Tax rate is enabled or disabled",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "country",
                hint: "Country where the tax code is applied"
              },
              {
                name: "created-at",
                label: "Created at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "created-by",
                label: "Created by",
                hint: "User who created",
                type: "object",
                properties: [
                  { name: "id", type: "integer" },
                  { name: "login" },
                  { name: "email", control_type: "email" }
                ]
              },
              {
                name: "effective-date",
                label: "Effective date",
                hint: "Date when tax rate is become active",
                type: "timestamp"
              },
              {
                name: "exempt",
                hint: "Whether Tax Rate is exempt or not",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "expiration-date",
                label: "Expiration date",
                hint: "Date when tax rate is expiring",
                type: "timestamp"
              },
              { name: "id", hint: "Coupa unique identifier", type: "integer" },
              {
                name: "percentage",
                hint: "Tax Rate percentage",
                control_type: "number",
                type: "number"
              },
              {
                name: "reverse-charge",
                label: "Reverse charge",
                hint: "Whether Tax Rate is Reverse Charge or not",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "tax-rate-type",
                label: "Tax rate type",
                type: "object",
                properties: [
                  {
                    name: "country",
                    hint: "Country where the tax rate type is applied"
                  },
                  {
                    name: "created-at",
                    label: "Created at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "created-by",
                    label: "Created by",
                    hint: "User who created",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  },
                  {
                    name: "description",
                    hint: "Description of the tax rate type"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier",
                    type: "integer"
                  },
                  {
                    name: "updated-at",
                    label: "Updated at",
                    hint: "Automatically created by Coupa in the format " \
                      "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                    type: "timestamp"
                  },
                  {
                    name: "updated-by",
                    label: "Updated by",
                    hint: "User who updated",
                    type: "object",
                    properties: [
                      { name: "id", type: "integer" },
                      { name: "login" },
                      { name: "email", control_type: "email" }
                    ]
                  }
                ]
              },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                hint: "User who updated"
              }
            ]
          },
          {
            name: "taxes-in-origin-country-currency",
            label: "Taxes in origin country currency",
            hint: "Local Currency Tax",
            control_type: "number",
            type: "number"
          },
          {
            name: "tolerance-failures",
            label: "Tolerance failures",
            control_type: "text-area"
          },
          {
            name: "total-with-taxes",
            label: "Total with taxes",
            control_type: "number",
            type: "number"
          },
          {
            name: "type-of-receipt",
            label: "Type of receipt",
            control_type: "text-area"
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-of-invoice",
            label: "Use of invoice",
            control_type: "text-area"
          }
        ]
        standard_field_names = invoice_fields.pluck(:name)
        sample_record = get("/api/invoices",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = invoice_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    invoice_update: {
      fields: lambda do |_connection, _config_fields|
        invoice_fields = [
          {
            name: "account-type",
            label: "Account type",
            type: "object",
            properties: [{
              name: "id",
              label: "Account type",
              control_type: "select",
              pick_list: "account_types",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account type ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "advance-payment-received-amount",
            label: "Advance payment received amount",
            hint: "Amount of advance payment received",
            control_type: "number",
            type: "number"
          },
          {
            name: "approvals",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "bill-to-address",
            label: "Bill to address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "buyer-tax-registration",
            label: "Buyer tax registration",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "cash-accounting-scheme-reference",
            label: "Cash accounting scheme reference",
            hint: "Note if using cash accounting scheme",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "comments", content_type: "text-area" },
          {
            name: "compliant",
            hint: "Invoice compliance indicator",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "confirmation", content_type: "text-area" },
          {
            name: "contract",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract",
              control_type: "select",
              pick_list: "contracts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "credit-note-differences-with-original-invoice",
            label: "Credit note differences with original invoice",
            control_type: "number",
            type: "number"
          },
          {
            name: "credit-reason",
            label: "Credit reason",
            hint: "The reason of creating the credit",
            control_type: "text-area"
          },
          {
            name: "currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              sticky: true,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "customs-declaration-date",
            label: "Customs declaration date",
            type: "timestamp"
          },
          {
            name: "customs-declaration-number",
            label: "Customs declaration number"
          },
          {
            name: "customs-office",
            label: "Customs office",
            control_type: "text-area"
          },
          {
            name: "destination-country",
            label: "Destination country",
            hint: "Country of destination used for compliance"
          },
          {
            name: "discount-amount",
            label: "Discount amount",
            hint: "Discount Amount provided by supplier",
            control_type: "number",
            type: "number"
          },
          {
            name: "discount-due-date",
            label: "Discount due date",
            hint: "Discount Due Date calculated based on the " \
              "discount payment terms",
            type: "timestamp"
          },
          {
            name: "discount-percent",
            label: "Discount percent",
            hint: "Discount %",
            control_type: "number",
            type: "number"
          },
          {
            name: "dispute-reason",
            label: "Dispute reason",
            type: "object",
            properties: [
              { name: "code" },
              { name: "description" },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing dispute reason.",
                type: "integer"
              },
            ]
          },
          {
            name: "early-payment-provisions",
            label: "Early payment provisions",
            hint: "Early payment incentives",
            control_type: "text-area"
          },
          {
            name: "exchange-rate",
            label: "Exchange rate",
            control_type: "number",
            type: "number"
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "failed-tolerances",
            label: "Failed tolerances",
            hint: "Failed tolerances",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "folio-number", label: "Folio number" },
          {
            name: "form-of-payment",
            label: "Form of payment",
            hint: "Payment form",
            control_type: "text-area"
          },
          {
            name: "gross-total",
            label: "Gross total",
            control_type: "number",
            type: "number"
          },
          {
            name: "handling-amount",
            label: "Handling amount",
            control_type: "number",
            type: "number"
          },
          { name: "id", hint: "Coupa unique identifier", type: "integer" },
          {
            name: "image-scan",
            label: "Image scan",
            hint: "Invoice Image Scan attachment filename"
          },
          {
            name: "image-scan-url",
            label: "Image scan URL",
            hint: "Invoice Image Scan URL. Must begin with " \
              "'http://' or 'https://'.",
            control_type: "url"
          },
          {
            name: "inbound-invoice",
            label: "Inbound invoice",
            hint: "Inbound invoice reference"
          },
          {
            name: "internal-note",
            label: "Internal note",
            control_type: "text-area"
          },
          {
            name: "invoice-charges",
            label: "Invoice charges",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "invoice-date", label: "Invoice date", type: "timestamp" },
          {
            name: "invoice-from-address",
            label: "Invoice from address",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "invoice-lines",
            label: "Invoice lines",
            type: "array",
            of: "object",
            properties: [
              {
                name: "account",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Account",
                  control_type: "select",
                  pick_list: "accounts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Account ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "account-allocations",
                label: "Account allocations",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "account",
                    type: "object",
                    properties: [{
                      name: "id",
                      label: "Account",
                      control_type: "select",
                      pick_list: "accounts",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "id",
                        label: "Account ID",
                        toggle_hint: "Use custom value",
                        control_type: "number",
                        type: "integer"
                      }
                    }]
                  },
                  { name: "amount", control_type: "number", type: "number" },
                  { name: "pct", control_type: "number", type: "number" },
                  {
                    name: "period",
                    type: "object",
                    properties: [{
                      name: "id",
                      label: "Period",
                      control_type: "select",
                      pick_list: "periods",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "id",
                        label: "Period ID",
                        toggle_hint: "Use custom value",
                        control_type: "number",
                        type: "integer"
                      }
                    }]
                  }
                ]
              },
              { name: "billing-note", label: "Billing note" },
              {
                name: "commodity",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Commodity",
                  control_type: "select",
                  pick_list: "commodities",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Commodity ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "contract",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Contract",
                  control_type: "select",
                  pick_list: "contracts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Contract ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "currency",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Currency",
                  control_type: "select",
                  pick_list: "currencies",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Currency ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "delivery-note-number", label: "Delivery note number" },
              { name: "description", sticky: true },
              {
                name: "failed-tolerances",
                label: "Failed tolerances",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing invoice line.",
                type: "integer"
              },
              {
                name: "item",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Item",
                  control_type: "select",
                  pick_list: "items",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Item ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "line-num", label: "Line num", type: "integer" },
              { name: "line-type", label: "Line type" },
              {
                name: "match-reference",
                label: "Match reference",
                hint: "Three-way match attribute to connect with " \
                  "Receipt and ASN Line"
              },
              {
                name: "net-weight",
                label: "Net weight",
                control_type: "number",
                type: "number"
              },
              { name: "order-line-id", label: "Order line ID" },
              {
                name: "original-date-of-supply",
                label: "Original date of supply",
                type: "timestamp"
              },
              {
                name: "period",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Period",
                  control_type: "select",
                  pick_list: "periods",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Period ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "price",
                sticky: true,
                control_type: "number",
                type: "number"
              },
              {
                name: "price-per-uom",
                label: "Price per uom",
                control_type: "number",
                type: "number"
              },
              {
                name: "quantity",
                control_type: "number",
                sticky: true,
                type: "number"
              },
              { name: "source-part-num", label: "Source part num" },
              {
                name: "taggings",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "active",
                    hint: "Tagging active state",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "description",
                    hint: "Description on the Tag on an Object (Tags on " \
                      "different objects can have different descriptions)",
                  },
                  {
                    name: "tag",
                    type: "object",
                    properties: [
                      { name: "name" },
                      {
                        name: "system-tag",
                        label: "System tag",
                        control_type: "checkbox",
                        type: "boolean"
                      }
                    ]
                  }
                ]
              },
              {
                name: "tags",
                type: "array",
                of: "object",
                properties: [
                  { name: "name" },
                  {
                    name: "system-tag",
                    label: "System tag",
                    control_type: "checkbox",
                    type: "boolean"
                  }
                ]
              },
              {
                name: "tax-amount",
                label: "Tax amount",
                hint: "tax_amount",
                control_type: "number",
                type: "number"
              },
              {
                name: "tax-code",
                label: "Tax code",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Tax code",
                  control_type: "select",
                  pick_list: "tax_codes",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Tax code ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "tax-lines",
                label: "Tax lines",
                type: "array",
                of: "object",
                properties: [
                  { name: "amount", control_type: "number", type: "number" },
                  {
                    name: "base",
                    hint: "Base to Calculate Withholding",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "basis",
                    hint: "Supplier Withholding Base Suggestion",
                    control_type: "number",
                    type: "number"
                  },
                  { name: "code-id", label: "Code ID", type: "integer" },
                  { name: "description", hint: "Tax Reference" },
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                      "if you want to update existing tax line.",
                    type: "integer"
                  },
                  { name: "rate", control_type: "number", type: "number" },
                  {
                    name: "supplier-rate",
                    label: "Supplier rate",
                    hint: "Supplier Withholding Rate Suggestion",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "tax-code",
                    label: "Tax code",
                    type: "object",
                    properties: [{
                      name: "id",
                      label: "Tax code",
                      control_type: "select",
                      pick_list: "tax_codes",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "id",
                        label: "Tax code ID",
                        toggle_hint: "Use custom value",
                        control_type: "number",
                        type: "integer"
                      }
                    }]
                  },
                  {
                    name: "tax-rate",
                    label: "Tax rate",
                    type: "object",
                    properties: [
                      {
                        name: "active",
                        hint: "Tax rate is enabled or disabled",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "country",
                        hint: "Country where the tax code is applied"
                      },
                      {
                        name: "effective-date",
                        label: "Effective date",
                        hint: "Date when tax rate is become active",
                        type: "timestamp"
                      },
                      {
                        name: "exempt",
                        hint: "Whether Tax Rate is exempt or not",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "expiration-date",
                        label: "Expiration date",
                        hint: "Date when tax rate is expiring",
                        type: "timestamp"
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier. Use this ID only " \
                          "if you want to update existing tax rate.",
                        type: "integer"
                      },
                      {
                        name: "percentage",
                        hint: "Tax Rate percentage",
                        control_type: "number",
                        type: "number"
                      },
                      {
                        name: "reverse-charge",
                        label: "Reverse charge",
                        hint: "Whether Tax Rate is Reverse Charge or not",
                        control_type: "checkbox",
                        type: "boolean"
                      },
                      {
                        name: "tax-rate-type",
                        label: "Tax rate type",
                        type: "object",
                        properties: [
                          {
                            name: "country",
                            hint: "Country where the tax rate type is applied"
                          },
                          {
                            name: "description",
                            hint: "Description of the tax rate type"
                          },
                          {
                            name: "id",
                            hint: "Coupa unique identifier. Use this ID only " \
                              "if you want to update existing tax rate type.",
                            type: "integer"
                          }
                        ]
                      }
                    ]
                  },
                  {
                    name: "tax-rate-type",
                    label: "Tax rate type",
                    type: "object",
                    properties: [
                      {
                        name: "country",
                        hint: "Country where the tax rate type is applied"
                      },
                      {
                        name: "description",
                        hint: "Description of the tax rate type"
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier. Use this ID only " \
                          "if you want to update existing tax rate type.",
                        type: "integer"
                      }
                    ]
                  },
                  {
                    name: "taxable-amount",
                    label: "Taxable amount",
                    hint: "Amount",
                    control_type: "number",
                    type: "number"
                  },
                  { name: "type", hint: "WithholdingTaxLine or TaxLine" },
                  {
                    name: "withholding-amount",
                    label: "Withholding amount",
                    control_type: "number",
                    type: "number"
                  }
                ]
              },
              { name: "tax-location", label: "Tax location" },
              {
                name: "type",
                control_type: "select",
                pick_list: "invoice_line_types",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "type",
                  label: "Type",
                  toggle_hint: "Use custom value",
                  control_type: "text",
                  type: "string"
                }
              },
              {
                name: "uom",
                label: "Unit of measure",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Unit of measure",
                  control_type: "select",
                  pick_list: "uoms",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Unit of measure ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "weight-uom",
                label: "Weight UOM",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Weight UOM",
                  control_type: "select",
                  pick_list: "uoms",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Weight UOM ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "withholding-tax-lines",
                label: "Withholding tax lines",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              }
            ]
          },
          { name: "invoice-number", label: "Invoice number" },
          {
            name: "issuance-place",
            label: "Issuance place",
            control_type: "text-area"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "late-payment-penalties",
            label: "Late payment penalties",
            control_type: "text-area"
          },
          {
            name: "legal-destination-country",
            label: "Legal destination country",
            hint: "Legal desitnation country used for compliance"
          },
          {
            name: "line-level-taxation",
            label: "Line level taxation",
            hint: "Flag indicating whether taxes are provided at line " \
              "level in this invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "lock-version-key",
            label: "Lock version key",
            type: "integer"
          },
          {
            name: "margin-scheme",
            label: "Margin scheme",
            hint: "Reason for using margin scheme",
            control_type: "text-area"
          },
          {
            name: "misc-amount",
            label: "Misc amount",
            hint: "Miscellaneous Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "net-due-date",
            label: "Net due date",
            hint: "Net Due Date calculated based on the net payment terms",
            type: "timestamp"
          },
          {
            name: "origin-country",
            label: "Origin country",
            hint: "Country of origin used for compliance"
          },
          {
            name: "origin-currency-gross",
            label: "Origin currency gross",
            hint: "Local Currency Gross",
            control_type: "number",
            type: "number"
          },
          {
            name: "origin-currency-net",
            label: "Origin currency net",
            hint: "Local Currency Net",
            control_type: "number",
            type: "number"
          },
          {
            name: "original-invoice-date",
            label: "Original invoice date",
            hint: "Original invoice date used in case of a Credit Note",
            sticky: true,
            type: "timestamp"
          },
          {
            name: "original-invoice-number",
            label: "Original invoice number",
            hint: "Original invoice number used in case of a Credit Note",
            sticky: true
          },
          { name: "paid", control_type: "checkbox", type: "boolean" },
          {
            name: "payment-date",
            label: "Payment date",
            hint: "Date of payment for invoice",
            type: "timestamp"
          },
          {
            name: "payment-method",
            label: "Payment method",
            hint: "Payment Method",
            control_type: "text-area"
          },
          {
            name: "payment-notes",
            label: "Payment notes",
            hint: "Notes included with payment for invoice",
            control_type: "text-area",
            sticky: true
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Payment term code on invoice",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "payments",
            hint: "Payments",
            type: "array",
            of: "object",
            properties: [
              {
                name: "amount-paid",
                label: "Amount paid",
                control_type: "number",
                type: "number"
              },
              { name: "check-number", label: "Check number" },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing payment.",
                type: "integer"
              },
              { name: "notes", control_type: "text-area" },
              { name: "payable-id", label: "Payable ID", type: "integer" },
              { name: "payable-type", label: "Payable type" },
              { name: "payment-date", label: "Payment date", type: "timestamp" }
            ]
          },
          {
            name: "pre-payment-date",
            label: "Pre-payment date",
            type: "timestamp"
          },
          {
            name: "remit-to-address",
            label: "Remit-to address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "requested-by",
            label: "Requested by",
            hint: "Requester on the invoice",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "reverse-charge-reference",
            label: "Reverse charge reference",
            control_type: "text-area"
          },
          {
            name: "self-billing-reference",
            label: "Self billing reference",
            hint: "Self billing reference on the invoice",
            control_type: "text-area"
          },
          { name: "series", control_type: "text-area" },
          {
            name: "ship-from-address",
            label: "Ship from address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "ship-to-address",
            label: "Ship to address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "shipping-amount",
            label: "Shipping amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "status", hint: "Invoice Status" },
          {
            name: "supplier",
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              sticky: true,
              control_type: "select",
              pick_list: "suppliers",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier-created",
            label: "Supplier created",
            hint: "Supplier created indicator for invoice",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "supplier-note",
            label: "Supplier note",
            hint: "Note provided by supplier",
            control_type: "text-area",
            sticky: true
          },
          {
            name: "supplier-remit-to",
            label: "Supplier remit to",
            hint: "Supplier provided remit to address",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "supplier-tax-registration",
            label: "Supplier tax registration",
            control_type: "select",
            pick_list: "tax_registrations",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "supplier-tax-registration",
              label: "Supplier tax registration ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "supplier-total",
            label: "Supplier total",
            control_type: "number",
            type: "number"
          },
          {
            name: "taggings",
            type: "array",
            of: "object",
            properties: [
              {
                name: "active",
                hint: "Tagging active state",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "description",
                hint: "Description on the Tag on an Object (Tags on " \
                  "different objects can have different descriptions)"
              },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing taggings.",
                type: "integer"
              },
              {
                name: "tag",
                type: "object",
                properties: [
                  { name: "name" },
                  {
                    name: "system-tag",
                    label: "System tag",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                      "if you want to update existing tag.",
                    type: "integer"
                  }
                ]
              }
            ]
          },
          {
            name: "tags",
            type: "array",
            of: "object",
            properties: [
              { name: "name" },
              {
                name: "system-tag",
                label: "System tag",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing tag.",
                type: "integer"
              }
            ]
          },
          {
            name: "tax-amount",
            label: "Tax amount",
            hint: "Tax amount (not used if tax is provided at line level)",
            control_type: "number",
            type: "number"
          },
          {
            name: "tax-amount-engine",
            label: "Tax amount engine",
            hint: "Tax amount calculated by either Coupa Native or " \
              "External Tax Engine based on configuration",
            control_type: "number",
            type: "number"
          },
          {
            name: "tax-code",
            label: "Tax code",
            hint: "This field is not used if tax is provided at line level",
            type: "object",
            properties: [{
              name: "id",
              label: "Tax code",
              control_type: "select",
              pick_list: "tax_codes",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Tax code ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "tax-lines",
            label: "Tax lines",
            hint: "Line tax code (not used if tax is provided at header level)",
            type: "array",
            of: "object",
            properties: [
              { name: "amount", control_type: "number", type: "number" },
              {
                name: "base",
                hint: "Base to Calculate Withholding",
                control_type: "number",
                type: "number"
              },
              {
                name: "basis",
                hint: "Supplier Withholding Base Suggestion",
                control_type: "number",
                type: "number"
              },
              { name: "code-id", label: "Code ID", type: "integer" },
              { name: "description", hint: "Tax Reference" },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing tax line.",
                type: "integer"
              },
              { name: "rate", control_type: "number", type: "number" },
              {
                name: "supplier-rate",
                label: "Supplier rate",
                hint: "Supplier Withholding Rate Suggestion",
                control_type: "number",
                type: "number"
              },
              {
                name: "tax-code",
                label: "Tax code",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Tax code",
                  control_type: "select",
                  pick_list: "tax_codes",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Tax code ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "tax-rate",
                label: "Tax rate",
                type: "object",
                properties: [
                  {
                    name: "active",
                    hint: "Tax rate is enabled or disabled",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "country",
                    hint: "Country where the tax code is applied"
                  },
                  {
                    name: "effective-date",
                    label: "Effective date",
                    hint: "Date when tax rate is become active",
                    type: "timestamp"
                  },
                  {
                    name: "exempt",
                    hint: "Whether Tax Rate is exempt or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "expiration-date",
                    label: "Expiration date",
                    hint: "Date when tax rate is expiring",
                    type: "timestamp"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                      "if you want to update existing tax rate.",
                    type: "integer"
                  },
                  {
                    name: "percentage",
                    hint: "Tax Rate percentage",
                    control_type: "number",
                    type: "number"
                  },
                  {
                    name: "reverse-charge",
                    label: "Reverse charge",
                    hint: "Whether Tax Rate is Reverse Charge or not",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "tax-rate-type",
                    label: "Tax rate type",
                    type: "object",
                    properties: [
                      {
                        name: "country",
                        hint: "Country where the tax rate type is applied"
                      },
                      {
                        name: "description",
                        hint: "Description of the tax rate type"
                      },
                      {
                        name: "id",
                        hint: "Coupa unique identifier. Use this ID only " \
                          "if you want to update existing tax rate type.",
                        type: "integer"
                      }
                    ]
                  }
                ]
              },
              {
                name: "tax-rate-type",
                label: "Tax rate type",
                type: "object",
                properties: [
                  {
                    name: "country",
                    hint: "Country where the tax rate type is applied"
                  },
                  {
                    name: "description",
                    hint: "Description of the tax rate type"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                      "if you want to update existing tax rate type.",
                    type: "integer"
                  }
                ]
              },
              {
                name: "taxable-amount",
                label: "Taxable amount",
                hint: "Amount",
                control_type: "number",
                type: "number"
              },
              {
                name: "type",
                hint: "WithholdingTaxLine or TaxLine",
                control_type: "text-area"
              },
              {
                name: "withholding-amount",
                label: "Withholding amount",
                control_type: "number",
                type: "number"
              }
            ]
          },
          {
            name: "tax-rate",
            label: "Tax rate",
            type: "object",
            properties: [
              {
                name: "active",
                hint: "Tax rate is enabled or disabled",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "country",
                hint: "Country where the tax code is applied"
              },
              {
                name: "effective-date",
                label: "Effective date",
                hint: "Date when tax rate is become active",
                type: "timestamp"
              },
              {
                name: "exempt",
                hint: "Whether Tax Rate is exempt or not",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "expiration-date",
                label: "Expiration date",
                hint: "Date when tax rate is expiring",
                type: "timestamp"
              },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing tax rate.",
                type: "integer"
              },
              {
                name: "percentage",
                hint: "Tax Rate percentage",
                control_type: "number",
                type: "number"
              },
              {
                name: "reverse-charge",
                label: "Reverse charge",
                hint: "Whether Tax Rate is Reverse Charge or not",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "tax-rate-type",
                label: "Tax rate type",
                type: "object",
                properties: [
                  {
                    name: "country",
                    hint: "Country where the tax rate type is applied",
                    type: "object",
                    properties: [{
                      name: "code",
                      label: "Country",
                      control_type: "select",
                      pick_list: "countries",
                      toggle_hint: "Select from list",
                      toggle_field: {
                        name: "code",
                        label: "Country code",
                        toggle_hint: "Use custom value",
                        control_type: "text",
                        type: "string"
                      }
                    }]
                  },
                  {
                    name: "description",
                    hint: "Description of the tax rate type"
                  },
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                      "if you want to update existing tax rate type.",
                    type: "integer"
                  }
                ]
              }
            ]
          },
          {
            name: "taxes-in-origin-country-currency",
            label: "Taxes in origin country currency",
            hint: "Local Currency Tax",
            control_type: "number",
            type: "number"
          },
          {
            name: "tolerance-failures",
            label: "Tolerance failures",
            control_type: "text-area"
          },
          {
            name: "total-with-taxes",
            label: "Total with taxes",
            control_type: "number",
            type: "number"
          },
          {
            name: "type-of-receipt",
            label: "Type of receipt",
            control_type: "text-area"
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-of-invoice",
            label: "Use of invoice",
            control_type: "text-area"
          }
        ]
        standard_field_names = invoice_fields.pluck(:name)
        sample_record = get("/api/invoices",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = invoice_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    item: {
      fields: lambda do |_connection, _config_fields|
        item_fields = [
          {
            name: "active",
            hint: "Is the item given for this supplier & contract active? " \
             "and if NOT then DELETE",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "commodity",
            type: "object",
            properties: [{
              name: "id",
              label: "Commodity",
              control_type: "select",
              pick_list: "commodities",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Commodity ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "connect-item-id",
            label: "Connect item id",
            type: "integer"
          },
          {
            name: "consumption-quantity",
            label: "Consumption quantity",
            type: "integer"
          },
          {
            name: "consumption-uom",
            label: "Consumption uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
             "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "description", hint: "Item desciption" },
          { name: "id", hint: "Coupa unique identifier", type: "integer" },
          {
            name: "image-url",
            label: "Image url",
            hint: "URL for item image (will be copied into Coupa on item " \
             "create/update)",
            control_type: "url"
          },
          {
            name: "item-number",
            label: "Item number",
            hint: "Unique item number",
            sticky: true
          },
          { name: "name", hint: "Item name", sticky: true },
          {
            name: "net-weight",
            label: "Net weight",
            control_type: "number",
            type: "number"
          },
          {
            name: "net-weight-uom",
            label: "Net weight uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "pack-qty",
            label: "Pack qty",
            control_type: "number",
            type: "number"
          },
          {
            name: "pack-uom",
            label: "Pack uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "pack-weight",
            label: "Pack weight",
            control_type: "number",
            type: "number"
          },
          {
            name: "receive-catch-weight",
            label: "Receive catch weight",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "receiving-form",
            label: "Receiving form",
            type: "object",
            properties: [{ name: "id" }]
          },
          {
            name: "reorder-alerts",
            label: "Reorder alerts",
            type: "array",
            of: "object",
            properties: [{ name: "id" }]
          },
          { name: "reorder-point", label: "Reorder point" },
          {
            name: "storage-quantity",
            label: "Storage quantity",
            type: "integer"
          },
          {
            name: "storage-uom",
            label: "Storage uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "uom",
            label: "Unit of measure",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              sticky: true,
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
             "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-pack-weight",
            label: "Use pack weight",
            control_type: "checkbox",
            type: "boolean"
          }
        ]
        standard_field_names = item_fields.pluck(:name)
        sample_record = get("/api/items",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = item_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    item_get: {
      fields: lambda do |_connection, _config_fields|
        item_fields = [
          {
            name: "active",
            hint: "Is the item given for this supplier & contract active? " \
             "and if NOT then DELETE",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "commodity",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "connect-item-id",
            label: "Connect item id",
            type: "integer"
          },
          {
            name: "consumption-quantity",
            label: "Consumption quantity",
            type: "integer"
          },
          {
            name: "consumption-uom",
            label: "Consumption uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
             "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "description", hint: "Item desciption" },
          { name: "id", hint: "Coupa unique identifier", type: "integer" },
          {
            name: "image-url",
            label: "Image url",
            hint: "URL for item image (will be copied into Coupa on item " \
             "create/update)",
            control_type: "url"
          },
          {
            name: "item-number",
            label: "Item number",
            hint: "Unique item number",
            sticky: true
          },
          { name: "name", hint: "Item name", sticky: true },
          {
            name: "net-weight",
            label: "Net weight",
            control_type: "number",
            type: "number"
          },
          {
            name: "net-weight-uom",
            label: "Net weight uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "pack-qty",
            label: "Pack qty",
            control_type: "number",
            type: "number"
          },
          {
            name: "pack-uom",
            label: "Pack uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "pack-weight",
            label: "Pack weight",
            control_type: "number",
            type: "number"
          },
          {
            name: "receive-catch-weight",
            label: "Receive catch weight",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "receiving-form",
            label: "Receiving form",
            type: "object",
            properties: [{ name: "id" }]
          },
          {
            name: "reorder-alerts",
            label: "Reorder alerts",
            type: "array",
            of: "object",
            properties: [{ name: "id" }]
          },
          { name: "reorder-point", label: "Reorder point" },
          {
            name: "storage-quantity",
            label: "Storage quantity",
            type: "integer"
          },
          {
            name: "storage-uom",
            label: "Storage uom",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "uom",
            label: "Unit of measure",
            type: "object",
            properties: [{
              name: "id",
              label: "Unit of measure",
              sticky: true,
              control_type: "select",
              pick_list: "uoms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Unit of measure ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
             "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "use-pack-weight",
            label: "Use pack weight",
            control_type: "checkbox",
            type: "boolean"
          }
        ]
        standard_field_names = item_fields.pluck(:name)
        sample_record = get("/api/items",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = item_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    lookup_value_create: {
      fields: lambda do |_connection, _config_fields|
        lookup_value_fields = [
          {
            name: "account-type",
            label: "Account type",
            type: "object",
            properties: [{
              name: "id",
              label: "Account type",
              control_type: "select",
              pick_list: "account_types",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account type ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "active",
            hint: "A yes will make it active and available to users. " \
              "A no will inactivate the account making it no longer " \
              "available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "depth", type: "integer" },
          {
            name: "description",
            hint: "Description of the lookup value",
            sticky: true
          },
          {
            name: "external-ref-code",
            label: "External ref code",
            hint: "Used for identification of individual Lookup " \
            "Value when using hierarchical lookups. This field " \
            "is a concatenation of the external ref num fields " \
            "starting with the root LookupValue. It does not get " \
            "set by the integration, but is used to identify an " \
            "existing lookup to update."
          },
          {
            name: "external-ref-num",
            label: "External ref num",
            hint: "Actual account value when used in accounting"
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            type: "integer",
            sticky: true
          },
          {
            name: "is-default",
            label: "Is default",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "lookup",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Lookup",
              optional: false,
              control_type: "select",
              pick_list: "lookups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Lookup ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "lookup-id", label: "Lookup ID", type: "integer" },
          { name: "name", hint: "Name of the lookup value", sticky: true },
          { name: "parent", hint: "External ref code of parent element" },
          { name: "parent-id", label: "Parent ID", type: "integer" },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = lookup_value_fields.pluck(:name)
        sample_record = get("/api/lookup_values",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = lookup_value_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    lookup_value_get: {
      fields: lambda do |_connection, _config_fields|
        lookup_value_fields = [
          {
            name: "account-type",
            label: "Account type",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "active",
            hint: "A yes will make it active and available to users. " \
              "A no will inactivate the account making it no longer " \
              "available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "depth", type: "integer" },
          {
            name: "description",
            hint: "Description of the lookup value",
            sticky: true
          },
          {
            name: "external-ref-code",
            label: "External ref code",
            hint: "Used for identification of individual Lookup " \
            "Value when using hierarchical lookups. This field " \
            "is a concatenation of the external ref num fields " \
            "starting with the root LookupValue. It does not get " \
            "set by the integration, but is used to identify an " \
            "existing lookup to update."
          },
          {
            name: "external-ref-num",
            label: "External ref num",
            hint: "Actual account value when used in accounting"
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            type: "integer",
            sticky: true
          },
          {
            name: "is-default",
            label: "Is default",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "lookup",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "lookup-id", label: "Lookup ID", type: "integer" },
          { name: "name", hint: "Name of the lookup value", sticky: true },
          { name: "parent", hint: "External ref code of parent element" },
          { name: "parent-id", label: "Parent ID", type: "integer" },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = lookup_value_fields.pluck(:name)
        sample_record = get("/api/lookup_values",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = lookup_value_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    lookup_value_update: {
      fields: lambda do |_connection, _config_fields|
        lookup_value_fields = [
          {
            name: "account-type",
            label: "Account type",
            type: "object",
            properties: [{
              name: "id",
              label: "Account type",
              control_type: "select",
              pick_list: "account_types",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account type ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "active",
            hint: "A yes will make it active and available to users. " \
              "A no will inactivate the account making it no longer " \
              "available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "depth", type: "integer" },
          {
            name: "description",
            hint: "Description of the lookup value",
            sticky: true
          },
          {
            name: "external-ref-code",
            label: "External ref code",
            hint: "Used for identification of individual Lookup " \
            "Value when using hierarchical lookups. This field " \
            "is a concatenation of the external ref num fields " \
            "starting with the root LookupValue. It does not get " \
            "set by the integration, but is used to identify an " \
            "existing lookup to update."
          },
          {
            name: "external-ref-num",
            label: "External ref num",
            hint: "Actual account value when used in accounting"
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            type: "integer",
            sticky: true
          },
          {
            name: "is-default",
            label: "Is default",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "lookup",
            type: "object",
            properties: [{
              name: "id",
              label: "Lookup",
              sticky: true,
              control_type: "select",
              pick_list: "lookups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Lookup ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "lookup-id", label: "Lookup ID", type: "integer" },
          { name: "name", hint: "Name of the lookup value", sticky: true },
          { name: "parent", hint: "External ref code of parent element" },
          { name: "parent-id", label: "Parent ID", type: "integer" },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = lookup_value_fields.pluck(:name)
        sample_record = get("/api/lookup_values",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = lookup_value_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    purchase_order_create: {
      fields: lambda do |_connection, _config_fields|
        purchase_order_fields = [
          {
            name: "acknowledged-at",
            label: "Acknowledged at",
            type: "timestamp"
          },
          {
            name: "acknowledged-flag",
            label: "Acknowledged flag",
            hint: "Has PO been acknowledged by Supplier?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "coupa-accelerate-status",
            label: "Coupa accelerate status",
            hint: "Status indicating whether the invoice has " \
              "discount payment terms via Coupa Accelerate",
            control_type: "select",
            pick_list: "accelerate_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "coupa-accelerate-status",
              label: "Coupa accelerate status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              optional: false,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa's Purchase Order ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "internal-revision",
            label: "Internal revision",
            hint: "Internal revision number - increases each time " \
              "a change is made to a PO whether that change is " \
              "internal or causes the PO to be resent to the supplier.",
            type: "integer"
          },
          {
            name: "invoice-stop",
            label: "Invoice stop",
            hint: "Invoice Stop flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported in " \
              "the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "order-lines",
            label: "Order lines",
            type: "array",
            of: "object",
            properties: [
              {
                name: "account",
                optional: false,
                type: "object",
                properties: [{
                  name: "id",
                  label: "Account",
                  optional: false,
                  control_type: "select",
                  pick_list: "accounts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Account ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "account-allocations", label: "Account allocations" },
              {
                name: "accounting-total",
                label: "Accounting total",
                control_type: "number",
                type: "number"
              },
              {
                name: "accounting-total-currency",
                label: "Accounting total currency",
                control_type: "select",
                pick_list: "currencies",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "accounting-total-currency",
                  label: "Accounting total currency",
                  toggle_hint: "Use custom value",
                  control_type: "number",
                  type: "integer"
                }
              },
              {
                name: "asset-tags",
                label: "Asset tags",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "inventory-balance-id",
                    label: "Inventory balance ID",
                    type: "integer"
                  },
                  { name: "note" },
                  {
                    name: "order-line-id",
                    label: "Order line ID",
                    type: "integer"
                  },
                  { name: "owner" },
                  {
                    name: "received",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "requisition-line-id",
                    label: "Requisition line ID",
                    type: "integer"
                  },
                  { name: "serial-number", label: "Serial number" },
                  { name: "tag" },
                ]
              },
              {
                name: "attachments",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              },
              {
                name: "commodity",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Commodity",
                  control_type: "select",
                  pick_list: "commodities",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Commodity ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "contract",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Contract",
                  control_type: "select",
                  pick_list: "contracts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Contract ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "currency",
                optional: false,
                type: "object",
                properties: [{
                  name: "id",
                  label: "Currency",
                  optional: false,
                  control_type: "select",
                  pick_list: "currencies",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Currency ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "Department",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Department",
                  control_type: "select",
                  pick_list: "departments",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Department ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "description", optional: false },
              {
                name: "form-response",
                label: "Form response",
                type: "array",
                of: "object",
                properties: [
                  { name: "prompt" },
                  {
                    name: "is_internal",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "responses",
                    type: "array",
                    properties: [{ name: "id", type: "integer" }]
                  }
                ]
              },
              { name: "invoiced", control_type: "number", type: "number" },
              {
                name: "item",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Item",
                  control_type: "select",
                  pick_list: "items",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Item ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "line-num", label: "Line num" },
              {
                name: "match-type",
                label: "Match type",
                control_type: "select",
                pick_list: "match_types",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "match-type",
                  label: "Match type",
                  toggle_hint: "Use custom value",
                  control_type: "text",
                  type: "string"
                }
              },
              {
                name: "need-by-date",
                label: "Need by date",
                type: "timestamp"
              },
              {
                name: "order-header-id",
                label: "Order header ID",
                type: "integer"
              },
              {
                name: "period",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Period",
                  control_type: "select",
                  pick_list: "periods",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Period ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "price",
                optional: false,
                control_type: "number",
                type: "number"
              },
              { name: "quantity", control_type: "number", type: "number" },
              {
                name: "receipt-required",
                label: "Receipt required",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "received",
                hint: "Quantity/Amount received",
                control_type: "number",
                type: "number"
              },
              {
                name: "receiving-warehouse",
                label: "Receiving warehouse",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Warehouse",
                  control_type: "select",
                  pick_list: "warehouses",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Warehouse ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "reporting-total",
                label: "Reporting total",
                control_type: "number",
                type: "number"
              },
              {
                name: "savings-pct",
                label: "Savings pct",
                control_type: "number",
                type: "number"
              },
              { name: "source-part-num", label: "Source part number" },
              { name: "status", hint: "Transaction status" },
              {
                name: "sub-line-num",
                label: "Sub line number",
                type: "integer"
              },
              { name: "supp-aux-part-num", label: "Supp aux part number" },
              {
                name: "supplier",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Supplier",
                  control_type: "select",
                  pick_list: "suppliers",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Supplier ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "supplier-order-number", label: "Supplier order number" },
              { name: "total", control_type: "number", type: "number" },
              { name: "type" },
              {
                name: "uom",
                label: "Unit of measure",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Unit of measure",
                  control_type: "select",
                  pick_list: "uoms",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Unit of measure ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "version", type: "integer" }
            ]
          },
          {
            name: "payment-method",
            label: "Payment method",
            control_type: "select",
            pick_list: "payment_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-method",
              label: "Payment method",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            type: "object",
            properties: [{
              name: "id",
              label: "Payment term",
              control_type: "select",
              pick_list: "payment_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Payment term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "pcard", label: "PCard" },
          { name: "po-number", label: "PO number" },
          {
            name: "price-hidden",
            label: "Price hidden",
            hint: "Hide price from supplier. True or false",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "requester",
            hint: "Requesting account's login",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "requisition-header",
            label: "Requisition header",
            type: "object",
            properties: [{
              name: "id",
              label: "Requisition",
              control_type: "select",
              pick_list: "requisitions",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Requisition ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "ship-to-address",
            label: "Ship to address",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              optional: false,
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "ship-to-attention",
            label: "Ship to attention",
            control_type: "text-area"
          },
          {
            name: "ship-to-user",
            label: "Ship to user",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              optional: false,
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "status", hint: "PO Status" },
          {
            name: "supplier",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              optional: false,
              control_type: "select",
              pick_list: "suppliers",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier-site",
            label: "Supplier site",
            optional: false,
            type: "object",
            properties: [{ name: "id", optional: false, type: "integer" }]
          },
          {
            name: "transmission-status",
            label: "Transmission status",
            control_type: "select",
            pick_list: "transmission_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "transmission-status",
              label: "Transmission status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "type",
            hint: "Type of Order",
            default: "ExternalOrderHeader",
            control_type: "select",
            pick_list: "order_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "Type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract owner",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract owner ID",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "version",
            hint: "PO supplier version number - increase each time " \
              "a PO is changed and triggers a resend to the supplier.",
            type: "integer"
          }
        ]
        standard_field_names = purchase_order_fields.pluck(:name)
        sample_record = get("/api/purchase_orders",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = purchase_order_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    purchase_order_get: {
      fields: lambda do |_connection, _config_fields|
        purchase_order_fields = [
          {
            name: "acknowledged-at",
            label: "Acknowledged at",
            type: "timestamp"
          },
          {
            name: "acknowledged-flag",
            label: "Acknowledged flag",
            hint: "Has PO been acknowledged by Supplier?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "coupa-accelerate-status",
            label: "Coupa accelerate status",
            hint: "Status indicating whether the invoice has " \
              "discount payment terms via Coupa Accelerate",
            control_type: "select",
            pick_list: "accelerate_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "coupa-accelerate-status",
              label: "Coupa accelerate status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa's Purchase Order ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "internal-revision",
            label: "Internal revision",
            hint: "Internal revision number - increases each time " \
              "a change is made to a PO whether that change is " \
              "internal or causes the PO to be resent to the supplier.",
            type: "integer"
          },
          {
            name: "invoice-stop",
            label: "Invoice stop",
            hint: "Invoice Stop flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "order-lines",
            label: "Order lines",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "payment-method",
            label: "Payment method",
            control_type: "select",
            pick_list: "payment_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-method",
              label: "Payment method",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "pcard", label: "PCard" },
          { name: "po-number", label: "PO number", sticky: true },
          {
            name: "price-hidden",
            label: "Price hidden",
            hint: "Hide price from supplier. True or false",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "requester",
            hint: "Requesting account's login",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "requisition-header",
            label: "Requisition header",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "ship-to-address",
            label: "Ship to address",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "ship-to-attention",
            label: "Ship to attention",
            control_type: "text-area"
          },
          {
            name: "ship-to-user",
            label: "Ship to user",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "status", hint: "PO Status" },
          {
            name: "supplier",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "number" }
            ]
          },
          {
            name: "supplier-sites",
            label: "Supplier sites",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "transmission-status",
            label: "Transmission status",
            control_type: "select",
            pick_list: "transmission_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "transmission-status",
              label: "Transmission status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "type",
            hint: "Type of Order",
            control_type: "select",
            pick_list: "order_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "Type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "version",
            hint: "PO supplier version number - increase each time " \
              "a PO is changed and triggers a resend to the supplier.",
            type: "integer"
          }
        ]
        standard_field_names = purchase_order_fields.pluck(:name)
        sample_record = get("/api/purchase_orders",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = purchase_order_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    purchase_order_update: {
      fields: lambda do |_connection, _config_fields|
        purchase_order_fields = [
          {
            name: "acknowledged-at",
            label: "Acknowledged at",
            type: "timestamp"
          },
          {
            name: "acknowledged-flag",
            label: "Acknowledged flag",
            hint: "Has PO been acknowledged by Supplier?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "coupa-accelerate-status",
            label: "Coupa accelerate status",
            hint: "Status indicating whether the invoice has " \
              "discount payment terms via Coupa Accelerate",
            control_type: "select",
            pick_list: "accelerate_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "coupa-accelerate-status",
              label: "Coupa accelerate status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "current-integration-history-records",
            label: "Current integration history records",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "exported",
            hint: "Indicates if transaction has been exported",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa's Purchase Order ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "internal-revision",
            label: "Internal revision",
            hint: "Internal revision number - increases each time " \
              "a change is made to a PO whether that change is " \
              "internal or causes the PO to be resent to the supplier.",
            type: "integer"
          },
          {
            name: "invoice-stop",
            label: "Invoice stop",
            hint: "Invoice Stop flag",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Date and time transaction was last exported in " \
              "the format YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "order-lines",
            label: "Order lines",
            sticky: true,
            type: "array",
            of: "object",
            properties: [
              {
                name: "account",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Account",
                  control_type: "select",
                  pick_list: "accounts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Account ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "account-allocations", label: "Account allocations" },
              {
                name: "accounting-total",
                label: "Accounting total",
                control_type: "number",
                type: "number"
              },
              {
                name: "accounting-total-currency",
                label: "Accounting total currency",
                control_type: "select",
                pick_list: "currencies",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "accounting-total-currency",
                  label: "Accounting total currency",
                  toggle_hint: "Use custom value",
                  control_type: "number",
                  type: "integer"
                }
              },
              {
                name: "asset-tags",
                label: "Asset tags",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                      "if you want to update existing asset tag.",
                    type: "integer"
                  },
                  {
                    name: "inventory-balance-id",
                    label: "Inventory balance ID",
                    type: "integer"
                  },
                  { name: "note" },
                  {
                    name: "order-line-id",
                    label: "Order line ID",
                    type: "integer"
                  },
                  { name: "owner" },
                  {
                    name: "received",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "requisition-line-id",
                    label: "Requisition line ID",
                    type: "integer"
                  },
                  { name: "serial-number", label: "Serial number" },
                  { name: "tag" },
                ]
              },
              {
                name: "attachments",
                type: "array",
                of: "object",
                properties: [{ name: "id", type: "integer" }]
              },
              {
                name: "commodity",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Commodity",
                  control_type: "select",
                  pick_list: "commodities",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Commodity ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "contract",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Contract",
                  control_type: "select",
                  pick_list: "contracts",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Contract ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "currency",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Currency",
                  control_type: "select",
                  pick_list: "currencies",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Currency ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "department",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Department",
                  control_type: "select",
                  pick_list: "departments",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Department ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "description" },
              {
                name: "form-response",
                label: "Form response",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "id",
                    hint: "Coupa unique identifier. Use this ID only " \
                    "if you want to update existing form response.",
                    sticky: true,
                    type: "integer"
                  },
                  { name: "prompt" },
                  {
                    name: "is_internal",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "responses",
                    type: "array",
                    properties: [{ name: "id", type: "integer" }]
                  }
                ]
              },
              {
                name: "id",
                hint: "Coupa unique identifier. Use this ID only " \
                  "if you want to update existing order line.",
                sticky: true,
                type: "integer"
              },
              { name: "invoiced", control_type: "number", type: "number" },
              {
                name: "item",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Item",
                  control_type: "select",
                  pick_list: "items",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Item ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "line-num", label: "Line num" },
              {
                name: "match-type",
                label: "Match type",
                control_type: "select",
                pick_list: "match_types",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "match-type",
                  label: "Match type",
                  toggle_hint: "Use custom value",
                  control_type: "text",
                  type: "string"
                }
              },
              {
                name: "need-by-date",
                label: "Need by date",
                type: "timestamp"
              },
              {
                name: "order-header-id",
                label: "Order header ID",
                type: "integer"
              },
              {
                name: "period",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Period",
                  control_type: "select",
                  pick_list: "periods",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Period ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "price",
                control_type: "number",
                type: "number"
              },
              { name: "quantity", control_type: "number", type: "number" },
              {
                name: "receipt-required",
                label: "Receipt required",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "received",
                hint: "Quantity/Amount received",
                control_type: "number",
                type: "number"
              },
              {
                name: "receiving-warehouse",
                label: "Receiving warehouse",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Warehouse",
                  control_type: "select",
                  pick_list: "warehouses",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Warehouse ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              {
                name: "reporting-total",
                label: "Reporting total",
                control_type: "number",
                type: "number"
              },
              {
                name: "savings-pct",
                label: "Savings pct",
                control_type: "number",
                type: "number"
              },
              { name: "source-part-num", label: "Source part number" },
              { name: "status", hint: "Transaction status", sticky: true },
              {
                name: "sub-line-num",
                label: "Sub line number",
                type: "integer"
              },
              { name: "supp-aux-part-num", label: "Supp aux part number" },
              {
                name: "supplier",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Supplier",
                  control_type: "select",
                  pick_list: "suppliers",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Supplier ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "supplier-order-number", label: "Supplier order number" },
              { name: "total", control_type: "number", type: "number" },
              { name: "type", sticky: true },
              {
                name: "uom",
                label: "Unit of measure",
                type: "object",
                properties: [{
                  name: "id",
                  label: "Unit of measure",
                  control_type: "select",
                  pick_list: "uoms",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "id",
                    label: "Unit of measure ID",
                    toggle_hint: "Use custom value",
                    control_type: "number",
                    type: "integer"
                  }
                }]
              },
              { name: "version", type: "integer" }
            ]
          },
          {
            name: "payment-method",
            label: "Payment method",
            control_type: "select",
            pick_list: "payment_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-method",
              label: "Payment method",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            type: "object",
            properties: [{
              name: "id",
              label: "Payment term",
              control_type: "select",
              pick_list: "payment_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Payment term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "pcard", label: "PCard" },
          { name: "po-number", label: "PO number", sticky: true },
          {
            name: "price-hidden",
            label: "Price hidden",
            hint: "Hide price from supplier. True or false",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "requester",
            hint: "Requesting account's login",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "requisition-header",
            label: "Requisition header",
            type: "object",
            properties: [{
              name: "id",
              label: "Requisition",
              control_type: "select",
              pick_list: "requisitions",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Requisition ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "ship-to-address",
            label: "Ship to address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              opitonal: false,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "ship-to-attention",
            label: "Ship to attention",
            control_type: "text-area"
          },
          {
            name: "ship-to-user",
            label: "Ship to user",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              opitonal: false,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "status", hint: "PO Status" },
          {
            name: "supplier",
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              control_type: "select",
              pick_list: "suppliers",
              opitonal: false,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "supplier-sites",
            label: "Supplier sites",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "transmission-status",
            label: "Transmission status",
            control_type: "select",
            pick_list: "transmission_statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "transmission-status",
              label: "Transmission status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "type",
            hint: "Type of Order",
            default: "ExternalOrderHeader",
            control_type: "select",
            pick_list: "order_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "Type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract owner",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract owner ID",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "version",
            hint: "PO supplier version number - increase each time " \
              "a PO is changed and triggers a resend to the supplier.",
            type: "integer"
          }
        ]
        standard_field_names = purchase_order_fields.pluck(:name)
        sample_record = get("/api/purchase_orders",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = purchase_order_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    purchase_order_line: {
      fields: lambda do |_connection, _config_fields|
        purchase_order_line_fields = [
          {
            name: "account",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "account-allocations",
            label: "Account allocations",
            type: "array",
            of: "object",
            properties: [
              { name: "amount", control_type: "number", type: "number" },
              {
                name: "created-at",
                label: "Created at",
                hint: "Automatically created by Coupa in the format " \
                  "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "created-by",
                label: "Created by",
                hint: "User who created"
              },
              { name: "id", hint: "Coupa unique identifier", type: "integer" },
              { name: "pct", control_type: "number", type: "number" },
              { name: "period" },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format "\
                 "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                hint: "User who updated"
              }
            ]
          },
          {
            name: "accounting-total",
            label: "Accounting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "accounting-total-currency",
            label: "Accounting total currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "asset-tags",
            label: "Asset tags",
            type: "array",
            of: "object",
            properties: [
              {
                name: "created-at",
                label: "Created at",
                hint: "Automatically created by Coupa in the format " \
                "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "created-by",
                label: "Created by",
                hint: "User who created"
              },
              { name: "id", hint: "Coupa unique identifier", type: "integer" },
              {
                name: "inventory-balance-id",
                label: "Inventory balance ID",
                type: "integer"
              },
              { name: "note" },
              {
                name: "order-line-id",
                label: "Order line ID",
                type: "integer"
              },
              { name: "owner" },
              { name: "received", control_type: "checkbox", type: "boolean" },
              {
                name: "requisition-line-id",
                label: "Requisition line ID",
                type: "integer"
              },
              { name: "serial-number", label: "Serial number" },
              { name: "tag" },
              {
                name: "updated-at",
                label: "Updated at",
                hint: "Automatically created by Coupa in the format " \
                "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
                type: "timestamp"
              },
              {
                name: "updated-by",
                label: "Updated by",
                hint: "User who updated"
              }
            ]
          },
          {
            name: "attachments",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "commodity",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "contract",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "department",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "description", control_type: "text-area" },
          {
            name: "extra-line-attribute",
            label: "Extra line attribute",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "form-response",
            label: "Form response",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              {
                name: "is_internal",
                control_type: "checkbox",
                type: "boolean"
              },
              { name: "prompt" },
              {
                name: "responses",
                type: "array",
                properties: [{ name: "id", type: "integer" }]
              }
            ]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "invoice-stop",
            label: "Invoice stop",
            hint: "Invoice Stop flag",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "invoiced", control_type: "number", type: "number" },
          {
            name: "item",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "item-number" },
              { name: "name" }
            ]
          },
          { name: "line-num", label: "Line num" },
          {
            name: "match-type",
            label: "Match type",
            control_type: "select",
            pick_list: "match_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "match-type",
              label: "Match type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "need-by-date", label: "Need by date", type: "timestamp" },
          {
            name: "order-header-id",
            label: "Order header ID",
            type: "integer"
          },
          {
            name: "order-header-number",
            label: "Order header number",
            hint: "PO Number"
          },
          {
            name: "period",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "price", control_type: "number", type: "number" },
          { name: "quantity", control_type: "number", type: "number" },
          {
            name: "receipt-required",
            label: "Receipt required",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "received",
            hint: "Quantity/Amount received",
            control_type: "number",
            type: "number"
          },
          {
            name: "receiving-warehouse",
            label: "Receiving warehouse",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "reporting-total",
            label: "Reporting total",
            control_type: "number",
            type: "number"
          },
          {
            name: "requester",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "rfq-form-response",
            label: "Rfq form response",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              {
                name: "is_internal",
                control_type: "checkbox",
                type: "boolean"
              },
              { name: "prompt" },
              {
                name: "responses",
                type: "array",
                properties: [{ name: "id", type: "integer" }]
              }
            ]
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            control_type: "number",
            type: "number"
          },
          {
            name: "service-type",
            label: "Service type",
            hint: "Specifies the type of service. Field only available when " \
              "services procurement is enabled in the instance.",
            control_type: "select",
            pick_list: "service_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "service-type",
              label: "Service type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "source-part-num", label: "Source part number" },
          { name: "status", hint: "Transaction status", sticky: true },
          { name: "sub-line-num", label: "Sub line number", type: "integer" },
          { name: "supp-aux-part-num", label: "Supp aux part number" },
          {
            name: "supplier",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "number" }
            ]
          },
          { name: "supplier-order-number", label: "Supplier order number" },
          {
            name: "supplier-site-id",
            label: "Supplier site ID",
            type: "integer"
          },
          { name: "total", control_type: "number", type: "number" },
          { name: "type", sticky: true },
          {
            name: "uom",
            label: "Unit of measure",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" },
              { name: "name" }
            ]
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            hint: "User who updated",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "version", type: "integer" }
        ]
        standard_field_names = purchase_order_line_fields.pluck(:name)
        sample_record = get("/api/purchase_order_lines",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = purchase_order_line_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    remit_to_address_create: {
      fields: lambda do |_connection, config_fields|
        address_fields = [
          {
            name: "active",
            hint: "A yes value will make it active and available " \
              "to users. A no value will make the address inactive " \
              "making it no longer available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "city" },
          {
            name: "country",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Country",
              optional: false,
              control_type: "select",
              pick_list: "all_countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Country ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "created_at", label: "Created at", type: "timestamp" },
          {
            name: "created_by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          { name: "local_tax_number", label: "Local tax number" },
          { name: "location_code" },
          { name: "name", hint: "Address 'nickname'", sticky: true },
          { name: "postal_code", label: "Postal code" },
          {
            name: "remit_to_code",
            label: "Remit to code",
            hint: "Remit to code (if a supplier address)"
          },
          { name: "state", hint: "State abbreviation" },
          { name: "street1", hint: "Address line 1" },
          { name: "street2", hint: "Address line 2" },
          { name: "updated_at", label: "Updated at", type: "timestamp" },
          {
            name: "updated_by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "vat_country",
            type: "object",
            properties: [{
              name: "code",
              label: "Country",
              control_type: "select",
              pick_list: "countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "code",
                label: "Country code",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "vat_number" }
        ]
        standard_field_names = address_fields.pluck(:name)
        object_id = get("/api/#{config_fields['object']}",
                        return_object: "shallow",
                        limit: 1).dig(0, "id") || " "
        sample_record = get("/api/#{config_fields['object']}/#{object_id}" \
                           "/addresses",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = address_fields.concat(custom_fields || []).compact
      end
    },

    remit_to_address_get: {
      fields: lambda do |_connection, config_fields|
        address_fields = [
          {
            name: "active",
            hint: "A yes value will make it active and available " \
              "to users. A no value will make the address inactive " \
              "making it no longer available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "city" },
          { name: "country" },
          { name: "country_id" },
          { name: "created_at", label: "Created at", type: "timestamp" },
          { name: "created_by", label: "Created by", type: "integer" },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          { name: "local_tax_number", label: "Local tax number" },
          { name: "location_code" },
          { name: "name", hint: "Address 'nickname'", sticky: true },
          { name: "postal_code", label: "Postal code" },
          {
            name: "remit_to_code",
            label: "Remit to code",
            hint: "Remit to code (if a supplier address)"
          },
          { name: "state", hint: "State abbreviation" },
          { name: "street1", hint: "Address line 1" },
          { name: "street2", hint: "Address line 2" },
          { name: "updated_at", label: "Updated at", type: "timestamp" },
          { name: "updated_by", label: "Updated by", type: "integer" },
          { name: "vat_country_id" },
          { name: "vat_number" }
        ]
        standard_field_names = address_fields.pluck(:name)
        sample_record = get("/api/#{config_fields['object']}" \
                            "/#{config_fields['object_id']}/addresses",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = address_fields.concat(custom_fields || []).compact
      end
    },

    remit_to_address_update: {
      fields: lambda do |_connection, config_fields|
        address_fields = [
          {
            name: "active",
            hint: "A yes value will make it active and available " \
              "to users. A no value will make the address inactive " \
              "making it no longer available to users.",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "city" },
          {
            name: "country",
            type: "object",
            properties: [{
              name: "id",
              label: "Country",
              control_type: "select",
              pick_list: "all_countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Country ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "created_at", label: "Created at", type: "timestamp" },
          {
            name: "created_by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          { name: "local_tax_number", label: "Local tax number" },
          { name: "location_code" },
          { name: "name", hint: "Address 'nickname'", sticky: true },
          { name: "postal_code", label: "Postal code" },
          {
            name: "remit_to_code",
            label: "Remit to code",
            hint: "Remit to code (if a supplier address)"
          },
          { name: "state", hint: "State abbreviation" },
          { name: "street1", hint: "Address line 1" },
          { name: "street2", hint: "Address line 2" },
          { name: "updated_at", label: "Updated at", type: "timestamp" },
          {
            name: "updated_by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "vat_country",
            type: "object",
            properties: [{
              name: "code",
              label: "Country",
              control_type: "select",
              pick_list: "countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "code",
                label: "Country code",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "vat_number" }
        ]
        standard_field_names = address_fields.pluck(:name)
        object_id = get("/api/#{config_fields['object']}",
                        return_object: "shallow",
                        limit: 1).dig(0, "id") || " "
        sample_record = get("/api/#{config_fields['object']}/#{object_id}" \
                           "/addresses",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = address_fields.concat(custom_fields || []).compact
      end
    },

    supplier_create: {
      fields: lambda do |_connection, config_fields|
        supplier_fields = [
          { name: "account-number", label: "Account number" },
          {
            name: "allow-csp-access-without-two-factor",
            label: "Allow CSP access without two factor",
            hint: "Allows supplier to access customer's data " \
              "from CSP without 2FA",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-cxml-invoicing",
            label: "Allow cXML invoicing",
            hint: "Allow cXML invoicing for supplier",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-choose-billing-account",
            label: "Allow inv choose billing account",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-from-connect",
            label: "Allow inv from connect",
            hint: "If yes, then the supplier can create invoices " \
              "against their POs or Contracts in the CSP",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-no-backing-doc-from-connect",
            label: "Allow inv no backing doc from connect",
            hint: "If yes, then the supplier can create invoices " \
              "without a backing PO or contract in the CSP.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-unbacked-lines-from-connect",
            label: "Allow inv unbacked lines from connect",
            hint: "If yes, then the supplier can create unbacked " \
              "invoices without a backing PO or Contract in the CSP.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "business-groups",
            label: "Business groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Business groups",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Business group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "buyer-hold",
            label: "Buyer hold",
            hint: "Hold all POs for buyer review",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "commodity",
            hint: "Default commodity, selectable from drop down",
            type: "object",
            properties: [{
              name: "id",
              label: "Commodity",
              control_type: "select",
              pick_list: "commodities",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Commodity ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "corporate-url",
            label: "Corporate URL",
            control_type: "url",
            type: "sting"
          },
          {
            name: "coupa-connect-secret",
            label: "Coupa connect secret",
            control_type: "password"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "currency_id", type: "integer" },
          {
            name: "cxml-domain",
            label: "cXML domain",
            hint: "'From', our domain",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml"),
            control_type: "url",
            type: "string"
          },
          {
            name: "cxml-http-password",
            label: "cXML HTTP password",
            control_type: "password"
          },
          { name: "cxml-http-username", label: "cXML HTTP username" },
          {
            name: "cxml-identity",
            label: "cXML identity",
            hint: "'From', our identity",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml"),
            control_type: "text-area"
          },
          {
            name: "cxml-invoice-buyer-domain",
            label: "cXML invoice buyer domain",
            hint: "Buyer Domain for cXML Invoicing",
            control_type: "url"
          },
          {
            name: "cxml-invoice-buyer-identity",
            label: "cXML invoice buyer identity",
            hint: "Buyer Identity for cXML Invoicing"
          },
          {
            name: "cxml-invoice-secret",
            label: "cXML invoice secret",
            hint: "Secret Key for cXML Invoicing Authentication",
            control_type: "password"
          },
          {
            name: "cxml-invoice-supplier-domain",
            label: "cXML invoice supplier domain",
            hint: "Supplier Domain for cXML Invoicing"
          },
          {
            name: "cxml-invoice-supplier-identity",
            label: "cXML invoice supplier identity",
            hint: "Supplier Identity for cXML Invoicing"
          },
          {
            name: "cxml-protocol",
            label: "cXML protocol",
            hint: "Transmission protocol",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml"),
            control_type: "text-area"
          },
          {
            name: "cxml-secret",
            label: "cXML secret",
            hint: "Shared secret",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml"),
            control_type: "password"
          },
          { name: "cxml-ssl-version", label: "cXML SSL version" },
          {
            name: "cxml-supplier-domain",
            label: "cXML supplier domain",
            hint: "'To', supplier domain cXML supplier domain",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml"),
            control_type: "url"
          },
          {
            name: "cxml-supplier-identity",
            label: "cXML supplier identity",
            hint: "'To', supplier identity cXML supplier identity",
            optional: ![config_fields["po-method"],
                        config_fields["po-change-method"]].include?("cxml"),
            control_type: "text-area"
          },
          {
            name: "cxml-url",
            label: "cXML URL",
            hint: "URL where POs are sent if PO transmission is 'cxml'",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml"),
            control_type: "url"
          },
          {
            name: "disable-cert-verify",
            label: "Disable cert verify",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "display-name", label: "Display name" },
          { name: "duns", hint: "Supplier DUNS number" },
          {
            name: "enterprise",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "code" }
            ]
          },
          {
            name: "hold-invoices-for-ap-review",
            label: "Hold invoices for AP review",
            hint: "Prevent invoices from this supplier from being " \
              "approved before AP reviews them.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa Internal ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "invoice-emails",
            label: "Invoice emails",
            hint: "Registered email addresses allowed to send invoices " \
              "via email to invoices@yourhost.coupahost.com.",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "invoice-matching-level",
            label: "Invoice matching level",
            default: "2-way",
            control_type: "select",
            pick_list: "invoice_matching_levels",
            sticky: true,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "invoice-matching-level",
              label: "Invoice matching level",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "name", hint: "Supplier name" },
          { name: "number", hint: "Supplier number" },
          {
            name: "on-hold",
            label: "On hold",
            hint: "Supplier On Hold",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "online-store",
            label: "Online store",
            hint: "Supplier website",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "parent",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "payment-method",
            label: "Payment method",
            hint: "Default payment method",
            sticky: true,
            default: "invoice",
            control_type: "select",
            pick_list: "payment_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-method",
              label: "Payment method",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            type: "object",
            properties: [{
              name: "id",
              label: "Payment term",
              control_type: "select",
              pick_list: "payment_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Payment term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "payment-term-id-for-api", label: "Payment term id for api" },
          {
            name: "po-email",
            label: "PO email",
            hint: "Email where POs are sent if PO transmission is 'email'",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("email"),
            control_type: "email"
          },
          {
            name: "primary-address",
            label: "Primary address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "primary-address",
            label: "Primary address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "primary-contact",
            label: "Primary contact",
            hint: "Primary supplier contact email",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "remit-to-addresses",
            label: "Remit-to addresses",
            type: "array",
            of: "object",
            properties: [
              { name: "id" },
              { name: "name" },
              { name: "location-code", label: "Location code" }
            ]
          },
          {
            name: "restricted-account-types",
            label: "Restricted account types",
            control_type: "select",
            pick_list: "account_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "restricted-account-types",
              label: "Restricted account type ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            hint: "Savings for using this supplier",
            control_type: "number",
            type: "number"
          },
          {
            name: "send-invoices-to-approvals",
            label: "Send invoices to approvals",
            hint: "If yes, then invoices will all be sent " \
              "thru approvals, regardless of total amount.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "status", hint: "Supplier status" },
          {
            name: "storefront-url",
            label: "Storefront URL",
            hint: "Supplier website",
            control_type: "url",
            type: "text"
          },
          {
            name: "supplier-sites",
            label: "Supplier sites",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "supplier-status", label: "Supplier status" },
          {
            name: "tax-code",
            label: "Tax code",
            hint: "Supplier tax code",
            type: "object",
            properties: [{
              name: "id",
              label: "Tax code",
              control_type: "select",
              pick_list: "tax_codes",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Tax code ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "website", hint: "Supplier website" }
        ]
        standard_field_names = supplier_fields.pluck(:name)
        sample_record = get("/api/suppliers",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_get: {
      fields: lambda do |_connection, _config_fields|
        supplier_fields = [
          { name: "account-number", label: "Account number" },
          {
            name: "allow-csp-access-without-two-factor",
            label: "Allow CSP access without two factor",
            hint: "Allows supplier to access customer's data " \
              "from CSP without 2FA",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-cxml-invoicing",
            label: "Allow cXML invoicing",
            hint: "Allow cXML invoicing for supplier",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-choose-billing-account",
            label: "Allow inv choose billing account",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-from-connect",
            label: "Allow inv from connect",
            hint: "If yes, then the supplier can create invoices " \
              "against their POs or " \
            "Contracts in the CSP",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-no-backing-doc-from-connect",
            label: "Allow inv no backing doc from connect",
            hint: "If yes, then the supplier can create invoices " \
              "without a backing PO or contract in the CSP.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-unbacked-lines-from-connect",
            label: "Allow inv unbacked lines from connect",
            hint: "If yes, then the supplier can create unbacked " \
              "invoices without a backing PO or Contract in the CSP.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "business-groups",
            label: "Business groups",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "buyer-hold",
            label: "Buyer hold",
            hint: "Hold all POs for buyer review",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "commodity",
            hint: "Default commodity, selectable from drop down",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "corporate-url",
            label: "Corporate URL",
            control_type: "url",
            type: "sting"
          },
          {
            name: "coupa-connect-secret",
            label: "Coupa connect secret",
            control_type: "password"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "currency_id", type: "integer" },
          {
            name: "cxml-domain",
            label: "cXML domain",
            hint: "'From', our domain",
            control_type: "url",
            type: "string"
          },
          {
            name: "cxml-http-password",
            label: "cXML HTTP password",
            control_type: "password"
          },
          { name: "cxml-http-username", label: "cXML HTTP username" },
          {
            name: "cxml-identity",
            label: "cXML identity",
            hint: "'From', our identity",
            control_type: "text-area"
          },
          {
            name: "cxml-invoice-buyer-domain",
            label: "cXML invoice buyer domain",
            hint: "Buyer Domain for cXML Invoicing",
            control_type: "url"
          },
          {
            name: "cxml-invoice-buyer-identity",
            label: "cXML invoice buyer identity",
            hint: "Buyer Identity for cXML Invoicing"
          },
          {
            name: "cxml-invoice-secret",
            label: "cXML invoice secret",
            hint: "Secret Key for cXML Invoicing Authentication",
            control_type: "password"
          },
          {
            name: "cxml-invoice-supplier-domain",
            label: "cXML invoice supplier domain",
            hint: "Supplier Domain for cXML Invoicing"
          },
          {
            name: "cxml-invoice-supplier-identity",
            label: "cXML invoice supplier identity",
            hint: "Supplier Identity for cXML Invoicing"
          },
          {
            name: "cxml-protocol",
            label: "cXML protocol",
            hint: "Transmission protocol",
            control_type: "text-area"
          },
          {
            name: "cxml-secret",
            label: "cXML secret",
            hint: "Shared secret",
            control_type: "password"
          },
          { name: "cxml-ssl-version", label: "cXML SSL version" },
          {
            name: "cxml-supplier-domain",
            label: "cXML supplier domain",
            hint: "'To', supplier domain cXML supplier domain",
            control_type: "url"
          },
          {
            name: "cxml-supplier-identity",
            label: "cXML supplier identity",
            hint: "'To', supplier identity cXML supplier identity",
            control_type: "text-area"
          },
          {
            name: "cxml-url",
            label: "cXML URL",
            hint: "URL where POs are sent if PO transmission is 'cxml'",
            control_type: "url"
          },
          {
            name: "disable-cert-verify",
            label: "Disable cert verify",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "display-name", label: "Display name" },
          { name: "duns", hint: "Supplier DUNS number" },
          {
            name: "enterprise",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "code" }
            ]
          },
          {
            name: "hold-invoices-for-ap-review",
            label: "Hold invoices for AP review",
            hint: "Prevent invoices from this supplier from being " \
              "approved before AP reviews them.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa Internal ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "invoice-emails",
            label: "Invoice emails",
            hint: "Registered email addresses allowed to send " \
              "invoices via email to invoices@yourhost.coupahost.com.",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "invoice-matching-level",
            label: "Invoice matching level",
            control_type: "select",
            pick_list: "invoice_matching_levels",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "invoice-matching-level",
              label: "Invoice matching level",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "name", hint: "Supplier name" },
          { name: "number", hint: "Supplier number" },
          {
            name: "on-hold",
            label: "On hold",
            hint: "Supplier On Hold",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "online-store",
            label: "Online store",
            hint: "Supplier website",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "parent",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "payment-method",
            label: "Payment method",
            hint: "Default payment method, selectable from drop down",
            control_type: "select",
            pick_list: "payment_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-method",
              label: "Payment method",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "payment-term-id-for-api",
            label: "Payment term id for api"
          },
          {
            name: "po-change-method",
            label: "PO change method",
            hint: "Purchase order change transmission method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-change-method",
              label: "PO change method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "po-email",
            label: "PO email",
            hint: "Email where POs are sent if PO transmission is 'email'",
            control_type: "email"
          },
          {
            name: "po-method",
            label: "PO method",
            hint: "Purchase order transmission method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-method",
              label: "PO method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "primary-address",
            label: "Primary address",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "location-code" }
            ]
          },
          {
            name: "primary-contact",
            label: "Primary contact",
            hint: "Primary supplier contact email",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "remit-to-addresses",
            label: "Remit-to addresses",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "location-code", label: "Location code" }
            ]
          },
          {
            name: "restricted-account-types",
            label: "Restricted account types",
            control_type: "select",
            pick_list: "account_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "restricted-account-types",
              label: "Restricted account type ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            hint: "Savings for using this supplier",
            control_type: "number",
            type: "number"
          },
          {
            name: "send-invoices-to-approvals",
            label: "Send invoices to approvals",
            hint: "If yes, then invoices will all be sent thru " \
              "approvals, regardless of total amount.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "status", hint: "Supplier status" },
          {
            name: "storefront-url",
            label: "Storefront URL",
            hint: "Supplier website",
            control_type: "url",
            type: "text"
          },
          {
            name: "supplier-sites",
            label: "Supplier sites",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "supplier-status", label: "Supplier status", sticky: true },
          {
            name: "tax-code",
            label: "Tax code",
            hint: "Supplier tax code",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "tax-id", label: "Tax ID", hint: "Supplier DUNS number" },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "website", hint: "Supplier website" }
        ]
        standard_field_names = supplier_fields.pluck(:name)
        sample_record = get("/api/suppliers",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_update: {
      fields: lambda do |_connection, _config_fields|
        supplier_fields = [
          { name: "account-number", label: "Account number" },
          {
            name: "allow-csp-access-without-two-factor",
            label: "Allow CSP access without two factor",
            hint: "Allows supplier to access customer's data " \
              "from CSP without 2FA",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-cxml-invoicing",
            label: "Allow cXML invoicing",
            hint: "Allow cXML invoicing for supplier",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-choose-billing-account",
            label: "Allow inv choose billing account",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-from-connect",
            label: "Allow inv from connect",
            hint: "If yes, then the supplier can create invoices " \
              "against their POs or " \
            "Contracts in the CSP",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-no-backing-doc-from-connect",
            label: "Allow inv no backing doc from connect",
            hint: "If yes, then the supplier can create invoices " \
              "without a backing PO or contract in the CSP.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-unbacked-lines-from-connect",
            label: "Allow inv unbacked lines from connect",
            hint: "If yes, then the supplier can create unbacked " \
              "invoices without a backing PO or Contract in the CSP.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "business-groups",
            label: "Business groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Business groups",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Business group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "buyer-hold",
            label: "Buyer hold",
            hint: "Hold all POs for buyer review",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "commodity",
            hint: "Default commodity, selectable from drop down",
            type: "object",
            properties: [{
              name: "id",
              label: "Commodity",
              control_type: "select",
              pick_list: "commodities",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Commodity ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "corporate-url",
            label: "Corporate URL",
            control_type: "url",
            type: "sting"
          },
          {
            name: "coupa-connect-secret",
            label: "Coupa connect secret",
            control_type: "password"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "currency_id", type: "integer" },
          {
            name: "cxml-domain",
            label: "cXML domain",
            hint: "'From', our domain",
            control_type: "url",
            type: "string"
          },
          {
            name: "cxml-http-password",
            label: "cXML HTTP password",
            control_type: "password"
          },
          {
            name: "cxml-http-username",
            label: "cXML HTTP username"
          },
          {
            name: "cxml-identity",
            label: "cXML identity",
            hint: "'From', our identity",
            control_type: "text-area"
          },
          {
            name: "cxml-invoice-buyer-domain",
            label: "cXML invoice buyer domain",
            hint: "Buyer Domain for cXML Invoicing",
            control_type: "url"
          },
          {
            name: "cxml-invoice-buyer-identity",
            label: "cXML invoice buyer identity",
            hint: "Buyer Identity for cXML Invoicing"
          },
          {
            name: "cxml-invoice-secret",
            label: "cXML invoice secret",
            hint: "Secret Key for cXML Invoicing Authentication",
            control_type: "password"
          },
          {
            name: "cxml-invoice-supplier-domain",
            label: "cXML invoice supplier domain",
            hint: "Supplier Domain for cXML Invoicing"
          },
          {
            name: "cxml-invoice-supplier-identity",
            label: "cXML invoice supplier identity",
            hint: "Supplier Identity for cXML Invoicing"
          },
          {
            name: "cxml-protocol",
            label: "cXML protocol",
            hint: "Transmission protocol",
            control_type: "text-area"
          },
          {
            name: "cxml-secret",
            label: "cXML secret",
            hint: "Shared secret",
            control_type: "password"
          },
          { name: "cxml-ssl-version", label: "cXML SSL version" },
          {
            name: "cxml-supplier-domain",
            label: "cXML supplier domain",
            hint: "'To', supplier domain cXML supplier domain",
            control_type: "url"
          },
          {
            name: "cxml-supplier-identity",
            label: "cXML supplier identity",
            hint: "'To', supplier identity cXML supplier identity",
            control_type: "text-area"
          },
          {
            name: "cxml-url",
            label: "cXML URL",
            hint: "URL where POs are sent if PO transmission is 'cxml'",
            control_type: "url"
          },
          {
            name: "disable-cert-verify",
            label: "Disable cert verify",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "display-name", label: "Display name" },
          { name: "duns", hint: "Supplier DUNS number" },
          {
            name: "enterprise",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "code" }
            ]
          },
          {
            name: "hold-invoices-for-ap-review",
            label: "Hold invoices for AP review",
            hint: "Prevent invoices from this supplier from being " \
              "approved before AP reviews them.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa Internal ID",
            sticky: true,
            type: "integer"
          },
          {
            name: "invoice-emails",
            label: "Invoice emails",
            hint: "Registered email addresses allowed to send " \
              "invoices via email to invoices@yourhost.coupahost.com.",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "invoice-matching-level",
            label: "Invoice matching level",
            control_type: "select",
            pick_list: "invoice_matching_levels",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "invoice-matching-level",
              label: "Invoice matching level",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "name", hint: "Supplier name" },
          { name: "number", hint: "Supplier number" },
          {
            name: "on-hold",
            label: "On hold",
            hint: "Supplier On Hold",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "online-store",
            label: "Online store",
            hint: "Supplier website",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "parent",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "payment-method",
            label: "Payment method",
            hint: "Default payment method, selectable from drop down",
            control_type: "select",
            pick_list: "payment_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-method",
              label: "Payment method",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            type: "object",
            properties: [{
              name: "id",
              label: "Payment term",
              control_type: "select",
              pick_list: "payment_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Payment term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "payment-term-id-for-api",
            label: "Payment term id for api"
          },
          {
            name: "po-change-method",
            label: "PO change method",
            hint: "Purchase order change transmission method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-change-method",
              label: "PO change method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "po-email",
            label: "PO email",
            hint: "Email where POs are sent if PO transmission is 'email'",
            control_type: "email"
          },
          {
            name: "po-method",
            label: "PO method",
            hint: "Purchase order transmission method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-method",
              label: "PO method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "primary-address",
            label: "Primary address",
            type: "object",
            properties: [{
              name: "id",
              label: "Address",
              control_type: "select",
              pick_list: "addresses",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Address ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "primary-contact",
            label: "Primary contact",
            hint: "Primary supplier contact email",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "remit-to-addresses",
            label: "Remit-to addresses",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "location-code", label: "Location code" }
            ]
          },
          {
            name: "restricted-account-types",
            label: "Restricted account types",
            control_type: "select",
            pick_list: "account_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "restricted-account-types",
              label: "Restricted account type ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            hint: "Savings for using this supplier",
            control_type: "number",
            type: "number"
          },
          {
            name: "send-invoices-to-approvals",
            label: "Send invoices to approvals",
            hint: "If yes, then invoices will all be sent thru " \
              "approvals, regardless of total amount.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "status", hint: "Supplier status" },
          {
            name: "storefront-url",
            label: "Storefront URL",
            hint: "Supplier website",
            control_type: "url",
            type: "text"
          },
          {
            name: "supplier-sites",
            label: "Supplier sites",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "supplier-status", label: "Supplier status", sticky: true },
          {
            name: "tax-code",
            label: "Tax code",
            hint: "Supplier tax code",
            type: "object",
            properties: [{
              name: "id",
              label: "Tax code",
              control_type: "select",
              pick_list: "tax_codes",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Tax code ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "tax-id",
            label: "Tax ID",
            hint: "Supplier DUNS number"
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "website",
            hint: "Supplier website"
          }
        ]
        standard_field_names = supplier_fields.pluck(:name)
        sample_record = get("/api/suppliers",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_information: {
      fields: lambda do |_connection, _config_fields|
        supplier_info_fields = [
          {
            name: "allow-cxml-invoicing",
            label: "Allow cxml invoicing",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-choose-billing-account",
            label: "Allow inv choose billing account",
            hint: "Allow Choosing Billing Account in Invoicing",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-from-connect",
            label: "Allow inv from connect",
            hint: "Allow invoicing from connect",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-no-backing-doc-from-connect",
            label: "Allow inv no backing doc from connect",
            hint: "If yes, then the supplier can create invoices " \
              "without a backing PO or contract in the CSP.",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "allow-inv-unbacked-lines-from-connect",
            label: "Allow inv unbacked lines from connect",
            hint: "Allow invoicing with unbacked lines from connect",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "backend-system-catalog",
            label: "Backend system catalog",
            hint: "Backend System used for catalog management",
            control_type: "select",
            pick_list: "system_catalogs",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "backend-system-catalog",
              label: "Backend system catalog ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "backend-system-invoicing",
            label: "Backend system invoicing",
            hint: "Backend System Used for Invoice"
          },
          {
            name: "buyer-hold",
            label: "Buyer hold",
            hint: "Hold POs for buyer review",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "buyer-id", label: "Buyer ID", type: "integer" },
          { name: "comment", hint: "Comment Text" },
          { name: "comment-source", label: "Comment source" },
          { name: "commodity-id", label: "Commodity ID", type: "integer" },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          { name: "country-of-operation", label: "Country of operation" },
          {
            name: "country-of-operation-id",
            label: "Country of operation ID",
            type: "integer"
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "SIM Record Create Date and Time",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "currency-id", label: "Currency ID", type: "integer" },
          { name: "cxml-domain", label: "Cxml domain" },
          { name: "cxml-http-username", label: "Cxml http username" },
          { name: "cxml-identity", label: "Cxml identity" },
          { name: "cxml-protocol", label: "Cxml protocol" },
          {
            name: "cxml-secret",
            label: "Cxml secret",
            control_type: "password"
          },
          { name: "cxml-ssl-version", label: "Cxml ssl version" },
          { name: "cxml-supplier-domain", label: "Cxml supplier domain" },
          { name: "cxml-supplier-identity", label: "Cxml supplier identity" },
          { name: "cxml-url", label: "Cxml url", control_type: "url" },
          {
            name: "default-commodity",
            label: "Default commodity",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "default-commodity-id",
            label: "Default commodity ID",
            hint: "Default Commodity",
            type: "integer"
          },
          {
            name: "default-invoice-email",
            label: "Default invoice email",
            control_type: "email"
          },
          {
            name: "disable-cert-verify",
            label: "Disable cert verify",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "display-name",
            label: "Display name",
            hint: "Supplier Display Name"
          },
          {
            name: "duns-number",
            label: "Duns number",
            hint: "Dun and Bradstreet Number"
          },
          {
            name: "duplicate-exists",
            label: "Duplicate exists",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "estimated-spend-amount",
            label: "Estimated spend amount",
            hint: "Estimate Spend Amount",
            control_type: "number",
            type: "number"
          },
          {
            name: "fed-reportable",
            label: "Fed reportable",
            hint: "Federal Tax Reportable Indicator",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "federal-tax-num",
            label: "Federal tax num",
            hint: "Federal Tax ID Number"
          },
          {
            name: "goods-services-provided",
            label: "Goods services provided",
            hint: "Goods and Services Provided"
          },
          {
            name: "govt-agency-interaction",
            label: "Govt agency interaction",
            hint: "Government Agency Interaction Explanation"
          },
          {
            name: "govt-agency-interaction-indicator",
            label: "Govt agency interaction indicator",
            hint: "Government Agency Interaction Indicator",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "govt-allegation-fraud-bribery",
            label: "Govt allegation fraud bribery",
            hint: "Supplier policy for government allegations of " \
              "fraud and bribery"
          },
          {
            name: "govt-allegation-fraud-bribery-indicator",
            label: "Govt allegation fraud bribery indicator",
            hint: "Does the supplier have a policy for government " \
              "allegations of fraud and bribery?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "hold-invoices-for-ap-review",
            label: "Hold invoices for ap review",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "hold-payment", label: "Hold payment" },
          {
            name: "hold-payment-indicator",
            label: "Hold payment indicator",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "id", hint: "SIM ID", sticky: true, type: "integer" },
          {
            name: "inbound-invoice-domain",
            label: "Inbound invoice domain",
            hint: "Inbound Invoice Email Domain",
            control_type: "email"
          },
          { name: "inco-terms", label: "Inco terms" },
          { name: "income-type", label: "Income type" },
          { name: "industry", hint: "Primary industry of supplier" },
          {
            name: "intl-other-explanation",
            label: "Intl other explanation",
            hint: "International Tax Classification Explanation"
          },
          {
            name: "intl-tax-classification",
            label: "Intl tax classification",
            hint: "International Tax Classification"
          },
          {
            name: "intl-tax-num",
            label: "Intl tax num",
            hint: "International Tax Number"
          },
          { name: "invoice-amount-limit", label: "Invoice amount limit" },
          {
            name: "invoice-inbound-emails",
            label: "Invoice inbound emails",
            control_type: "email"
          },
          { name: "invoice-matching-level", label: "Invoice matching level" },
          {
            name: "last-exported-at",
            label: "Last exported at",
            hint: "Last Exported Flag"
          },
          { name: "logo-content-type", label: "Logo content type" },
          { name: "logo-file-name", label: "Logo file name" },
          { name: "logo-file-size", label: "Logo file size", type: "integer" },
          {
            name: "logo-updated-at",
            label: "Logo updated at",
            type: "timestamp"
          },
          {
            name: "minority-indicator",
            label: "Minority indicator",
            hint: "MWBE Indicator",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "minority-type-id",
            label: "Minority type ID",
            hint: "Minority Type",
            type: "integer"
          },
          { name: "name", hint: "Supplier name", sticky: true },
          { name: "organization-type", label: "Organization type" },
          { name: "parent-company-name", label: "Parent company name" },
          { name: "pay-group", label: "Pay group" },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Payment term code on invoice",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "payment-term-id",
            label: "Payment term ID",
            hint: "Payment Term",
            type: "integer"
          },
          {
            name: "payment-terms-id",
            label: "Payment terms ID",
            hint: "Payment Term",
            type: "integer"
          },
          { name: "po-change-method", label: "PO change method" },
          { name: "po-email", label: "PO email", control_type: "email" },
          { name: "po-method", label: "PO method" },
          {
            name: "policy-for-bribery-corruption",
            label: "Policy for bribery corruption",
            hint: "Supplier policy for bribery and corruption"
          },
          {
            name: "policy-for-bribery-corruption-indicator",
            label: "Policy for bribery corruption indicator",
            hint: "Does the supplier have a policy for bribery and corruption?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "preferred-currency",
            label: "Preferred currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "preferred-currency-id",
            label: "Preferred currency ID",
            hint: "Default Currency ID",
            type: "integer"
          },
          { name: "preferred-language", label: "Preferred language" },
          {
            name: "preferred-language-id",
            label: "Preferred language ID",
            type: "integer"
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            hint: "Savings Percentage",
            control_type: "number",
            type: "number"
          },
          {
            name: "send-invoices-to-approvals",
            label: "Send invoices to approvals",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "separate-remit-to",
            label: "Separate remit to",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "shipping-term-id",
            label: "Shipping term ID",
            type: "integer"
          },
          { name: "social-security-number", label: "Social security number" },
          { name: "status" },
          { name: "supplier-id", label: "Supplier ID", type: "integer" },
          {
            name: "supplier-information-addresses",
            label: "Supplier information addresses",
            hint: "Addresses Sub-Object"
          },
          {
            name: "supplier-information-artifacts",
            label: "Supplier information artifacts",
            hint: "Artifacts/Attachments Sub-Object"
          },
          {
            name: "supplier-information-contacts",
            label: "Supplier information contacts",
            hint: "Contacts Sub-Object"
          },
          { name: "supplier-name", label: "Supplier name" },
          { name: "supplier-number", label: "Supplier number" },
          { name: "supplier-region", label: "Supplier region" },
          {
            name: "tax-classification",
            label: "Tax classification",
            hint: "US Tax Classification"
          },
          { name: "tax-code-id", label: "Tax code ID", type: "integer" },
          {
            name: "tax-exempt-other-explanation",
            label: "Tax exempt other explanation",
            hint: "Tax Exempt Explanation"
          },
          { name: "tax-region", label: "Tax region" },
          {
            name: "third-party-interaction",
            label: "Third party interaction",
            hint: "Supplier policy for Third Party Interactions"
          },
          {
            name: "third-party-interaction-indicator",
            label: "Third party interaction indicator",
            hint: "Supplier has a policy for its Third Party Interactions?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "SIM Record Updated Date and Time",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "user-id", label: "User ID", type: "integer" },
          { name: "website", control_type: "url" }
        ]
        standard_field_names = supplier_info_fields.pluck(:name)
        sample_record = get("/api/supplier_information",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_info_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_item_create: {
      fields: lambda do |_connection, _config_fields|
        supplier_item_fields = [
          { name: "catalog" },
          {
            name: "contract",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract",
              control_type: "select",
              pick_list: "contracts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-terms",
            label: "Contract terms",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Contract term",
              control_type: "select",
              pick_list: "contract_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Contract currency code",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              optional: false,
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "item",
            type: "object",
            properties: [{
              name: "id",
              label: "Item",
              control_type: "select",
              pick_list: "items",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Item ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "lead-time", label: "Lead time", type: "integer" },
          { name: "manufacturer" },
          {
            name: "preferred",
            hint: "Indicates preferred supplier for this item",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "price", control_type: "number", type: "number" },
          { name: "price-change", label: "Price change" },
          {
            name: "price-tier-1",
            label: "Price tier 1",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-2",
            label: "Price tier 2",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-3",
            label: "Price tier 3",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-4",
            label: "Price tier 4",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-5",
            label: "Price tier 5",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-6",
            label: "Price tier 6",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-7",
            label: "Price tier 7",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-8",
            label: "Price tier 8",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-9",
            label: "Price tier 9",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-10",
            label: "Price tier 10",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-11",
            label: "Price tier 11",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-12",
            label: "Price tier 12",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-13",
            label: "Price tier 13",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-14",
            label: "Price tier 14",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-15",
            label: "Price tier 15",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-16",
            label: "Price tier 16",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-17",
            label: "Price tier 17",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-18",
            label: "Price tier 18",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-19",
            label: "Price tier 19",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-20",
            label: "Price tier 20",
            control_type: "number",
            type: "number"
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            control_type: "number",
            type: "number"
          },
          {
            name: "supplier",
            optional: false,
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              optional: false,
              control_type: "select",
              pick_list: "suppliers",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "supplier-aux-part-num", label: "Supplier aux part num" },
          { name: "supplier-part-num", label: "Supplier part num" },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = supplier_item_fields.pluck(:name)
        sample_record = get("/api/supplier_items",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_item_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_item_get: {
      fields: lambda do |_connection, _config_fields|
        supplier_item_fields = [
          { name: "catalog" },
          {
            name: "contract",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "contract-terms",
            label: "Contract terms",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Contract currency code",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "item",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "item-number" },
              { name: "name" }
            ]
          },
          { name: "lead-time", label: "Lead time", type: "integer" },
          { name: "manufacturer" },
          {
            name: "preferred",
            hint: "Indicates preferred supplier for this item",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "price", control_type: "number", type: "number" },
          { name: "price-change", label: "Price change" },
          {
            name: "price-tier-1",
            label: "Price tier 1",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-2",
            label: "Price tier 2",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-3",
            label: "Price tier 3",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-4",
            label: "Price tier 4",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-5",
            label: "Price tier 5",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-6",
            label: "Price tier 6",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-7",
            label: "Price tier 7",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-8",
            label: "Price tier 8",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-9",
            label: "Price tier 9",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-10",
            label: "Price tier 10",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-11",
            label: "Price tier 11",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-12",
            label: "Price tier 12",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-13",
            label: "Price tier 13",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-14",
            label: "Price tier 14",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-15",
            label: "Price tier 15",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-16",
            label: "Price tier 16",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-17",
            label: "Price tier 17",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-18",
            label: "Price tier 18",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-19",
            label: "Price tier 19",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-20",
            label: "Price tier 20",
            control_type: "number",
            type: "number"
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            control_type: "number",
            type: "number"
          },
          {
            name: "supplier",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "number" }
            ]
          },
          { name: "supplier-aux-part-num", label: "Supplier aux part num" },
          { name: "supplier-part-num", label: "Supplier part num" },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = supplier_item_fields.pluck(:name)
        sample_record = get("/api/supplier_items",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_item_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_item_update: {
      fields: lambda do |_connection, _config_fields|
        supplier_item_fields = [
          { name: "catalog" },
          {
            name: "contract",
            type: "object",
            properties: [{
              name: "id",
              label: "Contract",
              control_type: "select",
              pick_list: "contracts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-terms",
            label: "Contract terms",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Contract term",
              control_type: "select",
              pick_list: "contract_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Contract term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "created-at",
            label: "Created at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "created-by",
            label: "Created by",
            hint: "User who created",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "currency",
            hint: "Contract currency code",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "item",
            type: "object",
            properties: [{
              name: "id",
              label: "Item",
              control_type: "select",
              pick_list: "items",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Item ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "lead-time", label: "Lead time", type: "integer" },
          { name: "manufacturer" },
          {
            name: "preferred",
            hint: "Indicates preferred supplier for this item",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "price", control_type: "number", type: "number" },
          { name: "price-change", label: "Price change" },
          {
            name: "price-tier-1",
            label: "Price tier 1",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-2",
            label: "Price tier 2",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-3",
            label: "Price tier 3",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-4",
            label: "Price tier 4",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-5",
            label: "Price tier 5",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-6",
            label: "Price tier 6",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-7",
            label: "Price tier 7",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-8",
            label: "Price tier 8",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-9",
            label: "Price tier 9",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-10",
            label: "Price tier 10",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-11",
            label: "Price tier 11",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-12",
            label: "Price tier 12",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-13",
            label: "Price tier 13",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-14",
            label: "Price tier 14",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-15",
            label: "Price tier 15",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-16",
            label: "Price tier 16",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-17",
            label: "Price tier 17",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-18",
            label: "Price tier 18",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-19",
            label: "Price tier 19",
            control_type: "number",
            type: "number"
          },
          {
            name: "price-tier-20",
            label: "Price tier 20",
            control_type: "number",
            type: "number"
          },
          {
            name: "savings-pct",
            label: "Savings pct",
            control_type: "number",
            type: "number"
          },
          {
            name: "supplier",
            type: "object",
            properties: [{
              name: "id",
              label: "Supplier",
              control_type: "select",
              pick_list: "suppliers",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Supplier ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "supplier-aux-part-num", label: "Supplier aux part num" },
          { name: "supplier-part-num", label: "Supplier part num" },
          {
            name: "updated-at",
            label: "Updated at",
            hint: "Automatically created by Coupa in the format " \
              "YYYY-MM-DDTHH:MM:SS+HH:MMZ",
            type: "timestamp"
          },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = supplier_item_fields.pluck(:name)
        sample_record = get("/api/supplier_items",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_item_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_site_create: {
      fields: lambda do |_connection, config_fields|
        supplier_site_fields = [
          {
            name: "active",
            hint: "Yes if the site is active",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "buyer-hold",
            label: "Buyer hold",
            hint: "Hold all POs for buyer review",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "code", hint: "Supplier code" },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "cxml-domain",
            label: "cXML domain",
            hint: "'From', Coupa domain",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml")
          },
          {
            name: "cxml-http-username",
            label: "cXML HTTP username",
            hint: "User name required to access the supplier's online store"
          },
          {
            name: "cxml-identity",
            label: "cXML identity",
            hint: "'From', Coupa identity",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml")
          },
          {
            name: "cxml-protocol",
            label: "cXML protocol",
            hint: "Transmission protocol",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml")
          },
          {
            name: "cxml-secret",
            label: "cXML secret",
            hint: "Shared secret",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml")
          },
          {
            name: "cxml-ssl-version",
            label: "cXML SSL version",
            hint: "Specify the SSL version used for cXML communication " \
              "with the supplier"
          },
          {
            name: "cxml-supplier-domain",
            label: "cXML supplier domain",
            hint: "'To', supplier domain",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml")
          },
          {
            name: "cxml-supplier-identity",
            label: "cXML supplier identity",
            hint: "'To', supplier identity",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml")
          },
          {
            name: "cxml-url",
            label: "cXML URL",
            hint: "URL where POs are sent if PO transmission is 'cxml'",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("cxml")
          },
          {
            name: "disable-cert-verify",
            label: "Disable cert verify",
            hint: "Specify whether to ignore SSL certificate mismatch errors",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa Internal ID of the Supplier Site record",
            sticky: true,
            type: "integer"
          },
          { name: "name" },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "po-email",
            label: "PO email",
            hint: "Email where POs are sent if PO transmission is 'email'",
            optional: ![config_fields["po_method"],
                        config_fields["po_change_method"]].include?("email"),
            control_type: "email",
            type: "string"
          },
          {
            name: "remit-to-addresses",
            label: "Remit-to addresses",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = supplier_site_fields.pluck(:name)
        sample_record = get("/api/suppliers" \
                            "/#{config_fields['supplier']}/supplier_sites",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_site_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_site_get: {
      fields: lambda do |_connection, config_fields|
        supplier_site_fields = [
          {
            name: "active",
            hint: "Yes if the site is active",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "buyer-hold",
            label: "Buyer hold",
            hint: "Hold all POs for buyer review",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "code", hint: "Supplier code" },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "cxml-domain",
            label: "cXML domain",
            hint: "'From', Coupa domain"
          },
          {
            name: "cxml-http-username",
            label: "cXML HTTP username",
            hint: "User name required to access the supplier's online store"
          },
          {
            name: "cxml-identity",
            label: "cXML identity",
            hint: "'From', Coupa identity"
          },
          {
            name: "cxml-protocol",
            label: "cXML protocol",
            hint: "Transmission protocol"
          },
          { name: "cxml-secret", label: "cXML secret", hint: "Shared secret" },
          {
            name: "cxml-ssl-version",
            label: "cXML SSL version",
            hint: "Specify the SSL version used for cXML communication " \
              "with the supplier",
          },
          {
            name: "cxml-supplier-domain",
            label: "cXML supplier domain",
            hint: "'To', supplier domain"
          },
          {
            name: "cxml-supplier-identity",
            label: "cXML supplier identity",
            hint: "'To', supplier identity"
          },
          {
            name: "cxml-url",
            label: "cXML URL",
            hint: "URL where POs are sent if PO transmission is 'cxml'"
          },
          {
            name: "disable-cert-verify",
            label: "Disable cert verify",
            hint: "Specify whether to ignore SSL certificate mismatch errors",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa Internal ID of the Supplier Site record",
            sticky: true,
            type: "integer"
          },
          { name: "name" },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "po-change-method",
            label: "PO change method",
            hint: "Purchase order change transmission method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-change-method",
              label: "PO change method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "po-email",
            label: "PO email",
            hint: "Email where POs are sent if PO transmission is 'email'",
            control_type: "email",
            type: "string"
          },
          {
            name: "po-method",
            label: "PO method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-method",
              label: "PO method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "remit-to-addresses",
            label: "Remit-to addresses",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }, { name: "name" }]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = supplier_site_fields.pluck(:name)
        sample_record = get("/api/suppliers" \
                            "/#{config_fields['supplier']}/supplier_sites",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_site_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    supplier_site_update: {
      fields: lambda do |_connection, config_fields|
        supplier_site_fields = [
          {
            name: "active",
            hint: "Yes if the site is active",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "buyer-hold",
            label: "Buyer hold",
            hint: "Hold all POs for buyer review",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "code", hint: "Supplier code" },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "cxml-domain",
            label: "cXML domain",
            hint: "'From', Coupa domain"
          },
          {
            name: "cxml-http-username",
            label: "cXML HTTP username",
            hint: "User name required to access the supplier's online store"
          },
          {
            name: "cxml-identity",
            label: "cXML identity",
            hint: "'From', Coupa identity"
          },
          {
            name: "cxml-protocol",
            label: "cXML protocol",
            hint: "Transmission protocol"
          },
          { name: "cxml-secret", label: "cXML secret", hint: "Shared secret" },
          {
            name: "cxml-ssl-version",
            label: "cXML SSL version",
            hint: "Specify the SSL version used for cXML communication " \
              "with the supplier",
          },
          {
            name: "cxml-supplier-domain",
            label: "cXML supplier domain",
            hint: "'To', supplier domain"
          },
          {
            name: "cxml-supplier-identity",
            label: "cXML supplier identity",
            hint: "'To', supplier identity"
          },
          {
            name: "cxml-url",
            label: "cXML URL",
            hint: "URL where POs are sent if PO transmission is 'cxml'"
          },
          {
            name: "disable-cert-verify",
            label: "Disable cert verify",
            hint: "Specify whether to ignore SSL certificate mismatch " \
              "errors",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "id",
            hint: "Coupa Internal ID of the Supplier Site record",
            sticky: true,
            type: "integer"
          },
          { name: "name" },
          {
            name: "payment-term",
            label: "Payment term",
            hint: "Default payment term, selectable from drop down",
            control_type: "select",
            pick_list: "payment_terms",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "payment-term",
              label: "Payment term ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "po-change-method",
            label: "PO change method",
            hint: "Purchase order change transmission method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-change-method",
              label: "PO change method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "po-email",
            label: "PO email",
            hint: "Email where POs are sent if PO transmission is 'email'",
            control_type: "email",
            type: "string"
          },
          {
            name: "po-method",
            label: "PO method",
            control_type: "select",
            pick_list: "po_transmission_methods",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "po-method",
              label: "PO method ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "remit-to-addresses",
            label: "Remit-to addresses",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }, { name: "name" }]
          },
          {
            name: "shipping-term",
            label: "Shipping term",
            type: "object",
            properties: [{
              name: "id",
              label: "Shipping term",
              control_type: "select",
              pick_list: "shipping_terms",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Shipping term ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          }
        ]
        standard_field_names = supplier_site_fields.pluck(:name)
        sample_record = get("/api/suppliers" \
                            "/#{config_fields['supplier']}/supplier_sites",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = supplier_site_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    user: {
      fields: lambda do |_connection, _config_fields|
        user_fields = [
          {
            name: "account-groups",
            label: "Account groups",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "account-security-type",
            label: "Account security type",
            type: "integer"
          },
          {
            name: "active",
            hint: "A yes will make it active and available to users. " \
              "A no will inactivate the account making it no longer " \
              "available to users.",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "analytics-user",
            label: "Analytics user",
            hint: "Does the user have an analytics license?",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "api-user",
            label: "API user",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "approval-groups",
            label: "Approval groups",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "approval-limit",
            label: "Approval limit",
            hint: "Maximum amount allowed to approve.",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "authentication-method",
            label: "Authentication method",
            hint: "What authentication method will be used " \
              "(coupa_credentials, ldap,  saml)?"
          },
          { name: "avatar-thumb-url", label: "Avatar thumb URL" },
          {
            name: "business-group-security-type",
            label: "Business group security type",
            control_type: "select",
            pick_list: "security_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "business-group-security-type",
              label: "Security type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "can-expense-for",
            label: "Can expense for",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Content group",
              control_type: "select",
              pick_list: "content_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Content group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-approval-limit",
            label: "Contract approval limit",
            hint: "Maximum amount allowed to approve.",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contract-self-approval-limit",
            label: "Contract self-approval limit",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "contracts-user",
            label: "Contracts user",
            hint: "Does the user have a contracts license?",
            type: "boolean",
            control_type: "checkbox"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "default-account",
            label: "Default account",
            type: "object",
            properties: [{
              name: "id",
              label: "Account",
              control_type: "select",
              pick_list: "accounts",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "default-account-type",
            label: "Default account type",
            type: "object",
            properties: [{
              name: "id",
              label: "Account type",
              control_type: "select",
              pick_list: "account_types",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Account type ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "default-address",
            label: "Default address",
            type: "object",
            hint: "Fields below are only required if default address " \
              "is to be set",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "location-code", label: "Location code" }
            ]
          },
          {
            name: "default-currency",
            label: "Default currency",
            type: "object",
            properties: [{
              name: "id",
              label: "Currency",
              control_type: "select",
              pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Currency ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "default-locale",
            label: "Default locale",
            control_type: "select",
            pick_list: "default_locales",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "default-locale",
              label: "Default locale ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "department",
            type: "object",
            properties: [{
              name: "id",
              label: "Department",
              control_type: "select",
              pick_list: "departments",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Department ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "edit-invoice-on-quick-entry",
            label: "Edit invoice on quick entry",
            hint: "Edit invoice button routes user to fast entry screen",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "email", control_type: "email", sticky: true },
          { name: "employee-number", label: "Employee number" },
          {
            name: "expense-approval-limit",
            label: "Expense approval limit",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "expense-self-approval-limit",
            label: "Expense self-approval limit",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "expense-user",
            label: "Expense user",
            hint: "Does the user have an expense license?",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "expenses-delegated-to",
            label: "Expenses delegated to",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "firstname", label: "First name" },
          { name: "fullname", label: "Full name" },
          {
            name: "generate-password-and-notify",
            label: "Generate password and notify",
            hint: "Set to yes, if you want the system to invite the " \
              "user to the system and have them set up their password",
            control_type: "select",
            pick_list: "yes_or_no_options",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "notify_option",
              label: "Notify options",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "inventory-organizations",
            label: "Inventory organizations",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "inventory-user",
            label: "Inventory user",
            hint: "Does the user have a Inventory license?",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "invoice-approval-limit",
            label: "Invoice approval limit",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "invoice-self-approval-limit",
            label: "Invoice self-approval limit",
            hint: "Maximum amount allowed for invoice self approvals",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "lastname", label: "Last name" },
          { name: "login" },
          {
            name: "manager",
            type: "object",
            properties: [{
              name: "id",
              label: "Manager",
              control_type: "select",
              pick_list: "users",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Manager user ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          { name: "mention-name", label: "Mention name" },
          {
            name: "password",
            hint: "Set temporary password for user",
            control_type: "password"
           },
          { name: "pcard", label: "PCard" },
          {
            name: "phone-mobile",
            label: "Mobile phone",
            type: "object",
            properties: [
              { name: "country-code" },
              { name: "area-code" },
              { name: "number" },
              { name: "extension" }
            ]
          },
          {
            name: "phone-work",
            label: "Work phone",
            type: "object",
            properties: [
              { name: "country-code" },
              { name: "area-code" },
              { name: "number" },
              { name: "extension" }
            ]
          },
          {
            name: "purchasing-user",
            label: "Purchasing user",
            hint: "Does the user have a Purchasing license?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "requisition-approval-limit",
            label: "Requisition approval limit",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "roles",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "Role",
              control_type: "select",
              pick_list: "roles",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Role ID",
                hint: "Use 'null' or 'nil' value to remove all roles",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "salesforce-enabled",
            label: "Salesforce enabled",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "salesforce-id",
            hint: "Required if Salesforce is enabled for user",
            label: "Salesforce ID"
          },
          {
            name: "self-approval-limit",
            label: "Self-approval limit",
            hint: "Maximum amount allowed for self approvals",
            type: "object",
            properties: [{
              name: "id",
              label: "Approval limit",
              control_type: "select",
              pick_list: "approval_limits",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Approval limit ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "sourcing-user",
            label: "Sourcing user",
            hint: "Does the user have a sourcing license?",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "sso-identifier", label: "SSO identifier" },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "user-groups",
            label: "User groups",
            type: "array",
            of: "object",
            properties: [{
              name: "id",
              label: "User group",
              control_type: "select",
              pick_list: "user_groups",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User group ID",
                toggle_hint: "Use custom value",
                control_type: "number",
                type: "integer"
              }
            }]
          },
          {
            name: "working-warehouses",
            label: "Working warehouses",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          }
        ]
        standard_field_names = user_fields.pluck(:name)
        sample_record = get("/api/users",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = user_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    },

    user_get: {
      fields: lambda do |_connection, _config_fields|
        user_fields = [
          {
            name: "account-groups",
            label: "Account groups",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "account-security-type",
            label: "Account security type",
            type: "integer"
          },
          {
            name: "active",
            hint: "A yes will make it active and available to users. " \
              "A no will inactivate the account making it no longer " \
              "available to users.",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "analytics-user",
            label: "Analytics user",
            hint: "Does the user have an analytics license?",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "api-user",
            label: "API user",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "approval-groups",
            label: "Approval groups",
            type: "array",
            of: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "approval-limit",
            label: "Approval limit",
            hint: "Maximum amount allowed to approve.",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "authentication-method",
            label: "Authentication method",
            hint: "What authentication method will be used " \
              "(coupa_credentials, ldap,  saml)?"
          },
          { name: "avatar-thumb-url", label: "Avatar thumb URL" },
          {
            name: "business-group-security-type",
            label: "Business group security type",
            control_type: "select",
            pick_list: "security_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "business-group-security-type",
              label: "Security type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "can-expense-for",
            label: "Can expense for",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "content-groups",
            label: "Content groups",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "contract-approval-limit",
            label: "Contract approval limit",
            hint: "Maximum amount allowed to approve.",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "contract-self-approval-limit",
            label: "Contract self-approval limit",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "contracts-user",
            label: "Contracts user",
            hint: "Does the user have a contracts license?",
            type: "boolean",
            control_type: "checkbox"
          },
          { name: "created-at", label: "Created at", type: "timestamp" },
          {
            name: "created-by",
            label: "Created by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "default-account",
            label: "Default account",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "default-account-type",
            label: "Default account type",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "default-address",
            label: "Default address",
            type: "object",
            hint: "Fields below are only required if default address " \
              "is to be set",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" },
              { name: "location-code", label: "Location code" }
            ]
          },
          {
            name: "default-currency",
            label: "Default currency",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "code" }
            ]
          },
          {
            name: "default-locale",
            label: "Default locale",
            control_type: "select",
            pick_list: "default_locales",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "default-locale",
              label: "Default locale ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "department",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "edit-invoice-on-quick-entry",
            label: "Edit invoice on quick entry",
            hint: "Edit invoice button routes user to fast entry screen",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "email", control_type: "email", sticky: true },
          { name: "employee-number", label: "Employee number" },
          {
            name: "expense-approval-limit",
            label: "Expense approval limit",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-self-approval-limit",
            label: "Expense self-approval limit",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "expense-user",
            label: "Expense user",
            hint: "Does the user have an expense license?",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "expenses-delegated-to",
            label: "Expenses delegated to",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "firstname", label: "First name" },
          { name: "fullname", label: "Full name" },
          {
            name: "generate-password-and-notify",
            label: "Generate password and notify",
            hint: "Set to yes, if you want the system to invite the " \
              "user to the system and have them set up their password",
            control_type: "select",
            pick_list: "yes_or_no_options",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "notify_option",
              label: "Notify options",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "id",
            hint: "Coupa unique identifier",
            sticky: true,
            type: "integer"
          },
          {
            name: "inventory-organizations",
            label: "Inventory organizations",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "inventory-user",
            label: "Inventory user",
            hint: "Does the user have a Inventory license?",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "invoice-approval-limit",
            label: "Invoice approval limit",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "invoice-self-approval-limit",
            label: "Invoice self-approval limit",
            hint: "Maximum amount allowed for invoice self approvals",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          { name: "lastname", label: "Last name" },
          { name: "login" },
          {
            name: "manager",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          { name: "mention-name", label: "Mention name" },
          {
            name: "password",
            hint: "Set temporary password for user",
            control_type: "password"
           },
          { name: "pcard", label: "PCard" },
          {
            name: "phone-mobile",
            label: "Mobile phone",
            type: "object",
            properties: [
              { name: "country-code" },
              { name: "area-code" },
              { name: "number" },
              { name: "extension" }
            ]
          },
          {
            name: "phone-work",
            label: "Work phone",
            type: "object",
            properties: [
              { name: "country-code" },
              { name: "area-code" },
              { name: "number" },
              { name: "extension" }
            ]
          },
          {
            name: "purchasing-user",
            label: "Purchasing user",
            hint: "Does the user have a Purchasing license?",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "requisition-approval-limit",
            label: "Requisition approval limit",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "roles",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "salesforce-enabled",
            label: "Salesforce enabled",
            type: "boolean",
            control_type: "checkbox"
          },
          {
            name: "salesforce-id",
            hint: "Required if Salesforce is enabled for user",
            label: "Salesforce ID"
          },
          {
            name: "self-approval-limit",
            label: "Self-approval limit",
            hint: "Maximum amount allowed for self approvals",
            type: "object",
            properties: [{ name: "id", type: "integer" }]
          },
          {
            name: "sourcing-user",
            label: "Sourcing user",
            hint: "Does the user have a sourcing license?",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "sso-identifier", label: "SSO identifier" },
          { name: "updated-at", label: "Updated at", type: "timestamp" },
          {
            name: "updated-by",
            label: "Updated by",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "login" },
              { name: "email", control_type: "email" }
            ]
          },
          {
            name: "user-groups",
            label: "User groups",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "working-warehouses",
            label: "Working warehouses",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "name" }
            ]
          }
        ]
        standard_field_names = user_fields.pluck(:name)
        sample_record = get("/api/users",
                            return_object: "shallow",
                            limit: 1)&.[](0)
        custom_fields = sample_record&.map do |key, _|
                          { name: key } unless standard_field_names.include? key
                        end&.compact
        all_fields = user_fields.concat(custom_fields || [])

        call("format_schema_field_names", all_fields.compact)
      end
    }
  },

  actions: {
    # Address related actions
    search_addresses: {
      subtitle: "Search addresses",
      description: "Search <span class='provider'>addresses</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of addresses (max 50).",

      execute: lambda do |_connection, input|
        {
          addresses: get("/api/addresses",
                         { return_object: "shallow" }.merge(input))&.compact
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["address_get"].
          only("active", "description", "id", "item-number")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "addresses",
          type: "array",
          of: "object",
          properties: object_definitions["address_get"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          addresses: get("/api/addresses",
                         return_object: "shallow",
                         limit: 1)&.compact
        }
      end
    },

    get_address_by_id: {
      subtitle: "Get address by ID",
      description: "Get <span class='provider'>address</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the address, that matches the given ID.",

      execute: lambda do |_connection, input|
        get("/api/addresses/#{input['id']}") .params(return_object: "shallow")
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["address_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["address_get"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/api/addresses", return_object: "shallow", limit: 1)&.[](0) || {}
      end
    },

    create_address: {
      subtitle: "Create address",
      description: "Create <span class='provider'>address</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        post("/api/addresses", input).params(return_object: "shallow")
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["address_create"].
          ignored("created_at", "created_by", "id", "updated_at", "updated_by").
          required("city", "postal_code", "street1")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["address_get"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/api/addresses", return_object: "shallow", limit: 1)&.[](0) || {}
      end
    },

    update_address: {
      subtitle: "Update address",
      description: "Update <span class='provider'>address</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the address, that matches the given ID.",

      execute: lambda do |_connection, input|
        put("/api/addresses/#{input['id']}", input).
          params(return_object: "shallow")
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["address_update"].
          ignored("created_at", "created_by", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["address_get"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/api/addresses", return_object: "shallow", limit: 1)&.[](0) || {}
      end
    },

    # Attachment related actions
    get_attachments_by_object_id: {
      subtitle: "Get attachments by object ID",
      description: "Get <span class='provider'>attachments</span> " \
        "by object ID in <span class='provider'>Coupa</span>",
      hint: "Fetches all attachments, that matches the given object ID.",

      execute: lambda do |_connection, input|
        {
          attachments: call("format_api_output_field_names",
                            get("/api/#{input['object']}/" \
                              "#{input['object_id']}/attachments",
                                return_object: "shallow")&.compact)
        }
      end,

      config_fields: [
        {
          name: "object",
          hint: "Choose whether the attachment is linked with  " \
            "contract, invoice, expense, purchase order, requisition or user",
          control_type: "select",
          pick_list: "attachment_objects",
          optional: false
        },
        {
          name: "object_id",
          hint: "Enter ID of corresponding contract, invoice, expense, " \
            "purchase order, requisition or user",
          optional: false,
          type: "integer"
        }
      ],

      output_fields: lambda do |object_definitions|
        [{
          name: "attachments",
          type: "array",
          of: "object",
          properties: object_definitions["attachment"]
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          attachments: call("format_api_output_field_names",
                            get("/api/#{input['object']}/" \
                              "#{input['object_id']}/attachments",
                                return_object: "shallow",
                                limit: 1)&.compact)
        }
      end
    },

    # Contract related actions
    search_contracts: {
      subtitle: "Search contracts",
      description: "Search <span class='provider'>contracts</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of contracts (max 50).",

      execute: lambda do |_connection, input|
        {
          contracts: call("format_api_output_field_names",
                          get("/api/contracts",
                              { return_object: "shallow" }.
                              merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["contract_get"].only("id", "name", "active")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "contracts",
          type: "array",
          of: "object",
          properties: object_definitions["contract_get"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          contracts: call("format_api_output_field_names",
                          get("/api/contracts",
                              return_object: "shallow",
                              limit: 1))
        }
      end
    },

    get_contract_by_id: {
      subtitle: "Get contract by ID",
      description: "Get <span class='provider'>contract</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the contract, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/contracts/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["contract_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["contract_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/contracts",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_contract: {
      subtitle: "Create contract",
      description: "Create <span class='provider'>contract</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/contracts",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["contract_create"].
          ignored("consent", "contract_owner", "created_at", "created_by",
                  "current_approval", "id", "length_of_notice_unit",
                  "length_of_notice_value", "no_of_renewals",
                  "quote_response_id", "renewal_length_unit",
                  "renewal_length_value", "strict_invoicing_rules",
                  "submitter", "term_type", "termination_notice", "type",
                  "updated_at", "updated_by", "used_for_buying").
          required("end_date", "name", "number", "start_date", "status",
                   "supplier")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["contract_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/contracts",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_contract: {
      subtitle: "Update contract",
      description: "Update <span class='provider'>contract</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the contract, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/contracts/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["contract_update"].
          ignored("consent", "contract_owner", "created_at", "created_by",
                  "current_approval", "length_of_notice_unit",
                  "length_of_notice_value", "no_of_renewals",
                  "quote_response_id", "renewal_length_unit",
                  "renewal_length_value", "strict_invoicing_rules",
                  "submitter", "term_type", "termination_notice", "type",
                  "updated_at", "updated_by", "used_for_buying").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["contract_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/contracts",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Department related actions
    search_departments: {
      subtitle: "Search departments",
      description: "Search <span class='provider'>departments</span> in " \
        "<span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of departments (max 50).",

      execute: lambda do |_connection, input|
        {
          departments: call("format_api_output_field_names",
                            get("/api/departments",
                                { return_object: "shallow" }.
                                merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["department"].only("id", "name", "active")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "departments",
          type: "array",
          of: "object",
          properties: object_definitions["department"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          departments: call("format_api_output_field_names",
                            get("/api/departments",
                                return_object: "shallow",
                                limit: 1)&.compact)
        }
      end
    },

    get_department_by_id: {
      subtitle: "Get department by ID",
      description: "Get <span class='provider'>department</span> by ID in " \
        "<span class='provider'>Coupa</span>",
      help: "Fetches the department, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/departments/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["department"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["department"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/departments",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_department: {
      subtitle: "Create department",
      description: "Create <span class='provider'>department</span> in " \
        "<span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/departments",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["department"].
          ignored("created_at", "created_by", "id", "updated_at", "updated_by").
          required("name", "active")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["department"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/departments",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_department: {
      subtitle: "Update department",
      description: "Update <span class='provider'>department</span> in " \
        "<span class='provider'>Coupa</span>",
      help: "Updates the department, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/departments/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["department"].
          ignored("created_at", "created_by", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["department"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/departments",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Exchange Rate related actions
    search_exchange_rates: {
      subtitle: "Search exchange rates",
      description: "Search <span class='provider'>exchange rates</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of exchange rates (max 50).",

      execute: lambda do |_connection, input|
        {
          exchange_rates: call("format_api_output_field_names",
                               get("/api/exchange_rates",
                                   { return_object: "shallow" }.
                                   merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["exchange_rate_get"] .only("id", "rate")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "exchange_rates",
          type: "array",
          of: "object",
          properties: object_definitions["exchange_rate_get"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          exchange_rates: call("format_api_output_field_names",
                               get("/api/exchange_rates",
                                   return_object: "shallow",
                                   limit: 1)&.compact)
        }
      end
    },

    get_exchange_rate_by_id: {
      subtitle: "Get exchange_rate by ID",
      description: "Get <span class='provider'>exchange rate</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the exchange rate, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/exchange_rates/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields:    lambda do |object_definitions|
        object_definitions["exchange_rate_get"].only("id").required("id")
      end,


      output_fields: lambda do |object_definitions|
        object_definitions["exchange_rate_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/exchange_rates",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_exchange_rate: {
      subtitle: "Create exchange rate",
      description: "Create <span class='provider'>exchange rate" \
        "</span> in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/exchange_rates",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["exchange_rate_create"].
          ignored("created_at", "created_by", "id", "updated_at", "updated_by").
          required("rate", "rate_date")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["exchange_rate_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/exchange_rates",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_exchange_rate: {
      subtitle: "Update exchange rate",
      description: "Update <span class='provider'>exchange rate" \
        "</span> in <span class='provider'>Coupa</span>",
      help: "Updates the exchange rate, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/exchange_rates/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["exchange_rate_update"].
          ignored("created_at", "created_by", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["exchange_rate_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/exchange_rates",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Expense Lines related actions
    search_expense_lines: {
      subtitle: "Search expense lines",
      description: "Search <span class='provider'>expense " \
        "lines</span> in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of expense lines (max 50).",

      execute: lambda do |_connection, input|
        {
          expense_lines: call("format_api_output_field_names",
                              get("/api/expense_lines",
                                  { return_object: "shallow" }.
                                  merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["expense_line_get"].
          only("custom_field_1", "custom_field_10", "custom_field_11",
                "custom_field_12", "custom_field_13", "custom_field_14",
                "custom_field_15", "custom_field_16", "custom_field_17",
                "custom_field_18", "custom_field_19", "custom_field_2",
                "custom_field_20", "custom_field_3", "custom_field_4",
                "custom_field_5", "custom_field_6", "custom_field_7",
                "custom_field_8", "custom_field_9", "description",
                "expense_category_custom_field_1",
                "expense_category_custom_field_2",
                "expense_category_custom_field_3",
                "expense_category_custom_field_4",
                "expense_category_custom_field_5",
                "expense_category_custom_field_6",
                "expense_category_custom_field_7",
                "expense_category_custom_field_8",
                "expense_category_custom_field_9",
                "expense_category_custom_field_10", "expense_report_id",
                "external_src_data", "external_src_name", "external_src_ref",
                "foreign_currency_id", "id", "line_number",
                "merchant", "order_line_id", "over_limit",
                "parent_expense_line_id", "parent_external_src_data",
                "parent_external_src_name", "parent_external_src_ref",
                "reason", "receipt_total_currency_id", "requires_receipt",
                "status", "type")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "expense_lines",
          type: "array",
          of: "object",
          properties: object_definitions["expense_line_get"].
            ignored("foreign_currency_id", "itemized_expense_lines")
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          expense_lines: call("format_api_output_field_names",
                              get("/api/expense_lines",
                                  return_object: "shallow",
                                  limit: 1)&.compact)
        }
      end
    },

    get_expense_line_by_id: {
      subtitle: "Get expense line by ID",
      description: "Get <span class='provider'>expense line</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the expense line, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/expense_lines/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,


      input_fields: lambda do |object_definitions|
        object_definitions["expense_line_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["expense_line_get"].
          ignored("foreign_currency_id", "itemized_expense_lines")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/expense_lines",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_expense_line: {
      subtitle: "Create expense line",
      description: "Create <span class='provider'>expense line</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/expense_lines",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["expense_line_create"].
          ignored("accounting_total", "audit_status", "created_at",
                   "created_by", "expense_artifacts", "expense_attendee",
                   "expense_line_imported_data", "expense_line_mileage",
                   "expense_line_per_diem", "expense_line_preapproval",
                   "expense_line_taxes", "expense_report_id",
                   "external_src_data", "frugality", "id", "integration",
                   "line_number", "over_limit", "parent_expense_line_id",
                   "parent_external_src_data", "parent_external_src_name",
                   "parent_external_src_ref", "reporting_total",
                   "requires_receipt", "status", "suggested_exchange_rate",
                   "type", "updated_at", "updated_by").
          required("description", "expense_date")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["expense_line_get"].
          ignored("foreign_currency_id", "itemized_expense_lines")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/expense_lines",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_expense_line: {
      subtitle: "Update expense line",
      description: "Update <span class='provider'>expense line</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the expense line, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/expense_lines/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["expense_line_update"].
        ignored("accounting_total", "audit_status", "created_at",
                "created_by", "expense_artifacts", "expense_attendee",
                "expense_line_imported_data", "expense_line_mileage",
                "expense_line_per_diem", "expense_line_preapproval",
                "expense_line_taxes", "expense_report_id",
                "external_src_data", "frugality", "integration",
                "line_number", "over_limit", "parent_expense_line_id",
                "parent_external_src_data", "parent_external_src_name",
                "parent_external_src_ref", "reporting_total",
                "requires_receipt", "status", "suggested_exchange_rate",
                "type", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["expense_line_get"].
          ignored("foreign_currency_id", "itemized_expense_lines")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/expense_lines",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Expense report related actions
    search_expense_reports: {
      subtitle: "Search expense reports",
      description: "Search <span class='provider'>expense reports</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of expense reports (max 50).",

      execute: lambda do |_connection, input|
        {
          expense_reports: call("format_api_output_field_names",
                                get("/api/expense_reports", input)&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["expense_get"] .only("id", "status", "title")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "expense_reports",
          type: "array",
          of: "object",
          properties: object_definitions["expense_get"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          expense_reports: call("format_api_output_field_names",
                                get("/api/expense_reports", limit: 1)&.compact)
        }
      end
    },

    get_expense_report_by_id: {
      subtitle: "Get expense report by ID",
      description: "Get <span class='provider'>expense report</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the expense report, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/expense_reports/#{input['id']}")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["expense_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["expense_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/expense_reports", limit: 1)&.[](0)) || {}
      end
    },

    create_expense_report: {
      subtitle: "Create expense report",
      description: "Create <span class='provider'>expense report</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/expense_reports",
                        call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["expense_create"].
          ignored("approvals", "audit_score", "comments", "created_at",
                  "created_by", "currency", "events",
                  "expense_policy_violations", "expense_violations",
                  "exported", "id", "last_exported_at", "past_due",
                  "report_due_date", "status", "submitted_by", "total",
                  "updated_at", "updated_by")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["expense_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/expense_reports", limit: 1)&.[](0)) || {}
      end
    },

    update_expense_report: {
      subtitle: "Update expense report",
      description: "Update <span class='provider'>expense report</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the expense report, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/expense_reports/#{input['id']}",
                       call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["expense_update"].
          ignored("approvals", "audit_score", "comments", "created_at",
                  "created_by", "currency", "events",
                  "expense_policy_violations", "expense_lines",
                  "expense_violations", "exported", "last_exported_at",
                  "past_due", "report_due_date", "status", "submitted_by",
                  "total", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["expense_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/expense_reports", limit: 1)&.[](0)) || {}
      end
    },

    # Inventory transaction related actions
    search_inventory_transactions: {
      subtitle: "Search inventory transactions",
      description: "Search <span class='provider'>inventory " \
        "transactions</span> in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search criteria. " \
        "Leave empty to get a list of inventory transaction (max 50).",

      execute: lambda do |_connection, input|
        {
          inventory_transactions: call("format_api_output_field_names",
                                       get("/api/inventory_transactions",
                                           { return_object: "shallow" }.
                                           merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["inventory_transaction_get"].only("id", "status")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "inventory_transactions",
          type: "array",
          of: "object",
          properties: object_definitions["inventory_transaction_get"].
            ignored("currency", "from_warehouse", "receipt",
                    "receiving_form_response", "to_warehouse")
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          inventory_transactions: call("format_api_output_field_names",
                                       get("/api/inventory_transactions",
                                           return_object: "shallow",
                                           limit: 1)&.compact)
        }
      end
    },

    get_inventory_transaction_by_id: {
      subtitle: "Get inventory transaction by ID",
      description: "Get <span class='provider'>inventory transaction</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the inventory transaction, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/inventory_transactions/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["inventory_transaction_get"].
          only("id").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["inventory_transaction_get"].
          ignored("currency", "from_warehouse", "receipt",
                   "receiving_form_response", "to_warehouse")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/inventory_transactions",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_inventory_transaction: {
      subtitle: "Create inventory transaction",
      description: "Create <span class='provider'>inventory transaction" \
        "</span> in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/inventory_transactions",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["inventory_transaction_create"].
          ignored("asn_header", "asn_line", "asset_tags", "attachments",
                  "created_at", "created_by",
                  "current_integration_history_records", "id",
                  "last_exported_at", "receipts_batch_id", "updated_at",
                  "updated_by").
          required("rfid_tag", "quantity", "type")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["inventory_transaction_get"].
          only("account_allocations", "asset_tags", "attachments",
               "current_integration_history_records", "exported", "price",
               "total", "status")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/inventory_transactions",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Invoice related actions
    search_invoices: {
      subtitle: "Search invoices",
      description: "Search <span class='provider'>invoices</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of invoices (max 50).",

      execute: lambda do |_connection, input|
        {
          invoices: call("format_api_output_field_names",
                         get("/api/invoices", input)&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["invoice_get"].
          only("document_type", "exported", "id", "invoice_number", "paid",
               "reverse_charge_reference", "self_billing_reference", "series",
               "status")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "invoices",
          type: "array",
          of: "object",
          properties: object_definitions["invoice_get"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          invoices: call("format_api_output_field_names",
                         get("/api/invoices", limit: 1)&.compact)
        }
      end
    },

    get_invoice_by_id: {
      subtitle: "Get invoice by ID",
      description: "Get <span class='provider'>invoice</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the invoice, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/invoices/#{input['id']}")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["invoice_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["invoice_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/invoices", limit: 1)&.[](0)) || {}
      end
    },

    create_invoice: {
      subtitle: "Create invoice",
      description: "Create <span class='provider'>invoice</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/invoices",
                        call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      config_fields: [{
        name: "document_type",
        label: "Document type",
        default: "Invoice",
        control_type: "select",
        pick_list: "document_types",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "document_type",
          label: "Document type",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["invoice_create"].
          ignored("approvals", "attachments", "buyer_tax_registration",
                  "compliant", "confirmation", "created_at", "created_by",
                  "current_integration_history_records", "destination_country",
                  "discount_due_date", "dispute_reason", "exported",
                  "failed_tolerances", "folio_number", "form_of_payment",
                  "gross_total", "id", "image_scan", "image_scan_url",
                  "inbound_invoice", "invoice_from_address", "issuance_place",
                  "last_exported_at", "legal_destination_country",
                  "lock_version_key", "net_due_date", "origin_country",
                  "origin_currency_gross", "origin_currency_net",
                  "payment_method", "requested_by", "series",
                  "ship_from_address", "shipping_term", "status",
                  "supplier_created", "supplier_tax_registration",
                  "supplier_total", "tax_amount_engine",
                  "taxes_in_origin_country_currency", "tolerance_failures",
                  "total_with_taxes", "type_of_receipt", "updated_at",
                  "use_of_invoice", "updated_by").
          required("invoice_date", "invoice_number")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["invoice_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/invoices", limit: 1)&.[](0)) || {}
      end
    },

    update_invoice: {
      subtitle: "Update invoice",
      description: "Update <span class='provider'>invoice</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the invoice, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/invoices/#{input['id']}",
                       call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["invoice_update"].
          ignored("approvals", "attachments", "buyer_tax_registration",
                  "compliant", "confirmation", "created_at", "created_by",
                  "current_integration_history_records", "destination_country",
                  "discount_due_date", "dispute_reason", "document_type",
                  "exported", "failed_tolerances", "folio_number",
                  "form_of_payment", "gross_total", "image_scan",
                  "image_scan_url", "inbound_invoice", "invoice_from_address",
                  "issuance_place", "last_exported_at",
                  "legal_destination_country", "lock_version_key",
                  "net_due_date", "origin_country", "origin_currency_gross",
                  "origin_currency_net", "payment_method", "requested_by",
                  "series", "ship_from_address", "shipping_term", "status",
                  "supplier_created", "supplier_tax_registration",
                  "supplier_total", "tax_amount_engine",
                  "taxes_in_origin_country_currency", "tolerance_failures",
                  "total_with_taxes", "type_of_receipt", "updated_at",
                  "use_of_invoice", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["invoice_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/invoices", limit: 1)&.[](0)) || {}
      end
    },

    # item related actions
    search_items: {
      subtitle: "Search items",
      description: "Search <span class='provider'>items</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of items (max 50).",

      execute: lambda do |_connection, input|
        {
          items: call("format_api_output_field_names",
                            get("/api/items",
                                { return_object: "shallow" }.
                                merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["item"].
          only("active", "id", "description", "item_number", "name")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "items",
          type: "array",
          of: "object",
          properties: object_definitions["item_get"].
            ignored("connect_item_id", "image_url", "net_weight",
                    "net_weight_uom", "pack_qty", "pack_uom", "pack_weight",
                    "receive_catch_weight", "reorder_point", "use_pack_weight")
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          items: call("format_api_output_field_names",
                      get("/api/items",
                          return_object: "shallow",
                          limit: 1)&.compact)
        }
      end
    },

    get_item_by_id: {
      subtitle: "Get item by ID",
      description: "Get <span class='provider'>item</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the item, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/items/#{input['id']}", return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["item"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["item_get"].
          ignored("connect_item_id", "image_url", "net_weight",
                  "net_weight_uom", "pack_qty", "pack_uom", "pack_weight",
                  "receive_catch_weight", "reorder_point", "use_pack_weight")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/items", return_object: "shallow", limit: 1)&.[](0)) || {}
      end
    },

    create_item: {
      subtitle: "Create item",
      description: "Create <span class='provider'>item</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/items",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["item"].
          ignored("created_at", "created_by", "id", "reorder_alerts",
                  "updated_at", "updated_by").
          required("description", "name")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["item_get"].
          ignored("connect_item_id", "image_url", "net_weight",
                  "net_weight_uom", "pack_qty", "pack_uom", "pack_weight",
                  "receive_catch_weight", "reorder_point", "use_pack_weight")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/items", return_object: "shallow", limit: 1)&.[](0)) || {}
      end
    },

    update_item: {
      subtitle: "Update item",
      description: "Update <span class='provider'>item</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the item, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/items/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["item"].
          ignored("created_at", "created_by", "reorder_alerts", "updated_at",
                  "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["item_get"].
          ignored("connect_item_id", "image_url", "net_weight",
                  "net_weight_uom", "pack_qty", "pack_uom", "pack_weight",
                  "receive_catch_weight", "reorder_point", "use_pack_weight")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/items", return_object: "shallow", limit: 1)&.[](0)) || {}
      end
    },

    # Lookup value related actions
    search_lookup_values: {
      subtitle: "Search lookup values",
      description: "Search <span class='provider'>lookup values</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of lookup values (max 50).",

      execute: lambda do |_connection, input|
        {
          lookup_values: call("format_api_output_field_names",
                            get("/api/lookup_values",
                                { return_object: "shallow" }.
                                merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["lookup_value_get"].
          only("active", "id", "name", "external_ref_code", "external_ref_num")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "lookup_values",
          type: "array",
          of: "object",
          properties: object_definitions["lookup_value_get"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          lookup_values: call("format_api_output_field_names",
                              get("/api/lookup_values",
                                  return_object: "shallow",
                                  limit: 1)&.compact)
        }
      end
    },

    get_lookup_value_by_id: {
      subtitle: "Get lookup value by ID",
      description: "Get <span class='provider'>lookup value</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the lookup value, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/lookup_values/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["lookup_value_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["lookup_value_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/lookup_values",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_lookup_value: {
      subtitle: "Create lookup value",
      description: "Create <span class='provider'>lookup value</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/lookup_values",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["lookup_value_create"].
          ignored("created_at", "created_by", "depth", "external_ref_code ",
                  "id", "lookup_id", "updated_at", "updated_by").
          required("name")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["lookup_value_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/lookup_values",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_lookup_value: {
      subtitle: "Update lookup value",
      description: "Update <span class='provider'>lookup value</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the lookup value, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/lookup_values/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["lookup_value_update"].
          ignored("created_at", "created_by", "depth", "external_ref_code ",
                  "lookup_id", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["lookup_value_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/lookup_values",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Purchase Order related actions
    search_purchase_orders: {
      subtitle: "Search purchase orders",
      description: "Search <span class='provider'>purchase orders</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of purchase orders (max 50).",

      execute: lambda do |_connection, input|
        {
          purchase_orders: call("format_api_output_field_names",
                                get("/api/purchase_orders",
                                  { return_object: "shallow" }.
                                  merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].
          only("id", "exported", "po_number", "status")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "purchase_orders",
          type: "array",
          of: "object",
          properties: object_definitions["purchase_order_get"].
            ignored("currency", "requester", "transmission_status", "type")
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          purchase_orders: call("format_api_output_field_names",
                                get("/api/purchase_orders",
                                    return_object: "shallow",
                                    limit: 1)&.compact)
        }
      end
    },

    get_purchase_order_by_id: {
      subtitle: "Get purchase order by ID",
      description: "Get <span class='provider'>purchase order</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the purchase order, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/purchase_orders/#{input['id']}")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].
          ignored("currency", "requester", "transmission_status", "type")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/purchase_orders", limit: 1)&.[](0)) || {}
      end
    },

    cancel_purchase_order: {
      subtitle: "Cancel purchase order",
      description: "Cancel <span class='provider'>purchase order</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Cancels the purchase order, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/purchase_orders/#{input['id']}/cancel",
                       call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].
          ignored("currency", "requester", "transmission_status", "type")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/purchase_orders", limit: 1)&.[](0)) || {}
      end
    },

    close_purchase_order: {
      subtitle: "Close purchase order",
      description: "Close <span class='provider'>purchase order</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Closes the purchase order, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/purchase_orders/#{input['id']}/close",
                       call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].
          ignored("currency", "requester", "transmission_status", "type")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/purchase_orders", limit: 1)&.[](0)) || {}
      end
    },

    create_purchase_order: {
      subtitle: "Create purchase order",
      description: "Create <span class='provider'>purchase order</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Make sure the flag 'Enable External Orders' is set for " \
        "your Coupa instance, to create purchase order successfully.",

      execute: lambda do |_connection, input|
        response = post("/api/purchase_orders",
                        call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_create"].
          ignored("acknowledged_at", "coupa_accelerate_status", "created_at",
                  "created_by", "current_integration_history_records",
                  "exported", "id", "internal_revision", "invoice_stop",
                  "last_exported_at", "price_hidden", "requisition_header",
                  "status", "transmission_status", "updated_at", "updated_by").
          required("currency", "order_lines", "po_number", "ship_to_address",
                   "ship_to_user", "supplier", "supplier_site", "type")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].
          ignored("currency", "requester", "transmission_status", "type")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/purchase_orders", limit: 1)&.[](0)) || {}
      end
    },

    update_purchase_order: {
      subtitle: "Update purchase order",
      description: "Update <span class='provider'>purchase order</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the purchase order, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/purchase_orders/#{input['id']}",
                       call("format_api_input_field_names", input))
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_update"].
          ignored("acknowledged_at", "coupa_accelerate_status", "created_at",
                  "created_by", "current_integration_history_records",
                  "exported", "internal_revision", "invoice_stop",
                  "last_exported_at", "price_hidden", "requisition_header",
                  "status", "transmission_status", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].
          ignored("currency", "requester", "transmission_status", "type")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/purchase_orders", limit: 1)&.[](0)) || {}
      end
    },

    # Purchase Order Lines related actions
    search_purchase_order_lines: {
      subtitle: "Search purchase order lines",
      description: "Search <span class='provider'>purchase order " \
        "lines</span> in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of purchase order lines (max 50).",

      execute: lambda do |_connection, input|
        {
          purchase_order_lines: call("format_api_output_field_names",
                            get("/api/purchase_order_lines",
                                { return_object: "shallow" }.
                                merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_line"].
          only("description", "id", "invoice-stop", "order-header-id",
              "status", "type")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "purchase_order_lines",
          type: "array",
          of: "object",
          properties: object_definitions["purchase_order_line"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          purchase_order_lines: call("format_api_output_field_names",
                                     get("/api/purchase_order_lines",
                                         return_object: "shallow",
                                         limit: 1)&.compact)
        }
      end
    },

    get_purchase_order_line_by_id: {
      subtitle: "Get purchase order line by ID",
      description: "Get <span class='provider'>purchase order line</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the purchase order line, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/purchase_order_lines/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["purchase_order_line"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["purchase_order_line"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/purchase_order_lines",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Remit-To Address related actions
    get_remit_to_addresses_by_object_id: {
      subtitle: "Get remit-to addresses by object ID",
      description: "Get <span class='provider'>remit-to addresses</span> " \
        "by object ID in <span class='provider'>Coupa</span>",
      help: "Fetches all remit-to addresses, for the given supplier or " \
        "invoice ID (max 50).",

      execute: lambda do |_connection, input|
        {
          addresses: get("/api/#{input['object']}/#{input['object_id']}" \
            "/addresses", return_object: "shallow")&.compact
        }
      end,

      config_fields: [
        {
          name: "object",
          control_type: "select",
          pick_list: "remit_to_address_objects",
          optional: false
        },
        {
          name: "object_id",
          hint: "Enter corresponding supplier ID",
          optional: false,
          type: "integer"
        }
      ],

      output_fields: lambda do |object_definitions|
        [{
          name: "addresses",
          type: "array",
          of: "object",
          properties: object_definitions["remit_to_address_get"]
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          addresses: get("/api/#{input['object']}/#{input['object_id']}" \
            "/addresses",
                         return_object: "shallow",
                         limit: 1)&.compact
        }
      end
    },

    create_remit_to_address: {
      subtitle: "Create remit-to address",
      description: "Create <span class='provider'>remit-to address</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        object = input.delete("object")
        object_id = input.delete("object_id")
        post("/api/#{object}/#{object_id}/addresses", input).
          params(return_object: "shallow")
      end,

      config_fields: [
        {
          name: "object",
          default: "suppliers",
          control_type: "select",
          pick_list: "remit_to_address_objects",
          optional: false
        },
        {
          name: "object_id",
          hint: "Enter corresponding supplier ID.",
          optional: false,
          type: "integer"
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["remit_to_address_create"].
          ignored("created_at", "created_by", "id", "updated_at", "updated_by").
          required("city", "local_tax_number", "postal_code", "remit_to_code",
                   "street1")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["remit_to_address_get"]
      end,

      sample_output: lambda do |_connection, input|
        get("/api/#{input['object']}/#{input['object_id']}/addresses",
            return_object: "shallow",
            limit: 1)&.[](0) || {}
      end
    },

    update_remit_to_address: {
      subtitle: "Update remit-to address",
      description: "Update <span class='provider'>remit-to address" \
        "</span> in <span class='provider'>Coupa</span>",
      help: "Updates the remit-to address, that matches the given ID.",

      execute: lambda do |_connection, input|
        object = input.delete("object")
        object_id = input.delete("object_id")
        put("/api/#{object}/#{object_id}/addresses/#{input['id']}", input).
          params(return_object: "shallow")
      end,

      config_fields: [
        {
          name: "object",
          default: "suppliers",
          control_type: "select",
          pick_list: "remit_to_address_objects",
          optional: false
        },
        {
          name: "object_id",
          hint: "Enter corresponding supplier ID.",
          optional: false,
          type: "integer"
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["remit_to_address_update"].
          ignored("created_at", "created_by", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["remit_to_address_get"]
      end,

      sample_output: lambda do |_connection, input|
        get("/api/#{input['object']}/#{input['object_id']}/addresses",
            return_object: "shallow",
            limit: 1)&.[](0) || {}
      end
    },

    # Supplier related actions
    search_suppliers: {
      subtitle: "Search suppliers",
      description: "Search <span class='provider'>suppliers</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of suppliers (max 50).",

      execute: lambda do |_connection, input|
        {
          suppliers: call("format_api_output_field_names",
                          get("/api/suppliers",
                              { return_object: "shallow" }.
                              merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_get"].only("id", "name")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "suppliers",
          type: "array",
          of: "object",
          properties: object_definitions["supplier_get"].
            ignored("corporate_url", "currency_id", "cxml_http_password",
                    "hold_invoices_for_ap_review", "payment_term_id_for_api",
                    "supplier_status")
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          suppliers: call("format_api_output_field_names",
                          get("/api/suppliers",
                              return_object: "shallow",
                              limit: 1)&.compact)
        }
      end
    },

    get_supplier_by_id: {
      subtitle: "Get supplier by ID",
      description: "Get <span class='provider'>supplier</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the supplier, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/suppliers/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_get"].
          ignored("corporate_url", "currency_id", "cxml_http_password",
                  "hold_invoices_for_ap_review", "payment_term_id_for_api",
                  "supplier_status")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/suppliers",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_supplier: {
      subtitle: "Create supplier",
      description: "Create <span class='provider'>supplier</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/suppliers",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      config_fields: [
        {
          name: "po_method",
          label: "PO method",
          default: "email",
          control_type: "select",
          pick_list: "po_transmission_methods",
          optional: false,
          toggle_hint: "Select from list",
          toggle_field: {
            name: "po_method",
            label: "PO method ID",
            toggle_hint: "Use custom value",
            control_type: "text",
            type: "string"
          }
        },
        {
          name: "po_change_method",
          label: "PO change method",
          hint: "Purchase order change transmission method",
          default: "prompt",
          control_type: "select",
          pick_list: "po_transmission_methods",
          optional: false,
          toggle_hint: "Select from list",
          toggle_field: {
            name: "po_change_method",
            label: "PO change method",
            toggle_hint: "Use custom value",
            control_type: "text",
            type: "string"
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_create"].
          ignored("coupa_connect_secret", "created_at", "created_by",
                  "currency_id", "id", "status", "updated_at", "updated_by").
          required("name", "payment_method", "invoice_matching_level")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_get"].
          ignored("corporate_url", "currency_id", "cxml_http_password",
                  "hold_invoices_for_ap_review", "payment_term_id_for_api",
                  "supplier_status")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/suppliers",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_supplier: {
      subtitle: "Update supplier",
      description: "Update <span class='provider'>supplier</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the supplier, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/suppliers/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
      object_definitions["supplier_get"].
        ignored("coupa_connect_secret", "created_at", "created_by",
                "currency_id", "status", "updated_at", "updated_by").
        required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_get"].
          ignored("corporate_url", "currency_id", "cxml_http_password",
                  "hold_invoices_for_ap_review", "payment_term_id_for_api",
                  "supplier_status")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/suppliers",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Supplier information related actions
    search_supplier_information: {
      subtitle: "Search supplier information",
      description: "Search <span class='provider'>supplier information" \
        "</span> in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search criteria. " \
        "Leave empty to get a list of supplier information (max 50).",

      execute: lambda do |_connection, input|
        {
          supplier_information: call("format_api_output_field_names",
                                     get("/api/supplier_information",
                                         { return_object: "shallow" }.
                                         merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_information"].
          only("buyer_id", "comment", "display_name", "id", "name",
               "po_email", "status")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "supplier_information",
          type: "array",
          of: "object",
          properties: object_definitions["supplier_information"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          supplier_information: call("format_api_output_field_names",
                                     get("/api/supplier_information",
                                         return_object: "shallow",
                                         limit: 1)&.compact)
        }
      end
    },

    get_supplier_information_by_id: {
      subtitle: "Get supplier information by ID",
      description: "Get <span class='provider'>supplier information</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the supplier information, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/supplier_information/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_information"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_information"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/supplier_information",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Supplier item related actions
    search_supplier_items: {
      subtitle: "Search supplier items",
      description: "Search <span class='provider'>supplier items</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of supplier items (max 50).",

      execute: lambda do |_connection, input|
        {
          supplier_items: call("format_api_output_field_names",
                               get("/api/supplier_items",
                                   { return_object: "shallow" }.
                                   merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_item_get"].only("id", "supplier_part_num")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "supplier_items",
          type: "array",
          of: "object",
          properties: object_definitions["supplier_item_get"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          supplier_items: call("format_api_output_field_names",
                               get("/api/supplier_items",
                                   return_object: "shallow",
                                   limit: 1)&.compact)
        }
      end
    },

    get_supplier_item_by_id: {
      subtitle: "Get supplier item by ID",
      description: "Get <span class='provider'>supplier item</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the supplier item, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/supplier_items/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_item_get"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_item_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/supplier_items",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_supplier_item: {
      subtitle: "Create supplier item",
      description: "Create <span class='provider'>supplier item</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/supplier_items",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_item_create"].
          ignored("created_at", "created_by", "id", "updated_at",
                  "updated_by").
          required("price", "currency", "supplier_part_num")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_item_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/supplier_items",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_supplier_item: {
      subtitle: "Update supplier item",
      description: "Update <span class='provider'>supplier item</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the supplier item, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = put("/api/supplier_items/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_item_get"].
          ignored("created_at", "created_by", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_item_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/supplier_items",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # Supplier site related actions
    get_supplier_sites_by_supplier: {
      subtitle: "Get supplier sites by supplier ID",
      description: "Get <span class='provider'>supplier sites</span> " \
        "by supplier ID in <span class='provider'>Coupa</span>",
      help: "Fetches all supplier sites, for the given supplier (max 50).",

      execute: lambda do |_connection, input|
        {
          supplier_sites: call("format_api_output_field_names",
                               get("/api/suppliers/#{input['supplier']}" \
                                 "/supplier_sites",
                                   return_object: "shallow")&.compact)
        }
      end,

      config_fields: [{
        name: "supplier",
        label: "Supplier",
        optional: false,
        control_type: "select",
        pick_list: "suppliers",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "supplier",
          label: "Supplier ID",
          toggle_hint: "Use custom value",
          control_type: "number",
          type: "integer"
        }
      }],

      output_fields: lambda do |object_definitions|
        [{
          name: "supplier_sites",
          type: "array",
          of: "object",
          properties: object_definitions["supplier_site_get"]
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          supplier_sites: call("format_api_output_field_names",
                               get("/api/suppliers/#{input['supplier']}" \
                                 "/supplier_sites",
                                   return_object: "shallow",
                                   limit: 1)&.compact)
        }
      end
    },

    create_supplier_site: {
      subtitle: "Create supplier site",
      description: "Create <span class='provider'>supplier site</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        supplier = input.delete("supplier")
        response = post("/api/suppliers/#{supplier}/supplier_sites",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      config_fields: [
        {
          name: "supplier",
          label: "Supplier",
          optional: false,
          control_type: "select",
          pick_list: "suppliers",
          toggle_hint: "Select from list",
          toggle_field: {
            name: "supplier",
            label: "Supplier ID",
            toggle_hint: "Use custom value",
            control_type: "number",
            type: "integer"
          }
        },
        {
          name: "po_method",
          label: "PO method",
          default: "email",
          control_type: "select",
          pick_list: "po_transmission_methods",
          optional: false,
          toggle_hint: "Select from list",
          toggle_field: {
            name: "po_method",
            label: "PO method ID",
            toggle_hint: "Use custom value",
            control_type: "number",
            type: "integer"
          }
        },
        {
          name: "po_change_method",
          label: "PO change method",
          hint: "Purchase order change transmission method",
          default: "prompt",
          control_type: "select",
          pick_list: "po_transmission_methods",
          optional: false,
          toggle_hint: "Select from list",
          toggle_field: {
            name: "po_change_method",
            label: "PO change method ID",
            toggle_hint: "Use custom value",
            control_type: "number",
            type: "integer"
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_site_create"].
          ignored("created_at", "created_by", "id", "updated_at", "updated_by").
          required("code", "name")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_site_get"]
      end,

      sample_output: lambda do |_connection, input|
        call("format_api_output_field_names",
             get("/api/suppliers/#{input['supplier']}/supplier_sites",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_supplier_site: {
      subtitle: "Update supplier site",
      description: "Update <span class='provider'>supplier site</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the supplier site, that matches the given ID.",

      execute: lambda do |_connection, input|
        supplier = input.delete("supplier")
        response = put("/api/suppliers/#{supplier}/supplier_sites" \
                     "/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      config_fields: [{
        name: "supplier",
        label: "Supplier",
        optional: false,
        control_type: "select",
        pick_list: "suppliers",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "supplier",
          label: "Supplier ID",
          toggle_hint: "Use custom value",
          control_type: "number",
          type: "integer"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["supplier_site_update"].
          ignored("created_at", "created_by", "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_site_get"]
      end,

      sample_output: lambda do |_connection, input|
        call("format_api_output_field_names",
             get("/api/suppliers/#{input['supplier']}/supplier_sites",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    # User related actions
    search_users: {
      subtitle: "Search users",
      description: "Search <span class='provider'>users</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Search will return results that match all your search " \
        "criteria. Leave empty to get a list of users (max 50).",

      execute: lambda do |_connection, input|
        {
          users: call("format_api_output_field_names",
                      get("/api/users",
                          { return_object: "shallow" }.
                          merge(input))&.compact)
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["user"].
          only("email", "employee_number", "fullname", "id", "login")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "users",
          type: "array",
          of: "object",
          properties: object_definitions["user_get"].
            ignored("approval_limit", "generate_password_and_notify",
                    "invoice_self_approval_limit", "password",
                    "salesforce_enabled", "self_approval_limit")
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          users: call("format_api_output_field_names",
                      get("/api/users",
                          return_object: "shallow",
                          limit: 1)&.compact)
        }
      end
    },

    get_user_by_id: {
      subtitle: "Get user by ID",
      description: "Get <span class='provider'>user</span> " \
        "by ID in <span class='provider'>Coupa</span>",
      help: "Fetches the user, that matches the given ID.",

      execute: lambda do |_connection, input|
        response = get("/api/users/#{input['id']}",
                       return_object: "shallow")
        call("format_api_output_field_names", response.compact)
      end,

      input_fields:    lambda do |object_definitions|
        object_definitions["user"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user_get"].
          ignored("approval_limit", "generate_password_and_notify",
                  "invoice_self_approval_limit", "password",
                  "salesforce_enabled", "self_approval_limit")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/users",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    create_user: {
      subtitle: "Create user",
      description: "Create <span class='provider'>user</span> " \
        "in <span class='provider'>Coupa</span>",

      execute: lambda do |_connection, input|
        response = post("/api/users",
                        call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["user"].
          ignored("avatar_thumb_url", "can_expense_for", "created_at",
                  "created_by", "expenses_delegated_to", "fullname", "id",
                  "updated_at", "updated_by").
          required("email", "firstname", "lastname", "login")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user_get"].
          ignored("approval_limit", "generate_password_and_notify",
                  "invoice_self_approval_limit", "password",
                  "salesforce_enabled", "self_approval_limit")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/users",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    update_user: {
      subtitle: "Update user",
      description: "Update <span class='provider'>user</span> " \
        "in <span class='provider'>Coupa</span>",
      help: "Updates the user, that matches the given ID.",

      execute: lambda do |_connection, input|
        input["roles"] = nil if [nil, "null", "nil"].
                                include?(input.dig("roles", 0, "id"))
        response = put("/api/users/#{input['id']}",
                       call("format_api_input_field_names", input)).
                   params(return_object: "shallow")
        call("format_api_output_field_names", response&.compact)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["user"].
          ignored("avatar_thumb_url", "can_expense_for", "created_at",
                  "created_by", "expenses_delegated_to", "fullname",
                  "updated_at", "updated_by").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user_get"].
          ignored("approval_limit", "generate_password_and_notify",
                  "invoice_self_approval_limit", "password",
                  "salesforce_enabled", "self_approval_limit")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/users",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    }
  },

  triggers: {
    new_inventory_transaction: {
      subtitle: "New inventory transaction",
      description: "New <span class='provider'>inventory transaction" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get inventory transactions created since given date/time. " \
            "Leave empty to get inventory transactions created one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/inventory_transactions",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |inventory_transaction|
        inventory_transaction["id"].to_s
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["inventory_transaction_get"].
          ignored("currency", "from_warehouse", "receipt",
                  "receiving_form_response", "to_warehouse")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/inventory_transactions",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_address: {
      subtitle: "New or updated address",
      description: "New or updated <span class='provider'>address" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get addresses created or updated since given " \
            "date/time. Leave empty to get addresses " \
            "created or updated  one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = get("/api/addresses",
                       "return_object": "shallow",
                       "updated_at[gt_or_eq]": updated_since,
                       "offset": offset,
                       "limit": page_size)&.compact
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |address|
        address["id"].to_s + "@" + address["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["address_get"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/api/addresses", return_object: "shallow", limit: 1)&.[](0) || {}
      end
    },

    new_or_updated_contract: {
      subtitle: "New or updated contract",
      description: "New or updated <span class='provider'>contract" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get contracts created or updated since given " \
            "date/time. Leave empty to get contracts " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/contracts",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |contract|
        contract["id"].to_s + "@" + contract["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["contract_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/contracts",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_department: {
      subtitle: "New or updated department",
      description: "New or updated <span class='provider'>department</span> " \
        "in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get departments created or updated since given date/time. " \
            "Leave empty to get departments created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/departments",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |department|
        department["id"].to_s + "@" + department["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["department"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/departments",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_exchange_rate: {
      subtitle: "New or updated exchange rate",
      description: "New or updated <span class='provider'>exchange " \
        "rate</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get exchange rates created or updated since given " \
            "date/time. Leave empty to get exchange rates " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/exchange_rates",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)

        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |exchange_rate|
        exchange_rate["id"].to_s + "@" + exchange_rate["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["exchange_rate_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/exchange_rates",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_expense_report: {
      subtitle: "New or updated expense report",
      description: "New or updated <span class='provider'>expense report" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get expense reports created or updated since given " \
            "date/time. Leave empty to get expense reports " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 10 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/expense_reports",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |expense_report|
        expense_report["id"].to_s + "@" + expense_report["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["expense_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/expense_reports", limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_invoice: {
      subtitle: "New or updated invoice",
      description: "New or updated <span class='provider'>invoice" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get invoices created or updated since given " \
            "date/time. Leave empty to get invoices " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 10 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/invoices",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: ->(invoice) { invoice["id"].to_s + "@" + invoice["updated_at"] },

      output_fields: lambda do |object_definitions|
        object_definitions["invoice_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/invoices", limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_lookup_value: {
      subtitle: "New or updated lookup value",
      description: "New or updated <span class='provider'>lookup value" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get lookup values created or updated since given " \
            "date/time. Leave empty to get lookup values " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/lookup_values",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |lookup_value|
        lookup_value["id"].to_s + "@" + lookup_value["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["lookup_value_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/lookup_values",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_purchase_order: {
      subtitle: "New or updated purchase order",
      description: "New or updated <span class='provider'>purchase order" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get purchase orders created or updated since given " \
            "date/time. Leave empty to get purchase orders " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 10 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/purchase_orders",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |purchase_order|
        purchase_order["id"].to_s + "@" + purchase_order["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["purchase_order_get"].
          ignored("currency", "requester", "transmission_status", "type")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/purchase_orders", limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_remit_to_address: {
      subtitle: "New or updated remit-to address",
      description: "New or updated <span class='provider'>remit-to " \
        "address</span> in <span class='provider'>Coupa</span>",

      config_fields: [
        {
          name: "object",
          default: "supplier",
          control_type: "select",
          pick_list: [["Supplier", "suppliers"]],
          optional: false
        },
        {
          name: "object_id",
          hint: "Enter ID of corresponding supplier or invoice",
          optional: false,
          type: "integer"
        }
      ],

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get remit-to addresses created or updated since " \
            "given date/time. Leave empty to get remit-to addresses " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = get("/api/#{input['object']}/#{input['object_id']}" \
                     "/addresses",
                       "return_object": "shallow",
                       "updated_at[gt_or_eq]": updated_since,
                       "offset": offset,
                       "limit": page_size)&.compact
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |remit_to_address|
        remit_to_address["id"].to_s + "@" + remit_to_address["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["remit_to_address_get"]
      end,

      sample_output: lambda do |_connection, input|
        get("/api/#{input['object']}/#{input['object_id']}" \
          "/addresses",
            return_object: "shallow",
            limit: 1)&.[](0) || {}
      end
    },

    new_or_updated_supplier: {
      subtitle: "New or updated supplier",
      description: "New or updated <span class='provider'>supplier" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get suppliers created or updated since given " \
            "date/time. Leave empty to get suppliers " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/suppliers",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |supplier|
        supplier["id"].to_s + "@" + supplier["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_get"].
          ignored("corporate_url", "currency_id", "cxml_http_password",
                  "hold_invoices_for_ap_review", "payment_term_id_for_api",
                  "supplier_status")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/suppliers",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_supplier_information: {
      subtitle: "New or updated supplier information",
      description: "New or updated <span class='provider'>" \
        "supplier information</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get supplier information created or updated since given " \
            "date/time. Leave empty to get supplier information " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/supplier_information",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |supplier_info|
        supplier_info["id"].to_s + "@" + supplier_info["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_information"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/supplier_information",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_supplier_item: {
      subtitle: "New or updated supplier item",
      description: "New or updated <span class='provider'>supplier item" \
        "</span> in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get supplier items created or updated since given " \
            "date/time. Leave empty to get supplier items " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/supplier_items",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |supplier_item|
        supplier_item["id"].to_s + "@" + supplier_item["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_item_get"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/supplier_items",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_supplier_site: {
      subtitle: "New or updated supplier site",
      description: "New or updated <span class='provider'>" \
        "supplier site</span> in <span class='provider'>Coupa</span>",

      config_fields: [{
        name: "supplier",
        label: "Supplier",
        optional: false,
        control_type: "select",
        pick_list: "suppliers",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "supplier",
          label: "Supplier ID",
          toggle_hint: "Use custom value",
          control_type: "number",
          type: "integer"
        }
      }],

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get supplier sites created or updated since " \
            "given date/time. Leave empty to get supplier sites " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/suppliers/#{input['supplier']}" \
                          "/supplier_sites",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |supplier_site|
        supplier_site["id"].to_s + "@" + supplier_site["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supplier_site_get"]
      end,

      sample_output: lambda do |_connection, input|
        call("format_api_output_field_names",
             get("/api/suppliers/#{input['supplier']}/supplier_sites",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },

    new_or_updated_user: {
      subtitle: "New or updated user",
      description: "New or updated <span class='provider'>user</span> " \
        "in <span class='provider'>Coupa</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get users created or updated since given " \
            "date/time. Leave empty to get users " \
            "created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50 # max is 50 for page_size in Coupa
        updated_since = (closure&.[](1) || input["since"] || 1.hour.ago).
                        to_time.utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/users",
                            "return_object": "shallow",
                            "updated_at[gt_or_eq]": updated_since,
                            "offset": offset,
                            "limit": page_size)&.compact)
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end

        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: ->(user) { user["id"].to_s + "@" + user["updated_at"] },

      output_fields: lambda do |object_definitions|
        object_definitions["user_get"].
          ignored("approval_limit", "generate_password_and_notify",
                  "invoice_self_approval_limit", "password",
                  "salesforce_enabled", "self_approval_limit")
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/users",
                 return_object: "shallow",
                 limit: 1)&.[](0)) || {}
      end
    },
  },

  pick_lists: {
    accelerate_statuses: ->(_connection) { [%w[Accelerated accelerated]] },

    accounts: lambda do |_connection|
      get_all_paginated_accounts = lambda do |input|
        page_size = 50 # max is 50 for page_size in Coupa
        url = input["url"]
        display_value = input["display_value"]
        id_value = input["id_value"]

        list = []
        offset = 0
        more_pages = true

        while (more_pages && list.size < 950 ) do
          response = get(url,
                         return_object: "shallow",
                         offset: offset,
                         limit: page_size) || []

          list.concat(response.map do |account|
                        [account["name"].blank? ? account["code"] :
                        account["name"], account["id"]]
                      end)
          more_pages = response.size >= page_size
          offset = offset + response.size
        end
        list
      end

      closure = { "url" => "/api/accounts" }
      get_all_paginated_accounts[closure]
    end,

    account_types: lambda do |_connection|
      closure = {
        "url"           => "/api/account_types",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    addresses: lambda do |_connection|
      closure = {
        "url"           => "/api/addresses",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    all_countries: lambda do |_connection|
      [%w[United\ States 223], %w[Afghanistan 2], %w[Albania 3],
       %w[Algeria 4], %w[American\ Samoa 5], %w[Andorra 6],
       %w[Angola 7], %w[Anguilla 8], %w[Antarctica 9],
       %w[Antigua\ &\ Barbuda 10], %w[Argentina 11], %w[Armenia 12],
       %w[Aruba 13], %w[Australia 14], %w[Austria 15],
       %w[Azerbaijan 16], %w[Bahamas 17], %w[Bahrain 18],
       %w[Bangladesh 19], %w[Barbados 20], %w[Belarus 21],
       %w[Belgium 22], %w[Belize 23], %w[Benin 24], %w[Bermuda 25],
       %w[Bhutan 26], %w[Bolivia \ Plurinational\ State\ Of 27],
       %w[Bosnia\ &\ Herzegovina 28], %w[Botswana 29],
       %w[Bouvet\ Island 30], %w[Brazil 31],
       %w[British\ Indian\ Ocean\ Territory 32], %w[Brunei\ Darussalam 33],
       %w[Bulgaria 34], %w[Burkina\ Faso 35], %w[Burundi 36],
       %w[Cambodia 37], %w[Cameroon 38], %w[Canada 39], %w[Cape\ Verde 40],
       %w[Cayman\ Islands 41], %w[Central\ African\ Republic 42],
       %w[Chad 43], %w[Chile 44], %w[China 45], %w[Christmas\ Island 46],
       %w[Cocos\ (Keeling)\ Islands 47], %w[Colombia 48], %w[Comoros 49],
       %w[Congo 50], %w[Cook\ Islands 51], %w[Costa\ Rica 52], %w[Croatia 53],
       %w[Cuba 54], %w[Cyprus 55], %w[Czech\ Republic 56], %w[Denmark 58],
       %w[Djibouti 59], %w[Dominica 60], %w[Dominican\ Republic 61],
       %w[Timor-Leste 62], %w[Ecuador 63], %w[Egypt 64], %w[El\ Salvador 65],
       %w[Equatorial\ Guinea 66], %w[Estonia 67], %w[Ethiopia 68],
       %w[Falkland\ Islands\ (Malvinas) 69], %w[Faroe\ Islands 70],
       %w[Fiji 71], %w[Finland 72], %w[France 73],
       %w[France\ (European\ Ter.) 74], %w[French\ Southern\ Territories 75],
       %w[Gabon 76], %w[Gambia 77], %w[Georgia 78], %w[Germany 79],
       %w[Ghana 80], %w[Gibraltar 81], %w[Greece 83], %w[Greenland 84],
       %w[Grenada 85], %w[Guadeloupe 86], %w[Guam 87], %w[Guatemala 88],
       %w[French\ Guiana 89], %w[Guinea 90], %w[Guinea-Bissau 91],
       %w[Guyana 92], %w[Haiti 93],
       %w[Heard\ Island\ &\ Mcdonald\ Islands 94], %w[Honduras 95],
       %w[Hong\ Kong 96], %w[Hungary 97], %w[Iceland 98], %w[India 99],
       %w[Indonesia 100], %w[Iran \ Islamic\ Republic\ Of 101], %w[Iraq 102],
       %w[Ireland 103], %w[Israel 104], %w[Italy 105], %w[Côte\ D'ivoire 106],
       %w[Jamaica 107], %w[Japan 108], %w[Jordan 109], %w[Kazakhstan 110],
       %w[Kenya 111], %w[Kiribati 112],
       %w[Korea \ Democratic\ People's\ Republic\ Of 113],
       %w[Korea \ Republic\ Of 114], %w[Kosovo 259], %w[Kuwait 115],
       %w[Kyrgyzstan 116], %w[Lao\ People's\ Democratic\ Republic 117],
       %w[Latvia 118], %w[Lebanon 119], %w[Lesotho 120], %w[Liberia 121],
       %w[Libyan\ Arab\ Jamahiriya 122], %w[Liechtenstein 123],
       %w[Lithuania 124]]
    end,

    attachment_objects: lambda do |_connection|
      [%w[Contracts contracts], %w[Invoices invoices],
       %w[Expenses expense_reports], %w[Purchase\ orders purchase_orders],
       %w[Requisitions requisitions], %w[Users users]]
    end,

    approval_limits: lambda do |_connection|
      closure = {
        "url"           => "/api/approval_limits",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    asn_headers: lambda do |_connection|
      closure = {
        "url"           => "/api/asn/headers",
        "display_value" => "asn-number",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    audit_statuses: lambda do |_connection|
      [["Verified receipt online", "Verified Receipt Online"],
       ["Verified unattached receipt", "Verified Unattached Receipt"],
       ["Waiting for receipt", "Waiting for Receipt"],
       ["No receipt required", "No Receipt Required"],
       ["Approved without receipt", "Approved Without Receipt"]]
    end,

    content_groups: lambda do |_connection|
      closure = {
        "url"           => "/api/business_groups",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    contract_terms: lambda do |_connection|
      closure = {
        "url"           => "/api/contract_terms",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    contract_types: lambda do |_connection|
      [%w[Master\ contract MasterContract],
       %w[Amendment\ contract AmendmentContract]]
    end,

    contracts: lambda do |_connection|
      closure = {
        "url"           => "/api/contracts",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    comments: lambda do |_connection|
      closure = {
        "url"           => "/api/comments",
        "display_value" => "name",
        "id_value" => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    commodities: lambda do |_connection|
      closure = {
        "url"           => "/api/commodities",
        "display_value" => "name",
        "id_value" => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    consents: lambda do |_connection|
      [%w[Notice notice], %w[Consent consent],
       %w[Not\ required not_required], %w[Not\ assignable not_assignable]]
    end,

    countries: lambda do |_connection|
      [%w[Australia AU], %w[Austria AT], %w[Belgium BE],
       %w[Brazil BR], %w[Bulgaria BG], %w[Canada CA],
       %w[Croatia HR], %w[Cyprus CY], %w[Czech\ Republic CZ],
       %w[Denmark DK], %w[Estonia EE], %w[Finland FI],
       %w[France FR], %w[Germany DE], %w[United\ Kingdom GB],
       %w[Greece GR], %w[Hong\ Kong HK], %w[Hungary HU],
       %w[Iceland IS], %w[Ireland IE], %w[Israel IL],
       %w[Italy IT], %w[Japan JP], %w[Latvia LV],
       %w[Liechtenstein LI], %w[Lithuania LT], %w[Luxembourg LU],
       %w[Malta MT], %w[Mexico MX], %w[Monaco MC],
       %w[Morocco MA], %w[Netherlands NL], %w[New\ Zealand NZ],
       %w[Norway NO], %w[Poland PL], %w[Portugal PT],
       %w[Qatar QA], %w[Romania RO], %w[Saudi\ Arabia SA],
       %w[Singapore SG], %w[Slovakia SK], %w[Slovenia SI],
       %w[South\ Africa ZA], %w[Spain ES], %w[Sweden SE],
       %w[Switzerland CH], %w[United\ Arab\ Emirates AE], %w[United\ States US],
       %w[Isle\ Of\ Man IM]]
    end,

    currencies: lambda do |_connection|
      closure = {
        "url"           => "/api/currencies",
        "display_value" => "code",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    default_locales: lambda do |_connection|
      [%w[en en], %w[tr tr],  %w[ja ja], %w[bg bg],
       %w[cs cs], %w[es es],  %w[da da], %w[de-AT de-AT],
       %w[de-BE de-BE], %w[de-CH de-CH], %w[de-LU de-LU], %w[de de],
       %w[el el], %w[en-AU en-AU], %w[en-CA en-CA], %w[en-GB en-GB],
       %w[en-HK en-HK], %w[en-IE en-IE], %w[en-IN en-IN], %w[en-MT en-MT],
       %w[en-MY en-MY], %w[en-NZ en-NZ], %w[en-SG en-SG], %w[en-ZA en-ZA],
       %w[es-CO es-CO], %w[es-MX es-MX], %w[es-PR es-PR], %w[et et],
       %w[fi fi], %w[fr-BE fr-BE], %w[fr-CA fr-CA], %w[fr-CH fr-CH],
       %w[fr-LU fr-LU],  %w[fr fr], %w[hr hr], %w[hu hu],
       %w[it-CH it-CH],  %w[it it], %w[ko ko], %w[lt lt],
       %w[lv lv],  %w[mt mt],  %w[nl-BE nl-BE],  %w[nl nl],
       %w[no no],  %w[pl pl],  %w[pt-BR pt-BR],  %w[pt pt],
       %w[ro ro],  %w[ru ru],  %w[sk sk], %w[sl sl],
       %w[sr sr], %w[sv sv], %w[zh-CN zh-CN], %w[zh-HK zh-HK],
       %w[zh-TW zh-TW], %w[en-ZZ en-ZZ], %w[en en], %w[tr tr],
       %w[ja ja], %w[bg bg], %w[cs cs], %w[es es],
       %w[da da], %w[de-AT de-AT], %w[de-BE de-BE], %w[de-CH de-CH],
       %w[de-LU de-LU], %w[de de], %w[el el], %w[en-AU en-AU],
       %w[en-CA en-CA], %w[en-GB en-GB], %w[en-HK en-HK], %w[en-IE en-IE],
       %w[en-IN en-IN], %w[en-MT en-MT], %w[en-MY en-MY], %w[en-NZ en-NZ],
       %w[en-SG en-SG], %w[en-ZA en-ZA], %w[es-CO es-CO], %w[es-MX es-MX],
       %w[es-PR es-PR], %w[et et], %w[fi fi], %w[fr-BE fr-BE],
       %w[fr-CA fr-CA], %w[fr-CH fr-CH], %w[fr-LU fr-LU], %w[fr fr],
       %w[hr hr], %w[hu hu], %w[it-CH it-CH], %w[it it],
       %w[ko ko], %w[lt lt], %w[lv lv], %w[mt mt],
       %w[nl-BE nl-BE], %w[nl nl], %w[no no], %w[pl pl],
       %w[pt-BR pt-BR], %w[pt pt], %w[ro ro], %w[ru ru],
       %w[sk sk], %w[sl sl], %w[sr sr], %w[sv sv],
       %w[zh-CN zh-CN], %w[zh-HK zh-HK], %w[zh-TW zh-TW], %w[en-ZZ en-ZZ]]
    end,

    departments: lambda do |_connection|
      closure = {
        "url"           => "/api/departments",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    document_types: lambda do |_connection|
      [%w[Invoice Invoice], %w[Credit\ note Credit\ Note]]
    end,

    expense_categories: lambda do |_connection|
      closure = {
        "url"           => "/api/expense_categories",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    frugalities: ->(_connection) { [%w[Shame shame], %w[Praise praise]] },

    inventory_types: lambda do |_connection|
      [%w[Inventory\ receipt InventoryReceipt],
       %w[Receiving\ consumption ReceivingConsumption],
       %w[Receiving\ return\ to\ supplier ReceivingReturnToSupplier],
       %w[Receiving\ disposal ReceivingDisposal]]
    end,

    invoice_line_types: lambda do |_connection|
      [%w[Quantity\ line InvoiceQuantityLine],
       %w[Amount\ line InvoiceAmountLine]]
    end,

    invoice_matching_levels: lambda do |_connection|
      [%w[2\ way 2-way], %w[3\ way 3-way],
       %w[3\ way\ direct 3-way-direct], %w[None none]]
    end,

    items: lambda do |_connection|
      closure = {
        "url"           => "/api/items",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    lookup_values: lambda do |_connection|
      closure = {
        "url"           => "/api/lookup_values",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    lookups: lambda do |_connection|
      closure = {
        "url"           => "/api/lookups",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    match_types: ->(_connection) { [%w[Direct\ matching direct_matching]] },

    order_types: lambda do |_connection|
      [%w[External\ order\ header ExternalOrderHeader]]
    end,

    payment_methods: lambda do |_connection|
      [%w[Invoice invoice], %w[PCard pcard], %w[Invoice\ only invoice_only],
       %w[PCard\ only pcard_only]]
    end,

    payment_terms: lambda do |_connection|
      closure = {
        "url"           => "/api/payment_terms",
        "display_value" => "code",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    periods: lambda do |_connection|
      closure = {
        "url"           => "/api/periods",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    po_transmission_methods: lambda do |_connection|
      [%w[cXML cxml], %w[XML xml], %w[Email email], %w[Prompt prompt],
       %w[Mark\ as\ sent mark_as_sent], %w[Buy\ online buy_online]]
    end,

    receipts: lambda do |_connection|
      closure = {
        "url"           => "/api/receipts",
        "display_value" => "receipt-date",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    remit_to_address_objects: lambda do |_connection|
      [%w[Suppliers suppliers]]
    end,

    requisitions: lambda do |_connection|
      closure = {
        "url"           => "/api/requisitions",
        "display_value" => "id",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    roles: lambda do |_connection|
      closure = {
        "url"           => "/api/roles",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    security_types: ->(_connection) { [[0, 0], [1, 1]] },

    service_types: ->(_connection) { [%w[Non\ service non_service]] },

    shipping_terms: lambda do |_connection|
      closure = {
        "url"           => "/api/shipping_terms",
        "display_value" => "code",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    suppliers: lambda do |_connection|
      closure = {
        "url"           => "/api/suppliers",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    system_catalogs: lambda do |_connection|
      [%w[Cat\ base CatBase], %w[Elastic Elastic],
       %w[iPartner iPartner], %w[Product Product],
       %w[Suite Suite], %w[Claritum Claritum],
       %w[Contalog Contalog], %w[Catalog\ n\ Time CatalognTime],
       %w[Advizia Advizia], %w[Aravo Aravo],
       %w[Matrix\ CMX MatrixCMX], %w[Sigma\ commerce SigmaCommerce]]
    end,

    tax_codes: lambda do |_connection|
      closure = {
        "url"           => "/api/tax_codes",
        "display_value" => "code",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    tax_registrations: lambda do |_connection|
      closure = {
        "url"           => "/api/tax_registrations",
        "display_value" => "number",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    term_types: lambda do |_connection|
      [%w[Fixed fixed], %w[Auto\ renew Auto_renew], %w[Perpetual perpetual]]
    end,

    transmission_statuses: lambda do |_connection|
      [%w[Created created], %w[Deferred deferred],
       %w[Deferred\ processing deferred_processing],
       %w[Pending\ manual pending_manual],
       %w[Pending\ manual\ cancel pending_manual_cancel],
       %w[Awaiting\ online\ purchase awaiting_online_purchase],
       %w[Scheduled\ for\ email scheduled_for_email],
       %w[Sent\ via\ email sent_via_email],
       %w[Scheduled\ for\ cXML scheduled_for_cxml],
       %w[Scheduled\ for\ XML scheduled_for_xml],
       %w[Sent\ via\ cXML sent_via_cxml],
       %w[Sent\ via\ XML sent_via_xml],
       %w[Sent\ manually sent_manually],
       %w[Purchased\ online purchased_online],
       %w[Transmission\ failure transmission_failure]]
    end,

    units: ->(_connection) { [%w[Days days], %w[Years years]] },

    uoms: lambda do |_connection|
      closure = {
        "url"           => "/api/uoms",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    users: lambda do |_connection|
      closure = {
        "url"           => "/api/users",
        "display_value" => "fullname",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    user_groups: lambda do |_connection|
      closure = {
        "url"           => "/api/user_groups",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    warehouses: lambda do |_connection|
      closure = {
        "url"           => "/api/warehouses",
        "display_value" => "name",
        "id_value"      => "id"
      }
      call("get_all_paginated_values", closure)
    end,

    yes_or_no_options: ->(_connection) { [%w[Yes Yes], %w[No No]] }
  }
}
