{
  title: 'Visibly',

  connection: {
    fields: [
      {
        name: 'jaya@visibly.io',
        optional: true,
        hint: 'email used for login'
      },
      {
        name: 'Pgffcj',
        control_type: 'password',
      }
    ],

    authorization: {
      type: 'basic_auth',

      credentials: ->(connection) {
        user(connection['username'])
        password(connection['password'])
      }
    }
  },

  object_definitions: {
    session: {
      fields: ->() {
        [
          { name: 'Email' }
        ]
      }
    }
  },

 test: ->(connection) {
   post("https://api.visibly.io/api/v1/clients/feed?feed_identity=BymMA").
     payload("feed_identity":"BymMA","type":"Internal","isCampaign":false,"latitude":23.3783296,"longitude":72.0371712,"media":[],"feedStatus":"live","schedule":[{"social_account_identity":"0","scheduled_at":"instant"}],"isScheduledPost":false,"user_tag":[],"link_preview":[],"detail":"this is testing post")

 },

 object_definitions: {
   time_entry: {
     fields: ->() {
       [
         { name:'curation_display', type: :boolean },
         { name:'identity' },
         { name:'is_default' },
         { name:'job_display' },
         { name:'name', type: :boolean },
         {name:'name'},
         {name:'owner_id'},
         {name:'privacy'}, 
         {name:'type'},
         {name:'users',type:"object",properties:
            [
              {
                name:'company_tag',type:"object",properties:[],
                name:'department_tag',type:"object",properties:[],
                name:'users',type:"object",properties:[
                    {name:"email"}
                    {name:"first_name"},
                    {name:"identity"},
                    {name:"is_archived"},
                    {name:"is_guest"},
                    {name:"is_owner"},
                    {name:"last_name"},
                    {name:"position"},
                    {name:"profile_image"},
                    {name:"role_identity"},
                    {name:"role_name"}
                ]
              }
            ]
          },
         {name:"is_cionfigure"},  
       ]
     }
   }
 },


  actions: {
    get_user_id: {
      input_fields: ->() {
      },
      
      execute: -> (connection, input) {
        get("https://api.visibly.io/api/v1/clients/feed?feed_identity=BymMA")
      },
      
      output_fields: -> (object_definitions) {
              object_definitions['time_entry']
            }
          }
        },

  triggers: {}
}
