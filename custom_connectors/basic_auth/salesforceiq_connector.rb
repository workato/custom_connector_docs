{
  title: "SalesforceIQ",

  connection: {
    fields: [
      { name: "api_key", label: "API key", hint: "Get more info from " \
          "<a href='https://help.salesforceiq.com/articles/set-up-api-access'" \
          "target='_blank'>here.</a>", optional: false },
      { name: "api_secret", label: "API secret", optional: false,
        control_type: "password" }
    ],
    authorization: {
      type: "basic_auth",
      credentials: lambda do |connection|
        user(connection["api_key"])
        password(connection["api_secret"])
      end
    },
    base_uri: lambda do
      "https://api.salesforceiq.com"
    end
  },

  test: lambda do |_connection|
    get("/v2/accounts?_limit=1")
  end,

  object_definitions: {
    account: {
      fields: lambda do |_connection|
        [
          { name: "id" },
          { name: "name", optional: false },
          { name: "modifiedDate", label: "Modified date", type: :integer,
            hint: "Stores a particular Date & Time in UTC milliseconds past" \
             " the epoch." }, # milliseconds since epoch
        ].concat(
          get("/v2/accounts/fields")["fields"].
          map do |field|
            pick_list = field["listOptions"].
              map { |o| [o["display"], o["id"]] } if field["dataType"] == "List"
            {
              name: field["id"],
              label: field["name"],
              control_type: field["dataType"] == "List" ? "select" : "text",
              pick_list: pick_list
            }
          end)
      end
    },
  },

  actions: {

    create_account: {
      description: "Create <span class='provider'>Account</span> in " \
      "<span class='provider'>SalesforceIQ</span>",
      input_fields: lambda do |object_definitions|
        object_definitions["account"].
          ignored("id", "modifiedDate", "address_city", "address_state",
                  "address_postal_code", "address_country")
      end,
      execute: lambda do |_connection, input|
        fields = input.select { |key, _| key != "name" }.
                  inject({}) do |hash, (key, value)|
                    hash.merge(key => [{ raw: value }])
                  end
        post("/v2/accounts").
          payload(name: input["name"], fieldValues: fields)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["account"]
      end,

      sample_output: lambda do
        get("/v2/accounts").
          params(_limit: 1).dig("objects", 0) || {}
      end
      },

    search_account: {
      description: "Search <span class='provider'>Account</span> in " \
       "<span class='provider'>SalesforceIQ</span>",
      help: "Returns accounts matching the IDs. Returns all" \
       " accounts, if blank.",
      input_fields: lambda do
        [
          { name: "_ids", label: "Account identifiers",
            hint: "Comma separated list of account identifiers" }
        ]
      end,

      execute: lambda do |_connection, input|
        accounts = get("/v2/accounts",
                       input)["objects"].each do |account|
          (account["fieldValues"] || {}).map do |k, v|
            account[k] = v.dig(0, "raw")
          end
        end
        {
          "accounts": accounts
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "accounts", type: :array, of: :object,
            properties: object_definitions["account"]
          }
        ]
      end,

      sample_output: lambda do
        get("/v2/accounts").
          params(_limit: 1).dig("objects", 0) || {}
      end
    }
  },

  triggers: {

    new_or_updated_accounts: {
      description: "New/Updated <span class='provider'>Account</span> in " \
        "<span class='provider'>SalesforceIQ</span>",
      help: "Checks for new or updated accounts.",
      input_fields: lambda do
        [
          {
            name: "since", type: :timestamp,
            sticky: true, label: "From",
            hint: "Fetch trigger events from specified time. If left blank," \
             " accounts are processed from recipe start time"
          }
        ]
      end,

      poll: lambda do |_connection, input, modified_date_since|
        limit = 50
        modified_date ||= ((input["since"].presence || Time.now).
          to_time.to_f * 1000).to_i
        # result returns in ascending order
        result = get("/v2/accounts").
                 params(_limit: limit, _start: 0,
                        modifiedDate: modified_date)["objects"]
        accounts = result.each do |account|
          (account["fieldValues"] || {}).map do |k, v|
            account[k] = v.dig(0, "raw")
          end
        end
        modified_date_since = accounts.dig(-1, "modifiedDate") ||
         (Time.now.to_f * 1000).to_i
        {
          events: accounts,
          next_poll: modified_date_since,
          can_poll_more: accounts.size >= limit
        }
      end,

      dedup: lambda do |account|
        [account["id"], account["modifiedDate"]].join("_")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["account"]
      end,

      sample_output: lambda do
        get("/v2/accounts").
          params(_limit: 1).dig("objects", 0) || {}
      end
    }
  }

}
