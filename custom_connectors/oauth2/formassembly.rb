{
  title: "FormAssembly",

  connection: {
    fields: [
      {
        name: "client_id",
        optional: false,
        hint: "Get your API key <a href='https://github.com/veerwest/" \
          "formassembly-api#self-register-your-app-on-an-existing-enterprise" \
          "-instance' target='_blank'>here</a>"
      },
      {
        name: "client_secret",
        optional: false,
        control_type: :password
      },
      {
        name: "endpoint",
        label: "Edition",
        control_type: "select",
        pick_list: [
          %w[FormAssembly\ Developer\ Sandbox https://developer.formassembly.com],
          %w[FormAssembly.com https://app.formassembly.com],
          %w[FormAssembly\ Enterprise\ Cloud https://base.tfaforms.net],
          %w[FormAssembly\ Enterprise\ On-Site https://base/formassembly]
        ],
        optional: false
      },
      {
        name: "base_url",
        ngIf: 'input.endpoint == "https://base/formassembly" ||
          input.endpoint == "https://base.tfaforms.net"',
        label: "Base URL",
        hint: "Use 'workato_formassembly' if that is your instance name or " \
          "'workato.formassembly.com' if your server is " \
          "'https://workato.formassembly.com/'"
      },
    ],

    base_uri: lambda do |connection|
      connection['endpoint'].gsub("base", connection['base_url'] || '')
    end,

    authorization: {
      type: 'oauth2',

      authorization_url: ->(connection) {
        base_url = connection['endpoint'].gsub("base", connection['base_url'] || '')
        "#{base_url}/oauth/login?type=web&client_id=#{connection['client_id']}" +
        "&response_type=code"
      },

      acquire: lambda do |connection, auth_code, redirect_uri|
        base_url = connection['endpoint'].gsub("base", connection['base_url'] || '')
        response = post("#{base_url}/oauth/access_token?type=web_server").
                     payload(
                       client_id: connection['client_id'] || '',
                       client_secret: connection['client_secret'] || '',
                       grant_type: 'authorization_code',
                       code: auth_code,
                       redirect_uri: redirect_uri
                     ).request_format_www_form_urlencoded
        [
          {
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          nil,
          nil
        ]
      end,

      refresh: lambda do |connection, refresh_token|
        base_url = connection['endpoint'].
                     gsub("base", connection['base_url'] || "")
        post("#{base_url}/oauth/access_token?type=web_server").
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401, 403],

      apply: ->(_connection, access_token) {
        params(access_token: access_token)
      },
    },
  },

  object_definitions: {
    form: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "id", type: "integer" },
          { name: "version_id", type: "integer" },
          { name: "name" },
          { name: "category" },
          { name: "subcategory" },
          { name: "is_template", type: "integer",
            hint: "0: Not a template<br>0: Is a template" },
          { name: "display_status", type: "integer",
            hint: "0: Archived<br>2: Active" },
          { name: "moderation_status", type: "integer",
            hint: "0: Not checked<br>2: " \
            "Reviewed and approved<br>3: Reviewed and denied" },
          { name: "expired" },
          { name: "use_ssl" },
          { name: "user_id" },
          { name: "created", type: "timestamp" },
          { name: "modified", type: "timestamp" },
          {
            name: "Aggregate_metadata",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "response_count", type: "integer" },
              { name: "submitted_count", type: "integer" },
              { name: "saved_count", type: "integer" },
              { name: "unread_count", type: "integer" },
              { name: "dropout_rate" },
              { name: "average_completion_time" },
              { name: "is_uptodate", type: "boolean" }
            ]
          }
        ]
      end
    },

    connector: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "id", type: "integer" },
          { name: "form_id", type: "integer" },
          { name: "name" },
          { name: "status", type: "integer",
            hint: "0: Disabled<br>1: Enabled" },
          { name: "event" }
        ]
      end
    }
  },

  actions: {
    list_forms: {
      description: "List <span class='provider'>forms</span> in " \
        "<span class='provider'> FormAssembly </span>",

      execute: ->(_connection, _input) {
        get("/api_v1/forms/index.json")
      },

      output_fields: lambda do |object_definitions|
        [
          {
            name: "Forms",
            type: "array",
            of: "object",
            properties: [
              {
                name: "Form",
                type: "object",
                properties: object_definitions['form']
              }
            ]
          }
        ]
      end,

      sample_output: lambda do |_connection|
        get("/api_v1/forms/index.json").
          dig("Forms", "Form", 0) || {}
      end
    },

    list_connectors: {
      description: "List <span class='provider'>connectors</span> in" \
        "<span class='provider'> FormAssembly </span>",

      config_fields: [
        {
          name: "form",
          control_type: "select",
          pick_list: "forms",
          optional: false
        }
      ],

      execute: ->(_connection, input) {
        get("/api_v1/connectors/index/#{input['form']}.json")
      },

      output_fields: lambda do |object_definitions|
        [
          {
            name: "Connectors",
            type: "array",
            of: "object",
            properties: [
              {
                name: "Connector",
                type: "object",
                properties: object_definitions['connector']
              }
            ]
          }
        ]
      end,

      sample_output: lambda do |_connection, input|
        get("/api_v1/connectors/index/#{input['form']}.json").
          dig("Connectors", "Connector", 0) || {}
      end
    },

    get_connector_by_id: {
      description: "Get <span class='provider'>connector details</span> " \
        "in <span class='provider'> FormAssembly </span>",

      input_fields: lambda do
        [
          { name: "connector_id", optional: false }
        ]
      end,

      execute: ->(_connection, input) {
        get("/api_v1/connectors/view/#{input['connector_id']}.json")
      },

      output_fields: lambda do |object_definitions|
        [
          {
            name: "Form",
            type: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "version_id", type: "integer" },
              { name: "name" }
            ]
          },
          {
            name: "Connector",
            type: "object",
            properties: object_definitions['connector']
          }
        ]
      end,

      sample_output: lambda do |_connection, input|
        get("/api_v1/connectors/view/#{input['connector_id']}.json").
          dig("Connectors", "Connector", 0) || {}
      end
    }
  },

  pick_lists: {
    forms: lambda do |_connection|
      get("/api_v1/forms/index.json")['Forms'].
        map do |form|
          form_data = form['Form']
          [form_data['name'], form_data['id']]
        end
    end
  }
}
