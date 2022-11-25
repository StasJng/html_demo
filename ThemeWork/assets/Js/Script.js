$(function () {
    $("[datafilter]").each(function (index, element) {
        var value = GetParameterByName($(element).attr("datafilter"));
        if (value != null && $.trim(value) != "")
            $(element).val(value);
    });
});
function GetParameterByName(name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
    return results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}
function NumberKeyPress(e, id, spaceChar, DecimalChar) {
    var key, keychar;
    if (window.event) { key = window.event.keyCode; }
    else if (e) { key = e.which; }
    else { return true; }
    keychar = String.fromCharCode(key);
    if ((key == null) || (key == 0) || (key == 8) || (key == 9) || (key == 13) || (key == 27)) {
        return true;

    }
    else if (("0123456789" + DecimalChar).indexOf(keychar) > -1) {
        if (document.getElementById) {
            var obj = document.getElementById(id);
            var sign = "";
            /*var str = obj.value.replace(/,/g, '');*/
            var replaceChar = spaceChar;
            if (spaceChar == '.') replaceChar = "\\.";

            var str = obj.value + keychar;

            str = str.replace(new RegExp(replaceChar, 'g'), '');
            if (str.indexOf('-') == 0 || str.indexOf('+') == 0) {
                sign = str.substr(0, 1);
                str = str.substr(1, str.lenght);
            }
            str = str.replace(/-/g, '');
            obj.value = sign + number_format(str, 0, DecimalChar, spaceChar);
            return false;
        }
        return true;
    }
    else if (keychar == "-") {
        var obj = document.getElementById(id);
        if (obj.value.length == 0) {
            return true;
        }
        else {
            return false;
        }
    }
    return false;
}

/*window.onload = function() { if (document.getElementById){var obj=document.getElementById('txt'); obj.onkeyup = function(event)  {if(event.keyCode==8 || event.keyCode==37 || event.keyCode==39) return; var str=this.value.replace(/,/g,''); obj.value = number_format(str, 0, '.', ','); } } }*/
function number_KeyUp(event, id, spaceChar, DecimalChar) {
    /*    var ingnore_key_codes = [109,188,190,8,48, 49, 50, 51, 52, 53, 54, 55, 56, 57];
    //    if ($.inArray(e.keyCode, ingnore_key_codes) < 0) {
    //        return;
    //    }*/
    if (document.getElementById) {
        var obj = document.getElementById(id);
        if (event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 8 || event.keyCode == 109 || event.keyCode == 68) return;
        var sign = "";
        /*var str = obj.value.replace(/,/g, '');*/
        var replaceChar = spaceChar;
        if (spaceChar == '.') replaceChar = "\\.";
        var str = obj.value.replace(new RegExp(replaceChar, 'g'), '');

        if (str.indexOf('-') == 0 || str.indexOf('+') == 0) {
            sign = str.substr(0, 1);
            str = str.substr(1, str.lenght);
        }
        str = str.replace(/-/g, '');
        obj.value = sign + number_format(str, 0, DecimalChar, spaceChar);
    }
}
var Shift = false;
function number_KeyDown(e, id) {

    var ingnore_key_codes = [37, 39, 8, 109, 188, 190, 8, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 35, 36, 37, 39];
    /*alert(e.keyCode);*/
    /*alert($.inArray(e.keyCode, ingnore_key_codes));*/
    var key = (document.all) ? e.keyCode : e.which;
    if (key == 16) {
        Shift = true;
        return;
    }
    if ($.inArray(key, ingnore_key_codes) < 0 || (Shift && $.inArray(key, ingnore_key_codes) > 0)) {
        if (e.preventDefault) {
            e.preventDefault();
        }
        else {
            e.returnValue = false;
        }
        Shift = false;
    }
    else {
        alert('xx' + key);
    }
}
function number_blur(event, id, spaceChar, DecimalChar) {
    if (document.getElementById) {
        var obj = document.getElementById(id);
        if (event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 8 || event.keyCode == 109 || event.keyCode == 68) return;
        var sign = "";
        var replaceChar = spaceChar;
        if (spaceChar == '.') replaceChar = "\\.";
        var str = obj.value.replace(new RegExp(replaceChar, 'g'), '');
        if (str.indexOf('-') == 0 || str.indexOf('+') == 0) {
            sign = str.substr(0, 1);
            str = str.substr(1, str.lenght);
        }
        str = str.replace(/-/g, '');
        obj.value = sign + number_format(str, 0, DecimalChar, spaceChar);
    }
}
function number_focus(event, id, spaceChar, DecimalChar) {

    if (document.getElementById) {
        var obj = document.getElementById(id);
        if (event.keyCode == 37 || event.keyCode == 39 || event.keyCode == 8 || event.keyCode == 109 || event.keyCode == 68) return;
        var sign = "";
        /*var str = obj.value.replace(/,/g, '');
        alert(spaceChar);*/
        var replaceChar = spaceChar;
        if (spaceChar == '.') replaceChar = "\\.";
        var str = obj.value.replace(new RegExp(replaceChar, 'g'), '');
        /*alert(str);*/
        if (str.indexOf('-') == 0 || str.indexOf('+') == 0) {
            sign = str.substr(0, 1);
            str = str.substr(1, str.lenght);
        }
        str = str.replace(/-/g, '');
        obj.value = sign + number_format(str, 0, DecimalChar, spaceChar);
        setCaretPosition(id, obj.value.length);
    }

}
function setCaretPosition(elemId, caretPos) {
    var elem = document.getElementById(elemId);

    if (elem != null) {
        if (elem.createTextRange) {
            var range = elem.createTextRange();
            range.move('character', caretPos);
            range.select();
        }
        else {
            if (elem.selectionStart) {
                elem.focus();
                elem.setSelectionRange(caretPos, caretPos);
            }
            else
                elem.focus();
        }
    }
}
function number_format(a, b, c, d) {
    a = Math.round(a * Math.pow(10, b)) / Math.pow(10, b);
    e = a + ''; f = e.split('.');
    if (!f[0]) { f[0] = '0'; }
    if (!f[1]) { f[1] = ''; }
    if (f[1].length < b) { g = f[1]; for (i = f[1].length + 1; i <= b; i++) { g += '0'; } f[1] = g; }
    if (d != '' && f[0].length > 3) {
        h = f[0]; f[0] = '';
        for (j = 3; j < h.length; j += 3) {
            i = h.slice(h.length - j, h.length - j + 3);
            f[0] = d + i + f[0] + '';
        }
        j = h.substr(0, (h.length % 3 == 0) ? 3 : (h.length % 3));
        f[0] = j + f[0];
    }
    c = (b <= 0) ? '' : c; f[0] = f[0] + c + f[1];
    if (f[0].indexOf('N') >= 0) { return '' } else { return f[0]; }
}

function delelteCommentHead(partam) {
    $.ajax({
        url: "notification/delete",
        type: "post",
        data: {
            cmtid: $(param).attr("data-cmtid")
        },
        success: function () {
            $("#" + $(param).attr("data-id")).remove();
        }
    });
}