{
  title: "Wachete",

  connection: {
    authorization: {
      type: "oauth2",

      authorization_url: lambda do
        "https: //www.wachete.com/login"
      end,

      token_url: lambda do
        "https: //api.wachete.com/v1/oauth/token"
      end,

      client_id: "WACHETE_CLIENT_ID",

      client_secret: "WACHETE_CLIENT_SECRET",

      credentials: lambda do |_connection, access_token|
        headers("Authorization": "bearer #{access_token}")
      end
    }
  },

  object_definitions: {
    notification: {
      fields: lambda do
        [
          {
            name: "id",
          },
          {
            name: "task",
            type: :object,
            properties: [
              {
                name: "definition",
                type: :object,
                properties: [
                  {
                    name: "name",
                    hint: "Name of wachet you received notification for"
                  }
                ]
              }
            ]
          },
          {
            name: "timestampUtc",
            label: "Timestamp",
            type: :timestamp,
            hint: "Time when notification happened"
          },
          {
            name: "current",
            hint: "Current value of wachet"
          },
          {
            name: "comparand",
            hint: "Previous value of wachet"
          },
          {
            name: "type",
            hint: "Type of notification"
          }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("https://api.wachete.com/v1/task/get")
  end,

  triggers: {
    new_notification: {
      poll: lambda do |_connection, _input, _last_updated_since|
        notifications = get("https://api.wachete.com/v1/alert/range").
                        params(from: "2006-01-25T10: 37: 23.574Z",
                               to: "2030-01-23T10: 37: 23.574Z",
                               count: 1)
        {
          events: notifications["data"]
        }
      end,

      dedup: lambda do |notification|
        notification["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["notification"]
      end
    }
  }
}
