{
  title: 'BuildingConnected',

  connection: {
    fields: [
      {
        name: 'client_id',
        optional: false
      },
      {
        name: 'client_secret',
        control_type: 'password',
        optional: false
      },
      {
        name: 'environment',
        optional: false,
        control_type: :select,
        pick_list: [
          ['Production', 'app'],
          ['Staging', 'app-stage']
        ]
      }
    ],

    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|

        {
          access_token:
            post("https://#{connection['environment']}." \
                  'buildingconnected.com/api-beta/auth/token',
                grant_type: 'client_credentials')
              .user(connection['client_id'])
              .password(connection['client_secret'])
              .headers("Content-Type": "application/json")
              .dig("access_token")
        }

      end,

      refresh_on: [401, 403],

      apply: lambda do |connection|
        headers(Authorization: "Bearer #{connection['access_token']}")
      end
    },

    base_uri: lambda do |connection|
      "https://#{connection['environment']}.buildingconnected.com/api-beta/"
    end
  },

  test: lambda do |_connection|
    get('projects?limit=1')
  end,

  methods: {
    make_schema_builder_fields_sticky: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call(
                                 'make_schema_builder_fields_sticky', 
                                 field[:properties]
                               )
        elsif field['properties'].present?
          field['properties'] = call(
                                  'make_schema_builder_fields_sticky', 
                                  field['properties']
                                )
        end
        field[:sticky] = true
        field
      end
    end
  },

  object_definitions: {

    project: {
      fields: lambda do |_connection, config_fields|
        [
          { name: '_id', label: 'ID' },
          { name: 'name' },
          { name: 'number' },
          { name: 'location', type: 'object', properties: [
            { name: 'city' },
            { name: 'complete', label: 'Complete Address' },
            { name: 'coords', label: 'Coordinates', 
              type: 'object', properties: [
                { name: 'lat', label: 'Latitude' },
                { name: 'lng', label: 'Longitude' }
              ]
            },
            { name: 'country' },
            { name: 'state' },
            { name: 'streetName', label: 'Street Name' },
            { name: 'streetNumber', label: 'Street Number' },
            { name: 'zip' }
          ]},
          { name: 'value', type: 'integer' },
          { name: 'projectSize', label: 'Project Size', type: 'integer' },
          { name: 'client' },
          { name: 'description' },
          { name: 'notes' },
          { name: 'dateBidsDue', type: 'date_time', label: 'Date Bids Due' },
          { name: 'dateCreated', type: 'date_time', label: 'Date Created' },
          { name: 'dateEnd', type: 'date_time', label: 'Date End' },
          { name: 'datePublished', type: 'date_time', 
            label: 'Date Published' },
          { name: 'dateRFIsDue', type: 'date_time', label: 'Date RFIs Due'},
          { name: 'dateStart', type: 'date_time', label: 'Start Date' },
          { name: 'dateDue', type: 'date_time', label: 'Due Date' },
          { name: 'awarded' },
          { name: 'state' },
          { name: 'bidsSealed', type: 'integer' },
          { name: 'ndaRequired', type: 'integer' },
          { name: 'public', type: 'integer' },
          { name: 'budgeting', type: 'integer' }
        ]
      end
    },

    bid_package: {
      fields: lambda do |_connection, config_fields|
        [
          { name: '_id', label: 'ID' },
          { name: 'projectId', label: 'Project ID' },
          { name: 'name' },
          { name: 'number' },
          { name: 'keywords', type: 'array', of: 'string'},
          { name: 'estimatedCost', type: 'integer' },
          { name: 'state' },
          { name: 'dateBidsDue', type: 'date_time', label: 'Bids Due Date' },
          { name: 'dateCreated', type: 'date_time', label: 'Date Created' },
          { name: 'dateEnd', type: 'date_time', label: 'End Date' },
          { name: 'datePublished', type: 'date_time', 
            label: 'Date Published' },
          { name: 'dateRFIsDue', type: 'date_time', label: 'RFIs Due Date' },
          { name: 'dateStart', type: 'date_time', label: 'Start Date' },
          { name: 'dateJobWalk', type: 'date_time', label: 'Job Walk Date' }
        ]
      end
    },

    contact: {
      fields: lambda do |_connection, config_fields|
        [
          { name: '_id', label: 'ID' },
          { name: 'clientCompanyId', label: 'Client Company ID' },
          { name: 'companyTags', label: 'Company Tags', 
            type: 'array', of: 'string' },
          { name: 'dateCreated', type: 'date_time', label: 'Date Created' },
          { name: 'dateUpdated', type: 'date_time', label: 'Date Updated' },
          { name: 'isRemoved', label: 'Is Removed', type: 'integer' },
          { name: 'qualification', type: 'object', properties: [
            { name: 'pqRelationshipId', label: 'ID' },
            { name: 'dateExpires', type: 'date_time', label: 'Date Expires' },
            { name: 'dateUpdated', type: 'date_time', label: 'Date Updated' },
            { name: 'gcCurrency', label: 'Currency' },
            { name: 'projectLimit', label: 'Project Limit', type: 'integer' },
            { name: 'state' },
            { name: 'summary' },
            { name: 'totalLimit', type: 'integer' },
            { name: 'attachmentIds', type: 'array', of: 'string' }
          ] },
          { name: 'stats', type: 'object', properties: [
            { name: 'awardedCount', label: 'Awarded Count', 
              type: 'integer' },
            { name: 'awardedPercentage', label: 'Awarded Percentage', 
              type: 'number' },
            { name: 'bidCount', label: 'Bid Count', type: 'integer' },
            { name: 'biddingCount', label: 'Bidding Count', 
              type: 'integer' },
            { name: 'biddingPercentage', label: 'Bidding Percentage', 
              type: 'number' },
            { name: 'declinedCount', label: 'Declined Count', type: 'integer' },
            { name: 'declinedPercentage', label: 'Declined Percentage', 
              type: 'number' },
            { name: 'invitedCount', label: 'Invited Count', type: 'integer' },
            { name: 'viewedCount', label: 'Viewed Count', type: 'integer' },
            { name: 'viewedPercentage', label: 'Viewed Percentage', 
              type: 'number' }
          ] },
          { name: 'submissionStatus', label: 'Submission Status' },
          { name: 'vendorCompany', label:'Vendor Company', 
            type: 'object', properties: [
              { name: '_id', label: 'ID' },
              { name: 'name' },
              { name: 'website' },
              { name: 'enterpriseType', label: 'Enterprise Type', 
                type: 'array', of: 'string' },
              { name: 'businessType', label: 'Business Type', 
                type: 'array', of: 'string' },
              { name: 'labelType', label: 'Labor Type', 
                type: 'array', of: 'string' }
            ]
          },
          { name: 'vendorOffice', label: 'Vendor Office', 
            type: 'object', properties: [
              { name: '_id', label: 'ID' },
              { name: 'name' },
              { name: 'keywords', type: 'array', of: 'string' },
              { name: 'location', type: 'object', properties: [
                { name: 'complete', label: 'Complete Address' },
                { name: 'streetNumber', label: 'Street Number' },
                { name: 'streetName', label: 'Street Name' },
                { name: 'city' },
                { name: 'country' },
                { name: 'state' },
                { name: 'zip' },
                { name: 'coords', label: 'Coordinates', 
                  type: 'object', properties: [
                    { name: 'lat', label: 'Latitude' },
                    { name: 'lng', label: 'Longitude' }
                  ]
                }
              ] },
              { name: 'phone' }
            ]
          }
        ]
      end
    },

    bidder: {
      fields: lambda do |_connection, config_fields|
        [
          { name: '_id', label: 'ID' },
          { name: 'name' },
          { name: 'companyTags', label: 'Company Tags', 
            type: 'array', of: 'string' },
          { name: 'officeId', label: 'Office ID' },
          { name: 'projectId', label: 'Project ID' },
          { name: 'bidPackageId', label: 'Bid Package ID' },
          { name: 'state' },
          { name: 'dateSubmitted', type: 'date_time', 
            label: 'Date Submitted' },
          { name: 'submittedBy', label: 'Submitted By' },
          { name: 'amount', type: 'integer' },
          { name: 'adjustedTotal', label: 'Adjusted Total', 
            type: 'integer' }
        ]
      end
    },

    submission: {
      fields: lambda do |_connection, config_fields|
        [
          { name: '_id', label: 'ID' },
          { name: 'vendorId' },
          { name: 'pqRelationshipId' },
          { name: 'dateCreated', type: 'date_time' },
          { name: 'dateLastEdited', type: 'date_time' },
          { name: 'dateSubmitted', type: 'date_time' },
          { name: 'dateUpdated', type: 'date_time' },
          { name: 'openingStatement' },
          { name: 'reviseMessage' },
          { name: 'state' },
          { name: 'sections', type: 'array', of: 'object', properties: [
            { name: 'description' },
            { name: 'sectionType' },
            { name: 'questions', type: 'array', of: 'object', properties: [
              { name: '_id', label: 'ID' },
              { name: 'custom' },
              { name: 'label' },
              { name: 'responseType' },
              { name: 'value', type: 'array' },
              { name: 'children', type: 'array', of: 'object', properties: [
                { name: '_id', label: 'ID' },
                { name: 'children' },
                { name: 'custom' },
                { name: 'label' },
                { name: 'responseType' },
                { name: 'value', type: 'array' }
              ] }
            ] }
          ] }
        ]
      end
    },

    qualification_form: {
      fields: lambda do |_connection, config_fields|
        [
          { name: '_id', label: 'ID' },
          { name: 'companyId' },
          { name: 'createdBy' },
          { name: 'updatedBy' },
          { name: 'dateCreated', type: 'date_time' },
          { name: 'dateUpdated', type: 'date_time' },
          { name: 'openingStatement' },
          { name: 'sections', type: 'array', of: 'object', properties: [
            { name: '_id', label: 'ID' },
            { name: 'description' },
            { name: 'sectionType' },
            { name: 'questions', type: 'array', of: 'object', properties: [
              { name: '_id', label: 'ID' },
              { name: 'label' },
              { name: 'slug' },
              { name: 'responseType' },
              { name: 'custom', type: 'boolean' },
              { name: 'required', type: 'boolean' },
              { name: 'include', type: 'boolean' },
              { name: 'alwaysIncludeOrRequired', type: 'boolean' },
              { name: 'children', type: 'array', of: 'object', properties: [
                { name: '_id', label: 'ID' },
                { name: 'label' },
                { name: 'slug' },
                { name: 'responseType' },
                { name: 'custom', type: 'boolean' },
                { name: 'required', type: 'boolean' },
                { name: 'include', type: 'boolean' },
                { name: 'alwaysIncludeOrRequired', type: 'boolean' }
              ] },
            ] }
          ] },
          { name: 'sectionsHash' }
        ]
      end
    },

    qualification_submission: {
      fields: lambda do |_connection, config_fields|
        [
          { name: '_id' },
          { name: 'dateSubmitted', type: 'date_time' },
          { name: 'dateUpdated', type: 'date_time' },
          { name: 'companyName' },
          { name: 'yearFounded', type: 'integer' },
          { name: 'stateFounded' },
          { name: 'federalTaxId' },
          { name: 'submissionCurrency' },
          { name: 'numberOfHomeOfficeEmployees', type: 'integer' },
          { name: 'numberOfFieldSupervisoryEmployees', type: 'integer' },
          { name: 'hasEnterpriseBusinessCertifications', type: 'boolean' },
          { name: 'hasProfessionalLicenses', type: 'boolean' },
          { name: 'hasUnionAffiliations', type: 'boolean' },
          { name: 'hasParentCompany', type: 'boolean' },
          { name: 'parentCompanyName' },
          { name: 'currentEstimatedBacklog', type: 'integer' },
          { name: 'insuranceBrokerCompanyName' },
          { name: 'insuranceBrokerContactName' },
          { name: 'insuranceBrokerContactPhone', type: 'integer' },
          { name: 'insuranceBrokerContactEmail' },
          { name: 'suretyBrokerCompanyName' },
          { name: 'suretyBrokerContactName' },
          { name: 'suretyBrokerContactPhone', type: 'integer' },
          { name: 'suretyCompanyName' },
          { name: 'suretySingleProjectBondingCapacity', type: 'integer' },
          { name: 'suretyAggregateBondingCapacity', type: 'integer' },
          { name: 'bankName' },
          { name: 'bankLineOfCreditTotal', type: 'integer' },
          { name: 'bankLineOfCreditOutstanding', type: 'integer' },
          { name: 'bankContactName' },
          { name: 'bankContactPhone', type: 'integer' },
          { name: 'bankContactEmail' },
          { name: 'csiCodesForWorkPerformed', type: 'array', 
            of: 'objects', properties: [
              { name: 'primaryCode' },
              { name: 'secondaryCode' },
              { name: 'tertiaryCode' },
              { name: 'description' }
            ]
          },
          { name: 'regions', type: 'array', of: 'object', properties: [
            { name: 'region' }
          ]},
          { name: 'markets', type: 'array', of: 'object', properties: [
            { name: 'market' }
          ]},
          { name: 'completedReferences', type: 'array', 
            of: 'object', properties: [
              { name: 'projectName' },
              { name: 'location' },
              { name: 'yearCompleted' },
              { name: 'value', type: 'integer' },
              { name: 'scope' },
              { name: 'referenceContactCompany' },
              { name: 'referenceContactName' },
              { name: 'referenceContactPhone', type: 'integer' },
              { name: 'referenceContactEmail' },
              { name: 'isLargestProject', type: 'boolean' }
            ]
          },
          { name: 'companyContacts', type: 'array', 
            of: 'object', properties: [
              { name: 'positionTitle' },
              { name: 'contactName' },
              { name: 'contactPhone', type: 'integer' },
              { name: 'contactEmail' },
              { name: 'contactFax', type: 'integer' },
              { name: 'contactType' }
            ]
          },
          { name: 'insuranceCoverages', type: 'array', 
            of: 'object', properties: [
              { name: 'insuranceType' },
              { name: 'carrier' },
              { name: 'perOccurrenceLimit', type: 'integer' },
              { name: 'aggregateLimit', type: 'integer' },
              { name: 'policyExpirationDate' },
              { name: 'notApplicable', type: 'boolean' }
            ]
          },
          { name: 'emr', type: 'array', of: 'object', properties: [
            { name: 'year', type: 'integer' },
            { name: 'emr' }
          ]},
          { name: 'osha300Results', type: 'array', 
            of: 'object', properties: [
              { name: 'year', type: 'integer' },
              { name: 'totalNumberDeathsBoxG', type: 'integer' },
              { name: 'totalNumberCasesDaysAwayBoxH', type: 'integer' },
              { name: 'totalNumberCasesRestrictionTransferBoxI', 
                type: 'integer' },
              { name: 'otherRecordableCasesBoxJ', type: 'integer' },
              { name: 'totalHoursWorked', type: 'integer' }
            ]
          },
          { name: 'enterpriseBusinessCertifications', type: 'array', 
            of: 'object', properties: [
              { name: 'additionalDescription' },
              { name: 'certificationState' },
              { name: 'certificationNumber' },
              { name: 'certificationType' },
              { name: 'otherType' },
              { name: 'certificationLevel' },
              { name: 'certificationCounty' },
              { name: 'certificationCity' },
              { name: 'certificationFederal' },
              { name: 'otherLevel' },
              { name: 'ownershipEthnicity' },
              { name: 'otherEthnicity' }
            ]
          },
          { name: 'unions', type: 'array', 
            of: 'object', properties: [
              { name: 'unionName' },
              { name: 'unionNumber' }
            ]
          },
          { name: 'annualVolumeRevenue', type: 'array', 
            of: 'object', properties: [
              { name: 'year', type: 'integer' },
              { name: 'estimatedVolumeRevenue', type: 'integer' }
            ]
          },
          { name: 'professionalLicenses', type: 'array', 
            of: 'object', properties: [
              { name: 'licenseType' },
              { name: 'licenseNumber' },
              { name: 'licenseState' },
              { name: 'issuingAgency' },
              { name: 'additionalDescription' }
            ]
          },
          { name: 'companyOfficeAddresses', type: 'array', 
            of: 'object', properties: [
              { name: 'isMainOffice', type: 'boolean' },
              { name: 'address1' },
              { name: 'address2' },
              { name: 'city' },
              { name: 'state' },
              { name: 'zip' }
            ]
          },
          { name: 'customQuestions', type: 'array', 
            of: 'object', properties: [
              { name: 'question' },
              { name: 'section' },
              { name: 'textResponse' },
              { name: 'numberResponse', type: 'integer' },
              { name: 'booleanResponse', type: 'boolean' }
            ]
          }
        ]
      end
    },

    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: "Base URI is https://#{connection['environment']}." \
                  'buildingconnected.com/api-beta/ - path will be appended ' \
                  'to this URI. Use absolute URI to override this base URI.'
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
                        properties: call(
                                      'make_schema_builder_fields_sticky',
                                      input_schema
                                    )
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
                        properties: input_schema
                        .each { |field| field[:sticky] = true }
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

  triggers: {
    new_updated_contact: {
      title: 'New or updated contact',
      description: 'New or updated <span class="provider">contact</span> '\
                    ' in <span class="provider">BuildingConnected</span>',
      help: {
        body: 'Triggers when a contact is created or updated.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        updated_after = closure['updatedAfter'] ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601

        response = if closure['afterId'].present?
                     get('contacts')
                       .params(
                          updatedAfter: updated_after,
                          afterId: closure['afterId']
                        )
                   else
                     get('contacts')
                       .params(updatedAfter: updated_after)
                   end

        closure = if response['results'].length > 0
                    {
                      'afterId' => response['results'].last['_id'],
                      'updatedAfter' => updated_after
                    }
                  end

        {
          events: response['results'] || [],
          next_poll: closure,
          can_poll_more: response['results'].length > 0
        }
      end,

      dedup: lambda do |object|
        "#{object['_id']}@#{object['dateUpdated']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['contact']
      end,

      sample_output: lambda do |_connection|
        get('contacts?limit=1').dig('results')[0]
      end

    }
  },

  actions: {
    custom_action: {
      description: 'Custom <span class="provider">action</span> ' \
                    'in <span class="provider">BuildingConnected</span>',
      help: {
        body: 'Build your own BuildingConnected action for any ' \
              'BuildingConnected API endpoint.',
        learn_more_url: 'https://app.buildingconnected.com/docs/',
        learn_more_text: 'BuildingConnected API Documentation'
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
        if %w[get post patch delete].exclude?(input['verb'])
          error("#{input['verb']} not supported")
        end
        data = input.dig('input', 'data').presence || {}
        case input['verb']
        when 'get'
          response = get(input['path'], data)
                     .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.compact
          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]')
                         .dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          post(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'patch'
          patch(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'delete'
          delete(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    get_contacts: {
      title: 'Get contacts',
      description: 'Get <span class="provider">contacts</span> ' \
                    'in <span class="provider">BuildingConnected</span>',
      help: "Retrieve a list of your company's contacts",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'updatedAfter',
            label: 'Updated After',
            sticky: true,
            type: 'timestamp',
            hint: 'Only retrieve contacts that were created/updated ' \
                  'after this specified datetime.'
          },
          {
            name: 'includeRemoved',
            label: 'Include Closed',
            type: :integer,
            sticky: true,
            hint: 'Specify whether to retrieve removed contacts. ' \
                    'The default is `0` and setting a `1` will inlude ' \
                    'removed contacts.'
          },
          {
            name: 'page',
            type: :integer,
            sticky: true,
            hint: 'Specify the page to retrieve.'
          },
          {
            name: 'limit',
            type: :integer,
            sticky: true,
            hint: 'Specify the number of projects to retrieve in a page. ' \
                  'Default is 50. Limit can be between 1 and 100.'
          },
          {
            name: 'afterId',
            label: 'After ID',
            sticky: true,
            hint: 'Specify the project ID to skip when paginating. ' \
                  'For example, if you want the next list of projects ' \
                  'following a specific project, enter the project ID to skip.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get('contacts')
          .params(input)
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: 'total',
            type: 'integer'
          },
          {
            name: 'results',
            type: 'array',
            of: 'object',
            properties: object_definitions['contact']
          }
        ]
      end,

      sample_output: lambda do |_connection|
        get('contacts?limit=1')
      end
    },

    get_contact: {
      title: 'Get contact by ID',
      description: 'Get <span class="provider">contact by ID</span> ' \
                    'in <span class="provider">BuildingConnected</span>',
      help: 'Retrieve a contact using the contact ID',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'contactId',
            label: 'Contact ID',
            hint: 'Specify the contact ID',
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get('contacts/' + input['contactId'])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['contact']
      end,

      sample_output: lambda do |_connection|
        get('contacts?limit=1').dig('results')[0]
      end
    },

    get_projects: {
      title: 'Get projects',
      description: 'Get <span class="provider">projects</span>' \
                    ' in <span class="provider">BuildingConnected</span>',
      help: "Retrieve a list of your company's projects",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'includeClosed',
            label: 'Include Closed',
            type: :integer,
            sticky: true,
            hint: 'Specify whether to retrieve closed projects.' \
                  ' The default is `0` and setting a `1` will inlude closed ' \
                  'projects.'
          },
          {
            name: 'page',
            type: :integer,
            sticky: true,
            hint: 'Specify the page to retrieve.'
          },
          {
            name: 'limit',
            type: :integer,
            sticky: true,
            hint: 'Specify the number of projects to retrieve in a page. ' \
                  'Default is 50. Limit can be between 1 and 100.'
          },
          {
            name: 'afterId',
            label: 'After ID',
            sticky: true,
            hint: 'Specify the project ID to skip when paginating. ' \
                  'For example, if you want the next list of projects ' \
                  'following a specific project, enter the project ID to skip.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get('projects')
          .params(input)
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: 'total',
            type: 'integer'
          },
          {
            name: 'results',
            type: 'array',
            of: 'object',
            properties: object_definitions['project']
          }
        ]
      end,

      sample_output: lambda do |_connection|
        get('projects?limit=1')
      end
    },

    get_project: {
      title: 'Get project by ID',
      description: 'Get <span class="provider">project by ID</span> '\
                    'in <span class="provider">BuildingConnected</span>',
      help: 'Retrieve a project using the project ID',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'projectId',
            label: 'Project ID',
            hint: 'Specify the project ID',
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get('projects/' + input['projectId'])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['project'].concat(
          [
            {
              name: 'bidPackages',
              label: 'Bid Packages',
              type: 'array', of: 'object',
              properties: object_definitions['bid_package']
            }
          ]
        )
      end,

      sample_output: lambda do |_connection|
        project_id = get('projects?limit=1').dig('results')[0].dig('_id')
        get('projects/' + project_id)
      end
    },

    get_bidders: {
      title: 'Get bidders for a bid package',
      description: 'Get <span class="provider">bidders</span> for a bid ' \
                    'package in <span class="provider">BuildingConnected' \
                    '</span>',
      help: 'Retrieve bidders for a project and bid package',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'projectId',
            label: 'Project ID',
            hint: 'Specify the project ID',
            optional: false
          },
          {
            name: 'bidPackageId',
            label: 'Bid Package Id',
            hint: 'Specify the bid package ID',
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("projects/#{input['projectId']}/bid-packages/" \
            "#{input['bidPackageId']}/bidders")
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: 'total',
            type: 'integer'
          },
          {
            name: 'results',
            type: 'array',
            of: 'object',
            properties: object_definitions['bidder']
          }
        ]
      end,

      sample_output: lambda do |_connection|
        project_id = get('projects?limit=1')
                     .dig('results')[0]
                     .dig('_id')
        bid_package_id = get("projects/#{project_id}")
                         .dig('bidPackages')[0]
                         .dig('_id')
        get("projects/#{project_id}/bid-packages/#{bid_package_id}/bidders")
      end
    },

    get_qualification: {
      title: 'Get qualification submission',
      description: 'Get <span class="provider">qualification submission' \
              '</span> in <span class="provider">BuildingConnected</span>',
      help: 'Retrieve qualification submission using an ID',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'idType',
            label: 'ID Type',
            optional: false,
            control_type: 'select',
            hint: 'Select the ID type to use. The qualification ID is ' \
                  'found on the contact object for the vendor.',
            pick_list: [
              ['Vendor ID', 'vendorId'],
              ['Qualification ID', 'pqRelationshipId']
            ]
          },
          {
            name: 'id',
            optional: false,
            label: 'ID'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        if input['idType'] == 'vendorId'
          get('qm-submissions')
            .params(vendorId: input['id'])
        else
          get('qm-submissions')
            .params(pqRelationshipId: input['id'])
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['submission']
      end,

      sample_output: lambda do |_connection|
        vendor_id = get('contacts?limit=1')
                    .dig('results')[0]
                    .dig('vendorCompany')['_id']
        get("qm-submissions?vendorId=#{vendor_id}")
      end
    },

    get_qualification_form: {
      title: 'Get qualification form',
      description: 'Get <span class="provider">qualification form</span> in ' \
                    '<span class="provider">BuildingConnected</span>',
      help: 'Retrieve qualification form your company uses to ' \
            'qualify subcontractors',

      execute: lambda do |_connection|
        get('qm-form')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['qualification_form']
      end,

      sample_output: lambda do |_connection|
        get('qm-form')
      end
    },

    get_qualifications_tradetapp: {
      title: 'Get completed TradeTapp qualifications',
      description: 'Get <span class="provider">completed TradeTapp ' \
                  'qualifications</span> in <span class="provider">' \
                  'BuildingConnected</span>',
      help: 'Retrieve completed TradeTapp qualification submissions ' \
              'from your vendors',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'page',
            type: :integer,
            hint: 'Specify the page to retrieve.',
            sticky: true
          },
          {
            name: 'limit',
            type: :integer,
            hint: 'Specify the number of submissions to retrieve in a page. ' \
                    'Default is 50. Limit can be between 1 and 100.',
            sticky: true
          },
          {
            name: 'afterId',
            label: 'After ID',
            hint: 'Specify the vendor ID to skip when paginating. ' \
                  'For example, if you want the next list of vendor ' \
                  'qualification submissions, enter the vendor ID to skip.',
            sticky: true
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get('tradetapp/qualification-submissions')
          .params(input)
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'total', type: 'integer' },
          { name: 'results',
            type: 'array',
            of: 'object',
            properties: object_definitions['qualification_submission'] }
        ]
      end,

      sample_output: lambda do |_connection|
        get('tradetapp/qualification-submissions?limit=1')
      end
    }

  }
}
