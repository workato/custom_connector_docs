{
  title: 'Unbounce',

  connection: {
    fields: [
      {
        name: 'api_key',
        optional: false,
        control_type: 'password',
        hint: 'Profile (top right) > Manage Account > API Keys'
      },
      {
        name: 'page_id',
        optional: false,
        hint: "ID of page to connect, found at the end of respective page's URL"
      }
    ],

    authorization: {
      type: 'basic_auth',
      # unbounce uses api key only for authentication. treats apikey as username and password left blank
      # curl -u "{your api_key}:" "https://api.unbounce.com"
      credentials: ->(connection) {
        user(connection['api_key'])
        password("")
      }
    }
  },

  test: ->(connection) {
    get("https://api.unbounce.com/pages/#{connection['page_id']}")
  },
  
  object_definitions: {

    form: {
      fields: ->(connection) {
        get("https://api.unbounce.com/pages/#{connection['page_id']}/form_fields")['formFields'].
          map { |field| { name: field['id'] } }
      }
    },

    page: {
      fields: ->(connection) {
        [
          { name:'subAccountId', type: :integer },
          { name:'integrationsCount', type: :integer },
          { name:'integrationsErrorsCount', type: :integer },
          { name:'id' },
          { name:'createdAt', type: :datetime },
          { name:'lastPublishedAt', type: :datetime },
          { name:'name' },
          { name:'state' },
          { name:'url', control_type: 'url' },
          { name:'variantsCount', type: :integer },
          { name:'domain', control_type: 'url' },
          { name:'fullUrl', control_type: 'url' },
          { name: 'metaData', type: :object, properties: [
            { name: 'documentation', control_type: 'url' },
            { name: 'location', control_type: 'url' },
            { name: 'related', type: :object, properties: [
              { name: 'leads', control_type: 'url' },
              { name: 'subAccount', control_type: 'url' }
            ]}
          ]}
        ]
      }
    }
  },

  actions: {

    get_page_details: {
      input_fields: ->() {},
      execute: ->(connection,input) {
        get("https://api.unbounce.com/pages/#{connection['page_id']}")
      },
      output_fields: ->(object_definitions) {
        object_definitions['page']
      }
    }
  },
  
  triggers: {

    new_submission: {
      
      type: :paging_desc,
      
      input_fields: ->() {
        [
          { name: 'since', type: :timestamp,
            hint: 'Defaults to submissions after the recipe is first started' }
        ]
      },

      poll: ->(connection, input, last_created_since) {
        since = last_created_since || input['since'] || Time.now
        
        leads = get("https://api.unbounce.com/pages/#{connection['page_id']}/leads").
                  params(from: since.to_time.iso8601,
                         sort_order: :desc, # API sorts by creation date
                         limit: 10)['leads']

        leads.map do |lead|
          lead['formData'] = lead['formData'].map do |k,v|
                               { k => v.first }
                             end.
                             inject(:merge)
          lead
        end

        next_updated_since = leads.first['createdAt'] unless leads.length == 0

        {
          events: leads,
          next_page: next_updated_since
        }
      },

      output_fields: ->(object_definitions) {
        [
          { name: 'id', type: :integer },
          { name: 'formData', type: :object, properties: object_definitions['form'] }
        ]
      }
    }
  },
}
