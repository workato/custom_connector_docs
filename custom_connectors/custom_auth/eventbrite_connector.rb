{
  title: "Eventbrite (custom)",

  connection: {
    fields: [
      {
        name: "personal_token",
        control_type: "password",
        hint: "Find your personal token here: https://www.eventbrite.com/myaccount/apps/"
        optional: false
      }
    ],

    authorization: {
      type: "custom_auth",

      apply: lambda do |connection|
        headers("Authorization": "Bearer #{connection["personal_token"]}")
      end
    },

    base_uri: lambda do
      "https://www.eventbriteapi.com"
    end
  },

  test: lambda do
    get("/v3/users/me")
  end,

  actions: {
    get_sales_report: {
      execute: lambda do |connection, input|
        get("/v3/reports/sales", input)
      end,

      input_fields: lambda do |object_definition|
        [
          {
            name: "event_status",
            control_type: "select",
            pick_list: [
              ["All", "all"],
              ["Live", "live"],
              ["Ended", "ended"]
            ],
            optional: false
          }
        ]
      end,

      output_fields: lambda do |object_definition|
        object_definition["sales_report"]
      end
    }
  },

  object_definitions: {
    sales_report: {
      fields: lambda do
        [
          {
            "control_type": "text",
            "label": "Timezone",
            "type": "string",
            "name": "timezone"
          },
          {
            "name": "event_ids",
            "type": "array",
            "of": "string",
            "control_type": "text",
            "label": "Event ids"
          },
          {
            "name": "data",
            "type": "array",
            "of": "object",
            "label": "Data",
            "properties": [
              {
                "control_type": "text",
                "label": "Date",
                "render_input": "date_time_conversion",
                "parse_output": "date_time_conversion",
                "type": "date_time",
                "name": "date"
              },
              {
                "control_type": "text",
                "label": "Date localized",
                "render_input": "date_time_conversion",
                "parse_output": "date_time_conversion",
                "type": "date_time",
                "name": "date_localized"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Currency",
                    "type": "string",
                    "name": "currency"
                  },
                  {
                    "control_type": "text",
                    "label": "Gross",
                    "type": "string",
                    "name": "gross"
                  },
                  {
                    "control_type": "text",
                    "label": "Net",
                    "type": "string",
                    "name": "net"
                  },
                  {
                    "control_type": "number",
                    "label": "Quantity",
                    "parse_output": "float_conversion",
                    "type": "number",
                    "name": "quantity"
                  },
                  {
                    "control_type": "text",
                    "label": "Fees",
                    "type": "string",
                    "name": "fees"
                  }
                ],
                "label": "Totals",
                "type": "object",
                "name": "totals"
              }
            ]
          },
          {
            "properties": [
              {
                "control_type": "text",
                "label": "Currency",
                "type": "string",
                "name": "currency"
              },
              {
                "control_type": "text",
                "label": "Gross",
                "type": "string",
                "name": "gross"
              },
              {
                "control_type": "text",
                "label": "Net",
                "type": "string",
                "name": "net"
              },
              {
                "control_type": "number",
                "label": "Quantity",
                "parse_output": "float_conversion",
                "type": "number",
                "name": "quantity"
              },
              {
                "control_type": "text",
                "label": "Fees",
                "type": "string",
                "name": "fees"
              }
            ],
            "label": "Totals",
            "type": "object",
            "name": "totals"
          }
        ]
      end
    }
  }
}
