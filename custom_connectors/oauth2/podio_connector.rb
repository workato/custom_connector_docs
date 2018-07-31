# Substitute YOUR_PODIO_CLIENT_ID for your OAuth2 client id from Podio
# Substitute YOUR_PODIO_CLIENT_SECRET for your OAuth2 client secret from Podio
{
  title: 'Podio',

  connection: {
    authorization: {
      type: 'oauth2',

      authorization_url: ->() {
        'https://podio.com/oauth/authorize'
      },

      token_url: ->() {
        'https://podio.com/oauth/token'
      },

      client_id: 'YOUR_PODIO_CLIENT_ID',

      client_secret: 'YOUR_PODIO_CLIENT_SECRET',

      credentials: ->(connection, access_token) {
        headers('Authorization': "OAuth2 #{access_token}")
      }
    }
  },

  object_definitions: {
    contact: {
	fields: ->(connection) {
	        [
	          { name: 'profile_id'},
	          { name: 'name'},
	          { name: 'organization'},
	          { name: 'department'},
	          { name: 'skype'},
	          { name: 'about'},
	          { name: 'address'},
	          { name: 'zip'},
	          { name: 'city'},
	          { name: 'state'},
	          { name: 'country'},
	          { name: 'mail'},
	          { name: 'phone'},
	          { name: 'title'},
	          { name: 'linkedin'},
	          { name: 'url'},
	          { name: 'twitter'}
	        ]
      },
    },

    application: {
      fields: ->(connection)	{
        [
          { name: 'app_id'},
          { name: 'original'},
          { name: 'original_revision'},
          { name: 'status'},
          { name: 'space_id'},
          { name: 'owner', type: :object, properties: [{name: 'user_id', type: :integer}, {name: 'avatar'}, {name: 'name'}]},
          { name: 'link'},
          { name: 'link_add'},
          { name: 'config', type: :object,
            properties: 
            [
              {	name: 'type', control_type: 'select', picklist: [['standard'], ['meeting'], ['contact']]},
              {	name: 'name'},
              {	name: 'item_name'},
              {	name: 'description'},
              {	name: 'usage'},
              {	name: 'external_id'},
              {	name: 'icon'},
              {	name: 'allow_edit', type: :boolean},
              {	name: 'default view'},
              {	name: 'allow_attachments', type: :boolean},
              {	name: 'allow_comments', type: :boolean},
              {	name: 'fivestar', type: :boolean},
              {	name: 'fivestar_label'},
              {	name: 'approved', type: :boolean},
              { name: 'thumbs', type: :boolean},
              {	name: 'thumbs_label', type: :boolean},
              {	name: 'rsvp', type: :boolean},
              {	name: 'yesno', type: :boolean},
              {	name: 'yesno_label'},
              {	name: 'tasks'}
            ]
          }
        ]
      }
    },

    tag: {
      fields: ->(connection){
        [{ name: 'count'},{ name: 'text'}]
      }
    }
  },

  actions: {

    get_apps: {
    	input_fields: ->(object_definitions){
        [
          { name: 'Workspace ID', optional: 'false'}
        ]
      },

      execute: ->(connection, input) {
      	{ applications: get("https://api.podio.com/app/space/#{input['Workspace ID']}")}
      },

      output_fields: ->(object_definitions) {
	{ name: 'applications', type: 'array', of: 'object', properties: object_definitions['application']}
      }
    },

    get_app_detail: {
    	input_fields: ->(object_definitions){
        [
         { name: 'Application ID', optional: 'false'}
        ]
      },

      execute: ->(connection, input) {
      	{ app_detail: get("https://api.podio.com/app/#{input['Application ID']}")}
      },

      output_fields: ->(object_definitions){
        object_definitions['application']
      }
   },

   get_app_tags: {
   	input_fields: ->(object_definitions){
         [
           { name: 'Application ID', optional: 'false'}
         ]
      	},

	execute: ->(connection, input) {
	   { tags: get("https://api.podio.com/tag/app/#{input['Application ID']}")}
	},

	output_fields: ->(object_definitions){
	   { name: 'tags', type = 'array', of: 'object', properties: object_definitions['tag']}
	}
   },

   get_contacts: {
	input_fields: ->(object_definitions) {[]},

	execute: ->(connection, input) {
	   { contacts: get("https://api.podio.com/contact/?limit=5")}
	},

	output_fields: ->(object_definitions) {
         [
	   { name: 'contacts', type: 'array', of: 'object', properties: object_definitions['contact']}
      	 ]
      	}
   }

  }
}
