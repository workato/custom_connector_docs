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
        optional: false
      },
      {
        name: 'user_key',
        label: 'API Key',
        hint: "Please find the API Key <a href='https://go.trackvia.com' \
          '/#/account' target='_blank'>here</a>",
        optional: false
      }
    ],
    authorization: {
      apply: lambda { |connection|
        params(user_key: connection['user_key'])
        params(access_token: connection['access_token'])
      }
    },
    base_uri: ->(_connection) { 'https://go.trackvia.com' }
  },
  test: lambda { |_connection|
          get('/openapi/views')
        },
  methods: {
    get_type: lambda { |input|
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
    },
    get_control_type: lambda { |input|
                        type = input[:type]
                        name = input[:name]

                        if %w[id ID].include?(name)
                          'integer'
                        else
                          case type
                          when 'identifier', 'shortAnswer'
                            'text'
                          when 'paragraph'
                            'text-area'
                          when 'number', 'currency', 'percentage',
                            'autoIncrement'
                            'number'
                          when 'relationship'
                            'integer'
                          when 'checkbox'
                            'multiselect'
                          when 'dropDown'
                            'select'
                          when 'date'
                            'date'
                          when 'datetime'
                            'date_time'
                          when 'email'
                            'email'
                          when 'point'
                            nil
                          else
                            'text'
                          end
                        end
                      },
    get_picklist_options: lambda { |input|
                            choices = input[:choices]
                            unless choices == nil
                              choices.map do |choice|
                                [choice, choice]
                              end
                            end
                          },
    get_properties: lambda { |input|
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
                    },
    get_delimeter: lambda { |input|
                     type = input[:type]

                     ',' if type == 'checkbox'
                   },
    get_output_fields: lambda { |input|
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
                       },
    get_fields: lambda { |input|
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
                }
  },
  object_definitions: {
    app: {
      fields: lambda {
                [
                  { name: 'name' },
                  { name: 'id', type: :integer }
                ]
              }
    },
    view: {
      fields: lambda {
        [
          { name: 'id', type: :integer },
          { name: 'name' },
          { name: 'applicationName' },
          { name: 'default', type: :boolean }
        ]
      }
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
      fields: lambda { |_connection, config_fields|
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
      }
    },
    user: {
      fields: lambda {
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
      }
    },
    column: {
      fields: lambda {
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
      }
    }
  },
  pick_lists: {
    apps: lambda { |_connection|
      get('/openapi/apps')
        .pluck('name', 'name')
    },
    views: lambda { |_connection, app_name:|
             get('/openapi/views')
               .select do |view|
               view['applicationName'] == app_name
             end
               .pluck('name', 'id')
           }
  },
  actions: {
    # GET requests
    get_apps: {
      description: "Gets&nbsp;<span class='provider'>"\
      'a list of apps</span>&nbsp;in' \
                "&nbsp;<span class='provider'>TrackVia</span>.",
      help: 'Gets a list of apps in your TrackVia account',

      config_fields: [
        {
          name: 'name',
          control_type: 'plain-text',
          optional: true,
          hint: 'Search for a specific application by name'
        }
      ],

      execute: lambda { |_connection, input|
                 apps = get('/openapi/apps').params(name: input['name'])
                 { apps: apps }
               },
      output_fields: lambda { |object_definitions|
                       [
                         {
                           name: 'apps',
                           type: :array,
                           of: :object,
                           properties: object_definitions['app']
                         }
                       ]
                     }
    },
    get_views: {
      description: "Gets&nbsp;<span class='provider'>"\
      'a list of views</span>&nbsp;in' \
              "&nbsp;<span class='provider'>TrackVia</span>.",
      help: 'Gets a list of views in your TrackVia account',
      config_fields: [
        {
          name: 'name',
          control_type: 'plain-text',
          optional: true,
          hint: 'Search for a specific view by name'
        }
      ],
      execute: lambda { |_connection, input|
                 views = get('/openapi/views').params(name: input['name'])
                 { views: views }
               },
      output_fields: lambda { |object_definitions|
                       [
                         {
                           name: 'views',
                           type: :array,
                           of: :object,
                           properties: object_definitions['view']
                         }
                       ]
                     }
    },
    get_records_in_view: {
      description: "Gets&nbsp;<span class='provider'>"\
      'a list of records</span>&nbsp;for a' \
              "&nbsp;<span class='provider'>TrackVia view</span>.",
      help: 'Gets a list of records for a specified TrackVia view',
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        },
        {
          name: 'start',
          type: 'integer',
          control_type: 'number',
          optional: true
        },
        {
          name: 'max',
          type: 'integer',
          control_type: 'number',
          optional: true
        }
      ],
      execute: lambda { |_connection, input|
                 response = get("/openapi/views/#{input['view_id']}")
                            .params(
                              start: input['start'],
                              max: input['max']
                            )
                 { data: response['data'],
                   totalCount: response['totalCount'],
                   structure: response['structure'] }
               },
      output_fields: lambda { |object_definitions|
                       [
                         { name: 'data',
                           type: :array, of: :object,
                           properties: object_definitions['record'] },
                         { name: 'structure',
                           type: :array, of: :object },
                         { name: 'totalCount',
                           type: :integer }
                       ]
                     }
    },
    get_all_view_records: {
      description: "Gets&nbsp;<span class='provider'>"\
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
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        }
      ],
      execute: lambda { |_connection, input|
                 all_records = []
                 start = 0
                 max = 100
                 first_page = get("/openapi/views/#{input['view_id']}")
                              .params(start: start, max: max)
                 total_records = first_page['totalCount']
                 all_records = all_records.concat(first_page['data'])
                 start = start + max
                 while all_records.length < total_records
                   page = get("/openapi/views/#{input['view_id']}")
                          .params(start: start, max: max)
                   all_records = all_records.concat(page['data'])
                   start = start + max
                 end
                 { data: all_records, totalCount: total_records }
               },
      output_fields: lambda { |object_definitions|
                       [
                         { name: 'data',
                           type: :array, of: :object,
                           properties: object_definitions['record'] },
                         { name: 'structure', type: :array, of: :object },
                         { name: 'totalCount', type: :integer }
                       ]
                     }
    },
    get_users: {
      description: "Gets&nbsp;<span class='provider'>"\
      'a list of users</span>&nbsp;in' \
              "&nbsp;<span class='provider'>TrackVia</span>.",
      help: 'Gets a list of users in your TrackVia account',
      config_fields: [
        {
          name: 'start',
          type: 'integer',
          control_type: 'number',
          optional: true
        },
        {
          name: 'max',
          type: 'integer',
          control_type: 'number',
          optional: true
        }
      ],
      execute: lambda { |_connection, input|
                 get('/openapi/users')
                   .params(
                     start: input['start'],
                     max: input['max']
                   )
               },
      output_fields: lambda { |object_definitions|
                       [
                         { name: 'structure', type: :array,
                           of: :object,
                           properties: object_definitions['column'] },
                         { name: 'data', type: :array,
                           of: :object,
                           properties: object_definitions['user'] },
                         { name: 'totalCount', type: :integer }
                       ]
                     }
    },
    get_all_users: {
      description: "Gets&nbsp;<span class='provider'>"\
      'a list of all users</span>&nbsp;in' \
              "&nbsp;<span class='provider'>TrackVia</span>.",
      help: 'Gets a list of all users in your TrackVia account',
      execute: lambda { |_connection, _input|
                 all_records = []
                 start = 0
                 max = 100
                 first_page = get('/openapi/users')
                              .params(
                                start: start,
                                max: max
                              )
                 total_records = first_page['totalCount']
                 all_records = all_records.concat(first_page['data'])
                 start = start + max
                 while all_records.length < total_records
                   page = get('/openapi/users')
                          .params(
                            start: start,
                            max: max
                          )
                   all_records = all_records.concat(page['data'])
                   start = start + max
                 end
                 { data: all_records, totalCount: total_records }
               },
      output_fields: lambda {
                       [
                         { name: 'data', type: :array, of: :object },
                         { name: 'totalCount', type: :integer }
                       ]
                     }
    },
    # POST requests
    create_user: {
      description: "Create a&nbsp;<span class='provider'>"\
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
      execute: lambda { |_connection, input|
                 post('/openapi/users')
                   .params(
                     email: input['email'],
                     firstName: input['first_name'],
                     lastName: input['last_name']
                   )
               },
      output_fields: lambda { |object_definitions|
                       [
                         { name: 'structure',
                           type: :array,
                           of: :object,
                           properties: object_definitions['column'] },
                         { name: 'data',
                           type: :array, of: :object,
                           properties: object_definitions['user'] }
                       ]
                     }
    },
    create_record: {
      description: "Create a&nbsp;<span class='provider'>"\
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
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        }
      ],
      input_fields: lambda { |object_definitions|
                      { name: 'data',
                        type: :array, of: :object,
                        properties: object_definitions['record'] }
                    },
      execute: lambda { |_connection, input|
                 post("/openapi/views/#{input['view_id']}/records")
                   .payload(data: input['data'])
               },
      output_fields: lambda { |object_definitions|
                       [
                         { name: 'structure',
                           type: :array, of: :object,
                           properties: object_definitions['column'] },
                         { name: 'data',
                           type: :array, of: :object,
                           properties: object_definitions['response_record'] },
                         { name: 'totalCount', type: :integer }
                       ]
                     }
    },
    # PUT requests
    update_record: {
      description: "Update an&nbsp;<span class='provider'>"\
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
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        },
        {
          name: 'id',
          type: 'integer',
          control_type: 'number',
          optional: false
        }
      ],
      input_fields: lambda { |object_definitions|
                      { name: 'data',
                        type: :array, of: :object,
                        properties: object_definitions['record'] }
                    },
      execute: lambda { |_connection, input|
                 put("/openapi/views/#{input['view_id']}"\
                    "/records/#{input['id']}")
                   .payload(data: input['data'])
               },
      output_fields: lambda { |object_definitions|
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
                     }
    },
    # DELETE requests
    delete_record: {
      description: "Delete an&nbsp;<span class='provider'>"\
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
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        },
        {
          name: 'id',
          type: 'integer',
          control_type: 'number',
          optional: false
        }
      ],
      execute: lambda { |_connection, input|
                 delete("/openapi/views/#{input['view_id']}"\
                    "/records/#{input['id']}")
               }
    },
    delete_all_records_in_view: {
      description: "Delete&nbsp;<span class='provider'>"\
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
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        }
      ],
      execute: lambda { |_connection, input|
                 delete("/openapi/views/#{input['view_id']}/records/all")
               }
    }
  },
  triggers: {
    new_record: {
      type: :paging_desc,
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        }
      ],
      webhook_notification: lambda { |_input, payload|
                              # payload[0]
                              # HACK: This is a quick fix to replace an
                              # issue with webhook responses returning 'id'
                              # instead of 'ID'
                              hash = payload[0]
                              hash['ID'] = hash.delete 'id'
                              hash
                            },
      webhook_subscribe: lambda { |webhook_url, _connection, input, _recipe_id|
                           post("/openapi/zapier/views/#{input['view_id']}"\
                            '/api/hooks',
                                target_url: webhook_url,
                                event: 'created')
                         },
      webhook_unsubscribe: lambda { |webhook, input|
                             delete("/openapi/zapier/views/#{input['view_id']}"\
                                "/api/hooks/#{webhook['id']}")
                           },
      output_fields: lambda { |object_definitions|
                       object_definitions['hook_body']
                     }
    },
    updated_record: {
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        }
      ],
      webhook_notification: lambda { |_input, payload|
                              # payload[0]
                              # HACK: This is a quick fix to replace an issue
                              # with webhook responses returning
                              # 'id' instead of 'ID'
                              hash = payload[0]
                              hash['ID'] = hash.delete 'id'
                              hash
                            },
      webhook_subscribe: lambda { |webhook_url, _connection, input, _recipe_id|
                           post("/openapi/zapier/views/#{input['view_id']}"\
                            '/api/hooks',
                                target_url: webhook_url,
                                event: 'updated')
                         },
      webhook_unsubscribe: lambda { |webhook, input|
                             delete("/openapi/zapier/views/#{input['view_id']}"\
                                "/api/hooks/#{webhook['id']}")
                           },
      output_fields: lambda { |object_definitions|
                       object_definitions['hook_body']
                     }
    },
    deleted_record: {
      config_fields: [
        {
          name: 'app_name',
          label: 'App',
          type: 'string',
          control_type: 'select',
          pick_list: 'apps',
          optional: false,
          change_on_blur: true
        },
        {
          name: 'view_id',
          label: 'View',
          type: 'integer',
          control_type: 'select',
          pick_list: 'views',
          pick_list_params: { app_name: 'app_name' },
          optional: false
        }
      ],
      webhook_notification: lambda { |_input, payload|
                              payload[0]
                            },
      webhook_subscribe: lambda { |webhook_url, _connection, input, _recipe_id|
                           post("/openapi/zapier/views/#{input['view_id']}"\
                            '/api/hooks',
                                target_url: webhook_url,
                                event: 'deleted')
                         },
      webhook_unsubscribe: lambda { |webhook, input|
                             delete("/openapi/zapier/views/#{input['view_id']}"\
                                "/api/hooks/#{webhook['id']}")
                           },
      output_fields: lambda { |object_definitions|
                       object_definitions['hook_body']
                     }
    }
  }
}
