{
  title: 'Domo',

  connection: {
    fields: [
      {
        name: 'client_id',
        optional: false,
        hint: 'To create client ID click <a ' \
        "href='https://developer.domo.com/new-client' target='_blank'>" \
        'here</a>'
      },
      {
        name: 'client_secret',
        control_type: 'password',
        optional: false,
        hint: 'To create client secret click <a ' \
        "href='https://developer.domo.com/new-client' target='_blank'>" \
        'here</a>'
      }
    ],
    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|
        {
          access_token: get('https://api.domo.com/oauth/token?' \
            'grant_type=client_credentials&scope=data')
            .user(connection['client_id'])
            .password(connection['client_secret'])['access_token']
        }
      end,

      refresh_on: [401],

      apply: lambda do |connection|
        headers(Authorization: "bearer #{connection['access_token']}")
      end
    },

    base_uri: lambda do |_connection|
      'https://api.domo.com'
    end
  },

  test: lambda do |_connection|
    get('/v1/datasets?limit=1')
  end,

  object_definitions: {
    dataset: {
      fields: lambda do |_connection, config_fields|
        column_headers =
          if config_fields.blank?
            []
          else
            get("/v1/datasets/#{config_fields['dataset_id']}")
              .dig('schema', 'columns')
          end&.map do |col|
            {
              name: col['name'],
              sticky: true,
              type: case col['type']
                    when 'DATE'
                      'date'
                    when 'DATETIME'
                      'date_time'
                    when 'LONG'
                      'integer'
                    when 'DECIMAL'
                      'number'
                    else
                      'string'
                    end
            }
          end
        {
          name: 'data',
          type: 'array',
          of: 'object',
          properties: column_headers,
          optional: false,
          hint: 'Map the Data source list and Data fields.'
        }
      end
    },

    dataset_definition: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'name', optional: false },
          { name: 'description', optional: false },
          {
            name: 'schema',
            optional: false,
            type: 'object', properties: [
              { name: 'columns',
                optional: false,
                type: 'array', of: 'object',
                properties: [
                  { name: 'name', optional: false },
                  { name: 'type',
                    optional: false,
                    control_type: 'select',
                    pick_list: [
                      %w[String STRING],
                      %w[Decimal DECIMAL],
                      %w[Long LONG],
                      %w[Double DOUBLE],
                      %w[Date DATE],
                      %w[Date\ time DATETIME]
                    ],
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'type', type: 'string',
                      control_type: 'text',
                      label: 'Type',
                      toggle_hint: 'Enter custom value',
                      hint: 'Allowed values are: STRING, DECIMAL, LONG,' \
                      'DOUBLE, DATE, DATETIME'
                    } }
                ] }
            ]
          },
          { name: 'rows', type: 'integer' },
          { name: 'columns', type: 'integer' },
          { name: 'owner', type: 'object', properties: [
            { name: 'id' },
            { name: 'name' }
          ] },
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' }
        ]
      end
    }
  },

  actions: {
    import_data: {
      description: 'Import <span class="provider">data</span> into ' \
      '<span class="provider">dataset</span>  in  ' \
      '<span class="provider">Domo</span>',
      help: 'Import data action replaces the data in the dataset',

      config_fields: [
        {
          name: 'dataset_id',
          control_type: 'select',
          pick_list: 'datasets',
          label: 'Dataset name',
          optional: false,
          help: 'Select the Dataset to import data.',
          toggle_hint: 'Select from list',
          toggle_field:
            { name: 'dataset_id',
              label: 'Dataset ID',
              type: :string,
              control_type: 'text',
              optional: false,
              toggle_hint: 'Use custom value' }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['dataset']
      end,

      execute: lambda do |_connection, input|
        payload = input['data'].map do |row|
          row.map do |_key, val|
            val
          end.join(',')
        end.join("\n")
        {
          status: put("/v1/datasets/#{input['dataset_id']}/data")
            .headers("Content-Type": 'text/csv')
            .request_body(payload)
            .request_format_www_form_urlencoded
            .after_error_response(/40*/) do |code, _body, _header, message|
              error("#{code}: #{message}")
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

    export_data: {
      description: 'Export <span class="provider">data</span> from ' \
      '<span class="provider">dataset</span>  in  ' \
      '<span class="provider">Domo</span>',
      help: 'Known Limitation: Data types will be exported as they are' \
      ' currently stored in the dataset. In addition, the only supported' \
      ' export type is CSV.',

      config_fields: [
        {
          name: 'dataset_id',
          control_type: 'select',
          label: 'Dataset name',
          pick_list: 'datasets',
          optional: false,
          toggle_hint: 'Select from list',
          toggle_field:
            { name: 'dataset_id',
              label: 'Dataset ID',
              type: :string,
              control_type: 'text',
              optional: false,
              toggle_hint: 'Use custom value' }
        }
      ],

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'includeHeader',
            type: 'boolean',
            label: 'Include header',
            control_type: 'checkbox',
            sticky: true,
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'includeHeader',
                label: 'Include header',
                type: :string,
                control_type: 'text',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false' }
          },
          {
            name: 'fileName',
            hint: 'The filename of the exported csv',
            sticky: true
          }
        ]
      end,

      execute: lambda do |_connection, input|
        {
          data: get("/v1/datasets/#{input.delete('dataset_id')}/data", input)
            .headers("Content-Type": 'text/csv',
                     'Accept': 'text/csv')
            .request_format_www_form_urlencoded
            .response_format_raw
        }
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'data' }]
      end,

      sample_output: lambda do |_connection, _input|
        { data: 'name,id sam,123 xavier,124' }
      end
    },

    create_dataset: {
      description: 'Create <span class="provider">dataset</span> ' \
      'in <span class="provider">Domo</span>',
      help: "Click <a href='https://developer.domo.com/docs/" \
      "dataset-api-reference/dataset#Create%20a%20DataSet' target='_blank'>" \
      'here</a> for supported data types',

      input_fields: lambda do |object_definitions|
        object_definitions['dataset_definition']
          .ignored('id', 'rows', 'columns', 'owner', 'createdAt', 'updatedAt')
      end,

      execute: lambda do |_connection, input|
        post('/v1/datasets/', input)
          .after_error_response(/40*/) do |code, _body, _header, message|
            error("#{code}: #{message}")
          end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['dataset_definition']
      end,

      sample_output: lambda do |_connection, _input|
        dataset_id = get('/v1/datasets?limit=1')&.dig(0, 'id')
        dataset_id.present? ? get("/v1/datasets/#{dataset_id}") : {}
      end
    }
  },

  pick_lists: {
    datasets: lambda do |_connection|
      get('/v1/datasets')&.pluck('name', 'id')
    end
  }
}
