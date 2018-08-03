# Adds operations missing from the standard adapter.
{
  title: "Bill.com (custom)",

  connection: {
    fields: [
      {
        name: "user_name",
        hint: "Bill.com app login username",
        optional: false
      },
      {
        name: "password",
        hint: "Bill.com app login password",
        optional: false,
        control_type: "password"
      },
      {
        name: "org_id",
        label: "Organisation ID",
        hint: "Log in to your Bill.com account, click on gear icon, click " \
          "on settings then click on profiles under your company. The "  \
          "Organization ID is at the end of the URL, after "                \
          "https://[app/app-stage].bill.com/Organization?Id=",
        optional: false
      },
      {
        name: "dev_key",
        label: "Developer API key",
        hint: "Sign up for the developer program to get API key. "           \
          "You may find more info <a href='https://developer.bill.com/hc/"   \
          "en-us/articles/208695076' target='_blank'>here</a>",
        optional: false,
        control_type: "password"
      },
      {
        name: "environment",
        hint: "Find more info <a href='https://developer.bill.com/hc/en-us/" \
          "articles/208249476-Sandbox-production-differences' " \
          "target='_blank'>here</a>",
        control_type: "select",
        pick_list: [
          %w[Production api],
          %w[Sandbox/Stage api-stage]
        ],
        optional: false
      }
    ],

    authorization: {
      type: "custom_auth",

      acquire: lambda { |connection|
        {
          session_id: post("https://#{connection['environment']}.bill.com" \
            "/api/v2/Login.json").
            payload(userName: connection["user_name"],
                    password: connection["password"],
                    orgId: connection["org_id"],
                    devKey: connection["dev_key"]).
            request_format_www_form_urlencoded.
            dig("response_data", "sessionId")
        }
      },

      refresh_on: [/"error_message"\s*\:\s*"Session is invalid/],

      detect_on: [/"response_message"\s*\:\s*"Error"/],

      apply: lambda { |connection|
        payload(sessionId:  connection["session_id"],
                devKey: connection["dev_key"])
        request_format_www_form_urlencoded
      }
    },

    base_uri: lambda { |connection|
      "https://#{connection['environment']}.bill.com"
    }
  },

  test: lambda { |_connection|
    post("/api/v2/GetSessionInfo.json")
  },

  object_definitions: {
    vendor: {
      fields: lambda { |_connection, _config_fields|
        post("/api/v2/GetEntityMetadata.json").
          dig("response_data", "Vendor", "fields").
          map { |key, _value| { name: key } } || []
      }
    }
  },

  triggers: {
    new_or_updated_vendor: {
      subtitle: "New or updated vendor",
      description: "New or updated <span class='provider'>vendor</span> in " \
        "<span class='provider'>Bill.com</span>",
      type: "paging_desc",

      input_fields: lambda { |_connection|
        [
          {
            name: "since",
            label: "From",
            type: "timestamp",
            optional: true,
            sticky: true,
            hint: "Get vendors created or updated since given date/time. " \
              "Leave empty to get vendors created or updated one hour ago"
          }
        ]
      },

      poll: lambda { |_connection, input, page|
        page ||= 0
        page_size = 50
        query = {
          start: page,
          max: page_size,
          filters: [
            {
              field: "updatedTime",
              op: ">=",
              value: (input["since"].presence || 1.hour.ago).
                utc.
                strftime("%Y-%m-%dT%H:%M:%S.%L%z")
            }
          ],
          sort: [{ field: "updatedTime", asc: 0 }]
        }

        vendors = post("/api/v2/List/Vendor.json").
                  payload(data: query.to_json).
                  dig("response_data") || []

        {
          events: vendors,
          next_page: (vendors.size >= page_size ? page + page_size : nil)
        }
      },

      document_id: lambda { |vendor|
        vendor["id"]
      },

      sort_by: lambda { |vendor|
        vendor["updatedTime"]
      },

      output_fields: lambda { |object_definitions|
        object_definitions["vendor"]
      },

      sample_output: lambda { |_connection|
        post("/api/v2/List/Vendor.json").
          payload(data: { start: 0,
                          max: 1,
                          sort: [{ field: "updatedTime", asc: 0 }] }.to_json).
          dig("response_data", 0) || {}
      }
    }
  }
}
