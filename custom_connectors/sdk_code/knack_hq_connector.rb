{
  title: 'Knack HQ',

  connection: {
    fields: [
      { name: 'app_id', optional: false },
      { name: 'api_key', control_type: 'password', optional: false }
    ],

    authorization: {
      type: 'custom_auth',

      credentials: ->(connection) {
        headers('X-Knack-Application-Id': connection['app_id'],
                'X-Knack-REST-API-Key': connection['api_key'])
      }
    }
  },
  
  test: ->(connection) {
    get("https://api.knackhq.com/v1/objects")
  },

  object_definitions: {
    object_1: {
      fields: ->(connection) {
        get("https://api.knackhq.com/v1/objects/object_1/fields")['fields'].
          map { |f| { name: f['key'], label: f['label'] } }
      }
    }
  },

  actions: {
    
    get_object_1_by_id: {
      input_fields: ->(object_definitions) {
        [
          { name: 'id', optional: false }
        ]
      },
      
      execute: ->(connection,input) {
        get("https://api.knackhq.com/v1/objects/object_1/records/#{input['id']}")
      },
      
      output_fields: -> (object_definitions) {
        object_definitions['object_1']
      }
    }
  },

  triggers: {
    new_object_1_record: {
      type: :paging_desc,
      
      input_fields: -> (object_definitions) {},
      
      poll: ->(connection,input,page) {
        page ||= 1
        
        response = get("https://api.knackhq.com/v1/objects/object_1/records").
                     params(sort_field: 'id',
                            sort_order: 'desc',
                            page: page)
        
        next_page = response['total_pages'] == response['current_page'].to_i ? nil : (page + 1)
        
        {
          events: response['records'],
          next_page: next_page
        }
      },
      
      output_fields: -> (object_definitions) {
        object_definitions['object_1']
      }
    }
  }
}
