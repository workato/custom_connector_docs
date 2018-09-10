/*
  Function to toggle navigation bar background when scrolled
*/
$(function () {
  $(".workato-logo").attr("src", "images/workatoDeveloper_logo.svg")
  $(".nav-bar").addClass("nav-home");
  $("#nav-dummy").removeClass("nav-dummy");

  $(document).scroll(function () {
	  var $nav = $(".nav-bar");
    var $bg = $(".nav-bg");
    var $content = $(".nav-home ul li a");
    var $logo = $(".workato-logo");

    $nav.toggleClass("scrolled-nav", $(this).scrollTop() > $nav.height());
	  // $bg.toggleClass("scrolled-bg", $(this).scrollTop() > $nav.height());
    // $content.toggleClass("scrolled-content", $(this).scrollTop() > $nav.height());
    // $logo.toggleClass("scrolled-logo", $(this).scrollTop() > $nav.height());

    if($nav.hasClass("scrolled-nav")){
      $bg.addClass("scrolled-bg");
      $content.addClass("scrolled-content");
      $logo.attr("src", "images/workatoDeveloper_logo_color.svg")
    } else {
      $bg.removeClass("scrolled-bg");
      $content.removeClass("scrolled-content");
      $logo.attr("src", "images/workatoDeveloper_logo.svg")
    }
	});
});
