//Global var
var adapterCount=0;

//On Init
$( document ).ready(function() {
  generateAdapters();
});

//Search Function
function filterFunc(event) {

  var tempCount=0;
  var userInput = event.value.toUpperCase();

  $('.app').each(function() {
    if (this.textContent.toUpperCase().indexOf(userInput) > -1) {
      $(this).show();
    } else {
      $(this).hide();

      tempCount += 1;
    }
    //Show no result message if all adapters are hidden
    if (tempCount == adapterCount){
      $('#no-result').show();
    } else {
      $('#no-result').hide();
    }
  });
}

//Load JSON file to generate app listing
function generateAdapters(){

  //Load JSON file
  $.getJSON('adapters/adapters.json', function (json) {
    var listCol = 5;
    var container = $('#container-apps');

    //Generate app list from adapters.JSON
    json.adapters.forEach(function (adapter) {

      //Count adapter for no result function
      adapterCount += 1;

      var link = adapter.link;
      var img = adapter.image;
      var name = adapter.name;

      var content = '<li class="app">' +
      '<a target="_blank" href="' + link + '">' +
      '<img src="' + img + '">' +
      '<div class="item-name black-font">' + name + '</div>';

      $(content).appendTo(container);
    });

    //Generate dummy box for responsive
    for (var i = 0; i < (listCol); i++) {
      $('<li class="item flex-dummy"></li>').appendTo(container);
    }
  });
}

//Function to toggle visibility of navigation dropdown for mobile nav
function toggleSideNav() {
    if ($( '.nav-links-li' ).is( ':hidden' )){
      $('.nav-links-li').removeClass('hide');
      $('.nav-links-li').addClass('show');
    } else {
      $('.nav-links-li').removeClass('show');
      $('.nav-links-li').addClass('hide');
    }
}
