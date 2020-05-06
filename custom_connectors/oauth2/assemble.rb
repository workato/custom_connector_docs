{
  title: 'Assemble',

  connection: {
    fields: [
      {
        name: 'client_id',
        optional: false
      },
      {
        name: 'client_secret',
        optional: false,
        type: 'password'
      },
      {
        name: 'subdomain',
        optional: false,
        control_type: 'subdomain',
        url: '.tryassemble.com'
      }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        'https://auth.tryassemble.com/connect/authorize?' +
        'acr_values=idp:forge&scope=tenant%20openid%20core_api.all%20offline_access&response_type=code' +
        "&client_id=#{connection['client_id']}&redirect_uri=https%3A%2F%2Fwww.workato.com%2Foauth%2Fcallback"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        post('https://auth.tryassemble.com/connect/token').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  code: auth_code,
                  grant_type: 'authorization_code',
                  redirect_uri: redirect_uri).
          request_format_www_form_urlencoded
      end,

      refresh_on: [400, 401, 403, 500],

      refresh: lambda do |connection, refresh_token|
        post('https://auth.tryassemble.com/connect/token').
          payload(
            client_id: connection['client_id'],
            client_secret: connection['client_secret'],
            grant_type: 'refresh_token',
            refresh_token: refresh_token
          ).
          request_format_www_form_urlencoded

      end,

      apply: lambda do |_connection, access_token|
        headers('Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json')
      end

    },

    base_uri: lambda do |connection|
        "https://#{connection['subdomain']}.tryassemble.com"
    end
    
  },

  test: lambda do |_connection|
    get('/api/v1/powerbi/projects')
  end,

  object_definitions: {
    project: {
      fields: lambda do |_connection|
        [
          { name: 'id', type: 'number'},
          { name: 'name' },
          { name: 'description' },
          { name: 'jobCode' },
          { name: 'cardColorCode' },
          { name: 'isArchived', type: 'boolean' },
          { name: 'unitType' },
          { name: 'userPublishAlignment' },
          { name: 'isValidation', type: 'boolean' },
          { name: 'isApproved', type: 'boolean' },
          { name: 'modelCount', type: 'number' },
          { name: 'viewCount', type: 'number' },
          { name: 'lastActivityTime', type: 'date_time' },
          { name: 'imageAttachmentId' },
          { name: 'imgUrl' },
          { name: 'organizationId', type: 'number' },
          { name: 'approvedByName' },
          { name: 'approvedByDate', type: 'date_time' },
          { name: 'referencedBIM360ProjectData' }
        ]
      end
    },
    model: {
      fields: lambda do |_connection|
        [
          { name: 'id', type: 'number'},
          { name: 'name' },
          { name: 'createdDate', type: 'date_time' },
          { name: 'createdBy' },
          { name: 'description' },
          { name: 'datasource' },
          { name: 'datasourceTitle' },
          { name: 'projectId', type: 'number' },
          { name: 'projectName' },
          { name: 'hasVersions', type: 'boolean' },
          { name: 'activeVersion', type: 'object', properties: [
            { name: 'id', type: 'number' },
            { name: 'name' },
            { name: 'guid' },
            { name: 'createdDate', type: 'date_time' },
            { name: 'createdBy' },
            { name: 'versionNumber', type: 'number' },
            { name: 'comments' },
            { name: 'projectId', type: 'number' },
            { name: 'projectName' },
            { name: 'modelId', type: 'number'  },
            { name: 'modelName' },
            { name: 'datasource' },
            { name: 'source' },
            { name: 'instanceCount', type: 'number' },
            { name: 'hasExpandedEdit', type: 'boolean' },
            { name: 'isMerged', type: 'boolean' },
            { name: 'geometryResourceId' },
            { name: 'sheetMappingResourceId' },
            { name: 'hasGeometry', type: 'boolean' },
            { name: 'canUseWebWorkers', type: 'boolean' },
            { name: 'geometryFilteredCategories' },
            { name: 'estimatedOn' },
            { name: 'estimatedBy' },
            { name: 'formattedEstimatedOn' },
            { name: 'canEstimate' },
            { name: 'audits' },
            { name: 'origins', type: 'object', properties: [
              { name: 'x', type: 'number' },
              { name: 'y', type: 'number' },
              { name: 'z', type: 'number' }
            ]},
            { name: 'rotation', type: 'object', properties: [
              { name: 'x', type: 'number' },
              { name: 'y', type: 'number' },
              { name: 'z', type: 'number' }
            ]},
            { name: 'userAlignment' },
            { name: 'data' }
          ]},
          { name: 'versions', type: 'array', of: 'object', properties: [
            { name: 'id', type: 'number' },
            { name: 'name' },
            { name: 'guid' },
            { name: 'createdDate', type: 'date_time' },
            { name: 'createdBy' },
            { name: 'versionNumber', type: 'number' },
            { name: 'comments' },
            { name: 'projectId', type: 'number' },
            { name: 'projectName' },
            { name: 'modelId', type: 'number'  },
            { name: 'modelName' },
            { name: 'datasource' },
            { name: 'source' },
            { name: 'instanceCount', type: 'number' },
            { name: 'hasExpandedEdit', type: 'boolean' },
            { name: 'isMerged', type: 'boolean' },
            { name: 'geometryResourceId' },
            { name: 'sheetMappingResourceId' },
            { name: 'hasGeometry', type: 'boolean' },
            { name: 'canUseWebWorkers', type: 'boolean' },
            { name: 'geometryFilteredCategories' },
            { name: 'estimatedOn' },
            { name: 'estimatedBy' },
            { name: 'formattedEstimatedOn' },
            { name: 'canEstimate' },
            { name: 'audits' },
            { name: 'origins', type: 'object', properties: [
              { name: 'x', type: 'number' },
              { name: 'y', type: 'number' },
              { name: 'z', type: 'number' }
            ]},
            { name: 'rotation', type: 'object', properties: [
              { name: 'x', type: 'number' },
              { name: 'y', type: 'number' },
              { name: 'z', type: 'number' }
            ]},
            { name: 'userAlignment' },
            { name: 'data' }
          ]}
        ]
      end
    },
    model_version: {
      fields: lambda do |_connection|
        [
          { name: 'id', type: 'number' },
          { name: 'name' },
          { name: 'guid' },
          { name: 'createdDate', type: 'date_time' },
          { name: 'createdBy' },
          { name: 'versionNumber', type: 'number' },
          { name: 'comments' },
          { name: 'projectId', type: 'number' },
          { name: 'projectName' },
          { name: 'modelId', type: 'number'  },
          { name: 'modelName' },
          { name: 'datasource' },
          { name: 'source' },
          { name: 'instanceCount', type: 'number' },
          { name: 'hasExpandedEdit', type: 'boolean' },
          { name: 'isMerged', type: 'boolean' },
          { name: 'geometryResourceId' },
          { name: 'sheetMappingResourceId' },
          { name: 'hasGeometry', type: 'boolean' },
          { name: 'canUseWebWorkers', type: 'boolean' },
          { name: 'geometryFilteredCategories' },
          { name: 'estimatedOn' },
          { name: 'estimatedBy' },
          { name: 'formattedEstimatedOn' },
          { name: 'canEstimate' },
          { name: 'audits' },
          { name: 'origins', type: 'object', properties: [
            { name: 'x', type: 'number' },
            { name: 'y', type: 'number' },
            { name: 'z', type: 'number' }
          ]},
          { name: 'rotation', type: 'object', properties: [
            { name: 'x', type: 'number' },
            { name: 'y', type: 'number' },
            { name: 'z', type: 'number' }
          ]},
          { name: 'userAlignment' },
          { name: 'data' }
        ]
      end
    },
    properties: {
      fields: lambda do |_connection|
        [
          { name: 'modelVersionId', type: 'number' },
          { name: 'properties', type: 'array', of: 'object', properties: [
            { name: 'id' },
            { name: 'name' },
            { name: 'unit' },
            { name: 'dataType' },
            { name: 'type' },
            { name: 'source' }
          ]}
        ]
      end
    },
    grid_data: {
      fields: lambda do |_connection|
        [
          { name: 'Id' },
          { name: 'RowType' },
          { name: 'AssembleName' },
          { name: 'AssembleModelName' },
          { name: 'ModelVersionDataSource' },
          { name: 'TakeoffUnitAbbreviation' },
          { name: 'TakeoffQuantity' },
          { name: 'QuantityProperty' },
          { name: 'IsActiveTakeoffQuantity' },
          { name: 'TypeProperties' },
          { name: 'ChildSourceIds' },
          { name: 'ModelVersionId' },
          { name: 'ColorOverrides' },
          { name: 'InstanceCount' },
          { name: 'CategoryName:::string', label: 'CategoryName' },
          { name: 'FamilyName:::string', label: 'FamilyName' },
          { name: 'TypeName:::string', label: 'TypeName' },
          { name: 'UnitCost:::numeric', label: 'UnitCost' },
          { name: 'AssembleTotalCost:::numeric', label: 'AssembleTotalCost' },
          { name: 'BidPackage_AssembleProperty:::string', label:  'BidPackage_AssembleProperty'},
          { name: 'AssemblyCode:::string', label: 'AssemblyCode' },
          { name: 'SourceId:::numeric', label: 'SourceId' }
        ]
      end
    },
    custom_action_input: {
      fields: lambda do |_connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: 'Base URI is https://demo.tryassemble.com - ' \
            'path will be appended to this URI. ' \
             'Use absolute URI to override this base URI.'
          },
          (
            if %w[get delete].include?(config_fields['verb'])
              {
                name: 'input',
                type: 'object',
                control_type: 'form-schema-builder',
                sticky: input_schema.blank?,
                label: 'URL parameters',
                add_field_label: 'Add URL parameter',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    sticky: input_schema.blank?
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
                        properties: call('make_schema_builder_fields_sticky',
                                         input_schema)
                      }
                    end
                  )
                ].compact
              }
            else
              {
                name: 'input',
                type: 'object',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    schema_neutral: true,
                    control_type: 'schema-designer',
                    sample_data_type: 'json_input',
                    sticky: input_schema.blank?,
                    label: 'Request body parameters',
                    add_field_label: 'Add request body parameter'
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
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
            name: 'output',
            control_type: 'schema-designer',
            sample_data_type: 'json_http',
            extends_schema: true,
            schema_neutral: true,
            sticky: true
          }
        ]
      end
    },
    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        parse_json(config_fields['output'] || '[]')
      end
    }
  },

  actions: {
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Assemble</span>",
      help: {
        body: 'Build your own Assemble action with an HTTP request'
      },
      config_fields: [{
        name: 'verb',
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: 'select',
        pick_list: %w[get post patch delete].map { |verb| [verb.upcase, verb] }
      }],
      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,
      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post patch delete].exclude?(verb)
          error("#{verb} not supported")
        end
        data = input.dig('input', 'data').presence || {}
        case verb
        when 'get'
          response =
            get(input['path'], data).
            headers('Content-Type': 'application/vnd.api+json').
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]').
                         dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          post(input['path'], data).
            headers('Content-Type': 'application/vnd.api+json').
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'patch'
          patch(input['path'], data).
            headers('Content-Type': 'application/vnd.api+json').
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'delete'
          delete(input['path'], data).
            headers('Content-Type': 'application/vnd.api+json').
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },
    get_projects: {
      title: 'Get projects',
      description: 'Get <span class="provider">projects</span> in <span class="provider">Assemble</span>.',

      execute: lambda do |_connection, input|
        { projects: get('/api/v1/powerbi/projects') }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'projects', label: 'Projects', 
            type: 'array', of: 'object', properties: object_definitions['project'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        { projects: get("/api/v1/powerbi/projects")&.dig(0) || {} }
      end

    },
    get_models: {
      title: 'Get models for a project',
      description: 'Get <span class="provider">models</span> in a project in <span class="provider">Assemble</span>.',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'projects_list',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Provide a project ID'
            }
          }
        ]
      end,
      execute: lambda do |_connection, input|
        { models: get("/api/v1/powerbi/projects/#{input['project_id']}/models") }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'models', label: 'Models', 
            type: 'array', of: 'object', properties: object_definitions['model'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        project = input['project_id'] || get("/api/v1/powerbi/projects")&.dig(0, 'id') || {}
        { models: get("/api/v1/powerbi/projects/#{project}/models")&.dig(0) || {} }
      end

    },
    get_model_versions: {
      title: 'Get model versions for a project',
      description: 'Get <span class="provider">model versions</span> in a project in <span class="provider">Assemble</span>.',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'projects_list',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Provide a project ID'
            }
          }
        ]
      end,
      execute: lambda do |_connection, input|
        { versions: get("/api/v1/powerbi/projects/#{input['project_id']}/versions") }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'versions', label: 'Versions', 
            type: 'array', of: 'object', properties: object_definitions['model_version'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        project = input['project_id'] || get("/api/v1/powerbi/projects")&.dig(0, 'id') || {}
        { versions: get("/api/v1/powerbi/projects/#{project}/versions")&.dig(0) || {} }
      end

    },
    get_properties: {
      title: 'Get properties for a project',
      description: 'Get <span class="provider">properties</span> in a project in <span class="provider">Assemble</span>.',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'projects_list',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Provide a project ID'
            }
          }
        ]
      end,
      execute: lambda do |_connection, input|
        { properties: get("/api/v1/powerbi/projects/#{input['project_id']}/properties") }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'properties', label: 'Properties', 
            type: 'array', of: 'object', properties: object_definitions['properties'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        project = input['project_id'] || get("/api/v1/powerbi/projects")&.dig(0, 'id') || {}
        { properties: get("/api/v1/powerbi/projects/#{project}/properties")&.dig(0) || {} }
      end

    },
    get_model_version_data: {
      title: 'Get model version data for a project',
      description: 'Get <span class="provider">model version data</span> in a project in <span class="provider">Assemble</span>.',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'projects_list',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Provide a project ID'
            }
          },
          {
            name: 'model_id',
            label: 'Model version',
            control_type: 'select',
            pick_list: 'model_versions_list',
            pick_list_params: { project_id: 'project_id' },
            optional: false,
            toggle_hint: 'Select model version',
            toggle_field: {
              name: 'model_id',
              label: 'Model ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use model ID',
              hint: 'Provide a model ID'
            }
          },
          {
            name: 'properties_select',
            label: 'Select properties',
            control_type: 'multiselect',
            pick_list: 'project_properties_list',
            pick_list_params: { project_id: 'project_id', model_id: 'model_id' },
            delimiter: ',',
            optional: true,
            sticky: true
          },
          {
            name: 'properties_define',
            label: 'Define properties',
            optional: true,
            sticky: true,
            type: 'array',
            of: 'object',
            properties: [
              { name: 'id' },
              { name: 'name' },
              { name: 'unit' },
              { name: 'dataType' },
              { name: 'type' },
              { name: 'source' }
            ]
          }
        ]
      end,
      execute: lambda do |_connection, input|
        if input['properties_select'].present?
          properties = input['properties_select'].split(',').map do |property|
            {
              'id': property.split('_')[0],
              'name': property.split('_')[1],
              'unit': property.split('_')[2],
              'dataType': property.split('_')[3],
              'type': property.split('_')[4],
              'source': property.split('_')[5]
            }
          end
        else
          properties = input['properties_define']
        end

        post("/api/v1/powerbi/projects/#{input['project_id']}/versiongriddata/#{input['model_id']}")
                        .request_body(properties.to_json)
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'records' },
          { name: 'rows', type: 'array', of: 'object', 
            properties: object_definitions['grid_data']
          }
        ]
      end,

      sample_output: lambda do |_connection, input|
        project = input['project_id'] || get("/api/v1/powerbi/projects")&.dig(0, 'id') || {}
        { properties: get("/api/v1/powerbi/projects/#{project}/properties")&.dig(0) || {} }
      end
    },
  },

  pick_lists: {
    projects_list: lambda do |_connection|
      get('/api/v1/powerbi/projects')&.map do |project|
        [ project.dig('name'), project.dig('id') ]
      end
    end,
    model_versions_list: lambda do |_connection, project_id:|
      if project_id.present? && project_id.slice(0,1) != '#'
        get("/api/v1/powerbi/projects/#{project_id}/versions")&.map do |version|
          [version.dig('name'), version['id']]
        end
      end
    end,
    project_properties_list: lambda do |_connection, project_id:, model_id:|
      if project_id.present? && project_id.slice(0,1) != '#'
        if model_id.present? && model_id.slice(0,1) != '#'
          properties = get("/api/v1/powerbi/projects/#{project_id}/properties")
          properties.where(['modelVersionId = ?', model_id]).first['properties'].map do |property|
            [ property.dig('name'), 
              "#{property['id']}_#{property['name']}_#{property['unit']}_#{property['dataType']}_#{property['type']}_#{property['source']}"
            ]
          end
        end
      end
    end,
  }
}
