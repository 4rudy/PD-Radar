$(document).ready(function() {
    window.addEventListener("message", function(event) {
        let data = event.data;
        if (data.type == "Display") {
            if (data.bool) return $("body").fadeIn();
            $("body").fadeOut();
        }
        if (data.type == "updateRadar") {
            if (data.myspeed !== undefined) {
                var myspeed = Number(data.myspeed);
                myspeed = !isNaN(myspeed) ? Math.floor(myspeed) : 0;
                $("#myspeed").text(myspeed);
            }
            if (data.frontplate !== undefined) {
                $("#frontplate").text(data.frontplate);
            }
            if (data.frontspeed !== undefined) {
                var frontspeed = Number(data.frontspeed);
                frontspeed = !isNaN(frontspeed) ? Math.floor(frontspeed) : 0;
                $("#frontspeed").text(frontspeed);
            }

            if (data.rearplate !== undefined) {
                $("#rearplate").text(data.rearplate);
            }
            if (data.rearspeed !== undefined) {
                var rearspeed = Number(data.rearspeed);
                rearspeed = !isNaN(rearspeed) ? Math.floor(rearspeed) : 0;
                $("#rearspeed").text(rearspeed);
            }

        }
    });


});

$("#frontSpeedLimit").on("input", function() {
    let limit = $(this).val();
    if (!$.isNumeric(limit)) {
        limit = 0;
        $(this).val(0);
    }
    $.post("https://4rd-radar/setSpeedLimit", JSON.stringify({type: "front", limit}));
});

$("#rearSpeedLimit").on("input", function() {
    let limit = $(this).val();
    if (!$.isNumeric(limit)) {
        limit = 0;
        $(this).val(0);
    }
    $.post("https://4rd-radar/setSpeedLimit", JSON.stringify({type: "rear", limit}));
});

$(document).on('keydown', function(e) {
    if (e.key === 'Enter' || e.key === 'Escape') {
        $.post("https://4rd-radar/closeCursor");
    }
});

function changefronttype() {
    let type = $("#frontType").text();
    type = (type == "same") ? "opp" : "same";
    $("#frontType").text(type);
    $.post("https://4rd-radar/setType", JSON.stringify({yon: "front", type}));
}

function changereartype() {
    let type = $("#rearType").text();
    type = (type == "same") ? "opp" : "same";
    $("#rearType").text(type);
    $.post("https://4rd-radar/setType", JSON.stringify({yon: "rear", type}));
}


$(document).ready(function(){
    $(".FrontlockText").each(function() {
      if ($(this).val() === "") {
        $(this).val("OFF");
      }
    });

    $(".FrontlockText").on("click", function(){
      if($(this).val() === "OFF"){
        $(this).val("");
      }
    });

    $(".FrontlockText").on("input", function(){
      if($(this).val() === ""){
        $(this).val("OFF");
      }
    });

    $(".FrontlockText").on("keyup", function(){
      if($(this).val() === "0" || $(this).val() === ""){
        $(this).val("OFF");
      }
    });
});

function kapattim() {
    $("body").fadeOut();
}

// #dragtest set draggable when load
$(document).ready(function(){
    $('#dragtest').draggable();
});



$(document).on("click", ".offbuton", function () {
    $("body").fadeOut();
    $.post("https://4rd-radar/close");
});

$(document).on("click", ".SameText", function () {
    let type = $("#frontType").text();
    type = (type == "same") ? "opp" : "same";
    $("#frontType").text(type);
    $.post("https://4rd-radar/setType", JSON.stringify({yon: "front", type}));
});

$(document).on("click", ".rearSameText", function () {
    let type = $("#rearType").text();
    type = (type == "same") ? "opp" : "same";
    $("#rearType").text(type);
    $.post("https://4rd-radar/setType", JSON.stringify({yon: "rear", type}));
});


size = 100;

$(document).on("click", ".plus-btn", function () {
    size += 10;
    if (size > 150) {
        size = 150;
    }
    $(".bg").css("zoom", size + "%");
});

$(document).on("click", ".minus-btn", function () {
    size -= 10;
    if (size < 70) {
        size = 70;
    }
    $(".bg").css("zoom", size + "%");
});
