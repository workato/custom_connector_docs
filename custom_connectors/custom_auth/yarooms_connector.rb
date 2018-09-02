{
  title: "Yarooms",

  connection: {
    fields: [
      {
        name: "subdomain",
        control_type: "subdomain",
        url: ".yarooms.com",
        optional: true
      },
      {
        name: "user",
        control_type: "email",
        optional: true
      },
      {
        name: "password",
        control_type: "password",
        optional: true
      }
    ],

    authorization: {
      type: "custom_auth",

      acquire: lambda do |connection|
        {
          authtoken: post("https://api.yarooms.com/auth").params(
            subdomain: connection["subdomain"],
            email: connection["user"],
            password: connection["password"]
          ).dig("data", "token")
        }
      end,

      refresh_on: [
        /Invalid token/
      ],

      detect_on: [
        /Invalid credentials/, /Invalid token/
      ],

      apply: lambda do |connection|
        headers("X-Token": connection["authtoken"])
      end
    },

    base_uri: lambda do |_connection|
      "https://api.yarooms.com"
    end
  },

  test: lambda do
    get("/accounts")["data"]
  end,

  object_definitions: {
    location: {
      fields: lambda do
        [
          { name: "id", type: :integer },
          { name: "name" },
          { name: "timezone" },
          { name: "created_at", type: :date_time },
          { name: "updated_at", type: :date_time }
        ]
      end
    },

    meeting: {
      fields: lambda do
        [
          { name: "id", type: :integer },
          { name: "account_id", type: :integer },
          { name: "type_id", type: :integer },
          { name: "location_id", type: :integer },
          { name: "room_id", type: :integer },
          { name: "name" },
          { name: "description" },
          { name: "start", type: :date_time },
          { name: "end", type: :date_time },
          { name: "modified_by", type: :integer },
          { name: "status", type: :integer },
          { name: "checkin", type: :integer },
          { name: "created_at", type: :date_time },
          { name: "updated_at", type: :date_time },
          {
            name: "recurrence", type: :object,
            properties: [
              { name: "type" },
              { name: "first", type: :integer },
              { name: "exclude_weekends", type: :integer },
              { name: "weekdays", type: :array, of: :integer },
              { name: "step" }
            ]
          }
        ]
      end
    },

    user: {
      fields: lambda do
        [
          { name: "id", type: :integer },
          { name: "location_id", type: :integer },
          { name: "group_id", type: :integer },
          { name: "first_name" },
          { name: "last_name" },
          { name: "email" },
          { name: "time_format" },
          { name: "schedule_screen" },
          { name: "fday" },
          { name: "suspended", type: :integer },
          { name: "created_at", type: :date_time },
          { name: "updated_at", type: :date_time }
        ]
      end
    }
  },

  actions: {
    create_user: {
      description: "Create <span class='provider'>user</span> in " \
        "<span class='provider'>Yarooms</span>",

      input_fields: lambda do
        [
          {
            name: "location_id",
            label: "Location",
            hint: "Default location of the user - usually the physical " \
              "location where the user has activity",
            control_type: :select,
            pick_list: "location",
            optional: false,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "location_id",
              label: "Location ID",
              type: "integer",
              control_type: "number",
              optional: false,
              toggle_hint: "Use location ID",
              hint: "Default location of the user - usually the physical " \
                "location where the user has activity"
            }
          },
          {
            name: "group_id",
            label: "Group",
            hint: "Access group of the user",
            control_type: :select,
            pick_list: "group",
            optional: false,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "group_id",
              label: "Group ID",
              type: "integer",
              control_type: "number",
              optional: false,
              toggle_hint: "Use group ID",
              hint: "ID of user's access group of the user"
            }
          },
          { name: "first_name", optional: false },
          { name: "last_name", optional: false },
          { name: "email", optional: false, control_type: "email" },
          { name: "password", optional: false, control_type: "password" },
          {
            name: "time_format",
            label: "Time format",
            control_type: :select,
            pick_list: "time_format",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "time_format",
              label: "Time format",
              type: "string",
              control_type: "text",
              toggle_hint: "Use custom value",
              hint: "Possible values: 'm' (military) or 'a' (am/pm)"
            }
          },
          {
            name: "schedule_screen",
            label: "Schedule screen",
            hint: "If left blank the default schedule screen of the " \
              "organization will be used",
            control_type: :select,
            pick_list: "schedules",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "schedule_screen",
              label: "Schedule screen",
              type: "string",
              control_type: "text",
              toggle_hint: "Use custom value",
              hint: "Possible values: 'monthly', 'weekly', 'daily' or leave " \
                "blank. If left blank the default schedule screen of the " \
                "organization will be used"
            }
          },
          {
            name: "fday",
            label: "First day of week",
            hint: "If left blank the default first day of the organization " \
              "will be used",
            control_type: :select,
            pick_list: "week_start",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "fday",
              label: "First day of week",
              type: "string",
              control_type: "text",
              toggle_hint: "Use custom value",
              hint: "Possible values: '1' (Monday) or '7' (Sunday) for the " \
                "first day of week. If empty the default first day of the " \
                "organization will be used"
            }
          },
          {
            name: "suspended",
            label: "Suspended",
            hint: "Yes if the user is suspended, no otherwise",
            control_type: :select,
            pick_list: "int_boolean",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "suspended",
              label: "Suspended",
              type: "string",
              control_type: "text",
              toggle_hint: "Use custom value",
              hint: "1 if the user is suspended, 0 otherwise"
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        input["location_id"] = input["location_id"].to_i
        input["group_id"] = input["group_id"].to_i
        input["fday"] = input["fday"].to_i
        input["suspended"] = input["suspended"].to_i
        post("/accounts").params(input)["data"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user"]
      end,

      sample_output: lambda do |_connection|
        get("accounts").dig("data", "list", 0) || {}
      end
    },

    create_meeting: {
      description: "Create <span class='provider'>meeting</span> in " \
        "<span class='provider'>Yarooms</span>",

      input_fields: lambda do
        [
          {
            name: "room_id",
            label: "Room",
            hint: "Room where the meeting will take place",
            control_type: :select,
            pick_list: "room",
            optional: false,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "room_id",
              label: "Room ID",
              type: "integer",
              control_type: "number",
              optional: false,
              toggle_hint: "Use room ID",
              hint: "ID of room where the meeting will take place"
            }
          },
          { name: "name", optional: false, hint: "Title of the meeting" },
          { name: "start", type: :date_time, optional: false,
            hint: "Starting date time of the meeting" },
          { name: "end", type: :date_time, optional: false,
            hint: "Ending date time of the meeting" },
          {
            name: "status",
            label: "Status",
            hint: "Yes if the user is suspended, no otherwise",
            control_type: :select,
            pick_list: "int_boolean",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "status",
              label: "Status",
              type: "string",
              control_type: "text",
              toggle_hint: "Use custom value",
              hint: "1 if the meeting is approved, 0 otherwise"
            }
          },
          { name: "description" },
          {
            name: "type_id",
            label: "Type",
            hint: "Type of meeting",
            control_type: :select,
            pick_list: "meeting_type",
            optional: false,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type_id",
              label: "Type",
              type: "integer",
              control_type: "number",
              optional: false,
              toggle_hint: "Use type ID",
              hint: "ID of meeting type"
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/meetings").params(
          room_id: input["room_id"].to_i,
          name: input["name"],
          start: input["start"].strftime("%Y-%m-%d %H:%M:%S"),
          end: input["end"].strftime("%Y-%m-%d %H:%M:%S"),
          status: input["status"].to_i,
          description: input["description"],
          type_id: input["type_id"].to_i
        )["data"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["meeting"]
      end,

      sample_output: lambda do |_connection|
        location_id = get("/locations").dig("data", "list")
        current_date = Time.now.utc.strftime("%Y-%m-%d")
        get("accounts").
          params("scope[where]": "location:#{location_id}",
                 "scope[when]": "month:#{current_date}").
          dig("data", "list")&.first || {}
      end
    }
  },

  triggers: {
    new_meeting: {
      description: "New <span class='provider'>meeting</span> in " \
        "<span class='provider'>Yarooms</span>",

      type: :paging_desc,

      input_fields: lambda do
        [
          { name: "since", type: :timestamp, optional: false }
        ]
      end,

      poll: lambda do |_connection, input, last_created_since|
        last_check =
          (last_created_since || input["since"]).strftime("%Y%m%d%H%M%S")
        meetings = get("/sync/#{last_check}").dig("data", "data", "new")
        if meetings.present?
          next_created_since = meetings.last["date_created"]
        end

        {
          events: meetings,
          next_page: next_created_since
        }
      end,

      dedup: lambda do |meeting|
        meeting["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["meeting"]
      end,

      sample_output: lambda do |_connection|
        location_id = get("/locations").dig("data", "list")
        current_date = Time.now.utc.strftime("%Y-%m-%d")
        get("accounts").
          params("scope[where]": "location:#{location_id}",
                 "scope[when]": "month:#{current_date}").
          dig("data", "list")&.first || {}
      end
    }
  },

  pick_lists: {
    location: lambda do
      get("/locations").dig("data", "list").pluck("name", "id")
    end,

    group: lambda do
      get("/groups").dig("data", "list").pluck("name", "id")
    end,

    room: lambda do
      get("/rooms").dig("data", "list").pluck("name", "id")
    end,

    meeting_type: lambda do
      get("/types").dig("data", "list").pluck("name", "id")
    end,

    time_format: lambda do |_connection|
      [
        %w[24\ hours m],
        ["am/pm", "a"]
      ]
    end,

    schedules: lambda do |_connection|
      [
        ["Default", ""],
        %w[Monthly monthly],
        %w[Weekly weekly],
        %w[Daily daily]
      ]
    end,

    week_start: lambda do |_connection|
      [
        ["Default", ""],
        %w[Monday 1],
        %w[Sunday 7]
      ]
    end,

    int_boolean: lambda do |_connection|
      [
        %w[Yes 1],
        %w[No 0]
      ]
    end
  }
}
