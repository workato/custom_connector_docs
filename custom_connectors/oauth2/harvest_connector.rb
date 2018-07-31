{
  title: "Harvest",

  connection: {
    fields: [
      {
        name: "client_id",
        label: "Client ID",
        optional: false,
        hint: "You can find your client ID " \
          "<a href='https://id.getharvest.com/developers' " \
          "target='_blank'>here</a>"
      },
      {
        name: "client_secret",
        label: "Client Secret",
        control_type: "password",
        optional: false,
        hint: "You can find your client secret " \
          "<a href='https://id.getharvest.com/developers' " \
          "target='_blank'>here</a>"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        "https://id.getharvest.com/oauth2/authorize?" \
          "client_id=#{connection['client_id']}&response_type=code"
      end,

      acquire: lambda do |connection, auth_code|
        response = post("https://id.getharvest.com/api/v2/oauth2/token").
                   payload(code: auth_code,
                           client_id: connection["client_id"],
                           client_secret: connection["client_secret"],
                           grant_type: "authorization_code").
                   request_format_www_form_urlencoded

        [response, nil, nil]
      end,

      refresh_on: [403],

      refresh: lambda do |connection, refresh_token|
        post("https://id.getharvest.com/api/v2/oauth2/token").
          payload(grant_type: "refresh_token",
                  client_id: connection["client_id"],
                  client_secret: connection["client_secret"],
                  refresh_token: refresh_token,
                  redirect_uri: "https://www.workato.com/oauth/callback").
          request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    },

    base_uri: lambda do
      "https://api.harvestapp.com"
    end
  },

  object_definitions: {
    client: {
      fields: lambda do |_object_definitions|
        [
          { name: "id", type: "integer" },
          { name: "name" },
          { name: "is_active", type: "boolean" },
          { name: "address" },
          { name: "created_at", type: "date_time" },
          { name: "updated_at", type: "date_time" },
          { name: "currency" }
        ]
      end
    },

    time_entry: {
      fields: lambda do |_object_definitions|
        [
          { name: "id", type: "integer" },
          { name: "spent_date", type: "date" },
          {
            name: "user",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "name" }
              ]
          },
          {
            name: "client",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "name" }
              ]
          },
          {
            name: "project",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "name" }
              ]
          },
          {
            name: "task",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "name" }
              ]
          },
          {
            name: "user_assignment",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "is_project_manager", type: "boolean" },
                { name: "is_active", type: "boolean" },
                { name: "budget", type: "number" },
                { name: "created_at", type: "date_time" },
                { name: "updated_at", type: "date_time" },
                { name: "hourly_rate", type: "number" }
              ]
          },
          {
            name: "task_assignment",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "billable", type: "boolean" },
                { name: "is_active", type: "boolean" },
                { name: "created_at", type: "date_time" },
                { name: "updated_at", type: "date_time" },
                { name: "hourly_rate", type: "number" },
                { name: "budget", type: "number" }
              ]
          },
          { name: "hours", type: "number" },
          { name: "notes" },
          { name: "created_at", type: "date_time" },
          { name: "updated_at", type: "date_time" },
          { name: "is_locked", type: "boolean" },
          { name: "locked_reason" },
          { name: "is_closed", type: "boolean" },
          { name: "is_billed", type: "boolean" },
          { name: "timer_started_at", type: "date_time" },
          { name: "started_time", type: "timestamp" },
          { name: "ended_time", type: "timestamp" },
          { name: "is_running", type: "boolean" },
          {
            name: "invoice",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "number" }
              ]
          },
          {
            name: "external_reference",
            type: "object",
            properties:
              [
                { name: "id", type: "integer" },
                { name: "group_id", type: "integer" },
                { name: "permalink" },
                { name: "service" },
                { name: "service_icon_url" },
                { name: "number" }
              ]
          },
          { name: "billable", type: "boolean" },
          { name: "budgeted", type: "boolean" },
          { name: "billable_rate", type: "number" },
          { name: "cost_rate", type: "number" }
        ]
      end
    }
  },

  actions: {
    search_time_entries: {
      description: "Search <span class='provider'>time entries</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Fetches the time entries that matches the criteria. Returns all " \
        "time entries if left blank. Returns a maximum of 100 records.",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "account_id",
            type: "select",
            control_type: "select",
            pick_list: "account_id",
            optional: false,
            hint: "Account to list clients from"
          },
          { name: "user_id", type: "integer" },
          { name: "client_id", type: "integer" },
          { name: "project_id", type: "integer" },
          {
            name: "is_billed",
            type: "boolean",
            control_type: "checkbox",
            hint: "Yes if invoiced, no if not yet invoiced"
          },
          {
            name: "is_running",
            type: "boolean",
            control_type: "checkbox",
            hint: "Yes if running, no if not running"
          },
          {
            name: "from",
            type: "date",
            hint: "Date of the time entry on or " \
              "after this will be returned"
          },
          {
            name: "to",
            type: "date",
            hint: "Date of the time entry on or " \
              "before this will be returned"
          }
        ]
      end,

      execute: lambda do |_connection, input|
        # API cap per page is 100.
        get("/v2/time_entries").
          headers("Harvest-Account-Id": input["account_id"]).
          params(user_id: input["user_id"],
                 client_id: input["client_id"],
                 project_id: input["project_id"],
                 is_billed: input["is_billed"],
                 is_running: input["is_running"],
                 from: input["from"],
                 to: input["to"],
                 per_page: 100)
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "time_entries",
            type: "array",
            of: "object",
            properties: object_definitions["time_entry"]
          }
        ]
      end,

      sample_output: lambda do |_connection, input|
        {
          time_entries: get("/v2/time_entries").
            headers("Harvest-Account-Id": input["account_id"]).
            params(per_page: 1)["time_entries"] || []
        }
      end
    },

    get_recent_clients: {
      description: "Get recent <span class='provider'>clients</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Fetchs clients that are last modified after a " \
        "specified time. Returns a maximum of 100 records.",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "account_id",
            type: "select",
            control_type: "select",
            pick_list: "account_id",
            optional: false,
            hint: "Account to list clients from"
          },
          {
            name: "updated_since",
            type: "date_time",
            sticky: true,
            hint: "Defaults to 1 hour ago if left blank"
          }
        ]
      end,

      execute: lambda do |_connection, input|
        # API cap per page is 100.
        get("/v2/clients").
          params(per_page: 100,
                 updated_since: (input["updated_since"] || now - 1.hours).
                 to_time.utc.iso8601).
          headers("Harvest-Account-Id": input["account_id"])
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "clients",
            type: "array",
            of: "object",
            properties: object_definitions["client"]
          }
        ]
      end,

      sample_output: lambda do |_connection, input|
        {
          clients: get("/v2/clients").
            params(per_page: 1).
            headers("Harvest-Account-Id": input["account_id"])["clients"] || []
        }
      end
    }
  },

  triggers: {
    new_client: {
      # API returns clients sorted by descending creation date.
      type: :paging_desc,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since",
            type: "timestamp",
            sticky: true,
            hint: "Defaults to 1 hour ago if left blank"
          },
          {
            name: "account_id",
            type: "select",
            control_type: "select",
            pick_list: "account_id",
            optional: false,
            hint: "Account to list clients from"
          },
          {
            name: "is_active",
            type: "boolean",
            control_type: "select",
            pick_list: "true_false",
            hint: "True for active, False for inactive"
          }
        ]
      end,

      poll: lambda do |_connection, input, page|
        created_since = (input["since"] || (now - 1.hours))
        page ||= 1
        limit = 100
        clients = get("/v2/clients").
                  params(updated_since: created_since.to_time.utc.iso8601,
                         is_active: input["is_active"],
                         page: page,
                         per_page: limit).
                  headers("Harvest-Account-Id": input["account_id"])

        {
          events: clients["clients"],
          next_page: clients["next_page"]
        }
      end,

      dedup: lambda do |client|
        client["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["client"]
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/clients").
          params(per_page: 1).
          headers("Harvest-Account-Id": input["account_id"]).
          dig("clients", 0) || {}
      end
    }
  },

  pick_lists: {
    account_id: lambda do |_connection|
      get("https://id.getharvest.com/api/v2/accounts")["accounts"].
        pluck("name", "id")
    end,
    true_false: lambda do |_connection|
      [
        %w(True true),
        %w(False false)
      ]
    end
  }
}
