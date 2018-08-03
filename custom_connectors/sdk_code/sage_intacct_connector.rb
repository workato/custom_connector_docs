{
  title: "Sage Intacct (custom)",

  connection: {
    fields: [
      { name: "login_username", optional: false },
      { name: "login_password", optional: false, control_type: "password" },
      { name: "sender_id", optional: false },
      { name: "sender_password", optional: false, control_type: "password" },
      { name: "company_id", optional: false }
    ],

    authorization: {
      type: "custom_auth",

      acquire: lambda do |connection|
        payload = {
          "control" => {
            "senderid" => connection["sender_id"],
            "password" => connection["sender_password"],
            "controlid" => "testControlId",
            "uniqueid" => false,
            "dtdversion" => 3.0
          },
          "operation" => {
            "authentication" => {
              "login" => {
                "userid" => connection["login_username"],
                "companyid" => connection["company_id"],
                "password" => connection["login_password"]
              }
            },
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "getAPISession" => ""
              }
            }
          }
        }
        api_response = post("/ia/xml/xmlgw.phtml", payload).
                       headers("Content-Type" => "x-intacct-xml-request").
                       format_xml("request").
                       dig("response", 0,
                           "operation", 0,
                           "result", 0,
                           "data", 0,
                           "api", 0)

        {
          session_id: (call("parse_xml_to_hash",
                            "xml" => api_response,
                            "array_fields" => []) || {})["sessionid"]
        }
      end,

      refresh_on: [401, /Invalid session/],

      detect_on: [%r{<status>failure</status>}],

      apply: lambda do |connection|
        headers("Content-Type" => "x-intacct-xml-request")
        payload do |current_payload|
          current_payload&.[]=(
            "control",
            {
              "senderid" => connection["sender_id"],
              "password" => connection["sender_password"],
              "controlid" => "testControlId",
              "uniqueid" => false,
              "dtdversion" => 3.0
            })
          current_payload&.[]("operation")&.[]=(
            "authentication",
            {
              "sessionid" => connection["session_id"]
            })
        end
        format_xml("request")
      end
    },

    base_uri: ->(_connection) { "https://api.intacct.com" }
  },

  test: lambda do |_connection|
    payload = {
      "control" => {},
      "operation" => {
        "authentication" => {}
      }
    }
    post("/ia/xml/xmlgw.phtml", payload)
  end,

  object_definitions: {
    api_session: {
      fields: lambda do |_connection|
        [
          { name: "sessionid", label: "Session ID" },
          { name: "endpoint", label: "Endpoint" }
        ]
      end
    },

    create_or_update_response: {
      fields: lambda do |_connection|
        [
          { name: "status" },
          { name: "function" },
          { name: "controlid", label: "Control ID" },
          { name: "key", label: "Record key" }
        ]
      end
    },

    employee_create: {
      fields: lambda do |_connection|
        [
          { name: "RECORDNO", label: "Record number", type: "integer" },
          { name: "EMPLOYEEID", label: "Employee ID", sticky: true },
          {
            name: "PERSONALINFO",
            label: "Personal info",
            hint: "Contact info",
            optional: false,
            type: "object",
            properties: [{
              name: "CONTACTNAME",
              label: "Contact name",
              hint: "Contact name of an existing contact",
              optional: false,
              control_type: "select",
              pick_list: "contact_names",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "CONTACTNAME",
                label: "Contact name",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          { name: "STARTDATE", label: "Start date", type: "date" },
          { name: "TITLE", label: "Title" },
          {
            name: "SSN",
            label: "Social Security Number",
            hint: "Do not include dashes."
          },
          { name: "EMPLOYEETYPE", label: "Employee type" },
          {
            name: "STATUS",
            label: "Status",
            hint: "Default: Active",
            control_type: "select",
            pick_list: "statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "STATUS",
              label: "Status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "BIRTHDATE", label: "Birth date", type: "date" },
          { name: "ENDDATE", label: "End date", type: "date" },
          {
            name: "TERMINATIONTYPE",
            label: "Termination type",
            control_type: "select",
            pick_list: "termination_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "TERMINATIONTYPE",
              label: "Termination type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "SUPERVISORID",
            label: "Manager",
            control_type: "select",
            pick_list: "employees",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "SUPERVISORID",
              label: "Manager's employee ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "GENDER",
            label: "Gender",
            control_type: "select",
            pick_list: "genders",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "GENDER",
              label: "Gender",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "DEPARTMENTID",
            label: "Department",
            control_type: "select",
            pick_list: "departments",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "DEPARTMENTID",
              label: "Department ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "LOCATIONID",
            label: "Location",
            hint: "Required only when an employee is created at the " \
              "top level in a multi-entity, multi-base-currency company.",
            sticky: true,
            control_type: "select",
            pick_list: "locations",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "LOCATIONID",
              label: "Location ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "CLASSID",
            label: "Class",
            control_type: "select",
            pick_list: "classes",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "CLASSID",
              label: "Class ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "CURRENCY",
            label: "Currency",
            hint: "Default currency code"
          },
          { name: "EARNINGTYPENAME", label: "Earning type name" },
          {
            name: "POSTACTUALCOST",
            label: "Post actual cost",
            hint: "Default: No",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "NAME1099", label: "Name 1099", hint: "Form 1099 name" },
          { name: "FORM1099TYPE", label: "Form 1099 type" },
          { name: "FORM1099BOX", label: "Form 1099 box" },
          {
            name: "SUPDOCFOLDERNAME",
            label: "Supporting doc folder name",
            hint: "Attachment folder name"
          },
          { name: "PAYMETHODKEY", label: "Preferred payment method" },
          {
            name: "PAYMENTNOTIFY",
            label: "Payment notify",
            hint: "Send automatic payment notification. Default: No",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "MERGEPAYMENTREQ",
            label: "Merge payment requests",
            hint: "Default: Yes",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "ACHENABLED",
            label: "ACH enabled",
            hint: "Default: No",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "ACHBANKROUTINGNUMBER", label: "ACH bank routing number" },
          { name: "ACHACCOUNTNUMBER", label: "ACH account number" },
          { name: "ACHACCOUNTTYPE", label: "ACH account type" },
          { name: "ACHREMITTANCETYPE", label: "ACH remittance type" },
          { name: "WHENCREATED", label: "Created date", type: "timestamp" },
          { name: "WHENMODIFIED", label: "Modified date", type: "timestamp" },
          { name: "CREATEDBY", label: "Created by" },
          { name: "MODIFIEDBY", label: "Modified by" }
        ]
      end
    },

    employee_get: {
      fields: lambda do |_connection|
        [
          { name: "RECORDNO", label: "Record number", type: "integer" },
          {
            name: "EMPLOYEEID",
            label: "Employee",
            sticky: true,
            control_type: "select",
            pick_list: "employees",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "EMPLOYEEID",
              label: "Employee ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "PERSONALINFO",
            label: "Personal info",
            hint: "Contact info",
            type: "object",
            properties: [
              {
                name: "CONTACTNAME",
                label: "Contact name",
                hint: "Contact name of an existing contact"
              },
              { name: "PRINTAS", label: "Print as" },
              { name: "COMPANYNAME", label: "Company name" },
              {
                name: "TAXABLE",
                label: "Taxable",
                control_type: "checkbox",
                type: "boolean"
              },
              {
                name: "TAXGROUP",
                label: "Tax group",
                hint: "Contact tax group name"
              },
              { name: "PREFIX", label: "Prefix" },
              { name: "FIRSTNAME", label: "First name" },
              { name: "LASTNAME", label: "Last name" },
              { name: "INITIAL", label: "Initial", hint: "Middle name" },
              {
                name: "PHONE1",
                label: "Primary phone number",
                control_type: "phone"
              },
              {
                name: "PHONE2",
                label: "Secondary phone number",
                control_type: "phone"
              },
              {
                name: "CELLPHONE",
                label: "Cellphone",
                hint: "Cellular phone number",
                control_type: "phone"
              },
              { name: "PAGER", label: "Pager", hint: "Pager number" },
              { name: "FAX", label: "Fax", hint: "Fax number" },
              {
                name: "EMAIL1",
                label: "Primary email address",
                control_type: "email"
              },
              {
                name: "EMAIL2",
                label: "Secondary email address",
                control_type: "email"
              },
              {
                name: "URL1",
                label: "Primary URL",
                control_type: "url"
              },
              {
                name: "URL2",
                label: "Secondary URL",
                control_type: "url"
              },
              {
                name: "STATUS",
                label: "Status",
                control_type: "select",
                pick_list: "statuses",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "STATUS",
                  label: "Status",
                  toggle_hint: "Use custom value",
                  control_type: "text",
                  type: "string"
                }
              },
              {
                name: "MAILADDRESS",
                label: "Mailing information",
                type: "object",
                properties: [
                  { name: "ADDRESS1", label: "Address line 1" },
                  { name: "ADDRESS2", label: "Address line 2" },
                  { name: "CITY", label: "City" },
                  { name: "STATE", label: "State", hint: "State/province" },
                  { name: "ZIP", label: "Zip", hint: "Zip/postal code" },
                  { name: "COUNTRY", label: "Country" }
                ]
              }
            ]
          },
          { name: "STARTDATE", label: "Start date", type: "date" },
          { name: "TITLE", label: "Title" },
          {
            name: "SSN",
            label: "Social Security Number",
            hint: "Do not include dashes"
          },
          { name: "EMPLOYEETYPE", label: "Employee type" },
          {
            name: "STATUS",
            label: "Status",
            control_type: "select",
            pick_list: "statuses",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "STATUS",
              label: "Status",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          { name: "BIRTHDATE", label: "Birth date", type: "date" },
          { name: "ENDDATE", label: "End date", type: "date" },
          {
            name: "TERMINATIONTYPE",
            label: "Termination type",
            control_type: "select",
            pick_list: "termination_types",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "TERMINATIONTYPE",
              label: "Termination type",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "SUPERVISORID",
            label: "Manager",
            control_type: "select",
            pick_list: "employees",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "SUPERVISORID",
              label: "Manager's employee ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "GENDER",
            label: "Gender",
            control_type: "select",
            pick_list: "genders",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "GENDER",
              label: "Gender",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "DEPARTMENTID",
            label: "Department",
            control_type: "select",
            pick_list: "departments",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "DEPARTMENTID",
              label: "Department ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "LOCATIONID",
            label: "Location",
            hint: "Required only when an employee is created at the " \
              "top level in a multi-entity, multi-base-currency company.",
            sticky: true,
            control_type: "select",
            pick_list: "locations",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "LOCATIONID",
              label: "Location ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "CLASSID",
            label: "Class",
            control_type: "select",
            pick_list: "classes",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "CLASSID",
              label: "Class ID",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          },
          {
            name: "CURRENCY",
            label: "Currency",
            hint: "Default currency code"
          },
          { name: "EARNINGTYPENAME", label: "Earning type name" },
          {
            name: "POSTACTUALCOST",
            label: "Post actual cost",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "NAME1099", label: "Name 1099", hint: "Form 1099 name" },
          { name: "FORM1099TYPE", label: "Form 1099 type" },
          { name: "FORM1099BOX", label: "Form 1099 box" },
          {
            name: "SUPDOCFOLDERNAME",
            label: "Supporting doc folder name",
            hint: "Attachment folder name"
          },
          { name: "PAYMETHODKEY", label: "Preferred payment method" },
          {
            name: "PAYMENTNOTIFY",
            label: "Payment notify",
            hint: "Send automatic payment notification",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "MERGEPAYMENTREQ",
            label: "Merge payment requests",
            control_type: "checkbox",
            type: "boolean"
          },
          {
            name: "ACHENABLED",
            label: "ACH enabled",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "ACHBANKROUTINGNUMBER", label: "ACH bank routing number" },
          { name: "ACHACCOUNTNUMBER", label: "ACH account number" },
          { name: "ACHACCOUNTTYPE", label: "ACH account type" },
          { name: "ACHREMITTANCETYPE", label: "ACH remittance type" },
          { name: "WHENCREATED", label: "Created date", type: "timestamp" },
          { name: "WHENMODIFIED", label: "Modified date", type: "timestamp" },
          { name: "CREATEDBY", label: "Created by" },
          { name: "MODIFIEDBY", label: "Modified by" }
        ]
      end
    },

    # Purchase order transaction
    po_txn_header: {
      fields: lambda do |_connection|
        [
          {
            name: "@key",
            label: "Key",
            hint: "Document ID of purchase transaction"
          },
          {
            name: "datecreated",
            label: "Date created",
            hint: "Transaction date",
            type: "date"
          },
          {
            name: "dateposted",
            label: "Date posted",
            hint: "GL posting date",
            type: "date"
          },
          { name: "referenceno", label: "Reference number" },
          { name: "vendordocno", label: "Vendor document number" },
          { name: "termname", label: "Payment term" },
          { name: "datedue", label: "Due date", type: "date" },
          { name: "message" },
          { name: "shippingmethod", label: "Shipping method" },
          {
            name: "returnto",
            label: "Return to contact",
            type: "object",
            properties: [{
              name: "contactname",
              label: "Contact name",
              hint: "Contact name of an existing contact",
              control_type: "select",
              pick_list: "contact_names",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "contactname",
                label: "Contact name",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          {
            name: "payto",
            label: "Pay to contact",
            type: "object",
            properties: [{
              name: "contactname",
              label: "Contact name",
              hint: "Contact name of an existing contact",
              control_type: "select",
              pick_list: "contact_names",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "contactname",
                label: "Contact name",
                toggle_hint: "Use custom value",
                control_type: "text",
                type: "string"
              }
            }]
          },
          {
            name: "supdocid",
            label: "Supporting document ID",
            hint: "Attachments ID"
          },
          { name: "externalid", label: "External ID" },
          { name: "basecurr", label: "Base currency code" },
          { name: "currency", hint: "Transaction currency code" },
          { name: "exchratedate", label: "Exchange rate date", type: "date" },
          {
            name: "exchratetype",
            label: "Exchange rate type",
            hint: "Do not use if exchange rate is set. " \
              "(Leave blank to use Intacct Daily Rate)"
          },
          {
            name: "exchrate",
            label: "Exchange rate",
            hint: "Do not use if exchange rate type is set."
          },
          {
            name: "customfields",
            label: "Custom fields",
            type: "array",
            of: "object",
            properties: [
              {
                name: "customfield",
                label: "Custom field",
                type: "array",
                of: "object",
                properties: [
                  {
                    name: "customfieldname",
                    label: "Custom field name",
                    hint: "Integration name of custom field"
                  },
                  {
                    name: "customfieldvalue",
                    label: "Custom field value",
                    hint: "Enter the value of custom field"
                  }
                ]
              }
            ]
          },
          {
            name: "state",
            label: "State",
            hint: "Action Draft, Pending or Closed. (Default depends " \
              "on transaction definition configuration)",
            control_type: "select",
            pick_list: "transaction_states",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "state",
              label: "State",
              toggle_hint: "Use custom value",
              control_type: "text",
              type: "string"
            }
          }
        ]
      end
    },

    po_txn_transitem: {
      fields: lambda do |_connection|
        [
          {
            name: "@key",
            label: "Key",
            hint: "Document ID of purchase transaction"
          },
          {
            name: "updatepotransitems",
            label: "Transaction items",
            hint: "Array to create new line items",
            type: "array",
            of: "object",
            properties: [
              {
                name: "potransitem",
                label: "Purchase order line items",
                type: "object",
                properties: [
                  { name: "itemid", label: "Item ID" },
                  { name: "itemdesc", label: "Item description" },
                  {
                    name: "taxable",
                    hint: "Customer must be set up for taxable.",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "warehouseid",
                    label: "Warehouse",
                    control_type: "select",
                    pick_list: "warehouses",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "warehouseid",
                      label: "Warehouse ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "quantity" },
                  { name: "unit", hint: "Unit of measure to base quantity" },
                  { name: "price", control_type: "currency", type: "number" },
                  {
                    name: "sourcelinekey",
                    label: "Source line key",
                    hint: "Source line to convert this line from. Use the " \
                      "RECORDNO of the line from the created from " \
                      "transaction document."
                  },
                  {
                    name: "overridetaxamount",
                    label: "Override tax amount",
                    control_type: "currency",
                    type: "number"
                  },
                  {
                    name: "tax",
                    hint: "Tax amount",
                    control_type: "currency",
                    type: "number"
                  },
                  {
                    name: "locationid",
                    label: "Location",
                    sticky: true,
                    control_type: "select",
                    pick_list: "locations",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "locationid",
                      label: "Location ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  {
                    name: "departmentid",
                    label: "Department",
                    control_type: "select",
                    pick_list: "departments",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "departmentid",
                      label: "Department ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "memo" },
                  # { name: "itemdetails", hint: "Array of item details" },
                  {
                    name: "form1099",
                    hint: "Vendor must be set up for 1099s.",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "customfields",
                    label: "Custom fields",
                    type: "array",
                    of: "object",
                    properties: [
                      {
                        name: "customfield",
                        label: "Custom field",
                        type: "array",
                        of: "object",
                        properties: [
                          {
                            name: "customfieldname",
                            label: "Custom field name",
                            hint: "Integration name of custom field"
                          },
                          {
                            name: "customfieldvalue",
                            label: "Custom field value",
                            hint: "Enter the value of custom field"
                          }
                        ]
                      }
                    ]
                  },
                  {
                    name: "projectid",
                    label: "Project",
                    control_type: "select",
                    pick_list: "projects",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "projectid",
                      label: "Project ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "customerid", label: "Customer ID" },
                  { name: "vendorid", label: "Vendor ID" },
                  {
                    name: "employeeid",
                    label: "Employee",
                    control_type: "select",
                    pick_list: "employees",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "employeeid",
                      label: "Employee ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  {
                    name: "classid",
                    label: "Class",
                    control_type: "select",
                    pick_list: "classes",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "classid",
                      label: "Class ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "contractid", label: "Contract ID" },
                  {
                    name: "billable",
                    control_type: "checkbox",
                    type: "boolean"
                  }
                ]
              }
            ]
          }
        ]
      end
    },

    po_txn_updatepotransitem: {
      fields: lambda do |_connection|
        [
          {
            name: "@key",
            label: "Key",
            hint: "Document ID of purchase transaction"
          },
          {
            name: "updatepotransitems",
            label: "Transaction items",
            hint: "Array to update the line items",
            optional: false,
            type: "array",
            of: "object",
            properties: [
              {
                name: "updatepotransitem",
                label: "Purchase order line items",
                hint: "Purchase order line items to update",
                type: "object",
                properties: [
                  {
                    name: "@line_num",
                    label: "Line number",
                    type: "integer",
                    optional: false
                  },
                  { name: "itemid", label: "Item ID" },
                  { name: "itemdesc", label: "Item description" },
                  {
                    name: "taxable",
                    hint: "Customer must be set up for taxable.",
                    control_type: "checkbox",
                    type: "boolean"
                  },
                  {
                    name: "warehouseid",
                    label: "Warehouse",
                    control_type: "select",
                    pick_list: "warehouses",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "warehouseid",
                      label: "Warehouse ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "quantity" },
                  { name: "unit", hint: "Unit of measure to base quantity" },
                  { name: "price", control_type: "currency", type: "number" },
                  {
                    name: "locationid",
                    label: "Location",
                    sticky: true,
                    control_type: "select",
                    pick_list: "locations",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "locationid",
                      label: "Location ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  {
                    name: "departmentid",
                    label: "Department",
                    control_type: "select",
                    pick_list: "departments",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "departmentid",
                      label: "Department ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "memo" },
                  # { name: "itemdetails", hint: "Array of item details" },
                  {
                    name: "customfields",
                    label: "Custom fields",
                    type: "array",
                    of: "object",
                    properties: [
                      {
                        name: "customfield",
                        label: "Custom field",
                        type: "array",
                        of: "object",
                        properties: [
                          {
                            name: "customfieldname",
                            label: "Custom field name",
                            hint: "Integration name of custom field"
                          },
                          {
                            name: "customfieldvalue",
                            label: "Custom field value",
                            hint: "Enter the value of custom field"
                          }
                        ]
                      }
                    ]
                  },
                  {
                    name: "projectid",
                    label: "Project",
                    control_type: "select",
                    pick_list: "projects",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "projectid",
                      label: "Project ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "customerid", label: "Customer ID" },
                  { name: "vendorid", label: "Vendor ID" },
                  {
                    name: "employeeid",
                    label: "Employee",
                    control_type: "select",
                    pick_list: "employees",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "employeeid",
                      label: "Employee ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  {
                    name: "classid",
                    label: "Class",
                    control_type: "select",
                    pick_list: "classes",
                    toggle_hint: "Select from list",
                    toggle_field: {
                      name: "classid",
                      label: "Class ID",
                      toggle_hint: "Use custom value",
                      control_type: "text",
                      type: "string"
                    }
                  },
                  { name: "contractid", label: "Contract ID" },
                  {
                    name: "billable",
                    control_type: "checkbox",
                    type: "boolean"
                  }
                ]
              }
            ]
          }
        ]
      end
    },

    # attachment
    supdoc_create: {
      fields: lambda do |_connection|
        [{
          name: "attachment",
          optional: false,
          type: "object",
          properties: [
            {
              name: "supdocid",
              label: "Supporting document ID",
              hint: "Required if company does not have " \
                "attachment autonumbering configured.",
              sticky: true
            },
            {
              name: "supdocname",
              label: "Supporting document name",
              hint: "Name of attachment",
              optional: false
            },
            {
              name: "supdocfoldername",
              label: "Folder name",
              hint: "Folder to create attachment in",
              optional: false
            },
            { name: "supdocdescription", label: "Attachment description" },
            {
              name: "attachments",
              hint: "Zero to many attachments",
              sticky: true,
              type: "array",
              of: "object",
              properties: [{
                name: "attachment",
                sticky: true,
                type: "object",
                properties: [
                  {
                    name: "attachmentname",
                    label: "Attachment name",
                    hint: "File name, no period or extension",
                    sticky: true
                  },
                  {
                    name: "attachmenttype",
                    label: "Attachment type",
                    hint: "File extension, no period",
                    sticky: true
                  },
                  {
                    name: "attachmentdata",
                    label: "Attachment data",
                    hint: "Base64-encoded file binary data",
                    sticky: true
                  }
                ]
              }]
            }
          ]
        }]
      end
    },

    supdoc_get: {
      fields: lambda do |_connection|
        [
          {
            name: "supdocid",
            label: "Supporting document ID",
            hint: "Required if company does not have " \
              "attachment autonumbering configured.",
            sticky: true
          },
          {
            name: "supdocname",
            label: "Supporting document name",
            hint: "Name of attachment"
          },
          {
            name: "folder",
            label: "Folder name",
            hint: "Attachment folder name"
          },
          { name: "description", label: "Attachment description" },
          {
            name: "supdocfoldername",
            label: "Folder name",
            hint: "Folder to store attachment in"
          },
          { name: "supdocdescription", label: "Attachment description" },
          {
            name: "attachments",
            type: "object",
            properties: [{
              name: "attachment",
              hint: "Zero to many attachments",
              type: "array",
              properties: [
                {
                  name: "attachmentname",
                  label: "Attachment name",
                  hint: "File name, no period or extension",
                  sticky: true
                },
                {
                  name: "attachmenttype",
                  label: "Attachment type",
                  hint: "File extension, no period",
                  sticky: true
                },
                {
                  name: "attachmentdata",
                  label: "Attachment data",
                  hint: "Base64-encoded file binary data",
                  sticky: true
                }
              ]
            }]
          },
          { name: "creationdate", label: "Creation date" },
          { name: "createdby", label: "Created by" },
          { name: "lastmodified", label: "Last modified" },
          { name: "lastmodifiedby", label: "Last modified by" }
        ]
      end
    },

    # attachment folder
    supdocfolder: {
      fields: lambda do |_connection|
        [
          {
            name: "name",
            label: "Folder name",
            hint: "Attachment folder name"
          },
          { name: "description", label: "Folder description" },
          {
            name: "parentfolder",
            label: "Parent folder name",
            hint: "Parent attachment folder"
          },
          {
            name: "supdocfoldername",
            label: "Folder name",
            hint: "Attachment folder name"
          },
          { name: "supdocfolderdescription", label: "Folder description" },
          {
            name: "supdocparentfoldername",
            label: "Parent folder name",
            hint: "Parent attachment folder"
          },
          { name: "creationdate", label: "Creation date" },
          { name: "createdby", label: "Created by" },
          { name: "lastmodified", label: "Last modified" },
          { name: "lastmodifiedby", label: "Last modified by" }
        ]
      end
    }
  },

  methods: {
    parse_xml_to_hash: lambda do |xml_obj|
      xml_obj["xml"]&.
        reject { |key, _value| key[/^@/] }&.
        inject({}) do |hash, (key, value)|
        if value.is_a?(Array)
          hash.merge(if (array_fields = xml_obj["array_fields"])&.include?(key)
                       {
                         key => value.map do |inner_hash|
                                  call("parse_xml_to_hash",
                                       "xml" => inner_hash,
                                       "array_fields" => array_fields)
                                end
                       }
                     else
                       {
                         key => call("parse_xml_to_hash",
                                     "xml" => value[0],
                                     "array_fields" => array_fields)
                       }
                     end)
        else
          value
        end
      end&.presence
    end,

    build_date_object: lambda do |date_field|
      if (raw_date = date_field&.to_date)
        {
          "year" => raw_date&.strftime("%Y") || "",
          "month" => raw_date&.strftime("%m") || "",
          "day" => raw_date&.strftime("%d") || ""
        }
      end
    end
  },

  actions: {
    # Attachment related actions
    create_attachments: {
      description: "Create <span class='provider'>attachments</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "create_supdoc" => input["attachment"]
              }
            }
          }
        }
        attachment_response = post("/ia/xml/xmlgw.phtml", payload).
                              dig("response", 0, "operation", 0, "result", 0)

        call("parse_xml_to_hash",
             "xml" => attachment_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supdoc_create"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["create_or_update_response"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          status: "success",
          function: "create_supdoc",
          controlid: "testControlId",
          key: 1234
        }
      end
    },

    get_attachment: {
      subtitle: "Get attachment by ID",
      description: "Get <span class='provider'>attachment</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "get" => {
                  "@object" => "supdoc",
                  "@key" => input["key"]
                }
              }
            }
          }
        }
        attachment_response = post("/ia/xml/xmlgw.phtml", payload).
                              dig("response", 0,
                                  "operation", 0,
                                  "result", 0,
                                  "data", 0,
                                  "supdoc", 0)

        call("parse_xml_to_hash",
             "xml" => attachment_response,
             "array_fields" => ["attachment"]) || {}
      end,

      input_fields: lambda do |_object_definitions|
        [{ name: "key", label: "Supporting document ID", optional: false }]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supdoc_get"].
          ignored("supdocfoldername", "supdocdescription")
      end,

      sample_output: lambda do |_object_definitions, _input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "get_list" => {
                  "@object" => "supdoc",
                  "@maxitems" => "1"
                }
              }
            }
          }
        }
        attachment_response = post("/ia/xml/xmlgw.phtml", payload).
                              dig("response", 0,
                                  "operation", 0,
                                  "result", 0,
                                  "data", 0,
                                  "supdoc", 0)

        call("parse_xml_to_hash",
             "xml" => attachment_response,
             "array_fields" => ["supdoc"]) || {}
      end
    },

    update_attachment: {
      description: "Update <span class='provider'>attachment</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the value for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "update_supdoc" => input
              }
            }
          }
        }
        attachment_response = post("/ia/xml/xmlgw.phtml", payload).
                              dig("response", 0, "operation", 0, "result", 0)

        call("parse_xml_to_hash",
             "xml" => attachment_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supdoc_get"].
          ignored("creationdate", "createdby", "lastmodified",
                  "lastmodifiedby", "folder", "description").
          required("supdocid")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["create_or_update_response"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          status: "success",
          function: "update_supdoc",
          controlid: "testControlId",
          key: 1234
        }
      end
    },

    # Attachment folder related actions
    create_attachment_folder: {
      description: "Create <span class='provider'>attachment folder</span> " \
         "in <span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "create_supdocfolder" => input
              }
            }
          }
        }
        folder_response = post("/ia/xml/xmlgw.phtml", payload).
                          dig("response", 0, "operation", 0, "result", 0)

        call("parse_xml_to_hash",
             "xml" => folder_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supdocfolder"].
          ignored("creationdate", "createdby", "lastmodified",
                  "lastmodifiedby", "name", "description", "parentfolder").
          required("supdocfoldername")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["create_or_update_response"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          status: "success",
          function: "create_supdocfolder",
          controlid: "testControlId",
          key: 1234
        }
      end
    },

    get_attachment_folder: {
      subtitle: "Get attachment folder by folder name",
      description: "Get <span class='provider'>attachment folder</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "get" => {
                  "@object" => "supdocfolder",
                  "@key" => input["key"]
                }
              }
            }
          }
        }
        attachment_folder_response = post("/ia/xml/xmlgw.phtml", payload).
                                     dig("response", 0,
                                         "operation", 0,
                                         "result", 0,
                                         "data", 0,
                                         "supdocfolder", 0)

        call("parse_xml_to_hash",
             "xml" => attachment_folder_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |_object_definitions|
        [{ name: "key", label: "Folder name", optional: false }]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["supdocfolder"].
          ignored("supdocfoldername", "supdocfolderdescription",
                  "supdocparentfoldername")
      end,

      sample_output: lambda do |_object_definitions, _input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "get_list" => {
                  "@object" => "supdocfolder",
                  "@maxitems" => "1"
                }
              }
            }
          }
        }
        attachment_folder_response = post("/ia/xml/xmlgw.phtml", payload).
                                     dig("response", 0,
                                         "operation", 0,
                                         "result", 0,
                                         "data", 0,
                                         "supdocfolder", 0)

        call("parse_xml_to_hash",
             "xml" => attachment_folder_response,
             "array_fields" => []) || {}
      end
    },

    update_attachment_folder: {
      description: "Update <span class='provider'>attachment folder</span> " \
        "in <span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "update_supdocfolder" => input
              }
            }
          }
        }
        folder_response = post("/ia/xml/xmlgw.phtml", payload).
                          dig("response", 0, "operation", 0, "result", 0)

        call("parse_xml_to_hash",
             "xml" => folder_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["supdocfolder"].
          ignored("creationdate", "createdby", "lastmodified",
                  "lastmodifiedby", "name", "description", "parentfolder").
          required("supdocfoldername")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["create_or_update_response"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          status: "success",
          function: "update_supdocfolder",
          controlid: "testControlId",
          key: 1234
        }
      end
    },

    # API Session related actions
    get_api_session: {
      title: "Get API session",
      description: "Get <span class='provider'>API session</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",
      help: "Action returns a unique identifier for an API session " \
        "and its endpoint.",

      execute: lambda do |_connection, _input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "getAPISession" => ""
              }
            }
          }
        }
        api_response = post("/ia/xml/xmlgw.phtml", payload).
                       dig("response", 0,
                           "operation", 0,
                           "result", 0,
                           "data", 0,
                           "api", 0)

        call("parse_xml_to_hash",
             "xml" => api_response,
             "array_fields" => []) || {}
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["api_session"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          sessionid: "ABCDzfHEFnEM2pxLOKhfecjzcQ3anA..",
          endpoint: "https://api.intacct.com/ia/xml/xmlgw.phtml"
        }
      end
    },

    # Employee related actions
    create_employee: {
      description: "Create <span class='provider'>employee</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "create" => { "EMPLOYEE" => input }
              }
            }
          }
        }
        employee_response = post("/ia/xml/xmlgw.phtml", payload).
                            dig("response", 0,
                                "operation", 0,
                                "result", 0,
                                "data", 0,
                                "employee", 0)

        call("parse_xml_to_hash",
             "xml" => employee_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["employee_create"].
          ignored("RECORDNO", "CREATEDBY", "MODIFIEDBY", "WHENCREATED",
                  "WHENMODIFIED")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["employee_get"].only("RECORDNO", "EMPLOYEEID")
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          "RECORDNO" => 1234,
          "EMPLOYEEID" => "EMP-007"
        }
      end
    },

    get_employee: {
      subtitle: "Get employee by recod number",
      description: "Get <span class='provider'>employee</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "read" => {
                  "object" => "EMPLOYEE",
                  "keys" => input["RECORDNO"],
                  "fields" => "*"
                }
              }
            }
          }
        }
        employee_response = post("/ia/xml/xmlgw.phtml", payload).
                            dig("response", 0,
                                "operation", 0,
                                "result", 0,
                                "data", 0,
                                "EMPLOYEE", 0)

        call("parse_xml_to_hash",
             "xml" => employee_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["employee_get"].
          only("RECORDNO").
          required("RECORDNO")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["employee_get"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "readByQuery" => {
                  "object" => "EMPLOYEE",
                  "query" =>  "",
                  "fields" => "*",
                  "pagesize" => "1"
                }
              }
            }
          }
        }
        employee_response = post("/ia/xml/xmlgw.phtml", payload).
                            dig("response", 0,
                                "operation", 0,
                                "result", 0,
                                "data", 0,
                                "employee", 0)

        call("parse_xml_to_hash",
             "xml" => employee_response,
             "array_fields" => []) || {}
      end
    },

    update_employee: {
      description: "Update <span class='provider'>employee</span> in " \
        "<span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "update" => { "EMPLOYEE" => input }
              }
            }
          }
        }
        employee_response = post("/ia/xml/xmlgw.phtml", payload).
                            dig("response", 0,
                                "operation", 0,
                                "result", 0,
                                "data", 0,
                                "employee", 0)

        call("parse_xml_to_hash",
             "xml" => employee_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["employee_get"].
          ignored("CREATEDBY", "MODIFIEDBY", "WHENCREATED", "WHENMODIFIED").
          required("RECORDNO")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["employee_get"].only("RECORDNO", "EMPLOYEEID")
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          "RECORDNO" => 1234,
          "EMPLOYEEID" => "EMP-007"
        }
      end
    },

    # Purchase Order Transaction related actions
    update_purchase_transaction_header: {
      description: "Update <span class='provider'>purchase transaction " \
        "header</span> in <span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        %w[datecreated dateposted datedue exchratedate].
          each do |date_field|
            input&.[]=(date_field,
                       call("build_date_object", input[date_field]))
          end
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "update_potransaction" => input&.compact
              }
            }
          }
        }
        po_txn_response = post("/ia/xml/xmlgw.phtml", payload).
                          dig("response", 0, "operation", 0, "result", 0)

        call("parse_xml_to_hash",
             "xml" => po_txn_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["po_txn_header"].required("@key")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["create_or_update_response"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          status: "success",
          function: "update_potransaction",
          controlid: "testControlId",
          key: 1234
        }
      end
    },

    add_purchase_transaction_items: {
      description: "Add <span class='provider'>purchase transaction " \
        "items</span> in <span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "update_potransaction" => input
              }
            }
          }
        }
        po_txn_response = post("/ia/xml/xmlgw.phtml", payload).
                          dig("response", 0, "operation", 0, "result", 0)

        call("parse_xml_to_hash",
             "xml" => po_txn_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["po_txn_transitem"].required("@key")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["create_or_update_response"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          status: "success",
          function: "update_potransaction",
          controlid: "testControlId",
          key: 1234
        }
      end
    },

    update_purchase_transaction_items: {
      description: "Update <span class='provider'>purchase transaction " \
        "items</span> in <span class='provider'>Sage Intacct (custom)</span>",
      help: "Pay special attention to enter the values for the " \
        "fields in the same order as listed below, " \
        "for the action to be successful!",

      execute: lambda do |_connection, input|
        payload = {
          "control" => {},
          "operation" => {
            "authentication" => {},
            "content" => {
              "function" => {
                "@controlid" => "testControlId",
                "update_potransaction" => input
              }
            }
          }
        }
        po_txn_response = post("/ia/xml/xmlgw.phtml", payload).
                          dig("response", 0, "operation", 0, "result", 0)

        call("parse_xml_to_hash",
             "xml" => po_txn_response,
             "array_fields" => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["po_txn_updatepotransitem"].required("@key")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["create_or_update_response"]
      end,

      sample_output: lambda do |_object_definitions, _input|
        {
          status: "success",
          function: "update_potransaction",
          controlid: "testControlId",
          key: 1234
        }
      end
    }
  },

  pick_lists: {
    classes: lambda do |_connection|
      payload = {
        "control" => {},
        "operation" => {
          "authentication" => {},
          "content" => {
            "function" => {
              "@controlid" => "testControlId",
              "readByQuery" => {
                "object" => "CLASS",
                "fields" => "NAME, CLASSID",
                "query" => "STATUS = 'T'",
                "pagesize" => "1000"
              }
            }
          }
        }
      }
      class_response = post("/ia/xml/xmlgw.phtml", payload).
                       dig("response", 0,
                           "operation", 0,
                           "result", 0,
                           "data", 0)

      call("parse_xml_to_hash",
           "xml" => class_response,
           "array_fields" => ["class"])&.
        []("class")&.
        pluck("NAME", "CLASSID") || []
    end,

    contact_names: lambda do |_connection|
      payload = {
        "control" => {},
        "operation" => {
          "authentication" => {},
          "content" => {
            "function" => {
              "@controlid" => "testControlId",
              "readByQuery" => {
                "object" => "CONTACT",
                "fields" => "RECORDNO, CONTACTNAME",
                "query" => "STATUS = 'T'",
                "pagesize" => "1000"
              }
            }
          }
        }
      }
      contact_response = post("/ia/xml/xmlgw.phtml", payload).
                         dig("response", 0,
                             "operation", 0,
                             "result", 0,
                             "data", 0)

      call("parse_xml_to_hash",
           "xml" => contact_response,
           "array_fields" => ["contact"])&.
        []("contact")&.
        pluck("CONTACTNAME", "CONTACTNAME") || []
    end,

    departments: lambda do |_connection|
      payload = {
        "control" => {},
        "operation" => {
          "authentication" => {},
          "content" => {
            "function" => {
              "@controlid" => "testControlId",
              "readByQuery" => {
                "object" => "DEPARTMENT",
                "fields" => "TITLE, DEPARTMENTID",
                "query" => "STATUS = 'T'",
                "pagesize" => "1000"
              }
            }
          }
        }
      }
      department_response = post("/ia/xml/xmlgw.phtml", payload).
                            dig("response", 0,
                                "operation", 0,
                                "result", 0,
                                "data", 0)

      call("parse_xml_to_hash",
           "xml" => department_response,
           "array_fields" => ["department"])&.
        []("department")&.
        pluck("TITLE", "DEPARTMENTID") || []
    end,

    employees: lambda do |_connection|
      payload = {
        "control" => {},
        "operation" => {
          "authentication" => {},
          "content" => {
            "function" => {
              "@controlid" => "testControlId",
              "readByQuery" => {
                "object" => "EMPLOYEE",
                "fields" => "TITLE, EMPLOYEEID",
                "query" => "STATUS = 'T'",
                "pagesize" => "1000"
              }
            }
          }
        }
      }
      employee_response = post("/ia/xml/xmlgw.phtml", payload).
                          dig("response", 0,
                              "operation", 0,
                              "result", 0,
                              "data", 0)

      call("parse_xml_to_hash",
           "xml" => employee_response,
           "array_fields" => ["employee"])&.
        []("employee")&.
        pluck("TITLE", "EMPLOYEEID") || []
    end,

    genders: ->(_connection) { [%w[Male male], %w[Female female]] },

    locations: lambda do |_connection|
      payload = {
        "control" => {},
        "operation" => {
          "authentication" => {},
          "content" => {
            "function" => {
              "@controlid" => "testControlId",
              "readByQuery" => {
                "object" => "LOCATION",
                "fields" => "NAME, LOCATIONID",
                "query" => "STATUS = 'T'",
                "pagesize" => "1000"
              }
            }
          }
        }
      }
      location_response = post("/ia/xml/xmlgw.phtml", payload).
                          dig("response", 0,
                              "operation", 0,
                              "result", 0,
                              "data", 0)

      call("parse_xml_to_hash",
           "xml" => location_response,
           "array_fields" => ["location"])&.
        []("location")&.
        pluck("NAME", "LOCATIONID") || []
    end,

    projects: lambda do |_connection|
      payload = {
        "control" => {},
        "operation" => {
          "authentication" => {},
          "content" => {
            "function" => {
              "@controlid" => "testControlId",
              "readByQuery" => {
                "object" => "PROJECT",
                "fields" => "NAME, PROJECTID",
                "query" => "STATUS = 'T'",
                "pagesize" => "1000"
              }
            }
          }
        }
      }
      project_response = post("/ia/xml/xmlgw.phtml", payload).
                         dig("response", 0,
                             "operation", 0,
                             "result", 0,
                             "data", 0)

      call("parse_xml_to_hash",
           "xml" => project_response,
           "array_fields" => ["project"])&.
        []("project")&.
        pluck("NAME", "PROJECTID") || []
    end,

    statuses: ->(_connection) { [%w[Active active], %w[Inactive inactive]] },

    termination_types: lambda do |_connection|
      [%w[Voluntary voluntary], %w[Involuntary involuntary],
       %w[Deceased deceased], %w[Disability disability],
       %w[Retired retired]]
    end,

    transaction_states: lambda do |_connection|
      [%w[Draft Draft], %w[Pending Pending], %w[Closed Closed]]
    end,

    warehouses: lambda do |_connection|
      payload = {
        "control" => {},
        "operation" => {
          "authentication" => {},
          "content" => {
            "function" => {
              "@controlid" => "testControlId",
              "readByQuery" => {
                "object" => "WAREHOUSE",
                "fields" => "NAME, WAREHOUSEID",
                "query" => "STATUS = 'T'",
                "pagesize" => "1000"
              }
            }
          }
        }
      }
      warehouse_response = post("/ia/xml/xmlgw.phtml", payload).
                           dig("response", 0,
                               "operation", 0,
                               "result", 0,
                               "data", 0)

      call("parse_xml_to_hash",
           "xml" => warehouse_response,
           "array_fields" => ["warehouse"])&.
        []("warehouse")&.
        pluck("NAME", "WAREHOUSEID") || []
    end
  }
}
