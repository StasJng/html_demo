$(function () {
    $.material.init();
    $(".select").dropdown({autoinit: "select"});
    $('.dropdown input, .dropdown .select-location').click(function (e) {
        e.stopPropagation();
    });
    $("#nav-tab-menu a").click(function () {
        $("#nav-tab-menu li").removeClass("active");
        $(".nav-tab-menu .tabs-c").removeClass("active");
        $(this).parent().addClass("active");
        $($(this).attr("href")).addClass("active");
        return false;
    });
    $("#head-sticky").sticky({topSpacing: 0, className: "head-sticky"});
    $('body').scrollspy({target: '#nav-scrollspy'})
    //$(".box-filter .col-xs-10").mCustomScrollbar();
    var slider = document.getElementById('slider');
    if (slider != null) {
        noUiSlider.create(slider, {
            start: [0, 10],
            connect: true,
            range: {
                'min': 0,
                'max': 3000000
            },
            step: 100000,
            pips: {
                mode: 'positions',
                density: 1,
                values: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
            }
        });
    }
    $(".box-item-sticky").sticky({
        topSpacing: 0, className: "is-sticky",
        wrapperClassName: "wrapper-sticky-c"
    });
    $("#box-menu-primary").sticky({
        topSpacing: 10, className: "is-sticky",
        wrapperClassName: "menu-category"
    });

    $('#box-menu-primary').on('sticky-start', function() {
        var _html=$(".box-menu-primary").clone();
        $(_html).attr("id","").addClass("menu-clone");
        $(_html).attr("style","z-index:9998");
        $(".menu-primary").append(_html);
        console.log("start"); });
    $('#box-menu-primary').on('sticky-end', function() {
        $(".menu-clone").remove();
        });
    $('#head-sticky').on('sticky-end', function () {
        $("#head-sticky-sticky-wrapper").css("height", "80px");
    });
    rating();

    $(".box-filter .btn").click(function () {
        if ($(this).hasClass("open")) {

            $(this).removeClass("open");
            $(this).find("i").removeClass("mdi-content-remove");
            $(this).parent().removeClass("active");
        } else {
            $(this).addClass("open");
            $(this).find("i").addClass("mdi-content-remove");
            $(this).parent().addClass("active");

        }
        return false;
    });

});

function rating() {
    setTimeout(function () {
        if ($.cookie('show_login') !== '1') {
            $("#box-account").addClass("open");
            $.cookie('show_login', '1');
        }

    }, 3000);

    var rating_quality = document.getElementById('rating-quality');
    var rating_price = document.getElementById('rating-price');
    var rating_service = document.getElementById('rating-service');
    if (rating_quality != null) {
        noUiSlider.create(rating_quality, {
            start: [5],
            range: {
                'min': 0,
                'max': 10
            },
            step: 1
        });
        rating_quality.noUiSlider.on('update', function (values, handle) {
            $("#rating-quality-val").html(parseInt(values[handle]));
        });
    }
    if (rating_price != null) {
        noUiSlider.create(rating_price, {
            start: [5],
            range: {
                'min': 0,
                'max': 10
            },
            step: 1
        });
        rating_price.noUiSlider.on('update', function (values, handle) {
            $("#rating-price-val").html(parseInt(values[handle]));
        });
    }
    if (rating_service != null) {
        noUiSlider.create(rating_service, {
            start: [5],
            range: {
                'min': 0,
                'max': 10
            },
            step: 1
        });
        rating_service.noUiSlider.on('update', function (values, handle) {
            $("#rating-service-val").html(parseInt(values[handle]));
        });
    }
}
var strWindowFeatures = "menubar=yes,location=yes,resizable=yes,scrollbars=yes,status=yes,height=400,width=800";
function ShareFacebook(url) {
    url = "https://www.facebook.com/sharer/sharer.php?u=" + url;
    windowObjectReference=window.open(url, "Share Facebook", strWindowFeatures);
    return false;
}
function ShareZing(url) {
    url = "http://link.apps.zing.vn/share?u=" + url;
    windowObjectReference = window.open(url, "Share Zing", strWindowFeatures);
    return false;
}
function ShareTwitter(url) {
    url = "https://twitter.com/intent/tweet?original_referer=" + url;
    windowObjectReference = window.open(url, "Share Zing", strWindowFeatures);
    return false;
}
function ShareGoogle(url) {
    url = "https://plus.google.com/share?url=" + url;
    windowObjectReference = window.open(url, "Share Zing", strWindowFeatures);
    return false;
}

