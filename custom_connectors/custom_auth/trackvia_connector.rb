# frozen_string_literal: true

{
  title: 'TrackVia',
  connection: {
    fields: [
      {
        name: 'access_token',
        label: 'Auth Token',
        hint: "Please find the Auth Token <a href='https://go.trackvia.com' \
            '/#/account' target='_blank'>here</a>",
        control_type: 'password',
        optional: false
      },
      {
        name: 'user_key',
        label: 'API Key',
        hint: "Please find the API Key <a href='https://go.trackvia.com' \
          '/#/account' target='_blank'>here</a>",
        control_type: 'password',
        optional: false
      }
    ],
    authorization: {
      apply: lambda { |connection|
        params(user_key: connection['user_key'])
        params(access_token: connection['access_token'])
      }
    },
    base_uri: lambda { |_connection| 'https://go.trackvia.com' }
  },
  test: lambda { |_connection| get('/openapi/views') },
  methods: {
    get_type: lambda do |input|
      type = input[:type]
      name = input[:name]

      if %w[id ID].include?(name)
        :number
      else
        case type
        when 'number', 'currency', 'percentage',
             'autoIncrement', 'relationship'
          :number
        when 'date'
          :date
        when 'datetime'
          :date_time
        when 'point'
          :object
        else
          :string
        end
      end
    end,
    get_control_type: lambda do |input|
      type = input[:type]
      name = input[:name]

      control_type_dictionary = {
        'paragraph' => 'text-area',
        'number' => 'number',
        'currency' => 'number',
        'percentage' => 'number',
        'autoIncrement' => 'number',
        'relationship' => 'integer',
        'checkbox' => 'multiselect',
        'dropDown' => 'select',
        'date' => 'date',
        'datetime' => 'date_time',
        'email' => 'email'
      }

      if %w[id ID].include?(name)
        'integer'
      else
        control_type_dictionary[type]
      end
    end,
    get_picklist_options: lambda do |input|
      choices = input[:choices]
      unless choices == nil
        choices.map do |choice|
          [choice, choice]
        end
      end
    end,
    get_properties: lambda do |input|
      type = input[:type]

      if type == 'point'
        [
          {
            name: 'latitude',
            type: 'number',
            control_type: 'number',
            optional: false
          },
          {
            name: 'longitude',
            type: 'number',
            control_type: 'number',
            optional: false
          }
        ]
      end
    end,
    get_delimeter: lambda do |input|
      type = input[:type]
      ',' if type == 'checkbox'
    end,
    get_output_fields: lambda do |input|
      view_id = input[:view_id]
      get("/openapi/views/#{view_id}")['structure']
        .map do |field|
        {
          name: field['name'],
          label: field['name'],
          optional: !field['required'],
          type: call(:get_type,
                     type: field['type'],
                     name: field['name']),
          control_type: call(:get_control_type,
                             type: field['type']),
          properties: call(:get_properties,
                           type: field['type'])
        }
      end
    end,
    get_fields: lambda do |input|
      view_id = input[:view_id]
      structure = get("/openapi/views/#{view_id}")['structure']
                  .reject do |field|
        !field['canCreate'] || !field['canUpdate']
      end

      structure.map do |field|
        {
          name: field['name'],
          label: field['name'],
          optional: !field['required'],
          type: call(:get_type, type: field['type']),
          control_type: call(:get_control_type,
                             type: field['type'],
                             name: field['name']),
          pick_list: call(:get_picklist_options,
                          choices: field['choices']),
          delimiter: call(:get_delimeter,
                          type: field['type']),
          properties: call(:get_properties,
                           type: field['type'])
        }
      end
    end
  },
  object_definitions: {
    app: {
      fields: lambda do
        [
          { name: 'name' },
          { name: 'id', type: :integer }
        ]
      end
    },
    view: {
      fields: lambda do
        [
          { name: 'id', type: :integer },
          { name: 'name' },
          { name: 'applicationName' },
          { name: 'default', type: :boolean }
        ]
      end
    },
    record: {
      fields: lambda { |_connection, config_fields|
        call(:get_fields, view_id: config_fields['view_id'])
      }
    },
    response_record: {
      fields: lambda { |_connection, config_fields|
        call(:get_output_fields, view_id: config_fields['view_id'])
      }
    },
    hook_body: {
      fields: lambda { |_connection, config_fields|
        call(:get_output_fields, view_id: config_fields['view_id'])
      }
    },
    request: {
      fields: lambda do |_connection, config_fields|
        [
          {
            name: 'data',
            type: :array,
            of: :object,
            properties: [
              call(:get_fields, view_id: config_fields['view_id'])
              # { name: 'fieldName' },
            ]
          }
          # { name: 'data', type: :array, of: :record }
        ]
      end
    },
    user: {
      fields: lambda do
        [
          { name: 'Status' },
          { name: 'Time Zone' },
          { name: 'Email' },
          { name: 'Record ID' },
          { name: 'Updated', type: :date_time },
          { name: 'First Name' },
          { name: 'id', type: :integer },
          { name: 'Last Name' },
          { name: 'Created', type: :date_time }
        ]
      end
    },
    column: {
      fields: lambda do
        [
          { name: 'name' },
          { name: 'type' },
          { name: 'required', type: :boolean },
          { name: 'unique', type: :boolean },
          { name: 'canRead', type: :boolean },
          { name: 'canUpdate', type: :boolean },
          { name: 'canCreate', type: :boolean },
          { name: 'displayOrder', type: :integer },
          { name: 'relationshipSize', type: :integer },
          { name: 'propertyName' }
        ]
      end
    }
  },
  pick_lists: {
    apps: lambda { |_connection| get('/openapi/apps').pluck('name', 'name') },
    views: lambda do |_connection, app_name:|
      get('/openapi/views')
        .select do |view|
          view['applicationName'] == app_name
        end
        .after_error_response(/.*/) do |code, body, header, message|
          error("#{message} : #{body}")
        end
        .pluck('name', 'id')
    end
  },
  actions: {
    # GET requests
    get_all_view_records: {
      description: "Gets&nbsp;<span class='provider'>" \
      'all records</span>&nbsp;for a' \
      "&nbsp;<span class='provider'>TrackVia view</span>.",
      help: 'Gets all records for a specified TrackVia view',
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        }
      ],
      execute: lambda do |_connection, input|
        all_records = []
        start = 0
        max = 100
        first_page = get("/openapi/views/#{input['view_id']}")
                     .params(start: start, max: max)
                     .after_error_response(/.*/) do 
                        |code, body, header, message|
                        error("#{message} : #{body}")
                      end
        total_records = first_page['totalCount']
        all_records = all_records.concat(first_page['data'])
        start = start + max
        while all_records.length < total_records
          page = get("/openapi/views/#{input['view_id']}")
                 .params(start: start, max: max)
                 .after_error_response(/.*/) do 
                    |code, body, header, message|
                    error("#{message} : #{body}")
                  end
          all_records = all_records.concat(page['data'])
          start = start + max
        end
        all_records.each do |hash|
          hash['ID'] = hash.delete 'id'
        end
        { data: all_records, totalCount: total_records }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'data',
            type: :array, of: :object,
            properties: object_definitions['response_record'] },
          { name: 'structure', type: :array, of: :object },
          { name: 'totalCount', type: :integer }
        ]
      end
    },
    # POST requests
    create_user: {
      description: "Create a&nbsp;<span class='provider'>" \
      'new user</span>&nbsp;in' \
      "&nbsp;<span class='provider'>TrackVia</span>.",
      help: 'Create a new user in your TrackVia account',
      config_fields: [
        {
          name: 'email',
          type: 'string',
          control_type: 'text',
          optional: false
        },
        {
          name: 'first_name',
          type: 'string',
          control_type: 'text',
          optional: false
        },
        {
          name: 'last_name',
          type: 'string',
          control_type: 'text',
          optional: false
        },
        # TODO: Change time_zone config field to a picklist selector
        {
          name: 'time_zone',
          type: 'string',
          control_type: 'text',
          optional: true
        }
      ],
      execute: lambda do |_connection, input|
        post('/openapi/users')
          .params(
            email: input['email'],
            firstName: input['first_name'],
            lastName: input['last_name']
          )
          .after_error_response(/.*/) do |code, body, header, message|
            error("#{message} : #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'structure',
            type: :array,
            of: :object,
            properties: object_definitions['column'] },
          { name: 'data',
            type: :array, of: :object,
            properties: object_definitions['user'] }
        ]
      end
    },
    create_record: {
      description: "Create a&nbsp;<span class='provider'>" \
      'new record</span>&nbsp;in&nbsp;' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Create a new record in your TrackVia account',
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        }
      ],
      input_fields: lambda do |object_definitions|
        { name: 'data',
          type: :array, of: :object,
          properties: object_definitions['record'] }
      end,
      execute: lambda do |_connection, input|
        post("/openapi/views/#{input['view_id']}/records")
          .payload(data: input['data'])
          .after_error_response(/.*/) do |code, body, header, message|
            error("#{message} : #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'structure',
            type: :array, of: :object,
            properties: object_definitions['column'] },
          { name: 'data',
            type: :array, of: :object,
            properties: object_definitions['response_record'] },
          { name: 'totalCount', type: :integer }
        ]
      end
    },
    # PUT requests
    update_record: {
      description: "Update an&nbsp;<span class='provider'>" \
      'existing record</span>&nbsp;in&nbsp;' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Update an existing record in your TrackVia account',
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        },
        {
          name: 'id',
          type: 'integer',
          control_type: 'number',
          optional: false
        }
      ],
      input_fields: lambda do |object_definitions|
        { name: 'data',
          type: :array, of: :object,
          properties: object_definitions['record'] }
      end,
      execute: lambda do |_connection, input|
        put("/openapi/views/#{input['view_id']}" \
        "/records/#{input['id']}")
          .payload(data: input['data'])
          .after_error_response(/.*/) do |code, body, header, message|
            error("#{message} : #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'structure',
            type: :array, of: :object,
            properties: object_definitions['column'] },
          { name: 'data',
            type: :array,
            of: :object,
            properties: object_definitions['response_record'] },
          { name: 'totalCount', type: :integer }
        ]
      end
    },
    # DELETE requests
    delete_record: {
      description: "Delete an&nbsp;<span class='provider'>" \
      'existing record</span>&nbsp;in&nbsp;' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Delete an existing record in your TrackVia account',
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        },
        {
          name: 'id',
          type: 'integer',
          control_type: 'number',
          optional: false
        }
      ],
      execute: lambda do |_connection, input|
        delete("/openapi/views/#{input['view_id']}" \
        "/records/#{input['id']}")
        .after_error_response(/.*/) do |code, body, header, message|
          error("#{message} : #{body}")
        end
      end
    },
    delete_all_records_in_view: {
      description: "Delete&nbsp;<span class='provider'>" \
      'all records</span>&nbsp;in a&nbsp;' \
      "<span class='provider'>TrackVia view</span>.",
      help: 'Delete all records in a TrackVia view',
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        }
      ],
      execute: lambda { |_connection, input|
        delete("/openapi/views/#{input['view_id']}/records/all")
          .after_error_response(/.*/) do |code, body, header, message|
            error("#{message} : #{body}")
          end
      }
    }
  },
  triggers: {
    new_record: {
      description: "Created&nbsp;<span class='provider'>" \
      'record</span>&nbsp;in&nbsp;' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Triggers whenever a record is created and&nbsp;' \
      'is added to a specified TrackVia view.',
      type: :paging_desc,
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        }
      ],
      webhook_notification: lambda do |_input, payload|
        # payload[0]
        # HACK: This is a quick fix to replace an
        # issue with webhook responses returning 'id'
        # instead of 'ID'
        hash = payload[0]
        hash['ID'] = hash.delete 'id'
        hash
      end,
      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        post("/openapi/zapier/views/#{input['view_id']}" \
        '/api/hooks',
             target_url: webhook_url,
             event: 'created')
      end,
      webhook_unsubscribe: lambda do |webhook, input|
        delete("/openapi/zapier/views/#{input['view_id']}" \
          "/api/hooks/#{webhook['id']}")
      end,
      output_fields: lambda { |object_definitions|
        object_definitions['hook_body']
      }
    },
    updated_record: {
      description: "Updated&nbsp;<span class='provider'>" \
      'record</span>&nbsp;in&nbsp;' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Triggers whenever a record belonging to&nbsp;' \
      'a specified TrackVia view is updated.',
      type: :paging_desc,
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        }
      ],
      webhook_notification: lambda do |_input, payload|
        # payload[0]
        # HACK: This is a quick fix to replace an issue
        # with webhook responses returning
        # 'id' instead of 'ID'
        hash = payload[0]
        hash['ID'] = hash.delete 'id'
        hash
      end,
      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        post("/openapi/zapier/views/#{input['view_id']}" \
        '/api/hooks',
             target_url: webhook_url,
             event: 'updated')
      end,
      webhook_unsubscribe: lambda do |webhook, input|
        delete("/openapi/zapier/views/#{input['view_id']}" \
          "/api/hooks/#{webhook['id']}")
      end,
      output_fields: lambda { |object_definitions|
        object_definitions['hook_body']
      }
    },
    deleted_record: {
      description: "Deleted&nbsp;<span class='provider'>" \
      'record</span>&nbsp;in&nbsp;' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Triggers whenever a record belonging to&nbsp;' \
      'a specified TrackVia view is deleted.',
      type: :paging_desc,
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true,
          hint: 'Select a TrackVia application from the list above'
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false,
          hint: 'Select an application view from the list above'
        }
      ],
      webhook_notification: lambda { |_input, payload| payload[0] },
      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        post("/openapi/zapier/views/#{input['view_id']}" \
        '/api/hooks',
             target_url: webhook_url,
             event: 'deleted')
      end,
      webhook_unsubscribe: lambda do |webhook, input|
        delete("/openapi/zapier/views/#{input['view_id']}" \
          "/api/hooks/#{webhook['id']}")
      end,
      output_fields: lambda { |object_definitions|
        object_definitions['hook_body']
      }
    }
  }
}
