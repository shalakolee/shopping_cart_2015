
$(document).ready(function () {

    ////////////////////////////////////////////////fade btns
    $('.fadeThis').append('<span class="hover"></span>').each(function () {
        var $span = $('> span.hover', this).css('opacity', 0);


        $(this).hover(function () {
            if ($(this).hasClass('inactive')) {
                //do nothing
            } else {
                $span.stop().fadeTo(300, 1);
            }
        }, function () {
            if ($(this).hasClass('active')) {
                //do nothing
            } else {
                $span.stop().fadeTo(300, 0);
            }
        });
    });


    ////////////////////////////////////////////////////////menu//////////////////////////
    $("ul#navUL li").hover(function () {
        $(this).find(".mBtn").css({ backgroundPosition: "0px bottom" }).stop().animate({ color: "#e95980" });
        $(this).find(".subMenu").stop(true, true).slideDown(200);
    }, function () {
        $(this).find(".mBtn").css({ backgroundPosition: "0px top" }).stop().animate({ color: "#ffffff" });
        $(this).find(".subMenu").stop(true, true).slideUp(200);
    });

    $(".subMenu .menuContent a").hover(function () {
        $(this).stop().animate({ paddingLeft: "5px", color: "#ba0605" });
    }, function () {
        $(this).stop().animate({ paddingLeft: "0px", color: "#5a5a5b" });
    });

    /////////////////anchor slide
    $(".scroll").click(function (event) {
        //prevent the default action for the click event
        event.preventDefault();

        //get the full url - like mysitecom/index.htm#home
        var full_url = this.href;

        //split the url by # and get the anchor target name - home in mysitecom/index.htm#home
        var parts = full_url.split("#");
        var trgt = parts[1];

        //get the top offset of the target anchor
        var target_offset = $("#" + trgt).offset();
        var target_top = target_offset.top;

        //goto that anchor by setting the body scroll top to anchor top
        $('html, body').animate({ scrollTop: target_top }, 500);
    });



});



$(function () {

    $('#side-menu').metisMenu();

});

//Loads the correct sidebar on window load,
//collapses the sidebar on window resize.
$(function () {
    $(window).bind("load resize", function () {
        width = (this.window.innerWidth > 0) ? this.window.innerWidth : this.screen.width;
        if (width < 768) {
            $('div.sidebar-collapse').addClass('collapse')
        } else {
            $('div.sidebar-collapse').removeClass('collapse')
        }
    })
})
