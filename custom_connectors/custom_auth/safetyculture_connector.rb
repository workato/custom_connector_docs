{
  title: 'SafetyCulture',

  connection: {
    fields: [
      {
        name: 'access_token',
        control_type: 'password'
      }
    ],

    authorization: {
      type: 'custom_auth',

      # Safety Culture uses non standard OAuth 2.0 type authentication. Workaround is to use access token generates in the UI
      credentials: ->(connection) {
        headers('Authorization': "Bearer #{connection['access_token']}")
      }
    }
  },

  test: ->(connection) {
    get("https://api.safetyculture.io/audits/search")
  },
  
  object_definitions: {
    audit: {
      fields: ->() {
       [
         { name: 'template_id' },
         { name: 'audit_id' },
         { name: 'created_at', type: :datetime },
         { name: 'modified_at', type: :datetime },
         { name: 'audit_data', type: :object, properties: [
           { name: 'name' },
           { name: 'score', type: :integer },
           { name: 'total_score', type: :integer },
           { name: 'score_percentage', type: :integer },
           { name: 'duration', type: :integer },
           { name: 'date_completed', type: :datetime },
           { name: 'date_modified', type: :datetime },
           { name: 'date_started', type: :datetime },
           { name: 'authorship', type: :object, properties: [
             { name: 'devise_id' },
             { name: 'owner' },
             { name: 'author' },
           ]}
         ]},
         { name: 'template_data', type: :object, properties: [
           { name: 'authorship', type: :object, properties: [
             { name: 'devise_id' },
             { name: 'owner' },
             { name: 'author' },
           ]},
             { name: 'metadata', type: :object, properties: [
             { name: 'description' },
             { name: 'name' }
           ]}
         ]},
         { name: 'header_items',type: :array, of: :object, properties: [
           { name: 'item_id' },
           { name: 'label' },
           { name: 'type' }
         ]},
         { name: 'items',type: :array, of: :object, properties: [
           { name: 'item_id' },
           { name: 'parent_id' },
           { name: 'label' },
           { name: 'type' },
           { name: 'scoring', type: :object, properties: [
             { name: 'combined_score', type: :integer },
             { name: 'combined_max_score', type: :integer },
             { name: 'combined_score_percentage', type: :integer },
           ]}
         ]}  
       ]  
      }  
    }
  },

  actions: {
    get_audit_data: {
      input_fields: ->() {
        [
          { name: 'audit_id' }
        ]
      },
      execute: ->(connection,input) {
        get("https://api.safetyculture.io/audits/#{input['audit_id']}")
      },
      output_fields: ->(object_definitions) {
        object_definitions['audit']
      } 
    }
  },

  triggers: {

    new_or_updated_audit: {

      type: :paging_desc,

      input_fields: ->() {
        [
          { name: 'since', type: :timestamp, optional: false,
            hint: 'Defaults to audits modified after the recipe is first started' },
          { name: 'completed', control_type: 'select', optional: false,
            pick_list: [
              ["Yes", "true"],
              ["No", "false"],
              ["Both", "both"]]
          }
        ]
      },

      poll: ->(connection, input, last_updated_since) {
        updated_since = last_updated_since || input['since'] || Time.now

        response = get("https://api.safetyculture.io/audits/search").
                  params(modified_after: updated_since.to_time.utc.iso8601,
                         order: :desc,
                         limit: 2,
                         completed: input['completed'])
        
        audits = response['audits'].map do |audit|
                   get("https://api.safetyculture.io/audits/#{audit['audit_id']}")
                 end

        next_updated_since = response['audits'].last['modified_at'] unless response['count'] == 0

        {
          events: audits,
          next_page: next_updated_since,
        }
      },

      dedup: ->(audit) {
        audit['audit_id']
      },

      output_fields: ->(object_definitions) {
        object_definitions['audit']
      }
    }
  }
}
