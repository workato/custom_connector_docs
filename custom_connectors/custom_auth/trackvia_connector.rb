{
  title: 'TrackVia',
  connection: {
    fields: [
      {
        name: 'user_key',
        label: 'API Key',
        hint: "Click <a href='https://go.trackvia.com/#/account' " \
        "target='_blank'>here</a> to find the API key",
        control_type: 'password',
        optional: false
      },
      {
        name: 'access_token',
        label: 'Auth Token',
        hint: "Click <a href='https://go.trackvia.com/#/account' " \
        "target='_blank'>here</a> to find the Authentication token",
        control_type: 'password',
        optional: false
      },
      {
        name: 'subdomain',
        label: 'Subdomain',
        hint: "Click <a href='https://go.trackvia.com/#/account' " \
        "target='_blank'>here</a> to find your account type",
        type: 'string',
        control_type: 'select',
        pick_list: [
          %w[Standard go],
          %w[Government gov],
          %w[HIPPA hippa]
        ],
        optional: true,
        toggle_hint: 'Select your environment type from the list',
        toggle_field: {
          name: 'subdomain',
          label: 'Private Subdomain',
          type: :string,
          control_type: 'text',
          optional: true,
          toggle_hint: 'Enter your private subdomain',
          hint: 'Enter your subdomain of your private instance. For example, ' \
            'if you login through mydomain.trackvia.com, use mydomain ' \
            'as your subdomain.'
        }
      }
    ],
    authorization: {
      apply: lambda { |connection|
        params(user_key: connection['user_key'],
               access_token: connection['access_token'])
      }
    },
    base_uri: lambda do |connection|
      if connection['sub_domain']
        "https://#{connection['sub_domain']}.trackvia.com"
      else
        'https://go.trackvia.com'
      end
    end
  },
  test: ->(_connection) { get('/openapi/views')&.first },
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
      choices.map { |choice| [choice, choice] } unless choices.blank?
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

    get_toggle_hint: lambda do |input|
      type = input[:type]
      if type == 'dropDown'
        'Select an option from the list'
      elsif type == 'checkbox'
        'Select one or more options from the list'
      end
    end,

    get_toggle_field: lambda do |input|
      type = input[:type]
      name = input[:name]
      required = input[:required]
      if %w[dropDown checkbox].include?(type)
        {
          name: name,
          label: name,
          type: :string,
          control_type: 'text',
          optional: required,
          toggle_hint: "Set #{name} manually",
          hint: 'Please ensure that the value provided is valid'
        }
      end
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
                  .reject { |field| !field['canCreate'] || !field['canUpdate'] }
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
                           type: field['type']),
          toggle_hint: call(:get_toggle_hint,
                            type: field['type'],
                            name: field['name']),
          toggle_field: call(:get_toggle_field,
                             type: field['type'],
                             name: field['name'],
                             required: !field['required'])
        }
      end
    end,

    get_fields_sample_output: lambda do |input|
      view_id = input[:view_id]
      get("/openapi/views/#{view_id}?start=0&max=1")
        .dig('data', 0)
    end
  },
  object_definitions: {
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
    }
  },
  pick_lists: {
    apps: ->(_connection) { get('/openapi/apps').pluck('name', 'name') },
    document_fields: lambda do |_connection, view_id:|
      document_fields = get("/openapi/views/#{view_id}")['structure']
                        .select { |field| field['type'] == 'document' }
                        &.pluck('name', 'name')
      output = []

      document_fields.each do |key, value|
        output << [key, value.gsub(' ', '%20')]
      end

      output
    end,
    mime_types: lambda do |_connection|
      [
        ['PDF', 'application/pdf'],
        ['CSV', 'text/csv'],
        ['Word', 'application/msword'],
        ['Excel', 'application/vnd.ms-excel'],
        ['Text', 'text/plain']
      ]
    end,
    views: lambda do |_connection, app_name:|
      get('/openapi/views')
        .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message} : #{body}")
        end&.select { |view| view['applicationName'] == app_name }
        &.pluck('name', 'id')
    end
  },
  actions: {
    # GET requests
    get_all_view_records: {
      description: "Get all <span class='provider'>" \
      'records</span> from a view in ' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Fetches all records for a specified view in TrackVia',
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
          hint: 'Select an available view from the list above.'
        }
      ],

      execute: lambda do |_connection, input|
        all_records = []
        start = 0
        max = 100
        first_page =
          get("/openapi/views/#{input['view_id']}")
          .params(start: start, max: max)
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message} : #{body}")
          end
        total_records = first_page['totalCount']
        all_records = all_records.concat(first_page['data'])
        start = start + max
        while all_records.length < total_records
          page =
            get("/openapi/views/#{input['view_id']}")
            .params(start: start, max: max)
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message} : #{body}")
            end
          all_records = all_records.concat(page['data'])
          start = start + max
        end
        all_records.each do |hash|
          hash['ID'] = hash.delete 'id'
        end
        { records: all_records }
      end,

      output_fields: lambda { |object_definitions|
        { name: 'records',
          type: :array, of: :object,
          properties: object_definitions['response_record'] }
      },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    find_records_in_view: {
      description: "Find <span class='provider'>" \
      'records</span> in a view in ' \
      "<span class='provider'>TrackVia</span>" \
      ' that contains a specific value.',
      help: 'Find all records for a specified view in TrackVia ' \
      'that has data that matches a provided value.',
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
          hint: 'Select an available view from the list above.'
        },
        {
          name: 'value_to_find',
          label: 'Value to find',
          type: 'string',
          hint: 'Data to find',
          optional: 'false'
        }
      ],

      execute: lambda do |_connection, input|
        all_records = []
        start = 0
        max = 100
        first_page =
          get("/openapi/views/#{input['view_id']}/find")
          .params(start: start, max: max, q: input[:value_to_find])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message} : #{body}")
          end
        total_records = first_page['totalCount']
        all_records = all_records.concat(first_page['data'])
        start = start + max
        while all_records.length < total_records
          page =
            get("/openapi/views/#{input['view_id']}")
            .params(start: start, max: max, q: input[:value_to_find])
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message} : #{body}")
            end
          all_records = all_records.concat(page['data'])
          start = start + max
        end
        all_records.each do |hash|
          hash['ID'] = hash.delete 'id'
        end
        { records: all_records }
      end,

      output_fields: lambda { |object_definitions|
        { name: 'records',
          type: :array, of: :object,
          properties: object_definitions['response_record'] }
      },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    get_file_from_record: {
      description: "Get <span class='provider'>file</span> from " \
      "a record in <span class='provider'>TrackVia</span>.",
      help: "Retreive a file from a record's document field in TrackVia",
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
          hint: 'Select an available view from the list above.'
        },
        {
          name: 'id',
          type: 'integer',
          control_type: 'number',
          optional: false
        },
        {
          name: 'field_name',
          label: 'Field Name',
          type: 'string',
          control_type: 'select',
          pick_list: 'document_fields',
          pick_list_params: { view_id: 'view_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        }
      ],

      execute: lambda do |_connection, input|
        {
          "content": get("/openapi/views/#{input['view_id']}" \
            "/records/#{input['id']}/files/#{input['field_name']}")
            .headers("Content-Type": 'text/plain')
            .response_format_raw
        }
      end,

      output_fields: lambda do
        [
          { name: 'content' }
        ]
      end,

      sample_output: lambda do
        { "content": 'test' }
      end
    },
    # POST requests
    create_user: {
      description: "Create <span class='provider'>user</span> " \
      "in <span class='provider'>TrackVia</span>",
      help: 'Create a user in TrackVia',
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
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message} : #{body}")
          end['data']
      end,

      output_fields: lambda { |object_definitions|
        object_definitions['response_record']
      },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    create_record: {
      description: "Create <span class='provider'>record</span> in " \
      "<span class='provider'>TrackVia</span>.",
      help: 'Create a record in TrackVia',
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
          hint: 'Select an available view from the list above.'
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
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message} : #{body}")
        end['data']
      end,

      output_fields: lambda { |object_definitions|
        object_definitions['response_record']
      },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    upload_file_to_record: {
      description: "Upload <span class='provider'>file</span> to " \
      "a record in <span class='provider'>TrackVia</span>.",
      help: "Upload a file to a record's document field in TrackVia",
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
          hint: 'Select an available view from the list above.'
        },
        {
          name: 'field_name',
          label: 'Field Name',
          type: 'string',
          control_type: 'select',
          pick_list: 'document_fields',
          pick_list_params: { view_id: 'view_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        }
      ],
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'id',
            type: 'integer',
            control_type: 'number',
            optional: false
          },
          {
            name: 'content',
            type: 'string',
            control_type: 'text-area',
            optional: false
          },
          {
            name: 'content_type',
            type: 'string',
            control_type: 'select',
            pick_list: 'mime_types',
            optional: false,
            hint: 'Select an available data type from the list above.',
            toggle_hint: 'Select a common file type',
            toggle_field: {
              name: 'content_type',
              label: 'Content Type',
              type: :string,
              control_type: 'text',
              optional: false,
              toggle_hint: 'Enter your private subdomain',
              hint: 'Enter the MIME type of the file you want to upload. ' \
                'See http://www.iana.org/assignments/media-types/' \
                'media-types.xhtml for the complete list of MIME types '
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/openapi/views/#{input['view_id']}" \
            "/records/#{input['id']}/files/#{input['field_name']}")
          .headers(enctype: 'multipart/form-data')
          .payload(file: [input['content'], [input['content_type']]])
          .request_format_multipart_form
      end,

      output_fields: lambda { |object_definitions|
        object_definitions['response_record']
      },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    # PUT requests
    update_record: {
      description: "Update <span class='provider'>record</span> in " \
      "<span class='provider'>TrackVia</span>.",
      help: 'Update a record in TrackVia',
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
          hint: 'Select an available view from the list above.'
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
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message} : #{body}")
          end
      end,

      output_fields: lambda { |object_definitions|
        object_definitions['response_record']
      },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    # DELETE requests
    delete_record: {
      description: "Delete <span class='provider'> record</span> in " \
      "<span class='provider'>TrackVia</span>.",
      help: 'Delete a record in TrackVia',
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
          hint: 'Select an available view from the list above.'
        },
        {
          name: 'id',
          type: 'integer',
          control_type: 'number',
          optional: false
        }
      ],

      execute: lambda do |_connection, input|
        {
          'status':
          delete("/openapi/views/#{input['view_id']}" \
          "/records/#{input['id']}")
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message} : #{body}")
          end&.presence || 'success'
        }
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,

      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    delete_all_records_in_view: {
      description: "Delete all <span class='provider'>" \
      'records</span> from a view in ' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Delete all records from a view in TrackVia',
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
          hint: 'Select an available view from the list above.'
        }
      ],

      execute: lambda do |_connection, input|
        {
          'status':
          delete("/openapi/views/#{input['view_id']}/records/all")
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message} : #{body}")
            end&.presence || 'success'
        }
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,

      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    }
  },
  triggers: {
    new_record: {
      description: "New <span class='provider'>" \
      'record</span> added to view in ' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Triggers when a record is created and added to a TrackVia view.',
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
          hint: 'Select an available view from the list above.'
        }
      ],

      webhook_notification: lambda do |_input, payload|
        hash = payload[0]
        hash['ID'] = hash.delete('id')
        hash
      end,
      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        post("/openapi/zapier/views/#{input['view_id']}/api/hooks",
             target_url: webhook_url,
             event: 'created')
      end,

      webhook_unsubscribe: lambda do |webhook, input|
        delete("/openapi/zapier/views/#{input['view_id']}" \
          "/api/hooks/#{webhook['id']}")
      end,

      output_fields: ->(object_definitions) { object_definitions['hook_body'] },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },

    updated_record: {
      description: "Updated <span class='provider'>" \
      'record</span> in ' \
      "<span class='provider'>TrackVia</span> view",
      help: 'Triggers when a record is updated in a TrackVia view.',
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
          hint: 'Select an available view from the list above.'
        }
      ],

      webhook_notification: lambda do |_input, payload|
        hash = payload[0]
        hash['ID'] = hash.delete('id')
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

      output_fields: ->(object_definitions) { object_definitions['hook_body'] },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    deleted_record: {
      description: "Deleted <span class='provider'>" \
      'record</span> from view in ' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Triggers when a record is deleted from a TrackVia view.',
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
          hint: 'Select an available view from the list above.'
        }
      ],

      webhook_notification: ->(_input, payload) { payload[0] },

      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        post("/openapi/zapier/views/#{input['view_id']}/api/hooks", \
             target_url: webhook_url,
             event: 'deleted')
      end,

      webhook_unsubscribe: lambda do |webhook, input|
        delete("/openapi/zapier/views/#{input['view_id']}" \
          "/api/hooks/#{webhook['id']}")
      end,

      output_fields: ->(object_definitions) { object_definitions['hook_body'] },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    }
  }
}
