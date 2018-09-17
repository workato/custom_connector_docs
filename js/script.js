//Global var
var adapterCount = 0;
var hiddenCount = 0;
var json;
var filterList = {};
var textFormat = {
  "api_type": "API Type",
  "auth_type": "Auth Type",
  "category": "Category"
};
//On Init
$(document).ready(function () {
  loadJSON();
  generateAdapters();
  filterHandler();
  clearSearch();
});

//Handle filter navigation clicks
function filterHandler() {
  $("body").on("click", ".filter-input", function () {
    //Get filter and value selected
    var filterHTML = ($(this).closest("ul").siblings("h5").html());
    var filter = (_.invert(textFormat)[filterHTML]);
    var selected = $("." + filter + ".selected-input");
    var val = $(this).html();
    var currentFilter = {};
    
    $("." + filter).removeClass("selected-input"); //Reset filter class to default style
    if ($(selected).html() == val) {
      filterList[filter] = ""; //Set filter to blank after deselecting
    } else {
      $(this).addClass("selected-input"); //Add active class to selected filter
      filterList[filter] = val; //Add filter value to filter key
    }

    //Toggle hidden according to filter match
    $('.app').each(function () {
      var parent = this;
      var name = $(this).find(".item-name").html();
      valid = true;

      $(this).children(".hoverContainer").children(".hover-properties").children("li").each(function () {
        tempFilter = (_.invert(textFormat)[$(this).find(".property-filter").html().slice(0, -1)]);
        tempValue = $(this).find(".property-value").html();
        currentFilter[tempFilter] = tempValue;
      });
      $.each(currentFilter, function (key, object) {
        if ((filterList[key] == object || filterList[key] == "")) {
        } else {
          valid = false;
        }
      });

      if (valid == false) {
        $(parent).addClass("filter-hidden");
      } else {
        $(parent).removeClass("filter-hidden");
      }
    })
    checkAllHidden();
  });
}

//Load JSON
function loadJSON() {
  $.ajax({
    'async': false,
    'global': false,
    'url': 'json/adapters.json',
    'dataType': "json",
    'success': function (data) {
      json = data;
    }
  });
}

//Search Function
function filterFunc(event) {
  var userInput = event.value.toUpperCase();
  $('.app').each(function () {
    if (this.textContent.toUpperCase().indexOf(userInput) > -1) {
      $(this).removeClass("search-hidden");
    } else {
      $(this).addClass("search-hidden");
    }
  });
  checkAllHidden();
}

//Function to check if all apps are hidden, show no results message
function checkAllHidden() {
  //Show no result message if all adapters are hidden
  var valid = true;
  $('.app').each(function () {
    if ($(this).attr("class") === "app") {
      valid = false;
    }

    if (valid == false) {
      $('#no-result').hide();
      $(".splitter").show();

    } else {
      $('#no-result').show();
      $(".splitter").hide();
    }
  })
}

//Load JSON file to generate app listing
function generateAdapters() {

  generateCount = 0;
  var filters = {};
  var listCol = 5;
  var ul = $('#container-apps');

  //Generate app list from adapters.JSON
  $.each(json, (function (object) {

    //Count adapter for no result function
    adapterCount += 1;

    var link = json[object].link;
    var git = json[object].github_link;
    var img = json[object].image;
    var name = json[object].name;
    var properties = json[object].properties;

    var li = $("<li>").attr({ "class": "app" }).appendTo(ul);
    var a = $("<a>").attr({
      "href": "javascript:void(0);",
      "target": "_blank",
      "class": "app-link",
    }).appendTo(li);

    var image = $("<img>").attr("src", img).appendTo(a);
    var label = $("<div>").attr("class", "item-name black-font").html(name).appendTo(a);
    var hoverContainer = $("<div>").attr("class", "hoverContainer").appendTo(li);
    var hoverName = $("<span>").attr("class", "hover-name").html(name).appendTo(hoverContainer);
    var hoverProperties = $("<ul>").attr("class", "hover-properties").appendTo(hoverContainer);
    var hoverUL = $("<ul>").appendTo(hoverContainer);
    var hoverPageLi = $("<li>").attr("class", name).appendTo(hoverUL);
    var hoverPageA = $("<a>").attr({ "href": link, "target": "_blank", "class": "app-link" }).html("Install Connector").appendTo(hoverPageLi);
    var hoverGitLi = $("<li>").appendTo(hoverUL);
    var hoverGitA = $("<a>").attr({ "href": git, "target": "_blank", "class": "app-link" }).html("View Source Code").appendTo(hoverGitLi);

    //Load filter options
    $.each(properties, function (i, item) {
      if (!(i in filters)) {
        filters[i] = [];
      }
      if (!(filters[i].includes(item))) {
        filters[i].push(item);
      }
      var hoverProperty = $("<li>").appendTo(hoverProperties)
      var hoverPropertyFilter = $("<span>").attr("class", "property-filter").html(textFormat[i] + ":").appendTo(hoverProperty);
      var hoverPropertyValue = $("<span>").attr("class", "property-value").html(item).appendTo(hoverProperty);
    })
  }));

  //Generate dummy box for responsive
  for (var i = 0; i < (listCol); i++) {
    $('<li class="item flex-dummy"></li>').appendTo(ul);
  }
  generateFilters(filters);
}

function generateFilters(filters) {
  var container = $("#container-filter");
  $.each(filters, function (i, item) {
    filterList[i] = ""; //Init empty filter values
    var div = $("<div>").attr("class", "filter-section ").appendTo(container);
    var title = $("<h5>").html(textFormat[i]).appendTo(div);
    var ul = $("<ul>").appendTo(div);
    i
    $.each(item, function (k, value) {
      var li = $("<li>").appendTo(ul);
      // var radioButtons = $("<input>").attr({
      //   "class": "filter-input",
      //   "type": "radio",
      //   "value": value,
      //   "name": i
      // }).appendTo(li);
      var label = $("<span>").attr("class", "filter-input " + i).html(value).appendTo(li);
    });
    isFirstInput = true;
  })
}

//Function to toggle visibility of navigation dropdown for mobile nav
function toggleSideNav() {
  if ($('.nav-links-li').is(':hidden')) {
    $('.nav-links-li').removeClass('hide');
    $('.nav-links-li').addClass('show');
  } else {
    $('.nav-links-li').removeClass('show');
    $('.nav-links-li').addClass('hide');
  }
}

//Function to toggle hover container
function toggleHover(item) {
  $(item).children(".hoverContainer").toggleClass("hoverContainer-show");
}

function clearSearch() {
  $("#clearForm").click(function () {
    var form = $("#search-form");
    $(form).val("");

    $('.app').each(function () {
      $(this).removeClass("search-hidden");
    });
    checkAllHidden();
  })
}
