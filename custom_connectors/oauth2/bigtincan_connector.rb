{
 title: 'Bigtincan Hub',

 connection: {

    authorization: {
     type: 'oauth2',

    authorization_url: ->() {
      'https://pubapi.bigtincan.com/services/oauth2/authorize?response_type=code&device_id=hub_auth'
    },

    token_url: ->() {
      'https://pubapi.bigtincan.com/services/oauth2/token'
    },

    client_id: 'BIGTINCAN_CLIENT_ID',

    client_secret: 'BIGTINCAN_CLIENT_SECRET',

    credentials: ->(connection, access_token) {
        headers('Authorization': "Bearer #{access_token}")
    }
  }
},

  object_definitions: {

    channel: {

      fields: ->() {
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' },
          { name: 'channel_type', type: 'string' }
        ]
      }
    },


    single_story: {
      fields: ->() {
        [
          { name: 'revision_id', type: 'string' },
          { name: 'perm_id', type: 'string' },
          { name: 'title', type: 'string'},
          { name: 'description', type: 'string'},
          { name: 'channels', type: :array, of: :object,
            properties: [
              { name: 'id', type: 'string'}
            ]
          }
        ]
      }
      },

    single_form: {
      fields: ->() {
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' }
        ]
      }

    },

    single_form_category: {

      fields: ->() {
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' },
          { name: 'note', type: 'string' }
        ]
      }
    },

    form_submission_data: {
      fields: ->(connection, config_fields) {
        [
          { name: 'submission_key', type: 'string' },
          { name: 'user_id', type: 'string' },
          { name: 'user_name', type: 'string' },
          { name: 'cursor', type: 'string' },
          { name: 'data', type: :object,
            properties:
              if config_fields['form_id'].present?
                fields = get("https://pubapi.bigtincan.com/v1/form/get/#{config_fields['form_id']}")['data']['form_data']['fields']
                fields.select { |field| field['label'].present? }.
                       map do |field|
                         {
                           name: field['label'].gsub(/[ ]/, '_'),
                           label: field['label'],
                           type: 'string'
                         }
                       end
              end
          }
        ]
      }
    }
  },

  actions: {
   # form: form/data
    get_form_data: {

      input_fields: ->() {
         [
           { name: 'form_id', optional: false },
           { name: 'page', optional: true },
           { name: 'limit', optional: true },
         ]
      },

      execute: ->(connection, input) {
        if input['page'].blank?
             input['page'] = 1
        end

        if input['limit'].blank?
             input['limit'] = 10
        end

        get("https://pubapi.bigtincan.com/v1/form/data/#{input['form_id']}").params(page: input['page'], limit: input['limit'])['data']
      },

      output_fields: ->(object_definitions) {
        [
         { name: 'columns', type: :array, of: :object,
           properties: [
               { name: 'columns', type: :array, of: :object },
             ]
         },
         { name: 'total_submissions', type: 'integer' },
         { name: 'submission_current_count', type: 'integer' },
         { name: 'submission_limit', type: 'integer'},
         { name: 'submission_page', type: 'integer' },
         { name: 'submission_next_page', type: 'integer' },
         { name: 'submission_prev_page', type: 'integer' },
         { name: 'submissions', type: :array, of: :object, properties: object_definitions['form_submission_data'] }
         ]
       }
    },

    # form: form/all
    list_forms: {
      input_fields: ->() {
         [
           { name: 'category_id', optional: true },
           { name: 'page', optional: true },
           { name: 'limit', optional: true },
         ]
      },

      execute: ->(connection, input) {

        if input['page'].blank?
             input['page'] = 1
        end

        if input['limit'].blank?
             input['limit'] = 10
        end

        get("https://pubapi.bigtincan.com/v1/form/all").params(input)
      
      },

      output_fields: ->(object_definitions) {
        [
         { name: 'page',  type: 'integer' },
         { name: 'page_total',  type: 'integer' },
         { name: 'limit',  type: 'integer' },
         { name: 'total_count',  type: 'integer' },
         { name: 'next_page',  type: 'integer' },
         { name: 'prev_page',  type: 'integer' },
         { name: 'current_count',  type: 'integer' },
         { name: 'data', type: :array, of: :object, properties: object_definitions['single_form'] },
        ]
      }
    },

    #form: form_category/all
    list_form_categories: {
        
        input_fields: ->() {
           [
             { name: 'page', optional: true },
             { name: 'limit', optional: true },
           ]
        },

      execute: ->(connection, input) {
        if input['page'].blank?
               input['page'] = 1
          end

          if input['limit'].blank?
               input['limit'] = 10
        end
        
        get("https://pubapi.bigtincan.com/v1/form_category/all").params(input)
      },

      output_fields: ->(object_definitions) {
        [
         { name: 'page',  type: 'integer' },
         { name: 'page_total',  type: 'integer' },
         { name: 'limit',  type: 'integer' },
         { name: 'total_count',  type: 'integer' },
         { name: 'next_page',  type: 'integer' },
         { name: 'prev_page',  type: 'integer' },
         { name: 'current_count',  type: 'integer' },
         { name: 'data', type: :array, of: :object, properties: object_definitions['single_form_category'] },
        ]
      }
    },

    #form: form/get
    get_form: {
      input_fields: ->() {
         [
           { name: 'form_id', optional: false },
           { name: 'include_data_sources', optional: true },
         ]
      },

      execute: ->(connection, input) {

        if input['include_data_sources'].blank?
             input['include_data_sources'] = true
        end

        get("https://pubapi.bigtincan.com/v1/form/get/#{input['form_id']}").params(include_data_sources: input['include_data_sources'])['data']

      },

        output_fields: ->(object_definitions) {
        [
         { name: 'id', type: 'string' },
         { name: 'name', type: 'string' },
         { name: 'form_data', 
           type: :object, 
           properties: [
             { name: 'fields', type: :array, of: :object,
               properties: [
                 { name: 'type', type: 'string'},
                 { name: 'value', type: 'string'},
                 { name: 'label', type: 'string'},
               ] }
           ]
         }
        ]
      },
    },
    
    #form: form/get fields only
    list_form_fields: {
             input_fields: ->() {
                [
                  { name: 'form_id', optional: false },
                ]
             },
       
             execute: ->(connection, input) {
       
               if input['include_data_sources'].blank?
                   input['include_data_sources'] = true
               end
       
               get("https://pubapi.bigtincan.com/v1/form/get/#{input['form_id']}")['data']['form_data']
       
             },
       
             output_fields: ->(object_definitions) {
             
                  [
                    { name: 'fields', type: :array, of: :object,
                      properties: [
                        { name: 'type', type: 'string'},
                        { name: 'value', type: 'string'},
                        { name: 'label', type: 'string'},
                      ] }
                  ]
         
             },
    },

    #story: story/all
    list_stories: {
      input_fields: ->() {
         [
           { name: 'channel_id', optional: true, type: :string , control_type: 'select', pick_list: 'channel_id' },
           { name: 'page', optional: true },
           { name: 'limit', optional: true },
         ]
      },
      execute: ->(connection, input) {
        
        if input['page'].blank?
                       input['page'] = 1
                  end

                  if input['limit'].blank?
                       input['limit'] = 10
        end
        
        get("https://pubapi.bigtincan.com/v1/story/all").params(input)
      },
      output_fields: ->(object_definitions) {
        [
         { name: 'page', type: 'integer' },
         { name: 'page_total', type: 'integer' },
         { name: 'limit',  type: 'integer' },
         { name: 'total_count', type: 'integer' },
         { name: 'next_page', type: 'integer' },
         { name: 'prev_page', type: 'integer' },
         { name: 'current_count',  type: 'integer' },
         { name: 'data', type: :array, of: :object, properties: object_definitions['single_story'] },
        ]
      }
    },

    #story: story/get
    get_story: {
      input_fields: ->() {
         [
           { name: 'story_perm_id', optional: false },
         ]
      },
      execute: ->(connection, input) {
        get("https://pubapi.bigtincan.com/v1/story/get/#{input['story_perm_id']}")
      },
      output_fields: ->(object_definitions) {
        [
          { name: 'data', type: :object, properties: object_definitions['single_story'] },
        ]
      }
    },

    #story: story/add
    create_story: {
      input_fields: ->() {
         [
           { name: 'title', optional: false },
           { name: 'description', optional: false },
           { name: 'channel_id', optional: false, type: :string , control_type: 'select', pick_list: 'channel_id' },
         ]
      },
      execute: ->(connection, input) {
        
        payload_object = {
          title: input['title'].presence,
          description: input['description'].presence,
          channels: [ { id: input['channel_id'] } ]
        }.compact
        
        post("https://pubapi.bigtincan.com/v1/story/add").payload(payload_object)
      },
      
      output_fields: ->(object_definitions) {
        [
          { name: 'data', type: :object, properties: object_definitions['single_story'] },
        ]
      }
    },

    #story: story/edit
    update_story: {
      input_fields: ->() {
         [
           { name: 'title', optional: true },
           { name: 'description', optional: true },
           { name: 'channel_id', optional: false, type: :string , control_type: 'select', pick_list: 'channel_id' },
           { name: 'revision_id', optional: false },
         ]
      },
      execute: ->(connection, input) {

        payload_object = {
          title: input['title'].presence,
          description: input['description'].presence,
          channels: [ { id: input['channel_id'] } ]
        }.compact
        
        put("https://pubapi.bigtincan.com/v1/story/edit/#{input['revision_id']}").payload(payload_object)['data']
      },

      output_fields: ->(object_definitions) {
        object_definitions['single_story']
      }
    },

    #story: story/delete
    delete_story: {

    input_fields: ->() {
         [
           { name: 'revision_id', optional: false },
         ]
      },
   execute: ->(connection, input) {
        delete("https://pubapi.bigtincan.com/v1/story/archive/#{input['revision_id']}")['data']
      },
   output_fields: ->(object_definitions) {
        [
          { name:'deleted', type:'boolean' }
        ]
    }
   },

   #channal: channel/all
   list_channels: {
    
      input_fields: ->() {
         [
           { name: 'page', optional: true },
           { name: 'limit', optional: true },
         ]
      },

      execute: ->(connection, input) {
        if input['page'].blank?
          input['page'] = 1
        end

        if input['limit'].blank?
          input['limit'] = 10
        end
        
        get("https://pubapi.bigtincan.com/v1/channel/all").params(input)
      },
      output_fields: ->(object_definitions) {
        [
         { name: 'page',  type: 'integer' },
         { name: 'page_total',  type: 'integer' },
         { name: 'limit',  type: 'integer' },
         { name: 'total_count',  type: 'integer' },
         { name: 'next_page',  type: 'integer' },
         { name: 'prev_page',  type: 'integer' },
         { name: 'current_count',  type: 'integer' },
         { name: 'data', type: :array, of: :object, properties: object_definitions['channel'] },
        ]
      }
    },
   },

   triggers: {

    new_form_submission: {

      type: :paging_desc,

      config_fields: [
        {  name: 'form_id', label: 'Form ID', optional: false, control_type: 'select', pick_list: 'form_id' }
      ],

      poll: ->(connection, input, page) {

        page ||= 1

        response = get("https://pubapi.bigtincan.com/v1/form/data/#{input['form_id']}").
                    params(limit: 30,
                           page: page,
                           sort: 'desc')['data']

        {
          events: response['submissions'],
          next_page: response['submission_next_page'],
        }
      },

      document_id: ->(submission) {
        submission['cursor']
      },

      output_fields: ->(object_definitions) {
        object_definitions['form_submission_data']
      }

    },

    new_story: {

      type: :paging_desc,

      input_fields: ->() {
              [
                { name: 'channel_id', optional: false, type: :string, control_type: 'select', pick_list: 'channel_id' }
              ]
      },

      poll: ->(connection, input, page) {

        page ||= 1

        stories = get("https://pubapi.bigtincan.com/v1/story/all").params(limit: 30, page: page, channel_id: input['channel_id'])

         { next_page: stories['next_page'], events: stories['data'] }
      },

      document_id: ->(story) {
        story['perm_id']
      },

      output_fields: ->(object_definitions) {
        object_definitions['single_story']
      }
    }
   },

   pick_lists: {

     channel_id: ->(connection){
       get("https://pubapi.bigtincan.com/v1/channel/all")['data'].
         map { |channel_id| [channel_id['name'], channel_id['id']] }
     },

     form_id: ->(connection){
       get("https://pubapi.bigtincan.com/v1/form/all?limit=100&form_only")['data'].
         map { |form_id| [form_id['name'], form_id['id']] }
     }

   }
}
