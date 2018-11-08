{
  title: 'transdirect',

  # HTTP basic auth example.
  connection: {
    fields: [
      {
        name: 'username',
        optional: true,
        hint: 'Your username; leave empty if using API key below'
      },
      {
        name: 'password',
        control_type: 'password',
        label: 'Password or personal API key'
      }
    ],

    authorization: {
      type: 'basic_auth',
      # them to the HTTP requests.
      credentials: ->(connection) {
          user(connection['username'])
          password(connection['password'])
        
      }
    }
  }, 
  object_definitions: {
    bookings: { 
      fields: ->(){
          [
            {name: 'id', type: :integer, control_type: :number, label: 'Booking ID'},
            {name: 'booked_at', type: :datetime, control_type: :timestamp, label: 'Created Date'},
            {name: 'booked_by', type: :string, control_type: :text, label: 'Booked By'},
            {name: 'created_at', type: :datetime, control_type: :timestamp, },
            {name: 'declared_value', type: :integer, control_type: :number},
            {name: 'insured_value', type: :integer, control_type: :number},
            {name: 'description', type: :string},
            {name: 'label', type: :string},
            {name: 'pickup_window', type: :array, of: :string, label: 'Ready Date'},
            {name: 'connote', type: :string, control_type: :text, label: 'Consignment'},
            {name: 'charged_weight', type: :integer, control_type: :number},
            {name: 'scanned_weight', type: :integer, control_type: :number},
            {name: 'special_instructions', type: :string, control_type: :text},
            {name: 'status', type: :string},
            {name: 'updated_at', type: :datetime, control_type: :timestamp},
            {name: 'pickup_instructions', type: :string},
            {name: 'tailgate_pickup', type: :boolean},
            {name: 'tailgate_delivery', type: :boolean},            
            {name: 'items', type: :array, of: :object, properties: [
                  {name: 'id', type: :integer, control_type: :number},
                  {name: 'description', type: :string, control_type: :text},
                  {name: 'weight', type: :integer, control_type: :number},
                  {name: 'height', type: :integer, control_type: :number},
                  {name: 'width', type: :integer, control_type: :number},
                  {name: 'length', type: :integer, control_type: :number},
                  {name: 'quantity', type: :integer, control_type: :number}                  
              ]},
            
            {name: 'notifications', type: :object, properties: [
                  {name: 'email', type: :boolean},
                  {name: 'sms', type: :boolean}
              ]},
            {name: 'sender', type: :object, properties: [
                {name: 'id', type: :integer},
                {name: 'address', type: :string, control_type: :text},
                {name: 'company_name', type: :string, control_type: :text},
                {name: 'email', type: :string},
                {name: 'name', type: :string},
                {name: 'postcode', type: :string, control_type: :text},
                {name: 'phone', type: :integer, control_type: :phone},
                {name: 'state'},
                {name: 'suburb'},
                {name: 'type'},
                {name: 'country'}
            ]},
            {name: 'receiver', type: :object, properties: [
                  {name: 'id', type: :integer},
                  {name: 'address', type: :string, control_type: :text},
                  {name: 'company_name', type: :string, control_type: :text},
                  {name: 'email', type: :string},
                  {name: 'name', type: :string},
                  {name: 'postcode', type: :string, control_type: :text},
                  {name: 'phone', type: :integer, control_type: :phone},
                  {name: 'state'},
                  {name: 'suburb'},
                  {name: 'type'},
                  {name: 'country'}
            ]},
            {name: 'quotes', type: :object, properties: [
                  {name: 'allied', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'couriers_please', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'fastway', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'toll_priority_overnight', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'tnt_nine_express', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'tnt_overnight_express', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'tnt_road_express', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'tnt_ten_express', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]},
                  {name: 'tnt_twelve_express', type: :object, properties: [
                        {name: 'total', type: :integer, control_type: :number},
                        {name: 'price_insurance_ex', type: :integer, control_type: :number},
                        {name: 'fee', type: :integer, control_type: :number},
                        {name: 'insured_amount', type: :integer, control_type: :number},
                        {name: 'service', type: :integer, control_type: :text},
                        {name: 'transit_time', type: :integer, control_type: :text},
                        {name: 'pickup_dates', type: :array, of: :date, control_type: :timestamp},
                        {name: 'pickup_time', type: :object, properties: [
                            {name: 'from', type: :string, control_type: :text},
                            {name: 'to', type: :string, control_type: :text}
                          ]}
                    ]}
            ]}          
         ]
        }

      },
    booking: {
      fields: ->(){
        [
          {name: 'declared_value', type: :integer, control_type: :number},
          {name: 'referrer'},
          {name: 'requesting_site'},
          {name: 'tailgate_pickup', type: :boolean},
          {name: 'tailgate_delivery', type: :boolean},
          {name: 'items', type: :array, of: :object, properties: [
            {name: 'weight', type: :integer, control_type: :number},
            {name: 'height', type: :integer, control_type: :number},
            {name: 'width', type: :integer, control_type: :number},
            {name: 'length', type: :integer, control_type: :number},
            {name: 'quantity', type: :integer, control_type: :number},
            {name: 'description', type: :string, control_type: :text}
          ]},
          {name: 'sender', type: :object, properties: [
            {name: 'address', type: :string, control_type: :text},
            {name: 'company_name', type: :string, control_type: :text},
            {name: 'email', type: :string},
            {name: 'name', type: :string},
            {name: 'postcode', type: :string, control_type: :text},
            {name: 'phone', type: :integer, control_type: :phone},
            {name: 'state'},
            {name: 'suburb'},
            {name: 'type'},
            {name: 'country'}
          ]},
          {name: 'receiver', type: :object, properties: [
            {name: 'address', type: :string, control_type: :text},
            {name: 'company_name', type: :string, control_type: :text},
            {name: 'email', type: :string},
            {name: 'name', type: :string},
            {name: 'postcode', type: :string, control_type: :text},
            {name: 'phone', type: :integer, control_type: :phone},
            {name: 'state'},
            {name: 'suburb'},
            {name: 'type'},
            {name: 'country'}
          ]}
        ]

      }
  
  	},
  },
  
  test: ->(connection) {
    get("https://www.transdirect.com.au/api/member")
  },

  actions: {   
    
    get_booking_details: {
      description: "Search <span class='provider'>Booking</span> in <span class='provider'>transdirect</span>",
      
      input_fields: ->(){
         {
              name: "id",
              type: "integer",
              label: "Booking Id"
          }
      },
      execute: ->(connection, input){
        { 
          booking: get("https://www.transdirect.com.au/api/bookings/"+ input['id']) 
        }
      },
      output_fields: ->(object_definitions){
        
        object_definitions['bookings']
        
      } },
    create_booking: {
      description: "Create <span class='provider'>Booking</span> details in <span class='provider'>transdirect</span>",
      input_fields: ->(object_definitions){
          object_definitions['booking']
      },
      execute: ->(connection,input) {
        { booking: post("https://www.transdirect.com.au/api/bookings",input) }
      },
      output_fields: ->(object_definitions){
        object_definitions['bookings']
      }
    }
  },

  triggers: {
      new_booking: {
        
        description: "New <span class='provider'>Booking</span> in <span class='provider'>transdirect</span>",
        subtitle: "Triggers when a new Booking is created",
        help: "Checks for new Booking every {{authUser.membership.poll_interval}} minutes.",

        
        input_fields: lambda do
          [
            {
              name: "since",
              type: "timestamp",
              hint: "Defaults to recipe start if not entered."
            }
          ]
        end,
        poll: lambda do |connection, input, last_updated_time |
          since = last_updated_time || input["since"] || Time.now 
          
          bookings = ( get("https://www.transdirect.com.au/api/bookings/").params( since: since.to_time.strftime("%Y-%m-%dT%H:%M:%S")) || [] ).reverse
          #puts response
          next_updated_time = bookings.last['updated_at'] unless bookings.blank?
          {
            events: bookings,
            next_poll: next_updated_time,
            can_poll_more:  bookings.blank? ? false : true            
          }
          
        end,
         dedup: lambda do |booking|
                booking['id']
          end,
        output_fields: lambda do |object_definitions|
          object_definitions['bookings']
        end

      }
   
  },
 
}
