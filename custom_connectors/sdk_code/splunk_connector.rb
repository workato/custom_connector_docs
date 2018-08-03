{
  title: "Splunk",
  secure_tunnel: true,

  connection: {
    fields: [
      {
        name: "server_url",
        label: "Server URL",
        control_type: "text",
        hint: "The URL of the Splunk management port " \
          "(e.g. https://yourdomain:8089). You MUST install the " \
          "<a href=\"https://splunkbase.splunk.com/apps/#/search/workato\">" \
          "Workato Add-on for Splunk</a> first."
      },
      {
        name: "username",
        hint: "The Splunk username (e.g. admin)"
      },
      {
        name: "password",
        control_type: "password",
        hint: "The password for the Splunk username"
      }
    ],

    authorization: {
      type: "basic_auth",
      credentials: lambda do |connection|
        user(connection["username"])
        password(connection["password"])
      end
    }
  },

  test: lambda do |connection|
    get("#{connection['server_url']}/services/workato/version")
  end,

  object_definitions: {
    generic_alert: {
      fields: lambda do |_connection, config_fields|
        config_fields["fields"].split(",").map do |name|
          {
            name: name.strip
          }
        end
      end
    },

    service_alert: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "event_id", type: :string, optional: false },
          { name: "severity", type: :string },
          { name: "title", type: :string },
          { name: "_time", type: :integer, optional: false },
          { name: "severity_label", type: :string },
          { name: "description", type: :string },
        ]
      end
    },
  },

  triggers: {
    new_generic_alert: {
      input_fields: lambda do |_object_definitions|
        [{
          name: "search_name",
          label: "Splunk alert",
          type: :string,
          control_type: :select,
          pick_list: "saved_searches",
          optional: false,
          hint: "Select one of the alerts saved in Splunk that " \
            "have the Workato alert action assigned.",
        }]
      end,

      config_fields: [
        {
          name: "fields",
          label: "Alert fields",
          type: :string,
          optional: false,
          hint: "Comma-separated field names to be taken over from the Splunk" \
            "data (e.g. host, count)",
        }
      ],

      webhook_subscribe: lambda do |callback_url, connection, input, _flow_id|
        data = post(
          "#{connection['server_url']}/services/workato/alerts",
          callback_url: callback_url,
          search_name: input["search_name"]
        )
        {
          server_url: connection["server_url"],
          search_name: data["search_name"],
          callback_url: data["callback_url"]
        }
      end,

      webhook_unsubscribe: lambda do |subscription|
        delete(
          "#{subscription['server_url']}/services/workato/alerts",
          search_name: subscription["search_name"],
          callback_url: subscription["callback_url"]
        )
      end,

      webhook_notification: lambda do |_input, payload|
        payload
      end,

      dedup: lambda do |_event|
        rand()
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["generic_alert"]
      end
    },
    new_service_alert: {
      webhook_subscribe: lambda do |callback_url, connection, _input, _flow_id|
        data = post(
          "#{connection['server_url']}/services/workato/servicealerts",
          callback_url: callback_url
        )
        {
          server_url: connection["server_url"],
          search_name: data["search_name"],
          callback_url: data["callback_url"]
        }
      end,

      webhook_unsubscribe: lambda do |subscription|
        delete(
          "#{subscription['server_url']}/services/workato/servicealerts",
          search_name: subscription["search_name"],
          callback_url: subscription["callback_url"]
        )
      end,

      webhook_notification: lambda do |_input, payload|
        payload
      end,

      dedup: lambda do |event|
        event["event_id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["service_alert"]
      end
    },
  },

  pick_lists: {
    saved_searches: lambda do |connection|
      get("#{connection['server_url']}/services/workato/alerts").
        map { |name| [name,name] }
    end
  },

  actions: {
    send_event_to_splunk: {
      input_fields: lambda do
        [
          {
            name: "payload",
            optional: false,
          },
          {
            name: "index",
            hint: "The name of the repository for Splunk to store the event in."
          },
          {
            name: "source",
            hint: "The source value to assign to the event data. For example," \
              " if you're sending data from an app you're developing, " \
              "you could set this key to the name of the app."
          },
          {
            name: "sourcetype",
            hint: "The sourcetype value to assign to the event data. " \
              "It identifies the data structure of an event. " \
              "A source type determines how Splunk formats the " \
              "data during the indexing and also parses the data " \
              "during searching process."
          },
          {
            name: "host",
            hint: "The host value to assign to the event data. " \
              "This is typically the hostname of the " \
              "client/server/service from which the data came from."
          },
        ]
      end,

      execute: lambda do |connection, input|
        post(
          "#{connection['server_url']}/services/workato/events",
          payload: input["payload"],
          index: input["index"],
          source: input["source"],
          sourcetype: input["sourcetype"],
          host: input["host"]
        )
      end,

      output_fields: lambda do |_object_definitions|
        []
      end
    }
  }
}
