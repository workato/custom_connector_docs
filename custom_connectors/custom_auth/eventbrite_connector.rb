{
  title: "Eventbrite (custom)",

  # API docs - https://www.eventbrite.com/developer/v3/api_overview/authentication
  connection: {
    # What inputs do you need from the user to connect?
    fields: [
      {
        name: "personal_token",
        control_type: "password",
        hint: "Find your personal token here: https://www.eventbrite.com/myaccount/apps/",
        optional: false
      }
    ],

    authorization: {
      # How does the API want the token to be sent?
      credentials: lambda do |connection|
        headers("Authorization": "Bearer #{connection['personal_token']}")
      end
    }
  },

  # Check that the credentials provided is valid
  test: lambda do
    get("https://www.eventbriteapi.com/v3/users/me")
  end,

  actions: {
    get_daily_sales_report: {
      # Perform the API request for this action
      execute: lambda do |connection, input|
        get("https://www.eventbriteapi.com/v3/reports/sales").
          params(event_status: input["event_status"], period: 1, date_facet: "day")
      end,

      input_fields: lambda do
        [
          {
            name: "event_status",
            control_type: "select",
            pick_list: [["All", "all"], ["Live", "live"], ["Ended", "ended"]],
            optional: false
          }
        ]
      end,

      output_fields: lambda do
        [
          { "name": "timezone" },
          {
            "name": "event_ids",
            "type": "array",
            "of": "string",
            "label": "Event IDs"
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
