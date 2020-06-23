{
  title: 'Google Cloud Storage',

  connection: {
    fields: [
      {
        name: 'client_id',
        hint: 'Find client ID ' \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false
      },
      {
        name: 'client_secret',
        hint: 'Find client secret ' \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false,
        control_type: 'password'
      }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        scopes = [
          'https://www.googleapis.com/auth/cloud-platform',
          'https://www.googleapis.com/auth/cloud-platform.read-only',
          'https://www.googleapis.com/auth/devstorage.full_control',
          'https://www.googleapis.com/auth/devstorage.read_only',
          'https://www.googleapis.com/auth/devstorage.read_write',
          'https://www.googleapis.com/auth/userinfo.email'
        ].join(' ')

        'https://accounts.google.com/o/oauth2/auth?client_id=' \
          "#{connection['client_id']}&response_type=code&scope=#{scopes}" \
          '&access_type=offline&include_granted_scopes=true&prompt=consent'
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post('https://accounts.google.com/o/oauth2/token').
                   payload(client_id: connection['client_id'],
                           client_secret: connection['client_secret'],
                           grant_type: 'authorization_code',
                           code: auth_code,
                           redirect_uri: redirect_uri).
                   request_format_www_form_urlencoded
        [response, nil, nil]
      end,

      refresh: lambda do |connection, refresh_token|
        post('https://accounts.google.com/o/oauth2/token').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401],

      detect_on: [/"errors"\:\s*\[/],

      apply: lambda do |_connection, access_token|
        headers('Authorization' => "Bearer #{access_token}")
      end
    },

    base_uri: lambda do |_connection|
      'https://storage.googleapis.com'
    end
  },

  test: lambda do |_connection|
    get('https://www.googleapis.com/oauth2/v2/userinfo')
  end,

  methods: {
    bucket_schema: lambda do |_input|
      [
        { name: 'id', label: 'Bucket ID', sticky: true, hint: 'The ID of the bucket' },
        { name: 'selfLink', label: 'Self link',
          hint: 'The URI of this bucket.' },
        { name: 'projectNumber', label: 'Project number', type: 'integer',
          control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The project number of the project the bucket belongs to.' },
        { name: 'name', label: 'Bucket name', sticky: true, hint: 'The name of the bucket' },
        { name: 'timeCreated',
          type: 'date_time',
          label: 'Bucket created date',
          hint: 'Bucket was created in RFC-3339 format. e.g. Thu, 20 Apr 2017 11:32:00 -0400' },
        { name: 'updated',
          type: 'date_time',
          label: 'Bucket updated date',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Bucket was updated in RFC-3339 format. e.g. Thu, 20 Apr 2017 11:32:00 -0400' },
        { name: 'defaultEventBasedHold', type: 'boolean',
          control_type: 'checkbox', label: 'Default event based hold',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether or not to automatically apply an eventBasedHold to new objects added to the bucket.',
          toggle_hint: 'Select from list',
          toggle_field:
          { name: 'defaultEventBasedHold',
            type: :boolean,
            label: 'Default event based hold',
            optional: true,
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Whether or not to automatically apply an default event based hold to new objects added to the bucket. ' \
              'Allowed values are true or false' } },
        {
          name: 'retentionPolicy',
          type: 'array', of: 'object',
          label: 'Retention Policy',
          properties: [
            { name: 'retentionPeriod', label: 'Retention period', type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              hint: 'The period of time, in seconds, that objects in the bucket must be retained and cannot be deleted, overwritten, or made noncurrent. ' \
                'The value must be greater than 0 seconds and less than 3,155,760,000 seconds.' },
            { name: 'effectiveTime',
              type: 'date_time',
              label: 'Bucket created date',
              hint: 'The time from which the retentionPolicy was effective, in RFC 3339 format.' },
            { name: 'isLocked', type: 'boolean',
              control_type: 'checkbox', label: 'Is locked',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              hint: 'Whether or not the retentionPolicy is locked.',
              toggle_hint: 'Select from list',
              toggle_field:
              { name: 'isLocked',
                type: :boolean,
                label: 'Is locked',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether or not the retentionPolicy is locked. ' \
                  'Allowed values are true or false' } }
          ]
        },
        { name: 'metageneration', label: 'Metageneration', type: 'integer',
          control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The metadata generation of this bucket.' },
        {
          name: 'acl',
          type: 'array', of: 'object',
          label: 'ACL',
          properties: call('access_control_schema', '')
        },
        {
          name: 'defaultObjectAcl',
          type: 'array', of: 'object',
          label: 'Default object ACL',
          properties: call('access_control_schema', '')
        },
        {
          name: 'iamConfiguration',
          type: 'object',
          label: 'IAM configuration',
          properties: [
            {
              name: 'enabled',
              type: 'object',
              label: 'Enabled',
              properties: [
                { name: 'enabled', type: 'boolean',
                  control_type: 'checkbox', label: 'Enabled',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  hint: 'Whether or not the bucket uses uniform bucket-level access.',
                  toggle_hint: 'Select from list',
                  toggle_field:
                  { name: 'enabled',
                    type: :boolean,
                    label: 'Enabled',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Whether or not the bucket uses uniform bucket-level access. ' \
                      'Allowed values are true or false' } }
              ]
            },
            { name: 'lockedTime',
              type: 'date_time',
              label: 'Locked time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              hint: 'The deadline time for changing iamConfiguration in RFC 3339 format. e.g. Thu, 20 Apr 2017 11:32:00 -0400' }
          ]
        },
        {
          name: 'owner',
          type: 'object',
          label: 'Owner',
          properties: [
            { name: 'entity', label: 'Entity' },
            { name: 'entityId', label: 'Entity ID' }
          ]
        },
        { name: 'location', label: 'Location' },
        { name: 'locationType', label: 'Location type' },
        {
          name: 'website',
          type: 'object',
          label: 'Website',
          properties: [
            { name: 'mainPageSuffix', label: 'Main page suffix' },
            { name: 'notFoundPage', label: 'Not found page' }
          ]
        },
        {
          name: 'logging',
          type: 'object',
          label: 'Logging',
          properties: [
            { name: 'logBucket', label: 'Log bucket' },
            { name: 'logObjectPrefix', label: 'Log object prefix' }
          ]
        },
        {
          name: 'versioning',
          type: 'object',
          label: 'Versioning',
          properties: [
            {
              name: 'enabled',
              type: 'object',
              label: 'Enabled',
              properties: [
                { name: 'enabled', type: 'boolean',
                  control_type: 'checkbox', label: 'Enabled',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  hint: 'When true, versioning is fully enabled for this bucket.',
                  toggle_hint: 'Select from list',
                  toggle_field:
                  { name: 'enabled',
                    type: :boolean,
                    label: 'Enabled',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'When true, versioning is fully enabled for this bucket. ' \
                      'Allowed values are true or false' } }
              ]
            }
          ]
        }

      ]
    end,

    object_schema: lambda do |_input|
      [
        { name: 'id', sticky: true },
        { name: 'selfLink' },
        { name: 'name', sticky: true },
        { name: 'bucket', sticky: true },
        {
          name: 'generation', type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion'
        },
        {
          name: 'metageneration', type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion'
        },
        { name: 'contentType' },
        {
          name: 'timeCreated',
          type: 'date_time',
          label: 'Created time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        {
          name: 'updated',
          type: 'date_time',
          label: 'Updated time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        {
          name: 'timeDeleted',
          type: 'date_time',
          label: 'Deleted time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        {
          name: 'temporaryHold', type: 'boolean',
          control_type: 'checkbox',
          label: 'Temporary hold',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'temporaryHold',
            type: :boolean,
            optional: true,
            control_type: 'text',
            label: 'Temporary hold',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are true or false'
          }
        },
        {
          name: 'eventBasedHold', type: 'boolean',
          control_type: 'checkbox',
          label: 'Event based hold',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'eventBasedHold',
            type: :boolean,
            optional: true,
            control_type: 'text',
            label: 'Event based hold',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are true or false'
          }
        },
        {
          name: 'retentionExpirationTime',
          type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        { name: 'storageClass' },
        {
          name: 'timeStorageClassUpdated',
          type: 'date_time',
          label: 'Storage class updated time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        {
          name: 'size', type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion'
        },
        { name: 'md5Hash', label: 'MD5 hash' },
        { name: 'mediaLink' },
        { name: 'contentEncoding' },
        { name: 'contentDisposition' },
        { name: 'contentLanguage' },
        { name: 'cacheControl' },
        {
          name: 'acl', label: 'ACL',
          type: 'array', of: 'object',
          properties: call('access_control_schema', '')
        },
        {
          name: 'owner',
          type: 'object',
          properties: [
            { name: 'entity' },
            { name: 'entityId' }
          ]
        },
        { name: 'crc32c' },
        { name: 'componentCount',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion' },
        {
          name: 'customerEncryption',
          type: 'object',
          properties: [
            { name: 'encryptionAlgorithm' },
            { name: 'keySha256', label: 'Key SHA 256' }
          ]
        },
        { name: 'kmsKeyName', label: 'KMS key name' }
      ]
    end,

    folder_schema: lambda do |_input|
      call('object_schema', 'input')
    end,

    access_control_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'selfLink' },
        { name: 'bucket' },
        { name: 'entity' },
        { name: 'role' },
        { name: 'email' },
        { name: 'entityId' },
        {
          name: 'projectTeam',
          type: 'object',
          properties: [
            { name: 'projectNumber' },
            { name: 'team' }
          ]
        },
        { name: 'etag' }
      ]
    end,

    bucket_create_schema: lambda do |_input|
      [
        {
          name: 'project_id',
          label: 'Project ID',
          hint: 'ID of the project',
          optional: false
        },
        {
          name: 'name',
          label: 'Name',
          hint: 'The name of the bucket. ' \
            'See the <a href="https://cloud.google.com/storage/docs/naming#requirements"> ' \
            'bucket naming guidelines</a> for more information.',
          optional: false
        }
      ]
    end,

    folder_create_schema: lambda do |_input|
      [
        {
          name: 'bucket',
          label: 'Bucket name',
          hint: 'The name of the bucket. e.g. bucket_name',
          optional: false
        },
        {
          name: 'folder',
          label: 'Folder name',
          hint: 'The name of the folder.',
          optional: false
        }
      ]
    end,

    bucket_search_schema: lambda do |_input|
      [
        {
          name: 'project_id',
          label: 'Project ID',
          hint: 'ID of the project',
          optional: false
        },
        {
          name: 'prefix', sticky: true,
          hint: 'The prefix of the bucket name. e.g. bucket_name'
        }
      ]
    end,

    create_bucket_execute: lambda do |input|
      post("/storage/v1/b?project=#{input.delete('project_id')}", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    create_folder_execute: lambda do |input|
      post("/upload/storage/v1/b/#{input.delete('bucket')}/o?name=#{input.delete('folder')&.encode_url}/").
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    search_bucket_execute: lambda do |input|
      get("/storage/v1/b?project=#{input.delete('project_id')}&prefix=#{input.delete('prefix')&.encode_url}", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    sample_bucket_output: lambda do
      {
        "kind": 'storage#bucket',
        "id": 'bucket_name',
        "selfLink": 'https://www.googleapis.com/storage/v1/b/bucket_name',
        "projectNumber": 925_883_042_379,
        "name": 'bucket_name',
        "timeCreated": '2020-01-22T10:32:39.913000+00:00',
        "updated": '2020-01-22T10:32:39.913000+00:00',
        "metageneration": 1,
        "iamConfiguration": {
          "bucketPolicyOnly": {
            "enabled": false
          },
          "uniformBucketLevelAccess": {
            "enabled": false
          }
        },
        "location": 'US',
        "locationType": 'multi-region',
        "storageClass": 'STANDARD',
        "etag": 'CAE='
      }
    end,

    sample_folder_output: lambda do
      {
        "kind": 'storage#object',
        "id": 'bucket_name/folder_name//1579847492904635',
        "selfLink": 'https://www.googleapis.com/storage/v1/b/bucket_name/o/folder_name%2F',
        "name": 'folder_name/',
        "bucket": 'bucket_name',
        "generation": 1_579_847_492_904_635,
        "metageneration": 1,
        "contentType": 'application/json',
        "timeCreated": '2020-01-24T06:31:32.904000+00:00',
        "updated": '2020-01-24T06:31:32.904000+00:00',
        "storageClass": 'STANDARD',
        "timeStorageClassUpdated": '2020-01-24T06:31:32.904000+00:00',
        "size": 0,
        "md5Hash": '1B2M2Y8AsgTpgAmY7PhCfg==',
        "mediaLink": 'https://storage.googleapis.com/download/storage/v1/b/bucket_name/o/folder_name%2F?generation=1579847492904635&alt=media',
        "crc32c": 'AAAAAA==',
        "etag": 'CLvN9MTOm+cCEAE='
      }
    end,

    sample_object_output: lambda do
      {
        "kind": 'storage#object',
        "id": 'bucket_name/object_name/1579847492904635',
        "selfLink": 'https://www.googleapis.com/storage/v1/b/bucket_name/o/object_name',
        "name": 'object_name',
        "bucket": 'bucket_name',
        "generation": 1_579_847_492_904_635,
        "metageneration": 1,
        "contentType": 'application/json',
        "timeCreated": '2020-01-24T06:31:32.904000+00:00',
        "updated": '2020-01-24T06:31:32.904000+00:00',
        "storageClass": 'STANDARD',
        "timeStorageClassUpdated": '2020-01-24T06:31:32.904000+00:00',
        "size": 0,
        "md5Hash": '1B2M2Y8AsgTpgAmY7PhCfg==',
        "mediaLink": 'https://storage.googleapis.com/download/storage/v1/b/bucket_name/o/object_name?generation=1579847492904635&alt=media',
        "crc32c": 'AAAAAA==',
        "etag": 'CLvN9MTOm+cCEAE='
      }
    end
  },

  object_definitions: {
    create_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_create_schema", 'create')
      end
    },

    create_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_schema", 'output')
      end
    },

    search_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_search_schema", 'create')
      end
    },

    search_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [
          {
            name: 'items', type: 'array', of: 'object',
            label: config_fields['object'].pluralize,
            properties: call("#{config_fields['object']}_schema", 'output')
          }
        ]
      end
    },

    list_object_input: {
      fields: lambda do
        [
          {
            name: 'bucket',
            label: 'Bucket name',
            hint: 'The name of the bucket.',
            optional: false
          }
        ]
      end
    },

    get_object_input: {
      fields: lambda do
        [
          {
            name: 'bucket',
            label: 'Bucket name',
            hint: 'The name of the bucket.',
            optional: false
          },
          {
            name: 'object',
            label: 'Object name',
            hint: 'The name of the object.',
            optional: false
          }
        ]
      end
    },

    copy_object_input: {
      fields: lambda do
        [
          {
            name: 'source_bucket',
            label: 'Source bucket name',
            hint: 'The name of the bucket. ' \
              'See the <a href="https://cloud.google.com/storage/docs/naming#requirements"> ' \
              'bucket naming guidelines</a> for more information.',
            optional: false
          },
          {
            name: 'source_object',
            label: 'Source object name',
            hint: 'The name of the object.',
            optional: false
          },
          {
            name: 'destination_bucket',
            label: 'Destination bucket name',
            hint: 'The name of the bucket.',
            optional: false
          },
          {
            name: 'destination_object',
            label: 'Destination object name',
            hint: 'The name of the object.',
            optional: false
          }
        ]
      end
    },

    download_file_input: {
      fields: lambda do
        [
          {
            name: 'bucket',
            label: 'Bucket name',
            hint: 'The name of the bucket. e.g. bucket_name',
            optional: false
          },
          {
            name: 'file_name',
            hint: 'The name of the file.',
            optional: false
          }
        ]
      end
    },

    upload_file_input: {
      fields: lambda do
        [
          {
            name: 'bucket',
            label: 'Bucket name',
            hint: 'The name of the bucket. e.g. bucket_name',
            optional: false
          },
          {
            name: 'file_name',
            hint: 'The name of the file.',
            optional: false
          },
          { name: 'file_content', optional: false }
        ]
      end
    },

    object_output_schema: {
      fields: lambda do |_input|
        call('object_schema', 'output')
      end
    }
  },

  actions: {
    create_object: {
      title: 'Create object',
      subtitle: 'Create an object in Google Cloud Storage. e.g. HR documents',

      description: lambda do |_connection, create_object_list|
        "Create <span class='provider'>a #{create_object_list[:object]&.downcase || 'an object'}" \
        "</span> in <span class='provider'>Google Cloud Storage</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'create_object_list',
          hint: 'Select any object from list.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['create_object_input']
      end,

      execute: lambda do |_connection, input|
        object_name = input.delete('object')
        call("create_#{object_name}_execute", input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definition|
        object_definition['create_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call("sample_#{input['object']}_output")
      end
    },

    search_object: {
      title: 'Search objects',
      subtitle: 'Search objects in Google Cloud Storage e.g. buckets, folders',

      description: lambda do |_connection, create_object_list|
        "Search <span class='provider'>a #{create_object_list[:object]&.downcase || 'an object'}" \
        "</span> in <span class='provider'>Google Cloud Storage</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'search_object_list',
          hint: 'Select any object from list.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['search_object_input']
      end,

      execute: lambda do |_connection, input|
        object_name = input.delete('object')
        call("search_#{object_name}_execute", input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definition|
        object_definition['search_object_output']
      end,

      sample_output: lambda do |_connection, input|
        { items: [call("sample_#{input['object']}_output")] }
      end
    },

    list_object_in_bucket: {
      title: 'List objects in bucket',
      subtitle: 'List the objects of a bucket in Google Cloud Storage',

      description: "List <span class='provider'>objects of a bucket</span> in " \
        "<span class='provider'>Google Cloud Storage</span>",

      input_fields: lambda do |object_definition|
        object_definition['list_object_input']
      end,

      execute: lambda do |_connection, input|
        get("/storage/v1/b/#{input.delete('bucket')}/o", input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definition|
        [
          {
            name: 'items', type: 'array', of: 'object',
            label: 'Objects',
            properties: object_definition['object_output_schema']
          }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        { items: [call('sample_object_output')] }
      end
    },

    get_object: {
      title: 'Get object',
      subtitle: 'Get object in Google Cloud Storage. e.g. file, folder',

      description: "Get <span class='provider'>object</span> in " \
        "<span class='provider'>Google Cloud Storage</span>",

      input_fields: lambda do |object_definition|
        object_definition['get_object_input']
      end,

      execute: lambda do |_connection, input|
        get("/storage/v1/b/#{input.delete('bucket')}/o/#{input.delete('object').encode_url}?alt=json").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definition|
        object_definition['object_output_schema']
      end,

      sample_output: lambda do |_connection, _input|
        call('sample_object_output')
      end
    },

    copy_object: {
      title: 'Copy object',
      subtitle: 'Copy object in Google Cloud Storage',

      description: lambda do |_connection, _search_object_list|
        "Copy <span class='provider'>object</span> in " \
          "<span class='provider'>Google Cloud Storage</span>"
      end,

      input_fields: lambda do |object_definition|
        object_definition['copy_object_input']
      end,

      execute: lambda do |_connection, input|
        post("/storage/v1/b/#{input.delete('source_bucket')}/o/#{input.delete('source_object').encode_url}" \
            "/copyTo/b/#{input.delete('destination_bucket')}/o/#{input.delete('destination_object').encode_url}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definition|
        object_definition['object_output_schema']
      end,

      sample_output: lambda do |_connection, _input|
        call('sample_object_output')
      end
    },

    download_file: {
      title: 'Download file',
      subtitle: 'Download file in Google Cloud Storage',

      description: "Download <span class='provider'>file</span> in " \
        "<span class='provider'>Google Cloud Storage</span>",

      input_fields: lambda do |object_definition|
        object_definition['download_file_input']
      end,

      execute: lambda do |_connection, input|
        file_content = get("/storage/v1/b/#{input.delete('bucket')}/o/#{input.delete('file_name').encode_url}?alt=media").
                       response_format_raw.after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end

        { file_content: file_content }
      end,

      output_fields: lambda do |_object_definition|
        [
          { name: 'file_content' }
        ]
      end
    },

    upload_file: {
      title: 'Upload file',
      subtitle: 'Upload file in Google Cloud Storage',

      description: "Upload <span class='provider'>file</span> in " \
        "<span class='provider'>Google Cloud Storage</span>",

      input_fields: lambda do |object_definition|
        object_definition['upload_file_input']
      end,

      execute: lambda do |_connection, input|
        post("/upload/storage/v1/b/#{input['bucket']}/o?uploadType=multipart&name=#{input['file_name'].encode_url}").
          headers('Content-Type': '*/*').
          request_body(input['file_content']).after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definition|
        object_definition['object_output_schema']
      end,

      sample_output: lambda do |_connection, _input|
        call('sample_object_output')
      end
    }
  },

  triggers: {},

  pick_lists: {
    create_object_list: lambda do
      [
        %w[Bucket bucket],
        %w[Folder folder]
      ]
    end,

    search_object_list: lambda do
      [
        %w[Bucket bucket]
      ]
    end
  }
}
