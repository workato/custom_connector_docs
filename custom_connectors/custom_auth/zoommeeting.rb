{
  title: "Zoom Meeting",

  connection: {
    fields: [
      {
        name: "jwt_token",
        label: "JSON web token",
        optional: false,
        control_type: "password",
        hint: "<a href='https://marketplace.zoom.us/docs/guides/authorization/jwt' target='_blank'>"\
        "Click here</a> to generate JWT token"
      }
    ],

    authorization: {
      type: "custom_auth",
      credentials: lambda do |connection|
        headers("Authorization": "Bearer #{connection['jwt_token']}")
      end
    },

    base_uri: lambda do |_connection|
      "https://api.zoom.us"
    end
  },

  test: ->(_connection) {
    get("/v2/users/me")
  },

  methods: {
    get_user_id: lambda do
      get("/v2/users/me")["id"]
    end

  },

  actions: {

    create_user: {
      description: "Create <span class='provider'>user</span> in " \
      "<span class='provider'>Zoom</span>",
      subtitle: "Create user in Zoom",
      help: "Action field can be one of: <br>
      <code>Create:</code> User will get email from Zoom<br>
      <code>Auto crate:</code> should be used for Enterprise customer's who has managed domain. <br>
      <code>Cust Create:</code> should be used by API partner only. <br>
      <code>SSO Create:</code> should be used for 'Pre provisioning SSO Use' option.",
      input_fields: lambda do |object_definitions|
        [
          { name: "action",
            optional: false,
            control_type: "select",
            pick_list: "user_action",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "action",
              label: "action",
              type: :string,
              control_type: "text",
              optional: false,
              toggle_hint: "User Custom Value"
            } },
          { name: "user_info", optional: false, type: "object",
            properties: object_definitions["user"].
            only("email", "type", "first_name", "last_name", "password") }
        ]
      end,
      execute: lambda do |_connection, input|
        post("/v2/users").payload(input)
      end,
      output_fields: lambda do |object_defintions|
        object_defintions["user"]
      end,
      sample_output: lambda do
        get("/v2/users?status=active&page_size=1&page_number=1").
          dig("users", 0)
      end

    },

    upload_user_picture: {
      description: "Upload <span class='provider'>user’s profile picture</span> in " \
      "<span class='provider'>Zoom</span>",
      input_fields: lambda do
        [
          { name: "user_id", optional: false },
          { name: "pic_file", optional: false,
            label: "Profile picture",
            hint: "User profile picture, must be jpg/jpeg file" },
          { name: "file_name", optional: false },
          { name: "file_type", optional: false,
            hint: "use image/jpg for jpg and image/jpeg for jpeg files" }
        ]
      end,
      execute: lambda do |_connection, input|
        post("/v2/users/#{input['user_id']}/picture").
          payload(
            pic_file: [input["pic_file"], input["file_type"], input["file_name"]]
          ).request_format_multipart_form.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_files: lambda do
        [
          { name: "id" },
          { name: "added_at", type: "date_time" }
        ]
      end,
      sample_output: lambda do
        {
          "id": "E5_MxPxGSr6wGPPlIhs",
          "added_at": "2018-09-19T21:38:38Z"
        }
      end
    },

    get_user_details: {
      description: "Get <span class='provider'>user</span>details in " \
      "<span class='provider'>Zoom</span>",
      subtitle: "Get user details by id or email Zoom",
      input_fields: lambda do
        [
          { name: "userId", label: "User ID or email address",
            optional: false },
          { name: "login_type", control_type: "select",
            pick_list: "login_type",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "login_type",
              label: "login_type".labelize,
              type: :integer,
              control_type: "number",
              optional: true,
              toggle_hint: "User Custom Value"
            } }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/v2/users/" + input.delete("userId"), input)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions["user"]
      end,
      sample_output: lambda do
        get("/v2/users?status=active&page_size=1&page_number=1").
          dig("users", 0)
      end
    },

    create_meeting: {
      description: "Create <span class='provider'>meeting</span> in " \
      "<span class='provider'>Zoom</span>",
      subtitle: "Create meeting Zoom",
      input_fields: lambda do |object_definitions|
        [
          { name: "userId", optional: false, hint: "The user ID or email address" }
        ].concat(object_definitions["meeting"].ignored("id", "uuid"))
      end,
      execute: lambda do |_connection, input|
        post("/v2/users/" + input.delete("userId") + "/meetings").
          payload(input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions["meeting_output"]
      end,
      sample_output: lambda do |_connection, input|
        get("/v2/users/" + input["userId"] + "/meetings?page_size=1&page_number=1").
          dig("meetings", 0)
      end
    },

    get_meeting_details: {
      description: "Retrieve a <span class='provider'>meeting's</span> detail in " \
      "<span class='provider'>Zoom</span>",
      input_fields: lambda do
        [
          { name: "meetingId", type: "integer", optional: false, label: "Meeting ID" }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/v2/meetings/" + input.delete("meetingId")).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.presence || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions["meeting"]
      end,
      sample_output: lambda do
        get("/v2/users/" + call("get_user_id", {}) + "/meetings?page_size=1&page_number=1").
          dig("meetings", 0)
      end
    },

    get_all_meeting_recordings: {
      description: "Retrieves all <span class='provider'>meeting</span>"\
      " recordings from <span class='provider'>Zoom</span>",
      subtitle: "Retrive all meeting recordings for <code>meeting id</code> from Zoom",
      input_fields: lambda do |_object_definitions|
        [
          { name: "meeting_id", type: "integer", optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/v2/meetings/" + input["meeting_id"] + "/recordings").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions["meeting_recording"]
      end
    },

    get_meeting_registrants: {
      description: "Get <span class='provider'>meeting</span> registrants"\
      " in <span class='provider'>Zoom</span>",
      subtitle: "Get meeting registrants for meeting in Zoom",
      input_fields: lambda do |_|
        [
          { name: "meeting_id",
            type: "integer",
            control_type: "number",
            optional: false,
            label: "Meeting ID" },
          { name: "occurrence_id" },
          { name: "status",
            control_type: "select",
            hint: "default: approved",
            label: "Registrant status",
            pick_list: "status",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "status",
              label: "Registrant status".labelize,
              type: :string,
              control_type: "text",
              optional: true,
              toggle_hint: "User Custom Value"
            } },
          { name: "page_size", type: "integer",
            control_type: "number",
            hint: "default: 30, maximum: 300" },
          { name: "page_number", type: "integer",
            control_type: "number",
            hint: "default 1" }
        ]
      end,
      execute: lambda do |_conneciton, input|
        get("/v2/meetings/" + input.delete("meeting_id") +
         "/registrants", input)
      end,
      output_fields: lambda do |object_defintions|
        [
          { name: "page_count", type: "integer" },
          { name: "page_number", type: "integer" },
          { name: "page_size", type: "integer" },
          { name: "total_records", type: "integer" },
          { name: "registrants", type: "array", of: "object",
            properties: object_defintions["registrant"] }
        ]
      end
    }

  },

  triggers: {

    meeting_events: {
      description: "Monitor <span class='provider'>meeting</span> object in <span class='provider'>Zoom</span>",
      subtitle: "Meeting object event types",
      help: "Webhook monitors one or more event types from: <code> meeting_started, meeting_ended,meeting_join, recording_completed,"\
      " participant_joined, participant_left, meeting_registered, recording_transcript_completed, meeting_jbh</code>"\
      "<br>Webhooks are only supported by the v2 API.</br>",
      input_fields: lambda do
        [
          { name: "events", label: "Events to monitor",
            control_type: "multiselect",
            optional: false,
            pick_list: "event_types",
            pick_list_params: {},
            delimiter: ",",
            hint: "Event types to monitor" }
        ]
      end,
      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        post("/v2/webhooks").
          payload(
            url: webhook_url,
            auth_user: "Zoom",
            auth_password: "Zoom",
            events: input["events"].split(",")
          ).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      webhook_notification: lambda do |_input, payload|
        payload
      end,
      webhook_unsubscribe: lambda do |webhook, _conneciton|
        delete("/v2/webhooks/#{webhook['webhook_id']}")
      end,
      dedup: lambda do |_meeting|
        Time.now.iso8601(9)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions["webhook_response"]
      end
    }
  },

  pick_lists: {
    rec_type: lambda do
      [
        ["Daily", "1"],
        ["Weekly", "2"],
        ["Monthly", "3"]
      ]
    end,
    weekly_days: lambda do
      [
        ["Sunday", "1"],
        ["Monday", "2"],
        ["Tuesday", "3"],
        ["Wednesday", "4"],
        ["Thursday", "5"],
        ["Friday", "6"],
        ["Saturday", "7"]
      ]
    end,
    monthly_week: lambda do
      [
        ["Last week", "-1"],
        ["First week", "1"],
        ["Second week", "2"],
        ["Third week", "3"],
        ["Fourth week", "4"]
      ]
    end,
    recurrence_type: lambda do
      [
        ["Daily", "1"],
        ["Weekly", "2"],
        ["Monthly", "3"]
      ]
    end,
    meeting_type: lambda do
      [
        ["Instant Meeting", "1"],
        ["Scheduled Meeting", "2"],
        ["Recurring Meeting with no fixed time", "3"],
        ["Recurring Meeting with fixed time", "8"]
      ]
    end,
    approval_type: lambda do
      [
        ["Automatically Approve", "1"],
        ["Manually Approve", "2"],
        ["No Registration Required", "3"]
      ]
    end,
    registration_type: lambda do
      [
        ["Attendees register once and can attend any of the occurrences", "1"],
        ["Attendees need to register for each occurrence to attend", "2"],
        ["Attendees register once and can choose one or more occurrences to attend", "3"]
      ]
    end,
    audio: lambda do
      [
        ["telephony", "telephony"],
        ["voip", "voip"],
        ["thirdParty", "thirdParty"],
        ["both", "both"]
      ]
    end,
    auto_recording: lambda do
      [
        ["local", "local"],
        ["cloud", "cloud"],
        ["none", "none"]
      ]
    end,
    login_type: lambda do
      [
        ["Facebook", "0"],
        ["Google", "1"],
        ["API", "99"],
        ["Zoom", "100"],
        ["SSO", "101"]
      ]
    end,
    user_type: lambda do
      [
        ["basic", "1"],
        ["pro", "2"],
        ["corp", "3"]
      ]
    end,
    user_action: lambda do
      [
        ["create", "create"],
        ["autoCreate", "autoCreate"],
        ["custCreate", "custCreate"],
        ["ssoCreate", "ssoCreate"]
      ]
    end,
    purchasing_time_frame: lambda do
      [
        ["Within a month", "Within a month"],
        ["1-3 months", "1-3 months"],
        ["4-6 months", "4-6 months"],
        ["More than 6 months", "More than 6 months"],
        ["No timeframe", "No timeframe"]
      ]
    end,
    role_in_purchase_process: lambda do
      [
        ["Decision Maker", "Decision Maker"],
        ["Evaluator/Recommender", "Evaluator/Recommender"],
        ["Influencer", "Influencer"],
        ["Not involved", "Not involved"]
      ]
    end,
    no_of_employees: lambda do
      [
        ["1-20", "1-20"],
        ["21-50", "21-50"],
        ["51-100", "51-100"],
        ["101-500", "101-500"],
        ["500-1,000", "500-1,000"],
        ["1,001-5,000", "1,001-5,000"],
        ["5,001-10,000", "5,001-10,000"],
        ["More than 10,000", "More than 10,000"]
      ]
    end,

    status: lambda do
      [
        ["pending", "pending"],
        ["approved", "approved"],
        ["denied", "denied"]
      ]
    end,

    event_types: lambda do
      [
        ["Meeting started", "meeting_started"],
        ["Meeting ended", "meeting_ended"],
        ["Attendee joined meeting before host.", "meeting_jbh"],
        ["Host hasn’t launched the meeting, attendee is waiting.", "meeting_join"],
        ["Recording completed", "recording_completed"],
        ["Participant joined", "participant_joined"],
        ["Participant left", "participant_left"],
        ["Meeting registered", "meeting_registered"],
        ["Recording transcript completed", "recording_transcript_completed"]
      ]
    end
  },

  object_definitions: {
    user: {
      fields: lambda do
        [
          { name: "id" },
          { name: "first_name",
            hint: "Cannot contain more than 5 Chinese words." },
          { name: "last_name",
            hint: "Cannot contain more than 5 Chinese words." },
          { name: "email",
            optional: false,
            hint: "maximum 128 chars" },
          { name: "type",
            optional: false,
            label: "User type",
            control_type: "select",
            pick_list: "user_type",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "User type",
              type: :integer,
              control_type: "number",
              optional: false,
              toggle_hint: "User Custom Value",
              hint: "User 1 for basic, 2 for pro and 3 for corp"
            } },
          { name: "pmi", type: "integer",
            control_type: "number" },
          { name: "personal_meeting_url",
            type: "string",
            control_type: "url" },
          { name: "timezone" },
          { name: "verified" },
          { name: "created_at",
            type: "date_time",
            control_type: "date_time" },
          { name: "last_login_time",
            type: "date_time",
            control_type: "date_time" },
          { name: "dept" },
          { name: "host_key" },
          { name: "group_ids" },
          { name: "im_group_ids" },
          { name: "account_id" },
          { name: "password",
            hint: "User’s password, Only for \"autoCreate\" action." }
        ]
      end
    },

    meeting: {
      fields: lambda do
        [
          { name: "id",
            type: "integer",
            control_type: "number" },
          { name: "topic",
            label: "Meeting topic",
            optional: false },
          { name: "type",
            control_type: "select",
            label: "Meeting type",
            sticky: true,
            pick_list: "meeting_type",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "Meeting type",
              type: :integer,
              control_type: "number",
              optional: true,
              toggle_hint: "User Custom Values",
              hint: "values 1 for Instant, 2 for Scheduled,"\
                " 3 for Recurring Meeting with no fixed time and "\
                "4 for Recurring Meeting with fixed time"
            } },
          { name: "start_time",
            label: "Meeting start time",
            type: "date_time", control_type: "date_time",
            hint: "Only used for schedule and recurring meetings with fixed time. When using a format like \"yyyy-MM-dd'T'HH:mm:ss'Z'\", always use GMT time" },
          { name: "duration", label: "Meeting duration (minutes)",
            type: "integer", control_type: "number",
            hint: "Used for scheduled meetings only. Duration in minutes" },
          { name: "timezone", label: "Timezone to format start_time",
            hint: "e.g. <code>America/Los_Angeles</code>, Please reference our <a href='https://devdocs.zoom.us/reference#timezones'>timezone</a>"\
            " list for supported timezones and their formats" },
          { name: "password", label: "Password",
            hint: "Max of 10 characters, may only contain the following characters: [a-z A-Z 0-9 @ - _ *]." },
          { name: "agenda", type: "string",
            control_type: "text-area",
            label: "Meeting description" },
          { name: "recurrence", type: "object",
            label: "Recurrence settings",
            properties: [
              { name: "type", control_type: "select",
                label: "Recurrence meeting type",
                pick_list: "rec_type",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "type",
                  label: "Recurrence type",
                  type: :integer,
                  control_type: "number",
                  optional: true,
                  toggle_hint: "User Custom Values",
                  hint: "values 1 for Daily, 2 for Weekly, 3 for Monthly"
                } },
              { name: "repeat_interval",
                type: "integer",
                control_type: "number",
                hint: "For a daily meeting, max of 90 days. For a weekly meeting, max of 12 weeks. For a monthly meeting, max of 3 months." },
              { name: "weekly_days",
                control_type: "multiselect",
                label: "Weekly days",
                optional: true,
                pick_list: "weekly_days",
                pick_list_params: {},
                delimiter: ",",
                hint: "Days of the week the meeting should repeat",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "weekly_days",
                  label: "Weekly days",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Values",
                  hint: "multiple values separated by "\
                  "comma e.g. <code>1,2</code> for Sunday and Monday"
                } },
              { name: "monthly_day", type: "integer",
                control_type: "number",
                label: "Day of the month",
                hint: "The value range is from 1 to 31" },
              { name: "monthly_week", type: "integer",
                control_type: "select",
                pick_list: "monthly_week",
                hint: "Week for which the meeting should recur each mont",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "monthly_week",
                  label: "Monthly week",
                  type: :integer,
                  control_type: "number",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "monthly_week_day",
                label: "Monthly week day",
                optional: true,
                control_type: "select",
                pick_list: "weekly_days",
                hint: "Day for which the meeting should recur each month",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "monthly_week_day",
                  label: "Monthly week day",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "end_times",
                type: "integer",
                control_type: "number",
                hint: "maximum 50, Cannot be used with \"end_date_time\"" },
              { name: "end_date_time", type: "date_time",
                control_type: "date_time",
                hint: "Should be UTC time, such as 2017-11-25T12:00:00Z. "\
                "(Cannot be used with \"end_times\".)" }
            ] },
          { name: "settings", type: "object",
            label: "Meeting settings",
            properties: [
              { name: "host_video", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "host_video",
                  label: "host_video".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "participant_video", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "participant_video",
                  label: "participant_video".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "cn_meeting", type: "boolean",
                control_type: "checkbox",
                label: "Host meeting in China",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "cn_meeting",
                  label: "Host meeting in China",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "in_meeting", type: "boolean",
                control_type: "checkbox",
                label: "Host meeting in India",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "in_meeting",
                  label: "Host meeting in India",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "join_before_host", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "join_before_host",
                  label: "join_before_host".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "mute_upon_entry", type: "boolean",
                control_type: "checkbox",
                label: "Mute participants upon entry",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "mute_upon_entry",
                  label: "Mute participants upon entry",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "watermark", type: "boolean",
                control_type: "checkbox",
                hint: "Add watermark when viewing shared screen",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "watermark",
                  label: "Watermark",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "use_pmi", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "use_pmi",
                  label: "use_pmi".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "approval_type", type: "integer",
                control_type: "select",
                pick_list: "approval_type",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "approval_type",
                  label: "Approval type",
                  type: :integer,
                  control_type: "number",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "registration_type", type: "integer",
                control_type: "select",
                pick_list: "registration_type",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "registration_type",
                  label: "Registration type",
                  type: :integer,
                  control_type: "number",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "Audio", control_type: "select",
                pick_list: "audio",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "Audio",
                  label: "Audio",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "auto_recording", control_type: "select",
                pick_list: "auto_recording",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "auto_recording",
                  label: "Auto recording",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "enforce_login", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "enforce_login",
                  label: "enforce_login".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "enforce_login_domains" },
              { name: "alternative_hosts",
                hint: "Alternative hosts emails or IDs."\
                " Multiple value separated by comma." }
            ] },
          { name: "uuid" }
        ]
      end
    },

    meeting_output: {
      fields: lambda do
        [
          { name: "id", type: "integer",
            label: "Meeting ID",
            control_type: "number" },
          { name: "host_id" },
          { name: "uuid" },
          { name: "topic", label: "Meeting topic",
            optional: false },
          { name: "start_time",
            label: "Meeting start time",
            optional: false,
            type: "date_time", control_type: "date_time",
            hint: "Only used for schedule and recurring meetings with fixed time. When using a format like \"yyyy-MM-dd'T'HH:mm:ss'Z'\", always use GMT time" },
          { name: "duration", label: "Meeting duration (minutes)",
            type: "integer", control_type: "number",
            optional: false,
            hint: "Used for schedule meetings only, Duration in minutes" },
          { name: "timezone", label: "Timezone to format start_time",
            hint: "e.g. <code>America/Los_Angeles</code>, Please reference our <a href='https://devdocs.zoom.us/reference#timezones'>"\
            "timezone</a> list for supported timezones and their formats" },
          { name: "password", label: "Password",
            hint: "Max of 10 characters, may not contain the"\
            " following characters: [a-z A-Z 0-9 @ - _ *]." },
          { name: "agenda", type: "string", control_type: "text-area",
            label: "Meeting description" },
          { name: "type", control_type: "select",
            label: "Recurrence meeting type",
            pick_list: "rec_type",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "type",
              label: "Recurrence type",
              type: :integer,
              control_type: "number",
              optional: true,
              toggle_hint: "User Custom Values",
              hint: "values 1 for Daily, 2 for Weekly, 3 for Monthly"
            } },
          { name: "start_url", type: "string", control_type: "url" },
          { name: "join_url", type: "string", control_type: "url" },
          { name: "h323_password" },
          { name: "pstn_password" },
          { name: "password" },
          { name: "settings", type: "object", label: "Meeting settings",
            properties: [
              { name: "host_video", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "host_video",
                  label: "host_video".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "participant_video", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "participant_video",
                  label: "participant_video".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "cn_meeting", type: "boolean",
                control_type: "checkbox",
                label: "Host meeting in China",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "cn_meeting",
                  label: "Host meeting in China",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "in_meeting", type: "boolean",
                control_type: "checkbox",
                label: "Host meeting in India",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "in_meeting",
                  label: "Host meeting in India",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "join_before_host", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "join_before_host",
                  label: "join_before_host".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "mute_upon_entry", type: "boolean",
                control_type: "checkbox",
                label: "Mute participants upon entry",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "mute_upon_entry",
                  label: "Mute participants upon entry",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "watermark", type: "boolean",
                control_type: "checkbox",
                hint: "Add watermark when viewing shared screen",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "watermark",
                  label: "Watermark",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "use_pmi", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "use_pmi",
                  label: "use_pmi".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "approval_type", type: "integer",
                control_type: "select",
                pick_list: "approval_type",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "approval_type",
                  label: "Approval type",
                  type: :integer,
                  control_type: "number",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "registration_type", type: "integer",
                control_type: "select",
                pick_list: "registration_type",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "registration_type",
                  label: "Registration type",
                  type: :integer,
                  control_type: "number",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "Audio", control_type: "select",
                pick_list: "audio",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "Audio",
                  label: "Audio",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "auto_recording", control_type: "select",
                pick_list: "auto_recording",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "auto_recording",
                  label: "Auto recording",
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value"
                } },
              { name: "enforce_login", type: "boolean",
                control_type: "checkbox",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "enforce_login",
                  label: "enforce_login".labelize,
                  type: :string,
                  control_type: "text",
                  optional: true,
                  toggle_hint: "User Custom Value",
                } },
              { name: "enforce_login_domains" },
              { name: "alternative_hosts",
                hint: "Alternative hosts emails or IDs. Multiple value separated by comma." }
            ] },
          { name: "uuid" }
        ]
      end
    },

    meeting_recording: {
      fields: lambda do
        [
          { name: "uuid" },
          { name: "id", label: "Meeting ID",
            type: "integer" },
          { name: "account_id" },
          { name: "host_id" },
          { name: "topic" },
          { name: "start_time" },
          { name: "timezone" },
          { name: "duration" },
          { name: "total_size", label: "Total file sie" },
          { name: "recording_count", type: "integer" },
          { name: "recording_files", type: "array", of: "object",
            properties: [
              { name: "id", label: "Recording ID" },
              { name: "meeting_id" },
              { name: "recording_start" },
              { name: "recording_end" },
              { name: "file_type" },
              { name: "file_size" },
              { name: "play_url", type: "string",
                control_type: "url" },
              { name: "download_url", type: "string",
                control_type: "url" },
              { name: "status" },
              { name: "recording_type" }
            ] }
        ]
      end
    },
    registrant: {
      fields: lambda do
        [
          { name: "id" },
          { name: "first_name", optional: false },
          { name: "last_name", optional: false },
          { name: "email", optional: false },
          { name: "address" },
          { name: "city" },
          { name: "country" },
          { name: "zip" },
          { name: "state" },
          { name: "phone" },
          { name: "industry" },
          { name: "org", label: "Organization" },
          { name: "job_title" },
          { name: "purchasing_time_frame",
            control_type: "select",
            pick_list: "purchasing_time_frame",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "purchasing_time_frame",
              label: "purchasing_time_frame".labelize,
              type: :string,
              control_type: "text",
              optional: true,
              toggle_hint: "User Custom Value"
            } },
          { name: "role_in_purchase_process",
            control_type: "select",
            pick_list: "role_in_purchase_process",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "role_in_purchase_process",
              label: "role_in_purchase_process".labelize,
              type: :string,
              control_type: "text",
              optional: true,
              toggle_hint: "User Custom Value"
            } },
          { name: "no_of_employees",
            control_type: "select",
            pick_list: "no_of_employees",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "no_of_employees",
              label: "no_of_employees".labelize,
              type: :string,
              control_type: "text",
              optional: true,
              toggle_hint: "User Custom Value"
            } },
          { name: "comments", type: "string",
            control_type: "text-area" },
          { name: "custom_questions",
            type: "array", of: "string" },
          { name: "status" },
          { name: "create_time",
            type: "date_time",
            control_type: "date_time" },
          { name: "join_url", type: "string",
            control_type: "url" }
        ]
      end
    },
    webhook_response: {
      fields: lambda do
        [
          { name: "event" },
          { name: "payload", type: "object", properties: [
            { name: "account_id" },
            { name: "meeting", type: "object", properties: [
              { name: "id",
                label: "Meeting ID",
                type: "integer",
                control_type: "number" },
              { name: "uuid", label: "UUID" },
              { name: "host_id" },
              { name: "topic" },
              { name: "duration", type: "integer",
                control_type: "number" },
              { name: "start_time", type: "date_time",
                control_type: "date_time" },
              { name: "end_time", type: "date_time",
                control_type: "date_time" },
              { name: "timezone" },
              { name: "type", control_type: "select",
                pick_list: "meeting_type" },
              { name: "participant", type: "object", properties: [
                { name: "user_id" },
                { name: "user_name" },
                { name: "join_time", type: "date_time",
                  control_type: "date_time" },
                { name: "leave_time", type: "date_time",
                  control_type: "date_time" }
              ] },
              { name: "registrant", type: "object", properties: [
                { name: "id" },
                { name: "first_name", optional: false },
                { name: "last_name", optional: false },
                { name: "email", optional: false },
                { name: "address" },
                { name: "city" },
                { name: "country" },
                { name: "zip" },
                { name: "state" },
                { name: "phone" },
                { name: "industry" },
                { name: "org", label: "Organization" },
                { name: "job_title" },
                { name: "purchasing_time_frame",
                  control_type: "select",
                  pick_list: "purchasing_time_frame",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "purchasing_time_frame",
                    label: "purchasing_time_frame".labelize,
                    type: :string,
                    control_type: "text",
                    optional: true,
                    toggle_hint: "User Custom Value"
                  } },
                { name: "role_in_purchase_process",
                  control_type: "select",
                  pick_list: "role_in_purchase_process",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "role_in_purchase_process",
                    label: "role_in_purchase_process".labelize,
                    type: :string,
                    control_type: "text",
                    optional: true,
                    toggle_hint: "User Custom Value"
                  } },
                { name: "no_of_employees",
                  control_type: "select",
                  pick_list: "no_of_employees",
                  toggle_hint: "Select from list",
                  toggle_field: {
                    name: "no_of_employees",
                    label: "no_of_employees".labelize,
                    type: :string,
                    control_type: "text",
                    optional: true,
                    toggle_hint: "User Custom Value"
                  } },
                { name: "comments", type: "string", control_type: "text-area" },
                { name: "custom_questions", type: "array", of: "string" },
                { name: "status" },
                { name: "join_url", type: "string", control_type: "url" }
              ] },
              # recording fields
              { name: "share_url" },
              { name: "total_size", type: "integer",
                control_type: "number" },
              { name: "recording_count", type: "integer",
                control_type: "number" },
              { name: "host_email" },
              { name: "recording_files", type: "array", of: "object",
                properties: [
                  { name: "id", label: "Recording ID" },
                  { name: "meeting_id" },
                  { name: "recording_start" },
                  { name: "recording_end" },
                  { name: "file_type" },
                  { name: "file_size", type: "integer" },
                  { name: "play_url", type: "string",
                    control_type: "url" },
                  { name: "download_url", type: "string",
                    control_type: "url" },
                  { name: "status" } ]
              } ]
            } ] }
        ]
      end
    }
  }
}
