{
  title: 'checkout',
  connection: {
    fields: [
      {
        name: 'merchant_code',
        optional: true,
        hint: "Click <a href='https://secure.2checkout.com/cpanel/" \
        "webhooks_api.php' target='_blank'>to find merchant code</a>."
      },
      {
        name: 'secret',
        optional: true,
        control_type: 'password',
        hint: "Click <a href='https://secure.2checkout.com/cpanel/" \
        "webhooks_api.php' target='_blank'>to find secret key</a>."
      }
    ],
    authorization: {}
  },
  test: lambda do |_connection|
    true
  end,
  methods: {
    sample_ipn_output: lambda do
      {
        'GIFT_ORDER': '0',
        'SALEDATE': '2019-04-14 12:52:37',
        'PAYMENTDATE': '2019-04-14 12:52:48',
        'REFNO': '94391473',
        'ORDERNO': '70',
        'ORDERSTATUS': 'COMPLETE',
        'PAYMETHOD': 'Visa/MasterCard',
        'PAYMETHOD_CODE': 'CCVISAMC',
        'FIRSTNAME': 'Samue',
        'LASTNAME': 'John',
        'ADDRESS1': '1232920',
        'ADDRESS2': 'Ohio',
        'CITY': 'Townsville',
        'STATE': 'Ohio',
        'ZIPCODE': '43206',
        'COUNTRY': 'United States of America',
        'COUNTRY_CODE': 'us',
        'CUSTOMEREMAIL': 'chandra@workato.com',
        'FIRSTNAME_D': 'Samue',
        'LASTNAME_D': 'John',
        'ADDRESS1_D': '1232920',
        'ADDRESS2_D': 'Ohio',
        'CITY_D': 'Townsville',
        'STATE_D': 'Ohio',
        'ZIPCODE_D': '43206',
        'COUNTRY_D': 'United States of America',
        'COUNTRY_D_CODE': 'us',
        'EMAIL_D': 'chandra@workato.com',
        'IPADDRESS': '122.182.214.88',
        'IPCOUNTRY': 'India',
        'COMPLETE_DATE': '2019-04-14 12:53:07',
        'TIMEZONE_OFFSET': 'GMT+03:00',
        'CURRENCY': 'USD',
        'LANGUAGE': 'en',
        'ORDERFLOW': 'REGULAR',
        'AVANGATE_CUSTOMER_REFERENCE': '631448417',
        'IPN_PARTNER_MARGIN_PERCENT': '0',
        'IPN_PARTNER_MARGIN': 0,
        'IPN_EXTRA_MARGIN': 0,
        'IPN_EXTRA_DISCOUNT': 0,
        'IPN_COUPON_DISCOUNT': 0,
        'IPN_REFERRER': 'https://secure.2checkout.com/cpanel/integration.php',
        'IPN_RESELLER_ID': 0,
        'IPN_RESELLER_COMMISSION': 0,
        'IPN_COMMISSION': 0.6,
        'CHARGEBACK_RESOLUTION': 'NONE',
        'TEST_ORDER': 1,
        'IPN_ORDER_ORIGIN': 'Web',
        'FRAUD_STATUS': 'APPROVED',
        'CARD_TYPE': 'visa',
        'CARD_LAST_DIGITS': '1111',
        'CARD_EXPIRATION_DATE': '04/20',
        'GATEWAY_RESPONSE': 'Approved',
        'IPN_DATE': '2019-04-14',
        'FX_RATE': 1,
        'FX_MARKUP': 0,
        'PAYABLE_AMOUNT': '4.9',
        'PAYOUT_CURRENCY': 'USD',
        'HASH': '5fc403c7e2a7b3b556add8fa910dba56',
        'IPN_ITEMS':
          [
            {
              'IPN_PID': 21685386,
              'IPN_PNAME': 'Sophos 9.0',
              'IPN_PCODE': '41BDF79363',
              'IPN_QTY': 5,
              'IPN_PRICE': 0.4,
              'IPN_VAT': '0.15',
              'IPN_VAT_RATE': '7.5',
              'IPN_DISCOUNT': 0,
              'IPN_ORDER_COSTS': 0,
              'IPN_PARTNER_CODE': 'null',
              'IPN_PGROUP': '81272',
              'IPN_PGROUP_NAME': 'General',
              'IPN_PCOMMISSION': 0,
              'IPN_LICENSE_PROD': 21685386,
              'IPN_LICENSE_TYPE': 'REGULAR',
              'IPN_LICENSE_REF': 'BC9ADC1D4C',
              'IPN_LICENSE_EXP': '9999-12-31 23:59:59',
              'IPN_LICENSE_START': '2019-04-14 12:52:48',
              'IPN_LICENSE_LIFETIME': 'YES',
              'IPN_ORIGINAL_LINK_SOURCE': 'null'
            }
          ]
      }
    end,
    sample_lcn_output: lambda do
      {
        'FIRST_NAME': 'Joe',
        'LAST_NAME': 'Flagster',
        'EMAIL': 'ayra.arellano@workato.com',
        'COUNTRY': 'United States of America',
        'STATE': 'Ohio',
        'CITY': 'Townsville',
        'ZIP': '43206',
        'ADDRESS': '123 Main Street',
        'LICENSE_CODE': 'AD42B977BE',
        'EXPIRATION_DATE_TIME': '9999-12-31 23:59:59',
        'EXPIRATION_DATE': '9999-12-31',
        'DATE_UPDATED': '2019-03-21 07:57:13',
        'AVANGATE_CUSTOMER_REFERENCE': '628406963',
        'TEST': '1',
        'CHANGED_BY': 'CUSTOMER',
        'LICENSE_TYPE': 'REGULAR',
        'DISABLED': '0',
        'RECURRING': '0',
        'LICENSE_PRODUCT': '19674915',
        'START_DATE': '2019-03-21',
        'START_DATE_TIME': '2019-03-21 07:57:13',
        'PURCHASE_DATE': '2019-03-21',
        'PURCHASE_DATE_TIME': '2019-03-21 07:57:13',
        'LICENSE_LIFETIME': '1',
        'CONTRACT_CYCLES': '1',
        'NEXT_RENEWAL_PAYMETHOD': 'Visa/MasterCard',
        'NEXT_RENEWAL_PAYMETHOD_CODE': 'CCVISAMC',
        'NEXT_RENEWAL_CARD_LAST_DIGITS': '1111',
        'NEXT_RENEWAL_CARD_TYPE': 'visa',
        'NEXT_RENEWAL_CARD_EXPIRATION_DATE': '03/2025',
        'AFFILIATE_ID': '0',
        'STATUS': 'ACTIVE',
        'EXPIRED': '0',
        'TIMEZONE_OFFSET': 'GMT+02:00',
        'LICENSE_GRACE_PERIOD': '0',
        'LICENSE_BILLING_TYPE': 'PREPAID',
        'ACTION_AFTER_CYCLES': 'NONE',
        'COUNTRY_CODE': 'us',
        'END_USER_LANGUAGE': 'en',
        'DISPATCH_REASON': 'LICENCE_CHANGE',
        'LAST_ORDER_REFERENCE': '92402153',
        'ORIGINAL_ORDER_REFERENCE': '92402153',
        'LICENSE_PRODUCT_CODE': '86A487139B',
        'RENEWALS_NUMBER': '0',
        'UPGRADES_NUMBER': '0',
        'IS_TRIAL': '0',
        'HASH': 'bf0a192b18deaa6a4a7f50a3fd829116'
      }
    end
  },
  object_definitions: {
    ipn: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'GIFT_ORDER', label: 'Gift Order', type: 'integer' },
          { name: 'SALEDATE', label: 'Sale Date' },
          { name: 'PAYMENTDATE', label: 'Payment Date' },
          { name: 'REFNO', label: 'Reference Number', type: 'integer' },
          { name: 'REFNOEXT', label: 'External Reference Number' },
          { name: 'ORIGINAL_REFNOEXT',
            label: 'Original External Reference No.' },
          { name: 'SHOPPER_REFERENCE_NUMBER', label: 'Shopper Reference No.' },
          { name: 'ORDERNO', label: 'Order Number', type: 'integer' },
          { name: 'ORDERSTATUS', label: 'Order Status' },
          { name: 'PAYMETHOD', label: 'Payment Method' },
          { name: 'PAYMETHOD_CODE', label: 'Payment Method Code' },
          { name: 'COMPLETE_DATE', label: 'Complete Date' }
        ]
      end
    },
    customer_billing: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'FIRSTNAME', label: 'First Name' },
          { name: 'LASTNAME', label: 'Last Name' },
          { name: 'COMPANY', label: 'Company' },
          { name: 'REGISTRATIONNUMBER', label: 'Registration Number' },
          { name: 'FISCALCODE', label: 'Fiscal Code' },
          { name: 'TAX_OFFICE', label: 'Tax Office' },
          { name: 'CBANKNAME', label: 'Company Bank Name' },
          { name: 'CBANKACCOUNT', label: 'Company Bank Account' },
          { name: 'ADDRESS1', label: 'Address 1' },
          { name: 'ADDRESS2', label: 'Address 2' },
          { name: 'CITY', label: 'City' },
          { name: 'STATE', label: 'State' },
          { name: 'ZIPCODE', label: 'Zip Code' },
          { name: 'COUNTRY', label: 'Country' },
          { name: 'COUNTRY_CODE', label: 'Country Code' },
          { name: 'PHONE', label: 'Phone' },
          { name: 'FAX', label: 'Fax' },
          { name: 'CUSTOMEREMAIL', label: 'Customer Email' }
        ]
      end
    },
    customer_delivery: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'FIRSTNAME_D', label: 'First Name' },
          { name: 'LASTNAME_D', label: 'Last Name' },
          { name: 'COMPANY_D', label: 'Company' },
          { name: 'ADDRESS1_D', label: 'Address 1' },
          { name: 'ADDRESS2_D', label: 'Address 2' },
          { name: 'CITY_D', label: 'City' },
          { name: 'STATE_D', label: 'State' },
          { name: 'ZIPCODE_D', label: 'Zip Code' },
          { name: 'COUNTRY_D', label: 'Country' },
          { name: 'COUNTRY_D_CODE', label: 'Country Code' },
          { name: 'PHONE_D', label: 'Phone' },
          { name: 'EMAIL_D', label: 'Email' },
          { name: 'IPADDRESS', label: 'IP Address' },
          { name: 'IPCOUNTRY', label: 'Country by IP' }
        ]
      end
    },
    customer_order: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'TIMEZONE_OFFSET', label: 'Timezone Offset' },
          { name: 'CURRENCY', label: 'Currency' },
          { name: 'LANGUAGE', label: 'Language' },
          { name: 'ORDERFLOW', label: 'Orderflow' },
          { name: 'IPN_ITEMS', type: 'array', of: 'object',
            properties: [
              { name: 'IPN_PID', type: 'integer',
                label: 'Products identifier' },
              { name: 'IPN_PNAME', label: 'Products name' },
              { name: 'IPN_PCODE', label: 'Product code' },
              { name: 'IPN_EXTERNAL_REFERENCE' },
              { name: 'IPN_INFO', label: 'Product information' },
              { name: 'IPN_QTY', type: 'integer', label: 'Purchased quantity' },
              { name: 'IPN_PRICE', type: 'number', label: 'Product price' },
              { name: 'IPN_VAT', type: 'number', label: 'Product VAT' },
              { name: 'IPN_VAT_RATE', type: 'number', label: 'VAT rate' },
              { name: 'IPN_VER', label: 'Product version' },
              { name: 'IPN_DISCOUNT', type: 'number', label: 'Discount' },
              { name: 'IPN_PROMONAME', label: 'Promotion name' },
              { name: 'IPN_SKU', label: 'Product SKU' },
              { name: 'IPN_PROMOCODE', label: 'Promotion code' },
              { name: 'IPN_ORDER_COSTS', label: 'Ordered Cost' },
              { name: 'IPN_PARTNER_CODE', label: 'Partner code' },
              { name: 'IPN_PGROUP', label: 'Group ID' },
              { name: 'IPN_PGROUP_NAME', label: 'Group name' },
              { name: 'IPN_PCOMMISSION', type: 'number' },
              { name: 'IPN_LICENSE_PROD', type: 'integer',
                label: 'System-generated product reference' },
              { name: 'IPN_LICENSE_TYPE', label: 'Subscription type' },
              { name: 'IPN_LICENSE_REF',
                label: 'System-generated subscription references' },
              { name: 'IPN_LICENSE_EXP',
                label: 'Subscription expiration date' },
              { name: 'IPN_LICENSE_START' },
              { name: 'IPN_LICENSE_LIFETIME', label: 'lifetime subscription' },
              { name: 'IPN_LICENSE_ADDITIONAL_INFO',
                label: 'License additional information' },
              { name: 'IPN_DELIVEREDCODES', label: 'Delivered code' },
              { name: 'IPN_ORIGINAL_LINK_SOURCE' }
            ] },
          { name: 'IPN_DOWNLOAD_LINK', label: 'IPN Download Link' },
          { name: 'IPN_TOTAL', label: 'IPN TOTAL', type: 'number' },
          { name: 'IPN_TOTALGENERAL', type: 'number' },
          { name: 'IPN_SHIPPING', type: 'number' },
          { name: 'IPN_SHIPPING_TAX', type: 'number' },
          { name: 'AVANGATE_CUSTOMER_REFERENCE',
            label: 'Avangate Customer Reference' },
          { name: 'EXTERNAL_CUSTOMER_REFERENCE',
            label: 'External Customer Reference' },
          { name: 'IPN_PARTNER_MARGIN_PERCENT',
            label: 'IPN Partner Margin Percent', type: 'number' },
          { name: 'IPN_PARTNER_MARGIN',
            label: 'IPN Partner Margin', type: 'number' },
          { name: 'IPN_EXTRA_MARGIN',
            label: 'IPN Extra Margin', type: 'number' },
          { name: 'IPN_EXTRA_DISCOUNT',
            label: 'IPN Extra Discount', type: 'number' },
          { name: 'IPN_COUPON_DISCOUNT',
            label: 'IPN Coupon Discount', type: 'number' },
          { name: 'IPN_REFERRER', label: 'IPN Referrer' },
          { name: 'IPN_RESELLER_ID',
            label: 'IPN Reseller ID', type: 'integer' },
          { name: 'IPN_RESELLER_NAME', label: 'IPN Reseller Name' },
          { name: 'IPN_RESELLER_URL', label: 'IPN Reseller URL' },
          { name: 'IPN_RESELLER_COMMISSION',
            label: 'IPN Reseller Commission', type: 'number' },
          { name: 'IPN_COMMISSION', label: 'IPN Commission', type: 'number' },
          { name: 'REFUND_TYPE', label: 'Refund Type' },
          { name: 'CHARGEBACK_RESOLUTION', label: 'Chargeback Resolution' },
          { name: 'CHARGEBACK_REASON_CODE', label: 'Chargeback Reason Code' },
          { name: 'TEST_ORDER', label: 'Test Order', type: 'integer' },
          { name: 'IPN_ORDER_ORIGIN', label: 'IPN Order Origin' },
          { name: 'FRAUD_STATUS', label: 'Fraud Status' },
          { name: 'CARD_TYPE', label: 'Card Type' },
          { name: 'CARD_LAST_DIGITS', label: 'Card Last Digits' },
          { name: 'CARD_EXPIRATION_DATE', label: 'Card Expiration Date' },
          { name: 'GATEWAY_RESPONSE', label: 'Gateway Response' },
          { name: 'IPN_DATE', label: 'IPN Date', type: 'date' },
          { name: 'FX_RATE', label: 'FX Rate', type: 'number' },
          { name: 'FX_MARKUP', label: 'FX Markup', type: 'number' },
          { name: 'PAYABLE_AMOUNT', label: 'Payable Amount', type: 'number' },
          { name: 'PAYOUT_CURRENCY', label: 'Payout Currency' },
          { name: 'HASH', label: 'Hash' }
        ]
      end
    },
    lcn: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'FIRST_NAME', Label: 'First Name' },
          { name: 'LAST_NAME', label: 'Last Name' },
          { name: 'COMPANY', label: 'Company' },
          { name: 'EMAIL', label: 'Email' },
          { name: 'PHONE', label: 'Phone' },
          { name: 'FAX', label: 'Fax' },
          { name: 'COUNTRY', label: 'Country' },
          { name: 'STATE', label: 'State' },
          { name: 'CITY', label: 'City' },
          { name: 'ZIP', label: 'Zip' },
          { name: 'ADDRESS', label: 'Address' },
          { name: 'LICENSE_CODE', label: 'License Code' },
          { name: 'EXPIRATION_DATE_TIME', label: 'Expiration Date Time' },
          { name: 'EXPIRATION_DATE', label: 'Expiration Date' },
          { name: 'DATE_UPDATED', label: 'Date Updated' },
          { name: 'AVANGATE_CUSTOMER_REFERENCE',
            label: 'Avangate Customer Reference' },
          { name: 'EXTERNAL_CUSTOMER_REFERENCE',
            label: 'External Customer Reference' },
          { name: 'TEST', label: 'Test' },
          { name: 'CHANGED_BY', label: 'Changed By' },
          { name: 'LICENSE_TYPE', label: 'License Type' },
          { name: 'DISABLED', label: 'Disabled' },
          { name: 'RECURRING', label: 'Recurring' },
          { name: 'LICENSE_PRODUCT', label: 'License Product' },
          { name: 'START_DATE', label: 'Start Date' },
          { name: 'START_DATE_TIME', label: 'Start Date Time' },
          { name: 'PURCHASE_DATE', label: 'Purchase Date' },
          { name: 'PURCHASE_DATE_TIME', label: 'Purchase Date Time' },
          { name: 'LICENSE_LIFETIME', label: 'License Lifetime' },
          { name: 'CONTRACT_CYCLES', label: 'Contract Cycles' },
          { name: 'BILLING_CYCLES', label: 'Billing Cycles' },
          { name: 'NEXT_RENEWAL_PRICE',
            label: 'Next Renewal Price', type: 'integer' },
          { name: 'NEXT_RENEWAL_CURRENCY', label: 'Next Renewal Currency' },
          { name: 'NEXT_RENEWAL_PRICE_TYPE', label: 'Next Renewal Price Type' },
          { name: 'NEXT_RENEWAL_DATE', label: 'Next Renewal Date' },
          { name: 'NEXT_RENEWAL_PAYMETHOD',
            label: 'Next Renewal Payment Method' },
          { name: 'NEXT_RENEWAL_PAYMETHOD_CODE',
            label: 'Next Renewal Payment Method Code' },
          { name: 'NEXT_RENEWAL_CARD_LAST_DIGITS',
            label: 'Next Renewal Card Last Digits' },
          { name: 'NEXT_RENEWAL_CARD_TYPE', label: 'Next Renewal Card Type' },
          { name: 'NEXT_RENEWAL_CARD_EXPIRATION_DATE',
            label: 'Next Renewal Card Expiration Date' },
          { name: 'PARTNER_CODE', label: 'Partner Code' },
          { name: 'AFFILIATE_ID', label: 'Affiliate ID' },
          { name: 'PSKU', label: 'PSKU' },
          { name: 'ACTIVATION_CODE', label: 'Activation Code' },
          { name: 'STATUS', label: 'Status' },
          { name: 'EXPIRED', label: 'Expired' },
          { name: 'TIMEZONE_OFFSET', label: 'TImezone Offset' },
          { name: 'LICENSE_GRACE_PERIOD', label: 'License Grace Period' },
          { name: 'LICENSE_BILLING_TYPE', label: 'License Billing Type' },
          { name: 'USAGE_BILLING_DATE', label: 'Usage Billing Date' },
          { name: 'USAGE_STATUS', label: 'Usage Status' },
          { name: 'LATEST_REPORTED_USAGE_DATE',
            label: 'Latest Reported Usage Date' },
          { name: 'COUNTRY_CODE', label: 'Country Code' },
          { name: 'END_USER_LANGUAGE', label: 'End User Language' },
          { name: 'DISPATCH_REASON', label: 'Dispatch Reason' },
          { name: 'LAST_ORDER_REFERENCE', label: 'Last Order Reference' },
          { name: 'ORIGINAL_ORDER_REFERENCE',
            label: 'Original Order Reference' },
          { name: 'LICENSE_PRODUCT_CODE', label: 'License Product Code' },
          { name: 'RENEWALS_NUMBER', label: 'Renewals Number' },
          { name: 'UPGRADES_NUMBER', label: 'Upgrades Number' },
          { name: 'IS_TRIAL', label: 'Is Trial' },
          { name: 'HASH', label: 'Hash' }
        ]
      end
    }
  },
  webhook_keys: lambda do |params, _headers, _payload|
    ["ipn-#{params['ORDERSTATUS']}", "lcn-#{params['DISPATCH_REASON']}"]
  end,

  triggers:
  {
    new_ipn: {
      title: 'New instant payment notification',
      description: 'New <span class="provider">instant payment notification' \
      ' </span> in <span class="provider">2checkout<span>',
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'event',
            optional: false,
            control_type: 'select',
            pick_list: [
              ['Pending orders', 'PENDING'],
              ['Authorized and approved orders', 'PAYMENT_AUTHORIZED'],
              ['Completed orders', 'COMPLETE'],
              ['Orders under 2Checkout review', 'PENDING_APPROVAL'],
              ['Canceled orders', 'CANCELED']
            ],
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Event',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'text',
              name: 'event',
              hint: "Click <a href='https://knowledgecenter.2checkout.com/" \
              'Integration/09Webhooks/06Instant_Payment_Notification_' \
              "(IPN)/02IPN_triggers' href='_blank'>here</a> for allowed values."
            }
          }
        ]
      end,
      webhook_key: lambda do |_connection, input|
        "ipn-#{input['event']}"
      end,
      webhook_notification: lambda do |_connection, payload|
        array_fields =
          %w[IPN_PID IPN_PNAME IPN_PCODE IPN_EXTERNAL_REFERENCE
             IPN_INFO IPN_QTY IPN_PRICE IPN_VAT IPN_VAT_RATE IPN_VER
             IPN_DISCOUNT IPN_PROMONAME IPN_PROMOCODE
             IPN_ORDER_COSTS IPN_SKU IPN_PARTNER_CODE IPN_PGROUP
             IPN_PGROUP_NAME IPN_PCOMMISSION
             IPN_LICENSE_PROD IPN_LICENSE_TYPE IPN_LICENSE_REF
             IPN_LICENSE_EXP IPN_LICENSE_START IPN_LICENSE_LIFETIME
             IPN_LICENSE_ADDITIONAL_INFO IPN_DELIVEREDCODES
             IPN_ORIGINAL_LINK_SOURCE ]
        items_size = [(payload&.[]('ITEM_PID') || []).length,
                      (payload&.[]('IPN_PCODE') || []).length].max
        i = 0
        items_list = []
        while i < items_size
          item =  array_fields.
                  map do |key|
                    { key => payload&.[](key)&.[](i) }
                  end.inject(:merge)
          items_list << item
          i = i + 1
        end
        payload.merge({ "IPN_ITEMS": items_list || [] })
      end,
      dedup: lambda do |message|
        "#{message['ORDERNO']}-#{message['ORDERSTATUS']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['ipn'].
          concat(object_definitions['customer_billing']).
          concat(object_definitions['customer_delivery']).
          concat(object_definitions['customer_order'])
      end,
      sample_output: lambda do |_connection, _input|
        call(:sample_ipn_output)
      end
    },
    new_lcn:
    {
      title: 'New license change notification',
      description: 'New <span class="provider">license change notification' \
      ' </span> in <span class="provider">2checkout<span>',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'reason',
            optional: false,
            control_type: 'select',
            pick_list:
            [
              %w[Expired LICENCE_EXPIRATION],
              %w[Change LICENCE_CHANGE],
              %w[Grace\ Period\ Change LICENCE_GRACE_PERIOD_CHANGE],
              %w[Pending\ Activation LICENCE_PENDING_ACTIVATION],
              %w[Past\ Due LICENCE_PAST_DUE]
            ],
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Reason',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'text',
              name: 'reason',
              hint: 'Allowed values: LICENCE_EXPIRATION, LICENCE_CHANGE, ' \
              ' LICENCE_GRACE_PERIOD_CHANGE, LICENCE_PENDING_ACTIVATION,' \
               ' LICENCE_PAST_DUE, LICENCE_CHANGE, LICENCE_CHANGE'
            } }
        ]
      end,
      webhook_key: lambda do |_connection, input|
        "lcn-#{input['reason']}"
      end,
      webhook_notification: lambda do |_connection, payload|
        payload
      end,
      dedup: lambda do |message|
        message['HASH']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['lcn']
      end,
      sample_output: lambda do |_connection, _input|
        call('sample_lcn_output')
      end
    }
  }
}
