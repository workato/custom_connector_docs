{
    title: 'TrackVia',
    connection: {
      fields: [
        {
          name: 'custom_domain',
          control_type: 'subdomain',
          label: 'TrackVia subdomain',
          hint: 'Enter your TrackVia subdomain. e.g. customdomain.trackvia.com. By default, <b>go.trackvia.com</b> will be used.',
          optional: 'true'
        },
        {
          name: 'client_id',
          control_type: 'text',
          label: 'TrackVia App Client ID',
          hint: 'Enter the Client ID of your own OAuth app registered on TrackVia',
          optional: 'false'
        },
        {
          name: 'client_secret',
          control_type: 'text',
          label: 'TrackVia App Client secret',
          hint: 'Enter the Client secret of your own OAuth app registered on TrackVia',
          optional: 'false'
        }
      ],

      authorization: {
        type: 'oauth2',

        authorization_url: lambda { |connection|
          "https://#{connection['custom_domain'].presence || 'go.trackvia.com'}/oauth/authorize?response_type=code"
        },

        acquire: lambda do |connection, auth_code, redirect_uri|
          url = "https://#{connection['custom_domain'].presence || 'go.trackvia.com'}"
          response = post("#{url}/oauth/token").payload(
            redirect_uri: redirect_uri,
            grant_type: 'authorization_code',
            code: auth_code,
            client_id: connection['client_id'],
            client_secret: connection['client_secret']
          ).request_format_www_form_urlencoded
          user_key = get("#{url}/3scale/openapiapps").params(access_token: response['access_token']).dig(0, 'userKey')
          [
            response,
            nil,
            {
              user_key: user_key
            }
          ]
        end,

        refresh: lambda do |connection, refresh_token|
          url = "https://#{connection['custom_domain'].presence || 'go.trackvia.com'}"
          response = post("#{url}/oauth/token").payload(
            client_id: connection['client_id'],
            client_secret: connection['client_secret'],
            grant_type: 'refresh_token',
            refresh_token: refresh_token
          ).request_format_www_form_urlencoded
        end,

        refresh_on: [401, 403],

        apply: lambda { |connection, access_token|
          params(access_token: access_token, user_key: connection['user_key'])
        }
      },

      base_uri: lambda do |connection|
        if connection['custom_domain']
          "https://#{connection['custom_domain']}/openapi/"
        else
          "https://go.trackvia.com/openapi/"
        end
      end
    },

    test: ->(_connection) { get('views') },

    methods: {
      get_all_output_fields: lambda do |input|
        url = input[:view_id].present? ? "views/#{input[:view_id]}" : "users"
        Array.wrap(get(url)&.[]('structure')).reject { |field| field['name'] == "ID" }.map do |field|
          case field['type']
          when 'number', 'currency', 'percentage', 'autoIncrement', 'relationship'
            { type: 'number' }
          when 'date'
            { type: 'date' }
          when 'datetime'
            { type: 'date_time' }
          when 'point'
            { type: 'object', properties: [
              { name: 'latitude', type: 'number', optional: false },
              { name: 'longitude', type: 'number', optional: false }
            ] }
          when 'checkbox'
            { type: :array, of: :object, properties: [
              { name: 'choice' }
            ] }
          else
            {}
          end.merge(name: "f_#{field['fieldMetaId']}", label: field['name'], field_name: field['name'])
        end.concat([{ name: 'id' }])
      end,

      get_output_fields: lambda do |input|
        url = input[:view_id].present? ? "views/#{input[:view_id]}" : "users"
        Array.wrap(get(url)&.[]('structure')).reject { |field| field['name'] == "ID" || %w(image document).include?(field['type']) }.map do |field|
          case field['type']
          when 'number', 'currency', 'percentage', 'autoIncrement', 'relationship'
            { type: 'number' }
          when 'date'
            { type: 'date' }
          when 'datetime'
            { type: 'date_time' }
          when 'point'
            { type: 'object', properties: [
              { name: 'latitude', type: 'number', optional: false },
              { name: 'longitude', type: 'number', optional: false }
            ] }
          when 'checkbox'
            { type: :array, of: :object, properties: [
              { name: 'choice' }
            ] }
          else
            {}
          end.merge(name: "f_#{field['fieldMetaId']}", label: field['name'], field_name: field['name'])
        end.concat([{ name: 'id' }])
      end,

      get_fields: lambda do |input|
        structure = Array.wrap(get("views/#{input[:view_id]}")&.[]('structure')).
                      reject { |field| field['canCreate'].is_not_true? || field['canUpdate'].is_not_true? || %w(image document).include?(field['type']) }
        structure.map do |field|
          # properties = { optional: input['id'].present? ? true : !field['required'], label: field['name'], field_name: field['name'] }
          case field['type']
          when 'number', 'currency', 'autoIncrement', 'relationship'
            { type: 'number' }
          when 'percentage'
            {
              type: 'number',
              hint: "Enter in your percentage as a decimal. i.e. 10% should be entered in as 0.10. If necessary, use the '/'' operator in formula mode to adjust your value."
            }
          when 'date'
            { type: 'date' }
          when 'datetime'
            { type: 'date_time' }
          when 'point'
            { type: 'object', properties: [
              { name: 'latitude', type: 'number', optional: false },
              { name: 'longitude', type: 'number', optional: false }
            ] }
          when 'user'
            { hint: 'Enter the required user ID. User ID can be foun at the end of URL.' }
          when 'userGroup'
            { hint: 'Enter valid user group ID.' }
          when 'checkbox'
            {
              control_type: 'multiselect', delimiter: ',', options: field['choices'].map { |k| [k, k] }, toggle_hint: 'Select from list',
              toggle_field: {
                name: "f_#{field['fieldMetaId']}",
                type: :string,
                label: field['name'],
                control_type: 'text',
                hint: "Valid values are #{field['choices'].map { |k| k }.join(', ')}. For multiple values, enter values separated by (<b>,</b>). Example: <b>choice1,choice2</b>",
                toggle_hint: 'Enter custom value'
              }
            }
          when 'dropDown'
            {
              control_type: 'select', pick_list: field['choices'].map { |k| [k, k] }, toggle_hint: 'Select from list',
              toggle_field: {
                name: "f_#{field['fieldMetaId']}",
                type: :string,
                label: field['name'],
                control_type: 'text',
                hint: "Valid values are #{field['choices'].map { |k| k }.join(', ')}.",
                toggle_hint: 'Enter custom value'
              }
            }
          when 'email'
            { control_type: 'email' }
          else
            {}
          end.merge(name: "f_#{field['fieldMetaId']}", optional: input['id'].present? ? true : !field['required'], label: field['name'], field_name: field['name'])
        end
      end,

      get_fields_sample_output: lambda do |input|
        url = input[:view_id].present? ? "views/#{input[:view_id]}" : "users"
        get("#{url}?start=0&max=1").dig('data', 0)
      end,

      format_input: lambda do |input, e_i_s|
        e_i_s[0]['properties'].each_with_object({}) do |k, hash|
          hash[k['field_name']] = input['data'][k['name']]
        end.compact
      end,

      format_output: lambda do |res, e_o_s|
        res.each do |key, val|
          if val.is_a?(Array) && val.first&.is_a?(String)
            res[key] = val.map { |value| { "choice" => value } }
          end
        end
        e_o_s.each_with_object({}) do |k, hash|
          hash[k['name']] = res[k['label']]
        end.compact.merge('id' => res['id'])
      end
    },

    object_definitions: {
      record: {
        fields: lambda { |_connection, config_fields|
          call(:get_fields, config_fields)
        }
      },

      list_record: {
        fields: lambda { |_connection, config_fields|
          call(:get_all_output_fields, view_id: config_fields['view_id'])
        }
      },

      create_record_output: {
        fields: lambda { |_connection, config_fields|
          call(:get_output_fields, view_id: config_fields['view_id'])
        }
      }
    },

    pick_lists: {
      apps: ->(_connection) { get('apps').pluck('name', 'name') },

      file_fields: lambda do |_connection, view_id:|
        file_fields = Array.wrap(get("views/#{view_id}")&.[]('structure')).select { |field| %w(image document).include?(field['type']) }.pluck('name', 'name')
        file_fields.map { |key, value| [key, value.gsub(' ', '%20')] }
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
        get('views').after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message} : #{body}")
        end&.select { |view| view['applicationName'] == app_name }&.pluck('name', 'id')
      end
    },
    actions: {
      # GET requests
      get_all_view_records: {
        description: "Get all <span class='provider'>records</span> from a view in <span class='provider'>TrackVia</span>",
        help: "Fetches records of a specified view in TrackVia. Maximum of 1000 records will be returned.",

        config_fields: [
          {
            name: 'app_name',
            label: 'Application',
            control_type: 'select',
            pick_list: 'apps',
            optional: false,
            hint: 'Select a TrackVia application.'
          },
          {
            name: 'view_id',
            label: 'View',
            control_type: 'select',
            pick_list: 'views',
            pick_list_params: { app_name: 'app_name' },
            optional: false,
            hint: 'Select an available view.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'view_id',
              label: 'View ID',
              type: :integer,
              disable_formula: true,
              control_type: 'plain_text',
              toggle_hint: 'Enter custom value',
              hint: 'Select the required view. ID can be found at the end of URL.'
            }
          },
          {
            name: 'query',
            label: 'Search text',
            type: 'string',
            sticky: true,
            hint: <<-HINT
                    Enter the value to find in the view.
                    Tables with indexed fields would return only records where indexed fields match the search text.
                  HINT
          }
        ],

        execute: lambda do |_connection, input, _e_i_s, e_o_s|
          response = get("views/#{input['view_id']}#{input['query'].present? ? '/find' : ''}").params(max: 1000, q: input['query']).
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message} : #{body}")
                       end
          response['data'].map do |res|
            call(:format_output, res, e_o_s.dig(0, 'properties'))
          end
          { records: response['data'].map { |res| call(:format_output, res, e_o_s.dig(0, 'properties')) } }
        end,

        output_fields: lambda { |object_definitions|
          { name: 'records', type: :array, of: :object, properties: object_definitions['list_record'] }
        },

        sample_output: lambda { |_connection, input, e_o_s|
          response = call(:get_fields_sample_output, view_id: input['view_id'])
          { records: Array.wrap(call(:format_output, response, e_o_s.dig(0, 'properties'))) }
        }
      },

      get_file_from_record: {
        description: "Get <span class='provider'>file</span> from a record in <span class='provider'>TrackVia</span>",
        help: "Retreive a file from a record's document or image field in TrackVia",

        input_fields: lambda do
          [
            {
              name: 'app_name',
              label: 'Application',
              control_type: 'select',
              pick_list: 'apps',
              optional: false,
              hint: 'Select a TrackVia application.'
            },
            {
              name: 'view_id',
              label: 'View',
              control_type: 'select',
              pick_list: 'views',
              pick_list_params: { app_name: 'app_name' },
              optional: false,
              hint: 'Select an available view.',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'view_id',
                label: 'View ID',
                type: :integer,
                disable_formula: true,
                control_type: 'plain_text',
                toggle_hint: 'Enter custom value',
                hint: 'Select the required view. ID can be found at the end of URL.'
              }
            },
            {
              name: 'id',
              type: 'integer',
              control_type: 'number',
              optional: false,
              hint: <<-HINT
                      Select the required record.
                       If the URL is https://go.trackvia.com/#/apps/3/tables/15/views/341/records/view/51/form/584, then <b>51</b> is the record ID.
                    HINT
            },
            {
              name: 'field_name',
              type: 'string',
              control_type: 'select',
              pick_list: 'file_fields',
              pick_list_params: { view_id: 'view_id' },
              optional: false,
              hint: 'Select the required file field.'
            }
          ]
        end,

        execute: lambda do |_connection, input|
          get("views/#{input['view_id']}/records/#{input['id']}/files/#{input['field_name']}")
            .response_format_raw
            .after_response do |_code, body, headers|
              {
                file_name: headers['content_disposition'].scan(/"(.*?)"/)[0][0],
                content: body
              }
            end
        end,

        output_fields: lambda do
          [
            { name: 'file_name' },
            { name: 'content' }
          ]
        end,

        sample_output: lambda do
          [
            { file_name: 'file.txt' },
            { content: 'Hello World.' }
          ]
        end
      },
      # POST requests
      create_user: {
        description: "Create <span class='provider'>user</span> in <span class='provider'>TrackVia</span>",
        help: 'Create a user in TrackVia',

        input_fields: lambda do
          [
            { name: 'email', optional: false },
            { name: 'firstName', optional: false },
            { name: 'lastName', optional: false },
            { name: 'timeZone', hint: 'Name of the timezone the user will be in. Example: <b>Asia/Kolkata</b>' }
          ]
        end,

        execute: lambda do |_connection, input, _e_i_s, e_o_s|
          res = post('users').params(input).after_error_response(/.*/) do |_code, body, _header, message|
                  error("#{message} : #{body}")
                end&.[]('data')
          call(:format_output, res, e_o_s)
        end,

        output_fields: lambda { |object_definitions|
          object_definitions['create_record_output'].concat([{ name: 'favorite_app_id' }])
        },

        sample_output: lambda { |_connection, input, e_o_s|
          res = call(:get_fields_sample_output, input)
          call(:format_output, res, e_o_s)
        }
      },

      create_record: {
        description: "Create <span class='provider'>record</span> in <span class='provider'>TrackVia</span>",
        help: 'Create a record in TrackVia',

        config_fields: [
          {
            name: 'app_name',
            label: 'Application',
            control_type: 'select',
            pick_list: 'apps',
            optional: false,
            hint: 'Select a TrackVia application.'
          },
          {
            name: 'view_id',
            label: 'View',
            control_type: 'select',
            pick_list: 'views',
            pick_list_params: { app_name: 'app_name' },
            optional: false,
            hint: 'Select an available view.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'view_id',
              label: 'View ID',
              type: :integer,
              disable_formula: true,
              control_type: 'plain_text',
              toggle_hint: 'Enter custom value',
              hint: 'Select the required view. ID can be found at the end of URL.'
            }
          }
        ],
        input_fields: lambda do |object_definitions|
          { name: 'data', label: 'Record', optional: 'false', type: :object, properties: object_definitions['record'] }
        end,

        output_fields: lambda { |object_definitions|
          object_definitions['create_record_output']
        },

        execute: lambda do |_, input, e_i_s, e_o_s|
          payload = call(:format_input, input, e_i_s)
          res = post("views/#{input['view_id']}/records").payload(data: Array.wrap(payload)).
                  after_error_response(/.*/) do |_code, body, _header, message|
                    error("#{message} : #{body}")
                  end.dig('data', 0)
          call(:format_output, res, e_o_s)
        end,

        sample_output: lambda { |_connection, input, e_o_s|
          res = call(:get_fields_sample_output, view_id: input['view_id'])
          call(:format_output, res, e_o_s)
        }
      },

      upload_file_to_record: {
        description: "Upload <span class='provider'>file</span> to a record in <span class='provider'>TrackVia</span>",
        help: "Upload a file to a record's document or image field in TrackVia. A maximum of 20mb can be uploaded.",

        config_fields: [
          {
            name: 'app_name',
            label: 'Application',
            control_type: 'select',
            pick_list: 'apps',
            optional: false,
            hint: 'Select a TrackVia application.'
          },
          {
            name: 'view_id',
            label: 'View',
            control_type: 'select',
            pick_list: 'views',
            pick_list_params: { app_name: 'app_name' },
            optional: false,
            hint: 'Select an available view.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'view_id',
              label: 'View ID',
              type: :integer,
              disable_formula: true,
              control_type: 'plain_text',
              toggle_hint: 'Enter custom value',
              hint: 'Select the required view. ID can be found at the end of URL.'
            }
          },
          {
            name: 'field_name',
            control_type: 'select',
            pick_list: 'file_fields',
            pick_list_params: { view_id: 'view_id' },
            optional: false,
            hint: 'Select the field to which document needs to be uploaded.'
          }
        ],

        input_fields: lambda do |_object_definitions|
          [
            {
              name: 'id',
              label: 'ID',
              type: 'integer',
              control_type: 'number',
              optional: false,
              hint: <<-HINT
                      Internal ID of the record. Select the required record.<br/>
                      If the URL ends like tables/15/views/341/records/view/51/form/584, then <b>51</b> is the record ID.
                    HINT
            },
            {
              name: 'content',
              optional: false
            },
            {
              name: 'content_type',
              type: 'string',
              control_type: 'select',
              pick_list: 'mime_types',
              optional: false,
              hint: 'Select an available content type from the list above.',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'content_type',
                label: 'Content Type',
                type: :string,
                control_type: 'text',
                optional: false,
                toggle_hint: 'Enter custom value',
                hint: <<-HINT
                        Enter the MIME type of the file you want to upload.
                        Refer <a href="http://www.iana.org/assignments/media-types/media-types.xhtml" target="_blank">here</a>
                        for the complete list of MIME types.
                      HINT
              }
            }
          ]
        end,

        execute: lambda do |_connection, input, _e_i_s, e_o_s|
          res = post("views/#{input['view_id']}/records/#{input['id']}/files/#{input['field_name']}").
                  headers(enctype: 'multipart/form-data').
                  payload(file: [input['content'], [input['content_type']]]).
                  request_format_multipart_form.
                  after_error_response(/.*/) do |_code, body, _header, message|
                    error("#{message} : #{body}")
                  end&.[]('data')
          call(:format_output, res, e_o_s)
        end,

        output_fields: lambda { |object_definitions|
          object_definitions['list_record']
        },

        sample_output: lambda { |_connection, input, e_o_s|
          record = call(:get_fields_sample_output, view_id: input['view_id'])
          call(:format_output, record, e_o_s)
        }
      },
      # PUT requests
      update_record: {
        description: "Update <span class='provider'>record</span> in <span class='provider'>TrackVia</span>",
        help: 'Update a record in TrackVia',

        config_fields: [
          {
            name: 'app_name',
            label: 'Application',
            control_type: 'select',
            pick_list: 'apps',
            optional: false,
            hint: 'Select a TrackVia application from the list above'
          },
          {
            name: 'view_id',
            label: 'View',
            control_type: 'select',
            pick_list: 'views',
            pick_list_params: { app_name: 'app_name' },
            optional: false,
            hint: 'Select an available view from the list above.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'view_id',
              label: 'View ID',
              type: :integer,
              disable_formula: true,
              control_type: 'plain_text',
              toggle_hint: 'Enter custom value',
              hint: 'Select the required view. ID can be found at the end of URL.'
            }
          },
          {
            name: 'id',
            type: 'integer',
            label: 'ID',
            control_type: 'number',
            optional: false,
            hint: <<-HINT
                    Internal ID of the record. Select the required record.<br/>
                    If the URL ends like tables/15/views/341/records/view/51/form/584, then <b>51</b> is the record ID.
                  HINT
          }
        ],
        input_fields: lambda do |object_definitions|
          { name: 'data', label: 'Record', optional: 'false', type: :object, properties: object_definitions['record'] }
        end,

        execute: lambda do |_connection, input, e_i_s, e_o_s|
          payload = call(:format_input, input.except('id', 'view_id'), e_i_s)
          response = put("views/#{input['view_id']}/records/#{input['id']}").payload(data: Array.wrap(payload)).
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message} : #{body}")
                       end&.[]('data')&.first
          call(:format_output, response, e_o_s)
        end,

        output_fields: lambda { |object_definitions|
          object_definitions['list_record']
        },

        sample_output: lambda { |_connection, input, e_o_s|
          record = call(:get_fields_sample_output, view_id: input['view_id'])
          call(:format_output, record, e_o_s)
        }
      },
      # DELETE requests

      delete_record: {
        description: "Delete <span class='provider'>record</span> in <span class='provider'>TrackVia</span>",
        help: 'Delete a record in TrackVia',

        input_fields: lambda do
          [
            {
              name: 'app_name',
              label: 'Application',
              control_type: 'select',
              pick_list: 'apps',
              optional: false,
              hint: 'Select a TrackVia application.'
            },
            {
              name: 'view_id',
              label: 'View',
              control_type: 'select',
              pick_list: 'views',
              pick_list_params: { app_name: 'app_name' },
              optional: false,
              hint: 'Select an available view.',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'view_id',
                label: 'View ID',
                type: :integer,
                disable_formula: true,
                control_type: 'plain_text',
                toggle_hint: 'Enter custom value',
                hint: 'Select the required view. ID can be found at the end of URL.'
              }
            },
            {
              name: 'id',
              type: 'integer',
              control_type: 'number',
              optional: false,
              hint: <<-HINT
                      Select the required record.
                       If the URL is https://go.trackvia.com/#/apps/3/tables/15/views/341/records/view/51/form/584, then <b>51</b> is the record ID.
                    HINT
            }
          ]
        end,

        execute: lambda do |_connection, input|
          {
            'status':
            delete("views/#{input['view_id']}/records/#{input['id']}").
              after_error_response(/.*/) do |_code, body, _header, message|
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
        description: "Delete all <span class='provider'>records</span> from a view in <span class='provider'>TrackVia</span>",
        help: 'Delete all records from a view in TrackVia',

        input_fields: lambda do
          [
            {
              name: 'app_name',
              label: 'Application',
              control_type: 'select',
              pick_list: 'apps',
              optional: false,
              hint: 'Select a TrackVia application.'
            },
            {
              name: 'view_id',
              label: 'View',
              control_type: 'select',
              pick_list: 'views',
              pick_list_params: { app_name: 'app_name' },
              optional: false,
              hint: 'Select an available view.',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'view_id',
                label: 'View ID',
                type: :integer,
                disable_formula: true,
                control_type: 'plain_text',
                toggle_hint: 'Enter custom value',
                hint: 'Select the required view. ID can be found at the end of URL.'
              }
            }
          ]
        end,

        execute: lambda do |_connection, input|
          {
            'status':
            delete("views/#{input['view_id']}/records/all").
              after_error_response(/401/) do |_code, body, _header, message|
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
        description: "New <span class='provider'>record</span> added to view in <span class='provider'>TrackVia</span>",
        help: 'Fetch records added to a TrackVia view in real-time. Records added when the trigger is stopped will not be processed.',
        config_fields: [
          {
            name: 'app_name',
            label: 'Application',
            control_type: 'select',
            pick_list: 'apps',
            optional: false,
            hint: 'Select a TrackVia application.'
          },
          {
            name: 'view_id',
            label: 'View',
            control_type: 'select',
            pick_list: 'views',
            pick_list_params: { app_name: 'app_name' },
            optional: false,
            hint: 'Select an available view.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'view_id',
              label: 'View ID',
              type: :integer,
              disable_formula: true,
              control_type: 'plain_text',
              toggle_hint: 'Enter custom value',
              hint: 'Select the required view. ID can be found at the end of URL.'
            }
          }
        ],

        webhook_notification: lambda do |_input, payload, _e_i_s, e_o_s|
          payload.map do |record|
            record.each do |key, val|
              if val.is_a?(Array) && val.first&.is_a?(String)
                record[key] = val.map { |value| { "choice" => value } }
              end
            end
            e_o_s.each_with_object({}) do |k, hash|
              hash[k[:name]] = record[k[:label]]
            end.compact.merge('id' => record['id'])
          end
        end,

        webhook_subscribe: lambda do |webhook_url, _connection, input|
          post("zapier/views/#{input['view_id']}/api/hooks",
               target_url: webhook_url,
               event: 'created').merge(view_id: input['view_id'])
        end,

        webhook_unsubscribe: lambda do |webhook|
          delete("zapier/views/#{webhook['view_id']}/api/hooks/#{webhook['id']}")
        end,

        dedup: lambda do |record|
          record['id']
        end,

        output_fields: ->(object_definitions) { object_definitions['list_record'] },

        sample_output: lambda { |_connection, input, e_o_s|
          record = call(:get_fields_sample_output, view_id: input['view_id'])
          call(:format_output, record, e_o_s)
        }
      },

      updated_record: {
        description: "Updated <span class='provider'>record</span> in <span class='provider'>TrackVia</span> view",
        help: 'Fetch records updated in a TrackVia view in real-time. Records updated when recipe is stopped will not be processed.',

        config_fields: [
          {
            name: 'app_name',
            label: 'Application',
            control_type: 'select',
            pick_list: 'apps',
            optional: false,
            hint: 'Select a TrackVia application from the list above'
          },
          {
            name: 'view_id',
            label: 'View',
            control_type: 'select',
            pick_list: 'views',
            pick_list_params: { app_name: 'app_name' },
            optional: false,
            hint: 'Select an available view from the list above.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'view_id',
              label: 'View ID',
              type: :integer,
              disable_formula: true,
              control_type: 'plain_text',
              toggle_hint: 'Enter custom value',
              hint: 'Select the required view. ID can be found at the end of URL.'
            }
          }
        ],

        webhook_notification: lambda do |_input, payload, _e_i_s, e_o_s|
          payload.map do |record|
            record.each do |key, val|
              if val.is_a?(Array) && val.first&.is_a?(String)
                record[key] = val.map { |value| { 'choice' => value } }
              end
            end
            e_o_s.each_with_object({}) do |k, hash|
              hash[k[:name]] = record[k[:label]]
            end.compact.merge('id' => record['id'], 'dedup_modifiedDate' => record['Updated'])
          end
        end,

        webhook_subscribe: lambda do |webhook_url, _connection, input|
          post("zapier/views/#{input['view_id']}/api/hooks",
               target_url: webhook_url,
               event: 'updated').merge(view_id: input['view_id'])
        end,

        webhook_unsubscribe: lambda do |webhook|
          delete("zapier/views/#{webhook['view_id']}/api/hooks/#{webhook['id']}")
        end,

        dedup: lambda do |record|
          "#{record['id']}@#{record['dedup_modifiedDate']}"
        end,

        output_fields: ->(object_definitions) { object_definitions['list_record'] },

        sample_output: lambda { |_connection, input, e_o_s|
          record = call(:get_fields_sample_output, view_id: input['view_id'])
          call(:format_output, record, e_o_s)
        }
      },

      deleted_record: {
        description: "Deleted <span class='provider'>record</span> from view in <span class='provider'>TrackVia</span>",
        help: 'Fetch records deleted from a TrackVia view in real-time. Records deleted when recipe is stopped will not be processed.',

        config_fields: [
          {
            name: 'app_name',
            label: 'Application',
            control_type: 'select',
            pick_list: 'apps',
            optional: false,
            hint: 'Select a TrackVia application.'
          },
          {
            name: 'view_id',
            label: 'View',
            control_type: 'select',
            pick_list: 'views',
            pick_list_params: { app_name: 'app_name' },
            optional: false,
            hint: 'Select an available view.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'view_id',
              label: 'View ID',
              type: :integer,
              disable_formula: true,
              control_type: 'plain_text',
              toggle_hint: 'Enter custom value',
              hint: 'Select the required view. ID can be found at the end of URL.'
            }
          }
        ],

        webhook_notification: lambda do |_input, payload, _e_i_s, e_o_s|
          payload.map do |record|
            record.each do |key, val|
              if val.is_a?(Array) && val.first&.is_a?(String)
                record[key] = val.map { |value| { 'choice' => value } }
              end
            end
            e_o_s.each_with_object({}) do |k, hash|
              hash[k[:name]] = record[k[:label]]
            end.compact.merge('id' => record['id'])
          end
        end,

        webhook_subscribe: lambda do |webhook_url, _connection, input|
          post("zapier/views/#{input['view_id']}/api/hooks",
               target_url: webhook_url,
               event: 'deleted').merge(view_id: input['view_id'])
        end,

        webhook_unsubscribe: lambda do |webhook|
          delete("zapier/views/#{webhook['view_id']}/api/hooks/#{webhook['id']}")
        end,

        dedup: lambda do |record|
          record['id']
        end,

        output_fields: lambda do |object_definitions|
          object_definitions['list_record']
        end,

        sample_output: lambda { |_connection, input, e_o_s|
          record = call(:get_fields_sample_output, view_id: input['view_id'])
          call(:format_output, record, e_o_s)
        }
      }
    }
}
