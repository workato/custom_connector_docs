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

    base_uri: ->(_connection) { "https://api.harvestapp.com" },

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        "https://id.getharvest.com/oauth2/authorize?" \
          "client_id=#{connection['client_id']}&response_type=code"
      end,

      acquire: lambda do |connection, auth_code|
        response = post("https://id.getharvest.com/api/v2/oauth2/token",
                        code: auth_code,
                        client_id: connection["client_id"],
                        client_secret: connection["client_secret"],
                        grant_type: "authorization_code").
                     request_format_www_form_urlencoded

        [response, nil, nil]
      end,

      refresh_on: [403],

      refresh: lambda do |connection, refresh_token|
        post("https://id.getharvest.com/api/v2/oauth2/token",
             grant_type: "refresh_token",
             client_id: connection["client_id"],
             client_secret: connection["client_secret"],
             refresh_token: refresh_token,
             redirect_uri: "https://www.workato.com/oauth/callback").
          request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        headers("Authorization" => "Bearer #{access_token}")
      end
    }
  },

  object_definitions: {
    client: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: "account_id",
            label: "Account",
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "updated_since",
            type: "timestamp",
            sticky: true,
            hint: "Only return time entries that have been updated since the " \
              "given date and time."
          },
          { name: "id", type: "integer", hint: "Unique ID for the client" },
          { name: "name", hint: "A textual description of the client" },
          {
            name: "is_active",
            control_type: "checkbox",
            type: "boolean",
            hint: "Whether the client is active or archived"
          },
          { name: "address", hint: "The physical address for the client" },
          {
            name: "created_at",
            type: "timestamp",
            hint: "Date and time the client was created."
          },
          {
            name: "updated_at",
            type: "timestamp",
            hint: "Date and time the client was last updated."
          },
          {
            name: "currency",
            label: "Currency",
            control_type: "select",
            pick_list: "currencies",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "currency",
              label: "Currency ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end
    },

    custom_action_input: {
      fields: lambda do |_connection, config_fields|
        input_schema = parse_json(config_fields.dig("input", "schema") || "[]")

        [
          {
            name: "account_id",
            label: "Account",
            optional: false,
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "path",
            optional: false,
            hint: "Base URI is <b>https://api.harvestapp.com</b> - " \
              "path will be appended to this URI, e.g. <b>/v2/clients</b>. " \
              "Use absolute URI to override this base URI."
          },
          (
            if %w[get delete].include?(config_fields['verb'])
              {
                name: "input",
                type: "object",
                control_type: "form-schema-builder",
                sticky: input_schema.blank?,
                label: "URL parameters",
                add_field_label: "Add URL parameter",
                properties: [
                  {
                    name: "schema",
                    extends_schema: true,
                    sticky: input_schema.blank?
                  },
                  (
                    if input_schema.present?
                      {
                        name: "data",
                        type: "object",
                        properties: input_schema.
                          each { |field| field[:sticky] = true }
                      }
                    end
                  )
                ].compact
              }
            else
              {
                name: "input",
                type: "object",
                properties: [
                  {
                    name: "schema",
                    extends_schema: true,
                    schema_neutral: true,
                    control_type: "schema-designer",
                    sample_data_type: "json_input",
                    sticky: input_schema.blank?,
                    label: "Request body parameters",
                    add_field_label: "Add request body parameter"
                  },
                  (
                    if input_schema.present?
                      {
                        name: "data",
                        type: "object",
                        properties: input_schema.
                          each { |field| field[:sticky] = true }
                      }
                    end
                  )
                ].compact
              }
            end
          ),
          {
            name: "output",
            control_type: "schema-designer",
            sample_data_type: "json_http",
            extends_schema: true,
            schema_neutral: true,
            sticky: true
          }
        ]
      end
    },

    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        parse_json(config_fields["output"] || "[]")
      end
    },

    project: {
      fields: lambda do |_connection, config_fields|
        clients = get("/api/v2/clients").
                    headers("Harvest-Account-Id" =>
                            config_fields["account_id"])&.
                    []("clients")&.
                    pluck("name", "id")
        [
          {
            name: "updated_since",
            type: "timestamp",
            sticky: true,
            hint: "Only return time entries that have been updated since the " \
              "given date and time."
          },
          {
            name: 'id',
            hint: 'Unique ID for the project.',
            type: 'integer'
          },
          {
            name: "client",
            label: "Client",
            type: "object",
            properties: [{
              name: "id",
              label: "Client",
              control_type: "select",
              pick_list: clients,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Client ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: 'name', hint: 'Unique name for the project.' },
          { name: 'code', hint: 'The code associated with the project.' },
          {
            name: 'is_active',
            hint: 'Whether the project is active or archived.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'is_billable',
            hint: 'Whether the project is billable or not.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'is_fixed_fee',
            hint: 'Whether the project is a fixed-fee project or not.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: "bill_by",
            label: "Bill by",
            hint: 'The method by which the project is invoiced.',
            control_type: "select",
            pick_list: "bill_by_options",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "bill_by",
              label: "Bill by",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: 'hourly_rate',
            hint: 'Rate for projects billed by Project Hourly Rate.',
            control_type: 'number',
            type: 'number'
          },
          {
            name: 'budget',
            hint: 'The budget in hours for the project when budgeting by time.',
            control_type: 'number',
            type: 'number'
          },
          {
            name: "budget_by",
            label: "Budget by",
            hint: 'The method by which the project is budgeted.',
            control_type: "select",
            pick_list: "budget_by_options",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "budget_by",
              label: "Budget by",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: 'budget_is_monthly',
            hint: 'Option to have the budget reset every month.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'notify_when_over_budget',
            hint: 'Whether project managers should be notified when the ' \
              'project goes over budget.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'over_budget_notification_percentage',
            hint: 'Percentage value used to trigger over budget email alerts.',
            control_type: 'number',
            type: 'number'
          },
          {
            name: 'over_budget_notification_date',
            hint: 'Date of last over budget notification. If none have ' \
              'been sent, this will be null.',
            type: 'date'
          },
          {
            name: 'show_budget_to_all',
            hint: 'Option to show project budget to all employees. ' \
              'Does not apply to Total Project Fee projects.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'cost_budget',
            hint: 'The monetary budget for the project when budgeting ' \
              'by money.',
            control_type: 'number',
            type: 'number'
          },
          {
            name: 'cost_budget_include_expenses',
            hint: 'Option for budget of Total Project Fees projects to ' \
              'include tracked expenses.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'fee',
            hint: 'The amount you plan to invoice for the project. ' \
              'Only used by fixed-fee projects.',
            control_type: 'number',
            type: 'number'
          },
          { name: 'notes', hint: 'Project notes.' },
          {
            name: 'starts_on',
            hint: 'Date the project was started.',
            type: 'date'
          },
          { name: 'ends_on', hint: 'Date the project will end.', type: 'date' },
          {
            name: 'created_at',
            hint: 'Date and time the project was created.',
            type: 'timestamp'
          },
          {
            name: 'updated_at',
            hint: 'Date and time the project was last updated.',
            type: 'timestamp'
          },
          {
            name: "client_id",
            label: "Client",
            control_type: "select",
            pick_list: clients,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "client_id",
              label: "Client ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          }
        ]
      end
    },

    task: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: "account_id",
            label: "Account",
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "updated_since",
            type: "timestamp",
            sticky: true,
            hint: "Only return time entries that have been updated since the " \
              "given date and time."
          },
          { name: 'id', hint: 'Unique ID for the task.', type: 'integer' },
          { name: 'name', hint: 'The name of the task.' },
          {
            name: 'billable_by_default',
            hint: 'Used in determining whether default tasks should be ' \
              'marked billable when creating a new project.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          { name: 'default_hourly_rate',
            hint: 'The hourly rate to use for this task when it is added ' \
              'to a project.',
            control_type: 'number',
            type: 'number' },
          {
            name: 'is_default',
            hint: 'Whether this task should be automatically added to ' \
              'future projects.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'is_active',
            hint: 'Whether this task is active or archived.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'created_at',
            hint: 'Date and time the task was created.',
            type: 'timestamp'
          },
          {
            name: 'updated_at',
            hint: 'Date and time the task was last updated.',
            type: 'timestamp'
          }
        ]
      end
    },

    time_entry: {
      fields: lambda do |_connection, config_fields|
        clients = get("/api/v2/clients").
                    headers("Harvest-Account-Id" =>
                           config_fields["account_id"])&.
                    []("clients")&.
                    pluck("name", "id")
        projects = get("/api/v2/projects").
                     headers("Harvest-Account-Id" =>
                            config_fields["account_id"])&.
                     []("projects")&.
                     pluck("name", "id")
        tasks = get("/api/v2/tasks").
                  headers("Harvest-Account-Id" =>
                         config_fields["account_id"])&.
                  []("tasks")&.
                  pluck("name", "id")
        users = get("/api/v2/users").
                  headers("Harvest-Account-Id" =>
                         config_fields["account_id"])&.
                  []("users")&.
                  pluck("name", "id")
        [
          {
            name: "updated_since",
            type: "timestamp",
            sticky: true,
            hint: "Only return time entries that have been updated since the " \
              "given date and time."
          },
          { name: "id", type: "integer", hint: "Unique ID for the time entry." },
          { name: "spent_date", type: "date" },
          {
            name: "user",
            label: "User",
            type: "object",
            properties: [{
              name: "id",
              label: "User",
              control_type: "select",
              pick_list: users,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "User ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          {
            name: "client",
            label: "Client",
            type: "object",
            properties: [{
              name: "id",
              label: "Client",
              control_type: "select",
              pick_list: clients,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Client ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          {
            name: "project",
            label: "Project",
            type: "object",
            properties: [{
              name: "id",
              label: "Project",
              control_type: "select",
              pick_list: projects,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Project ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          {
            name: "task",
            label: "Task",
            type: "object",
            properties: [{
              name: "id",
              label: "Task",
              control_type: "select",
              pick_list: tasks,
              toggle_hint: "Select from list",
              toggle_field: {
                name: "id",
                label: "Project ID",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          {
            name: "user_assignment",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              {
                name: "is_project_manager",
                control_type: "checkbox",
                type: "boolean"
              },
              { name: "is_active", control_type: "checkbox", type: "boolean" },
              { name: "budget", type: "number" },
              { name: "created_at", type: "timestamp" },
              { name: "updated_at", type: "timestamp" },
              { name: "hourly_rate", type: "number" }
            ]
          },
          {
            name: "task_assignment",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "billable", control_type: "checkbox", type: "boolean" },
              { name: "is_active", control_type: "checkbox", type: "boolean" },
              { name: "created_at", type: "timestamp" },
              { name: "updated_at", type: "timestamp" },
              { name: "hourly_rate", type: "number" },
              { name: "budget", type: "number" }
            ]
          },
          { name: "hours", type: "number" },
          { name: "notes" },
          { name: "created_at", type: "timestamp" },
          { name: "updated_at", type: "timestamp" },
          {
            name: "is_locked",
            control_type: "checkbox",
            type: "boolean",
            hint: "Whether or not the time entry has been locked."
          },
          {
            name: "locked_reason",
            hint: "Why the time entry has been locked."
          },
          {
            name: "is_closed",
            control_type: "checkbox",
            type: "boolean",
            hint: "Whether or not the time entry has been approved."
          },
          {
            name: "is_billed",
            control_type: "checkbox",
            type: "boolean",
            hint: "Whether or not the time entry has been marked as invoiced."
          },
          {
            name: "timer_started_at",
            type: "timestamp",
            hint: "Date and time the timer was started " \
              "(if tracking by duration)."
          },
          {
            name: "started_time",
            type: "timestamp",
            hint: "Time the time entry was started (if tracking by " \
              "start/end times)."
          },
          {
            name: "ended_time",
            type: "timestamp",
            hint: "Time the time entry was ended (if tracking by " \
              "start/end times)."
          },
          {
            name: "is_running",
            control_type: "checkbox",
            type: "boolean",
            hint: "Whether or not the time entry is currently running."
          },
          {
            name: "invoice",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "number" }
            ]
          },
          {
            name: "external_reference",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "group_id", type: "integer" },
              { name: "permalink" },
              { name: "service" },
              { name: "service_icon_url" },
              { name: "number" }
            ]
          },
          {
            name: "billable",
            control_type: "checkbox",
            type: "boolean",
            hint: "Whether or not the time entry is billable."
          },
          {
            name: "budgeted",
            control_type: "checkbox",
            type: "boolean",
            hint: "Whether or not the time entry counts towards the " \
              "project budget."
          },
          { name: "billable_rate", type: "number" },
          { name: "cost_rate", type: "number" },
          {
            name: "user_id",
            label: "User",
            control_type: "select",
            pick_list: users,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "user_id",
              label: "User ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "client_id",
            label: "Client",
            control_type: "select",
            pick_list: clients,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "client_id",
              label: "Client ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "project_id",
            label: "Project",
            control_type: "select",
            pick_list: projects,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "project_id",
              label: "Project ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          },
          {
            name: "task_id",
            label: "Task",
            control_type: "select",
            pick_list: tasks,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "task_id",
              label: "Task ID",
              toggle_hint: "Use custom value",
              control_type: "number",
              type: "integer"
            }
          }
        ]
      end
    },

    user: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: "account_id",
            label: "Account",
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "updated_since",
            type: "timestamp",
            sticky: true,
            hint: "Only return time entries that have been updated since the " \
              "given date and time."
          },
          { name: 'id', hint: 'Unique ID for the user.', type: 'integer' },
          { name: 'first_name', hint: 'The first name of the user.' },
          { name: 'last_name', hint: 'The last name of the user.' },
          {
            name: 'email',
            hint: 'The email address of the user.',
            control_type: 'email'
          },
          {
            name: 'telephone',
            hint: 'The telephone number for the user.',
            control_type: 'phone'
          },
          {
            name: "timezone",
            label: "Timezone",
            hint: 'The user’s timezone.',
            control_type: "select",
            pick_list: "time_zones",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "timezone",
              label: "Timezone",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: 'has_access_to_all_future_projects',
            hint: 'Whether the user should be automatically added to ' \
              'future projects.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'is_contractor',
            hint: 'Whether the user is a contractor or an employee.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'is_admin',
            hint: 'Whether the user has admin permissions.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'is_project_manager',
            hint: 'Whether the user has project manager permissions.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'can_see_rates',
            hint: 'Whether the user can see billable rates on projects. ' \
              'Only applicable to project managers.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'can_create_projects',
            hint: 'Whether the user can create projects. Only applicable ' \
              'to project managers.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'can_create_invoices',
            hint: 'Whether the user can create invoices. Only applicable ' \
              'to project managers.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'is_active',
            hint: 'Whether the user is active or archived.',
            control_type: 'checkbox',
            type: 'boolean'
          },
          {
            name: 'weekly_capacity',
            hint: 'The number of hours per week this person is available ' \
              'to work in seconds. For example, if a person’s capacity is ' \
              '35 hours, the API will return 126000 seconds.',
            type: 'integer'
          },
          {
            name: 'default_hourly_rate',
            hint: 'The billable rate to use for this user when they are ' \
              'added to a project.',
            control_type: 'number',
            type: 'number'
          },
          {
            name: 'cost_rate',
            hint: 'The cost rate to use for this user when calculating a ' \
              'project’s costs vs billable amount.',
            control_type: 'number',
            type: 'number'
          },
          { name: 'roles', hint: 'The role names assigned to this person.' },
          {
            name: 'avatar_url',
            hint: 'The URL to the user’s avatar image.',
            control_type: 'url'
          },
          {
            name: 'created_at',
            hint: 'Date and time the user was created.',
            type: 'timestamp'
          },
          {
            name: 'updated_at',
            hint: 'Date and time the user was last updated.',
            type: 'timestamp'
          }
        ]
      end
    }
  },

  actions: {
    # Custom action for Harvest
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Build your own Harvest action with a HTTP request. <br>" \
        " <br> <a href='https://help.getharvest.com/api-v2/'" \
        " target='_blank'>Harvest API Documentation</a> ",

      execute: lambda do |_connection, input|
        verb = input["verb"]
        if %w[get post put patch delete].exclude?(verb)
          error("#{verb} not supported")
        end
        data = input.dig("input", "data").presence || {}

        case verb
        when "get"
          get(input["path"], data).
            headers("Harvest-Account-Id" => input["account_id"])
        when "post"
          post(input["path"], data).
            headers("Harvest-Account-Id" => input["account_id"])
        when "patch"
          patch(input["path"], data).
            headers("Harvest-Account-Id" => input["account_id"])
        when "delete"
          delete(input["path"], data).
            headers("Harvest-Account-Id" => input["account_id"])
        end
      end,

      config_fields: [{
        name: "verb",
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: "select",
        pick_list: %w[get post patch delete].map { |v| [v.upcase, v] },
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["custom_action_output"]
      end
    },

    # Client actions
    create_client: {
      description: "Create <span class='provider'>client</span> " \
        "in <span class='provider'>Harvest</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["client"].
          ignored("created_at", "id", "updated_at", "updated_since").
          required("account_id", "name")
      end,

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        post("/v2/clients", input).
          headers("Harvest-Account-Id" => account_id)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["client"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/clients", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("clients", 0) || {}
      end
    },

    get_client_by_id: {
      description: "Get <span class='provider'>client by ID</span> " \
        "in <span class='provider'>Harvest</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["client"].
          only("account_id", "id").
          required("account_id", "id")
      end,

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        get("/v2/clients/#{input['id']}").
          headers("Harvest-Account-Id" => account_id)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["client"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/clients", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("clients", 0) || {}
      end
    },

    search_clients: {
      description: "Search <span class='provider'>clients</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Fetches the clients that matches the criteria (max 100).",

      input_fields: lambda do |object_definitions|
        object_definitions["client"].
          only("account_id", "is_active", "updated_since").
          required("account_id")
      end,

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        input["updated_since"] = input["updated_since"]&.to_time&.utc&.iso8601

        # API cap per page is 100.
        get("/v2/clients", input.merge(per_page: 100).compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "clients",
          type: "array",
          of: "object",
          properties: object_definitions["client"].
                        ignored("account_id", "updated_since")
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          clients: get("/v2/clients", per_page: 1).
                     headers("Harvest-Account-Id" => input["account_id"]).
                     []("clients") || []
        }
      end
    },

    update_client: {
      description: "Update <span class='provider'>client</span> " \
        "in <span class='provider'>Harvest</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["client"].
          ignored("created_at", "updated_at", "updated_since").
          required("account_id", "id")
      end,

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        client_id = input.delete("id")

        patch("/v2/clients/#{client_id}", input).
          headers("Harvest-Account-Id" => account_id)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["client"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/clients", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("clients", 0) || {}
      end
    },

    # Project actions
    create_project: {
      description: "Create <span class='provider'>project</span> in " \
        "<span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        post("/v2/projects", input).headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["project"].
          only("client_id", "name", "code", "is_active", "is_billable",
               "is_fixed_fee", "bill_by", "hourly_rate", "budget", "budget_by",
               "budget_is_monthly", "notify_when_over_budget",
               "over_budget_notification_percentage", "show_budget_to_all",
               "cost_budget", "cost_budget_include_expenses", "fee", "notes",
               "starts_on", "ends_on").
          required("bill_by", "budget_by", "client_id", "is_billable", "name")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["project"].
          ignored("account_id", "updated_since", "client_id")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/projects", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("projects", 0) || {}
      end
    },

    get_project_by_id: {
      description: "Get <span class='provider'>project by ID</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        get("/v2/projects/#{input['id']}").
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["project"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["project"].
          ignored("account_id", "updated_since", "client_id")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/projects", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("projects", 0) || {}
      end
    },

    search_projects: {
      description: "Search <span class='provider'>projects</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Fetches the projects that match the criteria (max 100).",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        input["updated_since"] = input["updated_since"]&.to_time&.utc&.iso8601

        get("/v2/projects", input.merge(per_page: 100).compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["project"].
          only("client_id", "is_active", "updated_since")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "projects",
          type: "array",
          of: "object",
          properties: object_definitions["project"].
                        ignored("account_id", "updated_since", "client_id")
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          projects: get("/v2/projects", per_page: 1).
                      headers("Harvest-Account-Id" => input["account_id"]).
                      []("projects") || []
        }
      end
    },

    update_project: {
      description: "Update <span class='provider'>project</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        project_id = input.delete("id")
        input['started_time'] = input['started_time']&.strftime("%I:%M%P")
        input['ended_time'] = input['ended_time']&.strftime("%I:%M%P")

        patch("/v2/projects/#{project_id}", input.compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["project"].
          only("client_id", "name", "code", "is_active", "is_billable", "id",
               "is_fixed_fee", "bill_by", "hourly_rate", "budget", "budget_by",
               "budget_is_monthly", "notify_when_over_budget",
               "over_budget_notification_percentage", "show_budget_to_all",
               "cost_budget", "cost_budget_include_expenses", "fee", "notes",
               "starts_on", "ends_on").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["project"].
          ignored("account_id", "updated_since", "client_id")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/projects", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("projects", 0) || {}
      end
    },

    # Task actions
    create_task: {
      description: "Create <span class='provider'>task</span> in " \
        "<span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        post("/v2/tasks", input).headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["task"].
          only("account_id", "name", "billable_by_default",
               "default_hourly_rate", "is_default", "is_active").
          required("account_id", "name")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["task"].ignored("updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/tasks", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("tasks", 0) || {}
      end
    },

    get_task_by_id: {
      description: "Get <span class='provider'>task by ID</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        get("/v2/tasks/#{input['id']}").
          headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["task"].
          only("account_id", "id").
          required("account_id", "id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["task"].ignored("updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/tasks", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("tasks", 0) || {}
      end
    },

    search_tasks: {
      description: "Search <span class='provider'>tasks</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Fetches the tasks that match the criteria (max 100).",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        input["updated_since"] = input["updated_since"]&.to_time&.utc&.iso8601

        get("/v2/tasks", input.merge(per_page: 100).compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["task"].
          only("account_id", "is_active", "updated_since").
          required("account_id")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "tasks",
          type: "array",
          of: "object",
          properties: object_definitions["task"].ignored("updated_since")
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          tasks: get("/v2/tasks", per_page: 1).
                   headers("Harvest-Account-Id" => input["account_id"]).
                   []("tasks") || []
        }
      end
    },

    update_task: {
      description: "Update <span class='provider'>task</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        task_id = input.delete("id")

        patch("/v2/tasks/#{task_id}", input).
          headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["task"].
          only("account_id", "name", "billable_by_default", "id",
               "default_hourly_rate", "is_default", "is_active").
          required("account_id", "id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["task"].ignored("updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/tasks", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("tasks", 0) || {}
      end
    },

    # Time entry actions
    create_time_entry_via_duration: {
      description: "Create <span class='provider'>time entry via " \
        "duration </span> in <span class='provider'>Harvest</span>",
      help: "You should only use this method to create time entries when " \
        "your account is configured to <b>track time via duration</b>. " \
        "You can verify this by visiting the <b>Settings</b> page in " \
        "your Harvest account.",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        post("/v2/time_entries", input).
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        [{ name: "hours", sticky: true, type: "number" }].
          concat(object_definitions["time_entry"].
                    only("user_id", "project_id", "task_id", "spent_date",
                         "notes", "external_reference").
                    required("name", "project_id", "task_id", "spent_date"))
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["time_entry"].
          ignored("account_id", "updated_since", "user_id", "client_id",
                  "project_id", "task_id")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/time_entries", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("time_entries", 0) || {}
      end
    },

    create_time_entry_via_start_and_end_time: {
      description: "Create <span class='provider'>time entry via start and " \
        "end time </span> in <span class='provider'>Harvest</span>",
      help: "You should only use this method to create time entries when " \
        "your account is configured to <b>track time via start and end " \
        "time</b>. You can verify this by visiting the <b>Settings</b> " \
        "page in your Harvest account.",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        input['started_time'] = input['started_time']&.strftime("%I:%M%P")
        input['ended_time'] = input['ended_time']&.strftime("%I:%M%P")

        post("/v2/time_entries", input.compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        [
          { name: "started_time", sticky: true, type: "timestamp" },
          { name: "ended_time", sticky: true, type: "timestamp" }
        ].concat(object_definitions["time_entry"].
                  only("user_id", "project_id", "task_id", "spent_date",
                       "notes", "external_reference").
                  required("name", "project_id", "task_id", "spent_date"))
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["time_entry"].
          ignored("account_id", "updated_since", "user_id", "client_id",
                  "project_id", "task_id")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/time_entries", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("time_entries", 0) || {}
      end
    },

    get_time_entry_by_id: {
      description: "Get <span class='provider'>time_entry by ID</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        get("/v2/time_entries/#{input['id']}").
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["time_entry"].only("id").required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["time_entry"].
          ignored("account_id", "updated_since", "user_id", "client_id",
                  "project_id", "task_id")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/time_entries", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("time_entries", 0) || {}
      end
    },

    search_time_entries: {
      description: "Search <span class='provider'>time entries</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Fetches the time entries that match the criteria (max 100).",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        input["updated_since"] = input["updated_since"]&.to_time&.utc&.iso8601

        get("/v2/time_entries", input.merge(per_page: 100).compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["time_entry"].
          only("from", "is_billed", "is_running", "to", "updated_since",
               "user_id", "client_id", "project_id")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "time_entries",
          type: "array",
          of: "object",
          properties: object_definitions["time_entry"].
                        ignored("account_id", "updated_since", "user_id",
                          "client_id", "project_id", "task_id")
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          time_entries: get("/v2/time_entries", per_page: 1).
                          headers("Harvest-Account-Id" => input["account_id"]).
                          []("time_entries") || []
        }
      end
    },

    update_time_entry: {
      description: "Update <span class='provider'>time entry</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        time_entry_id = input.delete("id")
        input['started_time'] = input['started_time']&.strftime("%I:%M%P")
        input['ended_time'] = input['ended_time']&.strftime("%I:%M%P")

        patch("/v2/time_entries/#{time_entry_id}", input.compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["time_entry"].
          only("id", "project_id", "task_id", "spent_date", "started_time",
               "ended_time", "hours", "notes", "external_reference").
          required("id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["time_entry"].
          ignored("account_id", "updated_since", "user_id", "client_id",
                  "project_id", "task_id")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/time_entries", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("time_entries", 0) || {}
      end
    },

    # User actions
    create_user: {
      description: "Create <span class='provider'>user</span> in " \
        "<span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        post("/v2/users", input).headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["user"].
          only("account_id", "first_name", "last_name",
               "email", "telephone", "timezone",
               "has_access_to_all_future_projects", "is_contractor",
               "is_admin", "is_project_manager", "can_see_rates",
               "can_create_projects", "can_create_invoices", "is_active",
               "weekly_capacity", "default_hourly_rate", "cost_rate", "roles").
          required("account_id", "name")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user"].ignored("updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/users", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("users", 0) || {}
      end
    },

    get_user_by_id: {
      description: "Get <span class='provider'>user by ID</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")

        get("/v2/users/#{input['id']}").
          headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["user"].
          only("account_id", "id").
          required("account_id", "id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user"].ignored("updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/users", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("users", 0) || {}
      end
    },

    search_users: {
      description: "Search <span class='provider'>users</span> " \
        "in <span class='provider'>Harvest</span>",
      help: "Fetches the users that match the criteria (max 100).",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        input["updated_since"] = input["updated_since"]&.to_time&.utc&.iso8601

        get("/v2/users", input.merge(per_page: 100).compact).
          headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["user"].
          only("account_id", "is_active", "updated_since").
          required("account_id")
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "users", type: "array", of: "object",
            properties: object_definitions["user"].ignored("updated_since") }
        ]
      end,

      sample_output: lambda do |_connection, input|
        {
          users: get("/v2/users", per_page: 1).
                   headers("Harvest-Account-Id" => input["account_id"]).
                   []("users") || []
        }
      end
    },

    update_user: {
      description: "Update <span class='provider'>user</span> " \
        "in <span class='provider'>Harvest</span>",

      execute: lambda do |_connection, input|
        account_id = input.delete("account_id")
        user_id = input.delete("id")

        patch("/v2/users/#{user_id}", input).
          headers("Harvest-Account-Id" => account_id)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["user"].
          only("account_id", "first_name", "id", "last_name",
            "email", "telephone", "timezone",
            "has_access_to_all_future_projects", "is_contractor",
            "is_admin", "is_project_manager", "can_see_rates",
            "can_create_projects", "can_create_invoices", "is_active",
            "weekly_capacity", "default_hourly_rate", "cost_rate", "roles").
          required("account_id", "id")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user"].ignored("updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/users", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("users", 0) || {}
      end
    }
  },

  triggers: {
    new_client: {
      title: "New client",
      description: "New <span class='provider'>client" \
        "</span> in <span class='provider'>Harvest</span>",
      # API returns clients sorted by descending creation date.
      type: :paging_desc,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since",
            label: "When first started, this recipe should pick up events from",
            hint: "When you start recipe for the first time, it picks up " \
              "trigger events from this specified date and time. Leave " \
              "empty to get events created one hour ago",
            sticky: true,
            optional: true,
            type: "timestamp",
          },
          {
            name: "account_id",
            label: "Account",
            optional: false,
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end,

      poll: lambda do |_connection, input, page|
        created_since = input["since"] || 1.hour.ago
        page ||= 1
        limit = 100
        response = get("/v2/clients",
                       updated_since: created_since.to_time.utc.iso8601,
                       page: page,
                       per_page: limit).
                     headers("Harvest-Account-Id" => input["account_id"])

        { events: response["clients"], next_page: response["next_page"] }
      end,

      dedup: ->(client) { client["id"] },

      output_fields: lambda do |object_definitions|
        object_definitions["client"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/clients", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("clients", 0) || {}
      end
    },

    new_updated_client: {
      title: "New/updated client",
      description: "New or updated <span class='provider'>client" \
        "</span> in <span class='provider'>Harvest</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since",
            label: "When first started, this recipe should pick up events from",
            hint: "When you start recipe for the first time, it picks up " \
              "trigger events from this specified date and time. Leave " \
              "empty to get events created one hour ago",
            sticky: true,
            optional: true,
            type: "timestamp",
          },
          {
            name: "account_id",
            label: "Account",
            optional: false,
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 100
        updated_since = (closure&.[]('updated_since') || input["since"] ||
                          1.hour.ago)
        offset = closure&.[]('offset') || 1
        response = get("/v2/clients",
                       updated_since: updated_since.to_time.utc.iso8601,
                       page: offset,
                       per_page: page_size).
                     headers("Harvest-Account-Id" => input["account_id"])
        more_pages = response["next_page"].present?
        closure = if more_pages
                    {
                      "offset" => response["next_page"],
                      "updated_since" => updated_since
                    }
                  else
                    { "offset" => 1, "updated_since" => now }
                  end

        {
          events: response["clients"],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(client) { "#{client['id']}@#{client['updated_at']}" },

      output_fields: lambda do |object_definitions|
        object_definitions["client"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/clients", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("clients", 0) || {}
      end
    },

    new_project: {
      description: "New <span class='provider'>project" \
        "</span> in <span class='provider'>Harvest</span>",
      type: :paging_desc,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |_object_definitions|
        [{
          name: "since",
          label: "When first started, this recipe should pick up events from",
          hint: "When you start recipe for the first time, it picks up " \
            "trigger events from this specified date and time. Leave " \
            "empty to get events created one hour ago",
          sticky: true,
          optional: true,
          type: "timestamp",
        }]
      end,

      poll: lambda do |_connection, input, page|
        created_since = input["since"] || 1.hour.ago
        page ||= 1
        limit = 100
        response = get("/v2/projects",
                       updated_since: created_since.to_time.utc.iso8601,
                       page: page,
                       per_page: limit).
                     headers("Harvest-Account-Id" => input["account_id"])

        { events: response["projects"], next_page: response["next_page"] }
      end,

      dedup: ->(project) { project["id"] },

      output_fields: lambda do |object_definitions|
        object_definitions["project"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/projects", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("projects", 0) || {}
      end
    },

    new_updated_project: {
      title: "New/updated project",
      description: "New or updated <span class='provider'>project" \
        "</span> in <span class='provider'>Harvest</span>",

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |_object_definitions|
        [{
          name: "since",
          label: "When first started, this recipe should pick up events from",
          hint: "When you start recipe for the first time, it picks up " \
            "trigger events from this specified date and time. Leave " \
            "empty to get events created one hour ago",
          sticky: true,
          optional: true,
          type: "timestamp",
        }]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 100
        updated_since = (closure&.[]('updated_since') || input["since"] ||
                          1.hour.ago)
        offset = closure&.[]('offset') || 1
        response = get("/v2/projects",
                       updated_since: updated_since.to_time.utc.iso8601,
                       page: offset,
                       per_page: page_size).
                     headers("Harvest-Account-Id" => input["account_id"])
        more_pages = response["next_page"].present?
        closure = if more_pages
                    {
                      "offset" => response["next_page"],
                      "updated_since" => updated_since
                    }
                  else
                    { "offset" => 1, "updated_since" => now }
                  end

        {
          events: response["projects"],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(project) { "#{project['id']}@#{project['updated_at']}" },

      output_fields: lambda do |object_definitions|
        object_definitions["project"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/projects", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("projects", 0) || {}
      end
    },

    new_task: {
      description: "New <span class='provider'>task" \
        "</span> in <span class='provider'>Harvest</span>",
      type: :paging_desc,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since",
            label: "When first started, this recipe should pick up events from",
            hint: "When you start recipe for the first time, it picks up " \
              "trigger events from this specified date and time. Leave " \
              "empty to get events created one hour ago",
            sticky: true,
            optional: true,
            type: "timestamp",
          },
          {
            name: "account_id",
            label: "Account",
            optional: false,
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end,

      poll: lambda do |_connection, input, page|
        created_since = input["since"] || 1.hour.ago
        page ||= 1
        limit = 100
        response = get("/v2/tasks",
                       updated_since: created_since.to_time.utc.iso8601,
                       page: page,
                       per_page: limit).
                     headers("Harvest-Account-Id" => input["account_id"])

        { events: response["tasks"], next_page: response["next_page"] }
      end,

      dedup: ->(task) { task["id"] },

      output_fields: lambda do |object_definitions|
        object_definitions["task"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/tasks", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("tasks", 0) || {}
      end
    },

    new_updated_task: {
      title: "New/updated task",
      description: "New or updated <span class='provider'>task" \
        "</span> in <span class='provider'>Harvest</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since",
            label: "When first started, this recipe should pick up events from",
            hint: "When you start recipe for the first time, it picks up " \
              "trigger events from this specified date and time. Leave " \
              "empty to get events created one hour ago",
            sticky: true,
            optional: true,
            type: "timestamp",
          },
          {
            name: "account_id",
            label: "Account",
            optional: false,
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 100
        updated_since = (closure&.[]('updated_since') || input["since"] ||
                          1.hour.ago)
        offset = closure&.[]('offset') || 1
        response = get("/v2/tasks",
                       updated_since: updated_since.to_time.utc.iso8601,
                       page: offset,
                       per_page: page_size).
                     headers("Harvest-Account-Id" => input["account_id"])
        more_pages = response["next_page"].present?
        closure = if more_pages
                    {
                      "offset" => response["next_page"],
                      "updated_since" => updated_since
                    }
                  else
                    { "offset" => 1, "updated_since" => now }
                  end

        {
          events: response["tasks"],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(task) { "#{task['id']}@#{task['updated_at']}" },

      output_fields: lambda do |object_definitions|
        object_definitions["task"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/tasks", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("tasks", 0) || {}
      end
    },

    new_time_entry: {
      description: "New <span class='provider'>time entry" \
        "</span> in <span class='provider'>Harvest</span>",
      type: :paging_desc,

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use custom value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |_object_definitions|
        [{
          name: "since",
          label: "When first started, this recipe should pick up events from",
          hint: "When you start recipe for the first time, it picks up " \
            "trigger events from this specified date and time. Leave " \
            "empty to get events created one hour ago",
          sticky: true,
          optional: true,
          type: "timestamp",
        }]
      end,

      poll: lambda do |_connection, input, page|
        created_since = input["since"] || 1.hour.ago
        page ||= 1
        limit = 100
        response = get("/v2/time_entries",
                       updated_since: created_since.to_time.utc.iso8601,
                       page: page,
                       per_page: limit).
                     headers("Harvest-Account-Id" => input["account_id"])

        { events: response["time_entries"], next_page: response["next_page"] }
      end,

      dedup: ->(time_entry) { time_entry["id"] },

      output_fields: lambda do |object_definitions|
        object_definitions["time_entry"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/time_entries", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("time_entries", 0) || {}
      end
    },

    new_updated_time_entry: {
      title: "New/updated time entry",
      description: "New or updated <span class='provider'>time_entry" \
        "</span> in <span class='provider'>Harvest</span>",

      config_fields: [{
        name: "account_id",
        label: "Account",
        optional: false,
        control_type: "select",
        pick_list: "accounts",
        toggle_hint: "Select from list",
        toggle_field: {
          name: "account_id",
          label: "Account ID",
          toggle_hint: "Use 
value",
          control_type: "text",
          type: "string"
        }
      }],

      input_fields: lambda do |_object_definitions|
        [{
          name: "since",
          label: "When first started, this recipe should pick up events from",
          hint: "When you start recipe for the first time, it picks up " \
            "trigger events from this specified date and time. Leave " \
            "empty to get events created one hour ago",
          sticky: true,
          optional: true,
          type: "timestamp",
        }]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 100
        updated_since = (closure&.[]('updated_since') || input["since"] ||
                          1.hour.ago)
        offset = closure&.[]('offset') || 1
        response = get("/v2/time_entries",
                       updated_since: updated_since.to_time.utc.iso8601,
                       page: offset,
                       per_page: page_size).
                     headers("Harvest-Account-Id" => input["account_id"])
        more_pages = response["next_page"].present?
        closure = if more_pages
                    {
                      "offset" => response["next_page"],
                      "updated_since" => updated_since
                    }
                  else
                    { "offset" => 1, "updated_since" => now }
                  end

        {
          events: response["time_entries"],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |time_entry|
        "#{time_entry['id']}@#{time_entry['updated_at']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["time_entry"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/time_entries", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("time_entries", 0) || {}
      end
    },

    new_user: {
      description: "New <span class='provider'>user" \
        "</span> in <span class='provider'>Harvest</span>",
      type: :paging_desc,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since",
            label: "When first started, this recipe should pick up events from",
            hint: "When you start recipe for the first time, it picks up " \
              "trigger events from this specified date and time. Leave " \
              "empty to get events created one hour ago",
            sticky: true,
            optional: true,
            type: "timestamp",
          },
          {
            name: "account_id",
            label: "Account",
            optional: false,
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end,

      poll: lambda do |_connection, input, page|
        created_since = input["since"] || 1.hour.ago
        page ||= 1
        limit = 100
        response = get("/v2/users",
                       updated_since: created_since.to_time.utc.iso8601,
                       page: page,
                       per_page: limit).
                     headers("Harvest-Account-Id" => input["account_id"])

        { events: response["users"], next_page: response["next_page"] }
      end,

      dedup: ->(user) { user["id"] },

      output_fields: lambda do |object_definitions|
        object_definitions["user"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/users", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("users", 0) || {}
      end
    },

    new_updated_user: {
      title: "New/updated user",
      description: "New or updated <span class='provider'>user" \
        "</span> in <span class='provider'>Harvest</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since",
            label: "When first started, this recipe should pick up events from",
            hint: "When you start recipe for the first time, it picks up " \
              "trigger events from this specified date and time. Leave " \
              "empty to get events created one hour ago",
            sticky: true,
            optional: true,
            type: "timestamp",
          },
          {
            name: "account_id",
            label: "Account",
            optional: false,
            control_type: "select",
            pick_list: "accounts",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "account_id",
              label: "Account ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 100
        updated_since = (closure&.[]('updated_since') || input["since"] ||
                          1.hour.ago)
        offset = closure&.[]('offset') || 1
        response = get("/v2/users",
                       updated_since: updated_since.to_time.utc.iso8601,
                       page: offset,
                       per_page: page_size).
                     headers("Harvest-Account-Id" => input["account_id"])
        more_pages = response["next_page"].present?
        closure = if more_pages
                    {
                      "offset" => response["next_page"],
                      "updated_since" => updated_since
                    }
                  else
                    { "offset" => 1, "updated_since" => now }
                  end

        {
          events: response["users"],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(user) { "#{user['id']}@#{user['updated_at']}" },

      output_fields: lambda do |object_definitions|
        object_definitions["user"].ignored("account_id", "updated_since")
      end,

      sample_output: lambda do |_connection, input|
        get("/v2/users", per_page: 1).
          headers("Harvest-Account-Id" => input["account_id"]).
          dig("users", 0) || {}
      end
    }
  },

  pick_lists: {
    accounts: lambda do |_connection|
      get("https://id.getharvest.com/api/v2/accounts")["accounts"]&.
        pluck("name", "id")
    end,

    bill_by_options: lambda do |_connection|
      [%w[Project Project], %w[Tasks Tasks], %w[People People], %w[None none]]
    end,

    budget_by_options: lambda do |_connection|
      [%w[Hours\ Per\ Project project], %w[Total\ Project\ Fees project_cost],
       %w[Hours\ Per\ Task task], %w[Fees\ Per\ Task task_fees],
       %w[Hours\ Per\ Person person], %w[No\ Budget none]]
    end,

    currencies: lambda do |_connection|
      [%w[United\ States\ Dollar USD], %w[British\ Pound GBP],
       %w[Australian\ Dollar AUD], %w[Canadian\ Dollar CAD],
       %w[Japanese\ Yen JPY], %w[United\ Arab\ Emirates\ Dirham AED],
       %w[Afghan\ Afghani AFN], %w[Albanian\ Lek ALL], %w[Armenian\ Dram AMD],
       %w[Netherlands\ Antillean\ Gulden ANG], %w[Angolan\ Kwanza AOA],
       %w[Argentine\ Peso ARS], %w[Aruban\ Florin AWG],
       %w[Azerbaijani\ Manat AZN],
       %w[Bosnia\ and\ Herzegovina\ Convertible\ Mark BAM],
       %w[Barbadian\ Dollar BBD],
       %w[Bangladeshi\ Taka BDT], %w[Bulgarian\ Lev BGN],
       %w[Bahraini\ Dinar BHD],
       %w[Burundian\ Franc BIF], %w[Bermudian\ Dollar BMD],
       %w[Brunei\ Dollar BND],
       %w[Bolivian\ Boliviano BOB], %w[Brazilian\ Real BRL],
       %w[Bahamian\ Dollar BSD],
       %w[Bhutanese\ Ngultrum BTN], %w[Botswana\ Pula BWP],
       %w[Belarusian\ Ruble BYN], %w[Belarusian\ Ruble BYR],
       %w[Belize\ Dollar BZD],
       %w[Congolese\ Franc CDF], %w[Swiss\ Franc CHF],
       %w[Unidad\ de\ Fomento CLF],
       %w[Chilean\ Peso CLP], %w[Chinese\ Renminbi\ Yuan CNY],
       %w[Colombian\ Peso COP],
       %w[Costa\ Rican\ Colón CRC], %w[Cuban\ Convertible\ Peso CUC],
       %w[Cuban\ Peso CUP], %w[Cape\ Verdean\ Escudo CVE],
       %w[Czech\ Koruna CZK], %w[Djiboutian\ Franc DJF], %w[Danish\ Krone DKK],
       %w[Dominican\ Peso DOP], %w[Algerian\ Dinar DZD],
       %w[Egyptian\ Pound EGP],
       %w[Eritrean\ Nakfa ERN], %w[Ethiopian\ Birr ETB], %w[Fijian\ Dollar FJD],
       %w[Falkland\ Pound FKP], %w[Georgian\ Lari GEL], %w[Ghanaian\ Cedi GHS],
       %w[Gibraltar\ Pound GIP], %w[Gambian\ Dalasi GMD],
       %w[Guinean\ Franc GNF],
       %w[Guatemalan\ Quetzal GTQ], %w[Guyanese\ Dollar GYD],
       %w[Hong\ Kong\ Dollar HKD], %w[Honduran\ Lempira HNL],
       %w[Croatian\ Kuna HRK],
       %w[Haitian\ Gourde HTG], %w[Hungarian\ Forint HUF],
       %w[Indonesian\ Rupiah IDR],
       %w[Israeli\ New\ Sheqel ILS], %w[Indian\ Rupee INR],
       %w[Iraqi\ Dinar IQD],
       %w[Iranian\ Rial IRR], %w[Icelandic\ Króna ISK],
       %w[Jamaican\ Dollar JMD],
       %w[Jordanian\ Dinar JOD], %w[Kenyan\ Shilling KES],
       %w[Kyrgyzstani\ Som KGS],
       %w[Cambodian\ Riel KHR], %w[Comorian\ Franc KMF],
       %w[North\ Korean\ Won KPW],
       %w[South\ Korean\ Won KRW], %w[Kuwaiti\ Dinar KWD],
       %w[Cayman\ Islands\ Dollar KYD],
       %w[Kazakhstani\ Tenge KZT], %w[Lao\ Kip LAK], %w[Lebanese\ Pound LBP],
       %w[Sri\ Lankan\ Rupee LKR], %w[Liberian\ Dollar LRD],
       %w[Lesotho\ Loti LSL], %w[Lithuanian\ Litas LTL],
       %w[Latvian\ Lats LVL], %w[Libyan\ Dinar LYD], %w[Moroccan\ Dirham MAD],
       %w[Moldovan\ Leu MDL], %w[Malagasy\ Ariary MGA],
       %w[Macedonian\ Denar MKD], %w[Myanmar\ Kyat MMK],
       %w[Mongolian\ Tögrög MNT], %w[Macanese\ Pataca MOP],
       %w[Mauritanian\ Ouguiya MRO], %w[Mauritian\ Rupee MUR],
       %w[Maldivian\ Rufiyaa MVR], %w[Malawian\ Kwacha MWK],
       %w[Mexican\ Peso MXN], %w[Malaysian\ Ringgit MYR],
       %w[Mozambican\ Metical MZN], %w[Namibian\ Dollar NAD],
       %w[Nigerian\ Naira NGN], %w[Nicaraguan\ Córdoba NIO],
       %w[Norwegian\ Krone NOK], %w[Nepalese\ Rupee NPR],
       %w[New\ Zealand\ Dollar NZD], %w[Omani\ Rial OMR],
       %w[Panamanian\ Balboa PAB], %w[Peruvian\ Sol PEN],
       %w[Papua\ New\ Guinean\ Kina PGK], %w[Philippine\ Peso PHP],
       %w[Pakistani\ Rupee PKR], %w[Polish\ Złoty PLN],
       %w[Paraguayan\ Guaraní PYG], %w[Qatari\ Riyal QAR],
       %w[Romanian\ Leu RON], %w[Serbian\ Dinar RSD],
       %w[Russian\ Ruble RUB], %w[Rwandan\ Franc RWF],
       %w[Saudi\ Riyal SAR], %w[Solomon\ Islands\ Dollar SBD],
       %w[Seychellois\ Rupee SCR], %w[Sudanese\ Pound SDG],
       %w[Swedish\ Krona SEK], %w[Singapore\ Dollar SGD],
       %w[Saint\ Helenian\ Pound SHP], %w[Slovak\ Koruna SKK],
       %w[Sierra\ Leonean\ Leone SLL], %w[Somali\ Shilling SOS],
       %w[Surinamese\ Dollar SRD], %w[South\ Sudanese\ Pound SSP],
       %w[São\ Tomé\ and\ Príncipe\ Dobra STD],
       %w[Salvadoran\ Colón SVC], %w[Syrian\ Pound SYP],
       %w[Swazi\ Lilangeni SZL], %w[Thai\ Baht THB],
       %w[Tajikistani\ Somoni TJS], %w[Turkmenistani\ Manat TMT],
       %w[Tunisian\ Dinar TND], %w[Tongan\ Paʻanga TOP],
       %w[Turkish\ Lira TRY], %w[Trinidad\ and\ Tobago\ Dollar TTD],
       %w[New\ Taiwan\ Dollar TWD], %w[Tanzanian\ Shilling TZS],
       %w[Ukrainian\ Hryvnia UAH], %w[Ugandan\ Shilling UGX],
       %w[Uruguayan\ Peso UYU], %w[Uzbekistan\ Som UZS],
       %w[Venezuelan\ Bolívar VEF], %w[Vietnamese\ Đồng VND],
       %w[Vanuatu\ Vatu VUV], %w[Samoan\ Tala WST],
       %w[Central\ African\ Cfa\ Franc XAF], %w[Silver\ (Troy\ Ounce) XAG],
       %w[Gold\ (Troy\ Ounce) XAU], %w[European\ Composite\ Unit XBA],
       %w[European\ Monetary\ Unit XBB], %w[European\ Unit\ of\ Account\ 9 XBC],
       %w[European\ Unit\ of\ Account\ 17 XBD], %w[East\ Caribbean\ Dollar XCD],
       %w[Special\ Drawing\ Rights XDR], %w[West\ African\ Cfa\ Franc XOF],
       %w[Palladium XPD], %w[Cfp\ Franc XPF], %w[Platinum XPT],
       %w[Yemeni\ Rial YER], %w[South\ African\ Rand ZAR],
       %w[Zambian\ Kwacha ZMK], %w[Zambian\ Kwacha ZMW] ]
    end,

    time_zones: lambda do |_connection|
      [%w[American\ Samoa Pacific/Pago_Pago],
       %w[International\ Date\ Line\ West Pacific/Midway],
       %w[Midway\ Island Pacific/Midway], %w[Hawaii Pacific/Honolulu],
       %w[Alaska America/Juneau],
       %w[Pacific\ Time\ (US\ &\ Canada) America/Los_Angeles],
       %w[Tijuana America/Tijuana], %w[Arizona America/Phoenix],
       %w[Chihuahua America/Chihuahua], %w[Mazatlan America/Mazatlan],
       %w[Mountain\ Time\ (US\ &\ Canada) America/Denver],
       %w[Central\ America America/Guatemala],
       %w[Central\ Time\ (US\ &\ Canada) America/Chicago],
       %w[Guadalajara America/Mexico_City],
       %w[Mexico\ City America/Mexico_City],
       %w[Monterrey America/Monterrey], %w[Saskatchewan America/Regina],
       %w[Bogota America/Bogota],
       %w[Eastern\ Time\ (US\ &\ Canada) America/New_York],
       %w[Indiana\ (East) America/Indiana/Indianapolis],
       %w[Lima America/Lima], %w[Quito America/Lima],
       %w[Atlantic\ Time\ (Canada) America/Halifax],
       %w[Caracas America/Caracas], %w[Georgetown America/Guyana],
       %w[La\ Paz America/La_Paz], %w[Santiago America/Santiago],
       %w[Newfoundland America/St_Johns], %w[Brasilia America/Sao_Paulo],
       %w[Buenos\ Aires America/Argentina/Buenos_Aires],
       %w[Greenland America/Godthab], %w[Montevideo America/Montevideo],
       %w[Mid-Atlantic Atlantic/South_Georgia],
       %w[Azores Atlantic/Azores], %w[Cape\ Verde\ Is. Atlantic/Cape_Verde],
       %w[Casablanca Africa/Casablanca], %w[Dublin Europe/Dublin],
       %w[Edinburgh Europe/London], %w[Lisbon Europe/Lisbon],
       %w[London Europe/London], %w[Monrovia Africa/Monrovia],
       %w[UTC Etc/UTC], %w[Amsterdam Europe/Amsterdam],
       %w[Belgrade Europe/Belgrade], %w[Berlin Europe/Berlin],
       %w[Bern Europe/Zurich], %w[Bratislava Europe/Bratislava],
       %w[Brussels Europe/Brussels], %w[Budapest Europe/Budapest],
       %w[Copenhagen Europe/Copenhagen], %w[Ljubljana Europe/Ljubljana],
       %w[Madrid Europe/Madrid], %w[Paris Europe/Paris],
       %w[Prague Europe/Prague], %w[Rome Europe/Rome],
       %w[Sarajevo Europe/Sarajevo], %w[Skopje Europe/Skopje],
       %w[Stockholm Europe/Stockholm], %w[Vienna Europe/Vienna],
       %w[Warsaw Europe/Warsaw], %w[West\ Central\ Africa Africa/Algiers],
       %w[Zagreb Europe/Zagreb], %w[Zurich Europe/Zurich],
       %w[Athens Europe/Athens], %w[Bucharest Europe/Bucharest],
       %w[Cairo Africa/Cairo], %w[Harare Africa/Harare],
       %w[Helsinki Europe/Helsinki], %w[Jerusalem Asia/Jerusalem],
       %w[Kaliningrad Europe/Kaliningrad], %w[Kyiv Europe/Kiev],
       %w[Pretoria Africa/Johannesburg], %w[Riga Europe/Riga],
       %w[Sofia Europe/Sofia], %w[Tallinn Europe/Tallinn],
       %w[Vilnius Europe/Vilnius], %w[Baghdad Asia/Baghdad],
       %w[Istanbul Europe/Istanbul], %w[Kuwait Asia/Kuwait],
       %w[Minsk Europe/Minsk],
       %w[Moscow Europe/Moscow], %w[Nairobi Africa/Nairobi],
       %w[Riyadh Asia/Riyadh], %w[St.\ Petersburg Europe/Moscow],
       %w[Volgograd Europe/Volgograd], %w[Tehran Asia/Tehran],
       %w[Abu\ Dhabi Asia/Muscat], %w[Baku Asia/Baku], %w[Muscat Asia/Muscat],
       %w[Samara Europe/Samara], %w[Tbilisi Asia/Tbilisi],
       %w[Yerevan Asia/Yerevan], %w[Kabul Asia/Kabul],
       %w[Ekaterinburg Asia/Yekaterinburg], %w[Islamabad Asia/Karachi],
       %w[Karachi Asia/Karachi], %w[Tashkent Asia/Tashkent],
       %w[Chennai Asia/Kolkata], %w[Kolkata Asia/Kolkata],
       %w[Mumbai Asia/Kolkata],
       %w[New\ Delhi Asia/Kolkata], %w[Sri\ Jayawardenepura Asia/Colombo],
       %w[Kathmandu Asia/Kathmandu], %w[Almaty Asia/Almaty],
       %w[Astana Asia/Dhaka], %w[Dhaka Asia/Dhaka], %w[Urumqi Asia/Urumqi],
       %w[Rangoon Asia/Rangoon], %w[Bangkok Asia/Bangkok],
       %w[Hanoi Asia/Bangkok], %w[Jakarta Asia/Jakarta],
       %w[Krasnoyarsk Asia/Krasnoyarsk], %w[Novosibirsk Asia/Novosibirsk],
       %w[Beijing Asia/Shanghai], %w[Chongqing Asia/Chongqing],
       %w[Hong\ Kong Asia/Hong_Kong], %w[Irkutsk Asia/Irkutsk],
       %w[Kuala\ Lumpur Asia/Kuala_Lumpur], %w[Perth Australia/Perth],
       %w[Singapore Asia/Singapore],
       %w[Taipei Asia/Taipei], %w[Ulaanbaatar Asia/Ulaanbaatar],
       %w[Osaka Asia/Tokyo], %w[Sapporo Asia/Tokyo], %w[Seoul Asia/Seoul],
       %w[Tokyo Asia/Tokyo], %w[Yakutsk Asia/Yakutsk],
       %w[Adelaide Australia/Adelaide], %w[Darwin Australia/Darwin],
       %w[Brisbane Australia/Brisbane], %w[Canberra Australia/Melbourne],
       %w[Guam Pacific/Guam], %w[Hobart Australia/Hobart],
       %w[Melbourne Australia/Melbourne],
       %w[Port\ Moresby Pacific/Port_Moresby],
       %w[Sydney Australia/Sydney], %w[Vladivostok Asia/Vladivostok],
       %w[Magadan Asia/Magadan], %w[New\ Caledonia Pacific/Noumea],
       %w[Solomon\ Is. Pacific/Guadalcanal],
       %w[Srednekolymsk Asia/Srednekolymsk], %w[Auckland Pacific/Auckland],
       %w[Fiji Pacific/Fiji], %w[Kamchatka Asia/Kamchatka],
       %w[Marshall\ Is. Pacific/Majuro], %w[Wellington Pacific/Auckland],
       %w[Chatham\ Is. Pacific/Chatham], %w[Nuku’alofa Pacific/Tongatapu],
       %w[Samoa Pacific/Apia], %w[Tokelau\ Is. Pacific/Fakaofo]]
    end
  }
}
