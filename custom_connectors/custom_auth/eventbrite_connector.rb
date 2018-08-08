{
  title: "Eventbrite (custom)",

  connection: {
    fields: [
      {
        name: "personal_token",
        control_type: "password",
        hint: "Find your personal token here: https://www.eventbrite.com/myaccount/apps/",
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
          { "name": "timezone" },
          {
            "name": "event_ids",
            "type": "array",
            "of": "string",
            "label": "Event IDs"
          },
          {
            "name": "data",
            "type": "array",
            "of": "object",
            "properties": [
              { "name": "date", "type": "date_time" },
              { "name": "date_localized","type": "date_time" },
              {
                "name": "totals",
                "type": "object",
                "properties": [
                  { "name": "currency" },
                  { "name": "gross" },
                  { "name": "net" },
                  { "type": "number", "name": "quantity" },
                  { "name": "fees" }
                ],
              }
            ]
          },
          {
            "name": "totals",
            "type": "object",
            "properties": [
              { "name": "currency" },
              { "name": "gross" },
              { "name": "net" },
              { "name": "quantity", "type": "number" },
              { "name": "fees" }
            ]
          }
        ]
      end
    }
  }
}
