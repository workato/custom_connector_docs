{
  title: 'LoJack',

  connection: {
    fields: [
      {
        name: 'account',
      },
      {
        name: 'username',
      },
      {
        name: 'password',
        control_type: 'password',
      }
    ],

    authorization: {
      type: 'custom_auth',

      credentials: ->(connection) {
        params(connection.merge(lang: 'en', outputformat: 'json'))
        # LoJack API expects a non-standard Accept header
        headers(Accept: "*/*")
      }
    }
  },

  object_definitions: {
  },

  test: ->(connection) {
    get("https://csv.business.tomtom.com/extern?action=showObjectReportExtern&filterstring=XXXXXXXX")
  },

  actions: {
    get_object_reports: {
      # not used
      input_fields: ->() {
        [
          {
            name: "filterstring",
            label: "Filter String",
            optional: true,
            hint: "An arbitrary pattern that is located in the object data."
          },

          {
            name: "objectgroupname",
            label: "Object Group Name",
            optional: true,
            hint: "A name of an object group."
          },

          {
            name: "objectno",
            label: "Object No",
            optional: true,
            hint: "Identifying number of an object. Unique within an account, case-sensitive. Can be used alternatively to Object UID"
          },

          {
            name: "objectuid",
            label: "Object UID",
            optional: true,
            hint: "Identifying number of an object. Unique within an account, case-sensitive. Can be used alternatively to Object No"
          },
      	]
      },

      execute: ->(connection, input) {
        reply = get("https://csv.business.tomtom.com/extern?action=showObjectReportExtern", input)        
        {        
          reports: (reply[0] ? reply : []) # reply is an array when successful otherwise an object
        }
      },
      
      output_fields: ->(object_definitions) {
        [ 
          { 
            name: 'reports',
            type: 'array',
            of: 'object',
            properties: [
              { name: "objectno" },
              { name: "objectname" },
              { name: "objectclassname" },
              { name: "objecttype" },
              { name: "description" },
              { name: "lastmsgid", type: "integer" },
              { name: "deleted", type: "boolean" },
              { name: "msgtime", type: "date_time" },
              { name: "longitude" },
              { name: "latitude" },
              { name: "postext" },
              { name: "postext_short" },
              { name: "status" },
              { name: "driver" },
              { name: "driver_currentworkstate", type: "integer" },
              { name: "codriver_currentworkstate", type: "integer" },
              { name: "odometer", type: "integer" },
              { name: "ignition", type: "integer" },
              { name: "dest_distance", type: "integer" },
              { name: "tripmode", type: "integer" },
              { name: "standstill", type: "integer" },
              { name: "pndconn", type: "integer" },
              { name: "ignition_time", type: "date_time" },
              { name: "drivername" },
              { name: "pos_time", type: "date_time" },
              { name: "longitude_mdeg", type: "integer" },
              { name: "latitude_mdeg", type: "integer" },
              { name: "objectuid" },
              { name: "driveruid" }
          	]
          }
      	]
      }
    }
  },
}
