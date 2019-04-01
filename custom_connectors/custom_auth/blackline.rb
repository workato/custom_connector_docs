{
  title: 'BlackLine',

  connection: {
    fields: [
      {
        name: 'environment',
        control_type: 'select',
        pick_list: [%w[Production us], %w[Sandbox sbus]],
        optional: false
      },
      {
        name: 'data_center',
        hint: 'E.g., 2, if the app URL is ' \
          'https://subdomain.us<b>2</b>.blackline.com',
        optional: false
      },
      { name: 'username', optional: false },
      {
        name: 'api_key',
        label: 'API key',
        hint: 'Login to app as System Admin and generate an API key by ' \
          'navigating to - System > Users Admin Grid > User > User Information',
        control_type: 'password',
        optional: false
      },
      {
        name: 'client_id',
        hint: 'E.g., subdomain, if the app URL is ' \
          'https://<b>subdomain</b>.us2.blackline.com',
        optional: false
      },
      { name: 'client_secret', control_type: 'password', optional: false },
      {
        name: 'user_scope',
        hint: 'E.g., DataIngestionAPI instance_ABCD-1234-5AC6-7D89-1C0A2345B6A',
        optional: false
      }
    ],

    base_uri: lambda do |connection|
      "https://#{connection['environment']}#{connection['data_center']}" \
      '.api.blackline.com'
    end,

    authorization: {
      type: 'custom',

      acquire: lambda do |connection|
        auth_header =
          "#{connection['client_id']}:#{connection['client_secret']}"
          .encode_base64
        response = post('/authorize/connect/token')
                   .headers('Authorization' => "Basic #{auth_header}")
                   .payload(grant_type: 'password',
                            password: connection['api_key'],
                            scope: connection['user_scope'],
                            username: connection['username'])
                   .request_format_www_form_urlencoded

        { access_token: response['access_token'] }
      end,

      # TODO: check how to avoid 400: Authentication failed, responses
      refresh_on: [401, /Authentication failed/],

      apply: lambda do |connection|
        headers('Authorization' => "Bearer #{connection['access_token']}")
      end
    }
  },

  test: lambda do |_connection|
    # TODO: fix this. We need to find the heart-beat endpoint to correct this.
    # ATM: Bypassing the test credentials block
    true
  end,

  object_definitions: {
    tsv: {
      fields: lambda do |_connection, _config_fields|
        [{
          name: 'content',
          label: 'TSV contents',
          hint: 'Place contents of TSV (excluding column headers) here',
          optional: false
        }]
      end
    },

    response: {
      fields: lambda do |_connection, _config_fields|
        [{ name: 'import_id', label: 'Import ID', type: 'integer' }]
      end
    }
  },

  actions: {
    # Currency Rates import
    import_currency_rates: {
      description: "Import <span class='provider'>currency rates</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/currency-rates')
          .params('message-version' => 2)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Account Balances Import
    import_account_balances: {
      description: "Import <span class='provider'>account balances</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts')
          .params('message-version' => 5)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Account Settings
    import_account_settings: {
      description: "Import <span class='provider'>account settings</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/settings')
          .params('message-version' => 2)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Subledger Balances
    import_subledger_balances: {
      description: "Import <span class='provider'>subledger balances</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/subledgers')
          .params('message-version' => 4)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Bank Balances
    import_bank_balances: {
      description: "Import <span class='provider'>bank balances</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/bank-balances')
          .params('message-version' => 4)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Item Detail
    import_item_detail: {
      description: "Import <span class='provider'>item detail</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/items')
          .params('message-version' => 5)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Multi Currency Balances
    import_multi_currency_balances: {
      title: 'Import multi-currency balances',
      description: "Import <span class='provider'>multi-currency balances " \
        "</span>in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/multi-currency-balances')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Account Group Settings
    import_account_group_settings: {
      description: "Import <span class='provider'>account group settings" \
        "</span> in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/group-settings')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Account Assignments
    import_account_assignments: {
      description: "Import <span class='provider'>account assignments</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/user-account-assignments')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Account Group Mappings
    import_account_group_mappings: {
      description: "Import <span class='provider'>account group mappings" \
        "</span> in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/accounts/group-mappings')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Entities
    import_entities: {
      description: "Import <span class='provider'>entities</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/entities')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Entity Types
    import_entity_types: {
      description: "Import <span class='provider'>entity types</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/entity-types')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # User Entities
    import_user_entities: {
      description: "Import <span class='provider'>user entities</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/user-entities')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Users
    import_users: {
      description: "Import <span class='provider'>users</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/users')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Teams
    import_teams: {
      description: "Import <span class='provider'>teams</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/teams')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Team Types
    import_team_types: {
      description: "Import <span class='provider'>team types</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/teams-types')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # User Team Assignments
    import_user_team_assignments: {
      description: "Import <span class='provider'>user team assignments" \
        "</span> in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/user-team-assignments')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # User Roles
    import_user_roles: {
      description: "Import <span class='provider'>user roles</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/settings/user-roles')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Tasks
    import_tasks: {
      description: "Import <span class='provider'>tasks</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/tasks')
          .params('message-version' => 2)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Task Dependencies
    import_task_dependencies: {
      description: "Import <span class='provider'>task dependencies</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/tasks/dependencies')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Task Description
    import_task_description: {
      description: "Import <span class='provider'>task description</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/tasks/descriptions')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Tasks Auto-Certify Completion
    import_tasks_auto_certify_completion: {
      title: 'Import tasks auto-certify completion',
      description: "Import <span class='provider'>tasks auto-certify " \
        "completion</span> in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/tasks/auto-certified-completed')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # CIM Mappings
    import_cim_mappings: {
      title: 'Import CIM mappings',
      description: "Import <span class='provider'>CIM mappings</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/cim/mappings')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Variance Settings
    import_variance_settings: {
      description: "Import <span class='provider'>variance settings</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/variance/variance-settings')
          .params('message-version' => 2)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Variance Group Settings
    import_variance_group_settings: {
      description: "Import <span class='provider'>variance group settings" \
        "</span> in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/variance/group-settings')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Variance Group Mapping
    import_variance_group_mapping: {
      description: "Import <span class='provider'>variance group mapping" \
        "</span> in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/variance/group-mappings')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Variance Rules
    import_variance_rules: {
      description: "Import <span class='provider'>variance rules</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/variance/rules')
          .params('message-version' => 1)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    },

    # Budgets
    import_budgets: {
      description: "Import <span class='provider'>budgets</span> " \
        "in <span class='provider'>BlackLine</span>",

      execute: lambda do |_connection, input|
        put('/dataingestion/variance/budgets')
          .params('message-version' => 4)
          .request_body(input['content'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: ->(object_definitions) { object_definitions['tsv'] },

      output_fields: ->(object_definitions) { object_definitions['response'] },

      sample_output: ->(_connection, _input) { { import_id: '123456' } }
    }
  }
}
