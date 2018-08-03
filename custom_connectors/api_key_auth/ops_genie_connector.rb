{
  title: "OpsGenie",

  connection: {
    fields: [
      {
        name: "key",
        hint: "Find your OpsGenie API key " \
          "<a href='https://app.opsgenie.com/integration#/'>here</a>.",
        optional: false
      }
    ],

    authorization: {
      type: "api_key",

      credentials: lambda do |connection|
        headers("Authorization": "GenieKey #{connection['key']}")
      end
    },

    base_uri: lambda do
      "https://api.opsgenie.com"
    end
  },

  test: lambda do
    get("/v2/alerts")
  end,

  object_definitions: {
    alert: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "message", optional: false },
          { name: "alias" },
          { name: "description" },
          { name: "responders", type: :object, properties: [
            { name: "id" },
            { name: "name" },
            { name: "username" },
            { name: "type" }
          ] },
          { name: "visibleTo", type: :object, properties: [
            { name: "id" },
            { name: "name" },
            { name: "username" },
            { name: "type" }
          ] },
          { name: "entity" },
          { name: "priority", control_type: "select", pick_list: "priorities" }
        ]
      end
    }
  },

  actions: {
    create_alert: {
      title: "Create an alert",
      description: "Create <span class='provider'>alert</span> in " \
      "<span class='provider'>OpsGenie</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["alert"]
      end,

      execute: lambda do |_connection, input|
        post("https://api.opsgenie.com/v2/alerts", input)
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: "result" },
          { name: "took", type: "number" },
          { name: "requestId" }
        ]
      end,

      sample_output: lambda do |_object_definitions|
        {
          "result": "Request will be processed",
          "took": 0.302,
          "requestId": "43a29c5c-3dbf-4fa4-9c26-f4f71023e120"
        }
      end
    }
  },

  pick_lists: {
    priorities: lambda do |_connection|
      [
        %w[P1 P1],
        %w[P2 P2],
        %w[P3 P3],
        %w[P4 P4],
        %w[P5 P5]
      ]
    end
  }
}
