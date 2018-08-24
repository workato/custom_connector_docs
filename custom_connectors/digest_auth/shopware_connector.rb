# Adapter for Shopware - The trendsetting eCommerce software to power
# your online business
{
  title: "Shopware",
  # Connection to Shopware
  connection: {
    fields: [
      {
        name: "user",
        optional: false
      },
      {
        name: "password",
        control_type: "password",
        optional: false

      },
      {
        name: "shopware_url",
        control_type: "subdomain",
        optional: false
      }
    ],

    # Digest Authentication
    authorization: {
      apply: lambda do |connection|
        user(connection["user"])
        password(connection["password"])
        digest_auth
      end
    },

    base_uri: lambda do |connection|
      "http://#{connection["shopware_url"]}"
    end
  },

  # Test connection
  test: lambda do |_connection|
    get("/api/version")
  end,

  # Object definitions:
  object_definitions: {
    # Customer definition
    customer: {
      fields: lambda do |_connection|
        [
          { name: "id", type: :integer, label: "Customer Id" },
          { name: "paymentId", type: :integer, label: "Payment Id" },
          { name: "groupKey", type: :string, label: "Group Key" },
          { name: "shopId", type: :integer, label: "Shop Id" },
          { name: "priceGroupId", type: :integer, label: "Price Group Id" },
          { name: "encoderName", type: :string, label: "Encode Name" },
          { name: "active", type: :boolean, label: "Active" },
          { name: "email", type: :string, label: "Email" },
          { name: "accountMode", type: :integer, label: "Account Mode" },
          { name: "validation", type: :string, label: "Validation" },
          { name: "affiliate", type: :boolean, label: "Affiliate" },
          { name: "languageId", type: :integer, label: "Langage Id" },
          { name: "referer", type: :string, label: "Referer" },
          { name: "internalComment", type: :string, label: "Internal Comment" },
          { name: "salutation", type: :string, label: "Salutation" },
          { name: "title", type: :string, label: "Title" },
          { name: "firstname", type: :string, label: "First Name" },
          { name: "number", type: :string, label: "Number" },
          { name: "lastname", type: :string, label: "Last Name" },
          { name: "birthday", type: :date, label: "Birth Day" },
          { name: "attribute", type: :array, properties: [
            { name: "id", type: :integer },
            { name: "customerId", type: :integer, label: "Customer Id" }
          ] }
        ]
      end
    },

    order: {
      fields: lambda do |_connection|
        [
          { name: "id", type: :integer, label: "Order Id" },
          { name: "number", type: :integer, label: "Number" },
          { name: "customerId", type: :integer, label: "Customer Id" },
          { name: "paymentId", type: :integer, label: "Payment Id" },
          { name: "dispatchId", type: :integer, label: "Dispatch Id" },
          { name: "partnerId", type: :string, label: "Parnter Id" },
          { name: "shopId", type: :integer, label: "Shop Id" },
          { name: "invoiceAmount", type: :number, label: "Invoice Amount" },
          { name: "invoiceAmountNet", type: :number,
            label: "Net Invoice Amount" },
          { name: "invoiceShipping", type: :number, label: "Invoice Shipping" },
          { name: "invoiceShippingNet", type: :number,
            label: "Net Invoice Shipping" },
          { name: "orderTime", type: :string, label: "Order Time" },
          { name: "transactionId", type: :string, label: "Transaction Id" },
          { name: "comment", type: :string, label: "Comment" },
          { name: "customerComment", type: :string, label: "Customer Comment" },
          { name: "internalComment", type: :string, label: "Internal Comment" },
          { name: "net", type: :integer, label: "Net" },
          { name: "taxFree", type: :integer, label: "Tax Free" },
          { name: "temporaryId", type: :string, label: "Temporary Id" },
          { name: "clearedDate", type: :string, label: "Cleared Date" },
          { name: "trackingCode", type: :string, label: "Tracking Code" },
          { name: "languageIso", type: :string, label: "Language Iso" },
          { name: "currency", type: :string, label: "Currency" },
          { name: "currencyFactor", type: :integer, label: "Currency Factor" },
          { name: "remoteAddress", type: :string, label: "Remote Address" },
          { name: "deviceType", type: :string, label: "Device Type" },
          { name: "attribute", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "orderId", type: :integer, label: "Order Id" },
            { name: "attribute1", type: :string },
            { name: "attribute2", type: :string },
            { name: "attribute3", type: :string },
            { name: "attribute4", type: :string },
            { name: "attribute5", type: :string },
            { name: "attribute6", type: :string },
            { name: "swagPayalBillingAgreementId", type: :integer },
            { name: "swagPayalExpress", type: :string },
            { name: "swagKlarnaStatus", type: :string },
            { name: "swagKlarnaInvoiceNumber", type: :string },
            { name: "swagAboCommerceId", type: :integer }
          ] },
          { name: "customer", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "email", type: :string, label: "Customer Email" }
          ] },
          { name: "paymentStatusId", type: :integer,
            label: "Payment Status Id" },
          { name: "orderStatusId", type: :integer, label: "Order Status Id"}
        ]
      end
    },

    # Enhance the schema mapping if any fields missed in customer_details object
    customer_details: {
      fields: lambda do |_connection|
        [
          { name: "id", type: :integer },
          { name: "paymentId", type: :integer },
          { name: "groupKey", type: :string },
          { name: "shopId", type: :integer },
          { name: "priceGroupId", type: :integer },
          { name: "encoderName", type: :string },
          { name: "active", type: :boolean },
          { name: "email", type: :string },
          { name: "accountMode", type: :integer },
          { name: "validation", type: :string },
          { name: "affiliate", type: :boolean },
          { name: "languageId", type: :integer },
          { name: "referer", type: :string },
          { name: "internalComment", type: :string },
          { name: "salutation", type: :string },
          { name: "title", type: :string },
          { name: "firstname", type: :string },
          { name: "number", type: :string },
          { name: "lastname", type: :string },
          { name: "birthday", type: :date },
          { name: "attribute", type: :array, properties: [
            { name: "id", type: :integer },
            { name: "customerId", type: :integer }
          ] },
          { name: "defaultBillingAddress", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "company", type: :string },
            { name: "department", type: :string },
            { name: "salutation", type: :string },
            { name: "firstname", type: :string },
            { name: "title", type: :string },
            { name: "lastname", type: :string },
            { name: "street", type: :string },
            { name: "zipcode", type: :string },
            { name: "city", type: :string },
            { name: "phone", type: :string },
            { name: "countryId", type: :integer },
            { name: "stateId", type: :integer },
            { name: "attribute", type: :object, properties: [
              { name: "id", type: :integer },
              { name: "customerAddressId", type: :integer }
            ] },
            { name: "country", type: :object, properties: [
              { name: "id", type: :integer },
              { name: "name", type: :string },
              { name: "iso", type: :string },
              { name: "isoName", type: :string },
              { name: "areaId", type: :integer }
            ] },
            { name: "state", type: :object, properties: [
              { name: "id", type: :integer },
              { name: "name", type: :string }
            ] }
          ] },
          { name: "paymentData", type: :array, of: :object },
          { name: "defaultShippingAddress", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "company", type: :string },
            { name: "department", type: :string },
            { name: "salutation", type: :string },
            { name: "firstname", type: :string },
            { name: "title", type: :string },
            { name: "lastname", type: :string },
            { name: "street", type: :string },
            { name: "zipcode", type: :string },
            { name: "city", type: :string },
            { name: "phone", type: :string },
            { name: "countryId", type: :integer },
            { name: "attribute", type: :object, properties: [
              { name: "id", type: :integer },
              { name: "customerAddressId", type: :integer }
            ] },
            { name: "country", type: :object, properties: [
                { name: "id", type: :integer },
                { name: "name", type: :string },
                { name: "iso", type: :string },
                { name: "isoName", type: :string },
                { name: "areaId", type: :integer }
            ] },
            { name: "state", type: :object, properties: [
                { name: "id", type: :integer },
                { name: "name", type: :string }
            ] }
          ] }
        ]
      end
    },

    # Use this definition for Get Order details
    order_details: {
      fields: lambda do |_connection|
        [
          { name: "id", type: :integer },
          { name: "number", type: :integer },
          { name: "customerId", type: :integer },
          { name: "paymentId", type: :integer },
          { name: "dispatchId", type: :integer },
          { name: "partnerId", type: :string },
          { name: "shopId", type: :integer },
          { name: "invoiceAmount", type: :number },
          { name: "invoiceAmountNet", type: :number },
          { name: "invoiceShipping", type: :number },
          { name: "invoiceShippingNet", type: :number },
          { name: "orderTime", type: :string }, # check date time
          { name: "transactionId", type: :string },
          { name: "comment", type: :string },
          { name: "customerComment", type: :string },
          { name: "internalComment", type: :string },
          { name: "net", type: :integer },
          { name: "taxFree", type: :integer },
          { name: "temporaryId", type: :string },
          { name: "clearedDate", type: :string },
          { name: "trackingCode", type: :string },
          { name: "languageIso", type: :string },
          { name: "currency", type: :string },
          { name: "currencyFactor", type: :integer },
          { name: "remoteAddress", type: :string },
          { name: "deviceType", type: :string }, # check device type
          { name: "details", type: :array, of: :object, properties: [
            { name: "id", type: :integer },
            { name: "orderId", type: :integer },
            { name: "articleId", type: :integer },
            { name: "taxId", type: :integer },
            { name: "taxRate", type: :number },
            { name: "statusId", type: :integer },
            { name: "number", type: :string },
            { name: "articleNumber", type: :string },
            { name: "price", type: :number },
            { name: "quantity", type: :integer },
            { name: "articleName", type: :string },
            { name: "shipped", type: :integer },
            { name: "shippedGroup", type: :integer },
            { name: "releaseDate", type: :string },
            { name: "mode", type: :integer },
            { name: "esdArticle", type: :integer },
            { name: "config", type: :string },
            { name: "ean", type: :string },
            { name: "unit", type: :string },
            { name: "packUnit", type: :string },
            { name: "attribute", type: :object, properties: [
              { name: "id", type: :integer },
              { name: "orderDetailId", type: :integer },
              { name: "swagKlarnaInvoiceNumber", type: :string },
              { name: "swagBonus", type: :boolean }
            ] }
          ] },
          { name: "documents", type: :array, of: :object, properties: [
            { name: "id", type: :integer },
            { name: "date", type: :string }, #check for datetime
            { name: "typeId", type: :integer },
            { name: "customerId", type: :integer },
            { name: "orderId", type: :integer },
            { name: "amount", type: :number },
            { name: "documentId", type: :integer },
            { name: "type", type: :object, properties: [
              { name: "id", type: :integer },
              { name: "name", type: :string },
              { name: "template", type: :string },
              { name: "numbers", type: :string },
              { name: "left", type: :integer },
              { name: "right", type: :integer },
              { name: "top", type: :integer },
              { name: "bottom", type: :integer },
              { name: "pageBreak", type: :integer }
            ] },
            { name: "attribute", type: :object, properties: [
              { name: "id", type: :integer },
              { name: "documentId", type: :integer }
            ] }
          ] },
          { name: "payment", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "name", type: :string },
            { name: "description", type: :string },
            { name: "debitPercent", type: :integer },
            { name: "surcharge", type: :integer },
            { name: "action", type: :string },
            { name: "pluginId", type: :integer }
          ] },
          { name: "paymentStatus", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "name", type: :string },
            { name: "description", type: :string },
            { name: "position", type: :integer },
            { name: "group", type: :string },
            { name: "sendMail", type: :integer }
          ] },
          { name: "orderStatus", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "name", type: :string },
            { name: "description", type: :string },
            { name: "position", type: :integer },
            { name: "group", type: :string },
            { name: "sendMail", type: :integer }
          ] },
          { name: "customer", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "paymentId", type: :integer },
            { name: "groupKey", type: :string },
            { name: "shopId", type: :integer },
            { name: "salutation", type: :string },
            { name: "title", type: :string },
            { name: "firstname", type: :string },
            { name: "lastname", type: :string },
            { name: "number", type: :string }
          ] },
          { name: "paymentInstances", type: :array, of: :object, properties: [
            { name: "id", type: :integer },
            { name: "firstName", type: :string },
            { name: "lastName", type: :string },
            { name: "address", type: :string },
            { name: "zipCode", type: :string },
            { name: "city", type: :string },
            { name: "bankName", type: :string },
            { name: "bankCode", type: :string },
            { name: "accountNumber", type: :string }, # check type
            { name: "accountHolder", type: :string },
            { name: "bic", type: :string }, # check type
            { name: "iban", type: :string },
            { name: "amount", type: :number }, # check type
            { name: "createdAt", type: :string } # check datetime type??
          ] },
          { name: "billing", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "orderId", type: :integer },
            { name: "customerId", type: :integer },
            { name: "countryId", type: :integer },
            { name: "stateId", type: :integer }
          ] },
          { name: "shipping", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "orderId", type: :integer },
            { name: "customerId", type: :integer },
            { name: "countryId", type: :integer },
            { name: "stateId", type: :integer }
          ] },
          { name: "shop", type: :object, properties: [
            { name: "id", type: :integer },
            { name: "mainId", type: :integer }, # check type
            { name: "categoryId", type: :integer },
            { name: "name", type: :string },
            { name: "title", type: :string },
            { name: "active", type: :boolean }
          ] },
          { name: "paymentStatusId", type: :integer },
          { name: "orderStatusId", type: :integer }
        ]
      end
    }
  },

  actions: {
    # Status: Completed
    get_customer_by_id: {
      description: "Get <span class='provider'>customer</span> by ID in " \
        "<span class='provider'>Shopware</span>",

      input_fields: lambda do
        [
          { name: "id", type: :integer, optional: false, label: "Customer Id" }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/api/customers/#{input['id']}")["data"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["customer_details"]
      end
    },

    get_order_by_id: {
      description: "Get <span class='provider'>order</span> by ID in "\
        "<span class='provider'>Shopware</span>",

      input_fields: lambda do
        [
          { name: "id", type: :integer, optional: false, label: "Order Id"}
        ]
      end,

      execute: lambda do |_connection, input|
        get("/api/orders/#{input['id']}")["data"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["order_details"]
      end
    },

    # Status: Completed
    update_order_by_id: {
      description: "Update <span class='provider'>order</span> by ID in " \
        "<span class='provider'>Shopware</span>",

      input_fields: lambda do
        [
          { name: "id", type: :integer, optional: false, label: "Product Id" },
          { name: "paymentStatusId", type: :integer,
            label: "Payment Status Id" },
          { name: "orderStatusId", type: :integer, label: "Order Status Id" },
          { name: "trackingCode", type: :string, label: "Tracking Code" },
          { name: "comment", type: :string, label: "Comments" },
          { name: "transactionId", type: :integer, label: "Transaction Id" },
          { name: "clearedDate", type: :date_time, label: "Cleared Date" }
        ]
      end,

      execute: lambda do |_connection, input|
        put("/api/orders/#{input['id']}", input)["data"]
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: "id", type: :integer },
          { name: "location", type: :url }
        ]
      end
    }
  },

  # Status: completed.
  triggers: {
    new_customer: {
      description: "New <span class='provider'>customer</span> in " \
        "<span class='provider'>Shopware</span>",

      input_fields: lambda do |_object_definitions|
        [
          { name: "id", type: :integer, label: "Customer ID",
            hint: "Provide inital customer ID from which trigger processes " \
              "records. Default starts with 0. E.g. use 4 for customer ID 5" }
        ]
      end,

      poll: lambda do |_connection, input, last_customer_id|
        limit_size = 100
        # set for the first invocation
        input_customer_id = input["id"] || 0

        customer_id = last_customer_id || input_customer_id
        params = ["filter" => {
                   "0" => {
                     "property" => "id",
                     "expression" => ">",
                     "value" => customer_id
                   }
                 },
                 "limit" => limit_size]
        response = get("/api/customers", params) || []
        customers = response["data"]
        last_customer_id = customers.last["id"] unless customers.blank?

        {
          events: customers,
          next_poll: last_customer_id || customer_id,
          can_poll_more: limit_size <= response["total"]
        }
      end,

      dedup: lambda do |customer|
        customer["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["customer"]
      end,

      sample_output: lambda do |_connection|
        get("/api/customers")["data"]&.first || {}
      end
    },

    # Status: Completed
    new_order: {
      description: "New <span class='provider'>order</span> in " \
        "<span class='provider'>Shopware</span>",

      input_fields: lambda do |_object_definitions|
        [
          { name: "id", type: :integer, label: "Order ID",
            hint: "Provide inital order ID from which trigger processes " \
              "records. Default starts with 0. E.g. use 4 for order ID 5" }
        ]
      end,

      poll: lambda do |_connection, input, latest_order_id|
        limit_size = 100

        # set for the first invocation
        input_order_id = input["id"] || 0

        order_id = latest_order_id || input_order_id
        params = ["filter" => {
                   "0" => {
                     "property" => "id",
                     "expression" => ">",
                     "value" => order_id
                   }
                 },
                 "limit" => limit_size]
        response = get("/api/orders", params) || []
        orders = response["data"]
        latest_order_id = orders.last["id"] unless orders.blank?

        {
          events: orders,
          next_poll: latest_order_id || order_id,
          can_poll_more: limit_size <= response["total"]
        }
      end,

      dedup: lambda do |order|
        order["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["order"]
      end,

      sample_output: lambda do |_connection|
        get("/api/orders")["data"]&.first || {}
      end
    }
  }
}
