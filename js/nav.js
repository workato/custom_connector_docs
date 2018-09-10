/*
  Function to toggle side nav when hamburger icon is clicked
*/
$(function () {
  $(".nav-hamburg").click(function () {
    $(".side-nav").toggleClass("side-nav-extend");
    $(".page").toggleClass("body-extend");
    $("body").toggleClass("no-scroll");
  });
});
