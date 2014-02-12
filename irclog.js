content_resize = function(){
    var w = $(window).width();
    $(".content").css("max-width", w - 2 - 9 * 22);
}

window_ready = function(){
    $("select").each(function(){
        $(this).val($(this).children("option[selected='selected']").val());
    });
    content_resize();
}

$(window).resize(content_resize);
$(window).ready(window_ready);
