/**
 * Created by TUANDINH on 18/05/2017.
 */
/*login & register*/
$(function () {
    //active phone
    $(".btn-menu").click(function () {
        if ($("html").hasClass("state-menu")) {
            $("html").removeClass("state-menu");
        } else {
            $("html").addClass("state-menu");
        }
    });
    $('.datepicker').datepicker({
        format: 'dd/mm/yyyy'
    });
    $(".list-menu li").click(function () {
        $(this).find(".sub-menu").slideToggle();
    });
    $(".wrapper .header .user-information,.list-transaction .item .text-3,.nap-diem .number-point,.nap-diem .table-1 tr td:last-child,.wrapper .header .notification .number .input-select").addClass("notranslate");
    try {
        document.cookie = 'googtrans' +
    '=; expires=Thu, 01-Jan-70 00:00:01 GMT;';
    } catch (e) {
        console.log(e);
    }
})

function createCookie(name, value, days, domain) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        var expires = "; expires=" + date.toGMTString();
    } else {
        var expires = "";
    }
    document.cookie = name + "=" + value + expires + "; domain=" + domain + "; path=/";
}

function eraseCookie(name, domain) {
    createCookie(name, "", -1, domain);
}


function TranslateData(_this) {
    var lang = $(_this).attr('data-lang');
    var trans = $.cookie("googtrans");
    if (lang == 'Vietnamese' && typeof $.cookie("googtrans") != 'undefined') {
        $(".box-flag a span").removeClass("vn");
        $(_this).find('span').addClass("en");
        $(_this).attr("data-lang", "English");
        $(_this).find('i').text('EN');
        eraseCookie("googtrans", ".dealtoday.vn");
        eraseCookie("googtrans", "");
        location.reload();
        return false;
    }
    if (lang == 'English' && typeof $.cookie("googtrans") == 'undefined') {
        $(".box-flag a span").removeClass("en");
        $(_this).find('span').addClass("vn");
        $(_this).attr("data-lang", "Vietnamese");
        $(_this).find('i').text('VN');
        var $frame = $('.goog-te-menu-frame:first');
        if (!$frame.size()) {
            alert("Error: Could not find Google translate frame.");
            return false;
        }
        $('.goog-te-menu-frame:first').contents().find('a span.text').get(1).click();
        return false;
    }
    return false;
}