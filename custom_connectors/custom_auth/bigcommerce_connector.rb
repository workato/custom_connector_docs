{
  title: 'Big Commerce',

  connection:
  {
    fields: [
      {
        name: 'client_id',
        hint: 'Click ' \
          "<a href='https://developer.bigcommerce.com/api-docs/getting-" \
          "started/authentication#obtaining-app-api-credentials' " \
          "target='_blank'>here</a> to get client id",
        optional: false
      },
      {
        name: 'access_token',
        label: 'Access Token',
        hint: 'Click ' \
          "<a href='https://developer.bigcommerce.com/api-docs/getting-" \
          "started/authentication#obtaining-app-api-credentials' " \
          "target='_blank'>here</a> to get access token",
        optional: false,
        control_type: 'password'
      },
      { name: 'store_hash', optional: false }
    ],
    authorization: {
      type: 'custom',
      apply: lambda do |connection|
        headers('X-Auth-Client': connection['client_id'],
                'X-Auth-Token': connection['access_token'])
      end
    },
    base_uri: lambda do |_connection|
      'https://api.bigcommerce.com'
    end
  },
  test: lambda do |connection|
    get("/stores/#{connection['store_hash']}/v3/catalog/summary")
  end,

  methods: {
    order_search_schema: lambda do |_input|
      [
        { name: 'min_id', type: 'integer',
          sticky: true,
          label: 'Minimum order ID' },
        { name: 'max_id',
          type: 'integer',
          sticky: true,
          label: 'Maximum order ID' },
        { name: 'min_total', type: 'number',
          sticky: true,
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          label: 'Minimum order total',
          hint: 'The minimum order total in float format. eg. 12.50' },
        { name: 'max_total', type: 'number',
          sticky: true,
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The maximum order total in float format. eg. 12.50' },
        { name: 'customer_id',
          type: 'integer',
          sticky: true },
        { name: 'email', sticky: true, label: 'Customer email' },
        { name: 'status_id', label: 'Order status ID',
          sticky: true,
          hint: 'The staus ID of the order. You can get the status id from the /orders endpoints.' },
        { name: 'cart_id',
          sticky: true,
          label: 'Order card ID' },
        { name: 'payment_method',
          control_type: 'select',
          pick_list: 'payment_methods',
          toggle_hint: 'Select payment method',
          toggle_field: {
            name: 'payment_method',
            label: 'Payment method',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'The payment method for this order. Can be one of the following: ' \
            '`Manual`, `Credit Card`, `cash`, `Test Payment Gateway`, etc.'
          } },
        { name: 'min_date_created',
          type: 'date_time',
          label: 'Order created from date',
          hint: 'Minimum date the order was created in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00' },
        { name: 'max_date_created',
          type: 'date_time',
          label: 'Order created to date',
          hint: 'Maximum date the order was created in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00' },
        { name: 'max_date_modified',
          type: 'date_time',
          label: 'Order modified to date',
          hint: 'Maximum date the order was modified in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00' },
        { name: 'page', type: 'integer', hint: 'The page to return in the response. Default page 1.' },
        { name: 'limit',
          type: 'integer',
          hint: 'Number of results to return. default value is 50. Minimum value 1, Maximum value 250.' },
        { name: 'sort', label: 'Sort orders',
          hint: 'Direction to sort orders asc or desc. Ex. sort=date_created:desc' },
        { name: 'is_deleted', label: 'Include deleted or archived orders?',
          type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'is_deleted',
            label: 'Include deleted or archived orders?',
            type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } }
      ]
    end,

    order_create_schema: lambda do |_input|
      [
        { name: 'products',
          label: 'Products',
          type: 'object',
          optional: false,
          hint: 'Provide any of <b>Standard Products</b> or </b>Custom products</b>',
          properties: [
            { name: 'products', type: 'array', of: 'object',
              label: 'Standard products',
              sticky: true,
              properties: call('product_upsert_schema', '').
                required('product_id', 'product_options', 'quantity') },
            { name: 'custom_products', type: 'array', of: 'object',
              sticky: true,
              properties: call('custom_product_upsert_schema', '').
                required('name', 'quantity', 'price_ex_tax', 'price_inc_tax') }
          ] },
        { name: 'billing_address',
          type: 'object',
          optional: false,
          hint: 'Required to create an order.',
          properties: call('billing_address', '') },
        { name: 'shipping_address',
          type: 'object',
          optional: true,
          properties: call('shipping_address', '') }
      ].concat(call('order_schema', '').
        only('customer_id', 'status_id', 'subtotal_ex_tax', 'subtotal_inc_tax', 'base_shipping_cost',
             'shipping_cost_ex_tax', 'shipping_cost_inc_tax', 'base_handling_cost', 'handling_cost_ex_tax',
             'handling_cost_inc_tax', 'base_wrapping_cost', 'wrapping_cost_ex_tax', 'wrapping_cost_inc_tax',
             'total_ex_tax', 'total_inc_tax', 'items_total', 'items_shipped', 'payment_method', 'payment_provider_id',
             'refunded_amount', 'order_is_digital', 'gift_certificate_amount', 'ip_address', 'geoip_country',
             'geoip_country_iso2', 'staff_notes', 'customer_message', 'discount_amount', 'is_deleted',
             'is_email_opt_in',
             'credit_card_type', 'ebay_order_id', 'external_source', 'external_id', 'external_merchant_id',
             'channel_id', 'tax_provider_id', 'date_created'))
    end,

    order_update_schema: lambda do |_input|
      [
        { name: 'order_id', type: 'integer', optional: false, hint: 'ID of the order' },
        { name: 'products',
          label: 'Products',
          type: 'object',
          optional: false,
          hint: 'Provide any of <b>Standard Products</b> or </b>Custom products</b>',
          properties: [
            { name: 'products', type: 'array', of: 'object',
              label: 'Standard products',
              sticky: true,
              properties: call('product_upsert_schema', '').
                required('product_id', 'product_options', 'quantity') },
            { name: 'custom_products', type: 'array', of: 'object',
              sticky: true,
              properties: call('custom_product_upsert_schema', '').
                required('name', 'quantity', 'price_ex_tax', 'price_inc_tax') }
          ] },
        { name: 'billing_address',
          type: 'object',
          optional: true,
          hint: 'Required to create an order.',
          properties: call('billing_address', '') },
        { name: 'shipping_address',
          type: 'object',
          optional: true,
          stikcy: true,
          properties: call('shipping_address', '') }
      ].concat(call('order_schema', '').
        only('customer_id', 'status_id', 'subtotal_ex_tax', 'subtotal_inc_tax',
             'base_shipping_cost', 'shipping_cost_ex_tax', 'shipping_cost_inc_tax',
             'base_handling_cost', 'handling_cost_ex_tax', 'handling_cost_inc_tax',
             'base_wrapping_cost', 'wrapping_cost_ex_tax', 'wrapping_cost_inc_tax',
             'total_ex_tax', 'total_inc_tax', 'items_total', 'items_shipped',
             'payment_method', 'payment_provider_id', 'refunded_amount', 'order_is_digital',
             'gift_certificate_amount', 'ip_address', 'geoip_country', 'geoip_country_iso2',
             'staff_notes', 'customer_message', 'discount_amount', 'is_deleted', 'is_email_opt_in',
             'credit_card_type', 'ebay_order_id', 'external_source', 'external_id', 'external_merchant_id',
             'channel_id', 'tax_provider_id', 'date_created'))
    end,

    order_get_schema: lambda do |_input|
      [
        { name: 'id', label: 'Order ID',
          type: 'integer', optional: false }
      ]
    end,

    order_schema: lambda do |_input|
      [
        { name: 'id', type: 'integer', control_type: 'number',
          sticky: true,
          hint: 'The ID of the order.' },
        { name: 'customer_id', type: 'integer',
          sticky: true,
          hint: 'The ID of the customer placing the order; or 0 if it was a guest order.' },
        { name: 'date_created', type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          sticky: true,
          hint: 'The date this order was created. If not specified, will default to the current' \
          ' time. The date should be in RFC 2822 format, e.g.: Tue, 20 Nov 2012 00:00:00 +0000' },
        { name: 'date_modified', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          sticky: true,
          hint: 'A read-only value representing the last modification of the order. Do not ' \
          'attempt to modify or set this value in a POST or PUT operation. RFC-2822' },
        { name: 'date_shipped', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          sticky: true,
          hint: 'A read-only value representing the date of shipment. Do not attempt to modify ' \
          'or set this value in a POST or PUT operation. RFC-2822' },
        { name: 'status_id', type: 'integer', hint: 'The status ID of the order.' },
        { name: 'cart_id',
          sticky: true,
          hint: 'The cart ID from which this order originated, if applicable. Correlates with the Cart API.' \
          'e.g. a8458391-ef68-4fe5-9ec1-442e6a767364' },
        {
          name: 'status',
          sticky: true,
          label: 'Order Status',
          control_type: 'select',
          pick_list: 'order_status_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'status',
            label: 'Order Status',
            type: :string,
            control_type: 'text',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'The status will include one of the values defined under Order Statuses.' \
            "click<a href='https://developer.bigcommerce.com/api-reference/store-management/" \
            "orders/models/orderstatuses' target='_blank'>here</a> for allowed values."
          }
        },
        { name: 'custom_status',
          sticky: true,
          hint: 'Contains the same value as the Order Statuses object\'s' \
          ' `custom_label` property.' },
        { name: 'subtotal_ex_tax', type: 'number',
          label: 'Subtotal excluding tax',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          sticky: true,
          hint: 'Override value for subtotal excluding tax. If specified, the field ' \
          '`subtotal_inc_tax` is also required.' },
        { name: 'subtotal_inc_tax', type: 'number',
          label: 'Subtotal including tax',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          sticky: true,
          hint: 'Override value for subtotal including tax. If specified, the field' \
          ' `subtotal_ex_tax` is also required.' },
        { name: 'subtotal_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'base_shipping_cost', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of the base shipping cost.' },
        { name: 'shipping_cost_ex_tax', type: 'number',
          label: 'Shipping cost(excluding tax)',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of shipping cost, excluding tax.' },
        { name: 'shipping_cost_inc_tax', type: 'number',
          label: 'Shipping cost(including tax)',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of shipping cost, including tax.' },
        { name: 'shipping_cost_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'shipping_cost_tax_class_id',
          type: 'integer',
          hint: 'Shipping-cost tax class. A read-only value. (NOTE: Value ignored ' \
          'if automatic tax is enabled on the store.)' },
        { name: 'base_handling_cost', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of the base handling cost.' },
        { name: 'handling_cost_ex_tax',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of the handling cost, excluding tax. ' },
        { name: 'handling_cost_inc_tax',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of the handling cost, including tax.' },
        { name: 'handling_cost_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'handling_cost_tax_class_id', type: 'integer',
          control_type: 'number' },
        { name: 'base_wrapping_cost', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of the base wrapping cost.' },
        { name: 'wrapping_cost_ex_tax', type: 'number',
          hint: 'The value of the wrapping cost, excluding tax.' },
        { name: 'wrapping_cost_inc_tax',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The value of the wrapping cost, including tax.' },
        { name: 'wrapping_cost_tax',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          type: 'number' },
        { name: 'wrapping_cost_tax_class_id',
          type: 'integer',
          hint: 'NOTE: Value ignored if automatic tax is enabled on the store.' },
        { name: 'total_ex_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Override value for the total, excluding tax. If specified, the field' \
          ' `total_inc_tax` is also required.' },
        { name: 'total_inc_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Override value for the total, including tax. If specified, the' \
          ' field `total_ex_tax` is also required.' },
        { name: 'total_tax', type: 'number',
          sticky: true },
        { name: 'items_total', type: 'number',
          sticky: true,
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The total number of items in the order.' },
        { name: 'items_shipped', type: 'number',
          sticky: true,
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The number of items that have been shipped.' },
        { name: 'payment_method',
          sticky: true,
          control_type: 'select',
          pick_list: 'payment_methods',
          toggle_hint: 'Select payment method',
          toggle_field: {
            name: 'payment_method',
            label: 'Payment method',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'The payment method for this order. Can be one of the following: ' \
            '`Manual`, `Credit Card`, `cash`, `Test Payment Gateway`, etc.'
          },
          hint: 'The payment method for this order. Can be one of the following: ' \
          '`Manual`, `Credit Card`, `cash`, `Test Payment Gateway`, etc.' },
        { name: 'payment_provider_id',
          sticky: true,
          hint: 'The external Transaction ID/Payment ID within this order\'s payment' \
          ' provider (if a payment provider was used).' },
        { name: 'payment_status' },
        { name: 'refunded_amount', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The amount refunded from this transaction.' },
        { name: 'order_is_digital', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether this is an order for digital products.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'order_is_digital',
                type: :boolean,
                label: 'Order is digital',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether this is an order for digital products. ' \
                'Allowed values are true or false' } },
        { name: 'store_credit_amount', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Represents the store credit that the shopper has redeemed on this individual order.' },
        { name: 'gift_certificate_amount', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'ip_address', hint: 'IP Address of the customer, if known.' },
        { name: 'geoip_country',
          hint: 'The full name of the country where the customer made the purchase, based on the IP.' },
        { name: 'geoip_country_iso2',
          hint: 'The country where the customer made the purchase, in ISO2 format, based on the IP.' },
        { name: 'currency_id', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The ID of the currency being used in this transaction.' },
        { name: 'currency_code',
          hint: 'The currency code of the currency being used in this transaction.' },
        { name: 'currency_exchange_rate', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'default_currency_id', type: 'integer' },
        { name: 'default_currency_code',
          hint: 'The currency code of the default currency for this type of transaction. ' },
        { name: 'staff_notes',
          hint: 'Any additional notes for staff.' },
        { name: 'customer_message',
          hint: 'Message that the customer entered -o the `Order Comments` box during checkout.' },
        { name: 'discount_amount', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Amount of discount for this transaction.' },
        { name: 'coupon_discount', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'shipping_address_count', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The number of shipping addresses associated with this transaction.' },
        { name: 'is_deleted',
          type: 'boolean',
          label: 'Deleted?',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Indicates whether the order was deleted (archived). Set to to true, to archive an order.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_deleted',
                type: :boolean,

                control_type: 'text',
                label: 'Deleted?',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
        { name: 'is_email_opt_in', type: 'boolean',
          control_type: 'checkbox',
          label: 'Email opt in?',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_email_opt_in',
                type: :boolean,
                optional: true,
                control_type: 'text',
                label: 'Email opt in?',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
        { name: 'credit_card_type', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'ebay_order_id',
          hint: 'If the order was placed through eBay, the eBay order number will' \
          ' be included. Otherwise, the value will be `0`.' },
        { name: 'billing_address', type: 'object', properties: call('billing_address', '') },
        { name: 'shipping_addresses', type: 'object', properties: [
          { name: 'url' },
          { name: 'resource', type: 'integer' }
        ] },
        { name: 'order_source',
          hint: 'Orders submitted via the store\'s website will include a `www` value.' \
          ' Orders submitted via the API will be set to `external`.' },
        { name: 'external_source',
          hint: 'For orders submitted or modified via the API, you can optionally' \
          ' pass in a value identifying the system used to generate the order. For ' \
          'example: `POS`. Otherwise, the value will be null.' },
        { name: 'products', type: 'object', properties: [
          { name: 'url' },
          { name: 'resource', type: 'integer' }
        ] },
        { name: 'coupons', type: 'object', properties: [
          { name: 'url' },
          { name: 'resource', type: 'integer' }
        ] },
        { name: 'external_id',
          hint: '"ID of the order in another system. For example, the Amazon Order ID' \
          ' if this is an Amazon order. The field \'external_id\' cannot be written to.' \
          ' Please remove it from your request before trying again. It can not be overwritten once set.' },
        { name: 'external_merchant_id', type: 'integer', control_type: 'number',
          hint: 'Id of the external merchant.' },
        { name: 'channel_id',
          type: 'integer',
          hint: 'Shows where the order originated. The channel_id will default to 1.' },
        { name: 'tax_provider_id',
          hint: 'BasicTaxProvider - Tax is set to manual. </br>AvaTaxProvider - This is for when the tax ' \
          'provider has been set to automatic and the order was NOT created by the API. Used for' \
          ' Avalara. </br>" " (blank) - When the tax provider is unknown.</br> This includes legacy orders ' \
          'and orders previously created via API. This can be set when creating an order.' }
      ]
    end,

    billing_address: lambda do |_input|
      [
        { name: 'first_name',
          sticky: true,
          hint: 'e.g. Jane' },
        { name: 'last_name', sticky: true, hint: 'e.g. Doe' },
        { name: 'company', sticky: true, hint: 'e.g. BigCommerce' },
        { name: 'street_1', sticky: true, label: 'Address one', hint: '123 Main Street' },
        { name: 'street_2', sticky: true },
        { name: 'city', sticky: true, hint: 'e.g. Austin' },
        { name: 'state', sticky: true, hint: 'e.g. TX' },
        { name: 'zip', sticky: true, hint: 'e.g. 12345' },
        { name: 'country', sticky: true, hint: 'e.g. United States' },
        { name: 'country_iso2', sticky: true, hint: 'e.g. US' },
        { name: 'phone', sticky: true },
        { name: 'email', sticky: true, hint: 'e.g. janedoe@email.com' },
        { name: 'form_fields', type: 'array', of: 'object',
          properties: call('form_fields', '') }
      ]
    end,

    shipping_address: lambda do |_input|
      [
        { name: 'first_name',
          sticky: true,
          hint: 'e.g. Jane' },
        { name: 'last_name', sticky: true, hint: 'e.g. Doe' },
        { name: 'company', sticky: true, hint: 'e.g. BigCommerce' },
        { name: 'street_1', sticky: true, label: 'Address one', hint: '123 Main Street' },
        { name: 'street_2', sticky: true },
        { name: 'city', sticky: true, hint: 'e.g. Austin' },
        { name: 'state', sticky: true, hint: 'e.g. TX' },
        { name: 'zip', sticky: true, hint: 'e.g. 12345' },
        { name: 'country', sticky: true, hint: 'e.g. United States' },
        { name: 'country_iso2', sticky: true, hint: 'e.g. US' },
        { name: 'phone', sticky: true },
        { name: 'email', sticky: true, hint: 'e.g. janedoe@email.com' },
        { name: 'form_fields', type: 'array', of: 'object',
          properties: call('form_fields', '') }
      ]
    end,

    custom_product: lambda do |_input|
      [
        { name: 'name' },
        { name: 'quantity', type: 'number' },
        { name: 'price_ex_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'price_inc_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'sku', label: 'SKU' },
        { name: 'upc', label: 'UPC' }
      ]
    end,

    form_fields: lambda do |_input|
      [{ name: 'name' }, { name: 'value' }]
    end,

    coupon_resource: lambda do |_input|
      [{ name: 'url' }, { name: 'resource' }]
    end,

    order_coupons: lambda do |_input|
      [
        { name: 'id', label: 'Coupons code(Numeric)', type: 'integer',
          hint: 'Numeric ID of the coupon code.' },
        { name: 'coupon_id', type: 'integer', hint: 'Numeric ID of the associated coupon.' },
        { name: 'order_id', type: 'integer', hint: 'Numeric ID of the associated order.' },
        { name: 'code', label: 'Coupons code(string)', hint: 'Coupon code, as a string.' },
        { name: 'amount' },
        { name: 'type', control_type: 'select', pick_list: 'order_coupon_types',
          toggle_hint: 'Select coupon type',
          toggle_field: {
            name: 'type',
            label: 'Coupon type',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: 0,1,2,3,4. type 0: per_item_discount type 1: ' \
            'percentage_discount type 2: per_total_discount type 3: shipping_discount' \
            ' type 4: free_shipping'
          } },
        { name: 'discount', hint: 'The amount off the order the discount is worth.' }
      ]
    end,

    product_upsert_schema: lambda do |_input|
      [
        { name: 'product_id', type: 'integer' },
        { name: 'quantity', type: 'integer' },
        { name: 'price_inc_tax', label: 'Price including tax',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'price_ex_tax', label: 'Price excluding tax',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'upc', label: 'UPC' },
        { name: 'variant_id', label: 'Products variant_id' },
        { name: 'product_options', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'value' }
          ] }
      ]
    end,

    custom_product_upsert_schema: lambda do |_input|
      [
        { name: 'name' },
        { name: 'quantity', type: 'integer' },
        { name: 'price_ex_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'price_inc_tax', type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion' },
        { name: 'sku', label: 'SKU' },
        { name: 'upc', label: 'UPC' }
      ]
    end,

    order_shipment_create_schema: lambda do |_input|
      call('order_shipment_schema', '').
        only('order_id', 'order_address_id', 'tracking_number', 'shipping_method',
             'shipping_provider', 'tracking_carrier', 'comments', 'items').
        required('order_id', 'order_address_id', 'items')
    end,

    order_shipment_update_schema: lambda do |_input|
      call('order_shipment_schema', '').
        only('id', 'order_id', 'order_address_id', 'tracking_number', 'shipping_method',
             'shipping_provider', 'tracking_carrier', 'comments').
        required('id', 'order_id', 'order_address_id')
    end,

    order_shipment_schema: lambda do |_input|
      [
        { name: 'id', label: 'Order shipment ID' },
        { name: 'order_id', hint: 'ID of the order' },
        { name: 'customer_id' },
        { name: 'date_created', type: 'date_time' },
        { name: 'order_address_id',
          type: 'integer', control_type: 'number',
          hint: 'ID of the associated order address.',
          sticky: true },
        {
          name: 'tracking_number',
          sticky: true,
          hint: 'Tracking number of the shipment.'
        },
        {
          name: 'shipping_method',
          sticky: true,
          hint: 'Extra detail to describe the shipment, with values like: Standard,' \
          ' My Custom Shipping Method Name, etc. Can also be used for live quotes from' \
          ' some shipping providers.'
        },
        {
          name: 'shipping_provider',
          optional: true,
          label: 'Shipping provider',
          control_type: 'select',
          pick_list: 'shipping_provider_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'shipping_provider',
            label: 'Shipping provider',
            type: :string,
            control_type: 'text',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: auspost, canadapost, endicia, usps,
            fedex, royalmail, ups, upsready, upsonline, shipperhq'
          },
          hint: 'Enum of the BigCommerce shipping-carrier integration/module. (Note: This' \
          ' property should be included in a POST request to create a shipment object. If it' \
          ' is omitted from the request, the property’s value will default to custom, and no' \
          ' tracking link will be generated in the email. To avoid this behavior, you can pass ' \
          'the property as an empty string.)'
        },
        {
          name: 'tracking_carrier',
          sticky: true,
          label: 'Tracking carrier',
          control_type: 'select',
          pick_list: 'tracking_carrier_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'tracking_carrier',
            label: 'Tracking carrier',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: auspost, canadapost, endicia, usps,
            fedex, royalmail, ups, upsready, upsonline, shipperhq'
          },
          hint: 'Optional, but if you include it, its value must refer/map to the same carrier' \
          ' service as the shipping_provider value.'
        },
        { name: 'comments', hint: 'Comments the shipper wishes to add.' },
        { name: 'items', type: 'array', of: 'object',
          properties: [
            { name: 'order_product_id', optional: false },
            { name: 'product_id' },
            { name: 'quantity', optional: false }
          ],
          hint: 'The items in the shipment. This has the following members, all integer:' \
          ' order_product_id (required), quantity (required), product_id (read-only). A ' \
          'sample items value might be: [ {“order_product_id”:16,“product_id”: 0,“quantity”:2} ]' },

        { name: 'billing_address', type: 'object', properties: call('billing_address', '') },
        { name: 'shipping_address',
          type: 'object',
          optional: false,
          hint: 'Required to create an order.',
          properties: call('shipping_address', '') }
      ]
    end,

    order_shipping_address_get_schema: lambda do |_input|
      [
        { name: 'order_id', label: 'Order ID',
          type: 'integer', optional: false },
        { name: 'id', label: 'Shipment address ID',
          type: 'integer', optional: false }
      ]
    end,

    order_shipping_address_schema: lambda do |_input|
      [
        { name: 'id', label: 'Shipping address ID' },
        { name: 'order_id', hint: 'ID of the order' }
      ].concat(call('shipping_address', ''))
    end,

    get_order_shipping_address_execute: lambda do |input|
      get("/stores/#{input.delete('store_hash')}/v2/orders/#{input['order_id']}/shipping_addresses/#{input['id']}").
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    create_order_execute: lambda do |input|
      store_hash = input.delete('store_hash')
      products = input.delete('products')
      payload =
        input&.merge('products' => (products['products'] || []) + (products['custom_products'] || []))
      post("/stores/#{store_hash}/v2/orders",
           payload.except('object', 'store_hash')).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    update_order_execute: lambda do |input|
      store_hash = input.delete('store_hash')
      order_id = input.delete('order_id')
      products = input.delete('products')
      payload =
        input&.merge('products' => (products['products'] || []) + (products['custom_products'] || []))
      put("/stores/#{store_hash}/v2/orders/#{order_id}", payload).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    get_order_execute: lambda do |input|
      get("/stores/#{input['store_hash']}/v2/orders/#{input['id']}").
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    search_order_execute: lambda do |input|
      get("/stores/#{input.delete('store_hash')}/v2/orders", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    create_order_shipment_execute: lambda do |input|
      post("/stores/#{input.delete('store_hash')}/v2/orders/#{input['order_id']}/shipments").
        payload(input.except('order_id')).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    update_order_shipment_execute: lambda do |input|
      put("/stores/#{input.delete('store_hash')}/v2/orders/#{input['order_id']}/shipments/#{input['id']}").
        payload(input.except('order_id', 'id')).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    sample_output: lambda do |input|
      call("search_#{input['object']}_execute",
           { 'store_hash' => input['store_hash'], limit: 1 })&.[](0)
    end,

    order_product_search_schema: lambda do |_input|
      [
        { name: 'order_id', optional: false },
        { name: 'page', type: 'integer', sticky: true,
          hint: 'The page to return in the response.' },
        { name: 'limit', type: 'integer', sticky: true,
          hint: 'Number of results to return in response' }
      ]
    end,

    order_product_get_schema: lambda do |_input|
      [
        { name: 'order_id', label: "Order ID",
          type: 'integer', optional: false },
        { name: 'id', label: "Product ID",
          type: 'integer', optional: false }
      ]
    end,

    order_product_schema: lambda do |_input|
      [
        { name: 'id', type: 'integer', label: 'Order product ID',
          hint: 'Numeric ID of this product within this order.' },
        { name: 'order_id', type: 'integer',
          label: 'Order ID',
          hint: 'Numeric ID of the associated order. e.g. 120' },
        { name: 'product_id', type: 'integer',
          hint: 'Numeric ID of the product. e.g. 20' },
        { name: 'order_address_id', type: 'integer',
          hint: 'Numeric ID of the associated order address.' },
        { name: 'name', label: 'Product name' },
        { name: 'sku', label: 'SKU', hint: 'User-defined product code/stock keeping unit (SKU).' },
        { name: 'type', control_type: 'select', pick_list: 'product_types',
          toggle_hint: 'Select product type',
          toggle_field: {
            name: 'type',
            label: 'Product type',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: physical or digital'
          } },
        { name: 'base_price', type: 'number' },
        { name: 'price_ex_tax', type: 'number', label: 'Product’s price excluding tax' },
        { name: 'price_inc_tax', type: 'number', label: 'Product’s price including tax' },
        { name: 'price_tax', type: 'number',
          hint: 'Amount of tax applied to a single product. \n\nPrice tax is calculated ' \
          'as:\n`price_tax = price_inc_tax - price_ex_tax`' },
        { name: 'base_total', type: 'number', label: 'Total base price' },
        { name: 'total_ex_tax', type: 'number', label: 'Total base price excluding tax' },
        { name: 'total_inc_tax', type: 'number', label: 'Total base price including tax' },
        { name: 'total_tax', type: 'number', label: 'Total tax applied to products' },
        { name: 'quantity', type: 'integer', hint: 'Quantity of the product ordered' },
        { name: 'base_cost_price', type: 'number', label: 'products cost price' },
        { name: 'cost_price_inc_tax', type: 'number', label: 'Products cost price including tax' },
        { name: 'cost_price_ex_tax', type: 'number', hint: 'Products cost price excluding tax' },
        { name: 'weight', type: 'number' },
        { name: 'cost_price_tax', type: 'number', label: 'Tax applied to the product’s cost price.' },
        { name: 'is_refunded', type: 'boolean', control_type: 'checkbox',
          hint: 'Whether the product has been refunded.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'is_refunded',
            type: 'string',
            control_type: 'text',
            label: 'Is refunded',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'refunded_amount', type: 'number',
          hint: 'The amount refunded from this transaction.' },
        { name: 'return_id', type: 'integer' },
        { name: 'wrapping_name' },
        { name: 'base_wrapping_cost', type: 'number' },
        { name: 'wrapping_cost_ex_tax', type: 'number', label: 'Wrapping cost(excluding tax)' },
        { name: 'wrapping_cost_inc_tax', type: 'number', label: 'Wrapping cost(including tax)' },
        { name: 'wrapping_cost_tax', type: 'number', hint: 'Tax applied to gift-wrapping option.' },
        { name: 'wrapping_message' },
        { name: 'quantity_shipped', type: 'number' },
        { name: 'event_name' },
        { name: 'event_date', type: 'date' },
        { name: 'fixed_shipping_cost', type: 'number' },
        { name: 'ebay_item_id' },
        { name: 'ebay_transaction_id' },
        { name: 'option_set_id', type: 'integer' },
        { name: 'parent_order_product_id' },
        { name: 'is_bundled_product', type: 'boolean', control_type: 'checkbox',
          hint: 'Whether this product is bundled with other products.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'is_bundled_product',
            type: 'boolean',
            label: 'Is bundled product',
            optional: true,
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Whether this product is bundled with other products. Allowed values: true, false'
          } },
        { name: 'bin_picking_number', type: 'integer' },
        { name: 'applied_discounts', type: 'array', of: 'object',
          hint: 'Order Products Applied Discounts',
          properties: [
            { name: 'id', type: 'Coupon ID' },
            { name: 'amount', type: 'number' },
            { name: 'name', label: 'Coupon name' },
            { name: 'code' },
            { name: 'target' }
          ] },
        { name: 'product_options', type: 'array', of: 'object',
          hint: 'Order Products Product Options',
          properties: [
            { name: 'id', type: 'Product options ID' },
            { name: 'option_id', type: 'integer' },
            { name: 'order_product_id', type: 'integer' },
            { name: 'product_option_id', type: 'integer' },
            { name: 'display_name' },
            { name: 'value' },
            { name: 'type' },
            { name: 'name' },
            { name: 'display_style' }
          ] },
        { name: 'external_id',
          hint: 'ID of the order in another system. For example, the Amazon Order ID' \
          ' if this is an Amazon order.' },
        { name: 'upc', label: 'Universal Product Code' },
        { name: 'variant_id', hint: 'The Variant ID is not available for custom products.' }
      ]
    end,

    search_order_product_execute: lambda do |input|
      get("/stores/#{input.delete('store_hash')}/v2/orders/#{input.delete('order_id')}/products", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    get_order_product_execute: lambda do |input|
      get("/stores/#{input.delete('store_hash')}/v2/orders/#{input['order_id']}/products/#{input['id']}").
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    price_list_search_schema: lambda do |_input|
      [
        { name: 'name',
          type: 'string',
          sticky: true,
          label: 'The name of the Price List' },
        { name: 'date_created',
          type: 'date_time',
          label: 'Price List created date',
          hint: 'Price List was created in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00' },
        { name: 'date_modified',
          type: 'date_time',
          label: 'Price List modified date',
          hint: 'Price List was modified in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00' },
        { name: 'page', type: 'integer', hint: 'The page to return in the response. Default page 1.' },
        { name: 'limit', type: 'integer',
          hint: 'Number of results to return. default value is 50. Minimum value 1, Maximum value 250.' },
      ]
    end,

    price_list_create_schema: lambda do |_input|
      [
        { name: 'name', type: 'string',
          sticky: true,
          hint: 'The name of the Price List.'
        },
        { name: 'active', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether or not this Price List and its prices are active.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'active',
                type: :boolean,
                label: 'Active',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether or not this Price List and its prices are active. ' \
                'Allowed values are true or false'
              }
        }
      ]
    end,

    price_list_update_schema: lambda do |_input|
      [
        { name: 'price_list_id', type: 'integer', optional: false, hint: 'ID of the price list' },
        { name: 'name', type: 'string',
          sticky: true,
          hint: 'The name of the Price List.'
        },
        { name: 'active', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether or not this Price List and its prices are active.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'active',
                type: :boolean,
                label: 'Active',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether or not this Price List and its prices are active. ' \
                'Allowed values are true or false'
              }
        }
      ]
    end,

    price_list_schema: lambda do |_input|
      [
          { name: 'id', type: 'integer',
            sticky: true,
            label: 'The ID of the Price List' },
          { name: 'name', type: 'string',
            sticky: true, label: 'The name of the Price List'
          },
          { name: 'active', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            hint: 'Whether or not this Price List and its prices are active.',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'active',
                  type: :boolean,
                  label: 'Active',
                  optional: true,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Whether or not this Price List and its prices are active. ' \
                  'Allowed values are true or false'
                }
          },
          { name: 'date_created',
            type: 'date_time',
            label: 'Price List created date',
            hint: 'Price List was created in RFC-2822 or ISO-8601. e.g. ' \
            '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
            '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00' },
          { name: 'date_modified',
            type: 'date_time',
            label: 'Price List modified date',
            hint: 'Price List was modified in RFC-2822 or ISO-8601. e.g. ' \
            '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
            '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00' }
      ]
    end,

    create_price_list_execute: lambda do |input|
      post("/stores/#{input.delete('store_hash')}/v3/pricelists", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    update_price_list_execute: lambda do |input|
      store_hash = input.delete('store_hash')
      price_list_id = input.delete('price_list_id')
      put("/stores/#{store_hash}/v3/pricelists/#{price_list_id}", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    search_price_list_execute: lambda do |input|
      get("/stores/#{input.delete('store_hash')}/v3/pricelists", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    product_search_schema: lambda do |_input|
      [
        { name: 'name', sticky: true, hint: 'Minimum length: 1, Maximum length: 255' },
        { name: 'sku', label: "SKU",
          hint: 'User defined product code/stock keeping unit (SKU). Minimum length: 1, Maximum length: 255' },
        { name: 'upc', label: "UPC",
          hint: 'The product UPC code, which is used in feeds for shopping comparison sites' \
          'and external channel integrations. Minimum length: 1, Maximum length: 255'
        },
        {
          name: 'price',
          type: 'number', sticky: true,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Price of the product, The price should include or exclude tax, ' \
          'based on the store settings.'
        },
        {
          name: 'weight',
          type: 'number', sticky: true,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Weight of the product, which can be used when calculating shipping costs. ' \
          'This is based on the unit set on the store. minimum: 0, maximum: 9999999999'
        },
        { name: 'condition', control_type: :select, pick_list:
            [
              %w[New New],
              %w[Used Used],
              %w[Refurbished Refurbished]
            ],
          toggle_hint: 'Select condition',
          toggle_field: {
            name: 'condition',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: New, Used, Refurbished'
          }
        },
        { name: 'brand_id',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'A product can be added to an existing brand. minimum: 0, maximum: 9999999999'
        },
        { name: 'date_modified', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'A read-only value representing the last modification of the product. Do not ' \
          'attempt to modify or set this value in a POST or PUT operation. RFC-2822'
        },
        { name: 'is_visible', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint:  'Whether the product should be displayed to customers browsing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_visible',
                type: :boolean,
                label: 'Is visible',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be displayed to customers browsing the store. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_featured', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product should be included in the featured products panel when viewing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_featured',
                type: :boolean,
                optional: true,
                label: 'Is featured',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be included in the featured products panel when viewing the store. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_free_shipping', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product has free shipping.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_free_shipping',
                type: :boolean,
                label: 'Is free shipping',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product has free shipping. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'inventory_level',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Current inventory level of the product. Simple inventory tracking must be enabled' \
          '(See the inventory_tracking field) for this to take any effect. minimum: 0, maximum: 9999999999'
        },
        { name: 'out_of_stock', sticky: true, control_type: :select, pick_list:
            [
              %w[Yes yes],
              %w[No no]
            ],
          toggle_hint: 'Select type',
          toggle_field: {
            name: 'out_of_stock',
            type: :string,
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: yes, no'
          }
        },
        { name: 'type', sticky: true, control_type: :select, pick_list:
            [
              %w[Physical physical],
              %w[Digital digital]
            ],
          toggle_hint: 'Select type',
          toggle_field: {
            name: 'type',
            type: :string,
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: physical, digital'
          }
        },
        { name: 'categories:in', label: 'Categories',
          hint: 'IDs should be comma(,) separated. Ex. 1,2,3' },
        { name: 'keyword', sticky: true },
        { name: 'keyword_context', sticky: true },
        { name: 'availability', control_type: :select, pick_list:
            [
              %w[Available available],
              %w[Disabled disabled],
              %w[Preorder preorder]
            ],
          toggle_hint: 'Select availability',
          toggle_field: {
            name: 'availability',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: available, disabled, preorder'
          }
        },
        { name: 'page', type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
           hint: 'The page to return in the response. Default page 1.' },
        { name: 'limit',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Number of results to return. default value is 50. Minimum value 1, Maximum value 250.' },
        { name: 'direction', label: 'Direction',
          hint: 'Direction to sort orders asc or desc. Ex. sort=date_created:desc' }
      ]
    end,

    product_create_schema: lambda do |_input|
      [
        { name: 'name', sticky: true, optional: false, hint: 'Minimum length: 1, Maximum length: 255' },
        { name: 'type', sticky: true, optional: false, control_type: :select, pick_list:
            [
              %w[Physical physical],
              %w[Digital digital]
            ],
          toggle_hint: 'Select type',
          toggle_field: {
            name: 'type',
            type: :string,
            control_type: 'text',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: physical, digital'
          }
        },
        { name: 'sku',
          hint: 'User defined product code/stock keeping unit (SKU). Minimum length: 1, Maximum length: 255' },
        { name: 'description', sticky: true, optional: false, hint: 'The product description, which can include HTML formatting.' },
        {
          name: 'weight',
          type: 'number', sticky: true, optional: false,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Weight of the product, which can be used when calculating shipping costs. ' \
          'This is based on the unit set on the store. minimum: 0, maximum: 9999999999'
        },
        {
          name: 'width',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Width of the product, which can be used when calculating shipping costs.' \
          ' minimum: 0, maximum: 9999999999'
        },
        {
          name: 'depth',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Depth of the product, which can be used when calculating shipping costs. ' \
          'minimum: 0, maximum: 9999999999'
        },
        {
          name: 'height',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Height of the product, which can be used when calculating shipping costs. ' \
          'minimum: 0, maximum: 9999999999'
        },
        {
          name: 'price',
          type: 'number', sticky: true, optional: false,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Price of the product, The price should include or exclude tax, ' \
          'based on the store settings.'
        },
        {
          name: 'cost_price',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The cost price of the product. Stored for reference only; it is ' \
          'not used or displayed anywhere on the store.'
        },
        {
          name: 'retail_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The retail cost of the product. If entered, the retail cost price' \
          ' will be shown on the product page.'
        },
        {
          name: 'sale_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'If entered, the sale price will be used instead of value in the price' \
          ' field when calculating the product’s cost.'
        },
        { name: 'tax_class_id',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The ID of the tax class applied to the product. (NOTE: Value ' \
          'ignored if automatic tax is enabled.)'
        },
        { name: 'product_tax_code',
          hint: 'Accepts AvaTax System Tax Codes, which identify products and services' \
          'that fall into special sales-tax categories. Minimum length: 1, Maximum length: 255'
        },
        {
          name: 'categories', sticky: true, optional: false,
          type: 'array', of: 'object',
          label: 'Categories',
          properties: [
            { name: 'id', optional: true, type: 'integer',
              hint: 'IDs for the categories. Does not accept more than 1,000 ID values.'
            }
          ]
        },
        { name: 'brand_id',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'A product can be added to an existing brand. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_level',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Current inventory level of the product. Simple inventory tracking must be enabled' \
          '(See the inventory_tracking field) for this to take any effect. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_warning_level',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Inventory warning level for the product. Simple inventory tracking must be enabled.' \
          '(See the inventory_tracking field) for this to take any effect. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_tracking', control_type: :select, pick_list:
            [
              %w[None none],
              %w[Product product],
              %w[Variant variant]
            ],
          toggle_hint: 'Select inventory tracking',
          toggle_field: {
            name: 'inventory_tracking',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: none, product, variant'
          }
        },
        { name: 'fixed_cost_shipping_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'A fixed shipping cost for the product. If defined, this value will be' \
          'used during checkout instead of normal shipping-cost calculation. minimum: 0'
        },
        { name: 'is_free_shipping', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product has free shipping.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_free_shipping',
                type: :boolean,
                label: 'is free shipping',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product has free shipping ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_visible', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint:  'Whether the product should be displayed to customers browsing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_visible',
                type: :boolean,
                label: 'Is visible',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be displayed to customers browsing the store. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_featured', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product should be included in the featured products panel when viewing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_featured',
                type: :boolean,
                optional: true,
                label: 'Is featured',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be included in the featured products panel when viewing the store. ' \
                'Allowed values are true or false'
              }
        },
        {
          name: 'related_products',
          type: 'array', of: 'object',
          label: 'Related products',
          properties: [
            { name: 'id', optional: false, type: 'integer',
              hint: 'An array of IDs for the related products.'
            }
          ]
        },
        { name: 'warranty',
          hint: 'Warranty information displayed on the product page. Can include HTML formatting. Minimum length: 1, Maximum length: 65535'
        },
        { name: 'bin_picking_number',
          hint: 'The BIN picking number for the product. Minimum length: 1, Maximum length: 255'
        },
        { name: 'layout_file',
          hint: 'The layout template file used to render this product category.' \
          'This field is writable only for stores with a Blueprint theme applied. Minimum length: 1, Maximum length: 500'
        },
        { name: 'upc',
          hint: 'The product UPC code, which is used in feeds for shopping comparison sites' \
          'and external channel integrations. Minimum length: 1, Maximum length: 255'
        },
        { name: 'search_keywords',
          hint: 'A comma-separated list of keywords that can be used to locate the product when searching the store.'\
          'Minimum length: 1, Maximum length: 65535'
        },
        { name: 'availability', control_type: :select, pick_list:
            [
              %w[Available available],
              %w[Disabled disabled],
              %w[Preorder preorder]
            ],
          toggle_hint: 'Select availability',
          toggle_field: {
            name: 'availability',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: available, disabled, preorder'
          }
        },
        { name: 'availability_description',
          hint: 'Availability text displayed on the checkout page, under the product title.'\
          'Minimum length: 1, Maximum length: 255'
        },
        { name: 'gift_wrapping_options_type', control_type: :select, pick_list:
            [
              %w[Any any],
              %w[None none],
              %w[List list]
            ],
          toggle_hint: 'Select gift wrapping options type',
          toggle_field: {
            name: 'gift_wrapping_options_type',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: any, none, list'
          }
        },
        {
          name: 'gift_wrapping_options_list',
          type: 'array', of: 'object',
          label: 'Gift wrapping option list',
          properties: [
            { name: 'id', optional: false, type: 'integer',
              hint: 'A list of gift-wrapping option IDs.' }
          ]
        },
        { name: 'sort_order',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Priority to give this product when included in product lists on category pages' \
          'and in search results. minimum: -2147483648, maximum:  2147483647'
        },
        { name: 'condition', control_type: :select, pick_list:
            [
              %w[New New],
              %w[Used Used],
              %w[Refurbished Refurbished]
            ],
          toggle_hint: 'Select condition',
          toggle_field: {
            name: 'condition',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: New, Used, Refurbished'
          }
        },
        { name: 'is_condition_shown', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product condition is shown to the customer on the product page.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_condition_shown',
                type: :boolean,
                optional: true,
                label: 'Is condition shown',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product condition is shown to the customer on the product page. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'order_quantity_minimum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The minimum quantity an order must contain, to be eligible to purchase this product.' \
          'minimum: 0, maximum:  9999999999'
        },
        { name: 'order_quantity_maximum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The maximum quantity an order must contain, to be eligible to purchase this product.' \
          'minimum: 0, maximum:  9999999999'
        },
        { name: 'page_title',
          hint: 'Custom title for the product page. If not defined, the product name will be used as the meta title.' \
          'Minimum length: 0, Maximum length: 255'
        },
        {
          name: 'meta_keywords',
          type: 'array', of: 'object',
          label: 'Meta keywords',
          properties: [{ name: 'keyword', hint: 'A list of gift-wrapping option IDs.' }]
        },
        { name: 'meta_description',
          hint: 'Custom meta description for the product page. Minimum length: 0, Maximum length: 255'
        },
        { name: 'view_count',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The number of times the product has been viewed. minimum: 0, maximum:  9999999999'
        },
        { name: 'preorder_release_date',
          type: 'date_time',
          label: 'Preorder release date',
          hint: 'Preorder release date in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00'
        },
        { name: 'preorder_message',
          hint: 'Custom expected-date message to display on the product page. Minimum length: 1, Maximum length: 255'
        },
        { name: 'is_preorder_only', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'If set to true, the price is hidden.' \
          '(NOTE: To successfully set is_price_hidden to true, the availability value must be disabled.)',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_preorder_only',
                type: :boolean,
                optional: true,
                label: 'Is preorder only',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'If set to true, the price is hidden.' \
                '(NOTE: To successfully set is_price_hidden to true, the availability value must be disabled.) ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_price_hidden', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'If set to true then on the preorder release date the preorder status will automatically be removed.' \
          'If set to false, then on the release date the preorder status will not be removed.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_price_hidden',
                type: :boolean,
                optional: true,
                label: 'Is price hidden',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'If set to true then on the preorder release date the preorder status will automatically be removed.' \
                'If set to false, then on the release date the preorder status will not be removed. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'price_hidden_label',
          hint: ' If is_price_hidden is true, the value of price_hidden_label is displayed instead of the price. Minimum length: 1, Maximum length: 200'
        },
        {
          name: 'custom_url',
          type: 'object',
          label: 'Custom URL',
          properties: [
            { name: 'url', hint: 'Product URL on the storefront.' },
            { name: 'is_customized', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'is_customized',
                    type: :boolean,
                    optional: true,
                    label: 'Is customized',
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value'
                  }
            }
          ]
        },
        { name: 'open_graph_type', control_type: :select, pick_list:
            [
              %w[Product product],
              %w[Album album],
              %w[Book book],
              %w[Drink drink],
              %w[Food food],
              %w[Game game],
              %w[Movie movie],
              %w[Song song],
              %w[TV\ show tv_show]
            ],
          toggle_hint: 'Select open graph type',
          toggle_field: {
            name: 'open_graph_type',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: product, album, book, drink, food, game, movie, song, tv_show'
          }
        },
        { name: 'open_graph_title',
          hint: 'Title of the product, if not specified the product name will be used instead.'
        },
        { name: 'open_graph_description',
          hint: 'Description to use for the product, if not specified then the meta_description will be used instead.'
        },
        { name: 'open_graph_use_meta_description', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether to determine if product description or open graph description is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_meta_description',
                type: :boolean,
                optional: true,
                label: 'Open graph use meta description',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product description or open graph description is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'open_graph_use_product_name', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether  to determine if product name or open graph name is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_product_name',
                type: :boolean,
                optional: true,
                label: 'Open graph use product name',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product name or open graph name is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'open_graph_use_image', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether to determine if product image or open graph image is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_image',
                type: :boolean,
                optional: true,
                label: 'Open graph use image',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product image or open graph image is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'brand_id',
          hint: 'The brand ID of the product.'
        },
        { name: 'gtin',
          hint: 'Global Trade Item Number'
        },
        { name: 'mpn',
          hint: 'Manufacturer Part Number'
        },
        { name: 'reviews_rating_sum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The total rating for the product.'
        },
        { name: 'reviews_count',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The number of times the product has been rated.'
        },
        { name: 'total_sold',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The total quantity of this product sold.'
        },
        { name: 'custom_fields', type: 'array', of: 'object',
          properties: [
            { name: 'name', optional: false, hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'value', optional: false, hint: 'Minimum length: 1, Maximum length: 250' }
          ],
          hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
        },
        { name: 'bulk_pricing_rules', type: 'array', of: 'object',
          properties: [
            { name: 'quantity_min', type: 'integer', optional: false, hint: 'The minimum inclusive quantity of a product. Minimum: 0' },
            { name: 'quantity_max', type: 'integer', optional: false, hint: 'The maximum inclusive quantity of a product. Minimum: 0' },
            { name: 'type', control_type: :select, pick_list:
                [
                  %w[Price price],
                  %w[Precent percent],
                  %w[Fixed fixed]
                ],
              toggle_hint: 'Select type',
              toggle_field: {
                name: 'type',
                type: :string,
                control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: price, percent, fixed'
              }
            },
            { name: 'amount', type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              optional: false, hint: 'The discount can be a fixed dollar amount or a percentage' }
          ],
          hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
        },
        { name: 'variants', type: 'array', of: 'object',
          properties: [
            { name: 'cost_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'sale_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'retail_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'weight',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'width',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'height',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'depth',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'is_free_shipping', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              hint: 'Whether the product has free shipping.',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'is_free_shipping',
                    type: :boolean,
                    label: 'Is free shipping',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Whether the product has free shipping. ' \
                    'Allowed values are true or false'
                  }
            },
            { name: 'fixed_cost_shipping_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'purchasing_disabled', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'purchasing_disabled',
                    type: :boolean,
                    label: 'Purchasing disabled',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false'
                  }
            },
            { name: 'purchasing_disabled_message', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'upc', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'inventory_level', type: 'integer'},
            { name: 'inventory_warning_level', type: 'integer'},
            { name: 'bin_picking_number', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'id', type: 'integer'},
            { name: 'product_id', type: 'integer'},
            { name: 'sku', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'sku_id', type: 'integer'},
            { name: 'option_values', type: 'array', of: 'object',
              properties: [
                { name: 'option_display_name', hint: 'Minimum length: 1, Maximum length: 250' },
                { name: 'label', hint: 'Minimum length: 1, Maximum length: 250' },
                { name: 'id', type: 'integer'},
                { name: 'option_id', type: 'integer'},
              ],
              hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
            }
          ],
          hint: 'The variants of the product.'
        }
      ]
    end,

    product_update_schema: lambda do |_input|
      [
        { name: 'product_id', sticky: true, optional: false,
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'ID of the product.'
        },
        { name: 'name', sticky: true, hint: 'Minimum length: 1, Maximum length: 255' },
        { name: 'type', sticky: true, control_type: :select, pick_list:
            [
              %w[Physical physical],
              %w[Digital digital]
            ],
          toggle_hint: 'Select type',
          toggle_field: {
            name: 'type',
            type: :string,
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: physical, digital'
          }
        },
        { name: 'sku',
          hint: 'User defined product code/stock keeping unit (SKU). Minimum length: 1, Maximum length: 255' },
        { name: 'description', sticky: true, hint: 'The product description, which can include HTML formatting.' },
        {
          name: 'weight',
          type: 'number', sticky: true,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Weight of the product, which can be used when calculating shipping costs. ' \
          'This is based on the unit set on the store. minimum: 0, maximum: 9999999999'
        },
        {
          name: 'width',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Width of the product, which can be used when calculating shipping costs.' \
          ' minimum: 0, maximum: 9999999999'
        },
        {
          name: 'depth',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Depth of the product, which can be used when calculating shipping costs. ' \
          'minimum: 0, maximum: 9999999999'
        },
        {
          name: 'height',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Height of the product, which can be used when calculating shipping costs. ' \
          'minimum: 0, maximum: 9999999999'
        },
        {
          name: 'price',
          type: 'number', sticky: true,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Price of the product, The price should include or exclude tax, ' \
          'based on the store settings.'
        },
        {
          name: 'cost_price',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The cost price of the product. Stored for reference only; it is ' \
          'not used or displayed anywhere on the store.'
        },
        {
          name: 'retail_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The retail cost of the product. If entered, the retail cost price' \
          ' will be shown on the product page.'
        },
        {
          name: 'sale_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'If entered, the sale price will be used instead of value in the price' \
          ' field when calculating the product’s cost.'
        },
        { name: 'tax_class_id',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The ID of the tax class applied to the product. (NOTE: Value ' \
          'ignored if automatic tax is enabled.)'
        },
        { name: 'product_tax_code',
          hint: 'Accepts AvaTax System Tax Codes, which identify products and services' \
          'that fall into special sales-tax categories. Minimum length: 1, Maximum length: 255'
        },
        {
          name: 'categories', sticky: true,
          type: 'array', of: 'object',
          label: 'Categories',
          properties: [
            { name: 'id', optional: true, type: 'integer',
              hint: 'IDs for the categories. Does not accept more than 1,000 ID values.'
            }
          ]
        },
        { name: 'brand_id',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'A product can be added to an existing brand. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_level',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Current inventory level of the product. Simple inventory tracking must be enabled' \
          '(See the inventory_tracking field) for this to take any effect. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_warning_level',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Inventory warning level for the product. Simple inventory tracking must be enabled.' \
          '(See the inventory_tracking field) for this to take any effect. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_tracking', control_type: :select, pick_list:
            [
              %w[None none],
              %w[Product product],
              %w[Variant variant]
            ],
          toggle_hint: 'Select inventory tracking',
          toggle_field: {
            name: 'inventory_tracking',
            type: :string,
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: none, product, variant'
          }
        },
        { name: 'fixed_cost_shipping_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'A fixed shipping cost for the product. If defined, this value will be' \
          'used during checkout instead of normal shipping-cost calculation. minimum: 0'
        },
        { name: 'is_free_shipping', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product has free shipping.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_free_shipping',
                type: :boolean,
                label: 'Is free shipping',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product has free shipping. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_visible', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint:  'Whether the product should be displayed to customers browsing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_visible',
                type: :boolean,
                label: 'Is visible',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be displayed to customers browsing the store. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_featured', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product should be included in the featured products panel when viewing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_featured',
                type: :boolean,
                optional: true,
                label: 'Is featured',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be included in the featured products panel when viewing the store. ' \
                'Allowed values are true or false'
              }
        },
        {
          name: 'related_products',
          type: 'array', of: 'object',
          label: 'Related products',
          properties: [
            { name: 'id', optional: false, type: 'integer',
              hint: 'An array of IDs for the related products.'
            }
          ]
        },
        { name: 'warranty',
          hint: 'Warranty information displayed on the product page. Can include HTML formatting. Minimum length: 1, Maximum length: 65535'
        },
        { name: 'bin_picking_number',
          hint: 'The BIN picking number for the product. Minimum length: 1, Maximum length: 255'
        },
        { name: 'layout_file',
          hint: 'The layout template file used to render this product category.' \
          'This field is writable only for stores with a Blueprint theme applied. Minimum length: 1, Maximum length: 500'
        },
        { name: 'upc',
          hint: 'The product UPC code, which is used in feeds for shopping comparison sites' \
          'and external channel integrations. Minimum length: 1, Maximum length: 255'
        },
        { name: 'search_keywords',
          hint: 'A comma-separated list of keywords that can be used to locate the product when searching the store.'\
          'Minimum length: 1, Maximum length: 65535'
        },
        { name: 'availability', control_type: :select, pick_list:
            [
              %w[Available available],
              %w[Disabled disabled],
              %w[Preorder preorder]
            ],
          toggle_hint: 'Select availability',
          toggle_field: {
            name: 'availability',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: available, disabled, preorder'
          }
        },
        { name: 'availability_description',
          hint: 'Availability text displayed on the checkout page, under the product title.'\
          'Minimum length: 1, Maximum length: 255'
        },
        { name: 'gift_wrapping_options_type', control_type: :select, pick_list:
            [
              %w[Any any],
              %w[None none],
              %w[List list]
            ],
          toggle_hint: 'Select gift wrapping options type',
          toggle_field: {
            name: 'gift_wrapping_options_type',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: any, none, list'
          }
        },
        {
          name: 'gift_wrapping_options_list',
          type: 'array', of: 'object',
          label: 'Gift wrapping option list',
          properties: [
            { name: 'id', optional: false, type: 'integer',
              hint: 'A list of gift-wrapping option IDs.' }
          ]
        },
        { name: 'sort_order',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Priority to give this product when included in product lists on category pages' \
          'and in search results. minimum: -2147483648, maximum:  2147483647'
        },
        { name: 'condition', control_type: :select, pick_list:
            [
              %w[New New],
              %w[Used Used],
              %w[Refurbished Refurbished]
            ],
          toggle_hint: 'Select condition',
          toggle_field: {
            name: 'condition',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: New, Used, Refurbished'
          }
        },
        { name: 'is_condition_shown', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product condition is shown to the customer on the product page.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_condition_shown',
                type: :boolean,
                optional: true,
                label: 'Is condition shown',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product condition is shown to the customer on the product page. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'order_quantity_minimum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The minimum quantity an order must contain, to be eligible to purchase this product.' \
          'minimum: 0, maximum:  9999999999'
        },
        { name: 'order_quantity_maximum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The maximum quantity an order must contain, to be eligible to purchase this product.' \
          'minimum: 0, maximum:  9999999999'
        },
        { name: 'page_title',
          hint: 'Custom title for the product page. If not defined, the product name will be used as the meta title.' \
          'Minimum length: 0, Maximum length: 255'
        },
        {
          name: 'meta_keywords',
          type: 'array', of: 'object',
          label: 'Meta keywords',
          properties: [{ name: 'keyword', hint: 'A list of gift-wrapping option IDs.' }]
        },
        { name: 'meta_description',
          hint: 'Custom meta description for the product page. Minimum length: 0, Maximum length: 255'
        },
        { name: 'view_count',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The number of times the product has been viewed. minimum: 0, maximum:  9999999999'
        },
        { name: 'preorder_release_date',
          type: 'date_time',
          label: 'Preorder release date',
          hint: 'Preorder release date in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00'
        },
        { name: 'preorder_message',
          hint: 'Custom expected-date message to display on the product page. Minimum length: 1, Maximum length: 255'
        },
        { name: 'is_preorder_only', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'If set to true, the price is hidden.' \
          '(NOTE: To successfully set is_price_hidden to true, the availability value must be disabled.)',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_preorder_only',
                type: :boolean,
                optional: true,
                label: 'Is preorder only',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'If set to true, the price is hidden.' \
                '(NOTE: To successfully set is_price_hidden to true, the availability value must be disabled.) ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_price_hidden', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'If set to true then on the preorder release date the preorder status will automatically be removed.' \
          'If set to false, then on the release date the preorder status will not be removed.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_price_hidden',
                type: :boolean,
                optional: true,
                label: 'Is price hidden',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'If set to true then on the preorder release date the preorder status will automatically be removed.' \
                'If set to false, then on the release date the preorder status will not be removed. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'price_hidden_label',
          hint: ' If is_price_hidden is true, the value of price_hidden_label is displayed instead of the price. Minimum length: 1, Maximum length: 200'
        },
        {
          name: 'custom_url',
          type: 'object',
          label: 'Custom URL',
          properties: [
            { name: 'url', hint: 'Product URL on the storefront.' },
            { name: 'is_customized', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'is_customized',
                    type: :boolean,
                    optional: true,
                    label: 'Is customized',
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value'
                  }
            }
          ]
        },
        { name: 'open_graph_type', control_type: :select, pick_list:
            [
              %w[Product product],
              %w[Album album],
              %w[Book book],
              %w[Drink drink],
              %w[Food food],
              %w[Game game],
              %w[Movie movie],
              %w[Song song],
              %w[TV\ show tv_show]
            ],
          toggle_hint: 'Select open graph type',
          toggle_field: {
            name: 'open_graph_type',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: product, album, book, drink, food, game, movie, song, tv_show'
          }
        },
        { name: 'open_graph_title',
          hint: 'Title of the product, if not specified the product name will be used instead.'
        },
        { name: 'open_graph_description',
          hint: 'Description to use for the product, if not specified then the meta_description will be used instead.'
        },
        { name: 'open_graph_use_meta_description', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether to determine if product description or open graph description is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_meta_description',
                type: :boolean,
                optional: true,
                label: 'Open graph use meta description',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product description or open graph description is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'open_graph_use_product_name', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether  to determine if product name or open graph name is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_product_name',
                type: :boolean,
                optional: true,
                label: 'Open graph use product name',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product name or open graph name is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'open_graph_use_image', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether to determine if product image or open graph image is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_image',
                type: :boolean,
                optional: true,
                label: 'Open graph use image',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product image or open graph image is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'brand_id',
          hint: 'The brand ID of the product.'
        },
        { name: 'gtin',
          hint: 'Global Trade Item Number'
        },
        { name: 'mpn',
          hint: 'Manufacturer Part Number'
        },
        { name: 'reviews_rating_sum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The total rating for the product.'
        },
        { name: 'reviews_count',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The number of times the product has been rated.'
        },
        { name: 'total_sold',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The total quantity of this product sold.'
        },
        { name: 'custom_fields', type: 'array', of: 'object',
          properties: [
            { name: 'name', optional: false, hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'value', optional: false, hint: 'Minimum length: 1, Maximum length: 250' }
          ],
          hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
        },
        { name: 'bulk_pricing_rules', type: 'array', of: 'object',
          properties: [
            { name: 'quantity_min', type: 'integer', optional: false, hint: 'The minimum inclusive quantity of a product. Minimum: 0' },
            { name: 'quantity_max', type: 'integer', optional: false, hint: 'The maximum inclusive quantity of a product. Minimum: 0' },
            { name: 'type', control_type: :select, pick_list:
                [
                  %w[Price price],
                  %w[Precent percent],
                  %w[Fixed fixed]
                ],
              toggle_hint: 'Select type',
              toggle_field: {
                name: 'type',
                type: :string,
                control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: price, percent, fixed'
              }
            },
            { name: 'amount', type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              optional: false, hint: 'The discount can be a fixed dollar amount or a percentage' }
          ],
          hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
        },
        { name: 'variants', type: 'array', of: 'object',
          properties: [
            { name: 'cost_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'sale_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'retail_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'weight',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'width',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'height',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'depth',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'is_free_shipping', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              hint: 'Whether the product has free shipping.',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'is_free_shipping',
                    type: :boolean,
                    label: 'Is free shipping',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Whether the product has free shipping. ' \
                    'Allowed values are true or false'
                  }
            },
            { name: 'fixed_cost_shipping_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'purchasing_disabled', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'purchasing_disabled',
                    type: :boolean,
                    label: 'Purchasing disabled',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false'
                  }
            },
            { name: 'purchasing_disabled_message', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'upc', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'inventory_level', type: 'integer'},
            { name: 'inventory_warning_level', type: 'integer'},
            { name: 'bin_picking_number', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'id', type: 'integer'},
            { name: 'product_id', type: 'integer'},
            { name: 'sku', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'sku_id', type: 'integer'},
            { name: 'option_values', type: 'array', of: 'object',
              properties: [
                { name: 'option_display_name', hint: 'Minimum length: 1, Maximum length: 250' },
                { name: 'label', hint: 'Minimum length: 1, Maximum length: 250' },
                { name: 'id', type: 'integer'},
                { name: 'option_id', type: 'integer'},
              ],
              hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
            }
          ],
          hint: 'The variants of the product.'
        }
      ]
    end,

    product_schema: lambda do |_input|
      [
        { name: 'id', sticky: true, optional: false,
          type: 'integer',
          hint: 'ID of the product.'
        },
        { name: 'name', sticky: true, optional: false, hint: 'Minimum length: 1, Maximum length: 255' },
        { name: 'type', sticky: true, optional: false, control_type: :select, pick_list:
            [
              %w[Physical physical],
              %w[Digital digital]
            ],
          toggle_hint: 'Select type',
          toggle_field: {
            name: 'type',
            type: :string,
            control_type: 'text',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: physical, digital'
          }
        },
        { name: 'sku',
          hint: 'User defined product code/stock keeping unit (SKU). Minimum length: 1, Maximum length: 255' },
        { name: 'description', sticky: true, optional: false, hint: 'The product description, which can include HTML formatting.' },
        {
          name: 'weight',
          type: 'number', sticky: true, optional: false,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Weight of the product, which can be used when calculating shipping costs. ' \
          'This is based on the unit set on the store. minimum: 0, maximum: 9999999999'
        },
        {
          name: 'width',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Width of the product, which can be used when calculating shipping costs.' \
          ' minimum: 0, maximum: 9999999999'
        },
        {
          name: 'depth',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Depth of the product, which can be used when calculating shipping costs. ' \
          'minimum: 0, maximum: 9999999999'
        },
        {
          name: 'height',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Height of the product, which can be used when calculating shipping costs. ' \
          'minimum: 0, maximum: 9999999999'
        },
        {
          name: 'price',
          type: 'number', sticky: true, optional: false,
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'Price of the product, The price should include or exclude tax, ' \
          'based on the store settings.'
        },
        {
          name: 'cost_price',
          type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The cost price of the product. Stored for reference only; it is ' \
          'not used or displayed anywhere on the store.'
        },
        {
          name: 'retail_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The retail cost of the product. If entered, the retail cost price' \
          ' will be shown on the product page.'
        },
        {
          name: 'sale_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'If entered, the sale price will be used instead of value in the price' \
          ' field when calculating the product’s cost.'
        },
        { name: 'tax_class_id',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The ID of the tax class applied to the product. (NOTE: Value ' \
          'ignored if automatic tax is enabled.)'
        },
        { name: 'product_tax_code',
          hint: 'Accepts AvaTax System Tax Codes, which identify products and services' \
          'that fall into special sales-tax categories. Minimum length: 1, Maximum length: 255'
        },
        {
          name: "categories", sticky: true, optional: false,
          type: "array", of: "object",
          label: "Categories",
          properties: [
            { name: 'id', optional: false, type: 'integer',
              hint: 'IDs for the categories. Does not accept more than 1,000 ID values.'
            }
          ]
        },
        { name: 'brand_id',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'A product can be added to an existing brand. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_level',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Current inventory level of the product. Simple inventory tracking must be enabled' \
          '(See the inventory_tracking field) for this to take any effect. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_warning_level',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Inventory warning level for the product. Simple inventory tracking must be enabled.' \
          '(See the inventory_tracking field) for this to take any effect. minimum: 0, maximum: 9999999999'
        },
        { name: 'inventory_tracking', control_type: :select, pick_list:
            [
              %w[None none],
              %w[Product product],
              %w[Variant variant]
            ],
          toggle_hint: 'Select inventory tracking',
          toggle_field: {
            name: 'inventory_tracking',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: none, product, variant'
          }
        },
        { name: 'fixed_cost_shipping_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'A fixed shipping cost for the product. If defined, this value will be' \
          'used during checkout instead of normal shipping-cost calculation. minimum: 0'
        },
        { name: 'is_free_shipping', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product has free shipping.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_free_shipping',
                type: :boolean,
                label: 'Is free shipping',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product has free shipping. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_visible', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint:  'Whether the product should be displayed to customers browsing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_visible',
                type: :boolean,
                label: 'Is visible',
                optional: true,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be displayed to customers browsing the store. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_featured', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product should be included in the featured products panel when viewing the store.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_featured',
                type: :boolean,
                optional: true,
                label: 'Is featured',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product should be included in the featured products panel when viewing the store. ' \
                'Allowed values are true or false'
              }
        },
        {
          name: "related_products",
          type: "array", of: "object",
          label: "Related products",
          properties: [
            { name: 'id', optional: false, type: 'integer',
              hint: 'An array of IDs for the related products.'
            }
          ]
        },
        { name: 'warranty',
          hint: 'Warranty information displayed on the product page. Can include HTML formatting. Minimum length: 1, Maximum length: 65535'
        },
        { name: 'bin_picking_number',
          hint: 'The BIN picking number for the product. Minimum length: 1, Maximum length: 255'
        },
        { name: 'layout_file',
          hint: 'The layout template file used to render this product category.' \
          'This field is writable only for stores with a Blueprint theme applied. Minimum length: 1, Maximum length: 500'
        },
        { name: 'upc',
          hint: 'The product UPC code, which is used in feeds for shopping comparison sites' \
          'and external channel integrations. Minimum length: 1, Maximum length: 255'
        },
        { name: 'search_keywords',
          hint: 'A comma-separated list of keywords that can be used to locate the product when searching the store.'\
          'Minimum length: 1, Maximum length: 65535'
        },
        { name: 'availability', control_type: :select, pick_list:
            [
              %w[Available available],
              %w[Disabled disabled],
              %w[Preorder preorder]
            ],
          toggle_hint: 'Select availability',
          toggle_field: {
            name: 'availability',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: available, disabled, preorder'
          }
        },
        { name: 'availability_description',
          hint: 'Availability text displayed on the checkout page, under the product title.'\
          'Minimum length: 1, Maximum length: 255'
        },
        { name: 'gift_wrapping_options_type', control_type: :select, pick_list:
            [
              %w[Any any],
              %w[None none],
              %w[List list]
            ],
          toggle_hint: 'Select gift wrapping options type',
          toggle_field: {
            name: 'gift_wrapping_options_type',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: any, none, list'
          }
        },
        {
          name: "gift_wrapping_options_list",
          type: "array", of: "object",
          label: "Gift wrapping option list",
          properties: [
            { name: 'id', optional: false, type: 'integer',
              hint: 'A list of gift-wrapping option IDs.' }
          ]
        },
        { name: 'sort_order',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Priority to give this product when included in product lists on category pages' \
          'and in search results. minimum: -2147483648, maximum:  2147483647'
        },
        { name: 'condition', control_type: :select, pick_list:
            [
              %w[New New],
              %w[Used Used],
              %w[Refurbished Refurbished]
            ],
          toggle_hint: 'Select condition',
          toggle_field: {
            name: 'condition',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: New, Used, Refurbished'
          }
        },
        { name: 'is_condition_shown', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether the product condition is shown to the customer on the product page.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_condition_shown',
                type: :boolean,
                optional: true,
                label: 'Is condition shown',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether the product condition is shown to the customer on the product page. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'order_quantity_minimum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The minimum quantity an order must contain, to be eligible to purchase this product.' \
          'minimum: 0, maximum:  9999999999'
        },
        { name: 'order_quantity_maximum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The maximum quantity an order must contain, to be eligible to purchase this product.' \
          'minimum: 0, maximum:  9999999999'
        },
        { name: 'page_title',
          hint: 'Custom title for the product page. If not defined, the product name will be used as the meta title.' \
          'Minimum length: 0, Maximum length: 255'
        },
        {
          name: "meta_keywords",
          type: "array", of: "object",
          label: "Meta keywords",
          properties: [{ name: 'keyword', hint: 'A list of gift-wrapping option IDs.' }]
        },
        { name: 'meta_description',
          hint: 'Custom meta description for the product page. Minimum length: 0, Maximum length: 255'
        },
        { name: 'view_count',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The number of times the product has been viewed. minimum: 0, maximum:  9999999999'
        },
        { name: 'preorder_release_date',
          type: 'date_time',
          label: 'Preorder release date',
          hint: 'Preorder release date in RFC-2822 or ISO-8601. e.g. ' \
          '<br>RFC-2822: Thu, 20 Apr 2017 11:32:00 -0400' \
          '<br>ISO-8601: 2017-04-20T11:32:00.000-04:00'
        },
        { name: 'preorder_message',
          hint: 'Custom expected-date message to display on the product page. Minimum length: 1, Maximum length: 255'
        },
        { name: 'is_preorder_only', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'If set to true, the price is hidden.' \
          '(NOTE: To successfully set is_price_hidden to true, the availability value must be disabled.)',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_preorder_only',
                type: :boolean,
                optional: true,
                label: 'Is preorder only',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'If set to true, the price is hidden.' \
                '(NOTE: To successfully set is_price_hidden to true, the availability value must be disabled.) ' \
                'Allowed values are true or false'
              }
        },
        { name: 'is_price_hidden', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'If set to true then on the preorder release date the preorder status will automatically be removed.' \
          'If set to false, then on the release date the preorder status will not be removed.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'is_price_hidden',
                type: :boolean,
                optional: true,
                label: 'Is price hidden',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'If set to true then on the preorder release date the preorder status will automatically be removed.' \
                'If set to false, then on the release date the preorder status will not be removed. ' \
                'Allowed values are true or false'
              }
        },
        { name: 'price_hidden_label',
          hint: ' If is_price_hidden is true, the value of price_hidden_label is displayed instead of the price. Minimum length: 1, Maximum length: 200'
        },
        {
          name: 'custom_url',
          type: 'object',
          label: 'Custom URL',
          properties: [
            { name: 'url', hint: 'Product URL on the storefront.' },
            { name: 'is_customized', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'is_customized',
                    type: :boolean,
                    optional: true,
                    label: 'Is customized',
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value'
                  }
            }
          ]
        },
        { name: 'open_graph_type', control_type: :select, pick_list:
            [
              %w[Product product],
              %w[Album album],
              %w[Book book],
              %w[Drink drink],
              %w[Food food],
              %w[Game game],
              %w[Movie movie],
              %w[Song song],
              %w[TV\ show tv_show]
            ],
          toggle_hint: 'Select open graph type',
          toggle_field: {
            name: 'open_graph_type',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: product, album, book, drink, food, game, movie, song, tv_show'
          }
        },
        { name: 'open_graph_title',
          hint: 'Title of the product, if not specified the product name will be used instead.'
        },
        { name: 'open_graph_description',
          hint: 'Description to use for the product, if not specified then the meta_description will be used instead.'
        },
        { name: 'open_graph_use_meta_description', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether to determine if product description or open graph description is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_meta_description',
                type: :boolean,
                optional: true,
                label: 'Open graph use meta description',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product description or open graph description is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'open_graph_use_product_name', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether  to determine if product name or open graph name is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_product_name',
                type: :boolean,
                optional: true,
                label: 'Open graph use product name',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product name or open graph name is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'open_graph_use_image', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Whether to determine if product image or open graph image is used.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'open_graph_use_image',
                type: :boolean,
                optional: true,
                label: 'Open graph use image',
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Whether to determine if product image or open graph image is used.' \
                 'Allowed values are true or false'
              }
        },
        { name: 'brand_id',
          hint: 'The brand ID of the product.'
        },
        { name: 'gtin',
          hint: 'Global Trade Item Number'
        },
        { name: 'mpn',
          hint: 'Manufacturer Part Number'
        },
        { name: 'calculated_price',
          type: 'number',
          control_type: 'number',
          render_input: 'float_conversion',
          parse_output: 'float_conversion',
          hint: 'The price of the product as seen on the storefront. It will be equal to the sale_price'
        },
        { name: 'reviews_rating_sum',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The total rating for the product.'
        },
        { name: 'reviews_count',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The number of times the product has been rated.'
        },
        { name: 'total_sold',
          type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The total quantity of this product sold.'
        },
        { name: 'custom_fields', type: 'array', of: 'object',
          properties: [
            { name: 'name', optional: false, hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'value', optional: false, hint: 'Minimum length: 1, Maximum length: 250' }
          ],
          hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
        },
        { name: 'bulk_pricing_rules', type: 'array', of: 'object',
          properties: [
            { name: 'quantity_min', type: 'integer', optional: false, hint: 'The minimum inclusive quantity of a product. Minimum: 0' },
            { name: 'quantity_max', type: 'integer', optional: false, hint: 'The maximum inclusive quantity of a product. Minimum: 0' },
            { name: 'type', control_type: :select, pick_list:
                [
                  %w[Price price],
                  %w[Precent percent],
                  %w[Fixed fixed]
                ],
              toggle_hint: 'Select type',
              toggle_field: {
                name: 'type',
                type: :string,
                control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: price, percent, fixed'
              }
            },
            { name: 'amount', type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              optional: false, hint: 'The discount can be a fixed dollar amount or a percentage' }
          ],
          hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
        },
        { name: 'date_created', type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date on which the product was created.. If not specified, will default to the current' \
          ' time. The date should be in RFC 2822 format, e.g.: Tue, 20 Nov 2012 00:00:00 +0000'
        },
        { name: 'date_modified', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'A read-only value representing the last modification of the product. Do not ' \
          'attempt to modify or set this value in a POST or PUT operation. RFC-2822'
        },
        { name: 'variants', type: 'array', of: 'object',
          properties: [
            { name: 'cost_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'sale_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'retail_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'weight',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'width',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'height',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'depth',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'is_free_shipping', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              hint: 'Whether the product has free shipping.',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'is_free_shipping',
                    type: :boolean,
                    label: 'Is free shipping',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Whether the product has free shipping. ' \
                    'Allowed values are true or false'
                  }
            },
            { name: 'fixed_cost_shipping_price',
              type: 'number',
              control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion'
            },
            { name: 'purchasing_disabled', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'purchasing_disabled',
                    type: :boolean,
                    label: 'Purchasing disabled',
                    optional: true,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false'
                  }
            },
            { name: 'purchasing_disabled_message', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'upc', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'inventory_level', type: 'integer'},
            { name: 'inventory_warning_level', type: 'integer'},
            { name: 'bin_picking_number', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'id', type: 'integer'},
            { name: 'product_id', type: 'integer'},
            { name: 'sku', hint: 'Minimum length: 1, Maximum length: 250' },
            { name: 'sku_id', type: 'integer'},
            { name: 'option_values', type: 'array', of: 'object',
              properties: [
                { name: 'option_display_name', hint: 'Minimum length: 1, Maximum length: 250' },
                { name: 'label', hint: 'Minimum length: 1, Maximum length: 250' },
                { name: 'id', type: 'integer'},
                { name: 'option_id', type: 'integer'},
              ],
              hint: 'The custom_fields in the product. This has the following members, name (required), value (required)'
            },
            { name: 'calculated_price', type: 'integer'}
          ],
          hint: 'The variants of the product.'
        },
        { name: 'base_variant_id', type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The unique identifier of the base variant associated with a simple product. This value is null for complex products.'
        }
      ]
    end,

    create_product_execute: lambda do |input|
      input['categories'] = input['categories'].map { |i| i['id'] } if input['categories']
      input['related_products'] = input['related_products'].map { |i| i['id'] }  if input['related_products']
      input['gift_wrapping_options_list'] = input['gift_wrapping_options_list'].map { |i| i['id'] }  if input['gift_wrapping_options_list']
      input['meta_keywords'] = input['meta_keywords'].map { |i| i['keyword'] } if input['meta_keywords']
      input['preorder_release_date'] = input['preorder_release_date']&.strftime('%Y-%m-%dT%H:%M:%S%:z')

      response = post("/stores/#{input.delete('store_hash')}/v3/catalog/products", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end

      call('process_product_response', response)
    end,

    update_product_execute: lambda do |input|
      input['categories'] = input['categories'].map { |i| i['id'] } if input['categories']
      input['related_products'] = input['related_products'].map { |i| i['id'] }  if input['related_products']
      input['gift_wrapping_options_list'] = input['gift_wrapping_options_list'].map { |i| i['id'] }  if input['gift_wrapping_options_list']
      input['meta_keywords'] = input['meta_keywords'].map { |i| i['keyword'] } if input['meta_keywords']
      input['preorder_release_date'] = input['preorder_release_date']&.strftime('%Y-%m-%dT%H:%M:%S%:z')

      response = put("/stores/#{input.delete('store_hash')}/v3/catalog/products/#{input.delete('product_id')}", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end

      call('process_product_response', response)
    end,

    search_product_execute: lambda do |input|
      response = get("/stores/#{input.delete('store_hash')}/v3/catalog/products", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end

      call('process_product_response', response)
    end,

    process_product_response: lambda do |input|
      if input['data'].is_a? Array
      input['data'].each do |datum|
        datum['categories'] = datum['categories'].map { |id| {'id': id} } if datum['categories']
        datum['related_products'] = datum['related_products'].map { |id| {'id': id} }  if datum['related_products']
        datum['gift_wrapping_options_list'] = datum['gift_wrapping_options_list'].map { |id| {'id': id} }  if datum['gift_wrapping_options_list']
        datum['meta_keywords'] = datum['meta_keywords'].map { |keyword| {'keyword': keyword} } if datum['meta_keywords']
      end
    else
      input['categories'] = input['categories'].map { |id| {'id': id} } if input['categories']
      input['related_products'] = input['related_products'].map { |id| {'id': id} }  if input['related_products']
      input['gift_wrapping_options_list'] = input['gift_wrapping_options_list'].map { |id| {'id': id} }  if input['gift_wrapping_options_list']
      input['meta_keywords'] = input['meta_keywords'].map { |keyword| {'keyword': keyword} } if input['meta_keywords']
    end
      input
    end,

    customer_search_schema: lambda do |_input|
      [
        {
          name:'page',type:'integer',label:'Page Number'
        },
        {
          name:'limit',type:'integer',label:'Limit'
        },
        {
          name:'id:in',type:'string',sticky:true,label:'ID',
          hint:"Multiple ID's can be given using commas. example(1,2,3)"
        },
        {
          name: 'company:in', type: 'string',sticky: true,label: 'Company Name',
          hint:"Multiple company's name can be given by using commas.Example(bigcommerce,commongood)"
        },
        {
          name:'customer_group_id:in',type:'string',label:'Customer Group ID',
          hint:"Multiple values can be given using commas"
        },
        {
          name:'date_created', type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',label:'Date Created',
          hint:'Filter items by date_created.'
        },
        {
          name:'date_created:max',type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',label:'Maximum Date Created',
          hint:'Filter items by maximum date_created. '
        },
        {
          name:'date_created:min',type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',label:'Minimum Date Created',
          hint:'Filter items by minimum date_created.'
        },
        {
          name:'date_modified',type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',label:'Date Modified',
          hint:'Filter items by date_modified. '
        },
        {
          name:'date_modified:min',type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',label:'Minimum Date Modified',
          hint:'Filter items by mininum date_modified.'
        },
        {
          name:'date_modified:max',type: 'date_time', render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',label:'Maximum Date Modified',
          hint:'Filter items by maximum date_modified'
        },
        {
          name:'email:in',type:'string',sticky:true,label:'Email',
          hint:'Filter items by email. '
        },
        {
          name:'name',type:'string',sticky:true,label:'Name',
          hint:'Filter items by first_name and last_name.'
        },
        {
          name:'name:like',type:'string',sticky:true,label:'Name:Like',
          hint:"Filter items by substring in first_name and last_name "
        },
        {
          name:'registration_ip_address:in',type:'string',label:'Registration IP Address',
          hint:'Filter items by registration_ip_address. If the customer was created using the API, then registration address is blank.'
        }
      ]
    end,

    customer_create_schema: lambda do |_input|
      [
        {
          name:'email',type:'string',optional:false,sticky:true,label:'Email Id',
          hint:'The email of the customer.'
        },
        {
          name:'first_name',type:'string',optional: false,sticky:true,label:'First Name',
          hint:'The first name of the customer.'
        },
        {
          name:'last_name',type:'string',optional:false,sticky:true,label:'Last Name',
          hint:'The last name of the customer.'
        },
        {
          name: 'company', type:'string',label:'Company Name',
          hint:'The company of the customer.'
        },
        {
          name:'phone',type:'string',label:'Phone Number',
          hint:'The phone number of the customer.'
        },
        {
          name:'notes',type:'string',label:'Notes',
          hint:'The customer notes.'
        },
        {
          name:'tax_exempt_category',type:'string',label:'Tax Exempt Category',
          hint:'The tax exempt category code for the customer.'
        },
        {
          name:'customer_group_id',type:'integer',label:'Customer Group ID',
          hint:'Id of the group which this customer belongs to.'
        },
        {
          name:'addresses',type:'array',of:'object',sticky:true,label:'Addresses',
          hint:'Array of customer addresses.',
          properties:[
            {
              name:'first_name',type:'string',sticky:true,optional:false,label:'First Name',
              hint:'The first name of the customer address.'
            },
            {
              name:'last_name',type:'string',sticky:true,optional:false,label:'Last Name',
              hint:'The last name of the customer address.'
            },
            {
              name:'company',type:'string',sticky:true,label:'Company Name',
              hint:'The company of the customer address.'
            },
            {
              name:'address1',type:'string',sticky:true,optional:false,label:'Address 1 Line',
              hint:'The address 1 line.'
            },
            {
              name:'address2',type:'string',sticky:true,label:'Address 2 Line',
              hint:'The address 2 line.'
            },
            {
              name:'city',type:'string',sticky:true,optional:false,label:'City',
              hint:'The city of the customer address.'
            },
            {
              name:'state_or_province',type:'string',sticky:true,optinal:false,label:'State or Province Name',
              hint:'The state or province name'
            },
            {
              name:'postal_code',type:'string',sticky:true,optional:false,label:'Postal Code',
              hint:'The postal code of the customer address.'
            },
            {
              name:'country_code',type:'string',sticky:true,optional:false,label:'Country Code',
              hint:'The country code of the customer address.Example:"US" '
            },
            {
              name:'phone',type:'string',sticky:true,label:'Phone Number',
              hint:'The phone number of the customer address.'
            },
            {
              name: 'address_type',label:'Address Type',sticky:true,
              hint:'The address type. Residential or Commercial',control_type: :select,
              pick_list:
                [
                  %w[Residential residential],
                  %w[Commercial commercial]
                ],
              toggle_hint: 'Select type',
              toggle_field: {
                name: 'type',
                type: :string,
                control_type: 'text',
                label:'Address Type',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: residential,commercial'
              }
            }
          ]
       },
       {
          name:'attributes',type:'array',of:'object',sticky:true,label:'Attributes',
          hint:'Array of customer attributes',
          properties:[
             {
               name:'attribute_id',type:'integer',sticky:true,optional:false,label:'Attribute Id'
             },
             {
               name:'attribute_value',type:'string',sticky:true,optional:false,label:'Attribute Value'
             },
         ]
       },
       {
         name:'authentication',type:'object',label:'Authentication',
         properties:[
             {
               name:'force_password_reset',type:'boolean',sticky:true,label:'Force Password Reset',
               hint:'If true, this customer will be forced to change password on next login.',
               control_type: 'checkbox',
               render_input: 'boolean_conversion',
               parse_output: 'boolean_conversion',
               toggle_hint: 'Select from list',
               toggle_field:
                {
                  name: 'force_password_reset',
                  label:'Force Password Reset',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint:'Allowed values are true or false'
              }
             },
             {
               name:'new_password',type:'string',sticky:true,label:'New Password',
               hint:'New password for customer.'
             }
         ]
       },
       {
          name: 'accepts_product_review_abandoned_cart_emails', type: 'boolean',
          hint:'It determines if the customer is signed up to receive either product review or abandoned cart emails or recieve both emails.',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
             toggle_field:
                {
                  name: 'accepts_product_review_abandoned_cart_emails',
                  label:'Accepts Product Review Abandoned Cart Emails',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint:'Allowed values are true or true'
              }
       },
       {
          name:'store_credit_amounts',type:'array',of:'object',label:'Store Credit amounts',
         properties:[
             {
               name:'amount',type:'number',sticky:true,label:'Amount'
             }
         ]
       },
      ]
    end,

    customer_update_schema: lambda do |_input|
      [
        {
          name:'id',type:'integer',sticky:true,optional:false,label:'ID',
          hint:' ID of the customer.'
        },
        {
          name:'email',type:'string',label:'Email Id',
          hint:'The email of the customer.'
        },
        {
          name:'first_name',type:'string',label:'First Name',
          hint:'The first name of the customer.'
        },
        {
          name:'last_name',type:'string',label:'Last Name',
          hint:'The last name of the customer.'
        },
        {
          name: 'company', type:'string',label:'Company Name',
          hint:'The company of the customer.'
        },
        {
          name:'phone',type:'string',label:'Phone Number',
          hint:'The phone number of the customer.'
        },
        {
          name:'notes',type:'string',label:'Notes',
          hint:'The customer notes.'
        },
        {
          name:'tax_exempt_category',type:'string',label:'Tax Exempt Category',
          hint:'The tax exempt category code for the customer.'
        },
        {
          name:'customer_group_id',type:'integer',control_type: 'integer',render_input: 'integer_conversion',
          label:'Customer Group ID',hint:'Id of the group which this customer belongs to.'
        },
        {
          name:'registration_ip_address',type:'string',label:'Registration IP Address',
          hint:'The IP address from which this customer was registered.'
        },
        {
         name:'authentication',type:'object',label:'Authentication',
         properties:
            [
             {
               name:'force_password_reset',type:'boolean',sticky:true,label:'Force Password Reset',
               hint:'If true, this customer will be forced to change password on next login.',
               control_type: 'checkbox',
               render_input: 'boolean_conversion',
               parse_output: 'boolean_conversion',
               toggle_hint: 'Select from list',
               toggle_field:
                {
                  name: 'force_password_reset',
                  label:'Force Password Reset',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint:'Allowed values are true or false'
              }
             },
             {
               name:'new_password',type:'string',sticky:true,label:'New Password',
               hint:'New password for customer.'
             }
         ]
       },
       {
          name: 'accepts_product_review_abandoned_cart_emails', type: 'boolean',
          hint:'It determines if the customer is signed up to receive either product review or abandoned cart emails or recieve both emails.',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
         toggle_hint: 'Select from list',
             toggle_field:
                {
                  name: 'accepts_product_review_abandoned_cart_emails',
                  label:'Accepts Product Review Abandoned Cart Emails',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint:'Allowed values are true or true'
              }
       },
       {
          name:'store_credit_amounts',type:'array',of:'object',label:'Store Credit amounts',
          properties:
            [
              {
                name:'amount',type:'number',sticky:true,label:'Amount'
              }
         ]
       }
      ]
    end,

    customer_schema: lambda do |_input|
      [
        {
          name:'email',type:'string',sticky:true,label:'EmailId'
        },
        {
          name:'first_name',type:'string',sticky:true,label:'First Name'
        },
        {
          name:'last_name',type:'string',sticky:true,label:'Last Name'
        },
        {
          name:'company',type:'string',sticky:true,label:'Company Name'
        },
        {
          name:'phone',type:'string',sticky:true,label:"Phone Number"
        },
        {
          name:'registration_ip_address',type:'string',sticky:true,label:'Registration IP Address'
        },
        {
          name:'notes',type:'string',sticky:true,label:'Notes'
        },
        {
          name:'tax_exempt_category',type:'string',sticky:true,label:'Tax Exempt Category'
        },
        {
          name:'customer_group_id',type:'integer',sticky:true,label:'Customer Group Id'
        },
        {
          name:'id',type:'integer',sticky:true,label:'ID'
        },
        {
          name:'date_created',type:'string',sticky:true,label:'Date Created'
        },
        {
          name:'date_modified',type:'string',sticky:true,label:'Date Modified'
        },
        {
          name:'address_count',type:'integer',label:'Address Count'
        },
        {
          name:'attribute_count',type:'integer',label:'Attribute Count'
        },
        {
            name:'addresses',type:'object',sticky:true,label:'Addresses',
            properties:
              [
                {
                  name:'first_name',type:'string',sticky:true,optional:false,label:'First Name'
                },
                {
                  name:'last_name',type:'string',sticky:true,optional:false,label:'Last Name'
                },
                {
                  name:'company',type:'string',sticky:true,label:'Company Name'
                },
                {
                  name:'address1',type:'string',sticky:true,optional:false,label:'Address 1 Line'
                },
                {
                  name:'address2',type:'string',sticky:true,label:'Address 2 Line'
                },
                {
                  name:'city',type:'string',sticky:true,optional:false,label:'City'
                },
                {
                  name:'state_or_province',type:'string',sticky:true,optinal:false,label:'State or Province Name'
                },
                {
                  name:'postal_code',type:'string',sticky:true,optional:false,label:'Postal Code'
                },
                {
                  name:'country_code',type:'string',sticky:true,optional:false,label:'Country Code'
                },
                {
                  name:'phone',type:'string',sticky:true,label:'Phone Number'
                },
                {
                  name:'address_type',type:'string',sticky:true,label:'Address Type'
                },
                {
                  name:'customer_id',type:'integer',sticky:true,optional:false,label:'Customer Id'
                },
                {
                  name:'id',type:'integer',sticky:true,optional:false,label:'Id'
                },
                {
                  name:'country',type:'string',label:'Country'
                }
              ]
         },
         {
            name:'attributes',type:'object',sticky:true,label:'Attributes',
            properties:[
               {
                 name:'attribute_id',type:'integer',sticky:true,optional:false,label:'Attribute Id'
               },
               {
                 name:'value',type:'string',sticky:true,optional:false,label:'Attribute Value'
               },
               {
              name:'customer_id',type:'integer',sticky:true,optional:false,label:'Customer Id'
              },
              {
              name:'id',type:'integer',sticky:true,optional:false,label:'Id'
              },
              {
              name:'date_modified',type:'string',label:'Date Modified'
              },
             {
             name:'date_created',type:'string',label:'Date Created'
             }
           ]
         },
         {
           name:'accepts_product_review_abandoned_cart_emails',type:'boolean',label:'Accepts Product Review Abandoned Cart Emails'
         },
         {
            name:'store_credit_amounts',type:'object',label:'Store Credit amounts',
           properties:[
               {
                 name:'amount',type:'number',sticky:true,label:'Amount'
               }
           ]
         },
         {
         name:'form_fields',type:'object',label:'Form Fields',
           properties:[
           {
           name:'name',type:'string',sticky:true,optional:false,label:'Name'
           },
           {
           name:'value',type:'string',sticky:true,optional:false,label:'Value'
           }
           ]
         },
          {
           name:'authentication',type:'object',label:'Authentication',
           properties:[
               {
                 name:'force_password_reset',type:'boolean',sticky:true,label:'Force Password Reset'
               }
           ]
         }]
    end,

    create_customer_execute: lambda do |input|
      post("/stores/#{input.delete('store_hash')}/v3/customers", Array.wrap(input)).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
      end
    end,

    update_customer_execute: lambda do |input|
      input['id']=input['id'].to_i
      put("/stores/#{input.delete('store_hash')}/v3/customers", Array.wrap(input)).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    search_customer_execute: lambda do |input|
      get("/stores/#{input.delete('store_hash')}/v3/customers", input).
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
      end
    end,

    get_trigger_url: lambda do |object_name|
      if object_name == 'order'
        'v2/orders'
      elsif object_name == 'product'
        'v3/catalog/products'
      elsif object_name == 'price_list'
        'v3/pricelists'
      elsif object_name == 'customer'
        'v3/customers'
      end
    end,

    new_updated_trigger_execute: lambda do |connection, input, closure|
      object_name = input.delete('object')
      object_url = call('get_trigger_url', object_name)
      updated_after = closure&.[]('updated_after') ||
                      (input['since'] || 1.hour.ago).to_time.iso8601
      limit = 100
      page = closure['page'] || 1

      if object_name == 'order'
        is_deleted = closure&.[]('is_deleted') || input['is_deleted']
        records = get("/stores/#{connection['store_hash']}/#{object_url}").
                  params(limit: limit,
                         page: page,
                         min_date_modified: updated_after,
                         sort: 'date_modified:asc',
                         is_deleted: is_deleted || false) || []
      elsif object_name == 'product'
        response = get("/stores/#{connection['store_hash']}/#{object_url}").
                  params(limit: limit,
                         page: page,
                         'date_modified:min': updated_after,
                         sort: 'date_modified',
                         direction: 'asc') || []

      records = response['data'] || []
    elsif %w[price_list customer].include? object_name
      response = get("/stores/#{connection['store_hash']}/#{object_url}").
                params(limit: limit,
                       'date_modified:min': updated_after,
                       page: page) || []

    records = response['data'] || []
      end
    records
    end
  },

  object_definitions: {
    create_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_create_schema", 'create')
      end
    },
    create_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'order'
          call("#{config_fields['object']}_schema", 'output')
        else
          [{ name: 'data', type: 'object',
            label: config_fields['object'].pluralize,
            properties: call("#{config_fields['object']}_schema", 'output') }]
        end
      end
    },
    update_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_update_schema", 'update')
      end
    },
    update_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'order'
          call("#{config_fields['object']}_schema", 'output')
        else
          [{ name: 'data', type: 'object',
            label: config_fields['object'].pluralize,
            properties: call("#{config_fields['object']}_schema", 'output') }]
        end
      end
    },
    search_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_search_schema", '')
      end
    },
    search_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if %w[order order_product].include? config_fields['object']
          [{ name: 'records', type: 'array', of: 'object',
            label: config_fields['object'].pluralize,
            properties: call("#{config_fields['object']}_schema", 'output') }]
        else
          [{ name: 'data', type: 'array', of: 'object',
            label: config_fields['object'].pluralize,
            properties: call("#{config_fields['object']}_schema", 'output') }]
        end
      end
    },
    get_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_get_schema", '')
      end
    },
    get_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_schema", 'output')
      end
    },
    get_trigger_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'order'
          [
            { name: 'status_id', sticky: true, label: 'Status' },
            { name: 'is_deleted', type: 'boolean', control_type: 'checkbox',
              label: 'Include deleted orders',
              hint: 'Retrieves deleted or archived orders when true' },
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
        else
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
        end
      end
    },
  },

  actions: {
    create_object: {
      title: 'Create object',
      subtitle: 'Create an object in Bigcommerce',
      description: lambda do |_connection, create_object_list|
        object_name = {
          'Order' => 'an order',
          'Order shipment' => 'order shipment',
          'Product' => 'a product',
          'Customer' => 'a customer',
          'Price List' => 'a price list'
        }[create_object_list[:object]]
        "Create <span class='provider'>#{object_name || 'an object'}</span> in " \
        "<span class='provider'>Bigcommerce</span>"
      end,
      help: lambda do |_connection, create_object_list|
        object_help = {
          'Order shipment' => 'Note: <b>tracking_carrier</b> is optional, but if you include it, its value must' \
          ' refer/map to the same carrier service as the shipping_provider value.' \
          ' Acceptable values for tracking_carrier are an empty string (""), or one of' \
          " the valid tracking-carrier values viewable <a href='https://docs.google.com/" \
          "spreadsheets/d/1w9c_aECSCGyf-oOrvGeUniDl-ARGKemfZl0qSsav8D4/pubhtml?gid=0&single=true'" \
          " target='_blank'>here</a>"
        }[create_object_list[:object]]
        object_help
      end,
      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'create_object_list',
          hint: 'Select the object type from picklist.'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['create_object_input']
      end,
      execute: lambda do |connection, input|
        object_name = input.delete('object')
        call("create_#{object_name}_execute", input&.merge('store_hash' => connection['store_hash'])).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definition|
        object_definition['get_object_output']
      end,
      sample_output: lambda do |connection, input|
        call('sample_output', input&.merge('store_hash' => connection['store_hash']))
      end
    },

    update_object: {
      title: 'Update object',
      subtitle: 'Update an object in Bigcommerce',
      description: lambda do |_connection, update_object_list|
        object_name = {
          'Order' => 'an order',
          'Product' => 'a product',
          'Customer' => 'a customer',
          'Price List' => 'a price list'
        }[update_object_list[:object]]
        "Update <span class='provider'>#{object_name || 'an object'}</span> in " \
        "<span class='provider'>Bigcommerce</span>"
      end,
      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'update_object_list',
          hint: 'Select the object type from picklist.'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['update_object_input']
      end,
      execute: lambda do |connection, input|
        object_name = input.delete('object')
        call("update_#{object_name}_execute", input&.merge('store_hash' => connection['store_hash'])).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definition|
        object_definition['update_object_output']
      end,
      sample_output: lambda do |connection, input|
        call('sample_output', input&.merge('store_hash' => connection['store_hash']))
      end
    },

    search_object: {
      title: 'Search object',
      subtitle: 'Search for objects in Bigcommerce',
      description: lambda do |_connection, search_object_list|
        object_name = {
          'Order' => 'an orders',
          'Order product' => 'order products by order ID',
          'Product' => 'a product',
          'Customer' => 'a customer',
          'Price List' => 'a price list'
        }[search_object_list[:object]]
        "Search <span class='provider'>#{object_name || 'objects'}</span> in " \
        "<span class='provider'>Bigcommerce</span>"
      end,
      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'search_object_list',
          hint: 'Select the object type from picklist.'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['search_object_input']
      end,
      execute: lambda do |connection, input|
        object_name = input.delete('object')
        error('Provide at least one search criteria') if input.blank?

        if %w[order order_product].include? object_name
          { records: call("search_#{object_name}_execute",
            input&.merge('store_hash' => connection['store_hash'])).
            after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
            end
          }
        else
          call("search_#{object_name}_execute",
            input&.merge('store_hash' => connection['store_hash']))&.
            after_error_response(/.*/) do |_code, body, _header, message|
           error("#{message}: #{body}")
         end
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['search_object_output']
      end,
      sample_output: lambda do |connection, input|
        if %w[order order_product].include? input.delete('object')
          { records:
          call('sample_output', input&.merge('store_hash' => connection['store_hash'])) }
        else
          call('sample_output', input&.merge('store_hash' => connection['store_hash']))
        end
      end
    },

    get_object: {
      title: 'Get object by ID',
      subtitle: 'Get an object in Bigcommerce by its record ID',
      description: lambda do |_connection, get_object_list|
        object_name = {
          'Order' => 'a order',
          'Product in a specific order' => 'product in a specific order',
          'Shipping address in a specific order' => 'shipping address in a specific order'
        }[get_object_list[:object]]
        "Get <span class='provider'>#{object_name || 'an object'}</span> in " \
        "<span class='provider'>Bigcommerce</span> by ID"
      end,
      config_fields: [{
        name: 'object',
        optional: false,
        label: 'Object type',
        control_type: 'select',
        pick_list: 'get_object_list',
        hint: 'Select the object type from picklist.'
      }],
      input_fields: lambda do |object_definition|
        object_definition['get_object_input']
      end,
      execute: lambda do |connection, input|
        object_name = input.delete('object')
        call("get_#{object_name}_execute",
             input&.merge('store_hash' => connection['store_hash']))&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definition|
        object_definition['get_object_output']
      end,
      sample_output: lambda do |connection, input|
        call('sample_output', input&.merge('store_hash' => connection['store_hash']))
      end
    }
  },

  triggers: {
    new_updated_objects: {
      title: 'New/updated objects',
      description: lambda do |_input, pick_lists|
        object_name = {
          'Order' => 'order',
          'Product' => 'product',
          'Price List' => 'price list',
          'Customer' => 'customer'
        }[pick_lists['object']]
        "New/updated <span class='provider'>" \
        "#{object_name || 'record'}" \
        "</span> in <span class='provider'>Bigcommerce</span>"
      end,
      help: lambda do |_input, pick_lists|
        object_name = {
          'Order' => 'order',
          'Product' => 'product',
          'Price List' => 'price list',
          'Customer' => 'customer'
        }[pick_lists['object']]
        "Triggers when a #{object_name || 'record'}  is created or updated."
      end,
      config_fields: [{
        name: 'object',
        optional: false,
        label: 'Object type',
        control_type: 'select',
        pick_list: 'new_updated_objects',
        hint: 'Select the object type from picklist.'
      }],
      input_fields: lambda do |_object_definition|
        _object_definition['get_trigger_input']
      end,
      poll: lambda do |connection, input, closure|
        closure ||= {}
        updated_after = closure&.[]('updated_after') || (input['since'] || 1.hour.ago).to_time.iso8601
        page = closure['page'] || 1
        records = call('new_updated_trigger_execute', connection, input, closure) || []

        closure = if (has_more = records.size > 0) && records.present?
                    { 'updated_after': updated_after,
                      'page': page + 1 }
                  else
                    updated_after = if records.present? && (modified_date = records&.[]('date_modified'))
                                      modified_date.to_time.iso8601
                                    else
                                      now.to_time.iso8601
                                    end
                    { 'updated_after': updated_after,
                      'page': 1 }
                  end
        {
          events: records.presence || [],
          next_poll: closure,
          can_poll_more: has_more
        }
      end,
      dedup: lambda do |object|
        "#{object['id']}-#{object['date_modified']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['get_object_output']
      end,
      sample_output: lambda do |connection, input|
        call('sample_output', input&.merge('store_hash' => connection['store_hash']))
      end
    }
  },
  pick_lists: {
    new_updated_objects: lambda do
      [
        %w[Order order],
        %w[Product product],
        %w[Customer customer],
        %w[Price\ List price_list]
      ]
    end,
    create_object_list: lambda do
      [
        %w[Order order],
        %w[Order\ shipment order_shipment],
        %w[Product product],
        %w[Customer customer],
        %w[Price\ List price_list]
      ]
    end,
    update_object_list: lambda do
      [
        %w[Order order],
        %w[Order\ shipment order_shipment],
        %w[Product product],
        %w[Customer customer],
        %w[Price\ List price_list]
      ]
    end,

    search_object_list: lambda do
      [
        %w[Order order],
        %w[Products\ in\ a\ specific\ order order_product],
        %w[Product product],
        %w[Customer customer],
        %w[Price\ List price_list]
      ]
    end,

    get_object_list: lambda do
      [
        %w[Order order],
        %w[Product\ in\ a\ specific\ order order_product],
        %w[Shipping\ address\ in\ a\ specific\ order order_shipping_address]
      ]
    end,
    order_status_list: lambda do
      [
        %w[Incomplete 0],
        %w[Pending 1],
        %w[Shipped 2],
        %w[Partially\ Shipped 3],
        %w[Refunded 4],
        %w[Cancelled 5],
        %w[Declined 6],
        %w[Awaiting\ payment 7],
        %w[Awaiting\ pickup 8],
        %w[Awaiting\ shipmen 9],
        %w[Completed 10],
        %w[Awaiting\ fulfillment 11],
        %w[Manual\ verification\ required 12],
        %w[Disputed 13],
        %w[Partially\ refunded 14]
      ]
    end,
    order_coupon_types: lambda do |_input|
      [%w[per_item_discount 0],
       %w[percentage_discount 1],
       %w[per_total_discount 2],
       %w[shipping_discount 3],
       %w[free_shipping 4]]
    end,
    payment_methods: lambda do |_connection|
      [
        %w['Credit Card', 'Credit Card'],
        %w[Cash Cash],
        %w['Test Payment Gateway', 'Test Payment Gateway'],
        %w[Manual Manual]
      ]
    end,
    shipping_provider_list: lambda do |_connection|
      [
        %w[Australia Post auspost],
        %w[Canada Post canadapost],
        %w[Endicia endicia],
        %w[USPS usps],
        %w[FedEx fedex],
        %w[Royal Mail royalmail],
        %w[UPS ups],
        %w[UPS\ ready upsready],
        %w['UPS Online upsonline],
        %w[Shipper HQ shipperhq],
        ['custom', ' ']
      ]
    end,
    tracking_carrier_list: lambda do |_connection|
      [
        %w[Australia Post auspost],
        %w[Canada Post canadapost],
        %w[Endicia endicia],
        %w[USPS usps],
        %w[FedEx fedex],
        %w[Royal Mail royalmail],
        %w[UPS ups],
        %w[UPS\ ready upsready],
        %w[UPS Online upsonline],
        %w[Shipper HQ shipperhq]
      ]
    end,
    product_types: lambda do |_connection|
      [
        %w[Physical physical],
        %w[Digital digital]
      ]
    end
  }
}
