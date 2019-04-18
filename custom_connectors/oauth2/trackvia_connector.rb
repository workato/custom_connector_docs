{
  title: 'TrackVia',
  connection: {
    fields: [
      {
        name: 'custom_domain',
        label: 'Custom Domain',
        hint: 'Enter your custom TrackVia domain,'\
        ' e.g. customdomain.trackvia.com',
        optional: 'true'
      }
    ],
    authorization: {
      type: 'oauth2',
      client_id: 'Workato',
      client_secret: 'U9n0GXc9c1rj',

      authorization_url: lambda { |connection|
        url = 'https://go.trackvia.com'
        if connection['custom_domain']
          url = "https://#{connection['custom_domain']}"
        end
        params = {
          response_type: 'code'
        }.to_param
        "#{url}/oauth/authorize?" + params
      },

      acquire: lambda do |connection, auth_code|
        url = 'https://go.trackvia.com'
        if connection['custom_domain']
          url = "https://#{connection['custom_domain']}"
        end
        response = post("#{url}/oauth/token")
                   .payload(
                     redirect_uri: 'https://www.workato.com/oauth/callback',
                     grant_type: 'authorization_code',
                     code: auth_code,
                     client_id: 'Workato',
                     client_secret: 'U9n0GXc9c1rj'
                   ).request_format_www_form_urlencoded
        user_key = get("#{url}/3scale/openapiapps")
                   .params(
                     access_token: response['access_token']
                   )[0]['userKey']
        [
          response,
          nil,
          {
            user_key: user_key
          }
        ]
      end,

      refresh: lambda do |connection, refresh_token|
        url = 'https://go.trackvia.com'
        if connection['custom_domain']
          url = "https://#{connection['custom_domain']}"
        end
        response = post("#{url}/oauth/token")
                   .payload(client_id: 'Workato',
                            client_secret: 'U9n0GXc9c1rj',
                            grant_type: 'refresh_token',
                            refresh_token: refresh_token)
                   .request_format_www_form_urlencoded
        user_key = get("#{url}/3scale/openapiapps")
                   .params(
                     access_token: response['access_token']
                   )[0]['userKey']
        response['user_key'] = user_key
        response
      end,

      refresh_on: [401, 403],

      apply: lambda { |connection, access_token|
        params(access_token: access_token,
               user_key: connection['user_key'])
      }
    },
    base_uri: lambda do |connection|
      if connection['custom_domain']
        "https://#{connection['custom_domain']}"
      else
        'https://go.trackvia.com'
      end
    end
  },
  test: ->(_connection) { get('/openapi/views')&.first },
  methods: {
    convert_field: lambda do |input|
      field = input[:field]
      view_id = input[:view_id]
      field_mapping = input[:field_mapping]

      field_mapping ||= call(:get_field_mapping,
                             view_id: view_id)
      field_mapping[field]
    end,

    convert_fields: lambda do |input|
      data = input[:data]
      view_id = input[:view_id]
      field_mapping = input[:field_mapping]

      field_mapping ||= call(:get_field_mapping,
                             view_id: view_id)

      if data.is_a?(Array)
        data.map do |array_value|
          call('convert_fields',
               data: array_value,
               view_id: view_id,
               field_mapping: field_mapping)
        end
      elsif data.is_a?(Hash)
        data.map do |key, value|
          value = call('convert_fields',
                       data: value,
                       view_id: view_id,
                       field_mapping: field_mapping)
          old_key = key
          new_key = key
          new_key = field_mapping[key] if field_mapping[key]
          { key.gsub(old_key, new_key) => value }
        end.inject(:merge)
      else
        data
      end
    end,

    get_field_mapping: lambda do |input|
      view_id = input[:view_id]
      structure = get("/openapi/views/#{view_id}")['structure']
      field_mapping = {}
      structure.map do |field|
        if field['fieldMetaId']
          field_mapping["f_#{field['fieldMetaId']}"] = field['name']
        end
      end
      field_mapping
    end,

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
      field_meta_id = input[:field_meta_id]
      required = input[:required]
      if %w[dropDown checkbox].include?(type)
        {
          name: field_meta_id,
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
          type: call(:get_type,
                     type: field['type'],
                     name: field['name']),
          properties: call(:get_properties,
                           type: field['type'])
        }
      end
    end,

    get_fields: lambda do |input|
      view_id = input[:view_id]
      structure = get("/openapi/views/#{view_id}")['structure']
                  .reject { |field| !field['canCreate'] || !field['canUpdate'] }
      result = structure.map do |field|
        {
          name: "f_#{field['fieldMetaId']}",
          label: field['name'],
          optional: !field['required'],
          type: call(:get_type,
                     type: field['type'],
                     name: field['name']),
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
                             field_meta_id: "f_#{field['fieldMetaId']}",
                             required: !field['required'])
        }
      end
      puts result
      result
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
        call(:get_fields, config_fields)
      }
    },
    response_record: {
      fields: lambda { |_connection, config_fields|
        call(:get_output_fields,
             view_id: config_fields['view_id'].presence || 'users')
      }
    },
    hook_body: {
      fields: lambda { |_connection, config_fields|
        call(:get_output_fields, view_id: config_fields['view_id'])
      }
    }
  },
  pick_lists: {
    apps: ->(_connection) { get('/openapi/apps').pluck('name', 'id') },
    document_fields: lambda do |_connection, view_id:|
      get("/openapi/views/#{view_id}")['structure']
        .select { |field| field['type'] == 'document' }
      &.pluck('name', 'fieldMetaId')
    end,
    image_fields: lambda do |_connection, view_id:|
      get("/openapi/views/#{view_id}")['structure']
        .select { |field| field['type'] == 'document' }
      &.pluck('name', 'fieldMetaId')
    end,
    document_mime_types: lambda do |_connection|
      [
        ['PDF', 'application/pdf'],
        ['CSV', 'text/csv'],
        ['Word', 'application/msword'],
        ['Excel', 'application/vnd.ms-excel'],
        ['Text', 'text/plain']
      ]
    end,
    image_mime_types: lambda do |_connection|
      [
        ['JPEG', 'image/jpeg'],
        ['PNG', 'image/png'],
        ['GIF', 'image/gif'],
        ['SVG', 'image/svg+xml']
      ]
    end,
    views: lambda do |_connection, app_id:|
      apps = {}
      get('/openapi/apps').map do |app|
        apps[app['id'].to_i] = app['name']
      end
      application_name = apps[app_id.to_i]
      views = get('/openapi/views')
              .after_error_response(/.*/) do |_code, body, _header, message|
        error("#{message} : #{body}")
      end

      selected_views = views.select do |view|
        view['applicationName'] == application_name
      end

      picklist_values = []
      selected_views.each do |selected_view|
        picklist_values << [selected_view['name'], selected_view['id']]
      end

      picklist_values
    end
  },
  actions: {
    # GET requests
    get_records_from_view: {
      description: "Get <span class='provider'>" \
      'records</span> from a view in ' \
      "<span class='provider'>TrackVia</span>.",
      help: 'Fetches records for a specified view in TrackVia. '\
      'Limit to 1000 records.',
      config_fields: [
        {
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        }
      ],

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'number_of_records',
            label: 'Number of Records',
            type: 'integer',
            control_type: 'number',
            optional: false,
            hint: 'Number of records to retrieve from the view. Limit 1000.'
          },
          {
            name: 'start_index',
            label: 'Index',
            type: 'integer',
            control_type: 'number',
            optional: true,
            hint: 'Record index to start at'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        start = input['start_index'] || 0
        max = input['number_of_records'] || 1
        start = start.to_i
        max = max.to_i
        start = 0 if start < 0

        if max > 1000
          max = 1000
        elsif max < 1
          max = 1
        end

        records =
          get("/openapi/views/#{input['view_id']}")
          .params(start: start, max: max)
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message} : #{body}")
          end['data']
        records.each do |hash|
          hash['ID'] = hash.delete 'id'
        end
        { records: records }
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        },
        {
          name: 'value_to_find',
          label: 'Value to find',
          type: 'string',
          optional: 'false'
        }
      ],

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'number_of_records',
            label: 'Number of Records',
            type: 'integer',
            control_type: 'number',
            optional: false,
            hint: 'Number of records to retrieve from the view. Limit 1000.'
          },
          {
            name: 'start_index',
            label: 'Index',
            type: 'integer',
            control_type: 'number',
            optional: true,
            hint: 'Record index to start at'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        start = input['start_index'] || 0
        max = input['number_of_records'] || 1
        start = start.to_i
        max = max.to_i

        start = 0 if start < 0

        if max > 1000
          max = 1000
        elsif max < 1
          max = 1
        end

        records =
          get("/openapi/views/#{input['view_id']}/find")
          .params(start: start, max: max, q: input[:value_to_find])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message} : #{body}")
          end['data']
        records.each do |hash|
          hash['ID'] = hash.delete 'id'
        end
        { records: records }
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
    get_document_from_record: {
      description: "Get <span class='provider'>document</span> from " \
      "a record in <span class='provider'>TrackVia</span>.",
      help: "Retreive a file from a record's document field in TrackVia. " \
      "To retrieve a record from a record's image field, please use " \
      "'Get image from record'",
      config_fields: [
        {
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
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
          name: 'document_field',
          label: 'Document Field',
          type: 'string',
          control_type: 'select',
          pick_list: 'document_fields',
          pick_list_params: { view_id: 'view_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        }
      ],

      execute: lambda do |_connection, input|
        document_field = call(:convert_field,
                              field: input['document_field'],
                              view_id: input['view_id'],
                              field_mapping: nil)
        {
          "content": get("/openapi/views/#{input['view_id']}" \
            "/records/#{input['id']}/files/#{document_field}")
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
    get_image_from_record: {
      description: "Get <span class='provider'>image</span> from " \
      "a record in <span class='provider'>TrackVia</span>.",
      help: "Retreive an image from a record's image field in TrackVia",
      config_fields: [
        {
          name: 'app_id',
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
          pick_list_params: { app_id: 'app_id' },
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
          name: 'image_field',
          label: 'Image Field',
          type: 'string',
          control_type: 'select',
          pick_list: 'image_fields',
          pick_list_params: { view_id: 'view_id' },
          optional: false,
          hint: 'Select an available image field from the list above.'
        }
      ],

      execute: lambda do |_connection, input|
        {
          "content": get("/openapi/views/#{input['view_id']}" \
            "/records/#{input['id']}/files/#{input['image_field']}")
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
        end
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        }
      ],
      input_fields: lambda do |object_definitions|
        { name: 'data',
          label: 'Record',
          type: :array, of: :object,
          properties: object_definitions['record'] }
      end,

      execute: lambda do |_connection, input|
        post("/openapi/views/#{input['view_id']}/records")
          .payload(data: call(:convert_fields,
                              data: input['data'],
                              view_id: input['view_id'],
                              field_mapping: nil))
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message} : #{body}")
        end
      end,

      output_fields: lambda { |object_definitions|
        { name: 'data',
          type: :array, of: :object,
          properties: object_definitions['response_record'] }
      },

      sample_output: lambda { |_connection, input|
        call(:get_fields_sample_output, view_id: input['view_id'])
      }
    },
    upload_document_to_record: {
      description: "Upload <span class='provider'>document</span> to " \
      "a record in <span class='provider'>TrackVia</span>.",
      help: "Upload a file to a record's document field in TrackVia",
      config_fields: [
        {
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        },
        {
          name: 'document_field',
          label: 'Document Field',
          type: 'string',
          control_type: 'select',
          pick_list: 'document_fields',
          pick_list_params: { view_id: 'view_id' },
          optional: false,
          hint: 'Select an available document field from the list above.'
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
            pick_list: 'document_mime_types',
            optional: false,
            hint: 'Select an available document type from the list above.',
            toggle_hint: 'Select a common file type',
            toggle_field: {
              name: 'content_type',
              label: 'Content Type',
              type: :string,
              control_type: 'text',
              optional: false,
              toggle_hint: 'Enter a document MIME type',
              hint: 'Enter the MIME type of the file you want to upload. ' \
                'See http://www.iana.org/assignments/media-types/' \
                'media-types.xhtml for the complete list of MIME types '
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        document_field = call(:convert_field,
                              field: input['document_field'],
                              view_id: input['view_id'],
                              field_mapping: nil)
        post("/openapi/views/#{input['view_id']}" \
            "/records/#{input['id']}/files/#{document_field}")
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
    upload_image_to_record: {
      description: "Upload <span class='provider'>image</span> to " \
      "a record in <span class='provider'>TrackVia</span>.",
      help: "Upload an image to a record's image field in TrackVia",
      config_fields: [
        {
          name: 'app_id',
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
          pick_list_params: { app_id: 'app_id' },
          optional: false,
          hint: 'Select an available view from the list above.'
        },
        {
          name: 'image_field',
          label: 'Image Field',
          type: 'string',
          control_type: 'select',
          pick_list: 'image_fields',
          pick_list_params: { view_id: 'view_id' },
          optional: false,
          hint: 'Select an available image field from the list above.'
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
            pick_list: 'image_mime_types',
            optional: false,
            hint: 'Select an available image type from the list above.',
            toggle_hint: 'Select a common image file type',
            toggle_field: {
              name: 'content_type',
              label: 'Content Type',
              type: :string,
              control_type: 'text',
              optional: false,
              toggle_hint: 'Enter a valid image MIME type',
              hint: 'Enter the MIME type of the image you want to upload. ' \
                'See http://www.iana.org/assignments/media-types/' \
                'media-types.xhtml for the complete list of MIME types '
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        image_field = call(:convert_field,
                           field: input['image_field'],
                           view_id: input['view_id'],
                           field_mapping: nil)
        post("/openapi/views/#{input['view_id']}" \
            "/records/#{input['id']}/files/#{image_field}")
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
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
          label: 'Record',
          type: :array, of: :object,
          properties: object_definitions['record'] }
      end,

      execute: lambda do |_connection, input|
        put("/openapi/views/#{input['view_id']}" \
        "/records/#{input['id']}")
          .payload(data: call(:convert_fields,
                              data: input['data'],
                              view_id: input['view_id'],
                              field_mapping: nil))
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
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

      dedup: lambda do |response|
        response['ID'].to_s + '@' + response['Updated'].to_s
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
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

      dedup: lambda do |response|
        response['ID'].to_s + '@' + response['Updated'].to_s
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
          name: 'app_id',
          label: 'App',
          type: 'integer',
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
          pick_list_params: { app_id: 'app_id' },
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
