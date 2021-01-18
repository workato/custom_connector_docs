{
  title: '2checkout',

  connection: {
    fields: [],

    authorization: {
      type: 'custom'
    },

    base_uri: lambda do |_connection|
      ''
    end
  },

  methods: {
    ipn_trigger_output_schema: lambda do
      [
        { name: 'GIFT_ORDER', label: 'Gift order',
          type: 'integer', control_type: 'integer' },
        { name: 'SALEDATE', label: 'Sale date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'PAYMENTDATE', label: 'Payment date',
          type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'COMPLETE_DATE', label: 'Complete date',
          type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'REFNO', label: 'Reference number',
          type: 'integer', control_type: 'integer' },
        { name: 'REFNOEXT', label: 'External reference number',
          type: 'integer', control_type: 'integer' },
        { name: 'ORIGINAL_REFNOEXT',
          label: 'Original external reference number',
          type: 'array', of: 'object',
          properties: [
            { name: 'ORIGINAL_REFNOEXT',
              label: 'Original external reference number' }
          ] },
        { name: 'SHOPPER_REFERENCE_NUMBER',
          label: 'Shopper reference number',
          type: 'integer', control_type: 'integer' },
        { name: 'ORDERNO', label: 'Order Number',
          type: 'integer', control_type: 'integer' },
        { name: 'ORDERSTATUS', label: 'Order status' },
        { name: 'PAYMETHOD', label: 'Payment method' },
        { name: 'PAYMETHOD_CODE', label: 'Payment method code' },
        { name: 'FIRSTNAME', label: 'First name' },
        { name: 'LASTNAME', label: 'Last name' },
        { name: 'COMPANY', label: 'Company' },
        { name: 'REGISTRATIONNUMBER', label: 'Registration number' },
        { name: 'FISCALCODE', label: 'Fiscal code' },
        { name: 'TAX_OFFICE', label: 'Tax office' },
        { name: 'CBANKNAME', label: 'Company bank name' },
        { name: 'CBANKACCOUNT', label: 'Company bank account' },
        { name: 'ADDRESS1', label: 'Address 1' },
        { name: 'ADDRESS2', label: 'Address 2' },
        { name: 'CITY', label: 'City' },
        { name: 'STATE', label: 'State' },
        { name: 'ZIPCODE', label: 'Zip code' },
        { name: 'COUNTRY', label: 'Country' },
        { name: 'COUNTRY_CODE', label: 'Country code' },
        { name: 'PHONE', label: 'Phone' },
        { name: 'FAX', label: 'Fax' },
        { name: 'CUSTOMEREMAIL', label: 'Customer Email' },
        { name: 'FIRSTNAME_D', label: 'First name (Delivery)' },
        { name: 'LASTNAME_D', label: 'Last name (Delivery)' },
        { name: 'COMPANY_D', label: 'Company (Delivery)' },
        { name: 'ADDRESS1_D', label: 'Address 1 (Delivery)' },
        { name: 'ADDRESS2_D', label: 'Address 2 (Delivery)' },
        { name: 'CITY_D', label: 'City (Delivery)' },
        { name: 'STATE_D', label: 'State (Delivery)' },
        { name: 'ZIPCODE_D', label: 'Zipcode (Delivery)' },
        { name: 'COUNTRY_D', label: 'Country (Delivery)' },
        { name: 'COUNTRY_D_CODE', label: 'Country code (Delivery)' },
        { name: 'PHONE_D', label: 'Phone (Delivery)' },
        { name: 'EMAIL_D', label: 'Email (Delivery)' },
        { name: 'IPADDRESS', label: 'IP address (Delivery)' },
        { name: 'IPCOUNTRY', label: 'IP country (Delivery)' },
        { name: 'COMPLETE_DATE', label: 'Complete date (Delivery)' },
        { name: 'TIMEZONE_OFFSET', label: 'Timezone offset' },
        { name: 'CURRENCY', label: 'Currency' },
        { name: 'LANGUAGE', label: 'Language' },
        { name: 'ORDERFLOW', label: 'Order flow' },
        { name: 'IPN_PID', label: 'IPN product ID', type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN product ID' }
          ] },
        { name: 'IPN_PNAME', label: 'IPN product name',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN product name' }
          ] },
        { name: 'IPN_PCODE', label: 'IPN product code',
          type: 'array', of: 'object',
          properties: [
            { name: 'value' }
          ] },
        { name: 'IPN_EXTERNAL_REFERENCE',
          label: 'IPN external reference',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN external reference' }
          ] },
        { name: 'IPN_INFO', label: 'IPN information',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN information' }
          ] },
        { name: 'IPN_QTY', label: 'IPN quantity', type: 'array', of: 'object',
          properties: [
            { name: 'value' }
          ] },
        { name: 'IPN_PRICE', label: 'IPN price', type: 'array', of: 'object',
          properties: [
            { name: 'value' }
          ] },
        { name: 'IPN_VAT', label: 'IPN VAT', type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN VAT' }
          ] },
        { name: 'IPN_VAT_RATE', label: 'IPN VAT rate',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN VAT rate' }
          ] },
        { name: 'IPN_VER', label: 'IPN version',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN version' }
          ] },
        { name: 'IPN_DISCOUNT', label: 'IPN discount',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN discount' }
          ] },
        { name: 'IPN_PROMONAME', label: 'IPN promotion name',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN promotion name' }
          ] },
        { name: 'IPN_PROMOCODE', label: 'IPN promotion code',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN promotion code' }
          ] },
        { name: 'IPN_ORDER_COSTS', label: 'IPN order costs',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN order cost' }
          ] },
        { name: 'IPN_SKU', label: 'IPN SKU', type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN SKU' }
          ] },
        { name: 'IPN_PARTNER_CODE', label: 'IPN partner code', type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN partner code' }
          ] },
        { name: 'IPN_PGROUP', label: 'IPN Product group',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN product group' }
          ] },
        { name: 'IPN_PGROUP_NAME', label: 'IPN product group name',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN product group name' }
          ] },
        { name: 'IPN_PCOMMISSION', label: 'IPN product comission',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN product comission' }
          ] },
        { name: 'IPN_LICENSE_PROD', label: 'IPN license product', type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN license product' }
          ] },
        { name: 'IPN_LICENSE_TYPE', label: 'IPN license type',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN license type' }
          ] },
        { name: 'IPN_LICENSE_REF', label: 'IPN license reference',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN license reference' }
          ] },
        { name: 'IPN_LICENSE_EXP', label: 'IPN license expiration',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN license expiration' }
          ] },
        { name: 'IPN_LICENSE_START', label: 'IPN license start',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN license start' }
          ] },
        { name: 'IPN_LICENSE_LIFETIME', label: 'IPN license lifetime',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN license lifetime' }
          ] },
        { name: 'IPN_LICENSE_ADDITIONAL_INFO',
          label: 'IPN license additional information',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN license addtional information' }
          ] },
        { name: 'IPN_DELIVEREDCODES', label: 'IPN delivered codes',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN delivered code' }
          ] },
        { name: 'IPN_DOWNLOAD_LINK', label: 'IPN download link' },
        { name: 'IPN_BUNDLE_DETAILS', label: 'IPN bundle details',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN bundle details' }
          ] },
        { name: 'IPN_BUNDLE_DELIVEREDCODES', label: 'IPN bundle delivered codes',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN bundle delivered code' }
          ] },
        { name: 'CUSTOM_FIELDS', label: 'Custom fields',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'Custom fields' }
          ] },
        { name: 'IPN_PRODUCT_OPTIONS', label: 'IPN product options',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN product option' }
          ] },
        { name: 'IPN_TOTAL', label: 'IPN total', type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN total' }
          ] },
        { name: 'IPN_TOTALGENERAL', label: 'IPN total general',
          type: 'number', control_type: 'number' },
        { name: 'IPN_SHIPPING', label: 'IPN shipping',
          type: 'number', control_type: 'number' },
        { name: 'IPN_SHIPPING_TAX', label: 'IPN shipping tax',
          type: 'number', control_type: 'number' },
        { name: 'AVANGATE_CUSTOMER_REFERENCE', label: 'Avangate customer reference' },
        { name: 'EXTERNAL_CUSTOMER_REFERENCE', label: 'External customer reference' },
        { name: 'IPN_PARTNER_MARGIN_PERCENT', label: 'IPN partner margin percent',
          type: 'number', control_type: 'number' },
        { name: 'IPN_PARTNER_MARGIN', label: 'IPN partner margin',
          type: 'number', control_type: 'number' },
        { name: 'IPN_EXTRA_MARGIN', label: 'IPN extra margin',
          type: 'number', control_type: 'number' },
        { name: 'IPN_EXTRA_DISCOUNT', label: 'IPN extra discount',
          type: 'number', control_type: 'number' },
        { name: 'IPN_COUPON_DISCOUNT', label: 'IPN coupon discount',
          type: 'number', control_type: 'number' },
        { name: 'IPN_LINK_SOURCE', label: 'IPN link source',
          type: 'string', control_type: 'string' },
        { name: 'IPN_ORIGINAL_LINK_SOURCE', label: 'IPN original link source',
          type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'IPN original link source' }
          ] },
        { name: 'IPN_REFERRER', label: 'IPN referrer' },
        { name: 'IPN_RESELLER_ID', label: 'IPN reseller ID',
          type: 'integer', control_type: 'integer' },
        { name: 'IPN_RESELLER_NAME', label: 'IPN reseller name' },
        { name: 'IPN_RESELLER_URL', label: 'IPN reseller URL' },
        { name: 'IPN_RESELLER_COMMISSION', label: 'IPN reseller commission',
          type: 'number', control_type: 'number' },
        { name: 'IPN_COMMISSION', label: 'IPN commission',
          type: 'number', control_type: 'number' },
        { name: 'REFUND_TYPE', label: 'Refund type' },
        { name: 'REFUND_REASON', label: 'Refund reason' },
        { name: 'CHARGEBACK_RESOLUTION', label: 'Chargeback resolution' },
        { name: 'CHARGEBACK_REASON_CODE', label: 'Chargeback reason code' },
        { name: 'TEST_ORDER', label: 'Test order',
          type: 'integer', control_type: 'integer' },
        { name: 'IPN_PURCHASE_ORDER_INFO', label: 'IPN purchase order information' },
        { name: 'IPN_ORDER_ORIGIN', label: 'IPN order origin' },
        { name: 'VENDOR_CODE', label: 'Vendor code' },
        { name: 'FRAUD_STATUS', label: 'Fruad status' },
        { name: 'MESSAGE_ID', label: 'Message ID',
          type: 'integer', control_type: 'integer' },
        { name: 'MESSAGE_TYPE', label: 'Message type' },
        { name: 'CARD_TYPE', label: 'Card type' },
        { name: 'CARD_LAST_DIGITS', label: 'Card last digits',
          type: 'integer', control_type: 'integer' },
        { name: 'CARD_EXPIRATION_DATE', label: 'Card expiration date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'GATEWAY_RESPONSE', label: 'Gateway response' },
        { name: 'IPN_DATE', label: 'IPN date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'FX_RATE', label: 'FX rate',
          type: 'number', control_type: 'number' },
        { name: 'FX_MARKUP', label: 'FX markup' },
        { name: 'PAYABLE_AMOUNT', label: 'Payable amount',
          type: 'number', control_type: 'number' },
        { name: 'PAYOUT_CURRENCY', label: 'Payout currency' },
        { name: 'PROPOSAL_ID', label: 'Proposal ID' },
        { name: 'HASH', label: 'Hash' }
      ]
    end,

    lcn_trigger_output_schema: lambda do
      [
        { name: 'FIRST_NAME', label: 'First name' },
        { name: 'LAST_NAME', label: 'Last name' },
        { name: 'COMPANY', label: 'Company' },
        { name: 'EMAIL', label: 'Email' },
        { name: 'PHONE', label: 'Phone',
          type: 'integer', control_type: 'integer' },
        { name: 'FAX', label: 'Fax' },
        { name: 'COUNTRY', label: 'Country' },
        { name: 'STATE', label: 'State' },
        { name: 'CITY', label: 'City' },
        { name: 'ZIP', label: 'Zip', type: 'integer', control_type: 'integer' },
        { name: 'ADDRESS', label: 'Address' },
        { name: 'LICENSE_CODE', label: 'License code' },
        { name: 'EXPIRATION_DATE_TIME', label: 'Expiration date time',
          type: 'date_time', control_type: 'date_time' },
        { name: 'EXPIRATION_DATE', label: 'Expiration date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'DATE_UPDATED', label: 'Date updated',
          type: 'date_time', control_type: 'date_time' },
        { name: 'AVANGATE_CUSTOMER_REFERENCE', label: 'Avangate customer reference',
          type: 'integer', control_type: 'integer' },
        { name: 'EXTERNAL_CUSTOMER_REFERENCE', label: 'External customer reference',
          type: 'integer', control_type: 'integer' },
        { name: 'TEST', label: 'Type',
          type: 'integer', control_type: 'integer' },
        { name: 'CHANGED_BY', label: 'Changed by' },
        { name: 'LICENSE_TYPE', label: 'License type' },
        { name: 'DISABLED', label: 'Disabled',
          type: 'integer', control_type: 'integer' },
        { name: 'RECURRING', label: 'Recurring',
          type: 'integer', control_type: 'integer' },
        { name: 'LICENSE_PRODUCT', label: 'License product',
          type: 'integer', control_type: 'integer' },
        { name: 'START_DATE', label: 'Start date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'START_DATE_TIME', label: 'Start date time',
          type: 'date_time', control_type: 'date_time' },
        { name: 'PURCHASE_DATE', label: 'Purchase date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'PURCHASE_DATE_TIME', label: 'Purchase date time',
          type: 'date_time', control_type: 'date_time' },
        { name: 'LICENSE_LIFETIME', label: 'License lifetime',
          type: 'integer', control_type: 'integer' },
        { name: 'BILLING_CYCLES', label: 'Billing cycles',
          type: 'integer', control_type: 'integer' },
        { name: 'CONTRACT_CYCLES', label: 'Contract cycles',
          type: 'integer', control_type: 'integer' },
        { name: 'BILLING_CYCLES_LEFT', label: 'Billing cycles left',
          type: 'integer', control_type: 'integer' },
        { name: 'CURRENT_BILLING_CYCLE', label: 'Current billing cycle',
          type: 'integer', control_type: 'integer' },
        { name: 'NEXT_RENEWAL_DATE', label: 'Next renewal date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'NEXT_RENEWAL_PRICE', label: 'Next renewal price',
          type: 'number', control_type: 'number' },
        { name: 'NEXT_RENEWAL_CURRENCY', label: 'Next renewal currency',
          type: 'number', control_type: 'number' },
        { name: 'NEXT_RENEWAL_PRICE_TYPE', label: 'Next renewal price type' },
        { name: 'NEXT_RENEWAL_PAYMETHOD', label: 'Next renewal payment method' },
        { name: 'NEXT_RENEWAL_PAYMETHOD_CODE', label: 'Next renewal payment method code' },
        { name: 'NEXT_RENEWAL_CARD_LAST_DIGITS', label: 'Next renewal card last digits',
          type: 'integer', control_type: 'integer' },
        { name: 'NEXT_RENEWAL_CARD_TYPE', label: 'Next nenewal card type' },
        { name: 'NEXT_RENEWAL_CARD_EXPIRATION_DATE', label: 'Next renewal card expiration date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'PARTNER_CODE', laebl: 'Partner code' },
        { name: 'AFFILIATE_ID', label: 'Affiliate ID',
          type: 'integer', control_type: 'integer' },
        { name: 'PSKU', label: 'Product SKU' },
        { name: 'ACTIVATION_CODE', label: 'Activation code' },
        { name: 'STATUS', label: 'Status' },
        { name: 'EXPIRED', label: 'Expired',
          type: 'integer', control_type: 'integer' },
        { name: 'TIMEZONE_OFFSET', label: 'Timezone offset' },
        { name: 'LICENSE_GRACE_PERIOD', label: 'License grace period',
          type: 'integer', control_type: 'integer' },
        { name: 'LICENSE_BILLING_TYPE', label: 'License billing type' },
        { name: 'ACTION_AFTER_CYCLES', label: 'Action after cycles' },
        { name: 'USAGE_BILLING_DATE', label: 'Usage billing date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'USAGE_STATUS', label: 'Usage status' },
        { name: 'LATEST_REPORTED_USAGE_DATE', label: 'Latest reported usage date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'COUNTRY_CODE', label: 'Country code' },
        { name: 'END_USER_LANGUAGE', label: 'End user language' },
        { name: 'DISPATCH_REASON', label: 'Dispatch reason' },
        { name: 'LAST_ORDER_REFERENCE', label: 'Last order reference',
          type: 'integer', control_type: 'integer' },
        { name: 'ORIGINAL_ORDER_REFERENCE', label: 'Original order reference',
          type: 'integer', control_type: 'integer' },
        { name: 'LICENSE_PRODUCT_CODE', label: 'License product code' },
        { name: 'LCN_LICENSE_ADDITIONAL_INFO_CUSTOM_VALUE',
          label: 'LCN License additional information custom value' },
        { name: 'PAUSE_START_DATE', label: 'Pause start date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'PAUSE_END_DATE', label: 'Pause end date',
          type: 'date_time', control_type: 'date_time' },
        { name: 'PAUSE_REASON', label: 'Pause reason' },
        { name: 'RENEWALS_NUMBER', label: 'Renewals number',
          type: 'integer', control_type: 'integer' },
        { name: 'UPGRADES_NUMBER', label: 'Upgraded number',
          type: 'integer', control_type: 'integer' },
        { name: 'IS_TRIAL', label: 'Is trial',
          type: 'integer', control_type: 'integer' },
        { name: 'MERCHANT_DEAL_AUTO_RENEWAL', label: 'Merchant deal auto renewal', type: 'boolean', control_type: 'checkbox', render_input: 'boolean_conversion', parse_ouput: 'boolean_conversion' },
        { name: 'CLIENT_DEAL_AUTO_RENEWAL', label: 'Client deal auto renewal', type: 'boolean', control_type: 'checkbox', render_input: 'boolean_conversion', parse_ouput: 'boolean_conversion' },
        { name: 'HASH', label: 'Hash' }
      ]
    end,

    pricing: lambda do
      [
        { name: 'name' },
        { name: 'code' },
        { name: 'default', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'billing_countries', type: 'array', of: 'object', properties: [
          { name: 'value' }
        ] },
        { name: 'use_original_prices' },
        { name: 'pricing_schema' },
        { name: 'price_type' },
        { name: 'default_currency' },
        { name: 'prices', type: 'object', properties: [
          { name: 'regular', type: 'array', of: 'object', properties: [
            { name: 'amount', type: 'integer', control_type: 'integer' },
            { name: 'currency' },
            { name: 'min_quantity', label: 'Minimum quantity',
              type: 'integer', control_type: 'integer' },
            { name: 'max_quantity', label: 'Maximum quantity',
              type: 'integer', control_type: 'integer' },
            { name: 'option_codes', type: 'array', of: 'object', properties: [
              { name: 'code' },
              { name: 'options', type: 'array', of: 'object', properties: [
                { name: 'value' }
              ] }
            ] }
          ] },
          { name: 'renewal', type: 'array', of: 'object', properties: [
            { name: 'amount', type: 'integer', control_type: 'integer' },
            { name: 'currency' },
            { name: 'min_quantity', label: 'Minimum quantity',
              type: 'integer', control_type: 'integer' },
            { name: 'max_quantity', laebl: 'Maximum quantity',
              type: 'integer', control_type: 'integer' },
            { name: 'option_codes', type: 'array', of: 'object', properties: [
              { name: 'code' },
              { name: 'options', type: 'array', of: 'object', properties: [
                { name: 'value' }
              ] }
            ] }
          ] }
        ] },
        { name: 'price_options', properties: [
          { name: 'code' },
          { name: 'required', type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' }
        ] }
      ]
    end,

    renewal: lambda do
      [
        { name: 'before30_days', label: 'Before 30 days',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'before15_days', label: 'Before 15 days',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'before7_days', label: 'Before 7 days',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'before1_day', label: 'Before 1 day',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'on_expiration_date', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'after5_days', label: 'After 5 days',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'after15_days', label: 'After 15 days',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' }
      ]
    end,

    item: lambda do
      [
        { name: 'item_name' },
        { name: 'item_id' },
        { name: 'item_list_amount', type: 'number', control_type: 'number' },
        { name: 'item_usd_amount', label: 'Item USD amount',
          type: 'number', control_type: 'number' },
        { name: 'item_cust_amount', label: 'Item customer amount',
          type: 'number', control_type: 'number' },
        { name: 'item_type' },
        { name: 'item_duration' }
      ]
    end,

    recurrence: lambda do
      [
        { name: 'item_recurrence' },
        { name: 'item_rec_list_amount',
          label: 'Item recurring list amount',
          type: 'number',
          control_type: 'number' },
        { name: 'item_rec_status', label: 'Item recurring status' },
        { name: 'item_rec_date_next',
          label: 'Item recurring date next',
          type: 'date_time',
          control_type: 'date_time' },
        { name: 'item_rec_install_billed',
          label: 'Item recurring install billed',
          type: 'integer',
          control_type: 'integer' }
      ]
    end,

    ins_event_schema: lambda do
      [
        { name: 'sale_id', type: 'integer', control_type: 'integer' },
        { name: 'sale_date_placed',
          type: 'date_time',
          control_type: 'date_time' },
        { name: 'recurring', type: 'integer', control_type: 'integer' },
        { name: 'payment_type' },
        { name: 'list_currency' },
        { name: 'fraud_status' },
        { name: 'order_ref', label: 'Order reference',
          type: 'integer', control_type: 'integer' },
        { name: 'order_no', label: 'Order number',
          type: 'integer', control_type: 'integer' },
        { name: 'vendor_id' },
        { name: 'vendor_order_id' },
        { name: 'invoice_status' },
        { name: 'invoice_list_amount', type: 'number', control_type: 'number' },
        { name: 'invoice_usd_amount', label: 'Invoice USD amount',
          type: 'number', control_type: 'number' },
        { name: 'invoice_cust_amount', label: 'Invoice customer amount',
          type: 'number', control_type: 'number' },
        { name: 'auth_exp', label: 'Authorization expiration',
          type: 'date_time', control_type: 'date_time' },
        { name: 'customer_first_name' },
        { name: 'customer_last_name' },
        { name: 'customer_name' },
        { name: 'customer_email' },
        { name: 'customer_phone', type: 'integer', control_type: 'integer' },
        { name: 'customer_ip', label: 'Customer IP' },
        { name: 'customer_ip_country', label: 'Customer IP country' },
        { name: 'cust_currency', label: 'Customer currency' },
        { name: 'bill_city' },
        { name: 'bill_country' },
        { name: 'bill_postal_code', type: 'integer', control_type: 'integer' },
        { name: 'bill_state' },
        { name: 'bill_street_address' },
        { name: 'bill_street_address2' },
        { name: 'ship_status' },
        { name: 'ship_tracking_number',
          type: 'integer',
          control_type: 'integer' },
        { name: 'ship_name' },
        { name: 'ship_street_address' },
        { name: 'ship_street_address2' },
        { name: 'ship_city' },
        { name: 'ship_state' },
        { name: 'ship_postal_code', type: 'integer', control_type: 'integer' },
        { name: 'ship_country' },
        { name: 'message_id', type: 'integer', control_type: 'integer' },
        { name: 'item_count', type: 'integer', control_type: 'integer' },
        { name: 'invoice_id' }
      ]
    end,

    proposal_schema: lambda do
      [
        { name: 'proposal_id' },
        { name: 'name' },
        { name: 'type' },
        { name: 'version', type: 'integer', control_type: 'integer' },
        { name: 'status' },
        { name: 'scope' },
        { name: 'status_comment' },
        { name: 'expiration_date',
          type: 'date_time',
          control_type: 'date_time' },
        { name: 'created_date', type: 'date_time', control_type: 'date_time' },
        { name: 'updated_date', type: 'date_time', control_type: 'date_time' },
        { name: 'created_by' },
        { name: 'updated_by' },
        { name: 'locked', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'source' },
        { name: 'content', type: 'object', properties: [
          { name: 'language' },
          { name: 'currency' },
          { name: 'terms', type: 'integer', control_type: 'integer' },
          { name: 'line_items', type: 'array', of: 'object', properties: [
            { name: 'product_name' },
            { name: 'product_code' },
            { name: 'quantity', type: 'integer', control_type: 'integer' },
            { name: 'price', type: 'number', control_type: 'number' },
            { name: 'subscription_reference', type: 'string', control_type: 'string' },
            { name: 'proration_date', type: 'date_time', control_type: 'date_time' },
            { name: 'next_contract_renewal_period', type: 'integer', control_type: 'integer' },
            { name: 'amendment_scenario', type: 'string', control_type: 'string' },
            { name: 'merchant_deal_auto_renewal', type: 'boolean', control_type: 'checkbox', render_input: 'boolean_conversion', parse_ouput: 'boolean_conversion' },
            { name: 'client_deal_auto_renewal', type: 'boolean', control_type: 'checkbox', render_input: 'boolean_conversion', parse_ouput: 'boolean_conversion' },
            { name: 'discounted_price',
              type: 'number',
              control_type: 'number' },
            { name: 'price_type' },
            { name: 'contract_period',
              type: 'integer', control_type: 'integer' },
            { name: 'immediate_action',
              type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_ouput: 'boolean_conversion' },
            { name: 'billing_cycle', type: 'object', properties: [
              { name: 'unit' },
              { name: 'value', type: 'integer', control_type: 'integer' }
            ] },
            { name: 'additional_fields', type: 'array', of: 'object',
              properties: [
                { name: 'code' },
                { name: 'value' }
              ] },
            { name: 'price_options', type: 'array', of: 'object', properties: [
              { name: 'group_code' },
              { name: 'group_options', type: 'array', of: 'object',
                properties: [
                  { name: 'value' }
                ] }
            ] }
          ] },
          { name: 'additional_fields', type: 'array', of: 'object',
            properties: [
              { name: 'code' },
              { name: 'value' }
            ] }
        ] },
        { name: 'bill_to', type: 'object', properties: [
          { name: 'company' },
          { name: 'email', control_type: 'email' },
          { name: 'first_name' },
          { name: 'last_name' },
          { name: 'phone', control_type: 'phone' },
          { name: 'country' },
          { name: 'state' },
          { name: 'city' },
          { name: 'zip' },
          { name: 'address' }
        ] },
        { name: 'sell_to', type: 'object', properties: [
          { name: 'company' },
          { name: 'email', control_type: 'email' },
          { name: 'first_name' },
          { name: 'last_name' },
          { name: 'phone', control_type: 'phone' },
          { name: 'country' },
          { name: 'state' },
          { name: 'city' },
          { name: 'zip' },
          { name: 'tax_exemption_id', type: 'string', control_type: 'string' },
          { name: 'vat_code', type: 'string', control_type: 'string' },
          { name: 'address' }
        ] },
        { name: 'tac', type: 'object', properties: [
          { name: 'content' },
          { name: 'accepted_date',
            type: 'date_time', control_type: 'date_time' }
        ] },
        { name: 'sent_by', type: 'object', properties: [
          { name: 'first_name' },
          { name: 'last_name' },
          { name: 'email', control_type: 'email' }
        ] },
        { name: 'links', type: 'array', of: 'object', properties: [
          { name: 'id' },
          { name: 'url' },
          { name: 'status' },
          { name: 'pdf', label: 'PDF' }
        ] }
      ]
    end,

    catalogue_product_schema: lambda do
      [
        { name: 'avangate_id' },
        { name: 'enabled', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'fulfillment' },
        { name: 'fulfillment_information', type: 'object', properties: [
          { name: 'is_starts_after_fulfillment',
            type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'is_electronic_code',
            type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'is_download_link',
            type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'is_backup_media',
            type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'is_download_insurance_service',
            type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'is_instant_delivery_thankyou_page',
            type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'is_display_in_partner_cpanel',
            type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'return_method', type: 'object', properties: [
            { name: 'type' },
            { name: 'url' }
          ] },
          { name: 'code_list', type: 'object', properties: [
            { name: 'code' },
            { name: 'name' },
            { name: 'type' }
          ] },
          { name: 'backup_media', type: 'object', properties: [
            { name: 'code' },
            { name: 'name' },
            { name: 'type' }
          ] },
          { name: 'product_file', type: 'object', properties: [
            { name: 'code' },
            { name: 'name' },
            { name: 'type' },
            { name: 'file' },
            { name: 'version' },
            { name: 'size' },
            { name: 'last_update' },
            { name: 'additional_information_by_email' },
            { name: 'additional_information_email_translations',
              type: 'array', of: 'object', properties: [
                { name: 'value' }
              ] },
            { name: 'additional_thankyou_page' },
            { name: 'additional_thankyou_page_translations',
              type: 'array', of: 'object', properties: [
                { name: 'value' }
              ] }
          ] }
        ] },
        { name: 'generates_subscription',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'gift_option', type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'product_group', type: 'object', properties: [
          { name: 'name' },
          { name: 'code' },
          { name: 'description' },
          { name: 'template_name' }
        ] },
        { name: 'long_description' },
        { name: 'platforms', type: 'array', of: 'object', properties: [
          { name: 'platform_name' },
          { name: 'category' }
        ] },
        { name: 'prices', type: 'object', properties: [
          { name: 'amount', type: 'integer', control_type: 'integer' },
          { name: 'currency' },
          { name: 'min_quantity', label: 'Maximum quantity',
            type: 'integer', control_type: 'integer' },
          { name: 'max_quantity', label: 'Minimum quantity',
            type: 'integer', control_type: 'integer' },
          { name: 'option_codes', type: 'array', of: 'object', properties: [
            { name: 'code' },
            { name: 'options', type: 'array', of: 'object', properties: [
              { name: 'value' }
            ] }
          ] }
        ] },
        { name: 'pricing_configurations', type: 'array', of: 'object',
          properties: call('pricing') },
        { name: 'product_category' },
        { name: 'product_code' },
        { name: 'product_images', type: 'array', of: 'object', properties: [
          { name: 'default', type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'url' }
        ] },
        { name: 'product_name' },
        { name: 'product_type' },
        { name: 'product_version' },
        { name: 'purchase_multiple_units',
          type: 'boolean', control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_ouput: 'boolean_conversion' },
        { name: 'shipping_class', type: 'object', properties: [
          { name: 'name' },
          { name: 'amount', type: 'number', control_type: 'number' },
          { name: 'currency' },
          { name: 'apply_to' },
          { name: 'type' }
        ] },
        { name: 'short_description' },
        { name: 'subscription_information', type: 'object', properties: [
          { name: 'deprecated_products', type: 'array', of: 'object',
            properties: [
              { name: 'value' }
            ] },
          { name: 'bundle_renewal_management' },
          { name: 'billing_cycle' },
          { name: 'billing_cycle_units' },
          { name: 'is_one_time_fee', type: 'boolean', control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_ouput: 'boolean_conversion' },
          { name: 'contract_period', type: 'object', properties: [
            { name: 'action' },
            { name: 'emails_during_contract',
              type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_ouput: 'boolean_conversion' },
            { name: 'period', type: 'integer', control_type: 'integer' },
            { name: 'period_units' },
            { name: 'is_unlimited', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_ouput: 'boolean_conversion' }
          ] },
          { name: 'usage_billing', type: 'integer', control_type: 'integer' },
          { name: 'grace_period', type: 'object', properties: [
            { name: 'type' },
            { name: 'period_units' },
            { name: 'period' },
            { name: 'is_unlimited', type: 'boolean', control_type: 'checkbox',
              render_input: 'boolean_conversion',
              parse_ouput: 'boolean_conversion' }
          ] },
          { name: 'renewal_emails', type: 'object', properties: [
            { name: 'type' },
            { name: 'settings', type: 'object', properties: [
              { name: 'manual_renewal', type: 'object',
                properties: call('renewal') },
              { name: 'automatic_renewal', type: 'object',
                properties: call('renewal') }
            ] }
          ] }
        ] },
        { name: 'trial_description' },
        { name: 'trial_url' }
      ]
    end,

    format_response: lambda do |output|
      output&.each do |key, value|
        if value.is_a?(Array)
          output[key] =
            value&.map do |val|
              { 'value' => val } if val.is_a?(String)
            end
        else
          value
        end
      end
    end,

    format_ins_response: lambda do |output|
      if output.is_a?(Array)
        output.map { |obj| call('format_ins_response', obj) }
      elsif output.is_a?(Hash)
        output.each do |key, value|
          output[key] =
            if ['platforms', 'regular', 'pricing_configurations', 'product_images'].include?(key)
              call('format_ins_response', value.values)
            elsif ['additional_information_email_translations', 'additional_thankyou_page_translations',
                   'billing_countries', 'options', 'deprecated_products', 'group_options'].include?(key)
              call('format_response', key => value)[key] # to format array of strings into array of hashes
            else
              call('format_ins_response', value)
            end
        end
      else
        output
      end
    end
  },

  object_definitions: {
    ipn_trigger_output_schema: {
      fields: lambda do |_connection|
        call('ipn_trigger_output_schema')
      end
    },

    lcn_trigger_output_schema: {
      fields: lambda do |_connection|
        call('lcn_trigger_output_schema')
      end
    },

    ins_trigger_output_schema: {
      fields: lambda do |_connection, config_fields|
        schema = [
          { name: 'message_type' },
          { name: 'message_description' },
          { name: 'timestamp', type: 'date_time', control_type: 'date_time' },
          { name: 'md5_hash' },
          { name: 'key_count' }
        ]
        next schema if config_fields.blank?

        fields = config_fields['field_list'].split(',')
        schema.concat(fields.map do |field|
          if ['catalogue_product_created', 'catalogue_product_updated'].include?(field)
            call('catalogue_product_schema')
          elsif field == 'proposal_updated'
            call('proposal_schema')
          elsif field == 'proposal_created'
            call('proposal_schema')
          else
            call('ins_event_schema')
          end
        end.flatten)
        fields = fields - %w[catalogue_product_created catalogue_product_updated proposal_updated proposal_created]
        if fields.length > 0
          items = unless fields.length == 1 && fields[0] == 'order_created'
                    call('recurrence')
                  end || []
          schema.concat(
            [{ name: 'items', type: 'array', of: 'object',
               properties: items.concat(call('item')) }]
          )
        end
        schema
      end
    }
  },

  test: lambda do |_connection|
    true
  end,

  webhook_keys: lambda do |_params, _headers, payload|
    if payload['LICENSE_CODE'].present?
      'LCN'
    elsif payload['IPN_PID']
      'IPN'
    else
      'INS'
    end
  end,

  triggers: {
    ipn_webhook: {
      title: 'IPN webhooks',
      subtitle: 'Triggers when the details of an order is changed in 2checkout',
      description: lambda do |_connection, _input|
        "<span class='provider'>IPN</span> webhooks in " \
        "<span class='provider'>2checkout</span>"
      end,
      help: {
        learn_more_url: 'https://knowledgecenter.2checkout.com/API-Integration/Webhooks/06Instant_Payment_Notification_(IPN)',
        learn_more_text: 'Learn to setup realtime triggers',
        body: <<-HTML
              This trigger requires endpoint setup in 2checkout with the webhook endpoint URL.
              <br/><br/><b>Endpoint URL</b>
        HTML
      },

      webhook_key: lambda do |_connection, _input|
        'IPN'
      end,

      webhook_notification: lambda do |_input, payload, _e_i_s, _e_o_s, _headers|
        if payload['HASH'].present? && payload['MESSAGE_ID'].present?
          payload&.each do |key, value|
            if value.is_a?(Array)
              payload[key] =
                value&.map do |val|
                  { 'value' => val } if val.is_a?(String)
                end
            else
              value
            end
          end
        else
          {}
        end
      end,

      dedup: lambda do |event|
        "#{event['HASH']}#{event['MESSAGE_ID']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['ipn_trigger_output_schema']
      end,

      sample_output: lambda do
        {
          GIFT_ORDER: 0,
          SALEDATE: '2020-12-14T13:17:09.000000-08:00',
          PAYMENTDATE: '2020-12-14T13:17:14.000000-08:00',
          REFNO: 139_669_255,
          ORDERNO: 189,
          ORDERSTATUS: 'COMPLETE',
          PAYMETHOD: 'Visa/MasterCard',
          PAYMETHOD_CODE: 'CCVISAMC',
          FIRSTNAME: 'John',
          LASTNAME: 'Joseph'
        }
      end
    },
    lcn_webhook: {
      title: 'LCN webhooks',
      subtitle: 'Triggers when the details of a license is changed in 2checkout',
      description: lambda do |_connection, _input|
        "<span class='provider'>LCN</span> webhooks in " \
        "<span class='provider'>2checkout</span>"
      end,
      help: {
        learn_more_url: 'https://knowledgecenter.2checkout.com/API-Integration/Webhooks/08License_Change_Notification_(LCN)',
        learn_more_text: 'Learn to setup realtime triggers',
        body: <<-HTML
              This trigger requires endpoint setup in 2checkout with the webhook endpoint URL.
              <br/><br/><b>Endpoint URL</b>
        HTML
      },

      webhook_key: lambda do |_connection, _input|
        'LCN'
      end,

      webhook_notification: lambda do |_input, payload, _e_i_s, _e_o_s, _headers|
        if payload['HASH'].present? && payload['DATE_UPDATED'].present?
          payload['CLIENT_DEAL_AUTO_RENEWAL'] = ['true', 1, '1', true].include?(payload['CLIENT_DEAL_AUTO_RENEWAL'])
          payload['MERCHANT_DEAL_AUTO_RENEWAL'] = ['true', 1, '1', true].include?(payload['MERCHANT_DEAL_AUTO_RENEWAL'])
          payload
        else
          {}
        end
      end,

      dedup: lambda do |event|
        "#{event['HASH']}#{event['DATE_UPDATED']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lcn_trigger_output_schema']
      end,

      sample_output: lambda do
        {
          FIRST_NAME: 'John',
          LAST_NAME: 'Joseph',
          COMPANY: 'Workato',
          EMAIL: 'john.joseph@example.com',
          PHONE: '987654321',
          COUNTRY: 'United States of America',
          STATE: 'Texas',
          CITY: 'Houston',
          ZIP: '770_32',
          ADDRESS: '123',
          LICENSE_CODE: 'WMQSFOS6V9'
        }
      end
    },
    ins_webhook: {
      title: 'INS webhooks',
      subtitle: 'Triggers when the events configured in trigger list occurs in 2checkout',
      description: lambda do |_connection, _input|
        "<span class='provider'>INS</span> webhooks in " \
        "<span class='provider'>2checkout</span>"
      end,
      help: {
        learn_more_url: 'https://knowledgecenter.2checkout.com/API-Integration/Webhooks/Instant-Notification-Service-(INS)',
        learn_more_text: 'Learn to setup realtime triggers',
        body: <<-HTML
              This trigger requires endpoint setup in 2checkout with the webhook endpoint URL.
              <br/><br/><b>Endpoint URL</b>
        HTML
      },
      config_fields: [
        { name: 'field_list',
          control_type: 'multiselect',
          label: 'Trigger list',
          optional: false,
          pick_list: :get_fields_pick_list,
          sticky: true,
          delimiter: ',',
          extends_schema: true,
          hint: "Select the events configured in the 'Trigger list' in " \
            '2checkout. The output fields are generated only ' \
            'for the selected trigger list.' }
      ],

      webhook_key: lambda do |_connection, _input|
        'INS'
      end,

      webhook_notification: lambda do |input, payload, _e_i_s, _e_o_s, _headers|
        if input['field_list']&.split(',')&.include?(payload['message_type']&.downcase)
          if %w[CATALOGUE_PRODUCT_CREATED CATALOGUE_PRODUCT_UPDATED
                PROPOSAL_UPDATED PROPOSAL_CREATED].include?(payload['message_type'])
            payload.each do |key, value|
              payload[key] = if value.is_a?(Array)
                               value.map do |obj|
                                 obj.each do |key1, value1|
                                   obj[key1] = if value1.is_a?(Array)
                                                 value1
                                               elsif value1.is_a?(Hash)
                                                 if ['platforms', 'regular', 'pricing_configurations', 'product_images'].include?(key)
                                                   value1.values
                                                 elsif ['additional_information_email_translations', 'additional_thankyou_page_translations',
                                                        'billing_countries', 'options', 'deprecated_products', 'group_options'].include?(key)
                                                   value1.map { |val| { key1 => val } } # to format array of strings into array of hashes
                                                 else
                                                   value1
                                                 end
                                               else
                                                 value1
                                               end
                                 end
                               end
                             elsif value.is_a?(Hash)
                               if ['platforms', 'regular', 'pricing_configurations', 'product_images'].include?(key)
                                 value.values
                               elsif ['additional_information_email_translations', 'additional_thankyou_page_translations',
                                      'billing_countries', 'options', 'deprecated_products', 'group_options'].include?(key)
                                 value.map { |val| { key => val } } # to format array of strings into array of hashes
                               elsif ['content', 'links'].include?(key)
                                 if key == 'links'
                                   value.values
                                 elsif value['line_items'].present?
                                   value['line_items'] = value.dig('line_items')&.
                                     map do |_item_key, item_value|
                                     if item_value['price_options'].present?
                                       item_value['price_options'] = item_value['price_options'].
                                         map do |_option_key, option_value|
                                           if option_value['group_options'].present?
                                             option_value['group_options'] = option_value['group_options'].values.
                                               map { |item| { value: item } }
                                           end
                                         option_value
                                       end
                                     end
                                     item_value
                                   end
                                   value
                                 end
                               else
                                 value.each do |key1, value1|
                                   value[key1] = if value1.is_a?(Array)
                                                   value1.map do |obj|
                                                   end
                                                 elsif value1.is_a?(Hash)
                                                   if ['platforms', 'regular', 'pricing_configurations', 'product_images'].include?(key)
                                                     value1.values
                                                   elsif ['additional_information_email_translations', 'additional_thankyou_page_translations',
                                                          'billing_countries', 'options', 'deprecated_products', 'group_options'].include?(key)
                                                     value1.map { |val| { key1 => val } } # to format array of strings into array of hashes
                                                   else
                                                     value1
                                                   end
                                                 else
                                                   value1
                                                 end
                                 end
                               end
                             else
                               value
                             end
            end
            payload
          else
            items = []
            (0...(payload['item_count'].to_i)).to_a.each do |index|
              items << payload.select { |key, _val| key.match?(/^item_.*_#{index + 1}+$/) }&.
                each_with_object({}) do |(key, value), hash|
                  hash[key.gsub("_#{index + 1}", '')] = value
                end
            end
            payload.reject { |key, _val| key.match?(/^item_.*_[0-9]+$/) }&.merge({ 'items' => items })
          end
        end
      end,

      dedup: lambda do |_event|
        Time.now.utc
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['ins_trigger_output_schema']
      end,

      sample_output: lambda do
        {
          sale_id: 250_647_843_257,
          sale_date_placed: '2020-12-14T13:17:09.000000-08:00',
          recurring: 1,
          payment_type: 'credit card',
          list_currency: 'USD',
          fraud_status: 'wait',
          order_ref: 139_669_255,
          order_no: 0,
          vendor_id: 'WWWWORKA',
          invoice_id: '250647843256',
          invoice_status: 'approved'
        }
      end
    }
  },

  pick_lists: {
    get_fields_pick_list: lambda do |_connection|
      [
        ['Order created', 'order_created'],
        ['Fraud status changed', 'fraud_status_changed'],
        ['Shipping status changed', 'shipping_status_changed'],
        ['Invoice status changed', 'invoice_status_changed'],
        ['Refund issued', 'refund_issued'],
        ['Recurring installment success', 'recurring_installment_success'],
        ['Recurring installment failed', 'recurring_installment_failed'],
        ['Recurring stopped', 'recurring_stopped'],
        ['Recurring complete', 'recurring_complete'],
        ['Recurring restarted', 'recurring_restarted'],
        ['Catalogue product created', 'catalogue_product_created'],
        ['Catalogue product update', 'catalogue_product_updated'],
        ['Proposal updated', 'proposal_updated'],
        ['Proposal created', 'proposal_created']
      ]
    end
  }
}
